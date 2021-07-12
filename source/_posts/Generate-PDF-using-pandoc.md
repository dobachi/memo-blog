---

title: Generate PDF using pandoc
date: 2020-10-29 22:17:31
categories:
  - Knowledge Management
  - Documentation
tags:
  - pandoc

---

# 参考

* [TeX Liveのインストール手順]
* [default.latex]

[TeX Liveのインストール手順]: https://texwiki.texjp.org/?Linux#texliveinstall
[default.latex]: https://github.com/jgm/pandoc-templates/blob/master/default.latex


# メモ

[TeX Liveのインストール手順] の通り、最新版をインストールする。
なお、フルセットでインストールした。


PDFを作成するときは以下のようにする。

```
$ pandoc test.md -o test.pdf --pdf-engine=lualatex -V documentclass=bxjsarticle -V classoption=pandoc
```

ただし、 [default.latex] に示すとおり、リンクに色を付けるなどしたいので、
上記マークダウンファイルには先頭部分にYAMLでコンフィグを記載することとした。

```markdown
---
title: テスト文章
date: 2020-10-30
author: dobachi
colorlinks: yes
numbersections: yes
toc: yes
---

# test

## これはテスト

[Google](https://www.google.com)

<!-- vim: set ft=markdown : -->
```


<!-- vim: set et tw=0 ts=2 sw=2: -->
