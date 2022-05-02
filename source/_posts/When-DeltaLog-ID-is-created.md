---

title: When DeltaLog ID is created
date: 2021-04-04 00:13:19
categories:
  - Knowledge Management
  - Storage Layer
  - Delta Lake
tags:
  - Delta Lake

---

# 参考


# メモ

Delta LakeのDelta LogのIDがいつ確定するのか、というのが気になり確認した。

## 前提

* Delta Lakeバージョン：0.8.0

## createRelationから確認する

`org.apache.spark.sql.delta.sources.DeltaDataSource#createRelation` をエントリポイントとする。

ポイントは、`DeltaLog` がインスタンス化されるときである。

まず最初にインスタンス化されるのは以下。

org/apache/spark/sql/delta/sources/DeltaDataSource.scala:141

```scala
    val deltaLog = DeltaLog.forTable(sqlContext.sparkSession, path)
```

`org.apache.spark.sql.delta.DeltaLog` は、 `org.apache.spark.sql.delta.SnapshotManagement` トレイトをミックスインしている。
当該トレイトには、 `currentSnapshot` というメンバ変数があり、これは `org.apache.spark.sql.delta.SnapshotManagement#getSnapshotAtInit` メソッドを利用し得られる。

org/apache/spark/sql/delta/SnapshotManagement.scala:47

```scala
  @volatile protected var currentSnapshot: Snapshot = getSnapshotAtInit
```

このメソッドは以下のように定義されている。

org/apache/spark/sql/delta/SnapshotManagement.scala:184

```scala
  protected def getSnapshotAtInit: Snapshot = {
    try {
      val segment = getLogSegmentFrom(lastCheckpoint)
      val startCheckpoint = segment.checkpointVersion
        .map(v => s" starting from checkpoint $v.").getOrElse(".")
      logInfo(s"Loading version ${segment.version}$startCheckpoint")
      val snapshot = createSnapshot(
        segment,
        minFileRetentionTimestamp,
        segment.lastCommitTimestamp)

      lastUpdateTimestamp = clock.getTimeMillis()
      logInfo(s"Returning initial snapshot $snapshot")
      snapshot
    } catch {
      case e: FileNotFoundException =>
        logInfo(s"Creating initial snapshot without metadata, because the directory is empty")
        // The log directory may not exist
        new InitialSnapshot(logPath, this)
    }
  }
```

ポイントは、スナップショットを作る際に用いられるセグメントである。
セグメントにバージョン情報が持たれている。

ここでは3行目の

```scala
      val segment = getLogSegmentFrom(lastCheckpoint)
```

にて `org.apache.spark.sql.delta.SnapshotManagement#getLogSegmentFrom` メソッドを用いて、
前回チェックポイントからセグメントの情報が生成される。

なお、参考までにLogSegmentクラスの定義は以下の通り。

org/apache/spark/sql/delta/SnapshotManagement.scala:392

```scala
case class LogSegment(
    logPath: Path,
    version: Long,
    deltas: Seq[FileStatus],
    checkpoint: Seq[FileStatus],
    checkpointVersion: Option[Long],
    lastCommitTimestamp: Long) {

  override def hashCode(): Int = logPath.hashCode() * 31 + (lastCommitTimestamp % 10000).toInt

  (snip)
```

上記の通り、コンストラクタ引数にバージョン情報が含まれていることがわかる。

インスタンス化の例は以下の通り。

org/apache/spark/sql/delta/SnapshotManagement.scala:140

```scala
      LogSegment(
        logPath,
        newVersion,
        deltasAfterCheckpoint,
        newCheckpointFiles,
        newCheckpoint.map(_.version),
        lastCommitTimestamp)
```


<!-- vim: set et tw=0 ts=2 sw=2: -->
