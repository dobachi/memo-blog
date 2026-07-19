# memo-blog

ブログURL: https://dobachi.github.io/memo-blog/

Hexo製ブログのソースと生成物を1リポジトリで管理する。

| ブランチ | 内容 |
|---|---|
| `main` | ソース（記事Markdown、テーマ、設定）。ここを編集する |
| `gh-pages` | GitHub Actions が生成した静的サイト。直接編集しない |

未公開の下書き・調査メモは、このリポジトリではなく親プロジェクト
[DevMemoBlog](https://github.com/dobachi/DevMemoBlog)（Private）の `content/` 配下で管理する。
`source/_drafts` はそこへのシンボリックリンクで、gitignore 済み。

> 旧 `memo-blog-text` リポジトリは本リポジトリへ統合済み（archive）。

## 準備

hexo-renderer-pandocを用いることにしたので、事前にPandoc2をインストールすること。
なお、1系ではないことに注意。

```
$ wget https://github.com/jgm/pandoc/releases/download/3.3/pandoc-3.3-1-amd64.deb
$ sudo dpkg -i pandoc-3.3-1-amd64.deb
```


## 初期化

Gitモジュール
```
$ git clone https://github.com/dobachi/memo-blog.git
$ cd memo-blog
$ git submodule init   # テーマの取得
$ git submodule update   # テーマの取得
```

npm関連
```
$ npm install
```

なお、Windows Subsystem for Linux (Ubuntu)で実行するときには、
Windows側のディレクトリをシンボリックリンク貼って使っているときに問題が生じたので注意。

## コマンド

https://hexo.io/docs/writing

なお、以下の例では、npmでローカルインストールしたhexoを用いることにしている。

### 新しい記事の作成
```
$ ./node_modules/hexo/bin/hexo new <title>
```

### ウェブサイトの生成

https://hexo.io/docs/generating

```
$ ./node_modules/hexo/bin/hexo generate
```

### デプロイ

`.deploy_git` ディレクトリでの `$ git config user.name <name>` と `$ git config user.email <email>` が必要

```
$ ./node_modules/hexo/bin/hexo deploy --generate
```

```
$ ./node_modules/hexo/bin/hexo draft
$ ./node_modules/hexo/bin/hexo publish
```

## Pandocを使ったHTML作成

```shell
$ cp -r .pandoc ~/.pandoc
$ pandoc -i source/_posts/<document>.md -o <document>.html -c css/github-pandoc.css --template mytemplate --toc -N --metadata title="<document>"
$ cp <document>.html ~/Downloads.win/
$ cp -r css ~/Downloads.win/
```

## 調査ディレクトリ

記事作成時の調査内容は、公開リポジトリではなく親プロジェクト DevMemoBlog（Private）の
`content/research/` で管理する。構成と使い方はそちらの `README.md` を参照。

