---

title: Gemini with Claude Code
date: 2025-01-25 12:00:00
categories:
  - Knowledge Management
  - AI
  - Claude Code
tags:
  - AI
  - Claude Code
  - Gemini
  - MCP

---

# メモ

Claude CodeからGeminiを利用する方法についてのメモ。
MCPサーバーを使うことで、Claude CodeのセッションからGeminiの機能を呼び出すことができる。

主な選択肢として以下がある。

1. **gemini-mcp-tool**: Gemini CLIラッパー（大規模ファイル分析向け）
2. **mcp-gemini-cli**: シンプルなGemini CLIラッパー
3. **@rlabs-inc/gemini-mcp**: 多機能なGemini統合サーバー

## gemini-mcp-tool

[gemini-mcp-tool] はGemini CLIのMCPサーバーラッパー。
Geminiの大規模トークンウィンドウを活用し、大規模ファイル分析やコードベース理解に適している。

### 特徴

- Gemini CLIの大規模トークンウィンドウを活用
- サンドボックスでのコード実行に対応
- @構文によるファイル/ディレクトリ参照

### 提供機能

| ツール名 | 説明 |
|---------|------|
| ask-gemini | ファイル解析や一般的な質問への回答 |
| sandbox-test | Geminiのサンドボックスでコード/コマンドを安全に実行 |

スラッシュコマンドとして `/analyze`、`/sandbox`、`/help`、`/ping` も提供。

### インストール

前提として、Gemini CLIのインストールと認証を完了しておく必要がある。

Claude Codeでのセットアップ:

```bash
$ claude mcp add gemini-cli -- npx -y gemini-mcp-tool
```

または、設定ファイル（`~/.claude.json` など）に直接記述:

```json
{
  "mcpServers": {
    "gemini-cli": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "gemini-mcp-tool"
      ],
      "env": {}
    }
  }
}
```

### ユースケース

- 大規模なコードベースの分析
- `@largefile.js` のような構文でファイルを指定して解析
- サンドボックス環境でのコードテスト

## mcp-gemini-cli

[mcp-gemini-cli] はGemini CLIのシンプルなMCPサーバーラッパー。
[MCP Gemini CLI入門：Claude CodeとGeminiの連携でAIコーディングを強化する] に詳しい解説がある。

### 特徴

- シンプルな設計で3つの機能を提供
- Gemini CLIの認証を利用

### 提供機能

| ツール名 | 説明 |
|---------|------|
| googleSearch | Gemini経由でGoogle検索を実行 |
| chat | Geminiとの直接会話 |
| analyzeFile | 画像、PDF、テキストファイルの分析 |

### インストール

前提として、Gemini CLIの認証を完了しておく必要がある。

```bash
$ claude mcp add -s project gemini-cli -- npx @choplin/mcp-gemini-cli --allow-npx
```

### ユースケース

- 「Geminiに最新のNext.js 15の新機能を検索してもらって」
- 「Geminiにこのエラーメッセージの解決方法を聞いて」

## @rlabs-inc/gemini-mcp

[RLabs-Inc/gemini-mcp] はGemini 3モデルとの統合を提供する多機能なMCPサーバー。
30以上のツールを提供し、画像生成、動画生成、コード実行など幅広い機能が利用可能。

### 特徴

- 30以上のツールを提供
- Gemini API Keyを使用（無料で取得可能）
- 画像生成（最大4K）、動画生成（Veo 2.0）、TTSなど

### 主な機能

| カテゴリ | 機能 |
|---------|------|
| コンテンツ生成 | 画像生成、動画生成、TTS（30種類の音声） |
| Web統合 | リアルタイム検索、YouTube動画分析 |
| ドキュメント処理 | PDF/DOCX分析、テーブル抽出、要約 |
| コード実行 | Python実行（numpy, pandas, matplotlib対応） |
| AI推論 | Geminiへの直接クエリ、思考レベル調整 |

### インストール

[Google AI Studio] からGemini API Keyを取得し、以下のコマンドでインストール。

```bash
$ claude mcp add gemini -s user -- env GEMINI_API_KEY=YOUR_KEY npx -y @rlabs-inc/gemini-mcp
```

グローバルインストールの場合:

```bash
$ npm install -g @rlabs-inc/gemini-mcp
```

### 設定オプション

| 環境変数 | 説明 |
|---------|------|
| GEMINI_API_KEY | 必須。Google AI Studioで取得 |
| GEMINI_OUTPUT_DIR | 生成ファイルの保存先（デフォルト: ./gemini-output） |
| VERBOSE | 詳細ログの有効化 |

## どれを選ぶか

| 観点 | gemini-mcp-tool | mcp-gemini-cli | @rlabs-inc/gemini-mcp |
|------|-----------------|----------------|----------------------|
| 導入の手軽さ | ◎ | ◎ | ○ API Key取得が必要 |
| 機能数 | ○ 2機能+コマンド | △ 3機能 | ◎ 30+機能 |
| 用途 | 大規模ファイル分析、サンドボックス | 検索・対話・ファイル分析 | 画像/動画生成、コード実行など多目的 |
| 依存関係 | Gemini CLI | Gemini CLI | なし（API直接利用） |
| 特徴 | 大規模トークンウィンドウ活用 | シンプル | 多機能 |

- 大規模コードベースの分析には **gemini-mcp-tool**
- シンプルに検索や対話を追加したい場合は **mcp-gemini-cli**
- 多機能な統合が必要な場合は **@rlabs-inc/gemini-mcp**

# 参考

* [gemini-mcp-tool]
* [mcp-gemini-cli]
* [MCP Gemini CLI入門：Claude CodeとGeminiの連携でAIコーディングを強化する]
* [RLabs-Inc/gemini-mcp]
* [Google AI Studio]

[gemini-mcp-tool]: https://github.com/jamubc/gemini-mcp-tool
[mcp-gemini-cli]: https://github.com/choplin/mcp-gemini-cli
[MCP Gemini CLI入門：Claude CodeとGeminiの連携でAIコーディングを強化する]: https://zenn.dev/choplin/articles/2025-06-28-mcp-gemini-cli-intro
[RLabs-Inc/gemini-mcp]: https://github.com/RLabs-Inc/gemini-mcp
[Google AI Studio]: https://aistudio.google.com/


<!-- vim: set et tw=0 ts=2 sw=2: -->
