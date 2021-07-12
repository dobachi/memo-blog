---

title: Delta Lake with Alluxio
date: 2020-12-31 01:13:15
categories:
  - Knowledge Management
  - Storage Layer
  - Delta Lake
tags:
  - Delta Lake
  - Alluxio

---

# 参考

## 論文

* [Delta Lake High-Performance ACID Table Storage over Cloud Object Stores]
* [Lakehouse A New Generation of Open Platforms that Unify Data Warehousing and Advanced Analytics]

[Delta Lake High-Performance ACID Table Storage over Cloud Object Stores]: https://databricks.com/wp-content/uploads/2020/08/p975-armbrust.pdf
[Lakehouse A New Generation of Open Platforms that Unify Data Warehousing and Advanced Analytics]: http://cidrdb.org/cidr2021/papers/cidr2021_paper17.pdf

## Hadoop環境

* [ansible-bigdata]

[ansible-bigdata]: https://github.com/dobachi/ansible-bigdata.git

## Alluxioドキュメント

* [Examples: Use Alluxio as Input and Output]
* [Alluxio Security]

[Examples: Use Alluxio as Input and Output]: https://docs.alluxio.io/os/user/stable/en/compute/Spark.html#examples-use-alluxio-as-input-and-output
[Alluxio Security]: https://docs.alluxio.io/os/user/stable/en/operation/Security.html

# メモ

[Delta Lake High-Performance ACID Table Storage over Cloud Object Stores] や
[Lakehouse A New Generation of Open Platforms that Unify Data Warehousing and Advanced Analytics] の論文の通り、
Delta Lakeはキャッシュとの組み合わせが可能である。

今回は、ストレージにHDFS、キャッシュにAlluxioを使って動作確認する。

## 疑似分散で動作確認

### 実行環境の準備

[ansible-bigdata] あたりを参考に、Hadoopの疑似分散環境を構築する。
Bigtopベースの2.8.5とした。

併せて、同Ansibleプレイブック集などを用いて、Spark3.1.1のコミュニティ版を配備した。

併せて、Alluxioは2.5.0-2を利用。

Alluxioに関しては、以下のようにコンパイルしてパッケージ化して用いることできる。

```shell
$ sudo -u alluxio mkdir /usr/local/src/alluxio
$ sudo -u alluxio chown alluxio:alluxio /usr/local/src/alluxio
$ cd /usr/local/src/alluxio
$ sudo -u alluxio git clone git://github.com/alluxio/alluxio.git
$ sudu -u alluxio git checkout -b v2.5.0-2 refs/tags/v2.5.0-2
$ sudo -u alluxio mvn install -Phadoop-2 -Dhadoop.version=2.8.5 -DskipTests
```

コンフィグとしては以下を利用。

```properties
$ cat conf/alluxio-site.properties

(snip)

# Common properties
# alluxio.master.hostname=localhost
alluxio.master.hostname=localhost
# alluxio.master.mount.table.root.ufs=${alluxio.work.dir}/underFSStorage
# alluxio.master.mount.table.root.ufs=/tmp
alluxio.master.mount.table.root.ufs=hdfs://localhost:8020/alluxio

# Security properties
# alluxio.security.authorization.permission.enabled=true
# alluxio.security.authentication.type=SIMPLE
alluxio.master.security.impersonation.yarn.users=*
alluxio.master.security.impersonation.yarn.groups=*

# Worker properties
# alluxio.worker.ramdisk.size=1GB
alluxio.worker.ramdisk.size=1GB
# alluxio.worker.tieredstore.levels=1
# alluxio.worker.tieredstore.level0.alias=MEM
# alluxio.worker.tieredstore.level0.dirs.path=/mnt/ramdisk

# User properties
# alluxio.user.file.readtype.default=CACHE
# alluxio.user.file.writetype.default=MUST_CACHE
```

ポイントは以下の通り。

* 疑似分散環境のHDFS利用
* Alluxioの使用するディレクトリとして、`/alluxio`を利用
* マスタはローカルホストで起動

