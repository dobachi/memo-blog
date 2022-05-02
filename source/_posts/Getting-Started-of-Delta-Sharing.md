---

title: Getting Started of Delta Sharing
date: 2021-09-10 11:14:58
categories:
  - Knowledge Management
  - Data Collaboration
  - Delta Sharing
tags:
  - Delta Sharing

---

# 参考

* [公式GitHub]
* [Autorization]
* [REST API]
* [Shareの取得]
* [Tableバージョンの取得]
* [テーブルメタデータの取得]
* [テーブルデータの読み出し]

[公式GitHub]: https://github.com/delta-io/delta-sharing
[Autorization]: https://github.com/delta-io/delta-sharing#authorization
[REST API]: https://github.com/delta-io/delta-sharing/blob/main/PROTOCOL.md#rest-apis
[Shareの取得]: https://github.com/delta-io/delta-sharing/blob/main/PROTOCOL.md#list-shares
[Tableバージョンの取得]: https://github.com/delta-io/delta-sharing/blob/main/PROTOCOL.md#query-table-version
[テーブルメタデータの取得]: https://github.com/delta-io/delta-sharing/blob/main/PROTOCOL.md#query-table-metadata
[テーブルデータの読み出し]: https://github.com/delta-io/delta-sharing/blob/main/PROTOCOL.md#read-data-from-a-table

* [Delta Sharing Example]
* [CreateDeltaTableS3]
* [pyspark_jupyter]
* [PythonConnectorExample]
* [TestProfileOnS3]

[Delta Sharing Example]: https://github.com/dobachi/delta_sharing_example
[CreateDeltaTableS3]: https://github.com/dobachi/delta_sharing_example/blob/main/CreateDeltaTableS3.ipynb
[pyspark_jupyter]: https://github.com/dobachi/delta_sharing_example/blob/main/bin/pyspark_jupyter.sh
[PythonConnectorExample]: https://github.com/dobachi/delta_sharing_example/blob/main/PythonConnectorExample.ipynb
[TestProfileOnS3]: https://github.com/dobachi/delta_sharing_example/blob/main/TestProfileOnS3.ipynb



# メモ

## 特徴

特徴については以下を参照。

<iframe src="https://onedrive.live.com/embed?cid=C6E669622F542498&resid=C6E669622F542498%21102556&authkey=AHO18y2xg6wyASo&em=2" width="402" height="327" frameborder="0" scrolling="no"></iframe>

## リファレンスサーバを動かす

[公式GitHub] のREADMEを参考に、リファレンスサーバを動かす。

### 前提

* OS: CentOS Linux release 7.8.2003 (Core)、CentOS Linux release 7.9.2009 (Core)
* 必要なライブラリ
  * bzip2-devel、readline-devel、openssl-devel、sqlite-devel、libffi-devel
* Python: 3.7.10
  * pipでjupyter labを入れておく。
* Spark:3.1.2 w/ Hadoop3.2
  * pipか公式サイトからダウンロードしたパッケージを利用してインストールしておく。
  * 今回は簡易的な動作確認のため、Spark単体（ローカルモード）で動作させる。Hadoopとの連係はさせない。

### サンプルスクリプト

[Delta Sharing Example] にこの記事で取り扱うサンプルスクリプト（Jupyterのノートブック）を置いてある。
なお、このプロジェクトには、Jupyter LabをPySparkと一緒に起動するサンプル補助スクリプト `./bin/pyspark_jupyter.sh` が入っている。
適宜編集して利用されたし。

以降の手順では、このノートブック群を利用した例を示す。
利用する場合はサブモジュールごと以下のようにクローンすると便利。

```shell
$ mkdir -p -/Sources
$ cd -/Sources
$ git clone --recursive https://github.com/dobachi/delta_sharing_example.git
```

#### .profileについて

なお、この補助スクリプトは同一ディレクトリに `.profile` があれば、それを読み込むようになっている。
特に、環境変数 `OPTIONS` や `S3_TEST_URL` に個人的な値を設定するために利用するとよい。

#### .profileで設定する環境変数について

* `OPTIONS` : Jupyter Lab起動時に、Sparkに渡すオプションを設定するために用意した。
* `S3_TEST_URL` : ノートブック内で読み書き動作確認用に用いるS3のURLを設定するために用意した。

### 基本的な動作

以下の流れで試す。

* S3上にサンプルデータを作成する
* 手元のマシンでDelta Sharingのサーバを立ち上げる
* githubからクローンしたライブラリをローカル環境にインストール
* S3に置いたサンプルデータをDelta Sharingのサーバ経由で取得する

#### S3上にサンプルデータを作成する

まずはS3上にデータを置く。なんの手段でも良いが、S3へのアクセスロールを持つEC2インスタンス上で
[CreateDeltaTableS3] を実行する。

