---
title: Hudi
date: 2020-03-25 23:40:12
categories:
  - Knowledge Management
  - Storage Layer
  - Hudi
tags:
  - Apache Hudi
  - Storage Layer
---

# 参考

* [公式ドキュメント]
* [Quick Start Guide]
* [Writing Hudi Tables]
* [公式ドキュメントのData Streamer]

* [apurvam streams-prototyping]

[公式ドキュメント]: https://hudi.apache.org/
[Quick Start Guide]: https://hudi.apache.org/docs/quick-start-guide.html
[Writing Hudi Tables]: https://hudi.apache.org/docs/writing_data.html
[公式ドキュメントのData Streamer]: https://hudi.apache.org/docs/writing_data.html#deltastreamer

[apurvam streams-prototyping]: https://github.com/apurvam/streams-prototyping


# メモ

## 公式ドキュメント

載っている特徴は、以下の通り。

* Upsert support with fast, pluggable indexing.
* Atomically publish data with rollback support.
* Snapshot isolation between writer & queries.
* Savepoints for data recovery.
* Manages file sizes, layout using statistics.
* Async compaction of row & columnar data.
* Timeline metadata to track lineage.

## クイックスタートから確認（version 0.5.2前提）

[Quick Start Guide] を参考に進める。

公式ドキュメントではSpark2.4.4を利用しているが、ここでは2.4.5を利用する。

```shell
$ export SPARK_HOME=/opt/spark/default
$ ${SPARK_HOME}/bin/spark-shell \
  --packages org.apache.hudi:hudi-spark-bundle_2.11:0.5.2-incubating,org.apache.spark:spark-avro_2.11:2.4.5 \
  --conf 'spark.serializer=org.apache.spark.serializer.KryoSerializer'
```

必要なライブラリをインポート

```scala
scala> import org.apache.hudi.QuickstartUtils._
scala> import scala.collection.JavaConversions._
scala> import org.apache.spark.sql.SaveMode._
scala> import org.apache.hudi.DataSourceReadOptions._
scala> import org.apache.hudi.DataSourceWriteOptions._
scala> import org.apache.hudi.config.HoodieWriteConfig._
scala> 
scala> val tableName = "hudi_trips_cow"
scala> val basePath = "file:///tmp/hudi_trips_cow"
scala> val dataGen = new DataGenerator
```

ダミーデータには `org.apache.hudi.QuickstartUtils.DataGenerator` クラスを利用する。
以下の例では、 `org.apache.hudi.QuickstartUtils.DataGenerator#generateInserts` メソッドを利用しデータを生成するが、
どういうレコードが生成されるかは、 `org.apache.hudi.QuickstartUtils.DataGenerator#generateRandomValue` メソッドあたりを見るとわかる。

ダミーデータを生成し、Spark DataFrameに変換。

```scala
scala> val inserts = convertToStringList(dataGen.generateInserts(10))
scala> val df = spark.read.json(spark.sparkContext.parallelize(inserts, 2))
```

中身は以下。

```scala
scala> df.show
+-------------------+-------------------+----------+-------------------+-------------------+------------------+--------------------+---------+---+--------------------+
|          begin_lat|          begin_lon|    driver|            end_lat|            end_lon|              fare|       partitionpath|    rider| ts|                uuid|
+-------------------+-------------------+----------+-------------------+-------------------+------------------+--------------------+---------+---+--------------------+
| 0.4726905879569653|0.46157858450465483|driver-213|  0.754803407008858| 0.9671159942018241|34.158284716382845|americas/brazil/s...|rider-213|0.0|28432dec-53eb-402...|
| 0.6100070562136587| 0.8779402295427752|driver-213| 0.3407870505929602| 0.5030798142293655|  43.4923811219014|americas/brazil/s...|rider-213|0.0|1bd3905e-a6c4-404...|
| 0.5731835407930634| 0.4923479652912024|driver-213|0.08988581780930216|0.42520899698713666| 64.27696295884016|americas/united_s...|rider-213|0.0|c9cc8f4b-acee-413...|
|0.21624150367601136|0.14285051259466197|driver-213| 0.5890949624813784| 0.0966823831927115| 93.56018115236618|americas/united_s...|rider-213|0.0|4be1c199-86dc-489...|
|   0.40613510977307| 0.5644092139040959|driver-213|  0.798706304941517|0.02698359227182834|17.851135255091155|  asia/india/chennai|rider-213|0.0|83f4d3df-46c1-48a...|
| 0.8742041526408587| 0.7528268153249502|driver-213| 0.9197827128888302|  0.362464770874404|19.179139106643607|americas/united_s...|rider-213|0.0|cb8b392d-c9d0-445...|
| 0.1856488085068272| 0.9694586417848392|driver-213|0.38186367037201974|0.25252652214479043| 33.92216483948643|americas/united_s...|rider-213|0.0|66aaf87d-4786-4d0...|
| 0.0750588760043035|0.03844104444445928|driver-213|0.04376353354538354| 0.6346040067610669| 66.62084366450246|americas/brazil/s...|rider-213|0.0|c5a335f5-c57f-4f5...|
|  0.651058505660742| 0.8192868687714224|driver-213|0.20714896002914462|0.06224031095826987| 41.06290929046368|  asia/india/chennai|rider-213|0.0|53026eda-28c4-4d8...|
|0.11488393157088261| 0.6273212202489661|driver-213| 0.7454678537511295| 0.3954939864908973| 27.79478688582596|americas/united_s...|rider-213|0.0|cd42df54-5215-402...|
+-------------------+-------------------+----------+-------------------+-------------------+------------------+--------------------+---------+---+--------------------+
```

```scala
scala> df.write.format("hudi").
         options(getQuickstartWriteConfigs).
         option(PRECOMBINE_FIELD_OPT_KEY, "ts").
         option(RECORDKEY_FIELD_OPT_KEY, "uuid").
         option(PARTITIONPATH_FIELD_OPT_KEY, "partitionpath").
         option(TABLE_NAME, tableName).
         mode(Overwrite).
         save(basePath)
```

なお、生成されたファイルは以下の通り。
`PARTITIONPATH_FIELD_OPT_KEY` で指定したカラムをパーティションキーとして用いていることがわかる。

```shell
$ ls -R /tmp/hudi_trips_cow/
/tmp/hudi_trips_cow/:
americas  asia

/tmp/hudi_trips_cow/americas:
brazil  united_states

/tmp/hudi_trips_cow/americas/brazil:
sao_paulo

/tmp/hudi_trips_cow/americas/brazil/sao_paulo:
ae28c85a-38f0-487f-a42d-3a0babc9d321-0_0-21-25_20200329002247.parquet

/tmp/hudi_trips_cow/americas/united_states:
san_francisco

/tmp/hudi_trips_cow/americas/united_states/san_francisco:
849db286-1cbe-4a1f-b544-9939893e99f8-0_1-21-26_20200329002247.parquet

/tmp/hudi_trips_cow/asia:
india

/tmp/hudi_trips_cow/asia/india:
chennai

/tmp/hudi_trips_cow/asia/india/chennai:
2ebfbab0-4f8f-42db-b79e-1c0cbcc3cf39-0_2-21-27_20200329002247.parquet
```

保存したデータを読み出してみる。

```scala
scala> val tripsSnapshotDF = spark.
         read.
         format("hudi").
         load(basePath + "/*/*/*/*")
scala> tripsSnapshotDF.createOrReplaceTempView("hudi_trips_snapshot")
```

中身は以下の通り。
元データに対し、Hudiのカラムが追加されていることがわかる。

