---
title: Headscale を自宅サーバまたは AWS EC2 で運用する
date: 2026-05-06 21:20:11
categories:
  - Infrastructure
  - Networking
tags:
  - Headscale
  - Tailscale
  - WireGuard
  - VPN
  - AWS
  - Ansible
  - Terraform
  - SelfHosting
---

# はじめに

[Tailscale][tailscale] は WireGuard をベースとしたメッシュ型 VPN サービスで、複数のデバイスを安全に相互接続できます。
普段はマネージドサービスとして利用すれば十分ですが、

- 制御サーバ（コーディネーションサーバ）を自分の管理下に置きたい
- ベンダーロックインを避け、構成情報を自身で持ちたい
- WireGuard と Tailscale の仕組みを学びたい

といった動機がある場合、[Headscale][headscale] を使ってセルフホスト構成を組むという選択肢があります。
本稿では、個人利用を想定して、Headscale を **AWS EC2 単体** または **自宅 Linux サーバ** で運用する手順を整理します。
あわせて、設定の自動化のための Terraform と Ansible の構成例も紹介します。

# Headscale の概要

Headscale は Tailscale 制御サーバの OSS 互換実装です。
データプレーン（実際のトラフィック）は Tailscale 公式と同じく WireGuard で構成され、
クライアントは公式の [Tailscale クライアント][tailscale-download]（macOS / Windows / Linux / iOS / Android）をそのまま利用します。
Headscale が代替するのは、ノード登録、鍵管理、ACL 配布、DNS、DERP リレーの調整といった「制御プレーン」の部分のみです。

![Headscale 制御プレーンとデータプレーン](/memo-blog/images/headscale-control-data-plane.png)

公式によれば「単一 tailnet を対象とした、個人や小規模 OSS 組織向けの実装」とされています [^scope]。
本稿の執筆時点における最新版は **v0.28.0**（2025-02-04 リリース）です [^release]。

# 構成パターンの選択

ホストする場所は、大きく次の 2 通りがあります。

| 構成 | 長所 | 短所 |
| --- | --- | --- |
| AWS EC2 単体 | 公衆 IP・DNS・帯域が安定。ポート開放を気にしなくてよい。 | 月額のランニングコストが発生する。 |
| 自宅 Linux サーバ | 既存サーバを活用できる。電気代以外の月額コストはほぼゼロ。 | グローバル IP の確保や、ISP の制約（CGNAT 等）に応じた工夫が必要。 |

リバースプロキシは **Caddy を推奨**します。Tailscale プロトコルは WebSocket POST を必要とするため、
**Cloudflare（および Cloudflare Tunnel）は使えない** 点に注意してください。
公式のリバースプロキシリファレンス [^reverse-proxy] でも明記されています。

# 事前準備（AWS アカウントとローカル環境）

実際に試す前に整えておくと、以降の手順がスムーズになります。
AWS で構築する場合と、自宅サーバ構成のどちらでも共通する項目を先に列挙します。

## AWS を使う場合

### 1. AWS アカウントと IAM ユーザー

ルートアカウントは使わず、Terraform 用の IAM ユーザーを作成します。

1. AWS マネジメントコンソール → IAM → 「ユーザーの作成」
2. 必要な権限ポリシー（個人利用なら以下のマネージドポリシーで十分）:
   - `AmazonEC2FullAccess`（VPC・EIP も含む）
   - `AmazonRoute53FullAccess`（Route 53 を使う場合のみ）
3. 作成後、対象ユーザー → 「セキュリティ認証情報」 → 「アクセスキーを作成」 → 用途「コマンドラインインターフェイス（CLI）」
4. アクセスキー ID とシークレットアクセスキーを控えておきます（**一度しか表示されない**）

### 2. AWS CLI のプロファイル設定

ローカル PC（WSL2 や Linux）に AWS CLI をインストールして、プロファイルを設定します。

```bash
sudo apt install -y awscli   # 未インストールなら

aws configure --profile headscale
# AWS Access Key ID:     <控えたアクセスキー>
# AWS Secret Access Key: <控えたシークレット>
# Default region name:   ap-northeast-1
# Default output format: json
```

以降のコマンドではプロファイルを環境変数で固定すると楽です。

```bash
export AWS_PROFILE=headscale
export AWS_REGION=ap-northeast-1

# 認証確認
aws sts get-caller-identity
```

### 3. SSH 鍵と EC2 キーペア

EC2 にログインするための鍵です（IAM のアクセスキーとは別物）。

```bash
# ローカルの SSH 鍵が無ければ生成
[ -f ~/.ssh/id_ed25519.pub ] || ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# AWS にキーペアを import
aws ec2 import-key-pair \
  --key-name headscale-key \
  --public-key-material fileb://~/.ssh/id_ed25519.pub
```

ここで指定した `--key-name` の値（例: `headscale-key`）を、後で Terraform の `key_name` 変数に渡します。両者の名前が一致していないと EC2 起動時に `InvalidKeyPair.NotFound` で失敗するので注意してください。

### 4. 利用可能な AZ の確認

新規 AWS アカウントには **特定の AZ（例: `ap-northeast-1a`）が割り当てられないことがあります**。
事前に利用可能な AZ を確認してください。

