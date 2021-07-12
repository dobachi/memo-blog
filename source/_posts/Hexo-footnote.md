---

title: Hexoでふっとノートを用いる
date: 2019-07-08 14:03:19
categories:
  - Knowledge Management
  - Hexo
tags:
  - Hexo
  - Hexo Plugin

---


# 参考

* [hexo-renderer-markdown-it]

[hexo-renderer-markdown-it]: https://github.com/hexojs/hexo-renderer-markdown-it

＃メモ

最初はhexo-footnoteを見つけたのだが、開発停止されているようなので、
そこで言及されていた [hexo-renderer-markdown-it] を利用してみることにした。

院すとーすして、以下のようなコンフィグレーションを `_config.yml` に追加。

```
markdown:
  render:
    html: true
    xhtmlOut: false
    breaks: false
    linkify: false
    typographer: false
    #quotes: '“”‘’'
  plugins:
    - markdown-it-abbr
    - markdown-it-footnote
    - markdown-it-ins
    - markdown-it-sub
    - markdown-it-sup
  anchors:
    level: 2
    collisionSuffix: 'v'
    permalink: true
    permalinkClass: header-anchor
    permalinkSymbol: ¶
```

これでフットノートが使えるようになった。
しかし、アンカーが使えないのだがまだ詳しく調査していない。
