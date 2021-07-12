---

title: CDC Kafka and master table cache
date: 2020-01-25 23:32:13
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka
  - CDC
  - RDBMS
  - Kafka Connect

---

過去の古いメモを少し細くしてアップロード。

# 参考

* [KafkaConnectを試す その2]
* [No More Silos: How to Integrate Your Databases with Apache Kafka and CDC]
* [JDBC Connector (Source and Sink) for Confluent Platform]
* [JDBC Connector Prerequisites]
* [JDBC Connector Incremental Query Modes]
* [JDBC Connector Message Keys]
* [Confluent PlatformのUbuntuへのインストール手順]
* [Confluent CLIのインストール手順]
* [PostgreSQLで更新時のtimestampをアップデートするには]
* [PostgreSQL で連番の数字のフィールドを作る方法 (sequence について)]
* [postgres - シーケンス　inser時に自動採番]
* [Kafka Streams例]
* [GlobalKTablesExample.java]

[KafkaConnectを試す その2]: https://tutuz-tech.hatenablog.com/entry/2019/03/21/000835
[No More Silos: How to Integrate Your Databases with Apache Kafka and CDC]: https://www.confluent.io/blog/no-more-silos-how-to-integrate-your-databases-with-apache-kafka-and-cdc/
[JDBC Connector (Source and Sink) for Confluent Platform]: https://docs.confluent.io/current/connect/kafka-connect-jdbc/index.html
[JDBC Connector Prerequisites]: https://docs.confluent.io/current/connect/kafka-connect-jdbc/source-connector/index.html#prerequisites
[JDBC Connector Incremental Query Modes]: https://docs.confluent.io/current/connect/kafka-connect-jdbc/source-connector/index.html#incremental-query-modes
[JDBC Connector Message Keys]: https://docs.confluent.io/current/connect/kafka-connect-jdbc/source-connector/index.html#message-keys
[Confluent PlatformのUbuntuへのインストール手順]: https://docs.confluent.io/current/installation/installing_cp/deb-ubuntu.html#systemd-ubuntu-debian-install
[Confluent CLIのインストール手順]: https://docs.confluent.io/current/cli/installing.html
[PostgreSQLで更新時のtimestampをアップデートするには]: https://open-groove.net/postgresql/update-timestamp-function/
[PostgreSQL で連番の数字のフィールドを作る方法 (sequence について)]: http://www.abe-tatsuya.com/web_prog/postgresql/seaquence.php
[postgres - シーケンス　inser時に自動採番]: http://developpp.blog.jp/archives/8224244.html
[Kafka Streams例]: https://github.com/confluentinc/kafka-streams-examples#available-examples
[GlobalKTablesExample.java]: https://github.com/confluentinc/kafka-streams-examples/blob/5.4.0-post/src/main/java/io/confluent/examples/streams/GlobalKTablesExample.java

# メモ

## やりたいこと

マスタデータを格納しているRDBMSからKafkaにデータを取り込み、
KTableとしてキャッシュしたうえで、ストリームデータとJoinする。

## RDBMSからのデータ取り込み

[KafkaConnectを試す その2] や [No More Silos: How to Integrate Your Databases with Apache Kafka and CDC] を
参考に、Kafka Connectのjdbcコネクタを使用してみようと思った。

しかしこの例で載っているのは、差分取り込みのためにシーケンシャルなIDを持つカラムが必要であることが要件を満たさないかも、と思った。
やりたいのは、Updateも含むChange Data Capture。

test_db.json 内の該当箇所は以下の通り。

```json
(snip)
    "mode" : "incrementing",
    "incrementing.column.name" : "seq",
(snip)
```

ということで、 [JDBC Connector (Source and Sink) for Confluent Platform] を確認してみた。
結論としては、更新時間とユニークIDを使うモードを利用すると良さそうだ。

### JDBC Kafka Connector

[JDBC Connector Prerequisites] によると、
Kafka と Schema Registryがあればよさそうだ。

[JDBC Connector Incremental Query Modes] によると、モードは以下の通り。

* Incrementing Column
  * ユニークで必ず値が大きくなるカラムを持つことを前提としたモード
  * 更新はキャプチャできない。そのためDWHのfactテーブルなどをキャプチャすることを想定している。
