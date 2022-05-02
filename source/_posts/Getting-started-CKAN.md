---

title: Getting_started_CKAN
date: 2022-01-20 18:04:05
categories:
  - Knowledge Management
  - Data Catalog
  - CKAN
tags:

---

# メモ

[CKAN公式サイト] によると、CKANはデータマネジメントシステムである。
[CKAN公式サイト] の内容をもとに進める。

このメモの時点では、CKAN 2.9.5を対象とする。

なお、公式ドキュメントによると `CKAN is a tool for making open data websites. ` とされており、
あくまで「オープンデータ向け」であることが伺える。

## ドキュメントより

### 特徴

[CKANの特徴] の通り、以下のような特徴を有している。

* CKAN APIを提供
* バックエンドのデータストア（アドホックなデータ置き場）
  * データソースかデータがpullされ、ストアされる
  * Data Explorer拡張を利用することでデータのプレビューが可能になる
  * 検索、更新などをデータ全てをダウンロード・アップロードせずにできる ★要確認
  * [DataPusher] 機能と一緒に使われることが多い
    * データソースから表形式のデータを取得し、DataStore APIを用いてCKANにデータ登録する仕組み
* 拡張機能
* 地理空間機能
* メタデータ
* データ管理のためのUI
* キーワード検索
* テーマ設定
* 可視化
* フェデレーション
* ファイルストア

### データのモデル

[Users, organizations and authorization] に記載の通り、基本的にはOrganizationに紐づけてDatasetが登録される。
Datasetは任意のフォーマットでよい。CKANにアップロードしてもよいし、単純にURLを登録してもよい。
デフォルトの挙動では、登録されたDatasetはPrivate扱いになり、所有するOrganizationに所属するユーザのみ見られる。

[Adding a new dataset] にある通り、Datasetを登録できる。
なお、Licenseに並んでいる項目を見ると、やはりオープンデータとの相性がよさそう、と感じる。

### DataStoreとDataPusher

[DataStore Extension] に記載の通り、 DataStore拡張機能を利用すると、Data Explorer拡張機能と併用することで自動的にプレビュー可能になる。
またDataStore APIを利用し、データ本体を丸ごとダウンロードすることなく、検索、フィルタ、更新できる。

自動的にデータを取り込むData Pusher拡張機能と併用されることが多い。

[DataPusher] の通り、データを取り出し自動的にCKANに登録できる。
ただし、注意書きにある通り、制約があるので注意。

[Data Dictionary] の通り、DataStoreのスキーマ情報はデータ辞書で管理できる。

[Downloading Resources] の通り、表形式のデータをCSVやエクセルで読み込める形式でダウンロードできる。

DataStore APIを利用すると、DataStoreリソースを検索したり、インクリメンタルにデータを追加できる。
バリデーションの機能もあるようだ。

APIについては、 [API reference] に記載されている。

### DataStoreの拡張

[Extending DataStore] に記載の通り、独自のDataStoreを利用可能。
正確には、実装可能。

[DatastoreBackend] がベースクラスである。

### バックグラウンドジョブ

[Background jobs] の通り、メインのアプリケーションをブロックせずに処理を実行できる。


## Dockerで動作確認

### セットアップ

[Installing CKAN with Docker Compose] を参考に、Docker Composeを利用して簡易的に動作確認する。
事前に、DockerとDocker Composeを導入しておくこと。

また、 [オープンソースのデータ管理システム「CKAN」を試してみた] が分かりやすかったのでおすすめ。

ソースコードをダウンロード。
ここではステーブルバージョンを利用することにした。

```shell
$ mkdir -p ~/Sources
$ cd ~/Sources
$ git clone https://github.com/ckan/ckan.git
$ git checkout -b ckan-2.9.5 tags/ckan-2.9.5
```

設定ファイルのコピー
適宜パスワードを変更するなど。
環境によっては、サイトURLを変更するのを忘れずに。

