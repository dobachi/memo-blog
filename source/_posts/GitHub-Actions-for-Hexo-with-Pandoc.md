---

title: GitHub Actions for Hexo with Pandoc
date: 2022-05-02 09:57:25
categories:
  - Knowledge Management
  - Hexo
tags:
  - Hexo
  - Pandoc

---

# メモ

遅ればせながら（？）、Circle CIからGitHub ActionsにHexo使ったブログのビルド・公開を移行する、と思い立ち、
このブログ生成ではPandocなどを利用していることから、独自のコンテナ環境があるとよいかと思い、調査。
Pandocインストールを含むDockerfileを準備し利用することにした。

◆理由

- Pandoc環境を含む、GitHub Actionがなさそうだった
- デプロイまで含めたActionがほとんどだったが、ビルドとデプロイを分けたかった（デプロイ部分は他の取り組みと共通化したかった）

[Docker コンテナのアクションを作成する] を参考にアクションを作成し、登録する。
またHexo環境の作成については、 [heowc/action-hexo] が参考になった。

## GitHub Actionで用いられるDockerfile等の作成

[Docker コンテナのアクションを作成する] を参考に以下のファイルを作成する。
なお、 [dobachi/hexo-pandoc-action] に該当するファイルを置いてある。

```
[dobachi@home HexoPandocDocker]$ ls -1
Dockerfile
README.md
action.yml
entrypoint.sh
```

### Dockerfile

Dockerファイル内では依存するパッケージのインストール、Pandocのインストールを実施。
NPMの必要パッケージインストールは、entrypoint側で実施するため、ここでは不要。

```
[dobachi@home HexoPandocDocker]$ cat Dockerfile
FROM ubuntu:20.04

# You may need to configure the time zone
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install minimal packages to prepare Hexo
RUN apt-get update && \
    apt-get install -y git-core npm wget

# Install Pandoc using deb package
RUN wget https://github.com/jgm/pandoc/releases/download/2.18/pandoc-2.18-1-amd64.deb
RUN apt-get install -y ./pandoc-2.18-1-amd64.deb

# Copy script for GitHub Action
COPY entrypoint.sh /entrypoint.sh

# Configure entrypointo for GitHub Action
ENTRYPOINT ["/entrypoint.sh"]
```

### action.yml

最低限の設定のみ使用。

```
[dobachi@home HexoPandocDocker]$ cat action.yml
# action.yml
name: 'Build Hexo with Pandoc'
description: 'build Hexo blog using Pandoc generator'
runs:
  using: 'docker'
  image: 'Dockerfile'
```

### entrypoint.yml

npmパッケージの依存パッケージをインストールし、HTMLを生成する。

```
[dobachi@home HexoPandocDocker]$ cat entrypoint.sh
#!/bin/sh -l

# Instlal Hexo and dependencies.
npm install -g hexo-cli
npm install

# Build
hexo g
```

## GitHub Actionの設定

### パーソナルトークンの生成

予め、GitHubの設定からパーソナルトークンを生成しておく。後ほど使用する。

### GitHub Actionを動かしたいレポジトリのAction用トークンを設定する。

ここでは `PERSONAL_TOKEN` という名前で設定した。
内容は、先に作っておいたもの。

### ワークフローの設定ファイル作成

GitHub Actionを使ってビルドするHexoブログのレポジトリにて、
`.github/workflows/gh-pages.yml` を生成する。

ここではプライベートのレポジトリで作成したHexo原稿をビルドし、
パブリックなGitHub Pages用レポジトリにpushする例を示す。

```
[dobachi@home memo-blog-text]$ cat .github/workflows/gh-pages.yml
name: GitHub Pages

on:
  push:
    branches:
      - master  # Set a branch name to trigger deployment
  pull_request:

jobs:
  deploy:
    runs-on: ubuntu-20.04
    concurrency:
      group: ${{ github.workflow }}-${{ github.ref }}
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: true  # Fetch Hugo themes (true OR recursive)
          fetch-depth: 0    # Fetch all history for .GitInfo and .Lastmod

      # Deploy hexo blog website.
      - name: Generate
        uses: dobachi/hexo-pandoc-action@v1.0.8

      # Copy source to repository for convinience
      - name: copy sources
        run: |
          sudo chown -R runner public
          cp -r ./source ./public/source

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        if: ${{ github.ref == 'refs/heads/master' }}
        with:
          external_repository: dobachi/memo-blog
          personal_token: ${{ secrets.PERSONAL_TOKEN }}
          publish_dir: ./public
```

# 参考

* [GitHub Actionsでmarkdownをpdfで出力する]
* [heowc/action-hexo]
* [Docker コンテナのアクションを作成する]
* [dobachi/hexo-pandoc-action]

[GitHub Actionsでmarkdownをpdfで出力する]: https://44smkn.hatenadiary.com/entry/2021/03/23/224925
[heowc/action-hexo]: https://github.com/heowc/action-hexo
[Docker コンテナのアクションを作成する]: https://docs.github.com/ja/actions/creating-actions/creating-a-docker-container-action
[dobachi/hexo-pandoc-action]: https://github.com/dobachi/hexo-pandoc-action



<!-- vim: set et tw=0 ts=2 sw=2: -->
