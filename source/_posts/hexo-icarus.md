---
title: Hexoでicarusテーマを使う
date: 2018-10-14 21:22:08
categories:
  - Knowledge Management
  - Hexo
tags:
  - Hexo
---

# 参考

* [HEXOテーマ「icarus」導入のあれこれ]

[HEXOテーマ「icarus」導入のあれこれ]: https://blog.hyrogram.com/2018/08/26/

# 基本な手順

基本的な手順は、 [HEXOテーマ「icarus」導入のあれこれ] に記載されている通りで問題ない。

# 注意点

> そのままだと普通の固定ページになるので、デモのようなページにしたい場合、
> themes/icarus/source/categoriesにできているindex.mdを、themesと同じ階層にあるsourceフォルダ内のcategoriesフォルダに
> themes/icarus/source/tagsにできているindex.mdを、themesと同じ階層にあるsourceフォルダ内のtagsフォルダにコピー（元のindex.mdと差し替え）します。

という記述があったが、手元の環境では`themes/icarus/_source/categories`、`themes/icarus/_source/tags`のように、`source`の前にアンダーバーが必要だった。
つまり、

* `themes/icarus/_source/categories` -> `source/categories`
* `themes/icarus/_source/tags` -> `source/tags`

のように、ディレクトリごとコピーしたところ、それぞれCategories、Tagsページが表示されるようになった。
ただ、Categoryはどう使うべきかいまだ決めかねている。