```shell
$ cp contrib/docker/.env.template contrib/docker/.env
```

ビルドと起動

```shell
$ cd contrib/docker
$ docker-compose up -d --build
```

後の作業のため、ストレージを変数化（しなくても、作業はできる。ボリュームのパスを覚えておけばよい）
（公式サイト手順の「Convenience: paths to named volumes」に記載あり）

```shell
$ export VOL_CKAN_HOME=$(docker volume inspect docker_ckan_home | jq -r -c '.[] | .Mountpoint')
$ echo $VOL_CKAN_HOME
$ export VOL_CKAN_CONFIG=$(docker volume inspect docker_ckan_config | jq -r -c '.[] | .Mountpoint')
$ echo $VOL_CKAN_CONFIG
$ export VOL_CKAN_STORAGE=$(docker volume inspect docker_ckan_storage | jq -r -c '.[] | .Mountpoint')
$ echo $VOL_CKAN_STORAGE
```

Datastoreとdatapusherを機能させるため、いくつか設定する。
まずはデータベースの設定。

```shell
$ docker exec ckan /usr/local/bin/ckan -c /etc/ckan/production.ini datastore set-permissions | docker exec -i db psql -U ckan
```

プラグインなどの設定

```shell
$ sudo vim $VOL_CKAN_CONFIG/production.ini
```

なお変更点は以下の通り。

```diff
$ sudo diff -u $VOL_CKAN_CONFIG/production.ini{.org,}
--- /var/lib/docker/volumes/docker_ckan_config/_data/production.ini.org 2022-01-22 22:22:11.992878002 +0900
+++ /var/lib/docker/volumes/docker_ckan_config/_data/production.ini     2022-01-22 22:23:56.367637134 +0900
@@ -21,7 +21,7 @@
 use = egg:ckan

 ## Development settings
-ckan.devserver.host = localhost
+ckan.devserver.host = ubu18
 ckan.devserver.port = 5000

 @@ -47,10 +47,10 @@                                                                                                                                                                           [2/7337] # who.timeout = 86400

 ## Database Settings
-sqlalchemy.url = postgresql://ckan_default:pass@localhost/ckan_default
+sqlalchemy.url = postgresql://ckan_default:pass@ubu18/ckan_default

-#ckan.datastore.write_url = postgresql://ckan_default:pass@localhost/datastore_default
-#ckan.datastore.read_url = postgresql://datastore_default:pass@localhost/datastore_default
+ckan.datastore.write_url = postgresql://ckan_default:pass@ubu18/datastore_default
+ckan.datastore.read_url = postgresql://datastore_default:pass@ubu18/datastore_default

 # PostgreSQL' full-text search parameters
 ckan.datastore.default_fts_lang = english
@@ -101,7 +101,7 @@
 ## Redis Settings

 # URL to your Redis instance, including the database to be used.
-#ckan.redis.url = redis://localhost:6379/0
+ckan.redis.url = redis://ubu18:6379/0


 ## CORS Settings
@@ -119,7 +119,7 @@
 #       Add ``datapusher`` to enable DataPusher
 #              Add ``resource_proxy`` to enable resorce proxying and get around the
 #              same origin policy
-ckan.plugins = stats text_view image_view recline_view
+ckan.plugins = stats text_view image_view recline_view datastore datapusher

 # Define which views should be created by default
 # (plugins must be loaded in ckan.plugins)
@@ -181,7 +181,7 @@

 # Make sure you have set up the DataStore

-#ckan.datapusher.formats = csv xls xlsx tsv application/csv application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
+ckan.datapusher.formats = csv xls xlsx tsv application/csv application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
 #ckan.datapusher.url = http://127.0.0.1:8800/
 #ckan.datapusher.assume_task_stale_after = 3600

@@ -206,7 +206,7 @@

 #email_to = errors@example.com
 #error_email_from = ckan-errors@example.com
-#smtp.server = localhost
+smtp.server = ubu18
 #smtp.starttls = False
 #smtp.user = username@example.com
 #smtp.password = your_password
```