* Timestamp Column
  * 更新時間のカラムを持つことを前提としたモード
  * 更新時間はユニークではないことを起因とした注意点がある。
    同一時刻に2個のレコードが更新された場合、もし1個目のレコードが処理されたあとに障害が生じたとしたら、
    復旧時にもう1個のレコードが処理されないことが起こりうる。
  * 疑問点：処理後に「処理済みTimestamp」を更新できないのだろうか
* Timestamp and Incrementing Columns
  * 更新時刻カラム、ユニークIDカラムの両方を前提としたモード
  * 先のTimestamp Columnモードで問題となった、同一時刻に複数レコードが生成された場合における、
    部分的なキャプチャ失敗を防ぐことができる。
  * 確認点：先に更新時刻を見て、ユニークIDで確認するのだろうか。だとしたら、更新もキャプチャできそう。
* Custom Query
  * クエリを用いてフィルタされた結果をキャプチャするモード
  * Incrementing Column、Timestamp Columnなどと比べ、オフセットをトラックしないので、
    クエリ自身がオフセットをトラックするのと同等の処理内容になっていないと行けない。
* Bulk
  * テーブルをまるごとキャプチャするモード
  * レコードが消える場合になどに対応
  * 補足：他のモードで、レコードの消去に対応するには、実際に消去するのではなく、消去フラグを立てる、などの工夫が必要そう

当然だが、必要に応じて元のRDBMS側でインデックスが貼られていないとならない。

timestamp.delay.interval.ms 設定を使い、更新時刻に対し、実際に取り込むタイミングを遅延させられる。
これはトランザクションを伴うときに、一連のレコードが更新されるのを待つための機能。

なお、 [JDBC Connector Message Keys] によると、レコードの値や特定のカラムから、Kafkaメッセージのキーを生成できる。

### 更新時間とユニークIDを利用したキャプチャ

[No More Silos: How to Integrate Your Databases with Apache Kafka and CDC] のあたりを参考に、
別のモードを使って試してみる。

まずはKafka環境を構築するが、ここでは簡単化のためにConfluent Platformを用いることとした。
[Confluent PlatformのUbuntuへのインストール手順] あたりを参考にすすめると良い。
また、 `confluent` コマンドがあると楽なので、 [Confluent CLIのインストール手順] を参考にインストールしておく。

インストールしたら、シングルモードでKafka環境を起動しておく。

```bash
$ confluent local start
```

[KafkaConnectを試す その2] あたりを参考に、Kafkaと同一マシンにPostgreSQLの環境を構築しておく。

```bash
$ sudo apt install -y postgresql
$ sudo vim /etc/postgresql/10/main/postgresql.conf
$ sudo cp /usr/share/postgresql/10/pg_hba.conf{.sample,}
$ sudo vim /usr/share/postgresql/10/pg_hba.conf
$ sudo systemctl restart postgresql
```

/etc/postgresql/10/main/postgresql.conf に追加する内容は以下の通り。

```ini
listen_addresses = '*'
```

/usr/share/postgresql/10/pg_hba.conf に追加する内容は以下の通り。

```postgres
# PostgreSQL Client Authentication Configuration File
# ===================================================
local all all                trust
host  all all 127.0.0.1/32 trust
```

Kakfa用のデータベースとテーブルを作る。

```bash
$ psql -c "alter user postgres with password 'kafkatest'" 
```

```bash
$ sudo -u postgres psql -U postgres -W -c "CREATE DATABASE testdb";
Password for user postgres:  
```

テーブルを作る際、Timestampとインクリメンタルな値を使ったデータキャプチャを実現するためのカラムを含むようにする。
[PostgreSQLで更新時のtimestampをアップデートするには] 、 [PostgreSQL で連番の数字のフィールドを作る方法 (sequence について)] 、
[postgres - シーケンス　inser時に自動採番] あたりを参考とする。

以下、テーブルを作り、ユニークID用のシーケンスを作り、タイムスタンプを作る流れ。
タイムスタンプはレコード更新時に合わせて更新されるようにトリガを設定する。

```
$ sudo -u postgres psql -U postgres testdb
```

