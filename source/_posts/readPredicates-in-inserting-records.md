---

title: readPredicates in inserting records
date: 2021-04-23 09:28:13
categories:
  - Knowledge Management
  - Storage Layer
  - Delta Lake
tags:
  - Delta Lake

---

# 参考


# メモ

## 前提

Delta Lake 0.7.0

## 動機

Delta Lakeのトランザクション管理について、
`org.apache.spark.sql.delta.OptimisticTransactionImpl#readPredicates`
がどのように利用されるか、を確認した。

特にInsert時に、競合確認するかどうかを決めるにあたって重要な変数である。

org/apache/spark/sql/delta/OptimisticTransaction.scala:600

```scala
      val predicatesMatchingAddedFiles = ExpressionSet(readPredicates).iterator.flatMap { p =>
        val conflictingFile = DeltaLog.filterFileList(
          metadata.partitionSchema,
          addedFilesToCheckForConflicts.toDF(), p :: Nil).as[AddFile].take(1)

        conflictingFile.headOption.map(f => getPrettyPartitionMessage(f.partitionValues))
      }.take(1).toArray
```

## 準備

SparkをDelta Lakeと一緒に起動する。
（ここではついでにデバッガをアタッチするコンフィグを付与している。不要なら、--driver-java-optionsを除外する）

```shell
dobachi@home:~/tmp$ /opt/spark/default/bin/spark-shell --packages io.delta:delta-core_2.12:0.7.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" --driver-java-options "-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=localhost:5005"
```

ファイルはSparkに含まれているサンプルファイルを使うことにする。

```scala
scala> val filePath = "/home/dobachi/Sources/spark/examples/src/main/resources/users.parquet"
filePath: String = /home/dobachi/Sources/spark/examples/src/main/resources/users.parquet

scala> val df = spark.read.parquet(filePath)
df: org.apache.spark.sql.DataFrame = [name: string, favorite_color: string ... 1 more field]
```

こんな感じのデータ

```scala
scala> df.show
+------+--------------+----------------+
|  name|favorite_color|favorite_numbers|
+------+--------------+----------------+
|Alyssa|          null|  [3, 9, 15, 20]|
|   Ben|           red|              []|
+------+--------------+----------------+
```

テーブル作成

```scala
df.write.format("delta").save("users1") 
```

ここまでで後でデータを追記するためのテーブル作成が完了。

## 簡単な動作確認

ここで、競合状況を再現するため、もうひとつターミナルを開き、Sparkシェルを起動した。

```shell
/opt/spark/default/bin/spark-shell --packages io.delta:delta-core_2.12:0.7.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
```

ターミナル1でデバッガを有効化しながら、以下を実行。

```scala
val tblPath = "users1"
df.write.format("delta").mode("append").save(tblPath)
```

ちなみにブレイクポイントは以下の箇所に設定した。

org/apache/spark/sql/delta/OptimisticTransaction.scala:482

```scala
      deltaLog.store.write(
        deltaFile(deltaLog.logPath, attemptVersion),
        actions.map(_.json).toIterator)
```

ターミナル2で以下を実行し、コンパクション実施。

```scala
val tblPath = "users1"
spark.read
 .format("delta")
 .load(tblPath)
 .repartition(2)
 .write
 .option("dataChange", "false")
 .format("delta")
 .mode("overwrite")
 .save(tblPath)
```

ターミナル1の処理で使用しているデバッガで、以下のあたりにブレイクポイントをおいて確認した。

org/apache/spark/sql/delta/OptimisticTransaction.scala:595

```scala
      val addedFilesToCheckForConflicts = commitIsolationLevel match {
        case Serializable => changedDataAddedFiles ++ blindAppendAddedFiles
        case WriteSerializable => changedDataAddedFiles // don't conflict with blind appends
        case SnapshotIsolation => Seq.empty
      }
```

この場合、`org.apache.spark.sql.delta.OptimisticTransactionImpl#readPredicates` はこのタイミングでは空のArrayBufferだった。

## readPredicatesに書き込みが生じるケース

以下の通り。

org/apache/spark/sql/delta/OptimisticTransaction.scala:239

```scala
  def filterFiles(filters: Seq[Expression]): Seq[AddFile] = {
    val scan = snapshot.filesForScan(Nil, filters)
    val partitionFilters = filters.filter { f =>
      DeltaTableUtils.isPredicatePartitionColumnsOnly(f, metadata.partitionColumns, spark)
    }
    readPredicates += partitionFilters.reduceLeftOption(And).getOrElse(Literal(true))
    readFiles ++= scan.files
    scan.files
  }

  /** Mark the entire table as tainted by this transaction. */
  def readWholeTable(): Unit = {
    readPredicates += Literal(true)
  }
```

`org.apache.spark.sql.delta.OptimisticTransactionImpl#filterFiles` メソッドは主にファイルを消すときに用いられる。
DELETEするとき、Updateするとき、Overwriteするとき（条件付き含む）など。

`org.apache.spark.sql.delta.OptimisticTransactionImpl#readWholeTable` メソッドは
ストリーム処理で書き込む際に用いられる。
書き込もうとしているテーブルを読んでいる場合はreadPredicatesに真値を追加する。

<!-- vim: set et tw=0 ts=2 sw=2: -->
