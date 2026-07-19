---
title: Claude Codeのカスタムコマンド入門
date: 2025-07-26 23:45:03
categories:
  - AI開発
  - Claude Code
tags:
  - Claude Code
  - カスタムコマンド
  - 開発効率化
  - AI
---

Claude Codeでは、カスタムコマンド（スラッシュコマンド）を作成して、よく使う操作を効率化できます。この記事では、カスタムコマンドの基本から実践的な活用方法まで解説します。

<!-- more -->

## はじめに

Claude Codeは、Anthropic社が提供するAI駆動の開発支援ツールです。その中でも特に便利な機能の一つが「カスタムコマンド」です。スラッシュコマンドとして使えるこの機能により、繰り返し行う作業を簡単に自動化できます。

## カスタムコマンドとは

カスタムコマンドは、Markdownファイルとして定義される再利用可能なプロンプトです。`/`で始まるコマンドとして実行でき、以下のような特徴があります：

- 簡単な作成：Markdownファイルを作るだけ
- 柔軟な拡張：引数、Bashコマンド、ファイル参照に対応
- スコープ管理：プロジェクト単位またはユーザー単位で管理可能

## 基本的な使い方

### 1. ディレクトリ構成

カスタムコマンドは以下の場所に保存します：

```
プロジェクト単位: .claude/commands/
ユーザー単位:     ~/.claude/commands/
```

### 2. シンプルなコマンドの作成

最も基本的なコマンドの例です：

```bash
# ディレクトリ作成
mkdir -p .claude/commands

# コマンドファイル作成
echo 'すべてのテストを実行して結果を報告してください。' > .claude/commands/test.md
```

使用方法：
```
/test
```

### 3. 引数を使ったコマンド

`$ARGUMENTS`を使って引数を受け取れます：

```bash
echo 'Issue #$ARGUMENTS を修正してください。' > .claude/commands/fix-issue.md
```

使用方法：
```
/fix-issue 123
```

## 高度な機能

### 1. Bashコマンドの実行

`!`記号を使ってBashコマンドを実行し、その結果を含められます：

```markdown
現在のブランチ: !`git branch --show-current`
変更ファイル: !`git status --porcelain`

上記の変更内容を確認してコミットメッセージを提案してください。
```

### 2. ファイル参照

`@`記号でファイルの内容を参照できます：

```markdown
@src/main.js のコードをレビューしてください。
特に以下の点に注目：
- エラーハンドリング
- パフォーマンス
- セキュリティ
```

### 3. frontmatterによる詳細設定

より高度な設定が必要な場合は、frontmatterを使用します：

```markdown
---
description: プルリクエスト作成支援
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(gh pr create:*)
---

## 現在の状況
- ブランチ: !`git branch --show-current`
- 差分: !`git diff --staged`

## タスク
1. 変更内容を確認
2. 適切なコミットメッセージを作成
3. プルリクエストを作成
```

## 実践的な活用例

### Hexoブログ用カスタムコマンド

このブログ（Hexo製）で実際に使っているコマンドを紹介します。

#### 1. 新規記事作成（`.claude/commands/new-post.md`）

```markdown
---
description: Hexoブログの新規記事を作成
allowed-tools: Bash(hexo new post:*), Read(*), Write(*)
---

Create a new Hexo blog post with the title "$ARGUMENTS".

Include:
- Proper frontmatter with title, date, tags, and categories
- A compelling introduction
- Well-structured sections
- Place for images if needed
- Summary at the end

Current posts for reference: !`ls -la source/_posts/ | tail -5`
```

#### 2. ビルド＆プレビュー（`.claude/commands/preview.md`）

```markdown
---
description: Hexoサイトをビルドしてプレビュー
---

Clean build the Hexo site and start the local preview server.

Steps:
1. Clean previous build: !`hexo clean`
2. Generate static files: !`hexo generate`
3. Start server: !`hexo server`

Show the local URL and any build warnings.
```

#### 3. 記事レビュー（`.claude/commands/review-post.md`）

```markdown
---
description: 記事のレビューと改善提案
---

Review the blog post @$ARGUMENTS and provide feedback on:

1. **Content Quality**
   - Is the information accurate and complete?
   - Are examples clear and practical?
   - Is the flow logical?

2. **Technical Accuracy**
   - Code examples correctness
   - Command syntax validation
   - Best practices adherence

3. **SEO & Readability**
   - Title effectiveness
   - Meta description suggestions
   - Heading structure
   - Keyword usage

4. **Improvements**
   - Missing sections
   - Additional examples needed
   - Visual elements to add

Provide specific, actionable feedback.
```

#### 4. 画像最適化（`.claude/commands/optimize-images.md`）

```markdown
---
description: 記事内の画像を最適化
allowed-tools: Bash(find:*), Bash(identify:*), Bash(convert:*)
---

Find and optimize images for the blog post "$ARGUMENTS".

Tasks:
1. List all images in source/images/: !`find source/images/ -name "*$ARGUMENTS*" -type f`
2. Check image sizes and formats
3. Suggest optimizations:
   - Convert PNG to JPG where appropriate
   - Resize images larger than 1200px width
   - Compress without losing quality
   - Generate WebP versions

Provide commands to optimize each image.
```

## ベストプラクティス

### 1. 命名規則

- わかりやすい名前を使う
- ハイフンで単語を区切る（`fix-issue.md`）
- 動詞から始める（`create-`, `review-`, `test-`）

### 2. ディレクトリ構成

カテゴリごとにサブディレクトリを作成：

```
.claude/commands/
├── git/
│   ├── commit.md
│   └── pr.md
├── test/
│   ├── unit.md
│   └── integration.md
└── docs/
    ├── generate.md
    └── review.md
```

### 3. バージョン管理

`.claude/commands/`をGitリポジトリに含めることで：
- チーム全体でコマンドを共有
- コマンドの変更履歴を追跡
- プロジェクト固有の作業フローを標準化

### 4. セキュリティ考慮事項

- センシティブな情報をコマンドに含めない
- `allowed-tools`で許可するツールを制限
- 外部コマンドの実行は慎重に

## トラブルシューティング

### コマンドが認識されない

1. ファイルパスを確認：`.claude/commands/`に配置されているか
2. ファイル拡張子：`.md`で終わっているか
3. Claude Codeを再起動してみる

### 引数が渡されない

- `$ARGUMENTS`のスペルを確認
- 引数に空白が含まれる場合は引用符で囲む

### Bashコマンドが実行されない

- バッククォートで囲まれているか確認：`` !`command` ``
- コマンドの権限を確認

## まとめ

Claude Codeのカスタムコマンドは、開発ワークフローを大幅に効率化できる強力な機能です。基本的なテキストコマンドから、Bashコマンドやファイル参照を組み合わせた高度なコマンドまで、様々な用途に対応できます。

プロジェクトの特性に合わせてカスタムコマンドを作成し、チームで共有することで、一貫性のある効率的な開発環境を構築できるでしょう。

## 参考リンク

- [Claude Code公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [Anthropic公式サイト](https://www.anthropic.com/)

<!-- vim: set et tw=0 ts=2 sw=2: -->