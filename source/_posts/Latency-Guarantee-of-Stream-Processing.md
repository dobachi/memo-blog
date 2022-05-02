---

title: Latency Guarantee of Stream Processing
date: 2022-01-18 00:49:18
categories:
  - Knowledge Management
  - Stream Processing
tags:
  - Stream Processing

---

# メモ

ストリーム処理におけるレイテンシ保証の仕組みにどんなものがあるか調査したメモ。

ストリーム処理のレイテンシとして気にするべきは、

* 正常時のレイテンシ
* 故障発生時のリカバリ含むレイテンシ

が挙げられそうである。

## 特許

* [ストリームデータ処理における性能保証方法および装置]
  * 日立製作所
  * 予め複数の計算方法を用意しておき、過去の計算結果から
    ユーザの要求するレイテンシ、精度を実現する計算方式に
    切り替えて処理する仕組みに関する提案
    * 切り替え判断の入力とするのは、処理量
  * 先行となる特許が2件あるようだ。
* [制御装置、情報処理装置、情報処理制御方法及びコンピュータプログラム]
  * アプリケーションの遅延要件を考慮して処理する
* [特開2021-60753(P2021-60753A):情報処理システム、情報処理方法、および情報処理プログラム]
  * 待ち時間を考慮したストリーム処理

## 論文

* [Elastic Stream Processing with Latency Guarantees]
  * アブストラクトを読む限り、パフォーマンスを計測し、
    適切なスケーリングを実行時に決定する。
    これによりレイテンシ保証する。
  * この論文の被引用数は大きいので、これを軸に情報を探すとよいか。
* [Topology-Aware Task Allocation for Distributed Stream Processing with Latency Guarantee]
  * レイテンシ保証。転送レイテンシとリソース需要を勘案。
* [Move Fast and Meet Deadlines: Fine-grained Real-time Stream Processing with Cameo]
  * Cameoの提案。ユーザが指定したレイテンシ対象に従い、イベントのプライオリティを伝搬し制御する。
* [Real-Time Stream Processing in Java]
  * Java8でストリーム処理。レイテンシ保証もありそう？
* [Minimum Backups for Stream Processing With Recovery Latency Guarantees]
  * [Elastic Stream Processing with Latency Guarantees] を引用している論文として見つけた。
  * Fault Tolerancyにおけるレイテンシのトレードオフを扱っている。
  * [Integrated recovery and task allocation for stream processing] にもFTに関する記載あり
* [Task Allocation for Stream Processing with Recovery Latency Guarantee] 
  * [Elastic Stream Processing with Latency Guarantees] を引用している
  * 故障発生時のリカバリ遅延を小さくする工夫
* [A Reactive Batching Strategy of Apache Kafka for Reliable Stream Processing in Real-time]
  * [Elastic Stream Processing with Latency Guarantees] を引用している
  * バッチベースのストリーム処理ではバッチサイズがデータロスの様子に影響を与えることに着目し、理アクティブなバッチの仕組みを提案
* [InferLine: latency-aware provisioning and scaling for prediction serving pipelines]
  * ストリーム処理ではなく、機械学習の推論システムだがレイテンシアウェアな処理の話
* [Self-Adaptive Data Stream Processing in Geo-Distributed Computing Environments]
  * セルフアダプティブな地理分散ストリーム処理。レイテンシ保証の話とは直接関係ないが、エッジコンピューティングとの関連から。

レイテンシ保証の話ではないが、ウォーターマークに関する取り組みもある。
以下は、2021年の論文。

* [Watermarks in stream processing systems: semantics and comparative analysis of Apache Flink and Google cloud dataflow]

## ソフトウェア

* いわゆるタイムウィンドウ処理やウォータマークの仕組みは既存の
  ストリーム処理OSSに採用されている。


## そのほか

* [A survey on data stream, big data and real-time]
  * ストリーム処理に関するサーベイ
* [A Survey on the Evolution of Stream Processing Systems]
  * ストリーム処理に関するサーベイ



# 参考

## 特許

* [ストリームデータ処理における性能保証方法および装置]
* [制御装置、情報処理装置、情報処理制御方法及びコンピュータプログラム]
* [特開2021-60753(P2021-60753A):情報処理システム、情報処理方法、および情報処理プログラム]

[ストリームデータ処理における性能保証方法および装置]: https://astamuse.com/ja/published/JP/No/2012094996
[制御装置、情報処理装置、情報処理制御方法及びコンピュータプログラム]: https://www.j-platpat.inpit.go.jp/p0200
[特開2021-60753(P2021-60753A):情報処理システム、情報処理方法、および情報処理プログラム]: https://www.j-platpat.inpit.go.jp/p0200


## 論文

* [Elastic Stream Processing with Latency Guarantees]
* [Task Allocation for Stream Processing with Recovery Latency Guarantee]
* [Topology-Aware Task Allocation for Distributed Stream Processing with Latency Guarantee]
* [Move Fast and Meet Deadlines: Fine-grained Real-time Stream Processing with Cameo]
* [Real-Time Stream Processing in Java]
* [Watermarks in stream processing systems: semantics and comparative analysis of Apache Flink and Google cloud dataflow]
* [Minimum Backups for Stream Processing With Recovery Latency Guarantees]
* [Integrated recovery and task allocation for stream processing]
* [A survey on data stream, big data and real-time]
* [A Survey on the Evolution of Stream Processing Systems]
* [InferLine: latency-aware provisioning and scaling for prediction serving pipelines]
* [Self-Adaptive Data Stream Processing in Geo-Distributed Computing Environments]
* [A Reactive Batching Strategy of Apache Kafka for Reliable Stream Processing in Real-time]

[Elastic Stream Processing with Latency Guarantees]: https://www.dos.tu-berlin.de/fileadmin/a34331500/misc/icdcs15_preprint.pdf
[Task Allocation for Stream Processing with Recovery Latency Guarantee]: https://ieeexplore.ieee.org/document/8048950
[Topology-Aware Task Allocation for Distributed Stream Processing with Latency Guarantee]:  https://dl.acm.org/doi/abs/10.1145/3239576.3239621
[Move Fast and Meet Deadlines: Fine-grained Real-time Stream Processing with Cameo]: https://www.usenix.org/system/files/nsdi21spring-xu.pdf
[Real-Time Stream Processing in Java]: https://www.cs.york.ac.uk/rts/static/papers/HaiTaoMe2016a.pdf
[Watermarks in stream processing systems: semantics and comparative analysis of Apache Flink and Google cloud dataflow]: https://dl.acm.org/doi/abs/10.14778/3476311.3476389
[Minimum Backups for Stream Processing With Recovery Latency Guarantees]: https://ieeexplore.ieee.org/abstract/document/7959102
[Integrated recovery and task allocation for stream processing]: https://ieeexplore.ieee.org/abstract/document/8280443
[A survey on data stream, big data and real-time]: https://www.inderscienceonline.com/doi/pdf/10.1504/IJNVO.2019.097631
[A Survey on the Evolution of Stream Processing Systems]: https://arxiv.org/abs/2008.00842
[InferLine: latency-aware provisioning and scaling for prediction serving pipelines]: https://dl.acm.org/doi/abs/10.1145/3419111.3421285
[Self-Adaptive Data Stream Processing in Geo-Distributed Computing Environments]: https://dl.acm.org/doi/abs/10.1145/3328905.3332304 
[A Reactive Batching Strategy of Apache Kafka for Reliable Stream Processing in Real-time]: https://ieeexplore.ieee.org/abstract/document/9251089



<!-- vim: set et tw=0 ts=2 sw=2: -->