```bash
aws ec2 describe-availability-zones \
  --query "AvailabilityZones[?State=='available'].[ZoneName,ZoneId]" \
  --output table
```

返ってきた中から 1 つを Terraform の `availability_zone` に指定します。
割り当てられていない AZ を指定すると、サブネット作成時に `unexpected state 'unavailable'` エラーが出ます。

### 5. ドメイン

`hs.example.com` のように、Headscale サーバを公開するドメイン（あるいはサブドメイン）が必要です。
お名前.com、Cloudflare、Route 53 など好みの DNS で構いません（後述の「DNS レコードの設定」で具体例を示します）。

## 自宅サーバを使う場合

- Ubuntu 24.04 LTS（ARM64 / AMD64 どちらでも）が動作するマシン
- ローカルから SSH 接続できる状態
- 以降の DNS / グローバル IP 関連は「案B: 自宅 Linux サーバでの構成」で扱います

## ローカル PC のツール

| ツール | 用途 | 備考 |
| --- | --- | --- |
| Terraform >= 1.6 | AWS リソース構築 | 自宅サーバ構成の場合は不要 |
| Ansible >= 2.16（ansible-core） | サーバへのソフトウェアインストール | 後述の通り apt 版は古い場合があるので注意 |
| AWS CLI v2 | AWS との対話 | AWS 構成の場合のみ |
| ssh / dig / curl | 動作確認 | 通常入っている |

## 想定コスト（AWS 構成、東京リージョン）

| 項目 | 月額目安 |
| --- | --- |
| EC2 `t4g.micro`（24h 稼働） | $7.78 |
| EBS gp3 16 GiB | $1.54 |
| Public IPv4（EIP）※ | $3.60 |
| **合計** | **約 $13 / 月（≒ ¥2,000）** |

※ 2024 年 2 月以降、AWS は接続中・未接続を問わずすべての Public IPv4 アドレスに対して $0.005/h の課金を行います。
試用後はすみやかに `terraform destroy` で削除すれば、それ以降の課金は止まります。

# 案A: AWS EC2 単体構成

先に前提条件が単純な EC2 構成から扱います。
本稿では Ubuntu 24.04 LTS（ARM64、`t4g.small`）を 1 台立ち上げ、Caddy で TLS 終端し、Headscale 本体はバックエンドに置く構成とします。

## 1. インスタンスの準備

- インスタンスタイプ: `t4g.micro`（2 vCPU / 1 GiB、ARM64）で個人利用には十分（クライアント数が増える / ACL を凝るなら `t4g.small` 推奨）
- AMI: 最新の Ubuntu 24.04（Canonical 公式）
- ストレージ: gp3 16 GiB（暗号化）
- パブリック IP: Elastic IP を付与（再起動でも IP を維持するため）
- AZ と キーペアは「事前準備」で確認した値を使用

セキュリティグループの受信ルールは次の通りです。

- `22/tcp`: 管理用、自宅 IP の `/32` のみ許可
- `80/tcp`、`443/tcp`: Caddy（自動 TLS 取得と HTTPS 公開）
- `3478/udp`: 組み込み DERP を使う場合のみ。本稿の構成では Tailscale 公式 DERP を利用するので **不要**

EIP を確保したら、後述の「[DNS レコードの設定](#DNS-レコードの設定)」に従って、利用するドメイン（例: `hs.example.com`）の A レコードを EIP に向けます。

## 2. Headscale のインストール

DEB パッケージでのインストールが公式推奨です [^install]。
`HEADSCALE_VERSION` は最新リリースに合わせて更新してください。

```bash
HEADSCALE_VERSION="0.28.0"
HEADSCALE_ARCH="arm64"   # x86_64 の場合は amd64

wget --output-document=headscale.deb \
  "https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_${HEADSCALE_ARCH}.deb"
sudo apt install ./headscale.deb
```

DEB パッケージなら、`headscale` ユーザー、systemd サービス、`/etc/headscale/` 以下のディレクトリ、`/var/lib/headscale/` のデータ領域などが一式整備されます。

## 3. 設定ファイル

`/etc/headscale/config.yaml` を編集します。最小構成は次のようなものです。

```yaml
server_url: https://hs.example.com
listen_addr: 127.0.0.1:8080      # Caddy 経由なのでローカル限定
metrics_listen_addr: 127.0.0.1:9090
grpc_listen_addr: 127.0.0.1:50443
grpc_allow_insecure: false

tls_cert_path: ""                 # TLS は Caddy で終端
tls_key_path: ""

noise:
  private_key_path: /var/lib/headscale/noise_private.key

prefixes:
  v4: 100.64.0.0/10
  v6: fd7a:115c:a1e0::/48
  allocation: sequential

derp:
  server:
    enabled: false
  urls:
    - https://controlplane.tailscale.com/derpmap/default

database:
  type: sqlite
  sqlite:
    path: /var/lib/headscale/db.sqlite
    write_ahead_log: true

dns:
  magic_dns: true
  base_domain: hs-net.example.com   # server_url のドメインとは別にする
  nameservers:
    global:
      - 1.1.1.1
      - 9.9.9.9

policy:
  mode: file
  path: /etc/headscale/acl.hujson

unix_socket: /var/run/headscale/headscale.sock
unix_socket_permission: "0770"
```

要点は次の通りです。

- `server_url` はクライアントが接続する URL。後述の Caddy が公開するドメインに合わせます。
- `tls_cert_path` / `tls_key_path` を空にして、TLS 終端は Caddy に任せます。
- `dns.base_domain` は `server_url` のドメインと **別の** ドメインを指定する必要があります（重複していると起動に失敗します）。
- 個人利用ではデータベースは SQLite で十分です。Postgres はレガシー扱いとされています [^db]。
- 設定の検証は `sudo headscale configtest` で行えます。

## 4. Caddy で自動 HTTPS

Caddy は自動 HTTPS と WebSocket 対応をデフォルトで備えており、Headscale との相性が良いです。

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key \
  | sudo tee /usr/share/keyrings/caddy-stable.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/caddy-stable.asc] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" \
  | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy
