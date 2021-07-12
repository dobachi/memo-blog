---

title: pandoc template and css
date: 2020-03-06 22:46:59
categories:
  - Knowledge Management
  - Documentation
tags:
  - pandoc

---

# 参考

* [Pandocを使ってMarkdownを整形されたHTMLに変換する]

[Pandocを使ってMarkdownを整形されたHTMLに変換する]: https://qiita.com/cawpea/items/cea1243e106ababd15e7
[dashed/github-pandoc.css]: https://gist.github.com/dashed/6714393


# メモ

Pandocのバージョンは、 2.9.2を使用。

[Pandocを使ってMarkdownを整形されたHTMLに変換する] を参考に、テンプレートを作成してCSSを用いた。

```shell
$ mkdir -p ~/.pandoc/templates
$ pandoc -D html5 > ~/.pandoc/templates/mytemplate.html
```

テンプレートを適当にいじる。

その後、HTMLを以下のように生成。

```shell
$ pandoc --css ./pandoc-github.css --template=mytemplate -i ./README.md -o ./README.html
```

なお、GitHub風になるCSSは、 [dashed/github-pandoc.css] に公開されていたものを利用。
`--css` はcssのURLを表すだけなので、上記の例ではREADME.htmlと同じディレクトリに `pandoc-github.css` があることを期待する。


<!-- vim: set et tw=0 ts=2 sw=2: -->
