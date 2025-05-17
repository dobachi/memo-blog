---

title: GitHub Actionsを使ったレポジトリの同期（一方向）
date: 2025-05-18 01:17:00
tags:
- Knowledge Management
- GitHub
- GitHub Actions
categories:
- Technical
- Git

---

## 動機

これまで組織名を設けずにGitHubを使っていた。しかし、Notion AIのConnect機能を利用して、GitHub上のレポジトリ群を読み取らせようとしたところ、組織下のレポジトリしか参照できないようだった。そこで、新たに組織を作成し、元のレポジトリから新しく作成した組織下のレポジトリに同期するようにした。

なお、この手順は、同期先のレポジトリがもともと存在しないことを想定して書いてある。

## 手順: 同期先リポジトリの初期設定と同期プロセス

### 1. 同期先リポジトリを新規作成

GitHub上で同期先リポジトリを作成する（例: `組織名/リポジトリ名`）。

- **リポジトリの設定**:
    - 空のリポジトリとして作成（`README.md` や `.gitignore` は追加しない）。
    - 必要に応じて「Write Access」のあるユーザーやDeploy Keyを設定。

### 2. ローカル環境での初期設定

ローカル環境を使って、同期元リポジトリから同期先リポジトリへ初期データを移行する。

### (1) 同期先リポジトリをクローン

ローカル環境に同期先リポジトリをクローンする。

```bash
git clone git@github.com:組織名/リポジトリ名.git
cd リポジトリ名
```

### (2) masterブランチを作成

新規作成したリポジトリにはブランチが存在しないため、`master` ブランチを作成する。

```bash
git checkout -b master
```

### (3) 同期元リポジトリをリモートとして追加

同期元リポジトリ（例: `ユーザー名/リポジトリ名`）をリモートとして追加する。

```bash
git remote add source git@github.com:ユーザー名/リポジトリ名.git
```

### (4) 同期元リポジトリをpull

同期元リポジトリからデータを取得する。

```bash
git pull source master
```

### (5) 同期先リポジトリにpush

同期先リポジトリにデータをプッシュする。

```bash
git push origin master
```

### 3. SSHキーの生成と登録

GitHub Actionsが同期先リポジトリにアクセスできるようにするため、SSHキーを設定する。

### (1) SSHキーの生成

以下のコマンドを実行し、新しいSSHキーを生成する（既存のSSHキーを使用する場合はこの手順を省略可能）。

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

- **入力プロンプト**:
    - 「Enter file in which to save the key」では、デフォルトの `~/.ssh/id_ed25519` を使用する場合、そのままEnterを押す。
    - 「Enter passphrase」では、必要に応じてパスフレーズを設定する（空でも可）。
- **生成されるファイル**:
    - 秘密鍵: `~/.ssh/id_ed25519`
    - 公開鍵: `~/.ssh/id_ed25519.pub`

### (2) 公開鍵を「Deploy Keys」に登録

生成された公開鍵（`id_ed25519.pub`）を同期先リポジトリの「Deploy Keys」に追加する。

- **手順**:
    - GitHubで同期先リポジトリを開く。
    - **「Settings」 > 「Deploy keys」** に移動する。
    - **「Add deploy key」** をクリックする。
    - 以下の情報を入力する:
        - **Title**: 任意の名前（例: `GitHub Actions Key`）。
        - **Key**: `id_ed25519.pub` の内容をコピーして貼り付ける。
        - **Allow write access**: チェックを入れる（書き込み権限を付与するため）。
    - **「Add key」** をクリックして登録を完了する。

### (3) 秘密鍵をSecretsに登録

生成された秘密鍵（`id_ed25519`）を同期元リポジトリのSecretsに登録する。

- **手順**:
    - GitHubで同期元リポジトリを開く。
    - **「Settings」 > 「Secrets and variables」 > 「Actions」** に移動する。
    - **「New repository secret」** をクリックする。
    - 以下の情報を入力する:
        - **Name**: `SYNC_SSH_KEY`
        - **Value**: `id_ed25519` の内容をコピーして貼り付ける。
    - **「Add secret」** をクリックして登録を完了する。

### 4. GitHub Actionsを設定

リポジトリの初期化が完了したら、GitHub Actionsを設定して自動同期を有効にする。

### (1) GitHub Actionsワークフローの作成

以下のワークフローを `.github/workflows/sync.yml` に保存する。

```yaml
name: Sync Repository

on:
  push:
    branches:
      - master

jobs:
  sync:
    runs-on: ubuntu-latest
    
    steps:
      # ソースリポジトリをチェックアウト
      - name: Checkout source repository
        uses: actions/checkout@v3
        with:
          repository: ユーザー名/リポジトリ名
          token: ${{ secrets.GITHUB_TOKEN }}
          ref: master
      
      # ターゲットリポジトリにプッシュ
      - name: Push to target repository
        env:
          TARGET_REPO: git@github.com:組織名/リポジトリ名.git
          SSH_PRIVATE_KEY: ${{ secrets.SYNC_SSH_KEY }}
        run: |
          # SSHキーの設定
          mkdir -p ~/.ssh
          echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh-keyscan -H github.com >> ~/.ssh/known_hosts
          
          # ターゲットリポジトリをリモートとして追加
          git remote add target "$TARGET_REPO"
          
          # ターゲットリポジトリにプッシュ
          git push --force target master
```

### 5. GitHub Actionsの実行確認

1. GitHub Actionsが正常に動作するか確認するため、同期元リポジトリに変更を加える。
2. 同期元リポジトリの`master`ブランチに変更をプッシュする。
3. 同期先リポジトリでGitHub Actionsがトリガーされ、変更が同期されていることを確認する。

### 補足: トラブルシューティング

### エラー: `Permission denied (publickey)`

SSHキーが正しく設定されていない可能性がある。以下を再確認すること：

- `SYNC_SSH_KEY` に登録した秘密鍵が正しいか。
- 公開鍵が同期先リポジトリの「Deploy Keys」に正しく登録されているか。
- 公開鍵に書き込み権限（Write Access）が付与されているか。

### エラー: `remote unpack failed: index-pack failed`

同期元リポジトリが大きすぎる場合に発生する。リポジトリサイズを縮小する方法については、[こちらの手順](https://docs.github.com/en/repositories/working-with-large-files)を参照のこと。

### エラー: `git@github.com: Permission denied (publickey)`

SSH接続が正しく設定されていない可能性がある。以下を確認すること：

- SSHキーペアが正しく生成されているか。
- GitHub Actionsのワークフローで正しいSSHキーが使用されているか。
- `~/.ssh/known_hosts` ファイルが正しく設定されているか。

### まとめ

1. 同期先リポジトリを新規作成した場合、ローカル環境で初期設定を行う。
2. 初期設定後、GitHub Actionsを設定して自動同期を有効にする。
3. 必要に応じてトラブルシューティングを実施する。

これにより、同期先リポジトリの初期化とGitHub Actionsを用いた同期がスムーズに行えるようになる。