```scala
scala> tripsSnapshotDF.show
+-------------------+--------------------+--------------------+----------------------+--------------------+-------------------+-------------------+----------+-------------------+-------------------+------------------+--------------------+---------+---+--------------------+
|_hoodie_commit_time|_hoodie_commit_seqno|  _hoodie_record_key|_hoodie_partition_path|   _hoodie_file_name|          begin_lat|          begin_lon|    driver|            end_lat|            end_lon|              fare|       partitionpath|    rider| ts|                uuid|
+-------------------+--------------------+--------------------+----------------------+--------------------+-------------------+-------------------+----------+-------------------+-------------------+------------------+--------------------+---------+---+--------------------+
|     20200329002247|  20200329002247_1_1|7695c291-8530-473...|  americas/united_s...|849db286-1cbe-4a1...|0.21624150367601136|0.14285051259466197|driver-213| 0.5890949624813784| 0.0966823831927115| 93.56018115236618|americas/united_s...|rider-213|0.0|7695c291-8530-473...|
|     20200329002247|  20200329002247_1_3|2f06fcd2-8296-423...|  americas/united_s...|849db286-1cbe-4a1...| 0.5731835407930634| 0.4923479652912024|driver-213|0.08988581780930216|0.42520899698713666| 64.27696295884016|americas/united_s...|rider-213|0.0|2f06fcd2-8296-423...|
|     20200329002247|  20200329002247_1_5|6ebc4028-9aae-420...|  americas/united_s...|849db286-1cbe-4a1...| 0.8742041526408587| 0.7528268153249502|driver-213| 0.9197827128888302|  0.362464770874404|19.179139106643607|americas/united_s...|rider-213|0.0|6ebc4028-9aae-420...|
|     20200329002247|  20200329002247_1_6|8bf60390-ad41-4b0...|  americas/united_s...|849db286-1cbe-4a1...|0.11488393157088261| 0.6273212202489661|driver-213| 0.7454678537511295| 0.3954939864908973| 27.79478688582596|americas/united_s...|rider-213|0.0|8bf60390-ad41-4b0...|
|     20200329002247|  20200329002247_1_7|762e8cb2-8806-47d...|  americas/united_s...|849db286-1cbe-4a1...| 0.1856488085068272| 0.9694586417848392|driver-213|0.38186367037201974|0.25252652214479043| 33.92216483948643|americas/united_s...|rider-213|0.0|762e8cb2-8806-47d...|
|     20200329002247|  20200329002247_0_8|28622337-d76b-442...|  americas/brazil/s...|ae28c85a-38f0-487...| 0.6100070562136587| 0.8779402295427752|driver-213| 0.3407870505929602| 0.5030798142293655|  43.4923811219014|americas/brazil/s...|rider-213|0.0|28622337-d76b-442...|
|     20200329002247|  20200329002247_0_9|33aec15d-356f-475...|  americas/brazil/s...|ae28c85a-38f0-487...| 0.0750588760043035|0.03844104444445928|driver-213|0.04376353354538354| 0.6346040067610669| 66.62084366450246|americas/brazil/s...|rider-213|0.0|33aec15d-356f-475...|
|     20200329002247| 20200329002247_0_10|2d71c9a3-26a3-40b...|  americas/brazil/s...|ae28c85a-38f0-487...| 0.4726905879569653|0.46157858450465483|driver-213|  0.754803407008858| 0.9671159942018241|34.158284716382845|americas/brazil/s...|rider-213|0.0|2d71c9a3-26a3-40b...|
|     20200329002247|  20200329002247_2_2|a997a8f0-4ab6-4d5...|    asia/india/chennai|2ebfbab0-4f8f-42d...|   0.40613510977307| 0.5644092139040959|driver-213|  0.798706304941517|0.02698359227182834|17.851135255091155|  asia/india/chennai|rider-213|0.0|a997a8f0-4ab6-4d5...|
|     20200329002247|  20200329002247_2_4|271de424-a0f8-427...|    asia/india/chennai|2ebfbab0-4f8f-42d...|  0.651058505660742| 0.8192868687714224|driver-213|0.20714896002914462|0.06224031095826987| 41.06290929046368|  asia/india/chennai|rider-213|0.0|271de424-a0f8-427...|
+-------------------+--------------------+--------------------+----------------------+--------------------+-------------------+-------------------+----------+-------------------+-------------------+------------------+--------------------+---------+---+--------------------+
```

上記の通り、SparkのData Source機能を利用している。
中では、`org.apache.hudi.DefaultSource#createRelation` メソッドが用いられる。

つづいて、更新を試す。

```scala
scala> val updates = convertToStringList(dataGen.generateUpdates(10))
scala> val df = spark.read.json(spark.sparkContext.parallelize(updates, 2))
scala> df.write.format("hudi").
         options(getQuickstartWriteConfigs).
         option(PRECOMBINE_FIELD_OPT_KEY, "ts").
         option(RECORDKEY_FIELD_OPT_KEY, "uuid").
         option(PARTITIONPATH_FIELD_OPT_KEY, "partitionpath").
         option(TABLE_NAME, tableName).
         mode(Append).
         save(basePath)
```

もう一度、DataFrameとして読み出すと、レコードが追加されていることを確かめられる。（ここでは省略）
この後の、 `incremental` クエリタイプの実験のため、上記の更新を幾度か実行しておく。

つづいて、 `incremental` クエリタイプで読み出す。

一度読み出し、最初のコミット時刻を取り出す。

```scala
scala> spark.
         read.
         format("hudi").
         load(basePath + "/*/*/*/*").
         createOrReplaceTempView("hudi_trips_snapshot")

scala> val commits = spark.sql("select distinct(_hoodie_commit_time) as commitTime from  hudi_trips_snapshot order by commitTime").map(k => k.getString(0)).take(50)
scala> val beginTime = commits(commits.length - 2) // commit time we are interested in
```

今回は、初回書き込みに加えて2回更新したので、
`commits` は以下の通り。

```scala
scala> commits
res12: Array[String] = Array(20200330002239, 20200330002354, 20200330003142)
```

また、今回「読み込みの最初」とするコミットは、以下の通り。
つまり、2回目の更新時。

```scala
scala> beginTime
res13: String = 20200330002354
```

では、 `incremental` クエリタイプで読み出す。

```scala
scala> val tripsIncrementalDF = spark.read.format("hudi").
         option(QUERY_TYPE_OPT_KEY, QUERY_TYPE_INCREMENTAL_OPT_VAL).
         option(BEGIN_INSTANTTIME_OPT_KEY, beginTime).
         load(basePath)
scala> tripsIncrementalDF.createOrReplaceTempView("hudi_trips_incremental")

scala> spark.sql("select `_hoodie_commit_time`, fare, begin_lon, begin_lat, ts from  hudi_trips_incremental where fare > 20.0").show()
```

結果は以下のようなイメージ。

```scala
scala> spark.sql("select `_hoodie_commit_time`, fare, begin_lon, begin_lat, ts from  hudi_trips_incremental where fare > 20.0").show()
+-------------------+------------------+--------------------+-------------------+---+
|_hoodie_commit_time|              fare|           begin_lon|          begin_lat| ts|
+-------------------+------------------+--------------------+-------------------+---+
|     20200330003142| 87.68271062363665|  0.9273857651526887| 0.1620033132033215|0.0|
|     20200330003142| 40.44073446276323|9.842943407509797E-4|0.47631824594751015|0.0|
|     20200330003142| 45.39370966816483|    0.65888271115305| 0.8535610661589833|0.0|
|     20200330003142|47.332186591003044|  0.8006023508896579| 0.9025851737325563|0.0|
|     20200330003142| 93.34457064050349|  0.6331319396951335| 0.5375953886834237|0.0|
|     20200330003142|31.065524210209226|  0.7608842984578864| 0.9514417909802292|0.0|
+-------------------+------------------+--------------------+-------------------+---+
```

なお、ここでbeginTimeを1遡ることにすると…。

```scala
scala> val beginTime = commits(commits.length - 3) // commit time we are interested in
```

以下のように、2回目のコミットも含まれるようになる。

```scala
scala> spark.sql("select `_hoodie_commit_time`, fare, begin_lon, begin_lat, ts from  hudi_trips_incremental where fare > 20.0").show()
+-------------------+------------------+--------------------+-------------------+---+
|_hoodie_commit_time|              fare|           begin_lon|          begin_lat| ts|
+-------------------+------------------+--------------------+-------------------+---+
|     20200330003142| 87.68271062363665|  0.9273857651526887| 0.1620033132033215|0.0|
|     20200330003142| 40.44073446276323|9.842943407509797E-4|0.47631824594751015|0.0|
|     20200330003142| 45.39370966816483|    0.65888271115305| 0.8535610661589833|0.0|
|     20200330003142|47.332186591003044|  0.8006023508896579| 0.9025851737325563|0.0|
|     20200330002354| 39.09858962414072| 0.08151154133724581|0.21729959707372848|0.0|
|     20200330003142| 93.34457064050349|  0.6331319396951335| 0.5375953886834237|0.0|
|     20200330002354| 80.87869643345753|  0.0748253615757305| 0.9787639413761751|0.0|
|     20200330003142|31.065524210209226|  0.7608842984578864| 0.9514417909802292|0.0|
|     20200330002354|21.602186045036387|   0.772134626462835| 0.3291184473506418|0.0|
|     20200330002354| 43.41497201940956|  0.6226833057042072| 0.5501675314928346|0.0|
|     20200330002354| 35.71294622426758|  0.6696123015022845| 0.7318572150654761|0.0|
|     20200330002354| 67.30906296028802| 0.16768228612130764|0.29666655980198253|0.0|
+-------------------+------------------+--------------------+-------------------+---+
```

### org.apache.hudi.DefaultSource#createRelation（書き込み）

クイックスタートで、例えば更新などする際の動作を確認する。

```scala
scala> df.write.format("hudi").
     |   options(getQuickstartWriteConfigs).
     |   option(PRECOMBINE_FIELD_OPT_KEY, "ts").
     |   option(RECORDKEY_FIELD_OPT_KEY, "uuid").
     |   option(PARTITIONPATH_FIELD_OPT_KEY, "partitionpath").
     |   option(TABLE_NAME, tableName).
     |   mode(Append).
     |   save(basePath)
```

のような例を実行する際、内部的には `org.apache.hudi.DefaultSource#createRelation` が呼ばれる。

org/apache/hudi/DefaultSource.scala:85

