---
title: WordからMarkdownを生成する
date: 2018-10-20 22:14:16
categories:
  - Knowledge Management
  - Documentation
tags:
  - Word
  - Markdown
  - pandoc
---

[ドンピシャのQiitaの記事](https://qiita.com/kinagaki/items/460577f46529484d720e) があったので
手元の環境で真似したところ、悪くない結果が得られた。

コマンドだけ引用すると以下の通り。

```
pandoc hoge.docx -t markdown-raw_html-native_divs-native_spans -o hoge.md 
```
