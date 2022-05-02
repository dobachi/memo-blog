---

title: Delta Sharing with MinIO
date: 2021-10-22 11:19:39
categories:
  - Knowledge Management
  - Data Collaboration
  - Delta Sharing
tags:
  - Minio
  - Delta Sharing

---

# メモ

Delta SharingはAWS S3、Azure Blob Storage、Azure Data Lake Storage Gen2に対応している。
そこで、AWS S3互換のストレージソフトウェアだったら使えるのではないか、ということで、
[MinIO] を利用してみることにする。

もろもろのサンプルコードは [dobachi DeltaSharingMinioExample] にある。

## MinIOの起動

[MinIO Quickstart Guide] を参考に、手元でMinIOサーバを構成する。
以下は手順の一例。

バイナリをダウンロードし、データ保存ディレクトリを作って立ち上げる。

```shell
$ mkdir -p ~/Minio
$ cd ~/Minio
$ wget https://dl.min.io/server/minio/release/linux-amd64/minio
$ mkdir -p data
$ chmod +x minio
$ ./minio server data
```

コンソールにメッセージが色々出る。
今回はテスト用なので特段指定しなかったが、Rootユーザの名称、パスワードが表示されているはずである。
これは後ほど、AWS S3プロトコルでMinIOサービスにアクセスする際のID、シークレットキーとしても利用する。

MinIOのクライアントをダウンロードし、エイリアスを設定する。
別のターミナルを開く。

```shell
$ cd ~/Minio
$ wget https://dl.min.io/client/mc/release/linux-amd64/mc
$ chmod +x mc
$ ./mc alias set myminio http://your_host:9000 minioadmin minioadmin
```

`your_host`のところは各自の環境に合わせて変更してほしい。
これにより、`myminio` という名前でエイリアスが作成された。

ちなみに、http://your_host:40915/ からアクセスできる。

なお、試しにAWS S3クライアントで接続してみることにする。

```shell
$ ./mc mb data/test_bucket
$ echo 'test' > test.txt
$ export AWS_ACCESS_KEY_ID=minioadmin
$ export AWS_SECRET_ACCESS_KEY=minioadmin
$ aws --endpoint-url http://localhost:9000 s3 ls
2021-10-22 12:26:13 test_bucket
$ aws --endpoint-url http://localhost:9000 s3 cp test.txt s3://test_bucket/test.txt
```

ここで、今回はMinioを利用していることから、エンドポイントURLを指定していることに注意。

![テストバケットに入ったデータ](images/minio_test_bucket.png)

## Delta Sharingサーバの起動

[Delta Sharing Reference Server] を参考に、サーバを起動する。

### リリースされたパッケージを利用する場合

パッケージを公式リリースからダウンロードして展開する。

```shell
$ mkdir -p ~/DeltaSharing
$ cd ~/DeltaSharing
$ wget https://github.com/delta-io/delta-sharing/releases/download/v0.2.0/delta-sharing-server-0.2.0.zip
$ unzip delta-sharing-server-0.2.0.zip
$ cd delta-sharing-server-0.2.0
```

### 現在のmainブランチを利用する場合

```shell
$ mkdir -p ~/Sources/
$ cd ~/Sources
$ git clone git@github.com:delta-io/delta-sharing.git
$ delta-sharing 
$ ./build/sbt server/universal:packageBin
```

`server/target/universal/delta-sharing-server-x.y.z-SNAPSHOT.zip` にパッケージが保存される。
なお、`x.y.z`にはバージョン情報が入る。ここでは`0.3.0`とする。

```shell
$ cp server/target/universal/delta-sharing-server-x.y.z-SNAPSHOT.zip ~/DeltaSharing/
$ cd ~/DeltaSharing/
$ unzip delta-sharing-server-0.3.0-SNAPSHOT.zip
$ cd delta-sharing-server-0.3.0-SNAPSHOT
```

### 設定ファイルの作成

