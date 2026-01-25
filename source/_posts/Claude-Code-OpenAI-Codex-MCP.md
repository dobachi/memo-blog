---
title: Claude CodeからOpenAI Codexを使う方法 - MCPで実現するマルチAI開発環境
date: 2026-01-25 19:12:20
categories:
  - AI
  - 開発環境
tags:
  - Claude Code
  - OpenAI
  - Codex
  - MCP
  - AI開発
---

Claude CodeとOpenAI Codexは、それぞれ異なる特性を持つ優れたコーディング支援AIである。
両者を組み合わせることで、各モデルの得意分野を活かしたマルチAI開発環境を構築できる。
本記事では、Model Context Protocol（MCP）を使用してClaude CodeからOpenAI Codexを呼び出す方法を解説する。

<!-- more -->

# はじめに

## Claude CodeとOpenAI Codexの位置づけ

Claude Codeは、Anthropic社が提供するターミナルベースのコーディングエージェントである。
深い文脈理解と長文対応に優れ、複雑なリファクタリングやコードレビューに強みを持つ。

一方、OpenAI Codexは、OpenAI社が提供するコーディング支援システムであり、最新のGPT-5.2-Codexモデルを搭載している。
高速なコード生成と幅広い言語サポートが特徴である。

## 両方を使いたいユースケース

異なるAIモデルには、それぞれ得意分野がある。例えば：

- **Claude Code**: 長いコンテキストの理解、複雑なリファクタリング、コードレビュー
- **OpenAI Codex**: 定型的なコード生成、APIドキュメントからの実装、特定言語での最適化

これらを状況に応じて使い分けることで、開発効率を向上させることができる。

## MCPによる連携の概要

Model Context Protocol（MCP）は、AIアシスタント間でツールやコンテキストを共有するための標準プロトコルである。
MCPサーバーを介することで、Claude CodeからOpenAI Codexの機能を呼び出すことが可能になる。

# 前提条件

本記事の手順を実行するには、以下の環境が必要である。

- **Claude Code**: インストール済みの環境
- **Node.js環境**: npm/npxが利用可能なこと
- **Python環境**: 3.12以上（openai-codex-mcp使用時）
- **OpenAI API**: APIキーまたはChatGPTアカウント（Plus以上）

# Codex CLIのセットアップ

まず、OpenAI Codex CLIをセットアップする。

## インストール方法

npmを使用してグローバルインストールする。

```bash
npm install -g @openai/codex
```

または、Homebrewを使用する場合（macOS）:

```bash
brew install openai-codex
```

## 認証設定

### APIキーを使用する場合

環境変数にAPIキーを設定する。

```bash
export OPENAI_API_KEY="sk-..."
```

### ChatGPTアカウントを使用する場合

初回起動時にブラウザ認証を行う。

```bash
codex auth login
```

## 動作確認

正常にセットアップできたか確認する。

```bash
codex --version
codex "Hello, world"
```

# 方法1: codex-mcp-server（Node.js版）

[codex-mcp-server] は、Node.jsで実装されたシンプルなMCPサーバーである。

## 特徴と利点

- **シンプルなセットアップ**: npxで即座に起動可能
- **セッション管理**: 対話履歴を保持したセッション機能
- **コードレビュー**: ファイルの自動レビュー機能

## セットアップ手順

Claude Codeの設定ファイル（`~/.claude.json`または`~/.config/claude/settings.json`）に以下を追加する。

```json
{
  "mcpServers": {
    "codex": {
      "command": "npx",
      "args": ["-y", "codex-mcp-server"],
      "env": {
        "OPENAI_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

## 提供ツール一覧

codex-mcp-serverは以下のツールを提供する。

| ツール名 | 説明 |
|---------|------|
| `codex_ask` | Codexにコーディング質問を送信 |
| `codex_session` | セッション付きの対話を実行 |
| `codex_review` | コードファイルのレビューを実行 |

## 使用例

Claude Code内でCodexを呼び出す例を示す。

```
# Codexにコーディング質問
「codex_askツールを使って、Pythonでフィボナッチ数列を生成する関数について質問して」