```scala
  override def createRelation(sqlContext: SQLContext,
                              mode: SaveMode,
                              optParams: Map[String, String],
                              df: DataFrame): BaseRelation = {

    val parameters = HoodieSparkSqlWriter.parametersWithWriteDefaults(optParams)
    HoodieSparkSqlWriter.write(sqlContext, mode, parameters, df)
    createRelation(sqlContext, parameters, df.schema)
  }
```

上記メソッド内では、 `org.apache.hudi.HoodieSparkSqlWriter$#write` メソッドが呼ばれており、
これが書き込みの実態である。
なお、その下の `org.apache.hudi.DefaultSource#createRelation` は、読み込み時に呼ばれるものと同一。

ここでは `org.apache.hudi.HoodieSparkSqlWriter#write` メソッドを確認する。
当該メソッドの冒頭では、オペレーションの判定などいくつか前処理が行われた後、
以下の箇所から実際に書き出す処理が定義されている。

org/apache/hudi/HoodieSparkSqlWriter.scala:85

```scala
    val (writeStatuses, writeClient: HoodieWriteClient[HoodieRecordPayload[Nothing]]) =
      if (!operation.equalsIgnoreCase(DELETE_OPERATION_OPT_VAL)) {
      // register classes & schemas
      val structName = s"${tblName.get}_record"
      val nameSpace = s"hoodie.${tblName.get}"
      sparkContext.getConf.registerKryoClasses(
        Array(classOf[org.apache.avro.generic.GenericData],
          classOf[org.apache.avro.Schema]))
      val schema = AvroConversionUtils.convertStructTypeToAvroSchema(df.schema, structName, nameSpace)
      sparkContext.getConf.registerAvroSchemas(schema)

      (snip)
```

まず `delete` オペレーションかどうかで処理が別れるが、上記の例では `upsert` オペレーションなので一旦そのまま読み進める。
ネームスペース（データベースやテーブル？）を取得した後、SparkのStructTypeで保持されたスキーマ情報を、AvroのSchemaに変換する。
変換されたスキーマをSparkで登録する。

つづいて、DataFrameをRDDに変換する。

org/apache/hudi/HoodieSparkSqlWriter.scala:97

```scala
      // Convert to RDD[HoodieRecord]
      val keyGenerator = DataSourceUtils.createKeyGenerator(toProperties(parameters))
      val genericRecords: RDD[GenericRecord] = AvroConversionUtils.createRdd(df, structName, nameSpace)
      val hoodieAllIncomingRecords = genericRecords.map(gr => {
        val orderingVal = DataSourceUtils.getNestedFieldValAsString(
          gr, parameters(PRECOMBINE_FIELD_OPT_KEY), false).asInstanceOf[Comparable[_]]
        DataSourceUtils.createHoodieRecord(gr,
          orderingVal, keyGenerator.getKey(gr), parameters(PAYLOAD_CLASS_OPT_KEY))
      }).toJavaRDD()
```

RDDに一度変換した後、mapメソッドで加工する。

まず、 `genericRecords` の内容は以下のようなものが含まれる。

```
result = {GenericRecord[1]@27822} 
 0 = {GenericData$Record@27827} "{"begin_lat": 0.09632451474505643, "begin_lon": 0.8989273848550128, "driver": "driver-164", "end_lat": 0.6431885917325862, "end_lon": 0.6664889106258252, "fare": 86.865568091804, "partitionpath": "americas/brazil/sao_paulo", "rider": "rider-164", "ts": 0.0, "uuid": "5d49cfb5-0db4-4172-bff4-e581eb1f9783"}"
  schema = {Schema$RecordSchema@27835} "{"type":"record","name":"hudi_trips_cow_record","namespace":"hoodie.hudi_trips_cow","fields":[{"name":"begin_lat","type":["double","null"]},{"name":"begin_lon","type":["double","null"]},{"name":"driver","type":["string","null"]},{"name":"end_lat","type":["double","null"]},{"name":"end_lon","type":["double","null"]},{"name":"fare","type":["double","null"]},{"name":"partitionpath","type":["string","null"]},{"name":"rider","type":["string","null"]},{"name":"ts","type":["double","null"]},{"name":"uuid","type":["string","null"]}]}"
  values = {Object[10]@27836} 
   0 = {Double@27838} 0.09632451474505643
   1 = {Double@27839} 0.8989273848550128
   2 = {Utf8@27840} "driver-164"
   3 = {Double@27841} 0.6431885917325862
   4 = {Double@27842} 0.6664889106258252
   5 = {Double@27843} 86.865568091804
   6 = {Utf8@27844} "americas/brazil/sao_paulo"
   7 = {Utf8@27845} "rider-164"
   8 = {Double@27846} 0.0
   9 = {Utf8@27847} "5d49cfb5-0db4-4172-bff4-e581eb1f9783"
```

上記の通り、これは入ロクレコードそのものである。
その後、mapメソッドを使ってHudiで利用するキーを含む、Hudiのレコード形式に変換する。

変換された `hoodieAllIncomingRecords` は以下のような内容になる。

```
result = {Wrappers$SeqWrapper@27881}  size = 1
 0 = {HoodieRecord@27883} "HoodieRecord{key=HoodieKey { recordKey=5d49cfb5-0db4-4172-bff4-e581eb1f9783 partitionPath=americas/brazil/sao_paulo}, currentLocation='null', newLocation='null'}"
  key = {HoodieKey@27892} "HoodieKey { recordKey=5d49cfb5-0db4-4172-bff4-e581eb1f9783 partitionPath=americas/brazil/sao_paulo}"
   recordKey = "5d49cfb5-0db4-4172-bff4-e581eb1f9783"
   partitionPath = "americas/brazil/sao_paulo"
  data = {OverwriteWithLatestAvroPayload@27893} 
   recordBytes = {byte[142]@27895} 
   orderingVal = "0.0"
  currentLocation = null
  newLocation = null
  sealed = false
```

上記の例の通り、ペイロードは `org.apache.hudi.common.model.OverwriteWithLatestAvroPayload` で保持される。

その後、いくつかモードの確認が行われた後、もしテーブルがなければ `org.apache.hudi.common.table.HoodieTableMetaClient#initTableType` を用いて
テーブルを初期化する。

その後、重複レコードを必要に応じて落とす。

org/apache/hudi/HoodieSparkSqlWriter.scala:132

```scala
      val hoodieRecords =
        if (parameters(INSERT_DROP_DUPS_OPT_KEY).toBoolean) {
          DataSourceUtils.dropDuplicates(
            jsc,
            hoodieAllIncomingRecords,
            mapAsJavaMap(parameters), client.getTimelineServer)
        } else {
          hoodieAllIncomingRecords
        }
```

レコードが空かどうかを改めて確認しつつ、
最後に書き込み実施。
`org.apache.hudi.DataSourceUtils#doWriteOperation` が実態である。

org/apache/hudi/HoodieSparkSqlWriter.scala:147

```
      val writeStatuses = DataSourceUtils.doWriteOperation(client, hoodieRecords, commitTime, operation)
```

`org.apache.hudi.DataSourceUtils#doWriteOperation` メソッドは以下の通り。

org/apache/hudi/DataSourceUtils.java:162

```java
  public static JavaRDD<WriteStatus> doWriteOperation(HoodieWriteClient client, JavaRDD<HoodieRecord> hoodieRecords,
                                                      String commitTime, String operation) {
    if (operation.equals(DataSourceWriteOptions.BULK_INSERT_OPERATION_OPT_VAL())) {
      return client.bulkInsert(hoodieRecords, commitTime);
    } else if (operation.equals(DataSourceWriteOptions.INSERT_OPERATION_OPT_VAL())) {
      return client.insert(hoodieRecords, commitTime);
    } else {
      // default is upsert
      return client.upsert(hoodieRecords, commitTime);
    }
  }
```

今回の例だと、 `upseart` オペレーションなので `org.apache.hudi.client.HoodieWriteClient#upsert` メソッドが呼ばれる。
このメソッドは以下のとおりだが、ポイントは、 `org.apache.hudi.client.HoodieWriteClient#upsertRecordsInternal` メソッドである。

```java
  public JavaRDD<WriteStatus> upsert(JavaRDD<HoodieRecord<T>> records, final String commitTime) {
    HoodieTable<T> table = getTableAndInitCtx(OperationType.UPSERT);
    try {
      // De-dupe/merge if needed
      JavaRDD<HoodieRecord<T>> dedupedRecords =
          combineOnCondition(config.shouldCombineBeforeUpsert(), records, config.getUpsertShuffleParallelism());

      Timer.Context indexTimer = metrics.getIndexCtx();
      // perform index loop up to get existing location of records
      JavaRDD<HoodieRecord<T>> taggedRecords = getIndex().tagLocation(dedupedRecords, jsc, table);
      metrics.updateIndexMetrics(LOOKUP_STR, metrics.getDurationInMs(indexTimer == null ? 0L : indexTimer.stop()));
      return upsertRecordsInternal(taggedRecords, commitTime, table, true);
    } catch (Throwable e) {
      if (e instanceof HoodieUpsertException) {
        throw (HoodieUpsertException) e;
      }
      throw new HoodieUpsertException("Failed to upsert for commit time " + commitTime, e);
    }
  }
```