### フォーマット、起動

```shell
$ sudo -u alluxio ./bin/alluxio format
$ sudo -u alluxio ./bin/alluxio-start.sh local SudoMount
```

テストを実行

```shell
$ sudo -u alluxio ./bin/alluxio runTests
```

もしエラーが生じた場合は、例えばHDFSの/alluxioディレクトリに、
適切な権限設定、所有者設定がされているかどうかを確認すること。

Alluxioが起動すると以下のようなUIを確認できる（ポート19999）

![AlluxioのUI](/memo-blog/images/20210101_alluxio_started.PNG)

先程テストで書き込まれたファイル群が見られるはず。

![Alluxioに書き込まれたテストファイル群I](/memo-blog/images/20210104_alluxio_testfiles.PNG)

ここでは、上記の通り、環境を整えた前提で以下説明する。


### Sparkの起動確認

[Examples: Use Alluxio as Input and Output] を参考に、Alluxio経由での読み書きを試す。

予め、今回の動作確認で使用するテキストデータ（AlluxioのREADME）をアップロードしておく。

```
$ sudo -u alluxio /opt/alluxio/default//bin/alluxio fs copyFromLocal /opt/alluxio/default/LICENSE /LICENSE
```

予め、以下のような設定をspark-defaults.confに入れておく。
Alluxioのクライアントライブラリを用いられるように。

```
spark.driver.extraClassPath   /opt/alluxio/default/client/alluxio-2.5.0-2-client.jar
spark.executor.extraClassPath /opt/alluxio/default/client/alluxio-2.5.0-2-client.jar
```
Sparkが起動することを確認する。ここではDelta Lakeも含めて起動する。

```shell
$ /usr/local/spark/default/bin/spark-shell \
  --packages io.delta:delta-core_2.12:0.8.0 \
  --conf "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
  --conf "spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog"
```

起動したシェルでAlluxio上のREADMEファイルを読み取り、行数を確認する。

```scala
scala> val pathOnAlluxio = "alluxio://localhost:19998/LICENSE"

scala> val testDF = spark.read.text(pathOnAlluxio)

scala> testDF.count
res0: Long = 482
```

### Delta Lakeを通じて書き込む動作確認

準備として、Alluxio上に、`dobachi`ユーザ用のディレクトリを作成してみる。

```shell
$ sudo -u alluxio /opt/alluxio/default/bin/alluxio fs mkdir /users
$ sudo -u alluxio /opt/alluxio/default/bin/alluxio fs mkdir /users/dobachi
$ sudo -u alluxio /opt/alluxio/default/bin/alluxio fs chown dobachi:dobachi /users/dobachi
```

先程起動しておいたシェルで、Delta Lake形式のデータを書き込んで見る。


```scala
scala> val data = spark.range(0, 5)
data: org.apache.spark.sql.Dataset[Long] = [id: bigint]

scala> val outputUrl = "alluxio://localhost:19998/users/dobachi/numbers"

scala> data.write.format("delta").save(outputUrl)
```

すると以下のようなエラーが生じた。

```
scala> data.write.format("delta").save(outputUrl)
21/01/05 22:47:50 ERROR HDFSLogStore: The error typically occurs when the default LogStore implementation, that
 is, HDFSLogStore, is used to write into a Delta table on a non-HDFS storage system.
 In order to get the transactional ACID guarantees on table updates, you have to use the
 correct implementation of LogStore that is appropriate for your storage system.
 See https://docs.delta.io/latest/delta-storage.html " for details.

org.apache.hadoop.fs.UnsupportedFileSystemException: fs.AbstractFileSystem.alluxio.impl=null: No AbstractFileSystem configured for scheme: alluxio

(snip)
```

当たり前だが、Delta Lakeの下回りのストレージとして標準では、
Alluxioが対応しておらず、LogStoreからエラーが生じた、ということのようだ。

