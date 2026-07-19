---

title: Claude Code with Claude Code Web
date: 2026-01-09 12:00:00
categories:
  - AI
  - Tools
tags:
  - Claude Code
  - AI Coding Assistant

---

# メモ

Claude Code（CLI版）とClaude Code Web（クラウド版）を連携して使う方法。

## 認証

Max Plan / Pro Planあれば、`claude login`でブラウザ認証すればAPIキー不要で両方使える。

```bash
claude login
```

## モデル設定

環境変数で統一:

```bash
export ANTHROPIC_MODEL=opus
```

起動時に指定:

```bash
claude --model opus
```

セッション中に切り替え:

```
/model sonnet
```

モデルエイリアス:

| エイリアス | 用途 |
|-----------|------|
| default | アカウント種別に応じた推奨 |
| sonnet | 普段のコーディング |
| opus | 複雑な推論 |
| haiku | 軽いタスク |
| opusplan | 計画時Opus、実行時Sonnet |

## &でWebにタスク送信

先頭に`&`付けると新規Webセッション作ってバックグラウンドで動く。

```
& Fix the authentication bug in src/auth/login.ts
```

コマンドラインからも:

```bash
claude --remote "Fix the authentication bug"
```

### 流れ

```
ローカルCLI会話
    ↓
[& タスク指示]  → 新規Webセッション作成
    ↓
Webで自律実行（バックグラウンド）
    ↓
/tasks で監視 → 必要ならteleportでローカルに戻す
```

### 向いてるタスク

- バグ修正、テスト作成など明確なタスク
- 複数タスク同時進行
- 時間かかる処理

### 並列実行

```bash
& Fix the flaky test in auth.spec.ts
& Update the API documentation
& Refactor the logger module
```

それぞれ別のWebセッションで同時に動く。

## タスク確認

```
/tasks
```

一覧出て、`t`キーでテレポートできる。
[claude.ai/code]でも確認できる。

## &とteleportの違い

| 機能 | 方向 | 用途 |
|-----|------|------|
| `&` | CLI → Web | タスクをWebに送る |
| `/teleport` | Web → CLI | Webセッションをローカルに持ってくる |

## ワークフロー例

```bash
# 1. ローカルで計画
claude --permission-mode plan

# 2. Webで実行
& Execute the migration plan we discussed
```

計画はローカルでやって、実行はクラウドに任せる。

## 制限

- GitHubのみ（GitLab未対応）
- 既存セッション丸ごとWebに移すのは無理（新規作成のみ）
- 同じClaude.aiアカウントでログイン必要

# 参考

[claude.ai/code]: https://claude.ai/code
[Claude Code on the web]: https://code.claude.com/docs/en/claude-code-on-the-web.md
[Model configuration guide]: https://code.claude.com/docs/en/model-config.md
[CLI reference documentation]: https://code.claude.com/docs/en/cli-reference.md



<!-- vim: set et tw=0 ts=2 sw=2: -->
