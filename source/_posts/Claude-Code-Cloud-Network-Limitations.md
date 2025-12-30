---

title: Claude Code クラウド環境のネットワーク制限と対処法
date: 2025-12-30 18:00:00
categories:
  - AI
  - Claude
tags:
  - Claude Code
  - Network
  - Proxy
  - Troubleshooting

---

# 概要

Claude Code on the web（クラウド環境）では、セキュリティのためネットワークアクセスに制限がある。
本記事では、スマホアプリ版のClaude Codeで作業しようとした際に遭遇した問題とその解決策を解説する。

# 環境構成

Claude Codeクラウド環境は以下の構成で動作している。

| 項目 | 設定 |
|------|------|
| ネットワーク | HTTPプロキシ経由（JWT認証付き） |
| DNS | `/etc/resolv.conf` が空（DNSサーバー未設定） |
| 許可ホスト | ホワイトリスト方式（開発ツール関連サイト） |

# 問題1: apt updateが失敗する

## 症状

```
W: Failed to fetch http://archive.ubuntu.com/ubuntu/dists/noble/InRelease
   Temporary failure resolving 'archive.ubuntu.com'
```

## 原因

- `/etc/resolv.conf` が空でDNSサーバーが設定されていない
- aptがプロキシを使用する設定になっていない

## 診断コマンド

```bash
# DNS設定確認
cat /etc/resolv.conf

# プロキシ環境変数確認
env | grep -i proxy

# curlの接続先確認（プロキシ経由か直接か）
curl -v http://archive.ubuntu.com 2>&1 | grep -E "Connected|Trying"
```

## 解決策

プロキシ環境変数からaptの設定を作成する。

```bash
# プロキシURLを取得
printenv http_proxy > /tmp/proxy_url.txt

# apt用プロキシ設定を作成
sudo bash -c 'cat > /etc/apt/apt.conf.d/proxy.conf << EOF
Acquire::http::Proxy "$(cat /tmp/proxy_url.txt)";
Acquire::https::Proxy "$(cat /tmp/proxy_url.txt)";
EOF'

# 動作確認
sudo apt update
```

**ポイント**: プロキシURLにはJWT認証トークンが含まれているため、完全なURLを使用する必要がある。

# 問題2: GitHubリリースのダウンロードが403エラー

## 症状

```bash
$ curl -L "https://github.com/quarto-dev/quarto-cli/releases/download/v1.4.549/quarto-1.4.549-linux-amd64.deb"
curl: (56) CONNECT tunnel failed, response 403
```

## 原因

GitHubリリースはCDN（`objects.githubusercontent.com`等）にリダイレクトされるが、
リダイレクト先がホワイトリストに含まれていない場合がある。

## 解決策: conda-forge経由でインストール

```bash
# Minicondaをダウンロード（repo.anaconda.comは許可されている）
curl -sL "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" \
  -o /tmp/miniconda.sh

# インストール
bash /tmp/miniconda.sh -b -p $HOME/miniconda3

# 利用規約に同意
$HOME/miniconda3/bin/conda tos accept --override-channels \
  --channel https://repo.anaconda.com/pkgs/main
$HOME/miniconda3/bin/conda tos accept --override-channels \
  --channel https://repo.anaconda.com/pkgs/r

# conda-forgeからQuartoをインストール
$HOME/miniconda3/bin/conda install -y -c conda-forge quarto
```

# 問題3: 外部サイト（zotero.org等）へのアクセスがブロック

## 症状

```
Could not fetch https://www.zotero.org/styles/ieee
ProxyConnectException "www.zotero.org" 443 (Status {statusCode = 403})
```

## 原因

ホワイトリストに含まれていないホストへのアクセスは403 Forbiddenで拒否される。

## 解決策: ローカルファイルを使用

```bash
# GitHubのraw.githubusercontent.comは許可されている
curl -sL "https://raw.githubusercontent.com/citation-style-language/styles/master/ieee.csl" \
  -o sources/references/ieee.csl

# 設定ファイルをローカル参照に変更
# csl: https://www.zotero.org/styles/ieee
#   ↓
# csl: ../sources/references/ieee.csl
```

# 許可されている主要ホスト

プロキシのJWTトークンに含まれる`allowed_hosts`から抜粋。

| カテゴリ | ホスト |
|----------|--------|
| パッケージ管理 | `pypi.org`, `registry.npmjs.org`, `repo.anaconda.com`, `conda.anaconda.org` |
| GitHub | `github.com`, `api.github.com`, `raw.githubusercontent.com`, `gist.github.com` |
| Ubuntu | `*.ubuntu.com`, `archive.ubuntu.com`, `security.ubuntu.com` |
| その他開発ツール | `crates.io`, `rubygems.org`, `golang.org`, `hub.docker.com` |

# conda-forge版Quartoの追加設定

conda-forgeからインストールしたQuartoは、パス設定に追加作業が必要な場合がある。

```bash
# QUARTO_SHARE_PATHを設定
export QUARTO_SHARE_PATH=$HOME/miniconda3/share/quarto

# ビルド実行
$HOME/miniconda3/bin/quarto render report.qmd --to html
```

# まとめ

| 問題 | 解決策 |
|------|--------|
| apt失敗 | プロキシ設定を`/etc/apt/apt.conf.d/proxy.conf`に追加 |
| GitHubリリースのブロック | conda-forge経由でインストール |
| 外部サイトのブロック | GitHubのraw URLからダウンロードしてローカル参照 |

## 推奨ワークフロー

1. **開発・プレビュー**: ローカル環境で実施（ネットワーク制限なし）
2. **ビルド・品質チェック**: クラウド環境で実施（上記対策を適用）
3. **外部依存ファイル**: 事前にローカルにダウンロードしてリポジトリに含める

# 参考

- [Claude Code]
- [Anthropic公式ドキュメント]

[Claude Code]: https://claude.ai/code
[Anthropic公式ドキュメント]: https://docs.anthropic.com/



<!-- vim: set et tw=0 ts=2 sw=2: -->
