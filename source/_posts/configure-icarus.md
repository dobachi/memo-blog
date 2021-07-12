---
title: HexoのIcarusテーマを設定する
date: 2018-10-14 22:27:07
categories:
  - Knowledge Management
  - Hexo
tags:
  - Hexo
  - Icarus
---

# 設定ファイル

`themes/icarus/_config.yml.example` にサンプルがあるので、
コピーして用いる。

```
$ cp themes/icarus/_config.yml{.example,}
$ vim themes/icarus/_config.yml
```

# 設定内容

* menuにTags、Categoriesを足した
* logo画像を差し替えた

  * `themes/icarus/source/css/images` 以下にlogo.pngがあるので差し替えた。

* プロフィール（例：アバター画像など）を差し替えた

  * アバター画像は. `themes/icarus/source/css/images` 以下にavatar.pngがあるので差し替えた。


