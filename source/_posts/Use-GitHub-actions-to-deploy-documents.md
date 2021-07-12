---

title: Use GitHub actions to deploy documents
date: 2020-08-09 23:30:38
categories:
  - Knowledge Management
  - Documentation
tags:
  - GitHub Actions
  - Sphinx

---

# 参考

* [GitHub Actionsを用いてGitHub Pagesへのデプロイを自動化する]
* [マーケットプレイスのsphinx-build]

[GitHub Actionsを用いてGitHub Pagesへのデプロイを自動化する]: https://sphinx-users.jp/cookbook/githubaction/index.html
[マーケットプレイスのsphinx-build]: https://github.com/marketplace/actions/sphinx-build


# メモ

[GitHub Actionsを用いてGitHub Pagesへのデプロイを自動化する] がSphinx JPのユーザ会による記事だったので参考になるが、
依存関係を都度pipインストールしているのが気になった。

[マーケットプレイスのsphinx-build] を利用すると良さそうだが、
この手順ではGITHUB TOKENを利用してデプロイしているのが気になった。
レポジトリごとに設定できる、Deploy Keyを利用したい。

そこでビルドには [マーケットプレイスのsphinx-build] を利用し、デプロイには [GitHub Actionsを用いてGitHub Pagesへのデプロイを自動化する]
の手順を利用することにした。

## レポジトリのDeploy Key設定

[GitHub Actionsを用いてGitHub Pagesへのデプロイを自動化する] の「Deploy keys の設定」章を参考に、
当該レポジトリのDeploy Keyを登録する。

任意の環境（ここではWSLのUbuntu18を利用した）で、
以下のコマンドを実行。

```shell
$ ssh-keygen -t rsa -b 4096 -C "＜レポジトリで使用しているメールアドレス＞" -f ＜任意の名前＞ -N ""
```

上記記事の通り、秘密鍵と公開鍵をGitHubのウェブUIで登録する。
なお、「Secrets」タブで登録した名称は、後ほどGitHub Actionsのワークフロー内で使用する。

## GitHub Actionsのワークフローの記述

[マーケットプレイスのsphinx-build] の例を参考に、
ワークフローを記述する。
なお、最後のデプロイする部分は、 [GitHub Actionsを用いてGitHub Pagesへのデプロイを自動化する] を参考に、
Deploy Keyを利用するよう修正した。

```yaml
name: CI

# 今回はマスタブランチへのPushをトリガとする。
on:
  push:
    branches:    
      - master

jobs:
  build:

    runs-on: ubuntu-latest
    # 今回はmasterブランチへのpushをトリガとしているので不要だが、gh-pagesへのpushをトリガとする場合など
    # 無限ループを回避する際には以下のように記述する。
    if: "!contains(github.event.head_commit.message, 'Update documentation via GitHub Actions')"

    steps:
    - uses: actions/checkout@v1

    # 今回はMakefileを利用するので、makeコマンドを使用するよう元ネタから修正した。
    # またドキュメントのソースが含まれているディレクトリは各自の定義に依存する。
    - uses: ammaraskar/sphinx-action@master
      with:
        build-command: "make html"
        docs-folder: "documents/"
    # 先ほどGitHubのウェブUIで定義した秘密鍵名を使用する。
    - name: Commit documentation changes and push it
      run: |
        mkdir ~/.ssh
        ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
        echo "${{ secrets.＜先ほどGitHubウェブUIで定義した秘密鍵名＞ }}" > ~/.ssh/id_rsa
        chmod 400 ~/.ssh/id_rsa
        git clone git@github.com:${GITHUB_REPOSITORY}.git --branch gh-pages --single-branch gh-pages
        cp -r documents/_build/html/* gh-pages/
        cd gh-pages
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add .
        git commit -m "Update documentation via GitHub Actions" -a || true
        git push origin HEAD:gh-pages
        # The above command will fail if no changes were present, so we ignore
        # that.
    # ===============================
```

<!-- vim: set et tw=0 ts=2 sw=2: -->
