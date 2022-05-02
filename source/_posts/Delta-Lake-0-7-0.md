---

title: Delta Lake 0.7.0
date: 2020-06-19 09:46:13
categories:
  - Knowledge Management
  - Storage Layer
  - Delta Lake
tags:
  - Delta Lake

---

# 参考

* [Delta Lake リリースノート]
* [0.7.0のテーブル読み書き]
* [0.6.1のテーブル読み書き]
* [Spark3系でないとHiveメタストアに対応できない理由]
* [SQLを用いたマージの例]
* [Table Properties]
* [Table Properties]
* [0.7.0で対応したAzure Data Lake Storage Gen2]

[Delta Lake リリースノート]: https://github.com/delta-io/delta/releases
[0.7.0のテーブル読み書き]: https://docs.delta.io/0.7.0/delta-batch.html
[0.6.1のテーブル読み書き]: https://docs.delta.io/0.6.1/delta-batch.html
[Spark3系でないとHiveメタストアに対応できない理由]: https://github.com/delta-io/delta/issues/307#issuecomment-582186407
[SQLを用いたマージの例]: https://github.com/delta-io/delta/blob/master/examples/scala/src/main/scala/example/QuickstartSQL.scala#L58
[Table Properties]: https://docs.delta.io/0.7.0/delta-batch.html#table-properties
[0.7.0で対応したAzure Data Lake Storage Gen2]: https://docs.delta.io/0.7.0/delta-storage.html#azure-data-lake-storage-gen2

# メモ

0.7.0が出たので、本リリースの特徴を確認する。


## SQL DDLへの対応やHive メタストアの対応

0.6系まではScala、Python APIのみであったが、SQL DDLにも対応した。
[0.7.0のテーブル読み書き] と [0.6.1のテーブル読み書き] を見比べると、SQLの例が載っていることがわかる。
対応するSQL構文については `src/main/antlr4/io/delta/sql/parser/DeltaSqlBase.g4` あたりを見ると良い。

なお、 [Spark3系でないとHiveメタストアに対応できない理由] を見る限り、
Spark3系のAPI（や、DataSourceV2も、かな）を使わないと、Data SourceのカスタムAPIを利用できないため、
これまでHiveメタストアのような外部メタストアと連携したDelta Lakeのメタデータ管理ができなかった、とのこと。

なお、今回の対応でSparkのカタログ機能を利用することになったので、起動時もしくはSparkSession生成時の
オプション指定が必要になった。
その代わり、ライブラリの明示的なインポートが不要であり、クエリはDelta Lakeのパーサで解釈された後、
解釈できないようであれば通常のパーサで処理されるようになる。


### 起動時のオプション例

例：

```shell
$ /opt/spark/default/bin/spark-shell --packages io.delta:delta-core_2.12:0.7.0 --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
```

なお、ここでは `SparkSessionExtensions` を利用し、SparkSession生成時にカスタムルール等を挿入している。
この機能は2020/06/19時点でSpark本体側でExperimentalであることに注意。
今後もSpark本体側の仕様変更に引きずられる可能性はある。

### パーサの呼び出し流れ

セッション拡張機能を利用し、パーサが差し替えられている。

io/delta/sql/DeltaSparkSessionExtension.scala:73

```scala
class DeltaSparkSessionExtension extends (SparkSessionExtensions => Unit) {
  override def apply(extensions: SparkSessionExtensions): Unit = {
    extensions.injectParser { (session, parser) =>
      new DeltaSqlParser(parser)
    }

(snip)
```
`io.delta.sql.parser.DeltaSqlParser` クラスでは
デリゲート用のパーサを受け取り、自身のパーサで処理できなかった場合に処理をデリゲートパーサに渡す。

io/delta/sql/parser/DeltaSqlParser.scala:66

```scala
class DeltaSqlParser(val delegate: ParserInterface) extends ParserInterface {
  private val builder = new DeltaSqlAstBuilder

(snip)
```

例えば、 `SparkSession` の `sql` メソッドを使って呼び出す場合を例にする。
このとき、内部では、 `org.apache.spark.sql.catalyst.parser.ParserInterface#parsePlan` メソッドが呼ばれて、
渡されたクエリ文 `sqlText` が処理される。

org/apache/spark/sql/SparkSession.scala:601

```scala
  def sql(sqlText: String): DataFrame = withActive {
    val tracker = new QueryPlanningTracker
    val plan = tracker.measurePhase(QueryPlanningTracker.PARSING) {
      sessionState.sqlParser.parsePlan(sqlText)
    }
    Dataset.ofRows(self, plan, tracker)
  }
```

この `parsePlan` がoverrideされており、以下のように定義されている。


io/delta/sql/parser/DeltaSqlParser.scala:69

```scala
  override def parsePlan(sqlText: String): LogicalPlan = parse(sqlText) { parser =>
    builder.visit(parser.singleStatement()) match {
      case plan: LogicalPlan => plan
      case _ => delegate.parsePlan(sqlText)
    }
  }
```