↑の変更点を説明する。

まず、今回はVM上のDockerで起動したので、SSHトンネル経由でのアクセスで困らないように開発環境ホスト名を
`localhost` から変更した。

また、Datastore機能、Datapusher機能を利用するためにプラグインを追加。

Datapusherのフォーマットを有効化（コメントアウトを解除）

コンテナを再起動。

```shell
$ docker-compose restart
```

公式サイトに記載の通り、APIに試しにアクセスるとレスポンスがあるはず。

```shell
$ curl 'http://localhost:5000/api/3/action/datastore_search?resource_id=_table_metadata'
```

アドミンユーザ作成。

```shell
$ docker exec -it ckan /usr/local/bin/ckan -c /etc/ckan/production.ini sysadmin add johndoe
```

http://<サイトのURL>/ckan にアクセスすれば、ウェブUIが確認できる。
先に設定した、アドミンユーザでとりあえずログインする。

### データストアとしてMinIO環境を整える

[MinIOのDocker] を参考に、Dockerでサーバを立ち上げる。

```shell
$ docker run -p 9000:9000 -p 9001:9001 minio/minio server /data --console-address ":9001"
```

http://<立ち上げたインスタンス>:9000 でMinIOのウェブコンソールにアクセスできる。
特に設定していなければ、ID：minioadmin、パスワード：minioadminである。

![MinIのUI](images/20220121_ckan_minio1.JPG)

![MinIのUI](images/20220123_ckan_minio2.JPG)

![MinIのUI](images/20220123_ckan_minio3.JPG)

別のコンソールで `mc`クライアントを立ち上げる。

```shell
$ docker run --name my-mc --hostname my-mc -it --entrypoint /bin/bash --rm minio/mc
```

エイリアスを設定し、バケットを作成する。
（URLは、MinIO起動時にコンソールに表示されるAPI用のURLを利用すること）

```shell
# mc alias set myminio http://172.17.0.2:9000 minioadmin minioadmin
# mc mb myminio/mybucket
```

ファイルを作成し、MinIOにアップロード（コピー）する。

```shell
# echo "hoge" > /tmp/hoge.txt
# mc cp /tmp/hoge.txt myminio/mybucket/hoge.txt
```

### AWS CLIでアクセスする

[AWS CLI v2 Docker image] を利用してAWS CLIを起動し、MinIOにアクセスする。
なお、コンテナで起動するのでそのままではホスト側の `~/.aws` にアクセスできない。そこで `-v` オプションを利用しマウントしてから configure するようにしている。
また、S3プロトコルでアクセスする際には、今回は手元のMinIO環境を利用するため、エンドポイントを指定していることに注意。

```shell
$ docker run --rm -it -v ~/.aws:/root/.aws amazon/aws-cli configure --profile myminio
$ docker run --rm -it -v ~/.aws:/root/.aws amazon/aws-cli --profile myminio s3 --endpoint-url http://172.17.0.2:9000 ls s3://mybucket/hoge.txt
2022-01-21 16:38:19          5 hoge.txt
```

無事にS3プロトコルでアクセスできたことが確かめられた。

### CKANのUIで操作

組織の作成

![組織作成](images/20220121_ckan_create_org1.JPG)

![組織作成](images/20220123_ckan_create_org2.JPG)

![組織作成](images/20220123_ckan_create_org3.JPG)

データセット作成

![データセット作成](images/20220121_ckan_create_dataset1.JPG)

![データセット作成](images/20220123_ckan_create_dataset2.JPG)

![データセット作成](images/20220123_ckan_create_dataset3.JPG)

先ほどのS3プロトコルURL（ `s3://mybucket/hoge.txt` ）を登録する。

### （補足）初期化

何らかの理由でDockerの環境をまっさらに戻したいことがあるかもしれない。
その場合は以下の通り。

