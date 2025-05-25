---

title: vim modeline format in Markrown
date: 2019-07-27 23:24:43
categories:
  - Clipping
  - Vim
tags:
  - Vim

---

# 参考

* [Add vim modeline in markdown document]

[Add vim modeline in markdown document]: https://stackoverflow.com/questions/53386522/add-vim-modeline-in-markdown-document

# メモ

[Add vim modeline in markdown document] にvimのモードラインをMarkdownファイル内で記載する方法について言及あり。

結論としては、

```
<!-- vim: set ft=markdown: -->
```
のように記載する。 `markdown:` の末尾のコロンがポイント。

<!-- vim: set tw=0 ts=4 sw=4: -->
