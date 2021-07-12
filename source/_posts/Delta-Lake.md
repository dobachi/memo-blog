---

title: Delta Lake
date: 2019-05-05 23:27:14
categories:
  - Knowledge Management
  - Storage Layer
  - Delta Lake
tags:
  - Storage Layer
  - Delta Lake
  - Spark
  - Parquet

---

# 参考

* [公式ドキュメント]
* [公式ドキュメント（クイックスタート）]
* [ストリームへの対応についての説明]
* [公式クイックスタート]
* [DatabricksのDelta Lakeの説明]
* [DataFrameを使った上書き]
* [データ・リテンション]
* [VACUUM]
* [最適化]
* [Delta LakeのOptimistic Concurrency Controlに関する記述]
* [Apache Hudi]
* [公式ドキュメントのCompact filesの説明]
* [公式ドキュメントのパーティション説明]
* [公式ドキュメントのスキーマバリデーション]
* [公式ドキュメントのスキーママージ]
* [公式ドキュメントのスキーマ上書き]
* [公式ドキュメントのマージの例]
* [公式ドキュメントのマージを使った上書き]
* [Slowly changing data (SCD) Type 2 operation]
* [Write change data into a Delta table]
* [Upsert from streaming queries using foreachBatch]
* [org.apache.spark.sql.streaming.DataStreamWriter#foreachBatch]
* [公式ドキュメントのVacuum]
* [Presto and Athena to Delta Lake Integration]
* [Presto Athena連係の制約]

[公式ドキュメント]: https://docs.delta.io/latest/
[公式ドキュメント（クイックスタート）]: https://docs.delta.io/latest/quick-start.html
[ストリームへの対応についての説明]: https://docs.delta.io/latest/delta-streaming.html
[公式クイックスタート]: https://docs.delta.io/latest/quick-start.html
[DatabricksのDelta Lakeの説明]: https://docs.databricks.com/delta/index.html
[DataFrameを使った上書き]: https://docs.databricks.com/delta/delta-batch.html#overwrite-using-dataframes
[データ・リテンション]: https://docs.databricks.com/delta/delta-batch.html#data-retention
[VACUUM]: https://docs.databricks.com/spark/latest/spark-sql/language-manual/vacuum.html#vacuum
[最適化]: https://docs.databricks.com/delta/optimizations.html
[Delta LakeのOptimistic Concurrency Controlに関する記述]: https://docs.delta.io/latest/concurrency-control.html#optimistic-concurrency-control
[Apache Hudi]: https://hudi.apache.org
[公式ドキュメントのCompact filesの説明]: https://docs.delta.io/latest/best-practices.html#compact-files
[公式ドキュメントのパーティション説明]: https://docs.delta.io/latest/delta-batch.html#partition-data
[公式ドキュメントのスキーマバリデーション]: https://docs.delta.io/latest/delta-batch.html#schema-validation
[公式ドキュメントのスキーママージ]: https://docs.delta.io/latest/delta-batch.html#add-columns
[公式ドキュメントのスキーマ上書き]: https://docs.delta.io/latest/delta-batch.html#replace-table-schema
[公式ドキュメントのマージの例]: https://docs.delta.io/latest/delta-update.html#merge-examples
[公式ドキュメントのマージを使った上書き]: https://docs.delta.io/latest/delta-update.html#data-deduplication-when-writing-into-delta-tables
[Slowly changing data (SCD) Type 2 operation]: https://docs.delta.io/latest/delta-update.html#slowly-changing-data-scd-type-2-operation-into-delta-tables
[Write change data into a Delta table]: https://docs.delta.io/latest/delta-update.html#write-change-data-into-a-delta-table
[Upsert from streaming queries using foreachBatch]: https://docs.delta.io/latest/delta-update.html#upsert-from-streaming-queries-using-foreachbatch
[org.apache.spark.sql.streaming.DataStreamWriter#foreachBatch]: https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#foreachbatch
[公式ドキュメントのVacuum]: https://docs.delta.io/latest/delta-utility.html#vacuum
[Presto and Athena to Delta Lake Integration]: https://docs.delta.io/0.5.0/presto-integration.html
[Presto Athena連係の制約]: https://docs.delta.io/0.5.0/presto-integration.html#limitations

# メモ

## 公式ドキュメントのうち気になったところのメモ（2019/5時点のメモ）

以下、ポイントの記載。あくまでドキュメント上の話。

### Sparkのユーザから見たときにはデータソースとして使えばよいようになっている

SparkにはData Sourceの仕組みがあるが、その１種として使えるようになっている。
したがって、DatasetやDataFrameで定義したデータを読み書きするデータソースの１種類として考えて使えば自然に使えるようになっている。

### スキーマの管理

通常のSpark APIでは、DataFrameを出力するときに過去のデータのスキーマを考慮したりしないが、
Delta Lakeを用いると過去のスキーマを考慮した振る舞いをさせることができる。
例えば、「スキーマを更新させない（意図しない更新が発生しているときにはエラーを吐かせるなど）」、
「既存のスキーマを利用して部分的な更新」などが可能。

またカラムの追加など、言ってみたら、スキーマの自動更新みたいなことも可能。

### ストリームとバッチの両対応

[ストリームへの対応についての説明] に記載があるが、Spark Structured Streamingの読み書き宛先として利用可能。
ストリーム処理では「Exactly Once」セマンティクスの保証が大変だったりするが、
そのあたりをDelta Lake層で考慮してくれる、などの利点が挙げられる。

Dalta Lake自身が差分管理の仕組みを持っているので、その仕組みを使って読み書きさせるのだろう、という想像。

なお、入力元としてDelta Lakeを想定した場合、「レコードの削除」、「レコードの更新」が発生することが
考えうる。それを入力元としてどう扱うか？を設定するパラメータがある。

* ignoreDeletes: 過去レコードの削除を下流に伝搬しない
* ignoreChanges: 上記に加え、更新されたレコードを含むファイルの内容全体を下流に伝搬させる

出力先としてDelta Lakeを想定した場合、トランザクションの仕組みを用いられるところが特徴となる。
つまり複数のストリーム処理アプリケーションが同じテーブルに出力するときにも適切にハンドルできるようになり、
出力先も含めたExactly Onceを実現可能になる。

## Databrciksドキュメントの気になったところのメモ（2019/5時点のメモ）

全体的な注意点として、Databricksのドキュメントなので、Databricksクラウド特有の話が含まれている可能性があることが挙げられる。

### データリテンション

[データ・リテンション] に記述あり。
デフォルトでは30日間のコミットログが保持される、とのこと。
VACUUM句を用いて縮めることができるようだ。

VACUUMについては、[VACUUM]を参照のこと。

### 最適化

[最適化] に記載がある。コンパクションやZ-Orderingなど。
Databricksクラウド上でSQL文で発行するようだ。

## クイックスタートから実装を追ってみる（2019/5時点でのメモ）

[公式クイックスタート] を参照しながら実装を確認してみる。

上記によると、まずはSBTでは以下の依存関係を追加することになっている。
```
libraryDependencies += "io.delta" %% "delta-core" % "0.1.0"
```

[Create a tableの章] には、バッチ処理での書き込みについて以下のような例が記載されていた。

[Create a tableの章]: https://docs.delta.io/latest/quick-start.html#create-a-table

```scala
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;

SparkSession spark = ...   // create SparkSession

Dataset<Row> data = data = spark.range(0, 5);
data.write().format("delta").save("/tmp/delta-table");
```

SparkのData Sourcesの仕組みとして扱えるようになっている。

テストコードで言えば、 `org/apache/spark/sql/delta/DeltaSuiteOSS.scala:24` あたりを眺めるとよいのではないか。

バッチ方式では、以下のようなテストが実装されている。

```scala
  test("append then read") {
    val tempDir = Utils.createTempDir()
    Seq(1).toDF().write.format("delta").save(tempDir.toString)
    Seq(2, 3).toDF().write.format("delta").mode("append").save(tempDir.toString)

    def data: DataFrame = spark.read.format("delta").load(tempDir.toString)
    checkAnswer(data, Row(1) :: Row(2) :: Row(3) :: Nil)

    // append more
    Seq(4, 5, 6).toDF().write.format("delta").mode("append").save(tempDir.toString)
    checkAnswer(data.toDF(), Row(1) :: Row(2) :: Row(3) :: Row(4) :: Row(5) :: Row(6) :: Nil)
  }
```


ストリーム方式では以下のようなテストが実装されている。


```scala
  test("append mode") {
    failAfter(streamingTimeout) {
      withTempDirs { (outputDir, checkpointDir) =>
        val inputData = MemoryStream[Int]
        val df = inputData.toDF()
        val query = df.writeStream
          .option("checkpointLocation", checkpointDir.getCanonicalPath)
          .format("delta")
          .start(outputDir.getCanonicalPath)
        val log = DeltaLog.forTable(spark, outputDir.getCanonicalPath)
        try {
          inputData.addData(1)
          query.processAllAvailable()

          val outputDf = spark.read.format("delta").load(outputDir.getCanonicalPath)
          checkDatasetUnorderly(outputDf.as[Int], 1)
          assert(log.update().transactions.head == (query.id.toString -> 0L))

          inputData.addData(2)
          query.processAllAvailable()

          checkDatasetUnorderly(outputDf.as[Int], 1, 2)
          assert(log.update().transactions.head == (query.id.toString -> 1L))

          inputData.addData(3)
          query.processAllAvailable()

          checkDatasetUnorderly(outputDf.as[Int], 1, 2, 3)
          assert(log.update().transactions.head == (query.id.toString -> 2L))
        } finally {
          query.stop()
        }
      }
    }
  }
```

### ひとまずRelationを調べて見る

いったんData Source V1だと仮定 [^DataSourceV1] して、createRelationメソッドを探したところ、
`org.apache.spark.sql.delta.sources.DeltaDataSource#createRelation` あたりを眺めると、
実態としては

org/apache/spark/sql/delta/sources/DeltaDataSource.scala:148
```
    deltaLog.createRelation()
```

が戻り値を返しているようだ。
このメソッドは、以下のように内部的には`org.apache.spark.sql.execution.datasources.HadoopFsRelation`クラスを
用いている。というより、うまいことほぼ流用している。
以下のような実装。

org/apache/spark/sql/delta/DeltaLog.scala:600
```
    new HadoopFsRelation(
      fileIndex,
      partitionSchema = snapshotToUse.metadata.partitionSchema,
      dataSchema = snapshotToUse.metadata.schema,
      bucketSpec = None,
      snapshotToUse.fileFormat,
      snapshotToUse.metadata.format.options)(spark) with InsertableRelation {
      def insert(data: DataFrame, overwrite: Boolean): Unit = {
        val mode = if (overwrite) SaveMode.Overwrite else SaveMode.Append
        WriteIntoDelta(
          deltaLog = DeltaLog.this,
          mode = mode,
          new DeltaOptions(Map.empty[String, String], spark.sessionState.conf),
          partitionColumns = Seq.empty,
          configuration = Map.empty,
          data = data).run(spark)
      }
    }
```

`insert`メソッドでDelta Lake独自の書き込み方式を実行する処理を定義している。

[^DataSourceV1]: その後の確認でやはりv1利用のように見えた。（2020/2時点）

なお、runの中で`org.apache.spark.sql.delta.DeltaOperations`内で定義されたWriteオペレーションを実行するように
なっているのだが、そこでは`org.apache.spark.sql.delta.OptimisticTransaction`を用いるようになっている。
要は、Optimistic Concurrency Controlの考え方を応用した実装になっているのではないかと想像。 [^OptimisticTransaction]

[^OptimisticTransaction]: その後の調査（2020/2時点）で改めて楽観ロックの仕組みで実現されていることを確認

※ [Delta LakeのOptimistic Concurrency Controlに関する記述] にその旨記載されているようだ。

また、上記の通り、データは`DeltaLog`クラスを経由して管理される。

実際にデータが書き込まれると思われる `org.apache.spark.sql.delta.commands.WriteIntoDelta#write` を眺めてよう。

最初にメタデータ更新？

org/apache/spark/sql/delta/commands/WriteIntoDelta.scala:87
```
    updateMetadata(txn, data, partitionColumns, configuration, isOverwriteOperation)
```
updateMetadataメソッドでは、内部的に以下の処理を実施。

* スキーマをマージ
* 「パーティションカラム」のチェック（パーティションカラムに指定された名前を持つ「複数のカラム」がないかどうか、など）
* replaceWhereオプション（ [DataFrameを使った上書き] 参照）によるフィルタ構成

★2019/5時点では、ここで調査が止まっていた。これ以降に続く実装調査については、 [動作確認しながら実装確認](#動作確認しながら実装確認) を参照

## Data Source V1とV2

`org.apache.spark.sql.delta.sources.DeltaDataSource` あたりがData Source V1向けの実装のエントリポイントか。
これを見る限り、V1で実装されているように見える…？

## 設定の類

`org.apache.spark.sql.delta.sources.DeltaSQLConf` あたりが設定か。

`spark.databricks.delta.$key`で指定可能なようだ。

## チェックポイントを調査してみる

チェックポイントは、その名の通り、将来のリプレイ時にショートカットするための機能。
スナップショットからチェックポイントを作成する。

エントリポイントは、 `org.apache.spark.sql.delta.Checkpoints` だろうか。
ひとまず、 `org.apache.spark.sql.delta.Checkpoints#checkpoint` メソッドを見つけた。

org/apache/spark/sql/delta/Checkpoints.scala:118
```
  def checkpoint(): Unit = recordDeltaOperation(this, "delta.checkpoint") {
    val checkpointMetaData = checkpoint(snapshot)
    val json = JsonUtils.toJson(checkpointMetaData)
    store.write(LAST_CHECKPOINT, Iterator(json), overwrite = true)

    doLogCleanup()
  }
```

実態は、`org.apache.spark.sql.delta.Checkpoints$#writeCheckpoint` メソッドか。

org/apache/spark/sql/delta/Checkpoints.scala:126
```
  protected def checkpoint(snapshotToCheckpoint: Snapshot): CheckpointMetaData = {
    Checkpoints.writeCheckpoint(spark, this, snapshotToCheckpoint)
  }
```

ちなみに、 `org.apache.spark.sql.delta.Checkpoints$#writeCheckpoint` メソッド内ではややトリッキーな方法でチェックポイントの書き出しを行っている。

`org.apache.spark.sql.delta.Checkpoints#checkpoint()` メソッドが呼び出されるのは、
以下のようにOptimistic Transactionのポストコミット処理中である。

org/apache/spark/sql/delta/OptimisticTransaction.scala:294
```
  protected def postCommit(commitVersion: Long, committActions: Seq[Action]): Unit = {
    committed = true
    if (commitVersion != 0 && commitVersion % deltaLog.checkpointInterval == 0) {
      try {
        deltaLog.checkpoint()
      } catch {
        case e: IllegalStateException =>
          logWarning("Failed to checkpoint table state.", e)
      }
    }
  }
```

呼び出されるタイミングは予め設定されたインターバルのパラメータに依存する。

ということは、数回に1回はチェックポイント書き出しが行われるため、そのあたりでパフォーマンス上の影響があるのではないか、と想像される。

### スナップショットについて

関連事項として、スナップショットも調査。
スナップショットが作られるタイミングの **一例** としては、`org.apache.spark.sql.delta.DeltaLog#updateInternal`メソッドが
呼ばれるタイミングが挙げられる。
updateInternalメソッドは `org.apache.spark.sql.delta.DeltaLog#update` メソッド内で呼ばれる。
updateメソッドが呼ばれるタイミングはいくつかあるが、例えばトランザクション開始時に呼ばれる流れも存在する。
つまり、トランザクションを開始する前にはいったんスナップショットが定義されることがわかった。

その他にも、 `org.apache.spark.sql.delta.sources.DeltaDataSource#createRelation` メソッドの処理から実行されるケースもある。

このように、いくつかのタイミングでスナップショットが定義（最新化？）されるようになっている。

## 動作確認しながら実装確認（v0.5.0）

### クイックスタートの書き込み

[公式ドキュメント（クイックスタート）] を見る限り、
シェルで利用する分には `--package` などでDelta Lakeのパッケージを指定すれば良い。

```shell
$ <path to spark home>/bin/spark-shell --packages io.delta:delta-core_2.11:0.5.0
```

クイックスタートの例を実行する。

```scala
val data = spark.range(0, 5)
data.write.format("delta").save("/tmp/delta-table")
```

実際に出力されたParquetファイルは以下の通り。

```shell
$ ls -R /tmp/delta-table/
/tmp/delta-table/:
_delta_log                                                           part-00003-93af5943-2745-42e8-9ac6-c001f257f3a8-c000.snappy.parquet  part-00007-8ed33d7c-5634-4739-afbb-471961bec689-c000.snappy.parquet
part-00000-26d26a0d-ad19-44ac-aa78-046d1709e28b-c000.snappy.parquet  part-00004-11001300-1797-4a69-9155-876319eb2d00-c000.snappy.parquet
part-00001-6e4655ff-555e-441d-bdc9-68176e630936-c000.snappy.parquet  part-00006-94de7a9e-4dbd-4b50-b33c-949ae38dc676-c000.snappy.parquet

/tmp/delta-table/_delta_log:
00000000000000000000.json
```

これをデバッガをアタッチして、動作状況を覗いてみることにする。

```shell
$ <path to spark home>/bin/spark-shell --packages io.delta:delta-core_2.11:0.5.0 --driver-java-options -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005
```

Intellijなどでデバッガをアタッチする。

机上調査があっているか確認するため、 `org.apache.spark.sql.delta.sources.DeltaDataSource#createRelation` に
ブレイクポイントを設定して動作確認。

src/main/scala/org/apache/spark/sql/delta/sources/DeltaDataSource.scala:119

```scala
    val path = parameters.getOrElse("path", {
      throw DeltaErrors.pathNotSpecifiedException
    })
    val partitionColumns = parameters.get(DeltaSourceUtils.PARTITIONING_COLUMNS_KEY)
      .map(DeltaDataSource.decodePartitioningColumns)
      .getOrElse(Nil)

```

パスとパーティション指定するカラムを確認。
上記の例では、 `/tmp/delta-table` と `Nil` が戻り値になる。

src/main/scala/org/apache/spark/sql/delta/sources/DeltaDataSource.scala:126

```scala
    val deltaLog = DeltaLog.forTable(sqlContext.sparkSession, path)
```

DeltaLogのインスタンスを受け取る。

つづいて、 `org.apache.spark.sql.delta.commands.WriteIntoDelta#run` メソッドが呼び出される。

src/main/scala/org/apache/spark/sql/delta/commands/WriteIntoDelta.scala:63

```scala
  override def run(sparkSession: SparkSession): Seq[Row] = {
    deltaLog.withNewTransaction { txn =>
      val actions = write(txn, sparkSession)
      val operation = DeltaOperations.Write(mode, Option(partitionColumns), options.replaceWhere)
      txn.commit(actions, operation)
    }
    Seq.empty
  }
```

`withNewTransaction` 内で、 `org.apache.spark.sql.delta.commands.WriteIntoDelta#write`が呼び出される。
つまり、ここでトランザクションが開始され、下記の記載の通り、最終的にコミットされることになる。

いったん `withNewTransaction` の中で行われる処理に着目する。
まずはメタデータ（スキーマ？など？）が更新される。

src/main/scala/org/apache/spark/sql/delta/commands/WriteIntoDelta.scala:85

```scala
    updateMetadata(txn, data, partitionColumns, configuration, isOverwriteOperation, rearrangeOnly)
```

つづいて、"reaplaceWhere" 機能（パーティション列に対し、述語に一致するデータのみを置き換える機能）の
フィルタを算出する。

```scala
    val replaceWhere = options.replaceWhere
    val partitionFilters = if (replaceWhere.isDefined) {
      val predicates = parsePartitionPredicates(sparkSession, replaceWhere.get)
      if (mode == SaveMode.Overwrite) {
        verifyPartitionPredicates(
          sparkSession, txn.metadata.partitionColumns, predicates)
      }
      Some(predicates)
    } else {
      None
    }
```

つづいて、 `org.apache.spark.sql.delta.files.TransactionalWrite#writeFiles` メソッドが呼び出される。

src/main/scala/org/apache/spark/sql/delta/commands/WriteIntoDelta.scala:105

```scala
    val newFiles = txn.writeFiles(data, Some(options))
```

内部的には、 `org.apache.spark.sql.execution.datasources.FileFormatWriter#write` を用いて
与えられた `data` （＝DataFrame つまり Dataset）を書き出す処理（物理プラン）を実行する。

ここでのポイントは、割と直接的にSparkのDataSourcesの機能を利用しているところだ。
実装が簡素になる代わりに、Sparkに強く依存していることがわかる。

また、newFilesには出力PATHに作られるファイル群の情報（実際にはcase classのインスタンス）が含まれる。

ここで `org.apache.spark.sql.delta.commands.WriteIntoDelta#write` の呼び出し元、
`org.apache.spark.sql.delta.commands.WriteIntoDelta#run` に戻る。

writeが呼ばれたあとは、オペレーション情報がインスタンス化される。

src/main/scala/org/apache/spark/sql/delta/commands/WriteIntoDelta.scala:66

```scala
      val operation = DeltaOperations.Write(mode, Option(partitionColumns), options.replaceWhere)
```

上記のアクションとオペレーション情報を合わせて、以下のようにコミットされる。

src/main/scala/org/apache/spark/sql/delta/commands/WriteIntoDelta.scala:67

```scala
      txn.commit(actions, operation)
```

### クイックスタートの読み込み

[公式ドキュメント（クイックスタート）] には以下のような簡単な例が載っている。

```scala
val df = spark.read.format("delta").load("/tmp/delta-table")
df.show()
```

デバッガをアタッチしながら動作を確認しよう。

まず最初の

```scala
val df = spark.read.format("delta").load("/tmp/delta-table")
```

により、SparkのDataSourceの仕組みに基づいて、リレーションが生成される。
`org.apache.spark.sql.delta.sources.DeltaDataSource#createRelation` メソッドあたりを読み解く。

src/main/scala/org/apache/spark/sql/delta/sources/DeltaDataSource.scala:149

```scala
    val maybeTimeTravel =
      DeltaTableUtils.extractIfPathContainsTimeTravel(sqlContext.sparkSession, maybePath)
```

最初にタイムトラベル対象かどうかを判定する。タイムトラベル自体は別途。

src/main/scala/org/apache/spark/sql/delta/sources/DeltaDataSource.scala:159

```scala
    val hadoopPath = new Path(path)
    val rootPath = DeltaTableUtils.findDeltaTableRoot(sqlContext.sparkSession, hadoopPath)
      .getOrElse {
        val fs = hadoopPath.getFileSystem(sqlContext.sparkSession.sessionState.newHadoopConf())
        if (!fs.exists(hadoopPath)) {
          throw DeltaErrors.pathNotExistsException(path)
        }
        hadoopPath
      }

```

つづいて、Hadoopの機能を利用し、下回りのデータストアのファイルシステムを取得する。
このあたりでHadoopの機能を利用しているあたりが、HadoopやSparkを前提としたシステムであることがわかる。

また、一貫性を考えると、通常のHadoopやSparkを利用するときと同様に、
S3で一貫性を担保する仕組み（例えばs3a、s3ガードなど）を利用したほうが良いだろう。

src/main/scala/org/apache/spark/sql/delta/sources/DeltaDataSource.scala:169

```scala
    val deltaLog = DeltaLog.forTable(sqlContext.sparkSession, rootPath)
```

つづいて、DeltaLogインスタンスが生成される。
これにより、ログファイルに対する操作を開始できるようになる。（ここでは読み取りだが、書き込みも対応可能になる）

src/main/scala/org/apache/spark/sql/delta/sources/DeltaDataSource.scala:171

```scala
    val partitionFilters = if (rootPath != hadoopPath) {

(snip)

      if (files.count() == 0) {
        throw DeltaErrors.pathNotExistsException(path)
      }
      filters
    } else {
      Nil
    }
```

パーティションの読み込みかどうかを検知。
ただし、Delta LakeではパーティションのPATHを直接指定するのは推奨されておらず、where句を使うのが推奨されている。

src/main/scala/org/apache/spark/sql/delta/sources/DeltaDataSource.scala:210

```scala
    deltaLog.createRelation(partitionFilters, timeTravelByParams.orElse(timeTravelByPath))
```

最後に、実際にリレーションを生成し、戻り値とする。

なお、 `org.apache.spark.sql.delta.DeltaLog#createDataFrame` メソッドは以下の通り。

src/main/scala/org/apache/spark/sql/delta/DeltaLog.scala:630

```scala
  def createRelation(
      partitionFilters: Seq[Expression] = Nil,
      timeTravel: Option[DeltaTimeTravelSpec] = None): BaseRelation = {

(snip)

    new HadoopFsRelation(
      fileIndex,
      partitionSchema = snapshotToUse.metadata.partitionSchema,
      dataSchema = snapshotToUse.metadata.schema,
      bucketSpec = None,
      snapshotToUse.fileFormat,
      snapshotToUse.metadata.format.options)(spark) with InsertableRelation {
      def insert(data: DataFrame, overwrite: Boolean): Unit = {
        val mode = if (overwrite) SaveMode.Overwrite else SaveMode.Append
        WriteIntoDelta(
          deltaLog = DeltaLog.this,
          mode = mode,
          new DeltaOptions(Map.empty[String, String], spark.sessionState.conf),
          partitionColumns = Seq.empty,
          configuration = Map.empty,
          data = data).run(spark)
      }
    }
  }
}
```

#### TahoeLogFileIndex

なお、生成されたDataFrameのプランを確認すると以下のように表示される。

```
scala> df.explain
== Physical Plan ==
*(1) FileScan parquet [id#778L] Batched: true, Format: Parquet, Location: TahoeLogFileIndex[file:/tmp/delta-table], PartitionFilters: [], PushedFilters: [], ReadSchema: struct<id:bigint>
```

`TahoeLogFileIndex` はDelta Lakeが実装しているFileIndexの一種。

クラス階層は以下の通り。

* TahoeFileIndex (org.apache.spark.sql.delta.files)
  * TahoeBatchFileIndex (org.apache.spark.sql.delta.files)
  * TahoeLogFileIndex (org.apache.spark.sql.delta.files)

親クラスの `TahoeFileIndex` は、以下の通り `FileIndex`を継承している。

org/apache/spark/sql/delta/files/TahoeFileIndex.scala:35

```scala
abstract class TahoeFileIndex(
    val spark: SparkSession,
    val deltaLog: DeltaLog,
    val path: Path) extends FileIndex {
```

`TahoeFileIndex` のJavaDocには、

> A [[FileIndex]] that generates the list of files managed by the Tahoe protocol.

とあり、「Tahoeプロトコル」なるものを通じて、SparkのFileIndex機能を実現する。

例えば、showメソッドを呼び出すと、

```scala
scala> df.show()
```

実行の途中で、 `org.apache.spark.sql.delta.files.TahoeFileIndex#listFiles` メソッドが呼び出される。

以下、listFiles内での動作を軽く確認する。

org/apache/spark/sql/delta/files/TahoeFileIndex.scala:56

```scala
    matchingFiles(partitionFilters, dataFilters).groupBy(_.partitionValues).map {
```

まず、 `org.apache.spark.sql.delta.files.TahoeFileIndex#matchingFiles` メソッドが呼ばれ、
`AddFile` インスタンスのシーケンスが返される。

org/apache/spark/sql/delta/files/TahoeFileIndex.scala:129

```scala
  override def matchingFiles(
      partitionFilters: Seq[Expression],
      dataFilters: Seq[Expression],
      keepStats: Boolean = false): Seq[AddFile] = {
    getSnapshot(stalenessAcceptable = false).filesForScan(
      projection = Nil, this.partitionFilters ++ partitionFilters ++ dataFilters, keepStats).files
  }
```

上記の通り、戻り値は `Seq[AddFile]` である。

そこで `matchingFiles` メソッドの戻り値をグループ化した後は、mapメソッドにより、
以下のような処理が実行される。

org/apache/spark/sql/delta/files/TahoeFileIndex.scala:57

```scala
      case (partitionValues, files) =>
        val rowValues: Array[Any] = partitionSchema.map { p =>
          Cast(Literal(partitionValues(p.name)), p.dataType, Option(timeZone)).eval()
        }.toArray


        val fileStats = files.map { f =>
          new FileStatus(
            /* length */ f.size,
            /* isDir */ false,
            /* blockReplication */ 0,
            /* blockSize */ 1,
            /* modificationTime */ f.modificationTime,
            absolutePath(f.path))
        }.toArray

        PartitionDirectory(new GenericInternalRow(rowValues), fileStats)
```

参考までに、このとき、 `files` には以下のような値が入っている。

```
files = {WrappedArray$ofRef@19711} "WrappedArray$ofRef" size = 6
 0 = {AddFile@19694} "AddFile(part-00004-11001300-1797-4a69-9155-876319eb2d00-c000.snappy.parquet,Map(),429,1582472443000,false,null,null)"
 1 = {AddFile@19719} "AddFile(part-00003-93af5943-2745-42e8-9ac6-c001f257f3a8-c000.snappy.parquet,Map(),429,1582472443000,false,null,null)"
 2 = {AddFile@19720} "AddFile(part-00000-26d26a0d-ad19-44ac-aa78-046d1709e28b-c000.snappy.parquet,Map(),262,1582472443000,false,null,null)"
 3 = {AddFile@19721} "AddFile(part-00006-94de7a9e-4dbd-4b50-b33c-949ae38dc676-c000.snappy.parquet,Map(),429,1582472443000,false,null,null)"
 4 = {AddFile@19722} "AddFile(part-00001-6e4655ff-555e-441d-bdc9-68176e630936-c000.snappy.parquet,Map(),429,1582472443000,false,null,null)"
 5 = {AddFile@19723} "AddFile(part-00007-8ed33d7c-5634-4739-afbb-471961bec689-c000.snappy.parquet,Map(),429,1582472443000,false,null,null)"
```

ここまでが `org.apache.spark.sql.execution.datasources.FileIndex#listFiles` メソッドの内容である。

#### （参考）TahoeFileIndexがどこから呼ばれるか

ここではSpark v2.4.2を確認する。

`org.apache.spark.sql.Dataset#show` メソッドでは、内部的に `org.apache.spark.sql.Dataset#showString` メソッドを呼び出す。

org/apache/spark/sql/Dataset.scala:744

```scala
  def show(numRows: Int, truncate: Boolean): Unit = if (truncate) {
    println(showString(numRows, truncate = 20))
  } else {
    println(showString(numRows, truncate = 0))
  }
```

`org.apache.spark.sql.Dataset#showString` メソッド内で、
`org.apache.spark.sql.Dataset#getRows` メソッドが呼ばれる。

org/apache/spark/sql/Dataset.scala:285

```scala
  private[sql] def showString(
      _numRows: Int,
      truncate: Int = 20,
      vertical: Boolean = false): String = {
    val numRows = _numRows.max(0).min(ByteArrayMethods.MAX_ROUNDED_ARRAY_LENGTH - 1)
    // Get rows represented by Seq[Seq[String]], we may get one more line if it has more data.
    val tmpRows = getRows(numRows, truncate)

(snip)
```

`org.apache.spark.sql.Dataset#getRows` メソッド内では、 `org.apache.spark.sql.Dataset#take` メソッドが呼ばれる。

org/apache/spark/sql/Dataset.scala:241

```scala
  private[sql] def getRows(

(snip)

    val data = newDf.select(castCols: _*).take(numRows + 1)
  
(snip)
```

`org.apache.spark.sql.Dataset#take` メソッドでは `org.apache.spark.sql.Dataset#head(int)` メソッドが呼ばれる。

org/apache/spark/sql/Dataset.scala:2758

```scala
  def take(n: Int): Array[T] = head(n)
```

`org.apache.spark.sql.Dataset#head` メソッド内で、 `org.apache.spark.sql.Dataset#withAction` を用いて、
`org.apache.spark.sql.Dataset#collectFromPlan` メソッドが呼ばれる。

org/apache/spark/sql/Dataset.scala:2544

```scala
  def head(n: Int): Array[T] = withAction("head", limit(n).queryExecution)(collectFromPlan)
```


`org.apache.spark.sql.Dataset#collectFromPlan` メソッド内で `org.apache.spark.sql.execution.SparkPlan#executeCollect` メソッドが呼ばれる。

org/apache/spark/sql/Dataset.scala:3379

```scala
  private def collectFromPlan(plan: SparkPlan): Array[T] = {
    // This projection writes output to a `InternalRow`, which means applying this projection is not
    // thread-safe. Here we create the projection inside this method to make `Dataset` thread-safe.
    val objProj = GenerateSafeProjection.generate(deserializer :: Nil)
    plan.executeCollect().map { row =>
      // The row returned by SafeProjection is `SpecificInternalRow`, which ignore the data type
      // parameter of its `get` method, so it's safe to use null here.
      objProj(row).get(0, null).asInstanceOf[T]
    }
  }
```

なお、 `org.apache.spark.sql.execution.CollectLimitExec` のcase classインスタンス化の中で、
`org.apache.spark.sql.execution.CollectLimitExec#executeCollect` が以下のように定義されている。

org/apache/spark/sql/execution/limit.scala:35

```scala
case class CollectLimitExec(limit: Int, child: SparkPlan) extends UnaryExecNode {
  override def output: Seq[Attribute] = child.output
  override def outputPartitioning: Partitioning = SinglePartition
  override def executeCollect(): Array[InternalRow] = child.executeTake(limit)

(snip)
```

そこで、 `org.apache.spark.sql.execution.SparkPlan#executeTake` メソッドに着目していく。
当該メソッド内で、 `org.apache.spark.sql.execution.SparkPlan#getByteArrayRdd` メソッドが呼ばれ、 `childRDD` が生成される。

org/apache/spark/sql/execution/SparkPlan.scala:334

```scala
  def executeTake(n: Int): Array[InternalRow] = {
    if (n == 0) {
      return new Array[InternalRow](0)
    }

    val childRDD = getByteArrayRdd(n).map(_._2)
```

`org.apache.spark.sql.execution.SparkPlan#getByteArrayRdd` メソッドの実装は以下の通りで、
内部的に `org.apache.spark.sql.execution.SparkPlan#execute` メソッドが呼ばれる。

```scala
  private def getByteArrayRdd(n: Int = -1): RDD[(Long, Array[Byte])] = {
    execute().mapPartitionsInternal { iter =>
      var count = 0

(snip)
```

`org.apache.spark.sql.execution.SparkPlan#execute` メソッド内で `org.apache.spark.sql.execution.SparkPlan#executeQuery` を利用し、
その内部で`org.apache.spark.sql.execution.SparkPlan#doExecute` メソッドが呼ばれる。

org/apache/spark/sql/execution/SparkPlan.scala:127

```scala
  final def execute(): RDD[InternalRow] = executeQuery {
    if (isCanonicalizedPlan) {
      throw new IllegalStateException("A canonicalized plan is not supposed to be executed.")
    }
    doExecute()
  }
```

参考までに、`org.apache.spark.sql.execution.SparkPlan#executeQuery` 内では、
`org.apache.spark.rdd.RDDOperationScope#withScope` を使ってクエリが実行される。

org/apache/spark/sql/execution/SparkPlan.scala:151

```scala
  protected final def executeQuery[T](query: => T): T = {
    RDDOperationScope.withScope(sparkContext, nodeName, false, true) {
      prepare()
      waitForSubqueries()
      query
    }
  }
```

つづいて、 `doExecute` メソッドの確認に戻る。

`org.apache.spark.sql.execution.WholeStageCodegenExec#doExecute` メソッド内で、
`org.apache.spark.sql.execution.CodegenSupport#inputRDDs` メソッドが呼ばれる。

```scala
  override def doExecute(): RDD[InternalRow] = {

(snip)

    val durationMs = longMetric("pipelineTime")

    val rdds = child.asInstanceOf[CodegenSupport].inputRDDs()
    assert(rdds.size <= 2, "Up to two input RDDs can be supported")

(snip)
```

`inputRDDs` メソッド内でinputRDDが呼び出される。

org/apache/spark/sql/execution/DataSourceScanExec.scala:326

```scala
  override def inputRDDs(): Seq[RDD[InternalRow]] = {
    inputRDD :: Nil
  }
```

`inputRDD` にRDDインスタンスをバインドする際、その中で `org.apache.spark.sql.execution.FileSourceScanExec#createNonBucketedReadRDD` メソッドが呼ばれ、
そこに渡される `readFile` メソッドが実行される。

org/apache/spark/sql/execution/DataSourceScanExec.scala:305

```scala
  private lazy val inputRDD: RDD[InternalRow] = {
    // Update metrics for taking effect in both code generation node and normal node.
    updateDriverMetrics()
    val readFile: (PartitionedFile) => Iterator[InternalRow] =
      relation.fileFormat.buildReaderWithPartitionValues(
        sparkSession = relation.sparkSession,
        dataSchema = relation.dataSchema,
        partitionSchema = relation.partitionSchema,
        requiredSchema = requiredSchema,
        filters = pushedDownFilters,
        options = relation.options,
        hadoopConf = relation.sparkSession.sessionState.newHadoopConfWithOptions(relation.options))

    relation.bucketSpec match {
      case Some(bucketing) if relation.sparkSession.sessionState.conf.bucketingEnabled =>
        createBucketedReadRDD(bucketing, readFile, selectedPartitions, relation)
      case _ =>
        createNonBucketedReadRDD(readFile, selectedPartitions, relation)
    }
  }
```

`readFile` メソッドを一緒に `org.apache.spark.sql.execution.FileSourceScanExec#createNonBucketedReadRDD` メソッドに渡されている
`org.apache.spark.sql.execution.FileSourceScanExec#selectedPartitions` は以下のように定義される。
`Seq[PartitionDirectory]` のインスタンスを `selectedPartitions` にバインドする際に、
`org.apache.spark.sql.execution.datasources.FileIndex#listFiles` メソッドが呼び出される。

org/apache/spark/sql/execution/DataSourceScanExec.scala:190

```
  @transient private lazy val selectedPartitions: Seq[PartitionDirectory] = {
    val optimizerMetadataTimeNs = relation.location.metadataOpsTimeNs.getOrElse(0L)
    val startTime = System.nanoTime()
    val ret = relation.location.listFiles(partitionFilters, dataFilters)
    val timeTakenMs = ((System.nanoTime() - startTime) + optimizerMetadataTimeNs) / 1000 / 1000
    metadataTime = timeTakenMs
    ret
  }
```

このとき、具象クラス側の `listFiles` メソッドが呼ばれることになるが、
`TahoeLogFileIndex` クラスの場合は、親クラスのメソッド `org.apache.spark.sql.delta.files.TahoeFileIndex#listFiles` が呼ばれる。
当該メソッドの内容は、上記で示したとおり。

### クイックスタートの更新時

[公式ドキュメント（クイックスタート）] には
以下のような例が載っている。

```scala
val data = spark.range(5, 10)
data.write.format("delta").mode("overwrite").save("/tmp/delta-table")
```
上記を実行した際のデータ保存ディレクトリの構成は以下の通り。

```shell
$ ls -R /tmp/delta-table/
/tmp/delta-table/:
_delta_log                                                           part-00004-11001300-1797-4a69-9155-876319eb2d00-c000.snappy.parquet
part-00000-191c798b-3202-4fdf-9447-891f19953a37-c000.snappy.parquet  part-00004-62735ceb-255f-4349-b043-d14d798f653a-c000.snappy.parquet
part-00000-26d26a0d-ad19-44ac-aa78-046d1709e28b-c000.snappy.parquet  part-00006-94de7a9e-4dbd-4b50-b33c-949ae38dc676-c000.snappy.parquet
part-00001-6e4655ff-555e-441d-bdc9-68176e630936-c000.snappy.parquet  part-00006-f5cb90a2-06bd-46ec-af61-9490bdd4321c-c000.snappy.parquet
part-00001-b3bcd196-dc8b-43b8-ad43-f73ecac35ccb-c000.snappy.parquet  part-00007-6431fca3-bf2c-4ad7-a42c-a2e18feb3ed7-c000.snappy.parquet
part-00003-7fed5d2a-0ba9-4dcf-bc8d-ad9c729884e3-c000.snappy.parquet  part-00007-8ed33d7c-5634-4739-afbb-471961bec689-c000.snappy.parquet
part-00003-93af5943-2745-42e8-9ac6-c001f257f3a8-c000.snappy.parquet

/tmp/delta-table/_delta_log:
00000000000000000000.json  00000000000000000001.json
```
`00000000000000000001.json` の内容は以下の通り。

```json
{
  "commitInfo": {
    "timestamp": 1582681285873,
    "operation": "WRITE",
    "operationParameters": {
      "mode": "Overwrite",
      "partitionBy": "[]"
    },
    "readVersion": 0,
    "isBlindAppend": false
  }
}
{
  "add": {
    "path": "part-00000-191c798b-3202-4fdf-9447-891f19953a37-c000.snappy.parquet",
    "partitionValues": {},
    "size": 262,
    "modificationTime": 1582681285000,
    "dataChange": true
  }
}

(snip)
```

確かに上書きモードで書き込まれたことが確かめられる。

このモードは、例えば `org.apache.spark.sql.delta.commands.WriteIntoDelta` で用いられる。
上記の


```scala
data.write.format("delta").mode("overwrite").save("/tmp/delta-table")
```

が呼ばれるときに、内部的に `org.apache.spark.sql.delta.commands.WriteIntoDelta#run` メソッドが呼ばれ、
以下のように、 `mode` が渡される。

org/apache/spark/sql/delta/commands/WriteIntoDelta.scala:63

```scala
  override def run(sparkSession: SparkSession): Seq[Row] = {
    deltaLog.withNewTransaction { txn =>
      val actions = write(txn, sparkSession)
      val operation = DeltaOperations.Write(mode, Option(partitionColumns), options.replaceWhere)
      txn.commit(actions, operation)
    }
    Seq.empty
  }
```

なお、overwriteモードを指定しないと、 `mode` には `ErrorIfExists` が渡される。
モードの詳細は、enum `org.apache.spark.sql.SaveMode` （Spark SQL）を参照。
（例えば、他にも `append` や `Ignore` あたりも指定可能そうではある）


### クイックスタートのストリームデータ読み書き

[公式ドキュメント（クイックスタート）] には以下の例が載っていた。

```scala
scala> val streamingDf = spark.readStream.format("rate").load()
scala> val stream = streamingDf.select($"value" as "id").writeStream.format("delta").option("checkpointLocation", "/tmp/checkpoint").start("/tmp/delta-table")
```

別のターミナルを開き、Sparkシェルを開き、以下でデータを読み込む。

```scala
scala> val df = spark.read.format("delta").load("/tmp/delta-table")
```

裏でストリームデータを書き込んでいるので、適当に間をおいてcountを実行するとレコード数が増えていることが確かめられる。

```scala
scala> df.count
res1: Long = 1139

scala> df.count
res2: Long = 1158
```

```scala
scala> df.groupBy("id").count.sort($"count".desc).show
+----+-----+
|  id|count|
+----+-----+
| 964|    1|
|  29|    1|
|  26|    1|
| 474|    1|
| 831|    1|
|1042|    1|
| 167|    1|
| 112|    1|
| 299|    1|
| 155|    1|
| 385|    1|
| 736|    1|
| 113|    1|
|1055|    1|
| 502|    1|
|1480|    1|
| 656|    1|
| 287|    1|
|   0|    1|
| 348|    1|
+----+-----+
```

止めるには、ストリーム処理を実行しているターミナルで以下を実行。

```scala
scala> stream.stop() 
```

上記だと面白くないので、次に実行する処理内容を少しだけ修正。10で割った余りとするようにした。

```scala
scala> val stream = streamingDf.select($"value" % 10 as "id").writeStream.format("delta").option("checkpointLocation", "/tmp/checkpoint").start("/tmp/delta-table")
```

結果は以下の通り。先程書き込んだデータも含まれているので、
件数が1個のデータと、いま書き込んでいる10で割った余りのデータが混在しているように見えるはず。

```scala
scala> df.groupBy("id").count.sort($"count".desc).show
+----+-----+
|  id|count|
+----+-----+
|   0|   19|
|   9|   19|
|   1|   19|
|   2|   19|
|   3|   18|
|   6|   18|
|   5|   18|
|   8|   18|
|   7|   18|
|   4|   18|
|1055|    1|
|1547|    1|
|  26|    1|
|1224|    1|
| 502|    1|
|1480|    1|
| 237|    1|
| 588|    1|
| 602|    1|
| 347|    1|
+----+-----+
only showing top 20 rows
```

つづいてドキュメントに載っているストリームとしての読み取りを試す。

```scala
scala> val stream2 = spark.readStream.format("delta").load("/tmp/delta-table").writeStream.format("console").start()
```

以下のような表示がコンソールに出るはず。

```
-------------------------------------------
Batch: 7
-------------------------------------------
+---+
| id|
+---+
|  5|
|  6|
+---+
```

それぞれ止めておく。

```scala
scala> stream.stop()
```

```scala
scala> stream2.stop() 
```

さて、まず書き込み時の動作を確認する。

上記の例で言うと、ストリーム処理を定義し、スタートすると、

```scala
scala> val stream = streamingDf.select($"value" as "id").writeStream.format("delta").option("checkpointLocation", "/tmp/checkpoint").start("/tmp/delta-table")
```

以下の `org.apache.spark.sql.delta.sources.DeltaDataSource#createSink` メソッドが呼ばれる。

org/apache/spark/sql/delta/sources/DeltaDataSource.scala:99

```scala
  override def createSink(
      sqlContext: SQLContext,
      parameters: Map[String, String],
      partitionColumns: Seq[String],
      outputMode: OutputMode): Sink = {
    val path = parameters.getOrElse("path", {
      throw DeltaErrors.pathNotSpecifiedException
    })
    if (outputMode != OutputMode.Append && outputMode != OutputMode.Complete) {
      throw DeltaErrors.outputModeNotSupportedException(getClass.getName, outputMode)
    }
    val deltaOptions = new DeltaOptions(parameters, sqlContext.sparkSession.sessionState.conf)
    new DeltaSink(sqlContext, new Path(path), partitionColumns, outputMode, deltaOptions)
  }
```

上記の通り、実態は `org.apache.spark.sql.delta.sources.DeltaSink` クラスである。
当該クラスはSpark Structured Streamingの `org.apache.spark.sql.execution.streaming.Sink` トレートを継承（ミックスイン）している。

`org.apache.spark.sql.delta.sources.DeltaSink#addBatch` メソッドが、実際にシンクにバッチを追加する処理を規定している。

org/apache/spark/sql/delta/sources/DeltaSink.scala:50

```scala
  override def addBatch(batchId: Long, data: DataFrame): Unit = deltaLog.withNewTransaction { txn =>
    val queryId = sqlContext.sparkContext.getLocalProperty(StreamExecution.QUERY_ID_KEY)
    assert(queryId != null)

    if (SchemaUtils.typeExistsRecursively(data.schema)(_.isInstanceOf[NullType])) {
      throw DeltaErrors.streamWriteNullTypeException
    }

(snip)
```

上記のように、 `org.apache.spark.sql.delta.DeltaLog#withNewTransaction` メソッドを用いてトランザクションが開始される。
また引数には、バッチのユニークなIDと書き込み対象のDataFrameが含まれる。

このまま、軽く `org.apache.spark.sql.delta.sources.DeltaSink#addBatch` の内容を確認する。
以下、順に記載。

org/apache/spark/sql/delta/sources/DeltaSink.scala:63

```scala
    val selfScan = data.queryExecution.analyzed.collectFirst {
      case DeltaTable(index) if index.deltaLog.isSameLogAs(txn.deltaLog) => true
    }.nonEmpty
    if (selfScan) {
      txn.readWholeTable()
    }
```

この書き込み時に、同時に読み込みをしているかどうかを確認。
（トランザクション制御の関係で・・・）

org/apache/spark/sql/delta/sources/DeltaSink.scala:71

```scala
    updateMetadata(
      txn,
      data,
      partitionColumns,
      configuration = Map.empty,
      outputMode == OutputMode.Complete())
```

メタデータ更新。

org/apache/spark/sql/delta/sources/DeltaSink.scala:78

```scala
    val currentVersion = txn.txnVersion(queryId)
    if (currentVersion >= batchId) {
      logInfo(s"Skipping already complete epoch $batchId, in query $queryId")
      return
    }
```

バッチが重なっていないかどうかを確認。

org/apache/spark/sql/delta/sources/DeltaSink.scala:84

```scala
    val deletedFiles = outputMode match {
      case o if o == OutputMode.Complete() =>
        deltaLog.assertRemovable()
        txn.filterFiles().map(_.remove)
      case _ => Nil
    }
```

削除対象ファイルを確認。
なお、ここで記載している例においてはモードがAppendなので、値がNilになる。

org/apache/spark/sql/delta/sources/DeltaSink.scala:90

```scala
    val newFiles = txn.writeFiles(data, Some(options))
```

つづいて、ファイルを書き込み。
ちなみに、書き込まれたファイル情報が戻り値として得られる。
内容は以下のような感じ。

```
newFiles = {ArrayBuffer@20585} "ArrayBuffer" size = 7
 0 = {AddFile@20592} "AddFile(part-00000-80d99ff7-f0cd-48f7-80a1-30e7f60be763-c000.snappy.parquet,Map(),429,1582991406000,true,null,null)"
 1 = {AddFile@20593} "AddFile(part-00001-72553d89-8181-4550-b961-11463562768c-c000.snappy.parquet,Map(),429,1582991406000,true,null,null)"
 2 = {AddFile@20594} "AddFile(part-00002-3f95aa5d-03fd-40c7-ae36-c65f20d5c7e0-c000.snappy.parquet,Map(),429,1582991406000,true,null,null)"
 3 = {AddFile@20595} "AddFile(part-00003-ad9c1b95-868c-475f-a090-d73127bbff2b-c000.snappy.parquet,Map(),429,1582991406000,true,null,null)"
 4 = {AddFile@20596} "AddFile(part-00004-2d1b9266-6325-4f72-aa37-46b065d574a0-c000.snappy.parquet,Map(),429,1582991406000,true,null,null)"
 5 = {AddFile@20597} "AddFile(part-00005-aa35596d-3eb6-4046-977f-761d6f3e97f5-c000.snappy.parquet,Map(),429,1582991406000,true,null,null)"
 6 = {AddFile@20598} "AddFile(part-00006-5d370239-de8d-45fc-9836-6c154808291a-c000.snappy.parquet,Map(),429,1582991406000,true,null,null)"
```

実際に更新されたファイルを確認すると以下の通り。

```
$ ls -lt /tmp/delta-table/ | head
合計 8180
-rw-r--r-- 1 dobachi dobachi  429  3月  1 00:50 part-00000-80d99ff7-f0cd-48f7-80a1-30e7f60be763-c000.snappy.parquet
-rw-r--r-- 1 dobachi dobachi  429  3月  1 00:50 part-00003-ad9c1b95-868c-475f-a090-d73127bbff2b-c000.snappy.parquet
-rw-r--r-- 1 dobachi dobachi  429  3月  1 00:50 part-00006-5d370239-de8d-45fc-9836-6c154808291a-c000.snappy.parquet
-rw-r--r-- 1 dobachi dobachi  429  3月  1 00:50 part-00004-2d1b9266-6325-4f72-aa37-46b065d574a0-c000.snappy.parquet
-rw-r--r-- 1 dobachi dobachi  429  3月  1 00:50 part-00005-aa35596d-3eb6-4046-977f-761d6f3e97f5-c000.snappy.parquet
-rw-r--r-- 1 dobachi dobachi  429  3月  1 00:50 part-00001-72553d89-8181-4550-b961-11463562768c-c000.snappy.parquet
-rw-r--r-- 1 dobachi dobachi  429  3月  1 00:50 part-00002-3f95aa5d-03fd-40c7-ae36-c65f20d5c7e0-c000.snappy.parquet
```

では実装確認に戻る。

org/apache/spark/sql/delta/sources/DeltaSink.scala:91

```scala
    val setTxn = SetTransaction(queryId, batchId, Some(deltaLog.clock.getTimeMillis())) :: Nil
    val info = DeltaOperations.StreamingUpdate(outputMode, queryId, batchId)
    txn.commit(setTxn ++ newFiles ++ deletedFiles, info)
```

トランザクションをコミットすると、 `_delta_log` 以下のファイルも更新される。

次は、読み込みの動作を確認する。

読み込み時は、 `org.apache.spark.sql.delta.sources.DeltaSource#getBatch` メソッドが呼ばれ、
バッチが取得される。

org/apache/spark/sql/delta/sources/DeltaSource.scala:273

```scala
  override def getBatch(start: Option[Offset], end: Offset): DataFrame = {

  (snip)
```

ここでは `org.apache.spark.sql.delta.sources.DeltaSource#getBatch` メソッド内の処理を確認する。

org/apache/spark/sql/delta/sources/DeltaSource.scala:274

```scala
    val endOffset = DeltaSourceOffset(tableId, end)
    previousOffset = endOffset // For recovery
```

最初に、当該バッチの終わりの位置を示すオフセットを算出する。

org/apache/spark/sql/delta/sources/DeltaSource.scala:276

```scala
    val changes = if (start.isEmpty) {
      if (endOffset.isStartingVersion) {
        getChanges(endOffset.reservoirVersion, -1L, isStartingVersion = true)
      } else {
        assert(endOffset.reservoirVersion > 0, s"invalid reservoirVersion in endOffset: $endOffset")
        // Load from snapshot `endOffset.reservoirVersion - 1L` so that `index` in `endOffset`
        // is still valid.
        getChanges(endOffset.reservoirVersion - 1L, -1L, isStartingVersion = true)
      }
    } else {
      val startOffset = DeltaSourceOffset(tableId, start.get)
      if (!startOffset.isStartingVersion) {
        // unpersist `snapshot` because it won't be used any more.
        cleanUpSnapshotResources()
      }
      getChanges(startOffset.reservoirVersion, startOffset.index, startOffset.isStartingVersion)
    }
```

上記の通り、 `org.apache.spark.sql.delta.sources.DeltaSource#getChanges` メソッドを使って
`org.apache.spark.sql.delta.sources.IndexedFile` インスタンスのイテレータを受け取る。
特に初回のバッチでは変数 `start` が `None` であり、さらにスナップショットから開始するようになる。

なお、初回では無い場合は、以下が実行される。

org/apache/spark/sql/delta/sources/DeltaSource.scala:285

```scala
    } else {
      val startOffset = DeltaSourceOffset(tableId, start.get)
      if (!startOffset.isStartingVersion) {
        // unpersist `snapshot` because it won't be used any more.
        cleanUpSnapshotResources()
      }
      getChanges(startOffset.reservoirVersion, startOffset.index, startOffset.isStartingVersion)
    }
```

与えられたオフセット情報を元に `org.apache.spark.sql.delta.sources.DeltaSourceOffset` をインスタンス化し、それを用いてイテレータを生成する。

org/apache/spark/sql/delta/sources/DeltaSource.scala:294

```scala
    val addFilesIter = changes.takeWhile { case IndexedFile(version, index, _, _) =>
      version < endOffset.reservoirVersion ||
        (version == endOffset.reservoirVersion && index <= endOffset.index)
    }.collect { case i: IndexedFile if i.add != null => i.add }
    val addFiles =
      addFilesIter.filter(a => excludeRegex.forall(_.findFirstIn(a.path).isEmpty)).toSeq
```

上記で得られたイテレータをベースに、 `AddFile` インスタンスのシーケンスを得る。

```scala
    logDebug(s"start: $start end: $end ${addFiles.toList}")
    deltaLog.createDataFrame(deltaLog.snapshot, addFiles, isStreaming = true)
```

`org.apache.spark.sql.delta.DeltaLog#createDataFrame` メソッドを使って、今回のバッチ向けのDataFrameを得る。

#### （参考）DeltaSinkのaddBatchメソッドがどこから呼ばれるか。

Sparkの `org.apache.spark.sql.execution.streaming.MicroBatchExecution#runBatch` メソッド内で呼ばれる。

org/apache/spark/sql/execution/streaming/MicroBatchExecution.scala:534

```scala
    reportTimeTaken("addBatch") {
      SQLExecution.withNewExecutionId(sparkSessionToRunBatch, lastExecution) {
        sink match {
          case s: Sink => s.addBatch(currentBatchId, nextBatch)
          case _: StreamWriteSupport =>
            // This doesn't accumulate any data - it just forces execution of the microbatch writer.
            nextBatch.collect()
        }
      }
    }
```

なお、ここで渡されている `nextBatch` は、その直前で以下のように生成される。

org/apache/spark/sql/execution/streaming/MicroBatchExecution.scala:531

```scala
    val nextBatch =
      new Dataset(sparkSessionToRunBatch, lastExecution, RowEncoder(lastExecution.analyzed.schema))
```

なお、ほぼ自明であるが、上記例において `nextBatch` で渡されるバッチのクエリプランは以下のとおりである。

```
*(1) Project [value#684L AS id#4L]
+- *(1) Project [timestamp#683, value#684L]
   +- *(1) ScanV2 rate[timestamp#683, value#684L]
```

`org.apache.spark.sql.execution.streaming.MicroBatchExecution#runBatch` メソッド自体は、
`org.apache.spark.sql.execution.streaming.MicroBatchExecution#runActivatedStream` メソッド内で呼ばれる。
すなわち、 `org.apache.spark.sql.execution.streaming.StreamExecution` クラス内で管理される、ストリーム処理を実行する仕組みの中で、
繰り返し呼ばれることになる。

## スキーマバリデーション

[公式ドキュメントのスキーマバリデーション] には書き込みの際のスキーマ確認のアルゴリズムが載っている。

原則はカラムや型が一致することを求める。違っていたら例外が上がる。

また大文字小文字だけが異なるカラムを用ってはいけない。

### 試しに例外を出してみる

試しにスキーマの異なるレコードを追加しようと試みてみた。
ここでは、保存されているDelta Lakeテーブルには存在しない列を追加したデータを書き込もうとしてみる。

```scala
scala> // テーブルの準備
scala> val id = spark.range(0, 100000)
scala> val data = id.select($"id", rand() * 10 % 10 as "rand" cast "int")
scala> data.write.format("delta").save("/tmp/delta-table")
scala> // いったん別のDFとして読み込み定義
scala> val df = spark.read.format("delta").load("/tmp/delta-table")
scala> // 新しいカラム付きのレコードを定義し、書き込み
scala> val newRecords = id.select($"id", rand() * 10 % 10 as "rand" cast "int", rand() * 10 % 10 as "tmp" cast "int")
scala> newRecords.write.format("delta").mode("append").save("/tmp/delta-table")
```

以下のようなエラーが生じた。

```
scala> newRecords.write.format("delta").mode("append").save("/tmp/delta-table")
org.apache.spark.sql.AnalysisException: A schema mismatch detected when writing to the Delta table.
To enable schema migration, please set:
'.option("mergeSchema", "true")'.

Table schema:
root
-- id: long (nullable = true)
-- rand: integer (nullable = true)


Data schema:
root
-- id: long (nullable = true)
-- rand: integer (nullable = true)
-- tmp: integer (nullable = true)


If Table ACLs are enabled, these options will be ignored. Please use the ALTER TABLE
command for changing the schema.
        ;
  at org.apache.spark.sql.delta.MetadataMismatchErrorBuilder.finalizeAndThrow(DeltaErrors.scala:851)
  at org.apache.spark.sql.delta.schema.ImplicitMetadataOperation$class.updateMetadata(ImplicitMetadataOperation.scala:122)         at org.apache.spark.sql.delta.commands.WriteIntoDelta.updateMetadata(WriteIntoDelta.scala:45)
  at org.apache.spark.sql.delta.commands.WriteIntoDelta.write(WriteIntoDelta.scala:85)

(snip)
```

上記エラーは、 `org.apache.spark.sql.delta.MetadataMismatchErrorBuilder#addSchemaMismatch` メソッド内で
生成されたものである。

org/apache/spark/sql/delta/DeltaErrors.scala:810

```scala
  def addSchemaMismatch(original: StructType, data: StructType): Unit = {
    bits ++=
      s"""A schema mismatch detected when writing to the Delta table.
         |To enable schema migration, please set:
         |'.option("${DeltaOptions.MERGE_SCHEMA_OPTION}", "true")'.
         |
         |Table schema:
         |${DeltaErrors.formatSchema(original)}
         |
         |Data schema:
         |${DeltaErrors.formatSchema(data)}
         """.stripMargin :: Nil
    mentionedOption = true
  }
```

上記の通り、Before / Afterでスキーマを表示してくれるようになっている。
このメソッドは、 `org.apache.spark.sql.delta.schema.ImplicitMetadataOperation#updateMetadata` メソッド内で
呼ばれる。

org/apache/spark/sql/delta/schema/ImplicitMetadataOperation.scala:113

```scala
      if (isNewSchema) {
        errorBuilder.addSchemaMismatch(txn.metadata.schema, dataSchema)
      }
```

ここで `isNewSchema` は現在のスキーマと新たに渡されたデータの
スキーマが一致しているかどうかを示す変数。

org/apache/spark/sql/delta/schema/ImplicitMetadataOperation.scala:57

```scala
    val dataSchema = data.schema.asNullable
    val mergedSchema = if (isOverwriteMode && canOverwriteSchema) {
      dataSchema
    } else {
      SchemaUtils.mergeSchemas(txn.metadata.schema, dataSchema)
    }
    val normalizedPartitionCols =
      normalizePartitionColumns(data.sparkSession, partitionColumns, dataSchema)
    // Merged schema will contain additional columns at the end
    def isNewSchema: Boolean = txn.metadata.schema != mergedSchema
```

上記の通り、overwriteモードでスキーマのオーバライトが可能なときは、新しいデータのスキーマが有効。
そうでない場合は、 `org.apache.spark.sql.delta.schema.SchemaUtils$#mergeSchemas` メソッドを使って
改めてスキーマが確定する。

### 自動でのカラム追加（スキーマ変更）を試す

[公式ドキュメントのスキーママージ] に記載があるとおり試す。

上記の例外が出た例に対し、以下のexpressionは成功する。

```scala
scala> // テーブルの準備
scala> val id = spark.range(0, 100000)
scala> val data = id.select($"id", rand() * 10 % 10 as "rand" cast "int")
scala> data.write.format("delta").save("/tmp/delta-table")
scala> // いったん別のDFとして読み込み定義
scala> val df = spark.read.format("delta").load("/tmp/delta-table")
scala> // 新しいカラム付きのレコードを定義し、書き込み
scala> val newRecords = id.select($"id", rand() * 10 % 10 as "rand" cast "int", rand() * 10 % 10 as "tmp" cast "int")
scala> newRecords.write.format("delta").mode("append").option("mergeSchema", "true").save("/tmp/delta-table")
```

`org.apache.spark.sql.delta.schema.ImplicitMetadataOperation#updateMetadata` メソッドの内容を確認する。

org/apache/spark/sql/delta/schema/ImplicitMetadataOperation.scala:57

```scala
    val dataSchema = data.schema.asNullable
    val mergedSchema = if (isOverwriteMode && canOverwriteSchema) {
      dataSchema
    } else {
      SchemaUtils.mergeSchemas(txn.metadata.schema, dataSchema)
    }

```

上記expressionを実行した際、まず `dataSchema` には、以下のような値が含まれている。
つまり、新しく渡されたレコードのスキーマである。

```
dataSchema = {StructType@16480} "StructType" size = 3
 0 = {StructField@19860} "StructField(id,LongType,true)"
 1 = {StructField@19861} "StructField(rand,IntegerType,true)"
 2 = {StructField@19855} "StructField(tmp,IntegerType,true)"
```

一方、 `txn.metadata.schema` には以下のような値が含まれている。
つまり、書き込み先のテーブルのスキーマである。

```
result = {StructType@19866} "StructType" size = 2
 0 = {StructField@19871} "StructField(id,LongType,true)"
 1 = {StructField@19872} "StructField(rand,IntegerType,true)"
```

`org.apache.spark.sql.delta.schema.SchemaUtils$#mergeSchemas` メソッドによりマージされたスキーマ `mergedSchema` は、

```
result = {StructType@16487} "StructType" size = 3
 0 = {StructField@19853} "StructField(id,LongType,true)"
 1 = {StructField@19854} "StructField(rand,IntegerType,true)"
 2 = {StructField@19855} "StructField(tmp,IntegerType,true)"
```

となる。

したがって、 `isNewSchema` メソッドの戻り値は `true` となる。

```scala
    def isNewSchema: Boolean = txn.metadata.schema != mergedSchema
```

実際には

* overwriteモードかどうか
* 新しいパーティショニングが必要かどうか
* スキーマが変わるかどうか

に依存して処理が分かれるが、今回のケースでは以下のようにメタデータが更新される。

org/apache/spark/sql/delta/schema/ImplicitMetadataOperation.scala:103

```scala
    } else if (isNewSchema && canMergeSchema && !isNewPartitioning) {
      logInfo(s"New merged schema: ${mergedSchema.treeString}")
      recordDeltaEvent(txn.deltaLog, "delta.ddl.mergeSchema")
      if (rearrangeOnly) {
        throw DeltaErrors.unexpectedDataChangeException("Change the Delta table schema")
      }
      txn.updateMetadata(txn.metadata.copy(schemaString = mergedSchema.json))
```

### overwriteモード時のスキーマ上書き

[公式ドキュメントのスキーマ上書き] に記載の通り、overwriteモードのとき、デフォルトではスキーマを更新しない。
したがって以下のexpressionは例外を生じる。

```scala
scala> // テーブルの準備
scala> val id = spark.range(0, 100000)
scala> val data = id.select($"id", rand() * 10 % 10 as "rand" cast "int")
scala> data.write.format("delta").save("/tmp/delta-table")
scala> // いったん別のDFとして読み込み定義
scala> val df = spark.read.format("delta").load("/tmp/delta-table")
scala> // 新しいカラム付きのレコードを定義し、書き込み
scala> val newRecords = id.select($"id", rand() * 10 % 10 as "rand" cast "int", rand() * 10 % 10 as "tmp" cast "int")
scala> newRecords.write.format("delta").mode("overwrite").save("/tmp/delta-table")
```

`option("overwriteSchema", "true")` をつけると、overwriteモード時にスキーマの異なるデータで上書きするとき、例外を生じなくなる。

```scala
scala> // テーブルの準備
scala> val id = spark.range(0, 100000)
scala> val data = id.select($"id", rand() * 10 % 10 as "rand" cast "int")
scala> data.write.format("delta").save("/tmp/delta-table")
scala> // いったん別のDFとして読み込み定義
scala> val df = spark.read.format("delta").load("/tmp/delta-table")
scala> // 新しいカラム付きのレコードを定義し、書き込み
scala> val newRecords = id.select($"id", rand() * 10 % 10 as "rand" cast "int", rand() * 10 % 10 as "tmp" cast "int")
scala> newRecords.write.format("delta").mode("overwrite").option("overwriteSchema", "true").save("/tmp/delta-table")
```

つまり、

* overwriteモード
* スキーマ上書き可能
* 新しいスキーマ

という条件の下で、以下のようにメタデータが更新される。

org/apache/spark/sql/delta/schema/ImplicitMetadataOperation.scala:91

```scala
    } else if (isOverwriteMode && canOverwriteSchema && (isNewSchema || isNewPartitioning)) {
      // Can define new partitioning in overwrite mode
      val newMetadata = txn.metadata.copy(
        schemaString = dataSchema.json,
        partitionColumns = normalizedPartitionCols
      )
      recordDeltaEvent(txn.deltaLog, "delta.ddl.overwriteSchema")
      if (rearrangeOnly) {
        throw DeltaErrors.unexpectedDataChangeException("Overwrite the Delta table schema or " +
          "change the partition schema")
      }
      txn.updateMetadata(newMetadata)
```


## パーティション

[公式ドキュメントのパーティション説明] には、以下のような例が載っている。

```scala
scala> df.write.format("delta").partitionBy("date").save("/delta/events")
```

特にパーティションを指定せずに実行すると以下のようになる。

```scala
scala> val id = spark.range(0, 100000)
id: org.apache.spark.sql.Dataset[Long] = [id: bigint]

scala> val data = id.select($"id", rand() * 10 % 10 as "rand" cast "int")
data: org.apache.spark.sql.DataFrame = [id: bigint, rand: double]

scala> data.write.format("delta").save("/tmp/delta-table")
```

```shell
$ ls -1 /tmp/delta-table/
_delta_log
part-00000-6861eaa0-a0dc-4365-872b-b0c110fe1462-c000.snappy.parquet
part-00001-11725618-2e8e-4a6b-ad6c-5e32f668cb90-c000.snappy.parquet
part-00002-8d69aea0-a2f0-46c0-b5a3-dd892a182307-c000.snappy.parquet
part-00003-ff70d70b-0252-497e-93db-2cd715db8ab6-c000.snappy.parquet
part-00004-46e681ef-2521-4642-ae8c-63fc3c7c9817-c000.snappy.parquet
part-00005-10aec3fc-9538-408c-b520-894ccf529663-c000.snappy.parquet
part-00006-62bf3268-79f7-47ea-8400-b3f7566914cb-c000.snappy.parquet
part-00007-8683ce7e-9fe6-4b64-be97-bd158cda551f-c000.snappy.parquet
```

Parquetファイルが出力ディレクトリに直接置かれる。

つづいてパーティションカラムを指定して書き込み。

```scala
scala> data.write.format("delta").partitionBy("rand").save("/tmp/delta-table-partitioned")
```

```shell
$ ls -1 -R /tmp/delta-table-partitioned/
/tmp/delta-table-partitioned/:
_delta_log
'rand=0'
'rand=1'
'rand=2'
'rand=3'
'rand=4'
'rand=5'
'rand=6'
'rand=7'
'rand=8'
'rand=9'

/tmp/delta-table-partitioned/_delta_log:
00000000000000000000.json

'/tmp/delta-table-partitioned/rand=0':
part-00000-336b194c-8e44-4e37-ac8f-114fb0e813c7.c000.snappy.parquet
part-00001-d49f42cd-f0ca-4a5c-87a6-4f7647aecd52.c000.snappy.parquet
part-00002-2a5e96ed-c56b-4b6b-9471-6ca5830d512e.c000.snappy.parquet
part-00003-4e8d330d-9da7-40f5-91d2-cecf27347769.c000.snappy.parquet
part-00004-8f6b1d40-ea8c-4533-840d-ae688f729b50.c000.snappy.parquet
part-00005-f65d497c-2dc2-48b3-9252-e18dc077c5aa.c000.snappy.parquet
part-00006-eed688bb-104e-4940-a87a-e239294d4975.c000.snappy.parquet
part-00007-b6366ae1-fbbb-4789-910e-d896f62cee68.c000.snappy.parquet

(snip)
```

先程指定したカラムの値に基づき、パーティション化されていることがわかる。
なお、メタデータ（ `/tmp/delta-table-partitioned/_delta_log/00000000000000000000.json` 内でも以下のようにパーティションカラムが指定されたことが示されてる。

```json
{"commitInfo":{"timestamp":1583070456680,"operation":"WRITE","operationParameters":{"mode":"ErrorIfExists","partitionBy":"[\"rand\"]"},"isBlindAppend":true}}

(snip)
```



## Delta Table

[公式ドキュメント（クイックスタート）] にも記載あるが、データをテーブル形式で操作できる。
上記で掲載されている例は以下の通り。

```scala
import io.delta.tables._
import org.apache.spark.sql.functions._

val deltaTable = DeltaTable.forPath("/tmp/delta-table")

// Update every even value by adding 100 to it
deltaTable.update(
  condition = expr("id % 2 == 0"),
  set = Map("id" -> expr("id + 100")))

// Delete every even value
deltaTable.delete(condition = expr("id % 2 == 0"))

// Upsert (merge) new data
val newData = spark.range(0, 20).toDF

deltaTable.as("oldData")
  .merge(
    newData.as("newData"),
    "oldData.id = newData.id")
  .whenMatched
  .update(Map("id" -> col("newData.id")))
  .whenNotMatched
  .insert(Map("id" -> col("newData.id")))
  .execute()

deltaTable.toDF.show()
```

なお、 `io.delta.tables.DeltaTable` クラスの実態は、Dataset（DataFrame）とそれを操作するためのAPIの塊である。

例えば上記の 

`io.delta.tables.DeltaTable#forPath` メソッドは以下のように定義されている。

```scala
  def forPath(sparkSession: SparkSession, path: String): DeltaTable = {
    if (DeltaTableUtils.isDeltaTable(sparkSession, new Path(path))) {
      new DeltaTable(sparkSession.read.format("delta").load(path),
        DeltaLog.forTable(sparkSession, path))
    } else {
      throw DeltaErrors.notADeltaTableException(DeltaTableIdentifier(path = Some(path)))
    }
  }
```

### 条件でレコード削除

```scala
scala> // データ準備
scala> val id = spark.range(0, 100000)
scala> val data = id.select($"id", rand() * 10 % 10 as "rand" cast "int")
scala> data.write.format("delta").save("/tmp/delta-table")
scala> // テーブルとして読み込み定義
scala> import io.delta.tables._
scala> import org.apache.spark.sql.functions._
scala> val deltaTable = DeltaTable.forPath(spark, "/tmp/delta-table")
scala> // 条件に基づきレコードを削除
scala> deltaTable.delete("rand > 5")
scala> deltaTable.delete($"rand" > 6)
scala> deltaTable.toDF.show
+-----+----+
|   id|rand|
+-----+----+
|62500|   0|
|62501|   5|
|62503|   4|
|62504|   3|
|62505|   3|
|62506|   3|
|62507|   2|

(snip)
```

なお、 `io.delta.tables.DeltaTable#delete` メソッドの実態は、
`io.delta.tables.execution.DeltaTableOperations#executeDelete` メソッドである。

コメントで、

>    // current DELETE does not support subquery,
>    // and the reason why perform checking here is that
>    // we want to have more meaningful exception messages,
>    // instead of having some random msg generated by executePlan().

と記載されており、バージョン0.5.0の段階ではサブクエリを使った削除には対応していないようだ。

またドキュメントによると、

> delete removes the data from the latest version of the Delta table but does not remove it from the physical storage until the old versions are explicitly vacuumed. See vacuum for more details.

とあり、不要になったファイルはバキュームで削除されるとのこと。


### 更新

```scala
scala> // データ準備
scala> val id = spark.range(0, 100000)
scala> val data = id.select($"id", rand() * 10 % 10 as "rand" cast "int")
scala> data.write.format("delta").save("/tmp/delta-table")
scala> // テーブルとして読み込み定義
scala> import io.delta.tables._
scala> import org.apache.spark.sql.functions._
scala> val deltaTable = DeltaTable.forPath(spark, "/tmp/delta-table")
scala> // 条件に基づきレコードを更新
scala> deltaTable.updateExpr("rand = 0", Map("rand" -> "-1"))
```

元のデータが

```scala
scala> deltaTable.toDF.show
+---+----+
| id|rand|
+---+----+
|  0|   4|
|  1|   6|
|  2|   0|
|  3|   5|
|  4|   1|
|  5|   6|
|  6|   7|
|  7|   0|
|  8|   0|
|  9|   5|

(snip)
```

だとすると、

```scala
scala> deltaTable.toDF.show
+---+----+
| id|rand|
+---+----+
|  0|   4|
|  1|   6|
|  2|  -1|
|  3|   5|
|  4|   1|
|  5|   6|
|  6|   7|
|  7|  -1|
|  8|  -1|

(snip)
```

のようになる。

`io.delta.tables.DeltaTable#updateExpr` メソッドの実態は、
`io.delta.tables.execution.DeltaTableOperations#executeUpdate` メソッドである。

### upsert（マージ）

```scala
scala> // データ準備
scala> val id = spark.range(0, 100000)
scala> val data = id.select($"id", rand() * 10 % 10 as "rand" cast "int")
scala> data.write.format("delta").save("/tmp/delta-table")
scala> // テーブルとして読み込み定義
scala> import io.delta.tables._
scala> import org.apache.spark.sql.functions._
scala> val deltaTable = DeltaTable.forPath(spark, "/tmp/delta-table")
scala> // upsert用のデータ作成
scala> val id2 = spark.range(0, 200000)
scala> val data2 = id2.select($"id", rand() * 10 % 10 as "rand" cast "int")
scala> val dataForUpsert = data2.sample(false, 0.5)
scala> // データをマージ
scala> :paste
deltaTable
  .as("before")
  .merge(
    dataForUpsert.as("updates"),
    "before.id = updates.id")
  .whenMatched
  .updateExpr(
    Map("rand" -> "updates.rand"))
  .whenNotMatched
  .insertExpr(
    Map(
      "id" -> "updates.id",
      "rand" -> "updates.rand"))
  .execute()
```

まず元データには、99999より大きな値はない。

```scala
> deltaTable.toDF.filter($"id" > 99997).show
+-----+----+
|   id|rand|
+-----+----+
|99998|   4|
|99999|   0|
+-----+----+
```

元データの先頭は以下の通り。

```scala
scala> deltaTable.toDF.show
+---+----+
| id|rand|
+---+----+
|  0|   1|
|  1|   3|
|  2|   5|
|  3|   8|
|  4|   3|
|  5|   0|
|  6|   5|
|  7|   6|
|  8|   4|
|  9|   9|
| 10|   4|
| 11|   4|

(snip)
```

upsert用のデータは以下の通り。

```scala
scala> dataForUpsert.show
+---+----+
| id|rand|
+---+----+
|  0|   7|
|  2|   6|
|  5|   2|
|  8|   9|
| 10|   9|

(snip)
```

99999よりも大きな `id` も存在する。

```scala
scala> dataForUpsert.filter($"id" > 99997).show
+------+----+
|    id|rand|
+------+----+
| 99999|   0|
|100005|   3|
|100006|   9|
|100008|   7|
|100009|   1|

(snip)
```

upseart（マージ）を実行すると、

```scala
scala> deltaTable.toDF.orderBy($"id").show
+---+----+
| id|rand|
+---+----+
|  0|   7|
|  1|   3|
|  2|   6|
|  3|   8|
|  4|   3|
|  5|   2|
|  6|   5|
|  7|   6|
|  8|   9|

(snip)
```

上記のように、既存のレコードについては値が更新された。 [^orderingWithUpseart]

[^orderingWithUpseart]: マージ後は `id` 順に並んでいない。明示的なソートが必要のようだ。

また、

```scala
scala> deltaTable.toDF.filter($"id" > 99997).show
+------+----+
|    id|rand|
+------+----+
|100544|   5|
|100795|   1|
|101090|   5|
|101499|   1|
|101963|   7|

(snip)
```

のように、99997よりも大きな `id` のレコードも存在することがわかる。

#### io.delta.tables.DeltaTable#merge

上記の例に載っていた `io.delta.tables.DeltaTable#merge` を確認する。

io/delta/tables/DeltaTable.scala:501

```scala
  def merge(source: DataFrame, condition: Column): DeltaMergeBuilder = {
    DeltaMergeBuilder(this, source, condition)
  }
```

`io.delta.tables.DeltaMergeBuilder` はマージのロジックを構成するためのクラス。

* whenMatched
* whenNotMatched

メソッドが提供されており、それぞれマージの条件が合致した場合、合致しなかった場合に実行する処理を指定可能。
なお、それぞれメソッドの引数にString型の変数を渡すことができる。
その場合、マージの条件に **加えて** さらに条件を加えられる。

なお、 `whenNotMatched` に引数を与えた場合は、

* マージ条件に合致しなかった
* 引数で与えられた条件に合致した

が成り立つ場合に有効である。

`whenMatched` の場合は戻り値は `io.delta.tables.DeltaMergeMatchedActionBuilder` である。
`io.delta.tables.DeltaMergeMatchedActionBuilder` クラスには `update` メソッド、 `udpateExpr`、 `updateAll`、 `delete` メソッドがあり、
条件に合致したときに実行する処理を定義できる。

例えば、 `update` メソッドは以下の通り。

io/delta/tables/DeltaMergeBuilder.scala:298

```scala
  def update(set: Map[String, Column]): DeltaMergeBuilder = {
    addUpdateClause(set)
  }
```

io/delta/tables/DeltaMergeBuilder.scala:365

```scala
  private def addUpdateClause(set: Map[String, Column]): DeltaMergeBuilder = {
    if (set.isEmpty && matchCondition.isEmpty) {
      // Nothing to update = no need to add an update clause
      mergeBuilder
    } else {
      val setActions = set.toSeq
      val updateActions = MergeIntoClause.toActions(
        colNames = setActions.map(x => UnresolvedAttribute.quotedString(x._1)),
        exprs = setActions.map(x => x._2.expr),
        isEmptySeqEqualToStar = false)
      val updateClause = MergeIntoUpdateClause(matchCondition.map(_.expr), updateActions)
      mergeBuilder.withClause(updateClause)
    }
  }
```

戻り値は上記の通り、 `io.delta.tables.DeltaMergeBuilder` になる。
当該クラスは、メンバに `whenClauses` を持ち、指定された更新用の式（のセット）を保持する。

io/delta/tables/DeltaMergeBuilder.scala:244

```scala
  private[delta] def withClause(clause: MergeIntoClause): DeltaMergeBuilder = {
    new DeltaMergeBuilder(
      this.targetTable, this.source, this.onCondition, this.whenClauses :+ clause)
  }
```

なお、最後に `execute` メソッドを確認する。

io/delta/tables/DeltaMergeBuilder.scala:225

```scala
  def execute(): Unit = {
    val sparkSession = targetTable.toDF.sparkSession
    val resolvedMergeInto =
      MergeInto.resolveReferences(mergePlan)(tryResolveReferences(sparkSession) _)
    if (!resolvedMergeInto.resolved) {
      throw DeltaErrors.analysisException("Failed to resolve\n", plan = Some(resolvedMergeInto))
    }
    // Preprocess the actions and verify
    val mergeIntoCommand = PreprocessTableMerge(sparkSession.sessionState.conf)(resolvedMergeInto)
    sparkSession.sessionState.analyzer.checkAnalysis(mergeIntoCommand)
    mergeIntoCommand.run(sparkSession)
  }
```

最初に、DataFrameの変換前後の実行プラン、マージの際の条件等から
マージの実行プランを作成する。 ★要確認

#### 参考）値がユニークではないカラムを使ってのマージ

値がユニークではないカラムを使ってマージしようとすると、以下のようなエラーを生じる。

```
java.lang.UnsupportedOperationException: Cannot perform MERGE as multiple source rows matched and attempted to update the same
target row in the Delta table. By SQL semantics of merge, when multiple source rows match
on the same target row, the update operation is ambiguous as it is unclear which source
should be used to update the matching target row.
You can preprocess the source table to eliminate the possibility of multiple matches.
Please refer to
https://docs.delta.io/latest/delta/delta-update.html#upsert-into-a-table-using-merge

  at org.apache.spark.sql.delta.DeltaErrors$.multipleSourceRowMatchingTargetRowInMergeException(DeltaErrors.scala:444)
  at org.apache.spark.sql.delta.commands.MergeIntoCommand.org$apache$spark$sql$delta$commands$MergeIntoCommand$$findTouchedFiles(MergeIntoCommand.scala:225)
  at org.apache.spark.sql.delta.commands.MergeIntoCommand$$anonfun$run$1$$anonfun$apply$1$$anonfun$1.apply(MergeIntoCommand.scala:132)

(snip)
  
```

つまり、上記の例では `dataForUpsert` の中に、万が一重複する `id` をもつレコードが含まれていると、例外を生じることになる。
これは、重複する `id` について、どの値を採用したらよいか断定できなくなるため。

実装上は、 `org.apache.spark.sql.delta.commands.MergeIntoCommand#findTouchedFiles` メソッド内で重複の確認が行われる。
以下の通り。

org/apache/spark/sql/delta/commands/MergeIntoCommand.scala:223

```scala
    val matchedRowCounts = collectTouchedFiles.groupBy(ROW_ID_COL).agg(sum("one").as("count"))
    if (matchedRowCounts.filter("count > 1").count() != 0) {
      throw DeltaErrors.multipleSourceRowMatchingTargetRowInMergeException(spark)
    }
```

対象のカラムでgroupByして件数を数えていることがわかる。
最も容易に再現する方法は、 `val dataForUpsert = data2.sample(false, 0.5)` の第1引数をtrueにすれば、おそらく再現する。

### マージの例

[公式ドキュメントのマージの例] に有用な例が載っている。

* [公式ドキュメントのマージを使った上書き]
  * ログなどを収集する際、データソース側で重複させることがある。Delta Lakeのテーブルにマージしながら入力することで、
    レコード重複を排除しながらテーブルの内容を更新できる
  * さらに、新しいデータをマージする際、マージすべきデータの範囲がわかっていれば（例：最近7日間のログなど）、
    それを使ってスキャン・書き換えの範囲を絞りこめる。
* [Slowly changing data (SCD) Type 2 operation]
  * Dimensionalなデータを断続的にゆっくりと更新するワークロード
  * 新しい値で更新するときに、古い値を残しておく
* [Write change data into a Delta table]
  * 外部テーブルの変更をDelta Lakeに取り込む
  * DataFrame内にキー、タイムスタンプ、新しい値、削除フラグを持つ「変更内容」を表すレコードを保持。
  * 上記DataFrameには、あるキーに関する変更を複数含む可能性があるため、キーごとに一度アグリゲートし、
    グループごとに最も新しい変更内容を採用する。
  * DeltaTableのmerge機能を利用してupsert（や削除）する。
* [Upsert from streaming queries using foreachBatch]
  * [org.apache.spark.sql.streaming.DataStreamWriter#foreachBatch] を用いて、ストリームの各マイクロバッチに対する、
    Delta Lakeのマージ処理を行う。
  * CDCの方法と組み合わせ、重複排除（ユニークID利用、マイクロバッチのIDが使える？）との組み合わせも可能

## タイムトラベル

Deltaの持つヒストリは、上記の `DeltaTable` を利用して見られる。（その他にも、メタデータを直接確認する、という手もあるはある）

```scala
scala> val deltaTable = DeltaTable.forPath("/tmp/delta-table")
scala> deltaTable.history.show
+-------+-------------------+------+--------+---------+--------------------+----+--------+---------+-----------+--------------+-------------+
|version|          timestamp|userId|userName|operation| operationParameters| job|notebook|clusterId|readVersion|isolationLevel|isBlindAppend|
+-------+-------------------+------+--------+---------+--------------------+----+--------+---------+-----------+--------------+-------------+
|     13|2020-02-26 23:19:17|  null|    null|    MERGE|[predicate -> (ol...|null|    null|     null|         12|          null|        false|
|     12|2020-02-26 23:16:13|  null|    null|   DELETE|[predicate -> ["(...|null|    null|     null|         11|          null|        false|
|     11|2020-02-26 23:16:00|  null|    null|   UPDATE|[predicate -> ((i...|null|    null|     null|         10|          null|        false|
|     10|2020-02-26 23:12:48|  null|    null|    WRITE|[mode -> Append, ...|null|    null|     null|          9|          null|         true|
|      9|2020-02-26 23:12:33|  null|    null|    WRITE|[mode -> Overwrit...|null|    null|     null|          8|          null|        false|
|      8|2020-02-26 23:11:48|  null|    null|    WRITE|[mode -> Append, ...|null|    null|     null|          7|          null|         true|

(snip)
```

このうち、readVersionを指定し、ロードすることもできる。

```scala
scala> spark.read.format("delta").option("versionAsOf", 8).load("/tmp/delta-table").show
```

ここで指定した `versionAsOf` の値は、 `org.apache.spark.sql.delta.sources.DeltaDataSource` 内で用いられる。
`org.apache.spark.sql.delta.sources.DeltaDataSource#createRelation` メソッド内に以下のような実装があり、
ここでタイムトラベルの値が読み込まれる。

org/apache/spark/sql/delta/sources/DeltaDataSource.scala:153

```scala
    val timeTravelByParams = getTimeTravelVersion(parameters)
```

その他にもタイムスタンプで指定する方法もある。

[公式ドキュメント] の例：

```scala
df1 = spark.read.format("delta").option("timestampAsOf", timestamp_string).load("/delta/events")
```

なお、 [公式ドキュメント] には以下のような記載が見られた。

> This sample code writes out the data in df, validates that it all falls within the specified partitions, and performs an atomic replacement.

これは、データ本体を書き出してから、メタデータを新規作成することでアトミックに更新することを示していると想像される。
`org.apache.spark.sql.delta.OptimisticTransactionImpl#commit` メソッドあたりを確認したら良さそう。

## org.apache.spark.sql.delta.OptimisticTransactionImpl#commit

`org.apache.spark.sql.delta.OptimisticTransactionImpl#commit` メソッドは、
例えば `org.apache.spark.sql.delta.commands.WriteIntoDelta#run` メソッド内で呼ばれる。

org/apache/spark/sql/delta/commands/WriteIntoDelta.scala:63

```scala
  override def run(sparkSession: SparkSession): Seq[Row] = {
    deltaLog.withNewTransaction { txn =>
      val actions = write(txn, sparkSession)
      val operation = DeltaOperations.Write(mode, Option(partitionColumns), options.replaceWhere)
      txn.commit(actions, operation)
    }
    Seq.empty
  }
```

Delta Logを書き出した後に、メタデータを更新し書き出したDelta Logを有効化する。
書き込み衝突検知なども行われる。

org/apache/spark/sql/delta/OptimisticTransaction.scala:250

```scala
  def commit(actions: Seq[Action], op: DeltaOperations.Operation): Long = recordDeltaOperation(
      deltaLog,
      "delta.commit") {
    val version = try {

(snip)
```

commitメソッドは上記の通り、 `Action` と `Operation` を引数に取る。

* Action: Delta Tableに対する変更内容を表す。Actionのシーケンスがテーブル更新の内容を表す。
* Operation: Delta Tableに対する操作を表す。必ずしもテーブル内容の更新を示すわけではない。


なお、Operationの子クラスは以下の通り。

* ManualUpdate$ in DeltaOperations$ (org.apache.spark.sql.delta)
* UnsetTableProperties in DeltaOperations$ (org.apache.spark.sql.delta)
* Write in DeltaOperations$ (org.apache.spark.sql.delta)
* Convert in DeltaOperations$ (org.apache.spark.sql.delta)
* UpgradeProtocol in DeltaOperations$ (org.apache.spark.sql.delta)
* ComputeStats in DeltaOperations$ (org.apache.spark.sql.delta)
* SetTableProperties in DeltaOperations$ (org.apache.spark.sql.delta)
* FileNotificationRetention$ in DeltaOperations$ (org.apache.spark.sql.delta)
* Update in DeltaOperations$ (org.apache.spark.sql.delta)
* ReplaceTable in DeltaOperations$ (org.apache.spark.sql.delta)
* Truncate in DeltaOperations$ (org.apache.spark.sql.delta)
* Fsck in DeltaOperations$ (org.apache.spark.sql.delta)
* CreateTable in DeltaOperations$ (org.apache.spark.sql.delta)
* Merge in DeltaOperations$ (org.apache.spark.sql.delta)
* Optimize in DeltaOperations$ (org.apache.spark.sql.delta)
* ReplaceColumns in DeltaOperations$ (org.apache.spark.sql.delta)
* UpdateColumnMetadata in DeltaOperations$ (org.apache.spark.sql.delta)
* StreamingUpdate in DeltaOperations$ (org.apache.spark.sql.delta)
* Delete in DeltaOperations$ (org.apache.spark.sql.delta)
* ChangeColumn in DeltaOperations$ (org.apache.spark.sql.delta)
* ResetZCubeInfo in DeltaOperations$ (org.apache.spark.sql.delta)
* UpdateSchema in DeltaOperations$ (org.apache.spark.sql.delta)
* AddColumns in DeltaOperations$ (org.apache.spark.sql.delta)

では `commit` メソッドの内容確認に戻る。

org/apache/spark/sql/delta/OptimisticTransaction.scala:253

```scala
    val version = try {
      // Try to commit at the next version.
      var finalActions = prepareCommit(actions, op)
```

最初に、 `org.apache.spark.sql.delta.OptimisticTransactionImpl#prepareCommit` メソッドを利用し準備する。
例えば、

* メタデータ更新が一度に複数予定されていないか
* 最初の書き込みか？必要に応じて出力先ディレクトリを作り、初期のプロトコルバージョンを決める、など。
* 不要なファイルの削除

ここで「プロトコルバージョン」と言っているのは、クライアントが書き込みする際に使用するプロトコルのバージョンである。
つまり、テーブルに後方互換性を崩すような変更があった際、最小プロトコルバージョンを規定することで、
古すぎるクライアントのアクセスを許さないような仕組みが、Delta Lakeには備わっている。

では `commit` メソッドの内容確認に戻る。

org/apache/spark/sql/delta/OptimisticTransaction.scala:257

```scala
      // Find the isolation level to use for this commit
      val noDataChanged = actions.collect { case f: FileAction => f.dataChange }.forall(_ == false)
      val isolationLevelToUse = if (noDataChanged) {
        // If no data has changed (i.e. its is only being rearranged), then SnapshotIsolation
        // provides Serializable guarantee. Hence, allow reduced conflict detection by using
        // SnapshotIsolation of what the table isolation level is.
        SnapshotIsolation
      } else {
        Serializable
      }
```

書き込みファイル衝突時のアイソレーションレベルの確認。
なお、上記では実際には

* データ変更なし： `SnapshotIsolation`
* データ変更あり： `Serializable`

とされている。詳しくは [#アイソレーションレベル](#アイソレーションレベル) を参照。


(WIP)

## プロトコルバージョン

あとで書く。

## アイソレーションレベル

Delta Lakeは楽観ロックの仕組みであるが、3種類のアイソレーションレベルが用いられることになっている。（使い分けられることになっている）
DeltaTableのコンストラクタに、 `delta` ソースとして読み込んだDataFrameが渡されていることがわかる。
* org.apache.spark.sql.delta.Serializable
* org.apache.spark.sql.delta.WriteSerializable
* org.apache.spark.sql.delta.SnapshotIsolation

`org.apache.spark.sql.delta.OptimisticTransactionImpl#commit` メソッド内では
以下のようにデータ変更があるかどうかでアイソレーションレベルを使い分けるようになっている。

src/main/scala/org/apache/spark/sql/delta/OptimisticTransaction.scala:259

```scala
      val isolationLevelToUse = if (noDataChanged) {
        // If no data has changed (i.e. its is only being rearranged), then SnapshotIsolation
        // provides Serializable guarantee. Hence, allow reduced conflict detection by using
        // SnapshotIsolation of what the table isolation level is.
        SnapshotIsolation
      } else {
        Serializable
      }
```

また、実際に上記アイソレーションレベルの設定が用いられるのは、
`org.apache.spark.sql.delta.OptimisticTransactionImpl#doCommit` メソッドである。

src/main/scala/org/apache/spark/sql/delta/OptimisticTransaction.scala:293

```scala
      val commitVersion = doCommit(snapshot.version + 1, finalActions, 0, isolationLevelToUse)
```

`org.apache.spark.sql.delta.OptimisticTransactionImpl#doCommit` メソッドでは、
tryを用いてデルタログのストアファイルに書き込む。

```scala
  private def doCommit(
      attemptVersion: Long,
      actions: Seq[Action],
      attemptNumber: Int,
      isolationLevel: IsolationLevel): Long = deltaLog.lockInterruptibly {
    try {
      logDebug(
        s"Attempting to commit version $attemptVersion with ${actions.size} actions with " +
          s"$isolationLevel isolation level")

      deltaLog.store.write(
        deltaFile(deltaLog.logPath, attemptVersion),
        actions.map(_.json).toIterator)
```

ここで `java.nio.file.FileAlreadyExistsException` が発生すると、先程のアイソレーションレベルに
基づいた処理が行われることになる。
これは、楽観ロックであるため、いざ書き込もうとしたら「あ、デルタログのストアファイルが、誰かに書き込まれている…」ということが
ありえるからある。

```scala
    } catch {
      case e: java.nio.file.FileAlreadyExistsException =>
        checkAndRetry(attemptVersion, actions, attemptNumber, isolationLevel)
    }
```

上記の `org.apache.spark.sql.delta.OptimisticTransactionImpl#checkAndRetry` メソッドの内容を確認する。

org/apache/spark/sql/delta/OptimisticTransaction.scala:442

```scala
  protected def checkAndRetry(
      checkVersion: Long,
      actions: Seq[Action],
      attemptNumber: Int,
      commitIsolationLevel: IsolationLevel): Long = recordDeltaOperation(
        deltaLog,
        "delta.commit.retry",
        tags = Map(TAG_LOG_STORE_CLASS -> deltaLog.store.getClass.getName)) {

    import _spark.implicits._

    val nextAttemptVersion = getNextAttemptVersion(checkVersion)
```


最初に現在の最新のDeltaログのバージョン確認。
これをもとに、チェックするべきバージョン、つまりトランザクションを始めてから、
更新された内容をトラックする。

以下の通り。

org/apache/spark/sql/delta/OptimisticTransaction.scala:453

```scala
    (checkVersion until nextAttemptVersion).foreach { version =>
      // Actions of a commit which went in before ours
      val winningCommitActions =
        deltaLog.store.read(deltaFile(deltaLog.logPath, version)).map(Action.fromJson)

(snip)
```

上記で、トランザクション開始後のアクションを確認できる。

org/apache/spark/sql/delta/OptimisticTransaction.scala:460

```scala
      val metadataUpdates = winningCommitActions.collect { case a: Metadata => a }
      val removedFiles = winningCommitActions.collect { case a: RemoveFile => a }
      val txns = winningCommitActions.collect { case a: SetTransaction => a }
      val protocol = winningCommitActions.collect { case a: Protocol => a }
      val commitInfo = winningCommitActions.collectFirst { case a: CommitInfo => a }.map(
        ci => ci.copy(version = Some(version)))
```

この後の処理のため、アクションから各種情報を取り出す。

org/apache/spark/sql/delta/OptimisticTransaction.scala:467

```scala
      val blindAppendAddedFiles = mutable.ArrayBuffer[AddFile]()
      val changedDataAddedFiles = mutable.ArrayBuffer[AddFile]()

      val isBlindAppendOption = commitInfo.flatMap(_.isBlindAppend)
      if (isBlindAppendOption.getOrElse(false)) {
        blindAppendAddedFiles ++= winningCommitActions.collect { case a: AddFile => a }
      } else {
        changedDataAddedFiles ++= winningCommitActions.collect { case a: AddFile => a }
      }
```

まず、変更のあったファイルを確認する。
このとき、既存ファイルに関係なく書き込まれた（blind append）ファイルか、
そうでないかを仕分けながら確認する。
一応、後々アイソレーションレベルに基づいてファイルを処理する際に、
ここで得られた情報が用いられる。 [^BlindAppendAt0.5.0]

[^BlindAppendAt0.5.0]: ただし、バージョン0.5.0では、実際のところ使われているアイソレーションレベルが限られているので、ここでの仕分けはあまり意味がないかもしれない。

org/apache/spark/sql/delta/OptimisticTransaction.scala:479

```scala
      if (protocol.nonEmpty) {
        protocol.foreach { p =>
          deltaLog.protocolRead(p)
          deltaLog.protocolWrite(p)
        }
        actions.foreach {
          case Protocol(_, _) => throw new ProtocolChangedException(commitInfo)
          case _ =>
        }
      }
```

プロトコル変更がないかどうかを確認する。

org/apache/spark/sql/delta/OptimisticTransaction.scala:491

```scala
      if (metadataUpdates.nonEmpty) {
        throw new MetadataChangedException(commitInfo)
      }
```

メタデータに変更があったら例外。
つまり、トランザクション開始後、例えばスキーマ変更があったら例外になる、ということ。
スキーマ上書きを有効化した上でカラム追加を伴うような書き込みを行った際にメタデータが変わるため、
他のトランザクションからそのような書き込みがあった場合は、例外になることになる。

src/main/scala/org/apache/spark/sql/delta/OptimisticTransaction.scala:496

```scala
      val addedFilesToCheckForConflicts = commitIsolationLevel match {
        case Serializable => changedDataAddedFiles ++ blindAppendAddedFiles
        case WriteSerializable => changedDataAddedFiles // don't conflict with blind appends
        case SnapshotIsolation => Seq.empty
      }
```

アイソレーションレベルに基づいて、競合確認する対象ファイルを決める。

なお、前述の通り、実際にはデータの変更のありなしでアイソレーションレベルが変わるようになっている。
具体的には、

* データ変更あり：Serializable
* データ変更なし：SnapshotIsolation

となっており、いまの実装ではWriteSerializableは用いられないようにみえる。
`org.apache.spark.sql.delta.IsolationLevel` にもそのような旨の記載がある。

org/apache/spark/sql/delta/isolationLevels.scala:83

```scala
  /** All the valid isolation levels that can be specified as the table isolation level */
  val validTableIsolationLevels = Set[IsolationLevel](Serializable, WriteSerializable)
```

では、データの変更あり・なしは、どうやって設定されるのかというと、
`dataChange` というオプションで指定することになる。

データ変更なしの書き込みはいつ使われるのか、というと、
例えば「たくさん作られたDelta Lakeのファイルをまとめる（Compactする）とき」である。

説明が [公式ドキュメントのCompact filesの説明] にある。
ドキュメントの例では以下のようにオプションが指定されている。

```scala
 val path = "..."
 val numFiles = 16

 spark.read
   .format("delta")
   .load(path)
   .repartition(numFiles)
   .write
   .option("dataChange", "false")
   .format("delta")
   .mode("overwrite")
   .save(path)
```

例外処理の内容確認に戻る。

org/apache/spark/sql/delta/OptimisticTransaction.scala:496

```scala
      val addedFilesToCheckForConflicts = commitIsolationLevel match {
        case Serializable => changedDataAddedFiles ++ blindAppendAddedFiles
        case WriteSerializable => changedDataAddedFiles // don't conflict with blind appends
        case SnapshotIsolation => Seq.empty
      }
```

Delta Lakeバージョン0.5.0では、今回のトランザクションで書き込みがある場合は既存ファイルに影響ない書き込みを含め、すべて確認対象とする。
そうでない場合は確認対象は空である。

org/apache/spark/sql/delta/OptimisticTransaction.scala:501

```scala
      val predicatesMatchingAddedFiles = ExpressionSet(readPredicates).iterator.flatMap { p =>
        val conflictingFile = DeltaLog.filterFileList(
          metadata.partitionColumns,
          addedFilesToCheckForConflicts.toDF(), p :: Nil).as[AddFile].take(1)

        conflictingFile.headOption.map(f => getPrettyPartitionMessage(f.partitionValues))
      }.take(1).toArray
```

トランザクション中に、別のトランザクションによりファイルが追加された場合、関係するパーティション情報を取得。

org/apache/spark/sql/delta/OptimisticTransaction.scala:509

```scala
      if (predicatesMatchingAddedFiles.nonEmpty) {
        val isWriteSerializable = commitIsolationLevel == WriteSerializable
        val onlyAddFiles =
          winningCommitActions.collect { case f: FileAction => f }.forall(_.isInstanceOf[AddFile])

        val retryMsg =
          if (isWriteSerializable && onlyAddFiles && isBlindAppendOption.isEmpty) {
            // This transaction was made by an older version which did not set `isBlindAppend` flag.
            // So even if it looks like an append, we don't know for sure if it was a blind append
            // or not. So we suggest them to upgrade all there workloads to latest version.
            Some(
              "Upgrading all your concurrent writers to use the latest Delta Lake may " +
                "avoid this error. Please upgrade and then retry this operation again.")
          } else None
        throw new ConcurrentAppendException(commitInfo, predicatesMatchingAddedFiles.head, retryMsg)
      }
```

当該パーティション情報がから出ない場合は、例外 `org.apache.spark.sql.delta.ConcurrentAppendException#ConcurrentAppendException` が生じる。

つづいて、上記でないケースのうち、削除が行われたケース。

org/apache/spark/sql/delta/OptimisticTransaction.scala:527

```scala
      val readFilePaths = readFiles.map(f => f.path -> f.partitionValues).toMap
      val deleteReadOverlap = removedFiles.find(r => readFilePaths.contains(r.path))
      if (deleteReadOverlap.nonEmpty) {
        val filePath = deleteReadOverlap.get.path
        val partition = getPrettyPartitionMessage(readFilePaths(filePath))
        throw new ConcurrentDeleteReadException(commitInfo, s"$filePath in $partition")
      }
```

読もうとしたファイルが他のトランザクションにより削除された倍は、
例外 `org.apache.spark.sql.delta.ConcurrentDeleteReadException#ConcurrentDeleteReadException` を生じる。

もしくは、同じファイルを複数回消そうとしている場合、

org/apache/spark/sql/delta/OptimisticTransaction.scala:536

```scala
      val txnDeletes = actions.collect { case r: RemoveFile => r }.map(_.path).toSet
      val deleteOverlap = removedFiles.map(_.path).toSet intersect txnDeletes
      if (deleteOverlap.nonEmpty) {
        throw new ConcurrentDeleteDeleteException(commitInfo, deleteOverlap.head)
      }
```

例外 `org.apache.spark.sql.delta.ConcurrentDeleteDeleteException#ConcurrentDeleteDeleteException` が生じる。

その他、何らかトランザクション上重複した場合…

```scala
      val txnOverlap = txns.map(_.appId).toSet intersect readTxn.toSet
      if (txnOverlap.nonEmpty) {
        throw new ConcurrentTransactionException(commitInfo)
      }
```

例外 `org.apache.spark.sql.delta.ConcurrentTransactionException#ConcurrentTransactionException` が生じる。

以上に引っかからなかった場合は、例外を生じない。
トランザクション開始後、すべてのバージョンについて競合チェックが行われた後、
問題ない場合は、

org/apache/spark/sql/delta/OptimisticTransaction.scala:549

```scala
    logInfo(s"No logical conflicts with deltas [$checkVersion, $nextAttemptVersion), retrying.")
    doCommit(nextAttemptVersion, actions, attemptNumber + 1, commitIsolationLevel)
```

`org.apache.spark.sql.delta.OptimisticTransactionImpl#doCommit` メソッドが再実行される。
つまり、リトライである。

こうなるケースは何かというと、コンパクションを行った際、他のトランザクションで削除などが行われなかったケースなどだと想像。

### sbtでテストコードを使って確認

上記実装の内容を確認するため、SBTのコンフィグを以下のように修正し、デバッガをアタッチして確認する。

```diff
diff --git a/build.sbt b/build.sbt
index af4ab71..444fe55 100644
--- a/build.sbt
+++ b/build.sbt
@@ -63,6 +63,7 @@ scalacOptions ++= Seq(
 )

 javaOptions += "-Xmx1024m"
+javaOptions += "-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005"

 fork in Test := true
```

sbtを実行

```shell
$ ./build/sbt
```

sbtで以下のテストを実行する。

```sbt
> testOnly org.apache.spark.sql.delta.OptimisticTransactionSuite -- -z "block concurrent commit on full table scan"
```

テストの内容は以下の通り。
tx1でスキャンしようとしたとき、別のtx2で先に削除が行われたケース。

```scala
  test("block concurrent commit on full table scan") {
    withLog(addA_P1 :: addD_P2 :: Nil) { log =>
      val tx1 = log.startTransaction()
      // TX1 full table scan
      tx1.filterFiles()
      tx1.filterFiles(('part === 1).expr :: Nil)

      val tx2 = log.startTransaction()
      tx2.filterFiles()
      tx2.commit(addC_P2 :: addD_P2.remove :: Nil, ManualUpdate)

      intercept[ConcurrentAppendException] {
        tx1.commit(addE_P3 :: addF_P3 :: Nil, ManualUpdate)
      }
    }
  }
```

したがって、ここでは `removedFiles` に値が含まれることになる。

```
removedFiles = {ArrayBuffer@12893} "ArrayBuffer" size = 1
 0 = {RemoveFile@15705} "RemoveFile(part=2/d,Some(1583466515581),true)"
```

またtx2のアクションは正確には追加と削除であるから、 `winningCommitActions` の内容は以下の通りとなる。

```
winningCommitActions = {ArrayBuffer@12887} "ArrayBuffer" size = 3
 0 = {CommitInfo@16006} "CommitInfo(None,2020-03-05 19:48:35.582,None,None,Manual Update,Map(),None,None,None,Some(0),None,Some(false))"
 1 = {AddFile@15816} "AddFile(part=2/c,Map(part -> 2),1,1,true,null,null)"
 2 = {RemoveFile@15705} "RemoveFile(part=2/d,Some(1583466515581),true)"
```

なお、今回は既存ファイルへの変更になるため、Blind Appendではない。
結果として、 `changedDataAddedFiles` には以下のような値が含まれることになる。

```
changedDataAddedFiles = {ArrayBuffer@15736} "ArrayBuffer" size = 1
 0 = {AddFile@15816} "AddFile(part=2/c,Map(part -> 2),1,1,true,null,null)"
```

`addedFilesToCheckForConflicts` も同様。

`addedFilesToCheckForConflicts` には以下の通り、 `AddFile` インスンタスが含まれる。
つまりtx2で追加しているファイルの情報が含まれる。

```
addedFilesToCheckForConflicts = {ArrayBuffer@15866} "ArrayBuffer" size = 1
 0 = {AddFile@15816} "AddFile(part=2/c,Map(part -> 2),1,1,true,null,null)"
```

`predicatesMatchingAddedFiles` は以下の通り、ファイル追加に関係するパーティション情報が含まれる。

```
predicatesMatchingAddedFiles = {String[1]@15911} 
 0 = "partition [part=2]"
```

このことから、

org/apache/spark/sql/delta/OptimisticTransaction.scala:509

```scala
      if (predicatesMatchingAddedFiles.nonEmpty) {
```

がfalseになり、例外 `org.apache.spark.sql.delta.ConcurrentAppendException#ConcurrentAppendException` が生じることになる。
つまり、以下の箇所。

org/apache/spark/sql/delta/OptimisticTransaction.scala:509

```scala
      if (predicatesMatchingAddedFiles.nonEmpty) {
        val isWriteSerializable = commitIsolationLevel == WriteSerializable
        val onlyAddFiles =
          winningCommitActions.collect { case f: FileAction => f }.forall(_.isInstanceOf[AddFile])

        val retryMsg =
          if (isWriteSerializable && onlyAddFiles && isBlindAppendOption.isEmpty) {
            // This transaction was made by an older version which did not set `isBlindAppend` flag.
            // So even if it looks like an append, we don't know for sure if it was a blind append
            // or not. So we suggest them to upgrade all there workloads to latest version.
            Some(
              "Upgrading all your concurrent writers to use the latest Delta Lake may " +
                "avoid this error. Please upgrade and then retry this operation again.")
          } else None
        throw new ConcurrentAppendException(commitInfo, predicatesMatchingAddedFiles.head, retryMsg)
      }
```

## コンパクション

[公式ドキュメントのCompact filesの説明] にある通り、Delta Lakeで細かくデータを書き込むとファイルがたくさんできる。
これは性能に悪影響を及ぼす。
そこで、コンパクション（まとめこみ）を行うことがベストプラクティスとして紹介されている…。

なお、コンパクションでは古いファイルは消されないので、バキュームすることってことも書かれている。

## バキューム

[公式ドキュメントのVacuum] に記載の通り、Deltaテーブルから参照されていないファイルを削除する。
リテンション時間はデフォルト7日間。

`io.delta.tables.DeltaTable#vacuum` メソッドの実態は、

io/delta/tables/DeltaTable.scala:90

```scala
  def vacuum(retentionHours: Double): DataFrame = {
    executeVacuum(deltaLog, Some(retentionHours))
  }
```

の通り、 `io.delta.tables.execution.DeltaTableOperations#executeVacuum` メソッドである。

io/delta/tables/execution/DeltaTableOperations.scala:106

```scala
  protected def executeVacuum(
      deltaLog: DeltaLog,
      retentionHours: Option[Double]): DataFrame = {
    VacuumCommand.gc(sparkSession, deltaLog, false, retentionHours)
    sparkSession.emptyDataFrame
  }
```

なお、 `org.apache.spark.sql.delta.commands.VacuumCommand#gc` メソッドの内容は意外と複雑。
というのも、バキューム対象となるのは、「Deltaテーブルで参照されて **いない** ファイル」となるので、
すべてのファイル（やディレクトリ、そしてディレクトリ内のファイルも）をリストアップし、
その後消してはいけないファイルを除外できるようにして消すようになっている。

### 読まれているファイルの削除

[公式ドキュメントのVacuum] の中で、警告が書かれている。

> We do not recommend that you set a retention interval shorter than 7 days, because old snapshots and uncommitted files can still be in use by concurrent readers or writers to the table.
> If VACUUM cleans up active files, concurrent readers can fail or, worse, tables can be corrupted when VACUUM deletes files that have not yet been committed.

これは、バキューム対象から外す期間（リテンション時間）を不用意に短くしすぎると、
バキューム対象となったファイルを何かしらのトランザクションが読み込んでいる可能性があるからだ、という主旨の内容である。

実装から見ても、 `org.apache.spark.sql.delta.actions.FileAction` トレートに基づくフィルタリングはあるが、
当該トレートの子クラスは

* AddFile
* RemoveFile

であり、読み込みは含まれない。
そのため、仕様上、何らかのトランザクションが読み込んでいるファイルを消すことがあり得る、ということと考えられる。 ★要確認

なお、うっかりミスを防止するためのチェック機能はあり、 `org.apache.spark.sql.delta.commands.VacuumCommand#checkRetentionPeriodSafety` メソッドがその実態である。
このメソッド内では、DeltaLogごとに定義されている `org.apache.spark.sql.delta.DeltaLog#tombstoneRetentionMillis` で指定されるよりも、短い期間をリテンション時間として
指定しているかどうかを確認し、警告を出すようになっている。

つまり、

```
deltaTable.vacuum(100)     // vacuum files not required by versions more than 100 hours old
```

のようにリテンション時間を指定しながらバキュームを実行する際に、DeltaLog自身が保持している `tombstoneRetentionMillis` よりも短い期間を閾値として
バキュームを実行しようとすると警告が生じる。なお、このチェックをオフにすることもできる。

## コンフィグ

`org.apache.spark.sql.delta.DeltaConfigs` あたりにDelta Lakeのコンフィグと説明がある。

例えば、 `org.apache.spark.sql.delta.DeltaConfigs$#LOG_RETENTION` であれば、
`org.apache.spark.sql.delta.MetadataCleanup` トレート内で利用されている。

## ログのクリーンアップ

[コンフィグ](#コンフィグ) にてリテンションを決めるパラメータを例として上げた。
具体的には、以下のように、ログのリテンション時間を決めるパラメータとして利用されている。

org/apache/spark/sql/delta/MetadataCleanup.scala:38

```scala
  def deltaRetentionMillis: Long = {
    val interval = DeltaConfigs.LOG_RETENTION.fromMetaData(metadata)
    DeltaConfigs.getMilliSeconds(interval)
  }
```

上記の `org.apache.spark.sql.delta.MetadataCleanup#deltaRetentionMillis` メソッドは、
`org.apache.spark.sql.delta.MetadataCleanup#cleanUpExpiredLogs` メソッド内で利用される。
このメソッドは古くなったデルタログやチェックポイントを削除する。

このメソッド自体は単純で、以下のような実装である。

org/apache/spark/sql/delta/MetadataCleanup.scala:50

```scala
  private[delta] def cleanUpExpiredLogs(): Unit = {
    recordDeltaOperation(this, "delta.log.cleanup") {
      val fileCutOffTime = truncateDay(clock.getTimeMillis() - deltaRetentionMillis).getTime
      val formattedDate = fileCutOffTime.toGMTString
      logInfo(s"Starting the deletion of log files older than $formattedDate")

      var numDeleted = 0
      listExpiredDeltaLogs(fileCutOffTime.getTime).map(_.getPath).foreach { path =>
        // recursive = false
        if (fs.delete(path, false)) numDeleted += 1
      }
      logInfo(s"Deleted $numDeleted log files older than $formattedDate")
    }
  }
```

ポイントはいくつかある。

* `org.apache.spark.sql.delta.MetadataCleanup#listExpiredDeltaLogs` メソッドは、チェックポイントファイル、デルタファイルの両方について、
  期限切れになっているファイルを返すイテレータを戻す。
* 上記イテレータに対し、mapとforeachでループさせ、ファイルを消す（`fs.delete(path, false)`）
* 最終的に消された件数をログに書き出す

なお、このクリーンアップは、チェックポイントのタイミングで実施される。

org/apache/spark/sql/delta/Checkpoints.scala:119

```scala
  def checkpoint(): Unit = recordDeltaOperation(this, "delta.checkpoint") {
    val checkpointMetaData = checkpoint(snapshot)
    val json = JsonUtils.toJson(checkpointMetaData)
    store.write(LAST_CHECKPOINT, Iterator(json), overwrite = true)

    doLogCleanup()
  }
```

チェックポイントが実行されるのは、別途 [チェックポイントを調査してみる](#チェックポイントを調査してみる) で説明したとおり、
トランザクションがコミットされるタイミングなどである。（正確にはコミット後の処理postCommit処理の中で行われる）

## ParquetからDeltaテーブルへの変換

スキーマ指定する方法としない方法がある。

```scala
import io.delta.tables._

// Convert unpartitioned parquet table at path '/path/to/table'
val deltaTable = DeltaTable.convertToDelta(spark, "parquet.`/path/to/table`")

// Convert partitioned parquet table at path '/path/to/table' and partitioned by integer column named 'part'
val partitionedDeltaTable = DeltaTable.convertToDelta(spark, "parquet.`/path/to/table`", "part int")
```

スキーマを指定しないAPIは以下の通り。

io/delta/tables/DeltaTable.scala:599

```scala
  def convertToDelta(
      spark: SparkSession,
      identifier: String): DeltaTable = {
    val tableId: TableIdentifier = spark.sessionState.sqlParser.parseTableIdentifier(identifier)
    DeltaConvert.executeConvert(spark, tableId, None, None)
  }
```

上記の通り、実態は `io.delta.tables.execution.DeltaConvertBase#executeConvert` メソッドであり、
その中で用いられている `org.apache.spark.sql.delta.commands.ConvertToDeltaCommandBase#run` メソッドである。

io/delta/tables/execution/DeltaConvert.scala:26

```scala
trait DeltaConvertBase {
  def executeConvert(
      spark: SparkSession,
      tableIdentifier: TableIdentifier,
      partitionSchema: Option[StructType],
      deltaPath: Option[String]): DeltaTable = {
    val cvt = ConvertToDeltaCommand(tableIdentifier, partitionSchema, deltaPath)
    cvt.run(spark)
    DeltaTable.forPath(spark, tableIdentifier.table)
  }
}
```

また、上記 `run` メソッド内の実態は `org.apache.spark.sql.delta.commands.ConvertToDeltaCommandBase#performConvert` メソッドである。

org/apache/spark/sql/delta/commands/ConvertToDeltaCommand.scala:76

```scala
  override def run(spark: SparkSession): Seq[Row] = {
    val convertProperties = getConvertProperties(spark, tableIdentifier)

    (snip)

    performConvert(spark, txn, convertProperties)
  }
```

`run` メソッド内の `performConvert` メソッドを利用し、実際に元データからDelta Lakeのデータ構造を作りつつ、
その後の `io.delta.tables.DeltaTable$#forPath(org.apache.spark.sql.SparkSession, java.lang.String)` メソッドを呼び出すことで、
データが正しく出力されたことを確認している。

```
    DeltaTable.forPath(spark, tableIdentifier.table)
```

もし出力された内容に何か問題あるようであれば、 `forPath` メソッドの途中で例外が生じるはず。
ただ、この仕組みだと変換自体は、たとえ失敗したとしても動いてしまう（アトミックな動作ではない）ところが気になった。 ★気になった点

### 動作確認

まずは、サンプルとしてSparkに含まれているParquetファイルを読み込む。

```scala
scala> val originDFPath = "/opt/spark/default/examples/src/main/resources/users.parquet"
scala> val originDF = spark.read.format("parquet").load(originDFPath)
scala> originDF.show
+------+--------------+----------------+
|  name|favorite_color|favorite_numbers|
+------+--------------+----------------+
|Alyssa|          null|  [3, 9, 15, 20]|
|   Ben|           red|              []|
+------+--------------+----------------+
```

では、このParquetファイルを変換する。
`io.delta.tables.DeltaTable#convertToDelta` メソッドの引数で与えるPATHは、
Parqeutテーブルを含む「ディレクトリ」を期待するので、最初にParquetファイルを
適当なディレクトリにコピーしておく。

```shell
$ mkdir /tmp/origin
$ cp /opt/spark/default/examples/src/main/resources/users.parquet /tmp/origin
```

上記ディレクトリを指定して、変換する。

```scala
scala> import io.delta.tables._
scala> val deltaTable = DeltaTable.convertToDelta(spark, s"parquet.`/tmp/origin`")
```

ディレクトリ以下は以下のようになった。

```shel
dobachi@thk:/mnt/c/Users/dobachi/Sources.win/memo-blog-text$ ls -R /tmp/origin/
/tmp/origin/:
_delta_log  users.parquet

/tmp/origin/_delta_log:
00000000000000000000.checkpoint.parquet  00000000000000000000.json  _last_checkpoint
```

なお、メタデータは以下の通り。

```json
$ cat /tmp/origin/_delta_log/00000000000000000000.json | jq

{
  "commitInfo": {
    "timestamp": 1584541495383,
    "operation": "CONVERT",
    "operationParameters": {
      "numFiles": 1,
      "partitionedBy": "[]",
      "collectStats": false
    }
  }
}
{
  "protocol": {
    "minReaderVersion": 1,
    "minWriterVersion": 2
  }
}
{
  "metaData": {
    "id": "40bd74eb-8005-4aaa-a455-fbbb37b22bb7",
    "format": {
      "provider": "parquet",
      "options": {}
    },
    "schemaString": "{\"type\":\"struct\",\"fields\":[{\"name\":\"name\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}},{\"name\":\"favorite_color\",\"type\":\"string\",\"nullable\":true,\"metadata\":{}},{\"name\":\"favorite_numbers\",\"type\":{\"type\":\"array\",\"elementType\":\"integer\",\"containsNull\":true},\"nullable\":true,\"metadata\":{}}]}",
    "partitionColumns": [],
    "configuration": {},
    "createdTime": 1584541495356
  }
}
{
  "add": {
    "path": "users.parquet",
    "partitionValues": {},
    "size": 615,
    "modificationTime": 1584541479000,
    "dataChange": true
  }
}
```

## Symlink Format Manifest

[Presto and Athena to Delta Lake Integration] によると、Presto等で利用可能なマニフェストを出力できる。

ここでは予め `/tmp/delta-table` に作成しておいたDelta Tableを読み込み、マニフェストを出力する。

```scala
scala> import io.delta.tables._
scala> val deltaTable = DeltaTable.forPath("/tmp/delta-table")
scala> deltaTable.generate("symlink_format_manifest")
```

以下のようなディレクトリ、ファイルが出力される。

```shell
$ ls -1
_delta_log
_symlink_format_manifest
derby.log
metastore_db
part-00000-e4518073-8ff1-4c2e-b765-922114a06c08-c000.snappy.parquet
part-00000-f692adf2-c015-4b0b-8db9-8004a69ac80b-c000.snappy.parquet
part-00001-7c3dd52d-f763-4835-9e97-9c6805ceff36-c000.snappy.parquet
part-00001-d13867d8-c685-4a56-b0cd-6541009222a5-c000.snappy.parquet
(snip)
```

`_delta_log` および `part-000...` というディレクトリ、ファイルはもともとDelta Lakeとして
存在していたものである。
これに対し、

* `_symlink_format_manifest`
  * Deltaテーブルが含むファイル群を示すマニフェストを含むディレクトリ
* `derby.log`
  * HiveメタストアDBのログ（Derbyのログ）
* `metastore_db`
  * Hiveメタストア

が出力されたと言える。
マニフェストの内容は以下の通り。

```shell
$ cat _symlink_format_manifest/manifest
file:/tmp/delta-table/part-00002-5f9ef6f0-da56-442d-8232-13937e00a54e-c000.snappy.parquet
file:/tmp/delta-table/part-00007-5522221f-20c2-4d70-aec8-3a990933b50e-c000.snappy.parquet
file:/tmp/delta-table/part-00003-572f44fd-9c36-409a-bbc8-8f23f869e3f1-c000.snappy.parquet
file:/tmp/delta-table/part-00000-f692adf2-c015-4b0b-8db9-8004a69ac80b-c000.snappy.parquet
(snip)
```

上記の例では、パーティション化されていないDeltaテーブルを扱った。
この場合、マニフェストは１個である。
アトミックな書き込みが可能。
Snapshot consistency が実現できる。

一方、 [Presto Athena連係の制約] によるとパーティション化されている場合、マニフェストもパーティション化される。
そのため、全パーティションを通じて一貫性を保つことができない。（部分的な更新が生じうる）

それでは、実装を確認する。

エントリポイントは、公式ドキュメントの例にも載っている `io.delta.tables.DeltaTable#generate` メソッド。


io/delta/tables/DeltaTable.scala:151

```scala
  def generate(mode: String): Unit = {
    val path = deltaLog.dataPath.toString
    executeGenerate(s"delta.`$path`", mode)
  }
```

これの定義を辿っていくと、 `org.apache.spark.sql.delta.commands.DeltaGenerateCommand#run` メソッドにたどり着く。

org/apache/spark/sql/delta/commands/DeltaGenerateCommand.scala:48

```scala
  override def run(sparkSession: SparkSession): Seq[Row] = {
    if (!modeNameToGenerationFunc.contains(modeName)) {
      throw DeltaErrors.unsupportedGenerateModeException(modeName)
    }
    val tablePath = getPath(sparkSession, tableId)
    val deltaLog = DeltaLog.forTable(sparkSession, tablePath)
    if (deltaLog.snapshot.version < 0) {
      throw new AnalysisException(s"Delta table not found at $tablePath.")
    }
    val generationFunc = modeNameToGenerationFunc(modeName)
    generationFunc(sparkSession, deltaLog)
    Seq.empty
  }
}
```

上記の通り、Delta LakeのディレクトリからDeltaLogを再現し、
それを引数としてマニフェストを生成するメソッドを呼び出す。
変数にバインドするなどしているが、実態は `org.apache.spark.sql.delta.hooks.GenerateSymlinkManifestImpl#generateFullManifest` メソッドである。

org/apache/spark/sql/delta/commands/DeltaGenerateCommand.scala:63

```scala
object DeltaGenerateCommand {
  val modeNameToGenerationFunc = CaseInsensitiveMap(
    Map[String, (SparkSession, DeltaLog) => Unit](
    "symlink_format_manifest" -> GenerateSymlinkManifest.generateFullManifest
  ))
}
```

そこで当該メソッドの内容を軽く確認する。

org/apache/spark/sql/delta/hooks/GenerateSymlinkManifest.scala:154

```scala
  def generateFullManifest(
      spark: SparkSession,
      deltaLog: DeltaLog): Unit = recordManifestGeneration(deltaLog, full = true) {

    val snapshot = deltaLog.update(stalenessAcceptable = false)
    val partitionCols = snapshot.metadata.partitionColumns
    val manifestRootDirPath = new Path(deltaLog.dataPath, MANIFEST_LOCATION).toString
    val hadoopConf = new SerializableConfiguration(spark.sessionState.newHadoopConf())

    // Update manifest files of the current partitions
    val newManifestPartitionRelativePaths = writeManifestFiles(
      deltaLog.dataPath,
      manifestRootDirPath,
      snapshot.allFiles,
      partitionCols,
      hadoopConf)

(snip)
```

ポイントは、 `org.apache.spark.sql.delta.hooks.GenerateSymlinkManifestImpl#writeManifestFiles` メソッドである。
これが実際にマニフェストを書き出すメソッド。

## 類似技術

* Apache Hudi
  * https://hudi.apache.org/
* Ice
  * https://iceberg.apache.org/