```shell
$ docker-compose down
$ docker rmi -f docker_ckan docker_db
$ docker rmi $(docker images -f dangling=true -q)
$ docker volume rm docker_ckan_config docker_ckan_home docker_ckan_storage docker_pg_data docker_solr_data
$ docker-compose build
$ docker-compose up -d
$ docker-compose restart ckan # give the db service time to initialize the db cluster on first run
```

## （補足）FIWAREのCKANは拡張済？

[FIWAREのCKAN] の説明を見ると、Dataset登録時に `Searchable` のような項目がある。公式2.9.5で試したときにはなかった。
他にも `Additional Info` という項目があり、そこには `OAuth-Token` という項目もあった。
このように、特にアクセス管理や認証認可の機能が拡張されているのか、と思った。

## インストール（パッケージ）

Ubuntu18環境にCKANをインストールする。
基本的には、 [Installing CKAN from package] に従う。

# 参考

## CKAN

* [CKAN公式サイト]
* [CKANの特徴]
* [公式ドキュメント]
* [Installing CKAN with Docker Compose]
* [オープンソースのデータ管理システム「CKAN」を試してみた]
* [FIWAREのCKAN]
* [Users, organizations and authorization]
* [Adding a new dataset]
* [DataPusher]
* [Data Dictionary]
* [Downloading Resources]
* [API reference]
* [Extending DataStore]
* [DatastoreBackend]
* [Background jobs]
* [background-job-queues]

[CKAN公式サイト]: https://ckan.org/
[CKANの特徴]: https://ckan.org/features
[公式ドキュメント]: http://docs.ckan.org/en/2.9/
[Installing CKAN from package]: http://docs.ckan.org/en/2.9/maintaining/installing/install-from-package.html
[Installing CKAN with Docker Compose]: http://docs.ckan.org/en/2.9/maintaining/installing/install-from-docker-compose.html
[DataPusher]: https://github.com/ckan/datapusher
[オープンソースのデータ管理システム「CKAN」を試してみた]: https://dev.classmethod.jp/articles/try-oss-data-management-system-ckan/
[FIWAREのCKAN]: https://fiwaretourguide.letsfiware.jp/publishing-open-data-in-fiware/how-to-publish-open-datasets-in-ckan-2/
[Users, organizations and authorization]: http://docs.ckan.org/en/2.9/user-guide.html#users-organizations-and-authorization
[Adding a new dataset]: http://docs.ckan.org/en/2.9/user-guide.html#adding-a-new-dataset
[DataStore Extension]: http://docs.ckan.org/en/2.9/maintaining/datastore.html#datastore-extension
[DataPusher]: http://docs.ckan.org/en/2.9/maintaining/datastore.html#datapusher-automatically-add-data-to-the-datastore
[Data Dictionary]: http://docs.ckan.org/en/2.9/maintaining/datastore.html#data-dictionary
[Downloading Resources]: http://docs.ckan.org/en/2.9/maintaining/datastore.html#downloading-resources
[API reference]: http://docs.ckan.org/en/2.9/maintaining/datastore.html#api-reference
[Extending DataStore]: http://docs.ckan.org/en/2.9/maintaining/datastore.html#extending-datastore
[DatastoreBackend]: http://docs.ckan.org/en/2.9/maintaining/datastore.html#ckanext.datastore.backend.DatastoreBackend
[Background jobs]: http://docs.ckan.org/en/2.9/maintaining/background-tasks.html
[background-job-queues]: http://docs.ckan.org/en/2.9/maintaining/background-tasks.html#background-job-queues

## MinIO

* [MinIOのDocker]

[MinIOのDocker]: https://min.io/download#/docker

## AWS CLI

* [AWS CLI v2 Docker image]

[AWS CLI v2 Docker image]: https://aws.amazon.com/jp/blogs/developer/aws-cli-v2-docker-image/

<!-- vim: set et tw=0 ts=2 sw=2: -->