```

`/etc/caddy/Caddyfile` を以下のように書き換えます。

```caddyfile
{
    email you@example.com
}

hs.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

設定を反映します。

```bash
sudo systemctl reload caddy
sudo systemctl enable --now headscale
```

`https://hs.example.com/health` にアクセスして `pass` が返ってくれば疎通できています。

# 案B: 自宅 Linux サーバでの構成

自宅サーバで運用する場合、最大の論点は **インターネットからの到達性** です。
ISP の契約によって状況が異なるため、まずは前提を整理します。

## 1. グローバル IP まわりの整理

確認すべき項目は次の 3 点です。

1. **公衆 IPv4 アドレスを持っているか**
   - 固定 IP か、動的 IP か
   - ルータの WAN 側 IP と、`curl ifconfig.me` で取得できる IP が一致していれば公衆 IP を直接持っています
   - 一致しない場合は ISP 側で NAT されており、おそらく **CGNAT** 環境です
2. **ポート 80 / 443 を外向けに開けられるか**
   - ルータでポートフォワードができるか
   - ISP が 80 / 443 をブロックしていないか
3. **IPv6 が利用できるか**
   - 利用できる場合でも、接続するクライアント側で必ず IPv6 が使えるとは限らないため、IPv6 単独は実用上の冗長系として捉えるのが無難です

これらの結果に応じて、以下のパターンに分かれます。

### パターンA: 公衆 IP + ポート開放可

最も素直な構成です。

- 動的 IP の場合は **DDNS** で名前を固定します。
  Cloudflare の DNS（普通の DNS のみ。Cloudflare Tunnel ではない）を使う場合、API トークンと簡単なスクリプト（`ddclient` や自前の cron スクリプト）でレコードを更新できます。
- 自宅ルータで `80/tcp` と `443/tcp` をサーバへフォワードします。
- サーバ側のセットアップは前述の AWS EC2 構成と同じです。Caddy が Let's Encrypt から自動で証明書を取得します。

### パターンB: CGNAT / ポート開放不可

外側からの着信が物理的に通せないため、外部に「踏み台」が必要になります。

- **解1: 安価な VPS に Headscale を直接置く**
  実質的に AWS EC2 と同じ構成になります。Hetzner や Vultr、Oracle Cloud の Always Free 枠などが選択肢です。
- **解2: VPS をリバースプロキシにし、自宅サーバへ WireGuard 等で逆トンネル**
  Headscale 本体は自宅サーバに置きつつ、外部に対する HTTPS エンドポイントは VPS が担う構成です。
  自宅サーバから VPS に向けて WireGuard を張り、VPS の Caddy が自宅側へ `reverse_proxy` します。
  自宅サーバの計算資源を活用したい場合に有用ですが、構成要素が増えるため **解1 のほうがおすすめ**です。

![CGNAT 配下の自宅サーバを VPS 経由で公開する構成](/memo-blog/images/headscale-cgnat-vps.png)

### Cloudflare Tunnel が使えない理由（補足）

外部公開の手段として人気のある Cloudflare Tunnel ですが、**Headscale では使えません**。
公式リバースプロキシリファレンス [^reverse-proxy] にも明記されている通り、Tailscale プロトコルは WebSocket の `POST` を必要とし、これを Cloudflare はサポートしていないためです。
Cloudflare 経由の HTTPS 化には魅力がありますが、Headscale に関しては別の方法を検討してください。

## 2. ソフトウェアのセットアップ

ここから先（Headscale + Caddy のインストール、`config.yaml` と `Caddyfile` の内容）は AWS EC2 構成と共通です。

# DNS レコードの設定

Headscale サーバには、`server_url` で指定したドメイン（例: `hs.example.com`）の **A レコード** を、サーバの公開 IP に向ける設定が必須です。
EC2 構成の場合は Elastic IP、自宅サーバ構成の場合は自宅ルータの公衆 IP（または踏み台 VPS の IP）が対象になります。
ドメインを管理している DNS 提供元ごとに、設定の入り口が異なります。

## お名前.com で運用する場合

お名前.com には紛らわしい点があり、**初期状態ではドメインのネームサーバが「お名前.com DNS（実際にレコード管理ができるサービス）」に向いていない** ことが多いです。
ドメイン購入直後は `dns1.onamae.com` / `dns2.onamae.com`（パーキング用 NS）が設定されており、A レコードを追加しようとしても画面が出てきません。

