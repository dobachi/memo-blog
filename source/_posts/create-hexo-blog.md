---
title: Hexoブログを作る
date: 2018-09-20 00:30:33
categories:
  - Knowledge Management
  - Hexo
tags: Hexo
---

あまり考えずに使えそうなブログ生成ツールということで、Hexoを選んでみました。

# 参考にした情報

* Hexo

  * https://liginc.co.jp/web/programming/server/104594
  * https://liginc.co.jp/web/programming/node-js/85318
  * http://paki.github.io/2015/05/26/hexo%E3%81%A7%E3%83%96%E3%83%AD%E3%82%B0%E3%81%A4%E3%81%8F%E3%81%A3%E3%81%9F/
  * https://hexo.io/

* GitHubページの作り方

  * https://ja.nuxtjs.org/faq/github-pages/

# ブログ構築の基本的な流れ

https://liginc.co.jp/web/programming/server/104594 に記載の流れで問題ありませんでしたが、
以下の点だけ少々異なる手順で実行しました。

## type

`_config.yml` の中で上記のブログでは以下のように設定するようになっています。

```
・・・(省略)・・・
# Deployment
## Docs: http://hexo.io/docs/deployment.html
deploy:
  type: github
  repo: git@github.com:n0bisuke/n0bisuke.github.io.git
  branch: master
```

このとき、自分がインストールした

```
hexo: 3.7.1
hexo-cli: 1.1.0
```

のバージョンのHexoではgithubではなく、gitを用いる必要がありました。
これについては、 https://liginc.co.jp/web/programming/node-js/85318 にも記載がありました。
本ブログに記載の通り、typeをgitにした後、

```
$ npm install hexo-deployer-git --save
```

と、hexo-deployer-gitをインストールしました。

## branch

私はGitHubアカウントのプロジェクトページにデプロイしたかったので、masterブランチではなく、
gh-pagesブランチを指定するようにしました。

# ブログの原稿や元データの保存について

公開されるデータは、 `.deploy_git` に保存されているように見えます。
またこれは生成されたデータであり、gh-pagesにデプロイされるデータも、この生成済みデータだけのように見えます。

ブログ原稿をどこでも記載できるようにするため、 `hexo init` したプロジェクトそのものをGitHubのプライベートレポジトリにも保存するようにしました。