`org.apache.hudi.client.HoodieWriteClient#upsertRecordsInternal` メソッド内のポイントは、
以下の箇所。
`org.apache.spark.api.java.AbstractJavaRDDLike#mapPartitionsWithIndex` メソッドで、upsertやinsertの処理を定義している。

org/apache/hudi/client/HoodieWriteClient.java:470

```java
    JavaRDD<WriteStatus> writeStatusRDD = partitionedRecords.mapPartitionsWithIndex((partition, recordItr) -> {
      if (isUpsert) {
        return hoodieTable.handleUpsertPartition(commitTime, partition, recordItr, partitioner);
      } else {
        return hoodieTable.handleInsertPartition(commitTime, partition, recordItr, partitioner);
      }
    }, true).flatMap(List::iterator);

    return updateIndexAndCommitIfNeeded(writeStatusRDD, hoodieTable, commitTime);
```

ここでは、 `org.apache.hudi.table.HoodieCopyOnWriteTable#handleUpsertPartition` メソッドを確認してみる。

org/apache/hudi/table/HoodieCopyOnWriteTable.java:253

```java
  public Iterator<List<WriteStatus>> handleUpsertPartition(String commitTime, Integer partition, Iterator recordItr,
      Partitioner partitioner) {
    UpsertPartitioner upsertPartitioner = (UpsertPartitioner) partitioner;
    BucketInfo binfo = upsertPartitioner.getBucketInfo(partition);
    BucketType btype = binfo.bucketType;
    try {
      if (btype.equals(BucketType.INSERT)) {
        return handleInsert(commitTime, binfo.fileIdPrefix, recordItr);
      } else if (btype.equals(BucketType.UPDATE)) {
        return handleUpdate(commitTime, binfo.fileIdPrefix, recordItr);
      } else {
        throw new HoodieUpsertException("Unknown bucketType " + btype + " for partition :" + partition);
      }
    } catch (Throwable t) {
      String msg = "Error upserting bucketType " + btype + " for partition :" + partition;
      LOG.error(msg, t);
      throw new HoodieUpsertException(msg, t);
    }
  }
```

真ん中あたりに、INSERTかUPDATEかで条件分岐しているが、ここでは例としてINSERT側を確認する。
`org.apache.hudi.table.HoodieCopyOnWriteTable#handleInsert` メソッドがポイントとなる。
なお、当該メッソッドには同期的な実装と、非同期的な実装があるよう。
ここでは上記呼び出しに基づき、非同期的な実装の方を確認する。

org/apache/hudi/table/HoodieCopyOnWriteTable.java:233

```java
  public Iterator<List<WriteStatus>> handleInsert(String commitTime, String idPfx, Iterator<HoodieRecord<T>> recordItr)
      throws Exception {
    // This is needed since sometimes some buckets are never picked in getPartition() and end up with 0 records
    if (!recordItr.hasNext()) {
      LOG.info("Empty partition");
      return Collections.singletonList((List<WriteStatus>) Collections.EMPTY_LIST).iterator();
    }
    return new CopyOnWriteLazyInsertIterable<>(recordItr, config, commitTime, this, idPfx);
  }
```

戻り値が、 `org.apache.hudi.execution.CopyOnWriteLazyInsertIterable` クラスのインスタンスになっていることがわかる。
このイテレータは、 `org.apache.hudi.client.utils.LazyIterableIterator` アブストラクトクラスを継承している。
`org.apache.hudi.client.utils.LazyIterableIterator` では、nextメソッドが

org/apache/hudi/client/utils/LazyIterableIterator.java:116

```java
  @Override
  public O next() {
    try {
      return computeNext();
    } catch (Exception ex) {
      throw new RuntimeException(ex);
    }
  }
```

のように定義されており、実態が `org.apache.hudi.client.utils.LazyIterableIterator#computeNext` であることがわかる。
当該メソッドは、 `org.apache.hudi.execution.CopyOnWriteLazyInsertIterable#CopyOnWriteLazyInsertIterable` クラスではオーバーライドされており、
以下のように定義されている。

org/apache/hudi/execution/CopyOnWriteLazyInsertIterable.java:93

```java
  @Override
  protected List<WriteStatus> computeNext() {
    // Executor service used for launching writer thread.
    BoundedInMemoryExecutor<HoodieRecord<T>, HoodieInsertValueGenResult<HoodieRecord>, List<WriteStatus>> bufferedIteratorExecutor =
        null;
    try {
      final Schema schema = new Schema.Parser().parse(hoodieConfig.getSchema());
      bufferedIteratorExecutor =
          new SparkBoundedInMemoryExecutor<>(hoodieConfig, inputItr, getInsertHandler(), getTransformFunction(schema));
      final List<WriteStatus> result = bufferedIteratorExecutor.execute();
      assert result != null && !result.isEmpty() && !bufferedIteratorExecutor.isRemaining();
      return result;
    } catch (Exception e) {
      throw new HoodieException(e);
    } finally {
      if (null != bufferedIteratorExecutor) {
        bufferedIteratorExecutor.shutdownNow();
      }
    }
  }
```

どうやら内部でFutureパターンを利用し、非同期化して書き込みを行っているようだ。（これが筋よしなのかどうかは要議論。update、つまりマージも同様になっている。）
処理内容を知る上でポイントとなるのは、

```java
      bufferedIteratorExecutor =
          new SparkBoundedInMemoryExecutor<>(hoodieConfig, inputItr, getInsertHandler(), getTransformFunction(schema));
```

の箇所。 `org.apache.hudi.execution.CopyOnWriteLazyInsertIterable#getInsertHandler` あたり。
中で用いられている、 `org.apache.hudi.execution.CopyOnWriteLazyInsertIterable.CopyOnWriteInsertHandler` クラスがポイントとなる。
このクラスは、書き込みデータのキュー（要確認）からレコードを受け取って、処理していると考えられる。

```java
    protected void consumeOneRecord(HoodieInsertValueGenResult<HoodieRecord> payload) {
      final HoodieRecord insertPayload = payload.record;
      // lazily initialize the handle, for the first time
      if (handle == null) {
        handle = new HoodieCreateHandle(hoodieConfig, commitTime, hoodieTable, insertPayload.getPartitionPath(),
            getNextFileId(idPrefix));
      }

      if (handle.canWrite(payload.record)) {
        // write the payload, if the handle has capacity
        handle.write(insertPayload, payload.insertValue, payload.exception);
      } else {
        // handle is full.
        statuses.add(handle.close());
        // Need to handle the rejected payload & open new handle
        handle = new HoodieCreateHandle(hoodieConfig, commitTime, hoodieTable, insertPayload.getPartitionPath(),
            getNextFileId(idPrefix));
        handle.write(insertPayload, payload.insertValue, payload.exception); // we should be able to write 1 payload.
      }
    }
```

下の方にある `org.apache.hudi.io.HoodieCreateHandle` クラスを用いているあたりがポイント。
そのwriteメソッドは以下の通り。
`org.apache.hudi.io.storage.HoodieStorageWriter#writeAvroWithMetadata` を用いて書き出しているように見える。
（実際には `org.apache.hudi.io.storage.HoodieParquetWriter` ）

```java
  public void write(HoodieRecord record, Option<IndexedRecord> avroRecord) {
    Option recordMetadata = record.getData().getMetadata();
    try {
      if (avroRecord.isPresent()) {
        // Convert GenericRecord to GenericRecord with hoodie commit metadata in schema
        IndexedRecord recordWithMetadataInSchema = rewriteRecord((GenericRecord) avroRecord.get());
        storageWriter.writeAvroWithMetadata(recordWithMetadataInSchema, record);
        // update the new location of record, so we know where to find it next
        record.unseal();
        record.setNewLocation(new HoodieRecordLocation(instantTime, writeStatus.getFileId()));
        record.seal();
        recordsWritten++;
        insertRecordsWritten++;
      } else {
        recordsDeleted++;
      }
      writeStatus.markSuccess(record, recordMetadata);
      // deflate record payload after recording success. This will help users access payload as a
      // part of marking
      // record successful.
      record.deflate();
    } catch (Throwable t) {
      // Not throwing exception from here, since we don't want to fail the entire job
      // for a single record
      writeStatus.markFailure(record, t, recordMetadata);
      LOG.error("Error writing record " + record, t);
    }
  }
```

`org.apache.hudi.io.storage.HoodieParquetWriter#writeAvroWithMetadata` メソッドは以下の通りである。
つまり、 `org.apache.parquet.hadoop.ParquetWriter#write` を用いてParquet内に、Avroレコードを書き出していることがわかる。