切り替えの最短手順は次の通りです。

### 1. 「DNS レコード設定を利用する」を選んでネームサーバごと切替

1. **[お名前.com Navi][onamae-navi]** にログイン
2. 上部メニューの「**ドメイン**」 → 対象ドメインの行で「**DNS**」または「**ドメインの DNS 関連機能の設定**」をクリック
3. 表示された選択肢から **「DNS レコード設定を利用する」 → 「設定する」**
   - この操作で、ネームサーバが自動的に `01.dnsv.jp` 〜 `04.dnsv.jp` に切り替わります
4. レコード追加フォームで以下を設定して「追加」:
   - **ホスト名**: `hs`（フルで `hs.example.com` の場合）
   - **TYPE**: `A`
   - **TTL**: `3600`（初期検証中は `300` でも可）
   - **VALUE**: サーバの公開 IP（EIP など）
   - **状態**: 有効
5. 画面下の「**確認画面へ進む**」 → 「**設定する**」で確定

### 2. NS 切替の反映を確認

ネームサーバの変更は反映に時間がかかります（最長 24 時間、通常は数分〜1 時間）。

```bash
# 権威 NS が切り替わったか
dig +short NS example.com
# 期待値: 01.dnsv.jp. 〜 04.dnsv.jp.

# A レコードが返るか（権威 DNS に直接問い合わせ）
dig +short hs.example.com @01.dnsv.jp

# 通常解決でも見えるか
dig +short hs.example.com
```

NS が `dns1.onamae.com` のままだと、A レコードを設定しても応答に反映されない、あるいは **パーキング用の IP（`150.95.x.x` 等）が返ってきてしまう** ので、まず NS の切替を完了させてください。

## 動的 IP の自宅サーバの場合（補足）

お名前.com DNS は API 経由の自動更新（DDNS）に対応していません。
公衆 IP が動的に変わる環境では、ドメインはお名前.com で管理したまま、**ネームサーバを Cloudflare DNS（無料プラン）に変更** する構成がよく使われます。
Cloudflare の API トークンと `ddclient` などのスクリプトがあれば、IP 変更時に A レコードを自動更新できます。
本稿で除外している「Cloudflare Tunnel」は WebSocket 制約により使えませんが、DNS としての Cloudflare 利用は問題ありません。

## Route 53 で運用する場合

DNS を AWS Route 53 でホスティングしているなら、Terraform で A レコードまで一括管理できます。
本稿の Terraform に次のリソースを追加するだけです。

```hcl
data "aws_route53_zone" "this" {
  name = "example.com."
}

resource "aws_route53_record" "headscale" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "hs.example.com"
  type    = "A"
  ttl     = 300
  records = [aws_eip.headscale.public_ip]
}
```

# クライアントの接続

クライアントを Tailnet に参加させる手順は、大きく次の流れになります。

1. サーバ側でユーザーと（必要なら）事前認証鍵を発行する
2. クライアント側で公式 Tailscale を起動し、`--login-server` で Headscale を指定する
3. 必要に応じてサーバ側でノードを承認する

## サーバ側: ユーザーと事前認証鍵の発行

v0.28.0 から `preauthkeys` コマンドはユーザー名ではなく **ユーザー ID** を引数に取る仕様に変わっているため、先に `users list` で ID を確認します。

```bash
sudo headscale users create alice
sudo headscale users list
# 表示された ID（例: 1）を控える

sudo headscale preauthkeys create --user 1 --reusable --expiration 24h
# 出力された tskey-auth-xxxxxxxxxxxxxxxxxxxxx を控える
```

`preauthkeys create` の主なフラグは次の通りです。

- `--reusable`: 同じ鍵を複数台に使い回す（IaC との併用で便利）
- `--ephemeral`: 切断時にノード登録を自動削除（CI ランナーや一時的なサーバ向け）
- `--expiration <duration>`: 有効期限（例: `24h`、`30d`）

## 方法 A: 事前認証鍵で自動登録（推奨）

クライアント側で `--login-server` と `--authkey` を渡すだけで完了します。スクリプトや cloud-init から無人で投入できるため、複数台を一気に追加する場合や、サーバ系のノードを登録する場面に向いています。

```bash
# Linux クライアント
sudo tailscale up \
  --login-server https://hs.example.com \
  --authkey tskey-auth-xxxxxxxxxxxxxxxxxxxxx
```

実行後、サーバ側で `sudo headscale nodes list` を打つと、登録済みノードとして表示されます。

## 方法 B: インタラクティブ登録（事前認証鍵を使わない）

`--authkey` を渡さずに `tailscale up` を実行すると、クライアント側に登録用 URL が表示されます。Headscale ではその URL を踏むだけでは登録が完了せず、URL に含まれる **ノードキー（`nodekey:...`）をサーバ側で承認** する流れになります。

```bash
# クライアント側
sudo tailscale up --login-server https://hs.example.com
# 出力例:
# To authenticate, visit:
#   https://hs.example.com/register/nodekey:abcdef0123...
```

URL の末尾にあるノードキーをサーバ側に渡して承認します。

```bash
# サーバ側（Headscale）
sudo headscale users list                              # 対象ユーザー ID を確認
sudo headscale nodes register \
  --user 1 \
  --key nodekey:abcdef0123...
```