# コードレビュー
「codex_reviewツールでsrc/main.pyをレビューして」
```

# 方法2: openai-codex-mcp（Python版）

[openai-codex-mcp] は、Python製のより多機能なMCPサーバーである。

## 特徴と利点

- **専用メソッド**: write_code、explain_code、debug_codeなどの特化型ツール
- **モデル選択**: o3、o4-mini、gpt-4.1など複数モデルから選択可能
- **柔軟な設定**: 詳細なパラメータ調整が可能

## セットアップ手順

### uvを使用する場合（推奨）

```json
{
  "mcpServers": {
    "openai-codex": {
      "command": "uvx",
      "args": ["openai-codex-mcp"],
      "env": {
        "OPENAI_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

### pipを使用する場合

```bash
pip install openai-codex-mcp
```

```json
{
  "mcpServers": {
    "openai-codex": {
      "command": "python",
      "args": ["-m", "openai_codex_mcp"],
      "env": {
        "OPENAI_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

## 専用メソッド

openai-codex-mcpは以下の専用メソッドを提供する。

| メソッド名 | 説明 |
|-----------|------|
| `write_code` | 指定した要件に基づいてコードを生成 |
| `explain_code` | コードの詳細な説明を生成 |
| `debug_code` | コードの問題を分析し修正案を提示 |
| `refactor_code` | コードのリファクタリング提案を生成 |
| `ask_codex` | 自由形式の質問を送信 |

## 使用例

```
# コード生成
「write_codeツールを使って、REST APIのCRUDエンドポイントを生成して」

# デバッグ支援
「debug_codeツールでこのエラーの原因を分析して」
```

# 両者の比較と使い分け

## 機能比較表

| 項目 | codex-mcp-server | openai-codex-mcp |
|------|------------------|------------------|
| 言語 | Node.js | Python |
| セットアップ | 1コマンド | 数ステップ |
| 機能数 | 少（3ツール） | 多（5ツール以上） |
| セッション管理 | あり | なし |
| モデル選択 | なし | あり |
| 依存関係 | npm/npxのみ | Python 3.12以上 |

## 適切な選択基準

- **素早く試したい場合**: codex-mcp-server
- **多機能が必要な場合**: openai-codex-mcp
- **Node.js環境のみの場合**: codex-mcp-server
- **モデルを切り替えたい場合**: openai-codex-mcp

# ユースケースと活用Tips

## 効果的な使い分け例

### シナリオ1: 大規模リファクタリング

1. Claude Codeでコードベース全体を分析
2. リファクタリング計画をClaude Codeで立案
3. 個別の関数変換をCodexで高速に実行
4. 最終レビューをClaude Codeで実施

### シナリオ2: 新機能開発

1. Codexで定型的なボイラープレートを生成
2. Claude Codeでビジネスロジックを実装
3. Codexでテストコードを生成
4. Claude Codeで統合テストを確認

## 注意点

### APIコストについて

- 各AIサービスには個別の料金が発生する
- 使用量を監視し、予算を設定することを推奨
- 開発用途では、低コストモデル（o4-miniなど）の活用を検討

### レート制限

- 各サービスにはレート制限がある
- 連続した大量リクエストは避ける
- エラーハンドリングを適切に設定する

# まとめ

MCPを活用することで、Claude CodeとOpenAI Codexを組み合わせたマルチAI開発環境を構築できる。
各モデルの特性を理解し、適材適所で使い分けることで、開発効率を向上させることが可能である。

今後、MCPエコシステムの発展により、さらに多くのAIサービスとの連携が容易になることが期待される。

# 参考

* [OpenAI Codex公式]
* [Codex CLI GitHub]
* [codex-mcp-server]
* [openai-codex-mcp]

[OpenAI Codex公式]: https://openai.com/codex/
[Codex CLI GitHub]: https://github.com/openai/codex
[codex-mcp-server]: https://github.com/tuannvm/codex-mcp-server
[openai-codex-mcp]: https://github.com/agency-ai-solutions/openai-codex-mcp

<!-- vim: set et tw=0 ts=2 sw=2: -->