```java
  @Override
  public void writeAvroWithMetadata(R avroRecord, HoodieRecord record) throws IOException {
    String seqId =
        HoodieRecord.generateSequenceId(commitTime, TaskContext.getPartitionId(), recordIndex.getAndIncrement());
    HoodieAvroUtils.addHoodieKeyToRecord((GenericRecord) avroRecord, record.getRecordKey(), record.getPartitionPath(),
        file.getName());
    HoodieAvroUtils.addCommitMetadataToRecord((GenericRecord) avroRecord, commitTime, seqId);
    super.write(avroRecord);
    writeSupport.add(record.getRecordKey());
  }
```

今回のクイックスタートの例では、 `avroRecord` には以下のような内容が含まれていた。

```
result = {GenericData$Record@18566} "{"_hoodie_commit_time": "20200331002133", "_hoodie_commit_seqno": "20200331002133_0_44", "_hoodie_record_key": "7b887fb5-2837-4cac-b075-a8a8450f453d", "_hoodie_partition_path": "asia/india/chennai", "_hoodie_file_name": "317a54b0-70b8-4bdc-bfde-12ba4fde982b-0_0-207-301_20200331002133.parquet", "begin_lat": 0.4789745387904072, "begin_lon": 0.14781856144057215, "driver": "driver-022", "end_lat": 0.10509642405359532, "end_lon": 0.07682825311613706, "fare": 30.429177017810616, "partitionpath": "asia/india/chennai", "rider": "rider-022", "ts": 0.0, "uuid": "7b887fb5-2837-4cac-b075-a8a8450f453d"}"
 schema = {Schema$RecordSchema@18582} "{"type":"record","name":"hudi_trips_cow_record","namespace":"hoodie.hudi_trips_cow","fields":[{"name":"_hoodie_commit_time","type":["null","string"],"doc":"","default":null},{"name":"_hoodie_commit_seqno","type":["null","string"],"doc":"","default":null},{"name":"_hoodie_record_key","type":["null","string"],"doc":"","default":null},{"name":"_hoodie_partition_path","type":["null","string"],"doc":"","default":null},{"name":"_hoodie_file_name","type":["null","string"],"doc":"","default":null},{"name":"begin_lat","type":["double","null"]},{"name":"begin_lon","type":["double","null"]},{"name":"driver","type":["string","null"]},{"name":"end_lat","type":["double","null"]},{"name":"end_lon","type":["double","null"]},{"name":"fare","type":["double","null"]},{"name":"partitionpath","type":["string","null"]},{"name":"rider","type":["string","null"]},{"name":"ts","type":["double","null"]},{"name":"uuid","type":["string","null"]}]}"
 values = {Object[15]@18583} 
  0 = "20200331002133"
  1 = "20200331002133_0_44"
  2 = "7b887fb5-2837-4cac-b075-a8a8450f453d"
  3 = "asia/india/chennai"
  4 = "317a54b0-70b8-4bdc-bfde-12ba4fde982b-0_0-207-301_20200331002133.parquet"
  5 = {Double@18596} 0.4789745387904072
  6 = {Double@18597} 0.14781856144057215
  7 = {Utf8@18598} "driver-022"
  8 = {Double@18599} 0.10509642405359532
  9 = {Double@18600} 0.07682825311613706
  10 = {Double@18601} 30.429177017810616
  11 = {Utf8@18602} "asia/india/chennai"
  12 = {Utf8@18603} "rider-022"
  13 = {Double@18604} 0.0
  14 = {Utf8@18605} "7b887fb5-2837-4cac-b075-a8a8450f453d"
```

### org.apache.hudi.DefaultSource#createRelation（読み込み）

当該メソッドのポイントを確認する。

`hoodie.datasource.query.type` の種類によって返すRelationが変わる。

org/apache/hudi/DefaultSource.scala:60

```scala
    if (parameters(QUERY_TYPE_OPT_KEY).equals(QUERY_TYPE_SNAPSHOT_OPT_VAL)) {

    (snip)

    } else if (parameters(QUERY_TYPE_OPT_KEY).equals(QUERY_TYPE_INCREMENTAL_OPT_VAL)) {

    (snip)

    } else {
      throw new HoodieException("Invalid query type :" + parameters(QUERY_TYPE_OPT_KEY))
    }
```

上記の通り、 `snapshot` 、もしくは `incremental` クエリタイプである。
なお、以下の通り、 `MERGE_ON_READ` テーブルに対する `snapshot` クエリタイプは利用できない。
もし使いたければ、SparkのData Source機能ではなく、Hiveテーブルとして読み込むこと。

org/apache/hudi/DefaultSource.scala:69

```scala
      log.warn("Snapshot view not supported yet via data source, for MERGE_ON_READ tables. " +
        "Please query the Hive table registered using Spark SQL.")
```

まずクエリタイプが `snapshot` である場合は、
以下の通り、Parquetとして読み込みが定義され、Relationが返される。

org/apache/hudi/DefaultSource.scala:72

```scala
      DataSource.apply(
        sparkSession = sqlContext.sparkSession,
        userSpecifiedSchema = Option(schema),
        className = "parquet",
        options = parameters)
        .resolveRelation()
```

例えば、クイックスタートの例

```scala
scala> val tripsSnapshotDF = spark.
         read.
         format("hudi").
         load(basePath + "/*/*/*/*")
scala> tripsSnapshotDF.createOrReplaceTempView("hudi_trips_snapshot")
```

では、こちらのタイプ。
ParquetベースのRelation（実際には、HadoopFsRelation）が返される。
上記の例では、当該RelationのrootPathsに、以下のような値が含まれる。

```
rootPaths = {$colon$colon@14885} "::" size = 6
 0 = {Path@15421} "file:/tmp/hudi_trips_cow/americas/brazil/sao_paulo/ae28c85a-38f0-487f-a42d-3a0babc9d321-0_0-21-25_20200329002247.parquet"
 1 = {Path@15422} "file:/tmp/hudi_trips_cow/americas/brazil/sao_paulo/.hoodie_partition_metadata"
 2 = {Path@15423} "file:/tmp/hudi_trips_cow/americas/united_states/san_francisco/849db286-1cbe-4a1f-b544-9939893e99f8-0_1-21-26_20200329002247.parquet"
 3 = {Path@15424} "file:/tmp/hudi_trips_cow/americas/united_states/san_francisco/.hoodie_partition_metadata"
 4 = {Path@15425} "file:/tmp/hudi_trips_cow/asia/india/chennai/2ebfbab0-4f8f-42db-b79e-1c0cbcc3cf39-0_2-21-27_20200329002247.parquet"
 5 = {Path@15426} "file:/tmp/hudi_trips_cow/asia/india/chennai/.hoodie_partition_metadata"
```

次にクエリタイプが `incremental` である場合は、
以下の通り、 `org.apache.hudi.IncrementalRelation#IncrementalRelation` が返される。

org/apache/hudi/DefaultSource.scala:79

```scala
      new IncrementalRelation(sqlContext, path.get, optParams, schema)
```

クイックスタートの例

```scala
scala> val tripsIncrementalDF = spark.read.format("hudi").
         option(QUERY_TYPE_OPT_KEY, QUERY_TYPE_INCREMENTAL_OPT_VAL).
         option(BEGIN_INSTANTTIME_OPT_KEY, beginTime).
         load(basePath)
scala> tripsIncrementalDF.createOrReplaceTempView("hudi_trips_incremental")

scala> spark.sql("select `_hoodie_commit_time`, fare, begin_lon, begin_lat, ts from  hudi_trips_incremental where fare > 20.0").show()
```

では、 `org.apache.hudi.IncrementalRelation#IncrementalRelation` が戻り値として返される。

### IncrementalRelation

#### コンストラクタ

Parquetをファイルを単純に読めば良いのと比べて、格納された最新データを返すようにしないとならないので
それなりに複雑なRelationとなっている。

以下、簡単にコンストラクタのポイントを確認する。

最初にメタデータを取得するクライアント。
コミット、セーブポイント、コンパクションなどの情報を得られるようになる。

org/apache/hudi/IncrementalRelation.scala:51

```scala
  val metaClient = new HoodieTableMetaClient(sqlContext.sparkContext.hadoopConfiguration, basePath, true)
```

クイックスタートの例では、 `metaPath` は、 `file:/tmp/hudi_trips_cow/.hoodie` だった。

続いてテーブル情報のインスタンスを取得する。
テーブル情報からタイムラインを取り出す。

org/apache/hudi/IncrementalRelation.scala:57

```scala
  private val hoodieTable = HoodieTable.getHoodieTable(metaClient, HoodieWriteConfig.newBuilder().withPath(basePath).build(),
    sqlContext.sparkContext)
  val commitTimeline = hoodieTable.getMetaClient.getCommitTimeline.filterCompletedInstants()
  if (commitTimeline.empty()) {
    throw new HoodieException("No instants to incrementally pull")
  }
  if (!optParams.contains(DataSourceReadOptions.BEGIN_INSTANTTIME_OPT_KEY)) {
    throw new HoodieException(s"Specify the begin instant time to pull from using " +
      s"option ${DataSourceReadOptions.BEGIN_INSTANTTIME_OPT_KEY}")
  }
```

クイックスタートの例で実際に生成されたタイムラインは以下の通り。