事前認証鍵の発行・配布が不要な代わりに、サーバ側で 1 台ずつ手動承認する手間が増えます。少数のノードを慎重に管理したいケースや、認証鍵をクライアント側に置きたくない運用ポリシーで有効です。

## 公式アプリ（macOS / iOS / Windows / Android）

GUI クライアントでも Headscale に接続できます。共通する流れは次の通りです [^connect]。

1. アプリの設定で「カスタムコーディネーションサーバ（Custom coordination server / Alternate server URL）」に `https://hs.example.com` を指定
2. ログイン操作を行うと、ブラウザで Headscale の登録ページが開く
3. 表示されたコマンド（`headscale nodes register --user <id> --key <nodekey>`）をサーバ側で実行して承認

事前認証鍵を使わせたい場合は、各アプリの「authkey でサインイン」相当のメニューに鍵を貼り付けます。
UI の文言や設定階層は OS とアプリ版によって変わりやすいため、本稿では公式ドキュメントへのリンクに留めます。

## 起動時に指定できる代表的なフラグ

`tailscale up` には接続時に指定できる便利なフラグがあります。よく使うものを用途別にまとめます。

| フラグ | 用途 |
| --- | --- |
| `--hostname=<name>` | Tailnet 上での表示名・MagicDNS 名を上書き |
| `--reset` | 過去のフラグを破棄して指定したフラグだけで再構成 |
| `--ssh` | Tailscale SSH を有効化（ACL で `ssh` ルール定義が必要） |
| `--accept-routes` | 他ノードが広告したサブネット経路を取り込む |
| `--accept-dns=false` | MagicDNS を使わず既存の DNS 設定を保つ |
| `--advertise-routes=<cidr>` | 自ノードをサブネットルータとして広告（要 `ip_forward`） |
| `--advertise-exit-node` | Exit Node として広告 |
| `--exit-node=<peer>` | 通信を peer 経由でインターネットに出す |

サブネットルータや Exit Node として広告する場合は、サーバ側でも経路の承認が必要です（`headscale nodes list-routes` で一覧、`headscale nodes approve-routes` で承認）。
ACL や経路まわりの細かい挙動は公式リファレンス [^acl] に委ね、本稿では「クライアントを Tailnet に参加させる」ところまでをカバーします。

## 接続後の動作確認（クライアント側）

Headscale 構成でも、クライアント側のサブコマンド体系は公式 Tailscale と同一です [^cli]。
接続が完了したら、まず以下の順で状態を確認します。

### 1. ノードの状態とピア一覧

```bash
tailscale ip          # 自ノードの Tailnet IP（既定では 100.64.0.0/10 から払い出し）
tailscale status      # ピア一覧と各ノードの状態（idle / active / offline 等）
tailscale version
```

`tailscale status` の各行末に `idle` や `offline` が並んだ状態のままになる場合、クライアント自身がコーディネーションサーバへ到達できていない可能性が高いため、次の `netcheck` とログで切り分けます。

### 2. 接続性とリレー判定

```bash
tailscale netcheck            # NAT 種別と各 DERP リレーまでの遅延を計測
tailscale ping <peer>         # 特定ピアまでの経路を確認（DERP 経由 / 直接 P2P を判別）
```

`tailscale ping` は ICMP ではなく Tailscale プロトコル上での到達性を測るため、経路途中で ICMP がブロックされていても結果が得られます。
出力に `via DERP` と表示されればリレー経由、`via direct` であれば P2P で接続できています。

### 3. デーモンの状態とログ

Linux クライアントでは `tailscaled` の状態と journald のログから原因を絞り込めます。

```bash
systemctl status tailscaled
sudo journalctl -u tailscaled -n 100 --no-pager
```

`Unable to connect to the Tailscale coordination server` のような出力がある場合は、

- `server_url`（例: `hs.example.com`）の DNS が公開 IP を指しているか
- Caddy が稼働しており `https://hs.example.com/health` が `pass` を返すか
- クライアントの `--login-server` が `server_url` と完全一致しているか（末尾スラッシュやスキームの差にも注意）

の順で見直すとスムーズです。

### 4. 再ログインと切断

ログインサーバを変更したり、状態をリセットしたい場合は次のコマンドを使います。

```bash
sudo tailscale up --login-server https://hs.example.com --reset
sudo tailscale down       # トンネルだけ切断（設定は維持）
sudo tailscale logout     # ノード登録を破棄
```

`--reset` を付けると過去に渡したフラグを引き継がず、指定したフラグのみで再構成できるため、設定変更時の事故を避けられます。

# 複数ノード間で SSH するまで

ここまでで 1 台のクライアントを Tailnet に参加させる手順を整理しました。
実用上は **複数のノード（ノート PC、サーバ、自宅マシンなど）を相互につなぎ、Tailnet 経由で SSH や各種サービスへ到達できる** ところまでを確認したいはずです。
本節では、2 台のクライアント（仮に `client-a` と `client-b` と呼びます）を登録した直後から、SSH 接続が通るまでの流れを順に追います。

## 1. ノードがサーバに登録されているかを確認

サーバ側で `headscale nodes list` を打ち、両ノードが並んで表示されることを確認します。

