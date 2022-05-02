---
title: Read and write data on Delta Lake streaming manner
date: 2020-11-19 00:11:42
categories:
  - Knowledge Management
  - Storage Layer
  - Delta Lake
tags:
  - Delta Lake
---

# 参考

* [dobachi's StructuredStreamingDeltaLakeExample] 
* [sbt]
* [SparkのUnitTest作成でspark-testing-base]
* [spark-testing-base]
* [dobachi's sparkProjectTemplate.g8]
* [dobachi's spark-sbt]
* [StructuredNetworkWordCount]
* [Delta table as a sink]
* [Delta table as a stream source]
* [Ignore updates and deletes]

[dobachi's StructuredStreamingDeltaLakeExample]: https://github.com/dobachi/StructuredStreamingDeltaLakeExample
[sbt]: https://www.scala-sbt.org/
[SparkのUnitTest作成でspark-testing-base]: https://dev.classmethod.jp/articles/merit-to-use-spark-testing-base-on-spark-unittest/
[spark-testing-base]: https://github.com/holdenk/spark-testing-base/
[dobachi's sparkProjectTemplate.g8]: https://github.com/dobachi/sparkProjectTemplate.g8
[dobachi's spark-sbt]: https://github.com/dobachi/spark-sbt.g8
[StructuredNetworkWordCount]: https://github.com/apache/spark/blob/master/examples/src/main/scala/org/apache/spark/examples/sql/streaming/StructuredNetworkWordCount.scala
[Delta table as a sink]: https://docs.delta.io/latest/delta-streaming.html#delta-table-as-a-sink 
[Delta table as a stream source]: https://docs.delta.io/latest/delta-streaming.html#delta-table-as-a-stream-source
[Ignore updates and deletes]: https://docs.delta.io/latest/delta-streaming.html#ignore-updates-and-deletes

# メモ


## 準備（SBT）

今回はSBTを利用してSalaを用いたSparkアプリケーションで試すことにする。
[sbt] を参考にSBTをセットアップする。（基本的には対象バージョンをダウンロードして置くだけ）

```shell
$ mkdir -p ~/Sources
$ cd ~/Sources
$ sbt new dobachi/spark-sbt.g8
```

ここでは、 [dobachi's spark-sbt.g8] を利用してSpark3.0.1の雛形を作った。
対話的に色々聞かれるので、ほぼデフォルトで生成。

ここでは、 [StructuredNetworkWordCount] を参考に、Word Countした結果をDelta Lakeに書き込むことにする。

なお、以降の例で示しているアプリケーションは、すべて [dobachi's StructuredStreamingDeltaLakeExample] に含まれている。

## 簡単なビルドと実行の例

以下のように予めncコマンドを起動しておく。

```shell
$ nc -lk 9999
```

続いて、別のターミナルでアプリケーションをビルドして実行。（ncコマンドを起動したターミナルは一旦保留）

```shell
$ cd structured_streaming_deltalake
$ sbt assembly
$ /opt/spark/default/bin/spark-submit --class com.example.StructuredStreamingDeltaLakeExample target/scala-2.12/structured_streaming_deltalake-assembly-0.0.1.jar localhost 9999
```

先程起動したncコマンドの引数に合わせ、9999ポートに接続する。
Structured Streamingが起動したら、ncコマンド側で、適当な文字列（単語）を入力する（以下は例）


```
hoge hoge fuga
fuga fuga
fuga fuga hoge
```

もうひとつターミナルを開き、spark-shellを起動する。

```shell
$ /opt/spark/default/bin/spark-shell --packages io.delta:delta-core_2.12:0.7.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
```

アプリケーションで出力先としたディレクトリ内のDelta Lakeテーブルを参照すると、以下のようにテーブルが更新されていることがわかる。
ひとまずncコマンドでいろいろな単語を入力して挙動を試すと良い。

```scala
scala> val df = spark.read.format("delta").load("/tmp/delta/wordcount")
df: org.apache.spark.sql.DataFrame = [value: string, count: bigint]

scala> df.show
+-----+-----+
|value|count|
+-----+-----+
| fuga|    5|
| hoge|    3|
+-----+-----+
```

(wip)

## 書き込み

[Delta table as a sink] の通り、Delta LakeテーブルをSink（つまり書き込み先）として利用する際には、
AppendモードとCompleteモードのそれぞれが使える。

### Appendモード

例のごとく、ncコマンドを起動し、アプリケーションを実行。（予めsbt assemblyしておく）
もうひとつターミナルを開き、spark-shellでDelta Lakeテーブルの中身を確認する。

ターミナル1

```shell
$ nc -lk 9999
```

ターミナル2

```shell
$ /opt/spark/default/bin/spark-submit --class com.example.StructuredStreamingDeltaLakeAppendExample
target/scala-2.12/structured_streaming_deltalake-assembly-0.0.1.jar localhost 9999
```

ターミナル3

```shell
$ /opt/spark/default/bin/spark-shell --packages io.delta:delta-core_2.12:0.7.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
```

ターミナル1のncで適当な単語列を入力する。

```
hoge hoge
```

ターミナル3のspark-shellでDelta Lakeテーブルの中身を確認する。


```scala
scala> val df = spark.read.format("delta").load("/tmp/delta/wordcount_per_line")
df: org.apache.spark.sql.DataFrame = [unixtime: bigint, count: bigint]

scala> df.show
+-------------+-----+
|     unixtime|count|
+-------------+-----+
|1605968491821|    2|
+-------------+-----+
```

何度かncコマンド経由でテキストを流し込むと、以下のように行が加わるkとがわかる。

```
scala> df.show
+-------------+-----+
|     unixtime|count|
+-------------+-----+
|1605968491821|    2|
+-------------+-----+


scala> df.show
+-------------+-----+
|     unixtime|count|
+-------------+-----+
|1605968518584|    2|
|1605968522461|    3|
|1605968491821|    2|
+-------------+-----+
```

### Completeモード

Completeモードは、上記のWordCountの例がそのまま例になっている。
`com.example.StructuredStreamingDeltaLakeExample` 参照。

## 読み出し

[Delta table as a stream source] の通り、既存のDelta Lakeテーブルからストリームデータを取り出す。

### 準備

ひとまずDelta Lakeのテーブルを作る。
ここではspark-shellで適当に作成する。

```shell
$ /opt/spark/default/bin/spark-shell --packages io.delta:delta-core_2.12:0.7.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
```

```scala
scala> val df = spark.read.format("parquet").load("/opt/spark/default/examples/src/main/resources/users.parquet")
scala> df.show
+------+--------------+----------------+
|  name|favorite_color|favorite_numbers|
+------+--------------+----------------+
|Alyssa|          null|  [3, 9, 15, 20]|
|   Ben|           red|              []|
+------+--------------+----------------+

scala> df.write.format("delta").save("/tmp/delta/users")
```

上記のDataFrameのスキーマは以下の通り。

```scala
scala> df.printSchema
root
 |-- name: string (nullable = true)
 |-- favorite_color: string (nullable = true)
 |-- favorite_numbers: array (nullable = true)
 |    |-- element: integer (containsNull = true)
```

### ストリームで読み込んでみる

もうひとつターミナルを立ち上げる。

```shell
$ /opt/spark/default/bin/spark-submit --class com.example.StructuredStreamingDeltaLakeReadExample target/scala-2.12/structured_streaming_deltalake-assembly-0.0.1.jar /tmp/delta/users
```

先程作成しておいたテーブルの中身が読み込まれる。

```
-------------------------------------------
Batch: 0
-------------------------------------------
20/11/22 00:29:41 INFO CodeGenerator: Code generated in 3.212 ms
20/11/22 00:29:41 INFO CodeGenerator: Code generated in 4.1238 ms
+------+--------------+----------------+
|  name|favorite_color|favorite_numbers|
+------+--------------+----------------+
|Alyssa|          null|  [3, 9, 15, 20]|
|   Ben|           red|              []|
+------+--------------+----------------+
```

先程の、Delta Lakeテーブルを作成したターミナルのspark-shellで、
追加データを作り、Delta Lakeテーブルに挿入する。

まず、追加データ用のスキーマを持つcase classを作成する。

```scala
scala> case class User(name: String, favorite_color: String, favorite_numbers: Array[Int])
```

つづいて、作られたcase classを利用して、追加用のDataFrameを作る。
（SeqからDataFrameを生成する）

```scala
scala> val addRecord = Seq(User("Bob", "yellow", Array(1,2))).toDF
```

appendモードで既存のDelta Lakeテーブルに追加する。

```scala
scala> addRecord.write.format("delta").mode("append").save("/tmp/delta/users")
```

ここで、ストリーム処理を動かしている方のターミナルを見ると、
以下のように追記された内容が表示されていることがわかる。


```
-------------------------------------------
Batch: 1
-------------------------------------------
+----+--------------+----------------+
|name|favorite_color|favorite_numbers|
+----+--------------+----------------+
| Bob|        yellow|          [1, 2]|
+----+--------------+----------------+
```
### 読み込み時の maxFilesPerTrigger オプション 

ストリーム読み込み時には、 `maxFilesPerTrigger` オプションを指定できる。
このオプションは、以下のパラメータとして利用される。

org/apache/spark/sql/delta/DeltaOptions.scala:98

```scala
  val maxFilesPerTrigger = options.get(MAX_FILES_PER_TRIGGER_OPTION).map { str =>
    Try(str.toInt).toOption.filter(_ > 0).getOrElse {
      throw DeltaErrors.illegalDeltaOptionException(
        MAX_FILES_PER_TRIGGER_OPTION, str, "must be a positive integer")
    }
  }
```

このパラメータは org.apache.spark.sql.delta.sources.DeltaSource.AdmissionLimits#toReadLimit メソッド内で用いられる。

org/apache/spark/sql/delta/sources/DeltaSource.scala:350

```scala
    def toReadLimit: ReadLimit = {
      if (options.maxFilesPerTrigger.isDefined && options.maxBytesPerTrigger.isDefined) {
        CompositeLimit(
          ReadMaxBytes(options.maxBytesPerTrigger.get),
          ReadLimit.maxFiles(options.maxFilesPerTrigger.get).asInstanceOf[ReadMaxFiles])
      } else if (options.maxBytesPerTrigger.isDefined) {
        ReadMaxBytes(options.maxBytesPerTrigger.get)
      } else {
        ReadLimit.maxFiles(
          options.maxFilesPerTrigger.getOrElse(DeltaOptions.MAX_FILES_PER_TRIGGER_OPTION_DEFAULT))
      }
    }
  }
```

このメソッドの呼び出し階層は以下の通り。

```
AdmissionLimits in DeltaSource.toReadLimit()  (org.apache.spark.sql.delta.sources)
  DeltaSource.getDefaultReadLimit()  (org.apache.spark.sql.delta.sources)
    MicroBatchExecution
```

MicroBatchExecutionは、 `org.apache.spark.sql.execution.streaming.MicroBatchExecution` クラスであり、
この仕組みを通じてSparkのStructured Streamingの持つレートコントロールの仕組みに設定値をベースにした値が渡される。

### 読み込み時の maxBytesPerTrigger オプション

原則的には、 `maxFilesPerTrigger` と同じようなもの。
指定された値を用いてcase classを定義し、最大バイトサイズの目安を保持する。

### 追記ではなく更新したらどうなるか？

Delta Lakeでoverwriteモードで書き込む際に、パーティションカラムに対して条件を指定できることを利用し、
部分更新することにする。

まず `name` をパーティションカラムとしたDataFrameを作ることにする。

```scala
scala> val df = spark.read.format("parquet").load("/opt/spark/default/examples/src/main/resources/users.parquet")
scala> df.show
+------+--------------+----------------+
|  name|favorite_color|favorite_numbers|
+------+--------------+----------------+
|Alyssa|          null|  [3, 9, 15, 20]|
|   Ben|           red|              []|
+------+--------------+----------------+

scala> df.write.format("delta").partitionBy("name").save("/tmp/delta/partitioned_users")
```

上記例と同様に、ストリームでデータを読み込むため、もうひとつターミナルを起動し、以下を実行。

```shell
$ /opt/spark/default/bin/spark-submit --class com.example.StructuredStreamingDeltaLakeReadExample target/scala-2.12/structured_streaming_deltalake-assembly-0.0.1.jar /tmp/delta/partitioned_users
```

spark-shellを起動したターミナルで、更新用のデータを準備。

```scala
scala> val updateRecord = Seq(User("Ben", "green", Array(1,2))).toDF
```

条件付きのoverwriteモードで既存のDelta Lakeテーブルの一部レコードを更新する。

```scala
scala> updateRecord
         .write
         .format("delta")
         .mode("overwrite")
         .option("replaceWhere", "name == 'Ben'")
         .save("/tmp/delta/partitioned_users")
```

上記を実行したときに、ストリーム処理を実行しているターミナル側で、
以下のエラーが生じ、プロセスが停止した。

```
20/11/23 22:10:55 ERROR MicroBatchExecution: Query [id = 13cf0aa0-116c-4c95-aea0-3e6f779e02c8, runId = 6f71a4bb-c067-4f6d-aa17-6bf04eea3520] terminated
with error
java.lang.UnsupportedOperationException: Detected a data update in the source table. This is currently not supported. If you'd like to ignore updates, set the option 'ignoreChanges' to 'true'. If you would like the data update to be reflected, please restart this query with a fresh checkpoint directory.        at org.apache.spark.sql.delta.sources.DeltaSource.verifyStreamHygieneAndFilterAddFiles(DeltaSource.scala:273)
        at org.apache.spark.sql.delta.sources.DeltaSource.$anonfun$getChanges$1(DeltaSource.scala:117)

(snip)
```

後ほど検証するが、Delta Lakeのストリーム処理では、既存レコードのupdate、deleteなどの既存レコードの更新となる処理は基本的にサポートされていない。
オプションを指定することで、更新を無視することができる。

### 読み込み時の ignoreDeletes オプション

基本的には、上記の通り、元テーブルに変化があった場合はエラーを生じるようになっている。
[Ignore updates and deletes] に記載の通り、update、merge into、delete、overwriteがエラーの対象である。

ひとまずdeleteでエラーになるのを避けるため、 `ignoreDeletes` で無視するオプションを指定できる。

動作確認する。

spark-shellを立ち上げ、検証用のテーブルを作成する。

```shell
$ /opt/spark/default/bin/spark-shell --packages io.delta:delta-core_2.12:0.7.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
```

```scala
scala> val df = spark.read.format("parquet").load("/opt/spark/default/examples/src/main/resources/users.parquet")
scala> df.show
+------+--------------+----------------+
|  name|favorite_color|favorite_numbers|
+------+--------------+----------------+
|Alyssa|          null|  [3, 9, 15, 20]|
|   Ben|           red|              []|
+------+--------------+----------------+

scala> df.write.format("delta").save("/tmp/delta/users_for_delete")
```

別のターミナルを立ち上げ、当該テーブルをストリームで読み込む。

```shell
$ /opt/spark/default/bin/spark-submit --class com.example.StructuredStreamingDeltaLakeReadExample target/scala-2.12/structured_streaming_deltalake-assembly-0.0.1.jar /tmp/delta/users_for_delete
```

spark-shellでテーブルとして読み込む。

```scala
scala> import io.delta.tables._
scala> val deltaTable = DeltaTable.forPath(spark, "/tmp/delta/users_for_delete")
```

```scala
scala> deltaTable.delete("name == 'Ben'")
```

上記の通り、テーブルを更新（削除）した結果、ストリーム処理が以下のエラーを出力して終了した。

```
20/11/23 22:26:21 ERROR MicroBatchExecution: Query [id = 660b82a9-ca40-4b91-8032-d75807b11c18, runId = 7e46e9a7-1ba2-48b2-b264-53c254cfa6fc] terminated
with error
java.lang.UnsupportedOperationException: Detected a data update in the source table. This is currently not supported. If you'd like to ignore updates, set the option 'ignoreChanges' to 'true'. If you would like the data update to be reflected, please restart this query with a fresh checkpoint directory.        at org.apache.spark.sql.delta.sources.DeltaSource.verifyStreamHygieneAndFilterAddFiles(DeltaSource.scala:273)
        at org.apache.spark.sql.delta.sources.DeltaSource.$anonfun$getChanges$1(DeltaSource.scala:117)
        at scala.collection.Iterator$$anon$11.nextCur(Iterator.scala:484)
(snip)
```

そこで、同じことをもう一度 ignoreDelte オプションを利用して実行してみる。

```
scala> df.write.format("delta").partitionBy("name").save("/tmp/delta/users_for_delete2")
```

なお、 `ignoreDelete` オプションはパーティションカラムに指定されたカラムに対し、
where句を利用して削除するものに対して有効である。
（パーティションカラムに指定されていないカラムをwhere句に使用してdeleteしたところ、エラーが生じた）

別のターミナルを立ち上げ、当該テーブルをストリームで読み込む。

```shell
$ /opt/spark/default/bin/spark-submit --class com.example.StructuredStreamingDeltaLakeDeleteExample target/scala-2.12/structured_streaming_deltalake-assembly-0.0.1.jar /tmp/delta/users_for_delete2
```

spark-shellでテーブルとして読み込む。

```scala
scala> import io.delta.tables._
scala> val deltaTable = DeltaTable.forPath(spark, "/tmp/delta/users_for_delete2")
```

```scala
scala> deltaTable.delete("name == 'Ben'")
```

このとき、特にエラーなくストリーム処理が続いた。

またテーブルを見たところ、

```scala
scala> deltaTable.toDF.show
+------+--------------+----------------+
|  name|favorite_color|favorite_numbers|
+------+--------------+----------------+
|Alyssa|          null|  [3, 9, 15, 20]|
+------+--------------+----------------+
```

削除対象のレコードが消えていることが確かめられる。

### 読み込み時の ignoreChanges オプション


`ignoreChanges` オプションは、いったん概ね `ignoreDelete` オプションと同様だと思えば良い。
ただしdeleteに限らない。（deleteも含む）
細かな点は後で調査する。

## org.apache.spark.sql.delta.sources.DeltaSource クラスについて

Delta Lake用のストリームData Sourceである。
親クラスは以下の通り。

```
DeltaSource (org.apache.spark.sql.delta.sources)
  Source (org.apache.spark.sql.execution.streaming)
    SparkDataStream (org.apache.spark.sql.connector.read.streaming)
```

気になったメンバ変数は以下の通り。

```scala
  /** A check on the source table that disallows deletes on the source data. */
  private val ignoreChanges = options.ignoreChanges || ignoreFileDeletion
  --> レコードの変更（ファイル変更）を無視するかどうか

  /** A check on the source table that disallows commits that only include deletes to the data. */
  private val ignoreDeletes = options.ignoreDeletes || ignoreFileDeletion || ignoreChanges
  --> レコードの削除（ファイル削除）を無視するかどうか

  private val excludeRegex: Option[Regex] = options.excludeRegex
  --> ADDファイルのリストする際、無視するファイルを指定する

  override val schema: StructType = deltaLog.snapshot.metadata.schema
  --> 対象テーブルのスキーマ

  (snip)

  private val tableId = deltaLog.snapshot.metadata.id
  --> テーブルのID

  private var previousOffset: DeltaSourceOffset = null
  --> バッチの取得時のオフセットを保持する

  // A metadata snapshot when starting the query.
  private var initialState: DeltaSourceSnapshot = null
  private var initialStateVersion: Long = -1L
  --> org.apache.spark.sql.delta.sources.DeltaSource#getBatch などから呼ばれる、スナップショットを保持するための変数
```

### org.apache.spark.sql.delta.sources.DeltaSource#getChanges メソッド

ストリーム処理のバッチ取得メソッド `org.apache.spark.sql.delta.sources.DeltaSource#getBatch` などから呼ばれるメソッド。
スナップショットなどの情報から、開始時点のバージョンから現在までの変化を返す。

### org.apache.spark.sql.delta.sources.DeltaSource#getSnapshotAt メソッド

上記の `org.apache.spark.sql.delta.sources.DeltaSource#getChanges` メソッドなどで利用される、
指定されたバージョンでのスナップショットを返す。

`org.apache.spark.sql.delta.SnapshotManagement#getSnapshotAt` を内部的に利用する。

### org.apache.spark.sql.delta.sources.DeltaSource#getChangesWithRateLimit メソッド

`org.apache.spark.sql.delta.sources.DeltaSource#getChanges` メソッドに比べ、
レート制限を考慮した上での変化を返す。

### org.apache.spark.sql.delta.sources.DeltaSource#getStartingOffset メソッド

`org.apache.spark.sql.delta.sources.DeltaSource#latestOffset` メソッド内で呼ばれる。
ストリーム処理でマイクロバッチを構成する際、対象としているデータのオフセットを返すのだが、
それらのうち、初回の場合に呼ばれる。★要確認

当該メソッド内で、「開始時点か、変化をキャプチャして処理しているのか」、「コミット内のオフセット位置」などの確認が行われ、
`org.apache.spark.sql.delta.sources.DeltaSourceOffset` にラップした上でメタデータが返される。

### org.apache.spark.sql.delta.sources.DeltaSource#latestOffset メソッド

`org.apache.spark.sql.connector.read.streaming.SupportsAdmissionControl#latestOffset` メソッドをオーバーライドしている。
今回のマイクロバッチで対象となるデータのうち、最後のデータを示すオフセットを返す。

### org.apache.spark.sql.delta.sources.DeltaSource#verifyStreamHygieneAndFilterAddFiles メソッド

`org.apache.spark.sql.delta.sources.DeltaSource#getChanges` メソッドで呼ばれる。
`getChanges` メソッドは指定されたバージョン以降の「変更」を取得するものである。
その中において、`verifyStreamHygieneAndFilterAddFiles` メソッドは関係あるアクションだけ取り出すために用いられる。

### org.apache.spark.sql.delta.sources.DeltaSource#getBatch メソッド

`org.apache.spark.sql.execution.streaming.Source#getBatch` メソッドをオーバライドしたもの。
与えられたオフセット（開始、終了）をもとに、そのタイミングで処理すべきバッチとなるDataFrameを返す。

## org.apache.spark.sql.delta.sources.DeltaSource.AdmissionLimits クラスについて

レート管理のためのクラス。

### org.apache.spark.sql.delta.sources.DeltaSource.AdmissionLimits#toReadLimit メソッド

`org.apache.spark.sql.delta.sources.DeltaSource#getDefaultReadLimit` メソッド内で呼ばれる。
オプションで与えられたレート制限のヒント値を、 `org.apache.spark.sql.connector.read.streaming.ReadLimit` に変換する。

### org.apache.spark.sql.delta.sources.DeltaSource.AdmissionLimits#admit メソッド

`org.apache.spark.sql.delta.sources.DeltaSource#getChangesWithRateLimit` メソッド内で呼ばれる。
上記メソッドは、レート制限を考慮して変化に関する情報のイテレータを返す。
`admit` メソッドはその中において、レートリミットに達しているかどうかを判断するために用いられる。

<!-- vim: set et tw=0 ts=2 sw=2: -->