```
instants = {ArrayList@25586}  size = 3
 0 = {HoodieInstant@25589} "[20200330002239__commit__COMPLETED]"
 1 = {HoodieInstant@25590} "[20200330002354__commit__COMPLETED]"
 2 = {HoodieInstant@25591} "[20200330003142__commit__COMPLETED]"
```

オプションとして与えられた「はじめ」と「おわり」から、
対象となるタイムラインを構成する。
タイムライン上、最も新しいインスタンスを取得し、
Parquetファイルからスキーマを読んでいる。

org/apache/hudi/IncrementalRelation.scala:68

```scala
  val lastInstant = commitTimeline.lastInstant().get()

  val commitsToReturn = commitTimeline.findInstantsInRange(
    optParams(DataSourceReadOptions.BEGIN_INSTANTTIME_OPT_KEY),
    optParams.getOrElse(DataSourceReadOptions.END_INSTANTTIME_OPT_KEY, lastInstant.getTimestamp))
    .getInstants.iterator().toList

  // use schema from a file produced in the latest instant
  val latestSchema = {
    // use last instant if instant range is empty
    val instant = commitsToReturn.lastOption.getOrElse(lastInstant)
    val latestMeta = HoodieCommitMetadata
          .fromBytes(commitTimeline.getInstantDetails(instant).get, classOf[HoodieCommitMetadata])
    val metaFilePath = latestMeta.getFileIdAndFullPaths(basePath).values().iterator().next()
    AvroConversionUtils.convertAvroSchemaToStructType(ParquetUtils.readAvroSchema(
      sqlContext.sparkContext.hadoopConfiguration, new Path(metaFilePath)))
  }
```

クイックスタートの例では、 `commitsToReturn` は以下の通り。

```
result = {$colon$colon@25626} "::" size = 1
 0 = {HoodieInstant@25591} "[20200330003142__commit__COMPLETED]"
  state = {HoodieInstant$State@25602} "COMPLETED"
  action = "commit"
  timestamp = "20200330003142"
```

また、少々気になるのは、

```scala
    AvroConversionUtils.convertAvroSchemaToStructType(ParquetUtils.readAvroSchema(
      sqlContext.sparkContext.hadoopConfiguration, new Path(metaFilePath)))
```

という箇所で、もともとParquet形式のデータからAvro形式のスキーマを取り出し、それをさらにSparkのStructTypeに変換しているところ。
実際にParquetのfooterから取り出したスキーマ情報を、AvroのSchemaに変換しているのは以下の箇所。

org/apache/hudi/common/util/ParquetUtils.java:140

```scala
  public static Schema readAvroSchema(Configuration configuration, Path parquetFilePath) {
    return new AvroSchemaConverter().convert(readSchema(configuration, parquetFilePath));
  }
```

- Parquet自身にAvroへの変換器 `org.apache.parquet.avro.AvroSchemaConverter` が備わっているので便利？
- SparkのData Source機能でDataFrame化してからスキーマを取り出すと、一度読み込みが生じていしまうから非効率？

という理由が想像されるが、やや回りくどいような印象を持った。 ★要確認

本編に戻る。続いてフィルタを定義。

org/apache/hudi/IncrementalRelation.scala:86

```scala
  val filters = {
    if (optParams.contains(DataSourceReadOptions.PUSH_DOWN_INCR_FILTERS_OPT_KEY)) {
      val filterStr = optParams.getOrElse(
        DataSourceReadOptions.PUSH_DOWN_INCR_FILTERS_OPT_KEY,
        DataSourceReadOptions.DEFAULT_PUSH_DOWN_FILTERS_OPT_VAL)
      filterStr.split(",").filter(!_.isEmpty)
    } else {
      Array[String]()
    }
  }
```

ここまでがコンストラクタ。

#### buildScan

実際にSparkのData Sourceで読み込むときに用いられる読み込みの手段が定義されている。
以下にポイントを述べる。

org/apache/hudi/IncrementalRelation.scala:99

```scala
  override def buildScan(): RDD[Row] = {

  (snip)
```

ファイルIDとフルPATHのマップを作る。

```scala
    val fileIdToFullPath = mutable.HashMap[String, String]()
    for (commit <- commitsToReturn) {
      val metadata: HoodieCommitMetadata = HoodieCommitMetadata.fromBytes(commitTimeline.getInstantDetails(commit)
        .get, classOf[HoodieCommitMetadata])
      fileIdToFullPath ++= metadata.getFileIdAndFullPaths(basePath).toMap
    }
```

上記マップに対し、必要に応じてフィルタを適用する。

org/apache/hudi/IncrementalRelation.scala:106

```scala
    val pathGlobPattern = optParams.getOrElse(
      DataSourceReadOptions.INCR_PATH_GLOB_OPT_KEY,
      DataSourceReadOptions.DEFAULT_INCR_PATH_GLOB_OPT_VAL)
    val filteredFullPath = if(!pathGlobPattern.equals(DataSourceReadOptions.DEFAULT_INCR_PATH_GLOB_OPT_VAL)) {
      val globMatcher = new GlobPattern("*" + pathGlobPattern)
      fileIdToFullPath.filter(p => globMatcher.matches(p._2))
    } else {
      fileIdToFullPath
    }
```

コンストラクタで定義されたフィルタを適用しながら、
対象となるParquetファイルを読み込み、RDDを生成する。

org/apache/hudi/IncrementalRelation.scala:117

```scala
    sqlContext.sparkContext.hadoopConfiguration.unset("mapreduce.input.pathFilter.class")
    val sOpts = optParams.filter(p => !p._1.equalsIgnoreCase("path"))
    if (filteredFullPath.isEmpty) {
      sqlContext.sparkContext.emptyRDD[Row]
    } else {
      log.info("Additional Filters to be applied to incremental source are :" + filters)
      filters.foldLeft(sqlContext.read.options(sOpts)
        .schema(latestSchema)
        .parquet(filteredFullPath.values.toList: _*)
        .filter(String.format("%s >= '%s'", HoodieRecord.COMMIT_TIME_METADATA_FIELD, commitsToReturn.head.getTimestamp))
        .filter(String.format("%s <= '%s'",
          HoodieRecord.COMMIT_TIME_METADATA_FIELD, commitsToReturn.last.getTimestamp)))((e, f) => e.filter(f))
        .toDF().rdd
    }
```

# Hudiへの書き込み

[Writing Hudi Tables] をベースに調べる。

## オペレーション種類

書き込みのオペレーション種類は、upsert、insert、bulk_insert。
クイックスタートにはbulk_insertはなかった。

## DeltaStreamer

ユーティリティとして付属するDeltaStreamerを用いると、
Kafka等からデータを取り込める。
Avro等のスキーマのデータを読み取れる。

### 動作確認

#### パッケージ化

[公式ドキュメントのData Streamer] の手順に基づくと、
ビルドされたユーティリティを使うことになるので、
予めパッケージ化しておく。

```shell
$ mkdir -p ~/Sources
$ cd ~/Sources
$ git clone https://github.com/apache/incubator-hudi.git incubator-hudi-052
$ cd incubator-hudi-052
$ git checkout -b release-0.5.2-incubating refs/tags/release-0.5.2-incubating
$ mvn clean package -DskipTests -DskipITs
```

#### 実行

[公式ドキュメントのData Streamer]に基づくと、Confluentメンバが作成した
（ [apurvam streams-prototyping] ）サンプルデータ作成用のAvroスキーマと
Confluent PlatformのKSQLのユーティリティを
使ってサンプルデータを作成する。

ついては。予めConfluent Platformをインストールしておくこと。

まずはスキーマをダウンロードする。

```shell
$ curl https://raw.githubusercontent.com/apurvam/streams-prototyping/master/src/main/resources/impressions.avro > /tmp/impressions.avro
```

テストデータを生成する。

```shell
$ ksql-datagen schema=/tmp/impressions.avro format=avro topic=impressions key=impressionid
```

別の端末を開き、ユーティリティを起動する。

```shell
$ export SPARK_HOME=/opt/spark/default
$ cd ~/Sources/incubator-hudi-052
$ ${SPARK_HOME}/bin/spark-submit --class org.apache.hudi.utilities.deltastreamer.HoodieDeltaStreamer packaging/hudi-utilities-bundle/target/hudi-utilities-bundle_2.11-0.5.2-incubating.jar \
  --props file://${PWD}/hudi-utilities/src/test/resources/delta-streamer-config/kafka-source.properties \
  --schemaprovider-class org.apache.hudi.utilities.schema.SchemaRegistryProvider \
  --source-class org.apache.hudi.utilities.sources.AvroKafkaSource \
  --source-ordering-field impresssiontime \
  --target-base-path file:\/\/\/tmp/hudi-deltastreamer-op \
  --target-table uber.impressions \
  --table-type COPY_ON_WRITE \
  --op BULK_INSERT
```

なお、 [公式ドキュメントのData Streamer] から2箇所修正した。（JarファイルPATH、 `--table-type` オプション追加。