```bash
sudo headscale nodes list
```

| 列の見方 | 意味 |
| --- | --- |
| `ID` | Headscale 内部のノード ID |
| `Hostname` | クライアント側の OS ホスト名（変更したい場合は `tailscale up --hostname` で上書き可能） |
| `IP addresses` | 払い出された Tailnet IP（既定では `100.64.0.0/10` 内） |
| `Online` | コーディネーションサーバとの接続状態 |
| `Expired` | ノードキーの有効期限切れ |

`Online: true` で両方が並べば、登録は完了です。クライアント側でも同様に状態を確認します。

```bash
# client-a で
tailscale status
# 自ノードの行に続いて、ピアとして client-b が表示される想定
```

## 2. ピア間の疎通確認

Tailscale プロトコル経由で相手ノードに到達できるかを `tailscale ping` で確認します。
このコマンドは ICMP ではなく Tailscale 内部の到達性を測るため、経路上で ICMP がブロックされていても結果が出ます。

```bash
# client-a から client-b へ
tailscale ping client-b

# IP 指定でも可
tailscale ping 100.64.0.x
```

出力に注目するのは経路の種別です。

- `pong from client-b ... via DERP(tok) in 12ms` → DERP リレー経由（NAT 越えに失敗した場合の自動フォールバック）
- `pong from client-b ... via 198.51.100.20:41641 in 5ms` → 直接 P2P 接続

最初は DERP 経由でも、しばらくすると P2P に切り替わることがあります。
NAT が厳しい環境では DERP のままになることもありますが、通信は成立します。

通常の `ping` も合わせて確認しておくと、ICMP まで通るかを把握できます。

```bash
ping -c 3 100.64.0.x
```

## 3. MagicDNS による名前解決

`config.yaml` で `dns.magic_dns: true` にしている場合、`<hostname>.<base_domain>` 形式でノード名を引けます。
たとえば `base_domain` を `hs-net.example.com` に設定していれば、`client-b.hs-net.example.com` が `client-b` の Tailnet IP に解決されます。

```bash
# 名前解決を確認
tailscale status                              # 各ノードの完全名（FQDN）を表示
ping -c 1 client-b.hs-net.example.com

# どうしても解決できない場合の切り分け
tailscale debug prefs | grep -i corpdns       # MagicDNS が有効か
resolvectl status                             # systemd-resolved 環境
```

`tailscale up` 時に `--accept-dns=false` を付けていると MagicDNS は無効になります。
その場合は IP 直打ち、または OS の `/etc/hosts` などで明示的に名前解決の経路を作る必要があります。

## 4. 通常の SSH で接続する

ここまで来れば、Tailnet 内であれば通常の OpenSSH で接続できます。
クライアント側に `tailscaled` が動いていて IP が振られていれば、SSH デーモン側は特別な設定なしで Tailnet からの接続を受け付けます。

```bash
# Tailnet IP で接続
ssh user@100.64.0.x

# MagicDNS 名で接続（推奨。IP が変わっても影響しない）
ssh user@client-b.hs-net.example.com
```

接続できない場合のチェック順は次の通りです。

1. ピア側で `sshd` が稼働しているか（`systemctl status ssh`）
2. ピア側のファイアウォール（`ufw status` など）が `tailscale0` インターフェイスからの 22/tcp を許可しているか
3. ACL（`/etc/headscale/acl.hujson`）で `dst` 側の 22/tcp が許可されているか
4. Tailnet IP / MagicDNS 名のどちらでも `tailscale ping` で疎通できているか

ACL を初期状態（全許可）から絞り込んだ場合、SSH のために次のような最小ルールを残しておくと運用しやすいです。

```json
{
  "acls": [
    {
      "action": "accept",
      "src":    ["alice"],
      "dst":    ["alice:22"]
    }
  ]
}
```

`alice` の部分は、Headscale 上で `users create` したユーザー名に置き換えます。
ユーザー単位で許可することで、後から別ユーザーを追加しても影響範囲を分離できます。

## 5. （任意）Tailscale SSH を有効化する

各ノードに OpenSSH を立てて鍵を配るのが面倒な場合、`tailscaled` 経由で SSH を提供する **Tailscale SSH** が便利です [^acl]。
鍵管理が不要になり、ACL でアクセス可否を一元的に制御できます。

クライアント側で SSH サーバ機能を有効化します。

```bash
sudo tailscale up \
  --login-server https://hs.example.com \
  --ssh \
  --reset
```

ACL には `ssh` ルールを追加します。

```json
{
  "acls": [
    { "action": "accept", "src": ["*"], "dst": ["*:*"] }
  ],
  "ssh": [
    {
      "action": "accept",
      "src":    ["alice"],
      "dst":    ["alice"],
      "users":  ["autogroup:nonroot"]
    }
  ]
}
```

利用側からは通常の `ssh` コマンドで接続できます。

```bash
ssh alice@client-b.hs-net.example.com
# OpenSSH の鍵ではなく、Tailscale ACL で認可される
```

`autogroup:nonroot` は root 以外のすべてのユーザーを意味します。
特定ユーザーだけに絞りたい場合は `["alice", "bob"]` のように列挙します。
ポリシー編集後は `sudo headscale policy check --file /etc/headscale/acl.hujson` で構文を確認してから反映してください。

