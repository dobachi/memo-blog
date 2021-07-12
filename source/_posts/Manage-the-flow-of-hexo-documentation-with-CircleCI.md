---

title: Manage the flow of hexo documentation with CircleCI
date: 2019-08-23 21:18:21
categories:
  - Knowledge Management
  - Hexo
tags:
  - Hexo
  - CircleCI

---

# 参考

* [LaTeXファイルをGithubにpushしたらCircle CIでPDF生成するようにした]
* [HexoのレンダリングエンジンとしてPandocを使う]
* [mathjax.html]

[LaTeXファイルをGithubにpushしたらCircle CIでPDF生成するようにした]: http://jackale.hateblo.jp/entry/2018/01/14/000709
[HexoのレンダリングエンジンとしてPandocを使う]: https://qiita.com/sky_y/items/7c29909c5cffa28b23d8
[mathjax.html]: https://github.com/phoenixcw/hexo-renderer-mathjax/blob/master/lib/mathjax.html#L15


# メモ

## HexoでPandasレンダラーを使うために最新版PandocをインストールしたDockerイメージを用意

ドキュメント等では、circleciのDockerイメージを使うことが記載されているが、
ここでは予め最新版Pandocをインストールしておきたかったので、circleciのDockerイメージをベースにしつつ、
インストーラをwget、dpkgでインストールしたDockerイメージを自作して利用した。

Dockerfileは以下の通り。

```
FROM circleci/node:8.10.0

RUN wget -P /tmp https://github.com/jgm/pandoc/releases/download/2.7.3/pandoc-2.7.3-1-amd64.deb

RUN sudo dpkg -i /tmp/pandoc-2.7.3-1-amd64.deb
```

今回は、これを使って作ったDockerイメージを、予めDocker Hubに登録しておく。
ここでは `hoge/fuga:1.0` と登録したものとする。

## HexoをCircleCIでビルドするための設定ファイルの作成

上記で作ったDockerイメージを使う、以下のようなCircleCi設定ファイルを作り、
Hexoプロジェクトのトップディレクトリ以下 `.circleci/config.yml` に保存する。

```
defaults: &defaults 
  docker:
    - image: hoge/fuga:1.0
      environment:
        TZ: Asia/Tokyo
  working_directory: ~/work

version: 2
jobs:
  build:
    <<: *defaults
    steps:
      - checkout
      - run: git submodule init
      - run: git submodule update
      - run: npm install --save
      - run: node_modules/.bin/hexo clean
      - run: sed -i -e "s#http://cdn.mathjax.org/mathjax#https://cdn.mathjax.org/mathjax#" node_modules/hexo-renderer-mathjax/mathjax.html 
      - run: cat node_modules/hexo-renderer-mathjax/mathjax.html
      - run: node_modules/.bin/hexo generate
      - run: git config --global user.name <your name>
      - run: git config --global user.email <your email address>
      - run: node_modules/.bin/hexo deploy
      - persist_to_workspace:
          root: .
          paths: [ '*' ]
```

上記 `config.yml` は、今後の拡張性を踏まえて記載してあるので、やや冗長な表現になっている。

なお、

```
      - run: sed -i -e "s#http://cdn.mathjax.org/mathjax#https://cdn.mathjax.org/mathjax#" node_modules/hexo-renderer-mathjax/mathjax.html 
```


としている箇所があるが、これは現在の `hexo-renderer-mathjax` をインストールすると、httpsではなくhttpを使用するようになっており、
結果としてgithub.ioでサイト公開するとmathjax部分が意図通りに表示されないからである。
[HexoのレンダリングエンジンとしてPandocを使う] にもその旨説明がある。
[mathjax.html] を見る限り、GitHub上のmasterブランチでは修正済みのようだ。

## CircleCI上でプロジェクトを作る

GitHubアカウントを連携している場合、既存のレポジトリが見えるので、
プロジェクトを作成する。

## GitHubへのPush用のSSH鍵を登録する

[LaTeXファイルをGithubにpushしたらCircle CIでPDF生成するようにした] あたりを参考に、SSH鍵の登録を実施。
プロジェクトの設定から、「Checkout SSH keys」を開き、「Add user key」から鍵を生成→登録した。

GitHub側のアカウント設定から鍵が登録されたことが確認できる。

以上で手順終了。
ブログを追記して、プロジェクトにpushするとCircleCIがhexo generateし、hexo deployするようになる。

<!-- vim: set tw=0 ts=4 sw=4: -->