Kafkaから読み込んで書き出したデータ（ `/tmp/hudi-deltastreamer-op` ）を確認してみる。

```shell
$ ${SPARK_HOME}/bin/spark-shell \
  --packages org.apache.hudi:hudi-spark-bundle_2.11:0.5.2-incubating,org.apache.spark:spark-avro_2.11:2.4.5 \
  --conf 'spark.serializer=org.apache.spark.serializer.KryoSerializer'
```

シェルが起動したら、以下の通り読み込んで見る。
なお、ここでは `userid` がパーティションキーとなっているので、ロード時にそれを指定した。

```scala
scala> val basePath = "file:///tmp/hudi-deltastreamer-op"
scala> val impressionDF = spark.
         read.
         format("hudi").
         load(basePath + "/*/*")
```

内容は以下の通り。

```scala
scala> impressionDF.show
+-------------------+--------------------+------------------+----------------------+--------------------+---------------+--------------+-------+-----+
|_hoodie_commit_time|_hoodie_commit_seqno|_hoodie_record_key|_hoodie_partition_path|   _hoodie_file_name|impresssiontime|  impressionid| userid| adid|
+-------------------+--------------------+------------------+----------------------+--------------------+---------------+--------------+-------+-----+
|     20200406002420|20200406002420_1_...|    impression_106|               user_83|fb381e12-f9ec-4fb...|  1586096500438|impression_106|user_83|ad_57|
|     20200406002420|20200406002420_1_...|    impression_107|               user_83|fb381e12-f9ec-4fb...|  1586096464324|impression_107|user_83|ad_11|
|     20200406002420|20200406002420_1_...|    impression_111|               user_83|fb381e12-f9ec-4fb...|  1586096366450|impression_111|user_83|ad_14|
|     20200406002420|20200406002420_1_...|    impression_111|               user_83|fb381e12-f9ec-4fb...|  1586099019181|impression_111|user_83|ad_38|
|     20200406002420|20200406002420_1_...|    impression_116|               user_83|fb381e12-f9ec-4fb...|  1586099146437|impression_116|user_83|ad_48|
|     20200406002420|20200406002420_1_...|    impression_121|               user_83|fb381e12-f9ec-4fb...|  1586098316334|impression_121|user_83|ad_26|

(snip)
```

### 実装確認

`org.apache.hudi.utilities.deltastreamer.HoodieDeltaStreamer` クラスの実装を確認する。

まずmainは以下の通り。

org/apache/hudi/utilities/deltastreamer/HoodieDeltaStreamer.java:298

```java
  public static void main(String[] args) throws Exception {
    final Config cfg = new Config();
    JCommander cmd = new JCommander(cfg, null, args);
    if (cfg.help || args.length == 0) {
      cmd.usage();
      System.exit(1);
    }

    Map<String, String> additionalSparkConfigs = SchedulerConfGenerator.getSparkSchedulingConfigs(cfg);
    JavaSparkContext jssc =
        UtilHelpers.buildSparkContext("delta-streamer-" + cfg.targetTableName, cfg.sparkMaster, additionalSparkConfigs);
    try {
      new HoodieDeltaStreamer(cfg, jssc).sync();
    } finally {
      jssc.stop();
    }
  }
```

上記の通り、 `org.apache.hudi.utilities.deltastreamer.HoodieDeltaStreamer#sync` メソッドがエントリポイント。

org/apache/hudi/utilities/deltastreamer/HoodieDeltaStreamer.java:116

```java
  public void sync() throws Exception {
    if (cfg.continuousMode) {
      deltaSyncService.start(this::onDeltaSyncShutdown);
      deltaSyncService.waitForShutdown();
      LOG.info("Delta Sync shutting down");
    } else {
      LOG.info("Delta Streamer running only single round");
      try {
        deltaSyncService.getDeltaSync().syncOnce();
      } catch (Exception ex) {
        LOG.error("Got error running delta sync once. Shutting down", ex);
        throw ex;
      } finally {
        deltaSyncService.close();
        LOG.info("Shut down delta streamer");
      }
    }
  }
```

上記の通り、 `continous` モードかどうかで動作が変わる。

ここでは一旦、ワンショットの場合を確認する。

上記の通り、 `org.apache.hudi.utilities.deltastreamer.DeltaSync#syncOnce` メソッドがエントリポイント。
当該メソッドは以下のようにシンプルな内容。

org/apache/hudi/utilities/deltastreamer/DeltaSync.java:218

```java
  public Option<String> syncOnce() throws Exception {
    Option<String> scheduledCompaction = Option.empty();
    HoodieDeltaStreamerMetrics metrics = new HoodieDeltaStreamerMetrics(getHoodieClientConfig(schemaProvider));
    Timer.Context overallTimerContext = metrics.getOverallTimerContext();

    // Refresh Timeline
    refreshTimeline();

    Pair<SchemaProvider, Pair<String, JavaRDD<HoodieRecord>>> srcRecordsWithCkpt = readFromSource(commitTimelineOpt);

    if (null != srcRecordsWithCkpt) {
      // this is the first input batch. If schemaProvider not set, use it and register Avro Schema and start
      // compactor
      if (null == schemaProvider) {
        // Set the schemaProvider if not user-provided
        this.schemaProvider = srcRecordsWithCkpt.getKey();
        // Setup HoodieWriteClient and compaction now that we decided on schema
        setupWriteClient();
      }

      scheduledCompaction = writeToSink(srcRecordsWithCkpt.getRight().getRight(),
          srcRecordsWithCkpt.getRight().getLeft(), metrics, overallTimerContext);
    }

    // Clear persistent RDDs
    jssc.getPersistentRDDs().values().forEach(JavaRDD::unpersist);
    return scheduledCompaction;
  }
```

最初にメトリクスの準備、データソースから読み出してRDD化する定義（ `org.apache.hudi.utilities.deltastreamer.DeltaSync#readFromSource` メソッド）
その後、 `org.apache.hudi.utilities.deltastreamer.DeltaSync#writeToSink` メソッドにより、定義されたRDDの内容を実際に書き込む。

ここでは上記メソッドを確認する。

まず与えられたRDDから重複排除する。

org/apache/hudi/utilities/deltastreamer/DeltaSync.java:352

```java
  private Option<String> writeToSink(JavaRDD<HoodieRecord> records, String checkpointStr,
                                     HoodieDeltaStreamerMetrics metrics, Timer.Context overallTimerContext) throws Exception {

    Option<String> scheduledCompactionInstant = Option.empty();
    // filter dupes if needed
    if (cfg.filterDupes) {
      // turn upserts to insert
      cfg.operation = cfg.operation == Operation.UPSERT ? Operation.INSERT : cfg.operation;
      records = DataSourceUtils.dropDuplicates(jssc, records, writeClient.getConfig());
    }

    boolean isEmpty = records.isEmpty();

(snip)
```

その後実際の書き込みになるが、そのとき採用したオペレーション種類によって動作が異なる。

org/apache/hudi/utilities/deltastreamer/DeltaSync.java:369

```java
    if (cfg.operation == Operation.INSERT) {
      writeStatusRDD = writeClient.insert(records, instantTime);
    } else if (cfg.operation == Operation.UPSERT) {
      writeStatusRDD = writeClient.upsert(records, instantTime);
    } else if (cfg.operation == Operation.BULK_INSERT) {
      writeStatusRDD = writeClient.bulkInsert(records, instantTime);
    } else {
      throw new HoodieDeltaStreamerException("Unknown operation :" + cfg.operation);
    }
```

#### bulkInsert

ここではためしに `org.apache.hudi.client.HoodieWriteClient#bulkInsert` メソッドを確認してみる。

当該メソッドでは、最初にCOPY_ON_WRITEかMERGE_ON_READかに応じて、それぞれの種類のテーブル情報を取得する。
その後、 `org.apache.hudi.client.HoodieWriteClient#bulkInsertInternal` メソッドを使ってデータを書き込む。

なお、その間で重複排除されているが、上記の通り、もともと重複排除しているはずなので、要確認。（重複排除のロジックが異なるのかどうか、など）
パット見た感じ、 `org.apache.hudi.DataSourceUtils#dropDuplicates` メソッドはロケーション情報（インデックス？）がない場合をドロップする。
`org.apache.hudi.client.HoodieWriteClient#combineOnCondition` メソッドはキーに基づきreduce処理する。
という違いがあるようだ。

org/apache/hudi/client/HoodieWriteClient.java:300

```java
  public JavaRDD<WriteStatus> bulkInsert(JavaRDD<HoodieRecord<T>> records, final String instantTime,
      Option<UserDefinedBulkInsertPartitioner> bulkInsertPartitioner) {
    HoodieTable<T> table = getTableAndInitCtx(WriteOperationType.BULK_INSERT);
    setOperationType(WriteOperationType.BULK_INSERT);
    try {
      // De-dupe/merge if needed
      JavaRDD<HoodieRecord<T>> dedupedRecords =
          combineOnCondition(config.shouldCombineBeforeInsert(), records, config.getInsertShuffleParallelism());

      return bulkInsertInternal(dedupedRecords, instantTime, table, bulkInsertPartitioner);
    } catch (Throwable e) {
      if (e instanceof HoodieInsertException) {
        throw e;
      }
      throw new HoodieInsertException("Failed to bulk insert for commit time " + instantTime, e);
    }
  }
```