# 構築の自動化（Terraform / Ansible）

ここまでの手順を自動化するための Terraform と Ansible の最小構成を用意しています。
記事と対応するソースは [GitHub の `dobachi/headscale-iac-sample` リポジトリ][iac-source]に置いてあるので、`git clone` してそのまま試せます。

## Terraform: AWS 側のリソース構築

新規 VPC、パブリックサブネット、セキュリティグループ、Ubuntu 24.04 ARM64 の EC2、Elastic IP を一括で作成します。

```bash
cd iac/terraform
cp terraform.tfvars.example terraform.tfvars
# key_name と allowed_ssh_cidr を編集
terraform init
terraform apply
```

主な変数（`variables.tf`）は次の通りです。

- `region` / `availability_zone`: デフォルトは東京リージョン
- `vpc_cidr` / `public_subnet_cidr`: VPC とサブネットの CIDR
- `instance_type`: 既定 `t4g.small`（個人利用なら `t4g.micro` でも十分。コストを優先したいときに切り替え）
- `key_name`: 事前に作成済みの EC2 キーペア名
- `allowed_ssh_cidr`: 自宅の `/32` を指定
- `enable_stun`: 組み込み DERP を使う場合に `true`

apply 後、`terraform output public_ip` で Elastic IP を確認し、DNS の A レコード（例: `hs.example.com`）をその IP へ向けます。

## Ansible: Headscale + Caddy のセットアップ

EC2 でも自宅サーバでも同じ Playbook が使えます。Ubuntu 24.04 を前提とし、

- Headscale の DEB をダウンロード・インストール
- `/etc/headscale/config.yaml` をテンプレートから配置
- 初期 ACL ファイル（全許可、後で絞り込み）を配置
- `headscale configtest` で構文検証
- Caddy をインストールし、`Caddyfile` を配置
- 初期ユーザーを作成

までを行います。

### Ansible のインストール

Ubuntu の apt で入る `ansible 2.10` 系は古く、Python 3.12 が動くターゲット（Ubuntu 24.04）では
`No module named 'ansible.module_utils.six.moves'` のような互換性エラーが出ます。
**pipx で最新の ansible-core を入れる** のが確実です。

```bash
sudo apt remove --purge -y ansible ansible-core 2>/dev/null || true
sudo apt install -y pipx python3-venv
pipx ensurepath
source ~/.bashrc

pipx install --include-deps ansible

ansible --version
# ansible [core 2.16.x] 以上 が表示されることを確認
```

### 実行

```bash
cd iac/ansible
cp inventory.example.ini inventory.ini
cp group_vars/all.yml.example group_vars/all.yml
# inventory.ini と group_vars/all.yml を編集

# 接続テスト（pong が返ればOK）
ansible -i inventory.ini headscale -m ping

ansible-playbook -i inventory.ini playbook.yml
```

`group_vars/all.yml` で設定する主な変数は次の通りです。

- `headscale_server_url`: クライアントが接続する URL（例: `https://hs.example.com`）
- `headscale_base_domain`: MagicDNS のベースドメイン（`server_url` のドメインとは別にする）
- `caddy_admin_email`: Let's Encrypt の連絡先
- `headscale_users`: 初期作成するユーザー名のリスト
- `headscale_arch`: `arm64`（AWS `t4g.*` や Raspberry Pi）または `amd64`

# 運用

## ACL ポリシー

`policy.mode: file` の場合、`/etc/headscale/acl.hujson` を編集することでアクセス制御を行います。
最小構成として「同一ユーザーのデバイス間のみ通信可」とする例です。

```json
{
  "acls": [
    { "action": "accept", "src": ["alice"], "dst": ["alice:*"] }
  ]
}
```

ACL 構文は Tailscale の ACL とほぼ互換で、グループ・タグ・ユーザー単位で細かく制御できます [^acl]。
編集後は `sudo headscale policy check --file /etc/headscale/acl.hujson` で検証してから、サービスを再読み込みします。

## バックアップ

最低限バックアップすべき対象は次の 3 つです。

- `/var/lib/headscale/db.sqlite`: ノード・ユーザー・鍵などの実体
- `/var/lib/headscale/noise_private.key`: ノイズプロトコルの秘密鍵（**紛失すると全クライアントの再登録が必要**）
- `/etc/headscale/`: 設定一式と ACL

cron で日次に固める例です。

```bash
sudo tar czf /var/backups/headscale-$(date +%F).tgz \
  /etc/headscale /var/lib/headscale
```

S3 や別ホストへ rsync する仕組みと併用するとより安全です。

## アップデート

DEB パッケージを上書きインストールするだけで完了します。

```bash
sudo systemctl stop headscale
sudo apt install ./headscale_<NEW_VERSION>_linux_arm64.deb
sudo headscale configtest
sudo systemctl start headscale
```

マイナーバージョンを跨ぐ場合は、必ず CHANGELOG を確認してください。
v0.28.0 のように、PreAuthKey の保存形式変更（bcrypt 化）など破壊的変更が入ることがあります [^release]。

## ログとトラブルシュート

サーバ側のログは journald で確認します。

```bash
sudo journalctl -u headscale -f
sudo journalctl -u caddy -f
```

