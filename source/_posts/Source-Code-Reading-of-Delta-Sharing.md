---

title: Source Code Reading of Delta Sharing
date: 2021-08-30 12:51:21
categories:
  - Knowledge Management
  - Data Collaboration
  - Delta Sharing
tags:
  - Delta Lake
  - Delta Sharing

---

# 参考

* [Delta Sharingの公式GitHub]
* [Read Data from a Table]

[Delta Sharingの公式GitHub]: https://github.com/delta-io/delta-sharing
[Read Data from a Table]: https://github.com/delta-io/delta-sharing/blob/main/PROTOCOL.md#read-data-from-a-table

* [Armeria]
* [ArmeriaのAnnotated service]

[Armeria]: https://armeria.dev/
[ArmeriaのAnnotated service]: https://armeria.dev/docs/server-annotated-service/

# メモ

## サーバの参考実装

### io.delta.sharing.server.DeltaSharingServiceの概略（起動の流れ）

サーバ起動スクリプトを見ると、以下のように `io.delta.sharing.server.DeltaSharingService` クラスが用いられている事が分かる。

```shell
declare -r lib_dir="$(realpath "${app_home}/../lib")"
declare -a app_mainclass=(io.delta.sharing.server.DeltaSharingService)
```

エントリポイントは以下の通り、

io/delta/sharing/server/DeltaSharingService.scala:276

```scala
  def main(args: Array[String]): Unit = {
    val ns = parser.parseArgsOrFail(args)
    val serverConfigPath = ns.getString("config")
    val serverConf = ServerConfig.load(serverConfigPath)
    start(serverConf).blockUntilShutdown()
  }
```

#### コンフィグのロード

渡された設定ファイルのPATHを用いて、設定を読み込む。

```scala
  /**
   * Load the configurations for the server from the config file. If the file name ends with
   * `.yaml` or `.yml`, load it using the YAML parser. Otherwise, throw an error.
   */
  def load(configFile: String): ServerConfig = {
    if (configFile.endsWith(".yaml") || configFile.endsWith(".yml")) {
      val serverConfig =
        createYamlObjectMapper.readValue(new File(configFile), classOf[ServerConfig])
      serverConfig.checkConfig()
      serverConfig
    } else {
      throw new IOException("The server config file must be a yml or yaml file")
    }
  }
```

#### startメソッド

オブジェクトのmainメソッド。その中で用いられている、 `start` メソッド内を確認していく。

io/delta/sharing/server/DeltaSharingService.scala:230

```scala
  def start(serverConfig: ServerConfig): Server = {
    lazy val server = {
      updateDefaultJsonPrinterForScalaPbConverterUtil()
      val builder = Server.builder()
        .defaultHostname(serverConfig.getHost)
        .disableDateHeader()
        .disableServerHeader()
        .annotatedService(serverConfig.endpoint, new DeltaSharingService(serverConfig): Any)
      if (serverConfig.ssl == null) {
        builder.http(serverConfig.getPort)
      } else {
        builder.https(serverConfig.getPort)
        if (serverConfig.ssl.selfSigned) {
          builder.tlsSelfSigned()
        } else {
          if (serverConfig.ssl.certificatePasswordFile == null) {
            builder.tls(
              new File(serverConfig.ssl.certificateFile),
              new File(serverConfig.ssl.certificateKeyFile))
          } else {
            builder.tls(
              new File(serverConfig.ssl.certificateFile),
              new File(serverConfig.ssl.certificateKeyFile),
              FileUtils.readFileToString(new File(serverConfig.ssl.certificatePasswordFile), UTF_8)
            )
          }
        }
      }
      if (serverConfig.getAuthorization != null) {
        // Authorization is set. Set up the authorization using the token in the server config.
        val authServiceBuilder =
          AuthService.builder.addOAuth2((_: ServiceRequestContext, token: OAuth2Token) => {
            // Use `MessageDigest.isEqual` to do a time-constant comparison to avoid timing attacks
            val authorized = MessageDigest.isEqual(
              token.accessToken.getBytes(UTF_8),
              serverConfig.getAuthorization.getBearerToken.getBytes(UTF_8))
            CompletableFuture.completedFuture(authorized)
          })
        builder.decorator(authServiceBuilder.newDecorator)
      }
      builder.build()
    }
    server.start().get()
    server
  }
```

