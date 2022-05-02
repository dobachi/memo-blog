---
title: Dask of Python
date: 2019-04-23 23:12:05
categories:
  - Knowledge Management
  - Data Processing Engine
tags:
  - Machine Learning
  - Data Analysis
  - Dask
  - Data Processing Engine
---

# 参考

* [Dask使ってみた]
* [Python Dask で 並列 DataFrame 処理]
* [【初めての大規模データ②】Daskでの並列分散処理]
* [時間のかかる前処理をDaskで高速化]

[Dask使ってみた]: https://qiita.com/art_526/items/ca003a78535ab4546a01
[Python Dask で 並列 DataFrame 処理]: http://sinhrks.hatenablog.com/entry/2015/09/24/222735
[【初めての大規模データ②】Daskでの並列分散処理]: https://qiita.com/katsuki104/items/222a9d5e85e4f92f4c43
[時間のかかる前処理をDaskで高速化]: http://cocodrips.hateblo.jp/entry/2018/12/18/201752

# メモ

## ダミー変数化での支障について

[【初めての大規模データ②】Daskでの並列分散処理] に記載あった点が気になった。

以下、引用。
```
dask.dataframeは行方向にしかデータを分割できないため、ダミー変数を作成する際には1列分のデータを取得するために、すべてのデータを読み込まなければならず、メモリエラーを起こす危険性があります。
そこで、大規模データの処理を行う際には、dask.dataframeを一度dask.arrayに1列ずつに分割した形で変換し、
それから1列分のデータのみを再度dask.dataframeに変換し、get_dummiesしてやるのが良いと思います。
※私はこの縛りに気づき、daskを使うのを諦めました...
```

上記ブログでは、少なくともダミー変数化の部分は素のPythonで実装したようだ。