まずは `io.delta.sql.parser.DeltaSqlParser#parse` メソッドを利用してパースがここ見られるが、
LogicalPlanが戻らなかったときは、デリゲート用パーサが呼び出されるようになっている。

### カスタムカタログ

Spark3ではDataSourvV2の中で、プラガブルなカタログに対応した。
Delta Lake 0.7.0はこれを利用し、カスタムカタログを用いる。（これにより、Hiveメタストアを経由してDelta Lake形式のデータを読み書きできるようになっている）
使われているカタログは `org.apache.spark.sql.delta.catalog.DeltaCatalog` である。
（SparkSessionのインスタンス生成する際、もしくは起動時のオプション指定）

当該カタログ内部では、例えば `org.apache.spark.sql.delta.catalog.DeltaCatalog#createDeltaTable` メソッドが定義されており、
`org.apache.spark.sql.delta.catalog.DeltaCatalog#createTable` ※ しようとするときなどに呼び出されるようになっている。

※ `org.apache.spark.sql.connector.catalog.DelegatingCatalogExtension#createTable` をoverrideしている


なお、このクラスもデリゲート用のカタログを用いるようになっている。
`org.apache.spark.sql.delta.catalog.DeltaCatalog#createTable` メソッドは以下のようになっており、
データソースが delta 出ない場合は、親クラスの `createTable` （つまり標準的なもの）が呼び出されるようになっている。

org/apache/spark/sql/delta/catalog/DeltaCatalog.scala:149

```scala
  override def createTable(
      ident: Identifier,
      schema: StructType,
      partitions: Array[Transform],
      properties: util.Map[String, String]): Table = {
    if (DeltaSourceUtils.isDeltaDataSourceName(getProvider(properties))) {
      createDeltaTable(
        ident, schema, partitions, properties, sourceQuery = None, TableCreationModes.Create)
    } else {
      super.createTable(ident, schema, partitions, properties)
    }
  }
```

### ScalaやPythonでの例


代表的にScalaの例を出す。公式サイトには以下のように載っている。

```scala
df.write.format("delta").saveAsTable("events")      // create table in the metastore

df.write.format("delta").save("/delta/events")  // create table by path
```

Hiveメタストア経由で書き込むケースと、ストレージ上に直接書き出すケースが載っている。


### SQLでのマージ処理

[SQLを用いたマージの例] の通り、Delta Lakeの特徴であるマージ機能もSQLから呼び出させる。

```scala
      spark.sql(s"""MERGE INTO $tableName USING newData
          ON ${tableName}.id = newData.id
          WHEN MATCHED THEN
            UPDATE SET ${tableName}.id = newData.id
          WHEN NOT MATCHED THEN INSERT *
      """)
```

Spark SQLのカタログに登録されたDelta LakeのテーブルからDeltaTableを生成することもできる。

```scala
scala> import io.delta.tables.DeltaTable
scala> val tbl = DeltaTable.forName(tableName)
```

## Presto / Athena用のメタデータの自動生成

Delta LakeはPresto、Athena用のメタデータを生成できるが、更新があった際にパーティションごとに自動で再生成できるようになった。

## テーブル履歴の切り詰めの管理

Delta Lakeは更新の履歴を保持することも特徴の一つだが、
データ本体とログのそれぞれの切り詰め対象期間を指定できる。

CREATEやALTER句内で、TBLPROPERTIESとして指定することになっている。
例えば以下。

```scala
spark.sql(s"CREATE TABLE $tableName(id LONG) USING delta TBLPROPERTIES ('delta.logRetentionDuration' = 'interval 1 day', 'delta.deletedFileRetentionDuration' = 'interval 1 day')")
spark.sql(s"ALTER TABLE $tableName SET TBLPROPERTIES ('delta.logRetentionDuration' = 'interval 1 day', 'delta.deletedFileRetentionDuration' = 'interval 1 day')")
```

## ユーザメタデータ

spark.databricks.delta.commitInfo.userMetadata プロパティを利用して、ユーザメタデータを付与できる。

```scala
df.write.option("spark.databricks.delta.commitInfo.userMetadata", "test").format("delta").mode("append").save("/tmp/test")
```

```scala
scala> spark.sql("SET spark.databricks.delta.commitInfo.userMetadata=test")
scala> spark.sql(s"INSERT INTO $tableName VALUES 0, 1, 2, 3, 4")
```

## AzureのData Lake Storage Gen2

対応した。

しかし、 [0.7.0で対応したAzure Data Lake Storage Gen2] の通り、
前提となっている各種ソフトウェアバージョンは高め。

## ストリーム処理のone-timeトリガの改善

DataStreamReaderのオプションでmaxFilesPerTriggerを設定しているとしても、
one-time triggerでは一度に溜まったすべてのデータを読み込むようになった。（Spark 3系の話）

<!-- vim: set et tw=0 ts=2 sw=2: -->
