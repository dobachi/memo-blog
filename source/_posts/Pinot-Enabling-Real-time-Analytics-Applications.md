---

title: 'Pinot: Enabling Real-time Analytics Applications'
date: 2020-01-01 23:01:36
categories:
  - Knowledge Management
  - Pinot
tags:
  - Pinot
  - LinkedIn
  - OLAP
  - Query Engine
  - Druid

---

# 参考

* [Pinot Enabling Real-time Analytics Applications atLinkedIn's Scale]
* [Star-Tree Index Powering Fast Aggregations on Pinot]

[Pinot Enabling Real-time Analytics Applications atLinkedIn's Scale]: https://www.slideshare.net/seunghyunlee1460/pinot-enabling-realtime-analytics-applications-linkedins-scale
[Star-Tree Index Powering Fast Aggregations on Pinot]: https://engineering.linkedin.com/blog/2019/06/star-tree-index--powering-fast-aggregations-on-pinot

# メモ

## オンライン分析のアーキテクチャ

* Join on the fly
  * ベーステーブルからクエリ実行のタイミングでデータ生成
* Pre Join + Pre Aggregate
  * 分析で必要となるテーブルをストリーム処理等で事前作成
  * 事前処理はマスタデータのテーブルとの結合、など
* Pre Join + Pre Aggregate + Pre Cube
  * さらに分析で求められる結果データを予め作成、インデックス化
  * 例えばAggregationしておく、など

レイテンシと柔軟性のトレードオフの関係：

![Latency vs. Flexibility](/memo-blog/images/knsEuAFXXibxOWVc-F9493.png)

![「Who View」のアーキテクチャ](/memo-blog/images/knsEuAFXXibxOWVc-06740.png)

## ユースケース

* LinkedInのメンバーが見る分析レポート
  * QPSが高い（数千/秒 級）
  * レイテンシは数十ms～sub秒
* インタラクティブダッシュボード
  * 様々なアグリゲーション
* 異常検知

LinkedIn以外の企業では、

* Uber
* slack
* MS Teams
* Weibo
* factual

あたりが利用しているようだ。
Uberは、自身の技術ブログでも触れていた。

## ワークフロー

![ワークフロー概要](/memo-blog/images/knsEuAFXXibxOWVc-60564.png)

Pinotは、原則としてPre Aggregation、Pre Cubeを前提とする仕組みなので、
スキーマの定義が非常に重要。

### 分散処理とIngestion

またバッチとストリーム両方に対応しているので、
それぞれデータ入力（Ingestion）を定義する。

データはセグメントに分けられ、サーバに分配される。

![Segment Assignment](/memo-blog/images/knsEuAFXXibxOWVc-87FDA.png)

### 分散処理とクエリルーティング

セグメントに基づき、Brokerによりルーティングされる。

### リアルタイムサーバとオフラインサーバ

ストリームから取り込んだデータとバッチで取り込んだデータは、
共通のスキーマを用いることになる。

したがって、統一的にクエリできる？

## アーキテクチャの特徴

### インデックス（Cube）の特徴

Scan、Inverted Index、Sorted Index、Star-Tree Indexを併用可能。

![データ処理上の工夫](/memo-blog/images/knsEuAFXXibxOWVc-BC4AB.png)

比較対象として、Druidがよく挙げられているが、Sorted Index、Star-Tree Indexがポイント。

カラムナデータフォーマットを用いるのは前提。
それに加え、Dictionary Encodeing、Bit Compressionを使ってデータ構造に基づいた圧縮を採用。

#### Inverted Index

転置インデックスを作っておく、という定番手法。

#### Sorted Index

予め、Dimensionに基づいてソートしておくことで、
フィルタする際にスキャン量を減らしながら、かつデータアクセスを効率化。

![Sroted Indexの特徴](/memo-blog/images/knsEuAFXXibxOWVc-7C19E.png)

#### Star-Tree Index

すべてをCube化するとデータ保持のスペースが大量に必要になる。
そこで部分的にCube化する。 ★要確認

![Star-Tree Indexの特徴](/memo-blog/images/knsEuAFXXibxOWVc-EE192.png)

## 性能特性

### Druidとの簡単な比較

Druidと簡易的に比較した結果が載っている。

まずは、レイテンシの小ささが求められるインタラクティブな分析における性能特徴：

![Druidとの簡易比較](/memo-blog/images/knsEuAFXXibxOWVc-C0381.png)


ミリ秒単位での分析を取り扱うことに関してDruidと共通だが、
各種インデックスのおかげか、Druidよりもパーセンタイルベースの比較で
レイテンシが小さいとされている。

つづいて、あらかじめ定義されたクエリを大量にさばくユースケース：

![Druidとの簡易比較2](/memo-blog/images/knsEuAFXXibxOWVc-3ACC9.png)

レイテンシを小さく保ったまま、高いQPSを実現していることを
示すグラフが載っている。
この辺りは、工夫として載っていた各種インデックスを予め定義していることが強く効きそうだ。

続いて異常検知ユースケースの例：

![Druidとの簡易比較3](/memo-blog/images/knsEuAFXXibxOWVc-FBA32.png)

データがSkewしていることが強調されているが、その意図はもう少し読み解く必要がありそう。 ★要確認

## Star-Tree Indexについて

[Star-Tree Index Powering Fast Aggregations on Pinot] に記載あり。


<!-- vim: set et tw=0 ts=2 sw=2: -->