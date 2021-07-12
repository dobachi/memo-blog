---

title: Storage Layer ? Storage Engine ?
date: 2019-05-10 14:36:50
categories:
  - Knowledge Management
  - Storage Layer
tags:
  - Storage Layer
  - Storage Engine

---

# 参考

## データベースエンジン あるいは ストレージエンジン
* [jp.wikipediaのデータベースエンジン]
* [MySQLの代替ストレージエンジン]
* [InnoDBイントロダクション]

[jp.wikipediaのデータベースエンジン]: https://ja.wikipedia.org/wiki/%E3%83%87%E3%83%BC%E3%82%BF%E3%83%99%E3%83%BC%E3%82%B9%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3
[MySQLの代替ストレージエンジン]: https://dev.mysql.com/doc/refman/5.6/ja/storage-engines.html
[InnoDBイントロダクション]: https://dev.mysql.com/doc/refman/5.6/ja/innodb-introduction.html

## Apache Parquet

* [Parquetの公式ウェブサイト]

[Parquetの公式ウェブサイト]: https://parquet.apache.org/

## Delta Lake

* [Delta Lake公式ウェブサイト]

[Delta Lake公式ウェブサイト]: https://delta.io/

## Apache Hudi

* [Apache Hudiの公式ウェブサイト]
* [Hudiのイメージを表す図]

[Apache Hudiの公式ウェブサイト]:https://hudi.incubator.apache.org/
[Hudiのイメージを表す図]: https://hudi.incubator.apache.org/images/hudi_intro_1.png

## Alluxio

* [Alluxio公式ウェブサイト]

[Alluxio公式ウェブサイト]: https://www.alluxio.io/

## AWS Aurora

* [kumagiさんの解説記事]
* [ACMライブラリの論文]

[kumagiさんの解説記事]: https://qiita.com/kumagi/items/67f9ac0fb4e6f70c056d
[ACMライブラリの論文]: https://dl.acm.org/citation.cfm?id=3056101

## Apache HBase

* [HBaseの公式ウェブサイト]

[HBaseの公式ウェブサイト]: https://hbase.apache.org/

## Apache Kudu

* [Apache Kuduの公式ウェブサイト]
* [DBテックショーでのKudu説明]

[Apache Kuduの公式ウェブサイト]: https://kudu.apache.org/
[DBテックショーでのKudu説明]: https://www.slideshare.net/Cloudera_jp/apache-kududb-dbts2017

# メモ

## 動機

単にPut、Getするだけではなく、例えばデータを内部的に構造化したり、トランザクションに対応したりする機能を持つ
ストレージ機能のことをなんと呼べば良いのかを考えてみる。

## どういうユースケースを想定するか？

* データがストリームとして届く
  * できる限り鮮度の高い状態で扱う
* 主に分析および分析結果を用いたビジネス
* 大規模なデータを取り扱う
  * 大規模なデータを一度の分析で取り扱う
  * 大規模なデータの中から、一部を一度の分析で取り扱う

## どういう特徴を持つストレージを探るか？

* 必須
  * Put、Getなど（あるいは、それ相当）の基本的なAPIを有する
    * 補足：POSIXでなくてもよい？
  * 大規模データを扱える。スケーラビリティを有する。
    大規模の種類には、サイズが大きいこと、件数が多いことの両方の特徴がありえる
    * データを高効率で圧縮できることは重要そう
  * クエリエンジンと連係する
* あると望ましい
  * トランザクションに対応
    * ストリーム処理の出力先として用いる場合、Exactly Onceセマンティクスを
      達成するためには出力先ストレージ側でトランザクション対応していることで
      ストリーム処理アプリケーションをシンプルにできる、はず
  * ストリームデータを効率的に永続化し、オンデマンドの分析向けにバックエンドで変換。
    あるいは分析向けにストア可能
    * 高頻度での書き込み + 一括での読み出し
  * サービスレス
    * 複雑なサービスを運用せずに済むなら越したことはない。
  * 読み出しについて、プッシュダウンフィルタへの対応
    * 更にデータ構造によっては、基本的な集計関数に対応していたら便利ではある
  * 更新のあるデータについて、過去のデータも取り出せる

## データベースエンジン あるいは ストレージエンジン

[jp.wikipediaのデータベースエンジン] によると、

> データベース管理システム (DBMS)がデータベースに対しデータを
> 挿入、抽出、更新および削除(CRUD参照)するために使用する基礎となる
> ソフトウェア部品

とある。

MySQLの場合には、　[MySQLの代替ストレージエンジン] に載っているようなものが該当する。
なお、デフォルトはInnoDB。
[InnoDBイントロダクション] に「表 14.1 InnoDB ストレージエンジンの機能」という項目がある。
インデックス、キャッシュ、トランザクション、バックアップ・リカバリ、レプリケーション、
圧縮、地理空間情報の取扱、暗号化対応などが大まかに挙げられる。

## Apache Parquet