一番最後の箇所の通り、

```scala
    server.start().get()
    server
```

`server` は、 [Armeria] のビルダを用いてインスタンス化されたサーバを起動する。
なお、`start`メソッド内ではTLS周りの設定、トークンの設定などが行われる。

なお、サーバに渡されるクラスは以下の通り、

```scala
      val builder = Server.builder()
        .defaultHostname(serverConfig.getHost)
        .disableDateHeader()
        .disableServerHeader()
        .annotatedService(serverConfig.endpoint, new DeltaSharingService(serverConfig): Any)
```

`com.linecorp.armeria.server.ServerBuilder#annotatedService(java.lang.String, java.lang.Object)` メソッドを用いて渡される。
渡されているのは `io.delta.sharing.server.DeltaSharingService` クラスである。
`annotatedService` メソッドについては、 [ArmeriaのAnnotated service] を参照。

### Shareのリストを返す箇所の実装

以下の通り、

io/delta/sharing/server/DeltaSharingService.scala:108

```scala
  @Get("/shares")
  @ProducesJson
  def listShares(
      @Param("maxResults") @Default("500") maxResults: Int,
      @Param("pageToken") @Nullable pageToken: String): ListSharesResponse = processRequest {
    val (shares, nextPageToken) = sharedTableManager.listShares(Option(pageToken), Some(maxResults))
    ListSharesResponse(shares, nextPageToken)
  }
```

`io.delta.sharing.server.SharedTableManager#SharedTableManager` クラスのインスタンスを利用し、
`io.delta.sharing.server.SharedTableManager#listShares` メソッドを用いて、
設定ファイルから読み込んだShareのリストを取得し返す。

つまり、このあたりの値を返す時にはデータ本体にアクセスしていない、ということになる。

仮に...もし設定ファイルに書かれたデータの実体が無かった場合はどうなるのだろうか。 ★要確認

テーブルのリスト取得も同じような感じだった。

### テーブルのバージョンを返す箇所の実装

io/delta/sharing/server/DeltaSharingService.scala:144

```scala
  @Head("/shares/{share}/schemas/{schema}/tables/{table}")
  def getTableVersion(
    @Param("share") share: String,
    @Param("schema") schema: String,
    @Param("table") table: String): HttpResponse = processRequest {
    val tableConfig = sharedTableManager.getTable(share, schema, table)
    val version = deltaSharedTableLoader.loadTable(tableConfig).tableVersion
    val headers = createHeadersBuilderForTableVersion(version).build()
    HttpResponse.of(headers)
  }
```

`io.delta.sharing.server.SharedTableManager#getTable` メソッドを利用し、コンフィグから読み込んだ情報を元に
テーブル情報を取得する。

つづいて、 `io.delta.standalone.internal.DeltaSharedTableLoader#loadTable` メソッドを利用し、
`io.delta.standalone.internal.DeltaSharedTable#DeltaSharedTable` クラスのインスタンスを取得する。

`DeltaSharedTable` クラスは、 `DeltaLog` クラスをラップした管理用のクラス。

### io.delta.standalone.internal.DeltaSharedTable クラス

このクラスは、`DeltaLog` クラスをラップしたものであり、サーバの管理機能の主要なコンポーネントである。

#### deltaLogの取得

例えば `deltaLog` インスタンスを取得できる。

io/delta/standalone/internal/DeltaSharedTableLoader.scala:74

```scala
  private val deltaLog = withClassLoader {
    val tablePath = new Path(tableConfig.getLocation)
    val fs = tablePath.getFileSystem(conf)
    if (!fs.isInstanceOf[S3AFileSystem]) {
      throw new IllegalStateException("Cannot share tables on non S3 file systems")
    }
    DeltaLog.forTable(conf, tablePath).asInstanceOf[DeltaLogImpl]
  }
```

