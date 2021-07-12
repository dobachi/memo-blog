---

title: Manifold of Uber
date: 2019-02-08 12:52:25
categories:
  - Knowledge Management
  - Machine Learning
  - Model Management
tags:
  - Machine Learning
  - Model Management
  - Uber

---

# 参考

* [O'Reillyの記事]
* [Uber eatsでの機械学習による配達時間短縮事例]
* [IEEE Transacionの論文]

[O'Reillyの記事]: https://eng.uber.com/manifold/?utm_medium=email&utm_source=topic+optin&utm_campaign=awareness&utm_content=20190206+data+nl&mkt_tok=eyJpIjoiTXpoaU5qazVZamhrWm1FdyIsInQiOiJIK1AxWGJ4dlRNWWtnMEp4bm9sbE1aVUdaRWx0ZVA1ZURSQkV4bWFCWWdQc2hHaEVJamdZVnBwcU93bVRIaEt3U3RMU0pMS2ZpTUd4M2xUbXlrOEtoSDBUOWhNbHg5VklnaFpcL2VyOVwvUm5wSlB5TXR1V0ZNejVpZUNPZFRndUhQIn0%3D
[Uber eatsでの機械学習による配達時間短縮事例]: https://eng.uber.com/uber-eats-trip-optimization/
[IEEE Transacionの論文]: https://arxiv.org/pdf/1808.00196.pdf

# O'Reillyの記事


## プロダクト概要

モデル管理をより視覚的に行いやすくするためのツール ManifoldをUberが開発した。
モデル性能劣化の潜在的な要因を探すのに役立つ。
また、あるデータセットに関して、各モデルがどういった性能を示すかを可視化し、
モデル化以前の工夫の効果を測ることが出来る。

既存のモデル可視化ツールは、特定のツール、アルゴリズムの内部状態を示す物が多かった。
Manifoldはモデル性能を改善／改悪するデータセグメントを見つける。
それらがアグリゲートされた評価も示す。これはアンサンブル手法にとって使いやすい。


現時点では、回帰と識別器に対応。

今のところオープンソース化はされていないようだ。

## 機能

Visualization and workflow designの箇所に図ありで説明がされている。

* 性能比較ビュー
  * 横軸：メトリクス、縦軸：データセグメント、色：モデル、という形で視覚的に
    モデルの傾向を確認できる
* 特徴ごとの比較ビュー
  * 横軸：特徴空間、縦軸：データポイント数、色：データセグメント、という形で
    視覚的にモデルの傾向を確認できる

グラフを表示ながら以下のような操作を加えて確認可能

* クラスタ数を変えながら、特徴がどのように変化するかを確認
* スライス（領域を区切ってズーム）
* 特徴の差の大きさ（？）にフィルタをかけて、気になる点を探す

## より直感的な皮革のための取り組み

またコンセプトとしては、さらに

* 横軸の性能
* 縦軸に特徴

という形で視覚化する方法が挙げられているが、まだ課題も挙げられている。
（例：データ点数が多くなりがちなので抽象化の仕組みが必要、など）

そこでManifoldではデータセグメントをクラスタ化して見やすくする、などの工夫が施されている。

## アーキテクチャ

PythonとJavaScriptのそれぞれを好きな方を使える。
これにより、Uber内の他のフレームワークと連携しやすくなっている。

ただしJavaScriptでクラスタリングなどを計算させると遅いことから、
TensorFlow.jsを用いている。

## ユースケース


### モデルの工夫の効果の確認

[Uber eatsでの機械学習による配達時間短縮事例] に記載の事例にて、
モデル比較のため使用。
モデル改善の工夫の評価をする際にManifoldを使用。
これにより、特定のデータセグメントに改善効果があることがわかった。

### False Negativeの低減のための分析

Safetyチームによる利用。
False Negativeレートの改善のために利用。
あるモデルがNegativeとしたデータセグメントについてドリルダウン分析。
当該モデルは、ある特徴の値が小さいときにNegativeと判定する傾向があることがわかった。
しかし実際にはその中にはPositiveなものも含まれいる。
ここから、その特徴に着目し、より差をつけやすい特徴を用いたり、モデルを用いるような工夫を施した。
