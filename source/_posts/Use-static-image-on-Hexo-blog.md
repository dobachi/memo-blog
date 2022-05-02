---

title: Use static image on Hexo blog
date: 2020-12-31 23:58:34
categories:
  - Knowledge Management
  - Hexo
tags:
  - Hexo

---

# 参考

* [Hexo 記事に画像を貼り付ける]
* [Global-Asset-Folder]

[Hexo 記事に画像を貼り付ける]: https://bitto.jp/posts/%E6%8A%80%E8%A1%93/Hexo/hexo-add-image/
[Global-Asset-Folder]: https://hexo.io/docs/asset-folders#Global-Asset-Folder


# メモ

[Hexo 記事に画像を貼り付ける] を参考に、もともとCacooのリンクを使っていた箇所を
すべてスタティックな画像を利用するようにした。

post_asset_folderを利用して、記事ごとの画像ディレクトリを利用することも考えたが、
画像はひとところに集まっていてほしいので、 [Global-Asset-Folder] を利用することにした。

なお、上記ブログでは

```
プロジェクトトップ/images/site
```

以下に画像を置き、

```
![猫](/images/site/cat.png)
```

のようにリンクを指定していた。

自身の環境では、rootを指定しているので

```
プロジェクトトップ/image
```

以下にディレクトリを置き、


```
![猫](memo-blog/images/cat.png)
```

と指定することにした。


<!-- vim: set et tw=0 ts=2 sw=2: -->