上記の通り、 `org.apache.hudi.client.HoodieWriteClient#bulkInsertInternal` メソッドが中で用いられている。
当該メソッドでは、再パーティションないしソートが行われた後、書き込みが実行される。

org/apache/hudi/client/HoodieWriteClient.java:412

```java
    JavaRDD<WriteStatus> writeStatusRDD = repartitionedRecords
        .mapPartitionsWithIndex(new BulkInsertMapFunction<T>(instantTime, config, table, fileIDPrefixes), true)
        .flatMap(List::iterator);
```

ポイントは、`org.apache.hudi.execution.BulkInsertMapFunction` クラスである。
このクラスが関数として渡されている。
`org.apache.hudi.execution.BulkInsertMapFunction#call` メソッドは以下の通り。

org/apache/hudi/execution/BulkInsertMapFunction.java:52

```java
  public Iterator<List<WriteStatus>> call(Integer partition, Iterator<HoodieRecord<T>> sortedRecordItr) {
    return new CopyOnWriteLazyInsertIterable<>(sortedRecordItr, config, instantTime, hoodieTable,
        fileIDPrefixes.get(partition), hoodieTable.getSparkTaskContextSupplier());
  }
```

`org.apache.hudi.execution.CopyOnWriteLazyInsertIterable` クラスについては、別の節で書いたとおり。

#### insert

`org.apache.hudi.client.HoodieWriteClient#insert` メソッド。

大まかな構造は、 `bulkInsert` と同様。
ポイントは、 `org.apache.hudi.client.HoodieWriteClient#upsertRecordsInternal` メソッド。

org/apache/hudi/client/HoodieWriteClient.java:229

```java
  public JavaRDD<WriteStatus> insert(JavaRDD<HoodieRecord<T>> records, final String instantTime) {
    HoodieTable<T> table = getTableAndInitCtx(WriteOperationType.INSERT);
    setOperationType(WriteOperationType.INSERT);
    try {
      // De-dupe/merge if needed
      JavaRDD<HoodieRecord<T>> dedupedRecords =
          combineOnCondition(config.shouldCombineBeforeInsert(), records, config.getInsertShuffleParallelism());

      return upsertRecordsInternal(dedupedRecords, instantTime, table, false);
    } catch (Throwable e) {
      if (e instanceof HoodieInsertException) {
        throw e;
      }
      throw new HoodieInsertException("Failed to insert for commit time " + instantTime, e);
    }
  }
```

上記の通り、挿入対象のデータを表すRDDを引数に取り、データを書き込む。
これは、upsertのときと同じメソッドである。第4引数でinsertかupsertかを分ける。

当該メソッドは以下の通り。
`bulkInsert` と同様にリパーティションなどを経て、 `org.apache.hudi.table.HoodieTable#handleUpsertPartition` が呼び出される。

org/apache/hudi/client/HoodieWriteClient.java:457

```java
  private JavaRDD<WriteStatus> upsertRecordsInternal(JavaRDD<HoodieRecord<T>> preppedRecords, String instantTime,
      HoodieTable<T> hoodieTable, final boolean isUpsert) {

(snip)

    JavaRDD<WriteStatus> writeStatusRDD = partitionedRecords.mapPartitionsWithIndex((partition, recordItr) -> {
      if (isUpsert) {
        return hoodieTable.handleUpsertPartition(instantTime, partition, recordItr, partitioner);
      } else {
        return hoodieTable.handleInsertPartition(instantTime, partition, recordItr, partitioner);
      }
    }, true).flatMap(List::iterator);

(snip)
```

`org.apache.hudi.table.HoodieTable#handleUpsertPartition` と `org.apache.hudi.table.HoodieTable#handleInsertPartition` が用いられている。
今回は、insertなので後者。

なお、 `org.apache.hudi.table.HoodieCopyOnWriteTable#handleInsertPartition` は以下の通り、実態としては
`org.apache.hudi.table.HoodieCopyOnWriteTable#handleUpsertPartition` である。


```java
  public Iterator<List<WriteStatus>> handleInsertPartition(String instantTime, Integer partition, Iterator recordItr,
                                                           Partitioner partitioner) {
    return handleUpsertPartition(instantTime, partition, recordItr, partitioner);
  }
```

当該メソッドは以下の通り。
insertやupsertでは、RDDひとつを1バケットと表現している。
バケットの情報から、insertやupdateの情報を取得して用いる。

```java
  public Iterator<List<WriteStatus>> handleUpsertPartition(String instantTime, Integer partition, Iterator recordItr,
                                                           Partitioner partitioner) {
    UpsertPartitioner upsertPartitioner = (UpsertPartitioner) partitioner;
    BucketInfo binfo = upsertPartitioner.getBucketInfo(partition);
    BucketType btype = binfo.bucketType;
    try {
      if (btype.equals(BucketType.INSERT)) {
        return handleInsert(instantTime, binfo.fileIdPrefix, recordItr);
      } else if (btype.equals(BucketType.UPDATE)) {
        return handleUpdate(instantTime, binfo.partitionPath, binfo.fileIdPrefix, recordItr);
      } else {
        throw new HoodieUpsertException("Unknown bucketType " + btype + " for partition :" + partition);
      }
    } catch (Throwable t) {
      String msg = "Error upserting bucketType " + btype + " for partition :" + partition;
      LOG.error(msg, t);
      throw new HoodieUpsertException(msg, t);
    }
  }
```

例えば、insertの場合は、 `org.apache.hudi.table.HoodieCopyOnWriteTable#handleInsert` が呼び出される。
当該メソッドでは、戻り値として `org.apache.hudi.execution.CopyOnWriteLazyInsertIterable#CopyOnWriteLazyInsertIterable` が返される。

org/apache/hudi/table/HoodieCopyOnWriteTable.java:186

```java
  public Iterator<List<WriteStatus>> handleInsert(String instantTime, String idPfx, Iterator<HoodieRecord<T>> recordItr)
      throws Exception {
    // This is needed since sometimes some buckets are never picked in getPartition() and end up with 0 records
    if (!recordItr.hasNext()) {
      LOG.info("Empty partition");
      return Collections.singletonList((List<WriteStatus>) Collections.EMPTY_LIST).iterator();
    }
    return new CopyOnWriteLazyInsertIterable<>(recordItr, config, instantTime, this, idPfx, sparkTaskContextSupplier);
  }
```

このメソッドについては上記ですでに説明したとおり。

#### HoodieCopyOnWriteTable と HoodieMergeOnReadTable

テーブルの種類によって、書き込みの実装上どういう違いがあるかを確認する。

例えば、`handleInsert` メソッドを確認する。なお、当該メソッドには同期的、非同期的な処理方式がそれぞれ実装されている。

HoodieCopyOnWriteTableの場合は以下の通り。

org/apache/hudi/table/HoodieCopyOnWriteTable.java:186

```java
  public Iterator<List<WriteStatus>> handleInsert(String instantTime, String idPfx, Iterator<HoodieRecord<T>> recordItr)
      throws Exception {
    // This is needed since sometimes some buckets are never picked in getPartition() and end up with 0 records
    if (!recordItr.hasNext()) {
      LOG.info("Empty partition");
      return Collections.singletonList((List<WriteStatus>) Collections.EMPTY_LIST).iterator();
    }
    return new CopyOnWriteLazyInsertIterable<>(recordItr, config, instantTime, this, idPfx, sparkTaskContextSupplier);
  }

  public Iterator<List<WriteStatus>> handleInsert(String instantTime, String partitionPath, String fileId,
      Iterator<HoodieRecord<T>> recordItr) {
    HoodieCreateHandle createHandle =
        new HoodieCreateHandle(config, instantTime, this, partitionPath, fileId, recordItr, sparkTaskContextSupplier);
    createHandle.write();
    return Collections.singletonList(Collections.singletonList(createHandle.close())).iterator();
  }
```

上が非同期的な方式、下が同期的な方式と見られる。
なお、実装上は同期的な処理方式は今は使われていないようにもみえるが、要確認。

HoodieMergeOnReadTableの場合は、非同期的な処理だけoverrideされている。

org/apache/hudi/table/HoodieMergeOnReadTable.java:120

```java
  public Iterator<List<WriteStatus>> handleInsert(String instantTime, String idPfx, Iterator<HoodieRecord<T>> recordItr)
      throws Exception {
    // If canIndexLogFiles, write inserts to log files else write inserts to parquet files
    if (index.canIndexLogFiles()) {
      return new MergeOnReadLazyInsertIterable<>(recordItr, config, instantTime, this, idPfx, sparkTaskContextSupplier);
    } else {
      return super.handleInsert(instantTime, idPfx, recordItr);
    }
  }
```

<!-- vim: set et tw=0 ts=2 sw=2: -->