上記の通り、内部では `io.delta.standalone.DeltaLog#forTable(org.apache.hadoop.conf.Configuration, org.apache.hadoop.fs.Path)` メソッドが
用いられており、実際にDelta Lake形式で保存されたデータ本体（Delta Lakeのメタデータ）にアクセスする。

#### テーブルバージョン取得

Delta Logの機能を利用し、テーブルのバージョンを取得できる。

```scala
  /** Return the current table version */
  def tableVersion: Long = withClassLoader {
    val snapshot = deltaLog.snapshot
    validateDeltaTable(snapshot)
    snapshot.version
  }
```

この機能は `io.delta.sharing.server.DeltaSharingService#getTableVersion` の実装に利用されている。

#### クエリ

`io.delta.standalone.internal.DeltaSharedTable#query` メソッドは、
後述の通り、`DeltaSharingSerivce` 内でファイルリストを取得したり、メタデータを取得したりするときに用いられる。



### ファイルリストを返す箇所の実装

`query` はファイルリストを返すAPIである。

io/delta/sharing/server/DeltaSharingService.scala:169

```scala
  @Post("/shares/{share}/schemas/{schema}/tables/{table}/query")
  @ConsumesJson
  def listFiles(
      @Param("share") share: String,
      @Param("schema") schema: String,
      @Param("table") table: String,
      queryTableRequest: QueryTableRequest): HttpResponse = processRequest {
    val tableConfig = sharedTableManager.getTable(share, schema, table)
    val (version, actions) = deltaSharedTableLoader.loadTable(tableConfig).query(
      includeFiles = true,
      queryTableRequest.predicateHints,
      queryTableRequest.limitHint)
    streamingOutput(version, actions)
  }
```

特徴的なのは、 `predicateHints` や `limitHint` が渡されており、フィルタ条件が指定できる点。
ただし、公式ドキュメント上では「ベストエフォート」と書かれている。

このメソッドのポイントは、 `io.delta.standalone.internal.DeltaSharedTableLoader#DeltaSharedTableLoader` クラスを用いたクエリの部分だと考えられる。
このクラスは、Deltaテーブルの本体にアクセスし、各種情報を読みこむためのもので、コメントを読む限り、キャッシュする機能なども有している。
内部では `io.delta.standalone.internal.DeltaSharedTable` クラスが利用されている。
`DeltaSharedTable` クラスは、 `DeltaLog` をラップしたものであり、Delta Logの各種情報をサーバ内で扱うための機能を提供する。

特に、今回用いられているのは `io.delta.standalone.internal.DeltaSharedTable#query` メソッドである。

io/delta/standalone/internal/DeltaSharedTableLoader.scala:118

```scala
  def query(
      includeFiles: Boolean,
      predicateHits: Seq[String],
      limitHint: Option[Int]): (Long, Seq[model.SingleAction]) = withClassLoader {
    // TODO Support `limitHint`

(snip)
```

メソッドの定義の通り、このクエリは最終的に、

io/delta/standalone/internal/DeltaSharedTableLoader.scala:165

```scala
    snapshot.version -> actions
```

Delta Logから情報取得したスナップショットのバージョン、ファイル情報のシーケンスを返す。

なお、 `actions` に格納されている `SingleAction` クラスは以下の通り、
ファイルひとつに関する情報、プロトコルの情報、メタデータについての情報を保持している。

io/delta/sharing/server/model.scala:22

```scala
case class SingleAction(
    file: AddFile = null,
    metaData: Metadata = null,
    protocol: Protocol = null) {

  def unwrap: Action = {
    if (file != null) {
      file
    } else if (metaData != null) {
      metaData
    } else if (protocol != null) {
      protocol
    } else {
      null
    }
  }
}
```

#### アクションの生成される箇所