なお、PySparkをJupyter Labで起動する補助するスクリプトの例が[pyspark_jupyter]に載っている。
[CreateDeltaTableS3] のレポジトリにおいても当該スクリプトがサブモジュールとして読み込まれる。

#### 手元のマシンでDelta Sharingのサーバを立ち上げる

つづいて、Delta Sharingのソースコードをクローンする。
なお、公式でリリースされたパッケージを用いてもよいのだが、
Delta Sharingはまだプロダクトが若く、変更も多いためmainブランチを
パッケージ化して用いることにする。

```shell
$ mkdir -p -/Sources
$ cd -/Sources
$ git clone https://github.com/delta-io/delta-sharing.git
$ cd delta-sharing
$ ./build/sbt server/universal:packageBin
```

これで `server/target/universal/delta-sharing-server-0.3.0-SNAPSHOT.zip` ができたはず。（2021/9現在。これ以降だと、バージョンが上がっている可能性がある）
これを適当なディレクトリに展開して用いるようにする。

```shell
$ mkdir -p ~/DeltaSharing
$ cp server/target/universal/delta-sharing-server-0.3.0-SNAPSHOT.zip ~/DeltaSharing
$ cd ~/DeltaSharing/
$ if [ -d delta-sharing-server-0.3.0-SNAPSHOT ]; then rm -r delta-sharing-server-0.3.0-SNAPSHOT; fi
$ unzip delta-sharing-server-0.3.0-SNAPSHOT.zip
```

展開したパッケージの中に、設定のテンプレートが入っているのでコピーして
自分の環境に合わせて編集する。

```shell
$ cd ~/DeltaSharing/delta-sharing-server-0.2.0-SNAPSHOT
$ cp conf/delta-sharing-server.yaml{.template,}
$ vim conf/delta-sharing-server.yaml
```

設定ファイルの例

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
      location: "s3a://<your configuration>"
# Set the host name that the server will use
host: "localhost"
# Set the port that the server will listen on
port: 80
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

サーバを起動する。

```shell
$ ./bin/delta-sharing-server -- --config conf/delta-sharing-server.yaml
```

#### githubからクローンしたライブラリをローカル環境にインストール

起動したサーバとは別のターミナルを開き、Pythonクライアントを試す。

先ほどクローンしたDelta Sharingのレポジトリを利用し、
venvなどで構築した環境下にpipでdelta sharingのPythonクライアントライブラリをインストールする。

```shell
$ pip install ~/Sources/delta-sharing/python/
```

なお、もしすでに一度インストールしたことがあるようであれば、アップデートするようにするなど工夫すること。

つづいて、Spark用のパッケージを作る。

```shell
$ cd ~/Sources/delta-sharing
$ ./build/sbt spark/package
```

`spark/target/scala-2.12/delta-sharing-spark_2.12-0.3.0-SNAPSHOT.jar` にJarファイルができる。

これをコネクタの起動時にロードするようにする。
例えば、PySparkのJupyter Lab起動時に以下のようなオプションを渡す。

```
--jars /home/centos/Sources/delta-sharing/spark/target/scala-2.12/delta-sharing-spark_2.12-0.3.0-SNAPSHOT.jar
```

のような

#### S3に置いたサンプルデータをDelta Sharingのサーバ経由で取得する

[PythonConnectorExample] にPythonのクライアントライブラリを用いた例を示す。
Pandas DataFrameで取得する例を掲載している。

上記スクリプト内でも利用している通り、クライアントがアクセスするためには、
以下のようなプロファイルを渡す必要がある。

```json
{
  "shareCredentialsVersion": 1,
  "endpoint": "http://localhost:80/delta-sharing/",
  "bearerToken": ""
}
```

このプロファイルは以下の通り、ファイルのPATH等を渡すか、`delta_sharing.protocol.DeltaSharingProfile`インスタンスを渡すかすれば良さそう。
後者の場合、JSONテキストから生成できる。

delta_sharing/delta_sharing.py:92

```python
    def __init__(self, profile: Union[str, BinaryIO, TextIO, Path, DeltaSharingProfile]):
```

一方、 `delta_sharing.delta_sharing.load_as_pandas` メソッドを用いて、
Pandas DataFrameで取得する場合は、その引数に渡すプロファイルはURLのテキストが期待されている。

```python
def load_as_pandas(url: str) -> pd.DataFrame:
    """
    Load the shared table using the give url as a pandas DataFrame.

    :param url: a url under the format "<profile>#<share>.<schema>.<table>"
    :return: A pandas DataFrame representing the shared table.
    """
    profile_json, share, schema, table = _parse_url(url)
    profile = DeltaSharingProfile.read_from_file(profile_json)
    return DeltaSharingReader(
        table=Table(name=table, share=share, schema=schema),
        rest_client=DataSharingRestClient(profile),
    ).to_pandas()
```

