---

title: Questioning the Lambda Architecture
date: 2020-01-13 21:50:11
categories:
  - Knowledge Management
  - Stream Processing
  - Kappa Architecture
tags:
  - Stream Processing
  - Kappa Architecture
  - Lambda Architecture

---

# 参考

* [Questioning the Lambda Architecture]

[Questioning the Lambda Architecture]: https://www.oreilly.com/radar/questioning-the-lambda-architecture/


# メモ

[Questioning the Lambda Architecture] にてJay Krepsが初めて言及したとされているようだ。
過去に読んだが忘れたので改めて、いかにメモを記載する。

## まとめ

主張としては、ストリーム処理はKafkaの登場により、十分に使用に耐えうるものになったため、
バッチ処理と両方使うのではなく、ストリーム処理1本で勝負できるのでは？ということだった。

## 気になった文言を引用

ラムダアーキテクチャについて：

> The Lambda Architecture is an approach to building stream processing applications on top of MapReduce and Storm or similar systems.

![Lambdaアーキテクチャのイメージ]

[Lambdaアーキテクチャのイメージ]: https://dmgpayxepw99m.cloudfront.net/lambda-16338c9225c8e6b0c33a3f953133a4cb.png

バッチ処理とストリーム処理で2回ロジックを書く。：

> You implement your transformation logic twice, once in the batch system and once in the stream processing system. 

レコメンデーションシステムを例にとる：

> A good example would be a news recommendation system that needs to crawl various news sources, process and normalize all the input, and then index, rank, and store it for serving.

データを取り込み、イミュターブルなものとして扱うことはありだと思う：

> I’ve written some of my thoughts about capturing and transforming immutable data streams 

> I have found that many people who attempt to build real-time data processing systems don’t put much thought into this problem and end-up with a system that simply cannot evolve quickly because it has no convenient way to handle reprocessing. 

リアルタイム処理が本質的に近似であり、バッチ処理よりも弱く、損失しがち、という意見があるよね、と。：

> One is that real-time processing is inherently approximate, less powerful, and more lossy than batch processing.

ラムダアーキテクチャの利点にCAP定理との比較が持ち出されることを引き合いに出し、ラムダアーキテクチャがCAP定例を克服するようなものではない旨を説明。：

> Long story short, although there are definitely latency/availability trade-offs in stream processing, this is an architecture for asynchronous processing, so the results being computed are not kept immediately consistent with the incoming data. The CAP theorem, sadly, remains intact.

結局、StormとHadoopの両方で同じ結果を生み出すアプリケーションを
実装するのがしんどいという話。：

> Programming in distributed frameworks like Storm and Hadoop is complex. 

ひとつの解法は抽象化。：

> Summingbird

とはいえ、2重運用はしんどい。デバッグなど。：

> the operational burden of running and debugging two systems is going to be very high. 

結局のところ、両方を同時に使わないでくれ、という結論：

> These days, my advice is to use a batch processing framework like MapReduce if you aren’t latency sensitive, and use a stream processing framework if you are, but not to try to do both at the same time unless you absolutely must.

ストリーム処理はヒストリカルデータの高スループットでの処理に向かない、という話もあるが…：

> When I’ve discussed this with people, they sometimes tell me that stream processing feels inappropriate for high-throughput processing of historical data.

バッチ処理もストリーム処理も抽象化の仕方は、DAGをベースにしたものであり、
その点では共通である、と。：

> But there is no reason this should be true. The fundamental abstraction in stream processing is data flow DAGs, which are exactly the same underlying abstraction in a traditional data warehouse (a la Volcano) as well as being the fundamental abstraction in the MapReduce successor Tez. 

ということでKafka。：

> Use Kafka

![提案アーキテクチャ]

[提案アーキテクチャ]: https://dmgpayxepw99m.cloudfront.net/kappa-61d0afc292912b61ce62517fa2bd4309.png

Kafkaに入れた後は、HDFS等に簡単に保存できる。：

> Kafka has good integration with Hadoop, so mirroring any Kafka topic into HDFS is easy. 

このあと少し、Kafkaの説明が続く。

この時点では、Event Sourcing、CQRSについての言及あり。

> Indeed, a lot of people are familiar with similar patterns that go by the name Event Sourcing or CQRS. 

LinkedInにて、JayはSamzaを利用。

> I know this approach works well using Samza as the stream processing system because we do it at LinkedIn.

提案手法の難点として、一時的に2倍の出力ストレージサイズが必要になる。

> However, my proposal requires temporarily having 2x the storage space in the output database and requires a database that supports high-volume writes for the re-load.

単純さを大事にする。：

> So, in cases where simplicity is important, consider this approach as an alternative to the Lambda Architecture.

## 所感

当時よりも、最近のワークロードは複雑なものも含めて期待されるようになっており、
ますます「バッチ処理とストリーム処理で同じ処理を実装する」というのがしんどくなっている印象。

<!-- vim: set et tw=0 ts=2 sw=2: -->