上記の通り、ここでいう「アクション」とはデータの実体であるファイル1個に関連する情報の塊である。
生成されるのは以下の箇所。

io/delta/standalone/internal/DeltaSharedTableLoader.scala:137

```scala
    val actions = Seq(modelProtocol.wrap, modelMetadata.wrap) ++ {
      if (includeFiles) {
        val selectedFiles = state.activeFiles.values.toSeq
        val filteredFilters =
          if (evaluatePredicateHints && modelMetadata.partitionColumns.nonEmpty) {
            PartitionFilterUtils.evaluatePredicate(
              modelMetadata.schemaString,
              modelMetadata.partitionColumns,
              predicateHits,
              selectedFiles
            )
          } else {
            selectedFiles
          }
        filteredFilters.map { addFile =>
          val cloudPath = absolutePath(deltaLog.dataPath, addFile.path)
          val signedUrl = signFile(cloudPath)
          val modelAddFile = model.AddFile(url = signedUrl,
            id = Hashing.md5().hashString(addFile.path, UTF_8).toString,
            partitionValues = addFile.partitionValues,
            size = addFile.size,
            stats = addFile.stats)
          modelAddFile.wrap
        }
      } else {
        Nil
      }
    }
```

最初から主要な部分の実装を確認する。

まず、シーケンスを作る際、先頭にプロトコルとメタデータをラップしたアクションが保持される。

```scala
    val actions = Seq(modelProtocol.wrap, modelMetadata.wrap) ++ {
```

その後、適宜ファイルに関する情報が格納される。
一応 `includeFiles` で空情報を返すかどうかの判定があるが、ここではTrueだとして話を進める。

まず、Delta Lakeテーブルのアクティブなファイルが取得される。

```scala
        val selectedFiles = state.activeFiles.values.toSeq
```

つづいて、Predicateヒントがあり、パーティションカラムが設定されている場合は、
それに基づいてフィルタが行われる。

```scala
        val filteredFilters =
          if (evaluatePredicateHints && modelMetadata.partitionColumns.nonEmpty) {
            PartitionFilterUtils.evaluatePredicate(
              modelMetadata.schemaString,
              modelMetadata.partitionColumns,
              predicateHits,
              selectedFiles
            )
          } else {
            selectedFiles
          }
```

ヒントを用いてフィルタしている箇所については後述する。

ここではフィルタされたファイルのリストが返されたとして話を続ける。

次に、`AddFile` の情報を用いて、より詳細な情報が確認される。

```scala
        filteredFilters.map { addFile =>
          val cloudPath = absolutePath(deltaLog.dataPath, addFile.path)
          val signedUrl = signFile(cloudPath)
          val modelAddFile = model.AddFile(url = signedUrl,
            id = Hashing.md5().hashString(addFile.path, UTF_8).toString,
            partitionValues = addFile.partitionValues,
            size = addFile.size,
            stats = addFile.stats)
          modelAddFile.wrap
        }
```

絶対PATH（というかURL）の取得、下回りのストレージ（現時点ではS3のみ対応）の署名済みURL取得が行われ、
改めて `AddFile` に格納されたのち、アクションにラップされて返される。

ここで、1点だけ署名済みURL取得する部分だけ確認する。
取得には、 `io.delta.standalone.internal.DeltaSharedTable#signFile` メソッドが用いられる。

io/delta/standalone/internal/DeltaSharedTableLoader.scala:192

```scala
  private def signFile(path: Path): String = {
    val absPath = path.toUri
    val bucketName = absPath.getHost
    val objectKey = absPath.getPath.stripPrefix("/")
    signer.sign(bucketName, objectKey).toString
  }
```

このメソッドでは、上記の通り、内部でバケット名やオブジェクトキーを渡しながら、
`io.delta.sharing.server.S3FileSigner#sign` メソッドが利用されている。

なお、`signer` インスタンスは以下のようになっており、

