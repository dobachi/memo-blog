---

title: Claude Code Setup
date: 2025-01-25 00:00:00
categories:
  - Knowledge Management
  - AI
  - Claude Code
tags:
  - AI
  - Claude Code
  - CLI

---

# メモ

Claude CodeのCLI版をセットアップするメモ。
以前はnpmでインストールしていたが、ネイティブインストールに切り替えた。

## システム要件

[Set up Claude Code] によると、以下の要件がある。

* **OS**: macOS 13.0+、Ubuntu 20.04+/Debian 10+、Windows 10+ (WSL 1、WSL 2、またはGit for Windows)
* **ハードウェア**: 4 GB以上のRAM
* **ネットワーク**: インターネット接続が必要
* **シェル**: BashまたはZshが推奨

なお、ネイティブインストールの場合はNode.jsは不要。npmインストール（非推奨）の場合のみNode.js 18以上が必要。

## ネイティブインストール（推奨）

現在はネイティブインストールが推奨されている。
Ubuntu/Linux/WSLの場合、以下のコマンドでインストールする。

```bash
$ curl -fsSL https://claude.ai/install.sh | bash
```

ネイティブインストールの場合、バックグラウンドで自動更新されるため、常に最新バージョンが利用可能。

### 既存のnpmインストールからの移行

既存のnpmインストールからネイティブインストールへ移行するには、以下のコマンドを実行する。

```bash
$ claude install
```

## npmインストール（非推奨）

npmインストールは非推奨となっている。
可能な限りネイティブインストールを使用すること。

```bash
$ npm install -g @anthropic-ai/claude-code
```

注意: `sudo npm install -g` は使用しないこと。パーミッションの問題やセキュリティリスクにつながる可能性がある。

## インストール後の確認

インストール後、以下のコマンドでインストールの種類とバージョンを確認できる。

```bash
$ claude doctor
```

### PATHの問題

`command not found: claude` というエラーが出る場合は、PATHに追加する。

```bash
$ echo 'export PATH="$HOME/.claude/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
$ source ~/.bashrc
```

## 認証

### 個人利用の場合

1. **Claude ProまたはMaxプラン（推奨）**: [Claude's Pro or Max plan] でサブスクライブし、Claude.aiアカウントでログイン
2. **Claude Console**: [Claude Console] からOAuthプロセスを完了。Anthropic Consoleでのアクティブな請求が必要

### チーム・組織での利用

1. **Claude for Teams または Enterprise（推奨）**: 一元化された請求とチーム管理
2. **Claude Console with team billing**: 共有組織を設定
3. **クラウドプロバイダ**: Amazon Bedrock、Google Vertex AI、Microsoft Foundryを使用

## アンインストール

### ネイティブインストールの場合

```bash
$ rm -f ~/.local/bin/claude
$ rm -rf ~/.local/share/claude
```

### npmインストールの場合

```bash
$ npm uninstall -g @anthropic-ai/claude-code
```

### 設定ファイルのクリーンアップ（オプション）

```bash
$ rm -rf ~/.claude
$ rm ~/.claude.json
```

注意: これにより全ての設定、許可されたツール、MCPサーバー設定、セッション履歴が削除される。

# 参考

* [Set up Claude Code]
* [Claude's Pro or Max plan]
* [Claude Console]
* [@anthropic-ai/claude-code - npm]

[Set up Claude Code]: https://code.claude.com/docs/en/setup
[Claude's Pro or Max plan]: https://claude.ai/pricing
[Claude Console]: https://console.anthropic.com
[@anthropic-ai/claude-code - npm]: https://www.npmjs.com/package/@anthropic-ai/claude-code


<!-- vim: set et tw=0 ts=2 sw=2: -->