一瞬、LogStoreを新たに開発しないといけないか？と思ったものの、よく考えたら、HDFSHadoopFileSystemLogStoreから
Alluxioのスキーマを認識させてアクセスできるようにすればよいだけでは？と思った。
そこで、Hadoopの設定でAlluxioFileSystemをalluxioスキーマ（ファイルシステムのスキーマ）に明示的に登録してみる。

/etc/hadoop/conf/core-site.xmlに以下を追記。

```xml
  <property>
    <name>fs.AbstractFileSystem.alluxio.impl</name>
    <value>alluxio.hadoop.AlluxioFileSystem</value>
    <description>The FileSystem for alluxio uris.</description>
  </property>
```

再びSparkを立ち上げ、適当なデータを書き込み。

```scala
scala> val data = spark.range(0, 5)

scala> val outputUrl = "alluxio://localhost:19998/users/dobachi/numbers"

scala> data.write.format("delta").save(outputUrl)
```

![Alluxio上にDelta Lakeで保存された様子](/memo-blog/images/20210430_alluxio_deltalake.png)

以上のように書き込みに成功した。

つづいて、テーブルとして読み出す。

```scala
scala> val df = spark.read.format("delta").load(outputUrl)
scala> df.show
+---+
| id|
+---+
|  1|
|  2|
|  3|
|  4|
|  0|
+---+
```

テーブルへの追記。

```scala
scala> val addData = spark.range(5, 10)
scala> addData.write.format("delta").mode("append").save(outputUrl)
scala> df.show
+---+
| id|
+---+
|  3|
|  9|
|  6|
|  5|
|  1|
|  8|
|  4|
|  2|
|  7|
|  0|
+---+
```

また、追記書き込みをしたのでDeltaログが増えていることが分かる。
（3回ぶんのログがあるのは、↑には記載していないがミスったため）

![Alluxio上にDelta LakeのDeltaログ](/memo-blog/images/20210430_alluxio_deltalake2.png)


### （補足）HDFS上のディレクトリ権限に関するエラー

Sparkでの処理実行時にYARNで実行していたところ、Executorにおける処理からAlluxioを呼び出すときにエラー。
yarnユーザでのアクセスとなり、HDFS上の `/alluxio` へのアクセス権がなかったと考えられる。

```
21/01/05 02:54:35 WARN TaskSetManager: Lost task 0.0 in stage 0.0 (TID 0, hadoop-pseudo, executor 2): alluxio.exception.status.UnauthenticatedException: Channel authentication failed with code:UNAUTHENTICATED. Channel: GrpcChannelKey{ClientType=FileSystemMasterClient, ClientHostname=hadoop-pseudo.mshome.net, ServerAddress=GrpcServerAddress{HostName=localhost, SocketAddress=localhost:19998}, ChannelId=81f7d97f-8e32-4289-bcab-ea6008d5ffac}, AuthType: SIMPLE, Error: alluxio.exception.status.UnauthenticatedException: Plain authentication failed: Failed to authenticate client user="yarn" connecting to Alluxio server and impersonating as impersonationUser="vagrant" to access Alluxio file system. User "yarn" is not configured to allow any impersonation. Please read the guide to configure impersonation at https://docs.alluxio.io/os/user/2.4/en/operation/Security.html
        at alluxio.exception.status.AlluxioStatusException.from(AlluxioStatusException.java:141)
```

[Alluxio Security] のドキュメント中に「Client-Side Hadoop Impersonation」を読むと、
「なりすまし」を許可する設定があるようだ。

そこで、`yarn`ユーザが様々なユーザになりすませるような簡易設定を以下のように加えることにした。
実際の運用する際は、なりすましのスコープに注意したほうが良さそうだ。

conf/alluxio-site.properties

```properties
alluxio.master.security.impersonation.yarn.users=*
alluxio.master.security.impersonation.yarn.groups=*
```

ドキュメントではクライアントで `alluxio.security.login.impersonation.username` も指定するよう書かれていたが、
起動時にしてしなくてもアクセスできるようになった。
あとで実装を調べたほうが良さそうだ。


<!-- vim: set et tw=0 ts=2 sw=2: -->
