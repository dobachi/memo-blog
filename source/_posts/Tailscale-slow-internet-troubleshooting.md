---
title: Tailscale 使用時にインターネットが遅くなるときの切り分け（Exit Node / DNS / Direct 接続）
date: 2026-05-24 17:39:46
categories:
  - Networking
tags:
  - Tailscale
  - WireGuard
  - VPN
  - DNS
  - Troubleshooting
---

# メモ

Tailscale をオンにしてからインターネットが遅い、と感じたときに最初に確認したい3点をまとめる。  
原因の大半は次のいずれかに収まる。

1. **Exit Node（出口ノード）が有効になっている** — すべての通信が他ノード経由になり、当然遅くなる
2. **Tailscale の DNS 設定が悪さをしている** — DNS 解決でつまずく
3. **P2P の直接接続が確立できておらず DERP リレー経由になっている** — 中継サーバ経由なので遅い

関連: [[Headscale を自宅サーバまたは AWS EC2 で運用する]](/2026/05/06/Headscale-Self-Hosting/)

## 環境

- クライアント: Windows / macOS / Linux / iOS / Android いずれも考え方は同じ
- 確認に使うコマンド: `tailscale status`, `tailscale netcheck`

# 1. Exit Node を無効化する

Tailscale の Exit Node 機能を有効にしていると、Web 閲覧を含む**すべてのインターネット通信**が指定ノード経由でルーティングされる。出口ノードの回線品質や物理的距離に律速されるため、通常は明確に遅くなる。

確認と解除:

- GUI クライアント: トレイ／メニューバーの Tailscale アイコンから **Exit node → None**
- CLI:

```bash
# 現在の Exit Node を解除
tailscale up --exit-node=

# 状態確認（"exit node" の行が消えていればOK）
tailscale status
```

ローカル LAN のリソースに Tailscale でアクセスしたいだけなら、Exit Node はオフのままで良い。

# 2. Tailscale の DNS 設定を見直す

`MagicDNS` や Admin Console の `Nameservers` 設定により、OS の DNS が Tailscale 管理下に置き換わっていることがある。  
社内 DNS や ISP の DNS との解決順序がずれて、名前解決でタイムアウト気味になっているケースが多い。

切り分け手順:

1. クライアント設定で **Use Tailscale DNS settings**（または `Override local DNS`）をいったんオフにする
2. それでも遅い場合は OS 側の DNS を `8.8.8.8` / `1.1.1.1` などのパブリック DNS に固定して比較
3. 改善するなら、Admin Console の `DNS` 設定（カスタム Nameserver、Split DNS、Search Domains）を見直す

CLI でも確認できる:

```bash
tailscale dns status
```

恒久対策としては、社内 DNS が必要なドメインだけ **Split DNS** で個別に解決させ、それ以外は OS デフォルトに任せる構成が扱いやすい。

# 3. Direct 接続になっているかを確認する

Tailscale は本来 WireGuard ベースで P2P 直接接続するが、NAT 越えに失敗すると **DERP リレー**（Tailscale が運用する中継サーバ）経由にフォールバックする。リレー経由は帯域・レイテンシの両面で不利になる。

確認:

```bash
tailscale status
```

各ピアの行末に `direct <peer-ip>:<port>` と表示されれば直接接続。`relay "xxx"` と表示されているとリレー経由。

ネットワーク側の事情を見たい場合:

```bash
tailscale netcheck
```

`UPnP` / `PMP` / `PCP` の可否、最寄り DERP までの RTT、IPv4/IPv6 の到達性などが出る。

## DERP リレーから抜け出すための対処

ルーター側で次のいずれかを行う。

- **UPnP / NAT-PMP / PCP を有効にする** — クライアント側でポートを自動的に開ける
- **UDP 41641 を手動で開放（ポートフォワード）する** — Tailscale クライアントが直接接続要求を受けるための既定ポート
- **CGNAT 配下を疑う** — モバイル回線や一部 ISP では、どう設定しても直接接続できないことがある。この場合は割り切るか、片側をグローバル IP のある拠点に置く

両側のクライアントがどちらも対称 NAT 配下にいると、UPnP を入れても直接接続できないことがある。`netcheck` の `NAT mapping` 行で `hard NAT` と出ているなら、ルーター買い替えやネットワーク構成見直しが必要になる。

# 切り分けのまとめ

| 症状 | まず疑うもの | 確認コマンド |
| --- | --- | --- |
| Web 全体が遅い | Exit Node が有効 | `tailscale status` の `exit node` 行 |
| ページ表示が引っかかる、名前解決が遅い | DNS 設定の競合 | `tailscale dns status` |
| Tailscale 内通信だけ遅い／不安定 | DERP リレー経由 | `tailscale status` / `tailscale netcheck` |

最初の一手は **`tailscale status` と `tailscale netcheck` を見る**こと。これだけで上記3つのうちどれが効いているかはほぼ判別できる。

# 参考

- Tailscale 公式ドキュメント (KB): Exit Nodes / DNS / Connection Types / Firewall Ports
- `tailscale --help`, `tailscale status --help`, `tailscale netcheck --help`

<!-- vim: set et tw=0 ts=2 sw=2: -->