Delta Sharingはデータストアのアクセスについて、間接的にHadoopライブラリに依存している。
そこで、AWS S3プロトコルでアクセスするためのHadoop設定ファイル `core-site.xml` を作成する。

conf/core-site.xml

```xml
<configuration>
  <property>
    <name>fs.s3a.endpoint</name>
    <value>http://localhost:9000</value>
  </property>
  <property>
    <name>fs.s3a.path.style.access</name>
    <value>true</value>
  </property>
</configuration>
```

ここではエンドポイントURL、パス指定方法の設定をしている。
なおパス指定方法の設定行わないと、Delta SharingからMinIOサーバにリクエストを送る際に、
ホスト名が `bucket_name.host` のような指定になってしまい、 `400 But Reuqest` エラーを生じてしまう。
詳しくは、 トラブルシュートの節を参照。

続いて、Delta Sharingサーバの設定ファイルを作成する。
以下は参考。

conf/delta-sharing-server.yml

```yaml
# The format version of this config file
version: 1
# Config shares/schemas/tables to share
shares:
- name: "share1"
  schemas:
  - name: "schema1"
    tables:
    - name: "table1"
      location: "s3a://test_bucket/delta_table"
# Set the host name that the server will use
host: "localhost"
# Set the port that the server will listen on
port: 18080
# Set the url prefix for the REST APIs
endpoint: "/delta-sharing"
# Set the timeout of S3 presigned url in seconds
preSignedUrlTimeoutSeconds: 900
# How many tables to cache in the server
deltaTableCacheSize: 10
# Whether we can accept working with a stale version of the table. This is useful when sharing
# static tables that will never be changed.
stalenessAcceptable: false
# Whether to evaluate user provided `predicateHints`
evaluatePredicateHints: false
```

ここで `s3a://test_bucket/delta_table` に指定しているのがMinIO内のデータである。
ここでは予め Delta Lakeフォーマットのデータを保存してあるものとする。

### Delta Sharingサーバの起動

```shell
$ ./bin/delta-sharing-server -- --conf conf/delta-sharing-server.yaml
```

### Delta SharingのPythonクライアントを利用してアクセスする。

まずクライアント用のプロファイルを準備する。

minio.share

```json
{
  "shareCredentialsVersion": 1,
  "endpoint": "http://localhost:18080/delta-sharing/",
  "bearerToken": ""
}
```

これを利用しながら、テーブルにアクセスする。

![Delta Sharingのクライアントでアクセス](images/20211022_delta_sharing_client.png)

ここでは試しにPandas DataFrameとして読み取っている。

## トラブルシュート

### パス指定方法の誤り

Hadoop設定上で、パス指定方法の設定を行わないと、以下のようなエラーが生じる。

Delta Sharingサーバ側のエラー

```
Caused by: org.apache.hadoop.fs.s3a.AWSS3IOException: doesBucketExist on test: com.amazonaws.services.s3.model.AmazonS3Exception: Bad Request (Service: Amazon S3; Status Code: 400; Error Code: 400 Bad Request; Request ID: null; S3 Extended Request ID: null), S3 Extended Request ID: null: Bad Request (Service: Amazon S3; Status Code: 400; Error Code: 400 Bad Request; Request ID: null; S3 Extended Request ID: null)
        at org.apache.hadoop.fs.s3a.S3AUtils.translateException(S3AUtils.java:194)
        at org.apache.hadoop.fs.s3a.S3AFileSystem.verifyBucketExists(S3AFileSystem.java:335)
        at org.apache.hadoop.fs.s3a.S3AFileSystem.initialize(S3AFileSystem.java:280)
        at org.apache.hadoop.fs.FileSystem.createFileSystem(FileSystem.java:3247)
        at org.apache.hadoop.fs.FileSystem.access$200(FileSystem.java:121)
        at org.apache.hadoop.fs.FileSystem$Cache.getInternal(FileSystem.java:3296)
        at org.apache.hadoop.fs.FileSystem$Cache.get(FileSystem.java:3264)
        at org.apache.hadoop.fs.FileSystem.get(FileSystem.java:475)
        at org.apache.hadoop.fs.Path.getFileSystem(Path.java:356)
        at io.delta.standalone.internal.DeltaSharedTable.$anonfun$deltaLog$1(DeltaSharedTableLoader.scala:76)
        at io.delta.standalone.internal.DeltaSharedTable.withClassLoader(DeltaSharedTableLoader.scala:95)
        at io.delta.standalone.internal.DeltaSharedTable.<init>(DeltaSharedTableLoader.scala:74)
        at io.delta.standalone.internal.DeltaSharedTableLoader.$anonfun$loadTable$1(DeltaSharedTableLoader.scala:53)
        at com.google.common.cache.LocalCache$LocalManualCache$1.load(LocalCache.java:4693)
        at com.google.common.cache.LocalCache$LoadingValueReference.loadFuture(LocalCache.java:3445)
        at com.google.common.cache.LocalCache$Segment.loadSync(LocalCache.java:2194)
        ... 60 more
```