クライアントと同様に、JSONのテキストでも受け付けられるようにしたら便利か。
そもそもプロファイルとスキーマ等の指定が必ずしもひとつのURLになっていなくてもよいのでは…？と思う節もある。
が、共有は基本的にすべてURLで…という統一性を大事にするのも分かる。

### プロファイルの場所にURLを指定できるか？

Spark Connector利用時は、例えばS3に置いたプロファイルを使用できるか？の確認をする。

◇補足：
というのも、Spark Connectorを利用している際、Sparkのコンフィグにて、 `HADOOP_HOME` を設定し、Hadoopを利用するようにしてみたらどうやらHDFS
を探しに行っているようだったため、SparkのAPIを通じてプロファイルを読みに行っているのだとしたら、S3等に置かれたプロファイルを読めるはずだ、と考えたため。

ここでは、 `s3://hoge/fuga/deltasharing.json` のようなURLを渡すことにする。

結論から言えば、delta sharingはプロファイルの読み出しにfsspecを利用しているため、仕様上はリモートのファイルを読み出せるようになっている。

ここで実行したノートブックは [TestProfileOnS3] に置いてある。

#### delta sharing clientの生成

まず、共有データ一覧を取得するために用いるクライアントだが、

```python
client = delta_sharing.SharingClient(profile_file)
```

の引数にS3のURLを渡したら、以下のエラーになった。

```
ImportError: Install s3fs to access S3
```

これは、delta sharing内で用いられるfsspecにより出された例外である。

python/delta_sharing/protocol.py:41

```python
    @staticmethod
    def read_from_file(profile: Union[str, IO, Path]) -> "DeltaSharingProfile":
        if isinstance(profile, str):
            infile = fsspec.open(profile).open()
        elif isinstance(profile, Path):
            infile = fsspec.open(profile.as_uri()).open()
        else:
            infile = profile
        try:
            return DeltaSharingProfile.from_json(infile.read())
        finally:
            infile.close()
```

ということで、Python環境にpipでs3fsをインストールしてからもう一度試したところ、ひとまず動作した。

fsspecを利用しているということは、仕様上はリモートに置いてあるファイルシステムにも対応可能である、ということだった。

Pandas DataFrame、Spark DataFrameそれぞれへの読み出しについて、動作した。

### 認可

[Autorization] の通り、Bearer認証を利用できるようだ。

### REST APIでアクセス

[REST API] を参考に確認する。

#### Shareのリスト

ひとまず一番簡単な、Share一覧を取得する。

```shell
$ curl http://127.0.0.1:80/delta-sharing/shares | jq
{
  "items": [
    {
      "name": "share1"
    }
  ]
}
```

#### テーブルバージョンの取得

[Tableバージョンの取得] の通り。
なお、なぜか2行出力される。

```shell
$ curl -I -D - http://127.0.0.1:80/delta-sharing/shares/share1/schemas/schema1/tables/table1
HTTP/1.1 200 OK
HTTP/1.1 200 OK
delta-table-version: 4
delta-table-version: 4
content-length: 0
content-length: 0
```

[Shareの取得]にあるようにクエリパラメタとして `maxResult` やページングの情報を渡せる。

#### メタデータの取得

[テーブルメタデータの取得] の通り。

```shell
$ curl http://127.0.0.1:80/delta-sharing/shares/share1/schemas/schema1/tables/table1/metadata | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   271    0   271    0     0    919      0 --:--:-- --:--:-- --:--:--   921
{
  "protocol": {
    "minReaderVersion": 1
  }
}
{
  "metaData": {
    "id": "cea27a35-d139-4a74-a5f7-5596985784b8",
    "format": {
      "provider": "parquet"
    },
    "schemaString": "{\"type\":\"struct\",\"fields\":[{\"name\":\"id\",\"type\":\"long\",\"nullable\":true,\"metadata\":{}}]}",
    "partitionColumns": []
  }
}
```

#### データの取得

[テーブルデータの読み出し] に従うと、「ヒント句」を渡しながら、データ（のアクセスURL）を取得できるようだ。
ドキュメントを読む限り、このヒントが働くかどうかはベストエフォートとのこと。

```
$ curl -X POST -H "Content-Type: application/json; charset=utf-8" http://127.0.0.1:80/delta-sharing/shares/share1/schemas/schema1/tables/table1/query -d @- << EOL
{
  "predicateHints": [ "id < 1"
  ],
  "limitHint": 1
}
EOL
```

このヒントの働きについては、別途調査する。

<!-- vim: set et tw=0 ts=2 sw=2: -->