```sql
CREATE TABLE test_table (
    seq SERIAL PRIMARY KEY,
    ts timestamp NOT NULL DEFAULT now(),
    item varchar(256),
    price integer,
    category varchar(256)
);
CREATE FUNCTION set_update_time() RETURNS OPAQUE AS '
  begin
    new.ts := ''now'';
    return new;
  end;
' LANGUAGE 'plpgsql';
CREATE TRIGGER update_tri BEFORE UPDATE ON test_table FOR EACH ROW
  EXECUTE PROCEDURE set_update_time();
CREATE USER connectuser WITH password 'connectuser';
GRANT ALL ON test_table TO connectuser;
INSERT INTO test_table(item, price, category) VALUES ('apple', 400, 'fruit');
INSERT INTO test_table(item, price, category) VALUES ('banana', 160, 'fruit');
UPDATE test_table SET item='orange', price=100 where seq = 2;
INSERT INTO test_table(item, price, category) VALUES ('banana', 200, 'fruit');
INSERT INTO test_table(item, price, category) VALUES ('pork', 400, 'meet');
INSERT INTO test_table(item, price, category) VALUES ('beef', 800, 'meet');
```

以下のような結果が得られるはずである。

```
testdb=# SELECT * FROM test_table;
 seq |             ts             |  item  | price | category
-----+----------------------------+--------+-------+----------
   1 | 2020-02-02 13:31:12.065458 | apple  |   400 | fruit
   2 | 2020-02-02 13:31:49.220178 | orange |   100 | fruit
   3 | 2020-02-02 13:32:32.324241 | banana |   200 | fruit
   4 | 2020-02-02 13:33:06.560747 | pork   |   400 | meet
   5 | 2020-02-02 13:33:06.561966 | beef   |   800 | meet
(5 rows)
```


### Kafka Connect

[JDBC Connector Incremental Query Modes] を参考に、タイムスタンプ＋インクリメンティングモードを用いる。

```
cat << EOF > test_db.json
{
  "name": "load-test-table",
  "config": {
    "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector", 
    "connection.url" : "jdbc:postgresql://localhost:5432/testdb",
    "connection.user" : "connectuser",
    "connection.password" : "connectuser",
    "mode" : "timestamp+incrementing",
    "incrementing.column.name" : "seq",
    "timestamp.column.name" : "ts",
    "table.whitelist" : "test_table",
    "topic.prefix" : "db_",
    "tasks.max" : "1"
  }
}
EOF
$ curl -X DELETE http://localhost:8083/connectors/load-test-table
$ curl -X POST -H "Content-Type: application/json" http://localhost:8083/connectors -d @test_db.json
$ curl http://localhost:8083/connectors
```

上記コネクタでは、KafkaにAvro形式で書き込むので、
`kafka-avro-console-consumer`で確認する。

```
$ kafka-avro-console-consumer --bootstrap-server localhost:9092 --topic db_test_table --from-beginning
```

上記を起動した後、PostgreSQL側で適当にレコードを挿入・更新すると、
以下のような内容がコンソールコンシューマの出力に表示される。

変化がキャプチャされて取り込まれることがわかる。
挿入だけではなく、更新したものも取り込まれる。メッセージには、シーケンスとタイムスタンプの療法が含まれている。

```
{"seq":1,"ts":1580650272065,"item":{"string":"apple"},"price":{"int":400},"category":{"string":"fruit"}}
{"seq":2,"ts":1580650296666,"item":{"string":"banana"},"price":{"int":160},"category":{"string":"fruit"}}
{"seq":2,"ts":1580650309220,"item":{"string":"orange"},"price":{"int":100},"category":{"string":"fruit"}}
{"seq":3,"ts":1580650352324,"item":{"string":"banana"},"price":{"int":200},"category":{"string":"fruit"}}
{"seq":4,"ts":1580650386560,"item":{"string":"pork"},"price":{"int":400},"category":{"string":"meet"}}
{"seq":5,"ts":1580650386561,"item":{"string":"beef"},"price":{"int":800},"category":{"string":"meet"}}
```

## Kafka Stramsでテーブルに変換

上記の通り、RDBMSからデータを取り込んだものに対し、
マスタテーブルとして使うため、KTableに変換してみる。


### GlobalKTableへの読み込み

[Kafka Streams例] あたりを参考にする。
特に、 [GlobalKTablesExample.java] あたりが参考になるかと思う。
今回は、上記レポジトリをベースに少しいじって、本例向けのサンプルアプリを作る。


[WIP]


<!-- vim: set et tw=0 ts=2 sw=2: -->