```scala
  private val signer = withClassLoader {
    new S3FileSigner(deltaLog.dataPath.toUri, conf, preSignedUrlTimeoutSeconds)
  }
```

将来的にS3以外にも対応できるような余地が残されている。

さて、 `sign` メソッドに戻る。

io/delta/sharing/server/CloudFileSigner.scala:41

```scala
  override def sign(bucket: String, objectKey: String): URL = {
    val expiration =
      new Date(System.currentTimeMillis() + SECONDS.toMillis(preSignedUrlTimeoutSeconds))
    val request = new GeneratePresignedUrlRequest(bucket, objectKey)
      .withMethod(HttpMethod.GET)
      .withExpiration(expiration)
    s3Client.generatePresignedUrl(request)
  }
```

上記の通り、 `com.amazonaws.services.s3.model.GeneratePresignedUrlRequest#GeneratePresignedUrlRequest(java.lang.String, java.lang.String)`
メソッドを利用してS3の署名付きURLが取得されている事が分かる。

#### ヒントが利用されている箇所

2021/9/18現在では、 `predicateHits` は用いられているが、`limitHint` は用いていないように見える。

`predicateHints` が用いられるのは以下の個所。

io/delta/standalone/internal/DeltaSharedTableLoader.scala:142

```scala
            PartitionFilterUtils.evaluatePredicate(
              modelMetadata.schemaString,
              modelMetadata.partitionColumns,
              predicateHits,
              selectedFiles
            )
```

`io.delta.standalone.internal.PartitionFilterUtils$#evaluatePredicate` メソッドは、
引数に `predicateHits` や対象となるDelta Tableに紐づいているアクティブなファイルリストを引数に渡される。
内部で、有効なpredicateかどうかなどをチェックされたのち、有効なpredicate文言があれば、
それに従いファイルリストがフィルタされる。

なお、内部的にはDelta LakeやSpark（の特にCatalyst）の実装に依存しているような箇所がみられる。

具体的には、 `evaluatePredicate` メソッド内の以下の個所。

io/delta/standalone/internal/PartitionFilterUtils.scala:61

```scala
        addFiles.filter { addFile =>
          val converter = CatalystTypeConverters.createToCatalystConverter(addSchema)
          predicate.eval(converter(addFile).asInstanceOf[InternalRow])
        }
```

ここで `predicate` は `org.apache.spark.sql.catalyst.expressions.InterpretedPredicate` クラスの
インスタンスである。（SparkのCatalystで用いられる、Predicate表現のひとつ）
このとき、`eval` メソッドが呼び出されていることがわかる。

/home/dobachi/.cache/coursier/v1/https/repo1.maven.org/maven2/org/apache/spark/spark-catalyst_2.12/2.4.7/spark-catalyst_2.12-2.4.7-sources.jar!/org/apache/spark/sql/catalyst/expressions/predicates.scala:39

```scala
case class InterpretedPredicate(expression: Expression) extends BasePredicate {
  override def eval(r: InternalRow): Boolean = expression.eval(r).asInstanceOf[Boolean]
```

このように、SparkのCatalystにおいては `eval` メソッドには、Spark SQLの行の表現である
`InternalRow` のインスタンスが渡され、当該 `predicate` に合致するかどうかがチェックされる。

### クラスローダについて

このクラスには、 `withClassLoader` が定義されており、
Armeriaではなく、DeltaSharedTableのクラスローダの下で関数を実行できるようになっている。

```scala
  /**
   * Run `func` under the classloader of `DeltaSharedTable`. We cannot use the classloader set by
   * Armeria as Hadoop needs to search the classpath to find its classes.
   */
  private def withClassLoader[T](func: => T): T = {
    val classLoader = Thread.currentThread().getContextClassLoader
    if (classLoader == null) {
      Thread.currentThread().setContextClassLoader(this.getClass.getClassLoader)
      try func finally {
        Thread.currentThread().setContextClassLoader(null)
      }
    } else {
      func
    }
  }
```



<!-- vim: set et tw=0 ts=2 sw=2: -->
