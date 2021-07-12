---

title: About tream table theory
date: 2020-05-20 00:12:43
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka

---

# 参考

* [Foundations of streaming SQL stream & table theory]

[Foundations of streaming SQL stream & table theory]: https://www.slideshare.net/Hadoop_Summit/foundations-of-streaming-sql-stream-table-theory
[Foundations of streaming SQL stream & table theory (General theory)]: https://www.slideshare.net/Hadoop_Summit/foundations-of-streaming-sql-stream-table-theory#43
[OReillyのStreaming Systems]: http://shop.oreilly.com/product/0636920073994.do

[Streams and Tables Two Sides of the Same Coin]: https://dl.acm.org/doi/10.1145/3242153.3242155 



# メモ

## Tyler AkidauらによるApache Beamにまつわる情報

[Foundations of streaming SQL stream & table theory (General theory)] の通り、
ストリームデータとテーブルデータの関係性を論じたもの。

上記の内容の全体は、 [OReillyのStreaming Systems] に記載あり。

これらは、ストリーム・テーブル理論をベースに、Apache Beamを利用したストリームデータ処理・活用システムについて論じたもの。

## Matthias J. Sax、Guozhang Wangらによる論文

[Streams and Tables Two Sides of the Same Coin]

### 概要

ストリームデータの処理モデルを提案。
論理・物理の間の一貫性の崩れに対処する。

### 1 Introduction

データストリームのチャレンジ

* 物理的なアウト・オブ・オーダへの対応
* 処理のオペレータがステートフルでないといけない、レイテンシ、正しさ、処理コストなどのトレードオフがある、など
* 分散処理への対応

物理的な並びが保証されない条件下で、
十分に表現力のあるオペレータ（モデル）を立案する。

### 2 Background

ストリームデータのモデル。

ポイント。レコード配下の構成。

* オフセット：物理の並び
* タイムスタンプ：論理の並び（生成時刻）
* キー
* バリュー

### 3 Duality of streams and tables

レイテンシは、データストリームの特性に依存する。

論理、物理の並びの差異を解決するため、結果を継続的に更新するモデルを提案した。

Dual Streaming Model

DUality of streams and tables

テーブルは、テーブルのバージョンのコレクションと考えることもできる。

### 4 STREAM PROCESSING OPERATORS

モデル定義を解説。
フィルターなどのステートレスな処理から、アグリゲーションなどのステートフルな処理まで。

out-of-order なレコードが届いても、最終的な出力結果テーブルがout-of-orderレコードがないときと同一になるように動くことを期待する。

Watermarkと似たような機構として、「retention time」を導入。
結果テーブル内の「現在時刻 - retention time」よりも古い結果をメンテナンス対象から外す。

Stream - Table Joinのケースで、「遅れテーブル更新」が生じると、
下流システムに対して結果の上書きデータを出力する必要がある。

### 5 CASE STUDY: APACHE KAFKA

Kafka Streamsの例。

Kafka Streamsの利用企業：The New York Times, Pinterest, LINE, Trivago, etc

Kafka Streamsのオペレーションはすべてノンブロッキングであり、
レコードを受領次第処理し、KTableにマテリアライズされたり、Topicに書き戻したりされる。

Window集計の例を題材に、retention timeを利用。
retention timeを長くするほどストレージを利用するが、
out-of-orderレコードに対してロバストになる。
また、retention timeが長いほど、ウィンドウ結果が確定したと言えるタイミングが遅くなる。

### 6 RELATED WORK

Relationを取り扱うモデル、out-of-orderを取り扱うモデル、テーブルバージョン管理を取り扱うモデルなど。



<!-- vim: set et tw=0 ts=2 sw=2: -->