Minioサーバ側でのエラー

```shell
$ ./mc admin trace myminio --debug -v
```

```
test.localhost:9000 [REQUEST methodNotAllowedHandler.func1] [2021-10-22T03:57:08:000] [Client IP: 127.0.0.1]
test.localhost:9000 HEAD /
test.localhost:9000 Proto: HTTP/1.1
test.localhost:9000 Host: test.localhost:9000
test.localhost:9000 Amz-Sdk-Invocation-Id: 821962e2-e1f8-31d7-4d0d-431529a3725c
test.localhost:9000 Authorization: AWS4-HMAC-SHA256 Credential=minioadmin/20211022/us-east-1/s3/aws4_request, SignedHeaders=amz-sdk-invocation-id;amz-sdk-retry;content-type;host;user-agent;x-amz-content-sha256;x-amz-date, Signature=07977380f3fd92b149e8c60937554fc5ee5287a0863c101431ef51aa3968c37b
test.localhost:9000 Connection: Keep-Alive
test.localhost:9000 Content-Type: application/octet-stream
test.localhost:9000 X-Amz-Content-Sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
test.localhost:9000 Amz-Sdk-Retry: 0/0/500
test.localhost:9000 Content-Length: 0
test.localhost:9000 User-Agent: Hadoop 2.10.1, aws-sdk-java/1.11.271 Linux/4.19.104-microsoft-standard OpenJDK_64-Bit_Server_VM/11.0.12+7-LTS java/11.0.12 scala/2.12.10
test.localhost:9000 X-Amz-Date: 20211022T035708Z
test.localhost:9000
test.localhost:9000 [RESPONSE] [2021-10-22T03:57:08:000] [ Duration 66µs  ↑ 137 B  ↓ 375 B ]
test.localhost:9000 400 Bad Request
test.localhost:9000 Content-Type: application/xml
test.localhost:9000 Server: MinIO
test.localhost:9000 Vary: Origin
test.localhost:9000 Accept-Ranges: bytes
test.localhost:9000 Content-Length: 261
test.localhost:9000 <?xml version="1.0" encoding="UTF-8"?>
<Error><Code>BadRequest</Code><Message>An error occurred when parsing the HTTP request HEAD at &#39;/&#39;</Message><Resource>/</Resource><RequestId></RequestId><HostId>baec9ee7-bfb0-441b-a70a-493bfd80d745</HostId></Error>
```

# 参考

## MinIO

* [MinIO]
* [MinIO Quickstart Guide]

[MinIO]: https://min.io/
[MinIO Quickstart Guide]: https://docs.min.io/docs/minio-quickstart-guide.html

## Delta Sharing

* [Delta Sharing Reference Server]

[Delta Sharing Reference Server]: https://github.com/delta-io/delta-sharing#delta-sharing-reference-server

## Sample code

* [dobachi DeltaSharingMinioExample]

[dobachi DeltaSharingMinioExample]: https://github.com/dobachi/DeltaSharingMinioExample

<!-- vim: set et tw=0 ts=2 sw=2: -->