つながらないときの典型的なチェックリストは次の通りです。

- DNS が EIP / 自宅の IP を正しく指しているか
- セキュリティグループ（あるいはルータ）で 443/tcp が開いているか
- Caddy が証明書を取得できているか（80/tcp が空いているかどうかが ACME 取得に効きます）
- `headscale nodes list` でノードが登録されているか
- クライアント側の `tailscale status` でコントロールプレーンへの接続状況を確認

# つまずきポイント集

実際に手順をなぞる過程で発生しやすいエラーをまとめておきます。

## Terraform: `unexpected state 'unavailable'`（サブネット作成）

```
Error: waiting for EC2 Subnet (subnet-xxxx) create:
  unexpected state 'unavailable', wanted target 'available'.
```

**原因**: `terraform.tfvars` の `availability_zone` が、AWS アカウントに割り当てられていない AZ を指している。
新規 AWS アカウントは `ap-northeast-1a` などが使えないことがあります。

**対応**: 「事前準備」の AZ 確認コマンドで使える AZ に書き換えて `terraform apply`。
すでに失敗したサブネットが残っている場合は `terraform state rm aws_subnet.public` で状態をクリアしてから再実行します。

## Terraform: `InvalidKeyPair.NotFound`

```
Error: ... api error InvalidKeyPair.NotFound: The key pair 'xxx' does not exist
```

**原因**: `key_name` の値が AWS に登録済みのキーペア名と一致していない。

**対応**: `aws ec2 describe-key-pairs --query "KeyPairs[].KeyName"` で確認し、`terraform.tfvars` の `key_name` を実在する名前に修正。

## DNS: パーキング用 IP（`150.95.x.x`）が返る

**原因**: お名前.com の場合、NS が `dns1/dns2.onamae.com`（パーキング用）のままになっている。

**対応**: 上述の「お名前.com で運用する場合」の手順で、NS を `01.dnsv.jp` 〜 `04.dnsv.jp` に切り替え、A レコードを再設定。

## Ansible: `No module named 'ansible.module_utils.six.moves'`

**原因**: ローカル Ansible のバージョンが古く（2.10 系等）、ターゲット側の Python 3.12 と互換性がない。

**対応**: 上述の「Ansible のインストール」に従って pipx で最新版を入れ替え。

## Ansible: `headscale configtest` が `acl.hujson` 不在で失敗

**原因**: 設定で `policy.mode: file` を有効にしているが、ACL ファイル本体を配置していない。

**対応**: 本稿の Ansible ロールには ACL テンプレート（`templates/acl.hujson.j2`）を含めてあるので、ロールを最新化してから再実行してください。手動セットアップの場合は次のようなファイルを `/etc/headscale/acl.hujson` に置きます。

```json
{
  "acls": [
    { "action": "accept", "src": ["*"], "dst": ["*:*"] }
  ]
}
```

## v0.28.0 以降: `preauthkeys create -u <ユーザー名>` が失敗

```
Error: invalid argument "alice" for "-u, --user" flag:
  strconv.ParseUint: parsing "alice": invalid syntax
```

**原因**: v0.28.0 で `preauthkeys` コマンドの `--user` がユーザー名から **ユーザー ID 指定** に変わった。

**対応**: `headscale users list` で ID を確認してから渡す。

```bash
sudo headscale users list           # ID を確認
sudo headscale preauthkeys create --user 1 --reusable --expiration 24h
```

# おわりに

本稿では、個人利用を想定して Headscale を AWS EC2 と自宅 Linux サーバの 2 通りで運用するための具体的な手順をまとめ、Terraform と Ansible による自動化の足場も用意しました。
EC2 構成は前提が単純で `t4g.small` でも快適に動きます。
自宅サーバ構成は ISP 環境次第で構成が分かれますが、CGNAT 配下でも安価な VPS を踏み台として使えば現実的に運用できます。
セルフホスト Tailscale を起点に、自宅とクラウド、外出先の端末をひとつの仮想ネットワークでつなぐ運用は、個人の学習用途としても実用上もよい題材だと感じます。

# 参考

- [^scope]: Headscale 公式ドキュメント, [Headscale][headscale]
- [^release]: Headscale v0.28.0 リリースノート, <https://github.com/juanfont/headscale/releases>
- [^install]: 公式インストールガイド, <https://headscale.net/stable/setup/install/official/>
- [^reverse-proxy]: 公式リバースプロキシリファレンス, <https://headscale.net/stable/ref/integration/reverse-proxy/>
- [^db]: 公式設定リファレンス, <https://headscale.net/stable/ref/configuration/>
- [^connect]: クライアント接続ガイド, <https://headscale.net/stable/usage/>
- [^cli]: Tailscale CLI リファレンス, <https://tailscale.com/kb/1080/cli>
- [^acl]: ACL 構文の解説, <https://tailscale.com/kb/1018/acls>

[tailscale]: https://tailscale.com/
[tailscale-download]: https://tailscale.com/download
[headscale]: https://headscale.net/stable/
[onamae-navi]: https://navi.onamae.com/
[iac-source]: https://github.com/dobachi/headscale-iac-sample

<!-- vim: set et tw=0 ts=2 sw=2: -->