[Parquetの公式ウェブサイト] によると以下のように定義されている。

> Apache Parquet is a columnar storage format available to any project in the Hadoop ecosystem,
> regardless of the choice of data processing framework, data model or programming language.

ストレージフォーマット単体でも、バッチ処理向けにはある程度有用であると考えられる。

## Delta Lake

[Delta Lake公式ウェブサイト] には、以下のような定義が記載されている。

> Delta Lake is an open-source storage layer that brings ACID
> transactions to Apache Spark™ and big data workloads.

またウェブサイトには、「Key Features」が挙げられている。2019/05/10時点では以下の通り。

* ACID Transactions
* Scalable Metadata Handling
* Time Travel (data versioning)
* Open Format
* Unified Batch and Streaming Source and Sink
* Schema Enforcement
* Schema Evolution
* 100% Compatible with Apache Spark API

データベースの「データベースエンジン」、「ストレージエンジン」とは異なる特徴を有することから、
定義上も「Storage Layer」と読んでいるのだろうか。

## Apache Hudi

[Apache Hudiの公式ウェブサイト] によると、

> Hudi (pronounced “Hoodie”) ingests & manages storage of large analytical datasets
> over DFS (HDFS or cloud stores) and provides three logical views for query access.

とのこと。

また特徴としては、2019/05/10現在

* Read Optimized View
* Incremental View
* Near-Real time Table

が挙げられていた。
なお、機能をイメージするには、 [Hudiのイメージを表す図] がちょうどよい。

Apache Hudiでは、「XXなYYである」のような定義は挙げられていない。

## Alluxio

ストレージそのものというより、ストレージの抽象化や透過的アクセスの仕組みとして考えられる。

[Alluxio公式ウェブサイト] には以下のように定義されている。

> Data orchestration for analytics and machine learning in the cloud

[Alluxio公式ウェブサイト] には、「KEY TECHNICAL FEATURES」というのが記載されている。
気になったものを列挙すると以下の通り。

* Compute
  * Flexible APIs
  * Intelligent data caching and tiering
* Storage
  * Built-in data policies 
  * Plug and play under stores
  * Transparent unified namespace for file system and object stores
* Enterprise
  * Security
  * Monitoring and management

## AWS Auroraのバックエンドストレージ（もしくはストレージエンジン）

[kumagiさんの解説記事] あたりが入り口としてとてもわかり易い。
また、元ネタは、 [ACMライブラリの論文] あたりか。

語弊を恐れずにいえば、上記でも触れられていたとおり、「Redo-logリプレイ機能付き分散ストレージ」という
名前が妥当だろうか。

## Apache HBase

[HBaseの公式ウェブサイト] によると、

> Apache HBase is the Hadoop database, a distributed, scalable, big data store.

のように定義されている。
また、挙げられていた特徴は以下のとおり。（2019/05/12現在）

* Linear and modular scalability.
* Strictly consistent reads and writes.
* Automatic and configurable sharding of tables
* Automatic failover support between RegionServers.
* Convenient base classes for backing Hadoop MapReduce jobs with Apache HBase tables.
* Easy to use Java API for client access.
* Block cache and Bloom Filters for real-time queries.
* Query predicate push down via server side Filters
* Thrift gateway and a REST-ful Web service that supports XML, Protobuf, and binary data encoding options
* Extensible jruby-based (JIRB) shell
* Support for exporting metrics via the Hadoop metrics subsystem to files or Ganglia; or via JMX

いわゆるスケールアウト可能なKVSだが、これを分析向けのストレージとして用いる選択肢もありえる。
ただし、いわゆるカラムナフォーマットでデータを扱うわけではない点と、
サービスを運用する必要がある点は懸念すべき点である。

## Apache Kudu

[Apache Kuduの公式ウェブサイト] を見ると、以下のように定義されている。

> A new addition to the open source Apache Hadoop ecosystem,
> Apache Kudu completes Hadoop's storage layer to enable fast analytics on fast data.

またKuduの利点は以下のように記載されている。

* Fast processing of OLAP workloads.
* Integration with MapReduce, Spark and other Hadoop ecosystem components.
* Tight integration with Apache Impala, making it a good, mutable alternative to using HDFS with Apache Parquet.
* Strong but flexible consistency model, allowing you to choose consistency requirements on a per-request basis, including the option for strict-serializable consistency.
* Strong performance for running sequential and random workloads simultaneously.
* Easy to administer and manage.
* High availability. Tablet Servers and Masters use the Raft Consensus Algorithm, which ensures that as long as more than half the total number of replicas is available, the tablet is available for reads and writes. For instance, if 2 out of 3 replicas or 3 out of 5 replicas are available, the tablet is available.
* Reads can be serviced by read-only follower tablets, even in the event of a leader tablet failure.
* Structured data model.

クエリエンジンImpalaと連係することを想定されている。
また、「ストレージレイヤ」という呼び方が、Delta Lake同様に用いられている。
