---

title: Reference of connector plugin
date: 2020-12-16 23:31:01
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka
  - Kafak Connect

---

# 参考

* [kafka-connect-syslog]
* [kafka-connect-datagen]
* [kafka-connect-datagenのGitHub]
* [ConfluentのGitHub]
* [Kafkaのクイックスタート]
* [Confluent Platform and Apache Kafka Compatibility]
* [avro-random-generator]
* [kafka-connect-datagenのサンプルスキーマ]

[kafka-connect-syslog]: https://www.confluent.io/hub/confluentinc/kafka-connect-syslog
[kafka-connect-datagen]: https://www.confluent.io/hub/confluentinc/kafka-connect-datagen
[kafka-connect-datagenのGitHub]: https://github.com/confluentinc/kafka-connect-datagen
[ConfluentのGitHub]: https://github.com/confluentinc
[Kafkaのクイックスタート]: https://kafka.apache.org/documentation/#quickstart
[Confluent Platform and Apache Kafka Compatibility]: https://docs.confluent.io/platform/current/installation/versions-interoperability.html#cp-and-apache-ak-compatibility
[avro-random-generator]: https://github.com/confluentinc/avro-random-generator
[kafka-connect-datagenのサンプルスキーマ]: https://github.com/confluentinc/kafka-connect-datagen/tree/master/src/main/resources


# メモ

2020/12時点で、Kafka Connectのプラグインの参考になるもの探す。

## kafka-connect-syslog

[kafka-connect-syslog] が最も簡易に動作確認できそうだった。
ただ、 [ConfluentのGitHub] を見る限り、GitHub上には実装が公開されていないようだった。

### 動作確認

ここでは、ローカルに簡易実験用の1プロセスのKafkaを起動した前提とする。
起動方法は [Kafkaのクイックスタート] を参照。

[kafka-connect-syslog] のパッケージをダウンロードして `/opt/connectors` 以下に展開。

```
$ cd /opt/connectors
$ sudo unzip confluentinc-kafka-connect-syslog-1.3.2.zip
$ sudo chown -R kafka:kafka confluentinc-kafka-connect-syslog-1.3.2
```

というパッケージが展開される。

動作確認に使用するプロパティは以下。

```
$ cat etc/minimal-tcp.properties
#
# Copyright [2016 - 2019] Confluent Inc.
#

name=syslog-tcp
tasks.max=1
connector.class=io.confluent.connect.syslog.SyslogSourceConnector
syslog.port=5515
syslog.listener=TCP
confluent.license
confluent.topic.bootstrap.servers=localhost:9092
confluent.topic.replication.factor=1
```

また、Connectの設定には以下を追加する。

/opt/kafka_pseudo/default/config/connect-standalone.properties

```
(snip)

plugin.path=/usr/local/share/java,/usr/local/share/kafka/plugins,/opt/connectors,
```

プラグインを置く場所として、 `/opt/connectors` を指定した。

`/opt/kafka_pseudo/default/bin/connect-standalone.sh` を利用して、
スタンドアローンモードでKafka Connectを起動。

```shell
$ sudo -u kafka /opt/kafka_pseudo/default/bin/connect-standalone.sh /opt/kafka_pseudo/default/config/connect-standalone.properties \
  /opt/connectors/confluentinc-kafka-connect-syslog-1.3.2/etc/minimal-tcp.properties 
```

起動したのを確認し、別の端末から適当なデータを送信。

```shell
$ echo "<34>1 2003-10-11T22:14:15.003Z mymachine.example.com su - ID47 - Your refrigerator is running" | nc -v -w 1 localhost 5515
```

Console Consumerを利用して書き込み状況を確認。

```shell
$ cd ${KAFKA_HOME}
$ ./bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic syslog --from-beginning
```

先程書き込んだものが表示されるはずである。

## kafka-connect-datagen

[kafka-connect-datagen] もあった。
[kafka-connect-datagenのGitHub] に実装も公開されているように見える。
ドキュメントのリンクから、当該レポジトリのREADMEにジャンプしたため、そのように判断。

以降、v0.4.0を対象として確認したものである。

### 概要

指定されたスキーマで、ダミーデータを生成するコネクタ。
[avro-random-generator] を内部的に利用している。

スキーマ指定はAvroのスキーマファイルを渡す方法もあるし、
組み込みのスキーマを指定する方法もある。
[kafka-connect-datagenのサンプルスキーマ] を参照。

また、Kafkaに出力する際のフォーマットは指定可能。
Kafka Connect自体の一般的なパラメータである、 `value.converter` を指定すれば良い。
例えば以下の通り。

```
"value.converter": "org.apache.kafka.connect.json.JsonConverter",
```


### 実装状況

2020/12/21時点では本プロジェクトのバージョンは0.4.0であり、

```xml
    <parent>
        <groupId>io.confluent</groupId>
        <artifactId>common-parent</artifactId>
        <version>6.0.0</version>
    </parent>
```

の通り、Confluent Platformのバージョンとしては、6系である。

[Confluent Platform and Apache Kafka Compatibility] によると、
Confluent Platform 6系のKafkaバージョンは2.6.Xである。

#### io.confluent.kafka.connect.datagen.DatagenConnector

`io.confluent.kafka.connect.datagen.DatagenConnector` クラスは、
`org.apache.kafka.connect.source.SourceConnector` を継承している。
割と素直な実装。

`io.confluent.kafka.connect.datagen.DatagenConnector#start` メソッドは特別なことはしておらず、
コンフィグをロードするだけ。

`io.confluent.kafka.connect.datagen.DatagenConnector#taskConfigs` メソッドも
特別なことはしていない。start時に受け取ったプロパティから
taskConfigを生成して返す。

`io.confluent.kafka.connect.datagen.DatagenConnector#stop` メソッド
および、 `io.confluent.kafka.connect.datagen.DatagenConnector#config` もほぼ何もしない。

タスクには `io.confluent.kafka.connect.datagen.DatagenTask` クラスを利用する。

#### io.confluent.kafka.connect.datagen.DatagenTask クラス

`io.confluent.kafka.connect.datagen.DatagenTask#start` メソッドが
overrideされている。
以下、ポイントを確認する。

オフセット管理の仕組みあり。

io/confluent/kafka/connect/datagen/DatagenTask.java:133

```java
    Map<String, Object> offset = context.offsetStorageReader().offset(sourcePartition);
    if (offset != null) {
      //  The offset as it is stored contains our next state, so restore it as-is.
      taskGeneration = ((Long) offset.get(TASK_GENERATION)).intValue();
      count = ((Long) offset.get(CURRENT_ITERATION));
      random.setSeed((Long) offset.get(RANDOM_SEED));
    }
```

`io.confluent.avro.random.generator.Generator` のジェネレータ（のビルダ）を利用する。

io/confluent/kafka/connect/datagen/DatagenTask.java:141

```java
    Generator.Builder generatorBuilder = new Generator.Builder()
        .random(random)
        .generation(count);
```

クイックスタートの設定があれば、それに従ってスキーマを読み込む。


io/confluent/kafka/connect/datagen/DatagenTask.java:144

```java
    String quickstartName = config.getQuickstart();
    if (quickstartName != "") {
      try {
        quickstart = Quickstart.valueOf(quickstartName.toUpperCase());
        if (quickstart != null) {
          schemaFilename = quickstart.getSchemaFilename();
          schemaKeyField = schemaKeyField.equals("")
              ? quickstart.getSchemaKeyField() : schemaKeyField;
          try {
            generator = generatorBuilder
                .schemaStream(getClass().getClassLoader().getResourceAsStream(schemaFilename))
                .build();
          } catch (IOException e) {
            throw new ConnectException("Unable to read the '"
                + schemaFilename + "' schema file", e);
          }
        }
      } catch (IllegalArgumentException e) {
        log.warn("Quickstart '{}' not found: ", quickstartName, e);
      }
```

指定されたクイックスタート名に従い、パッケージに含まれるスキーマファイルを読み込み、
それを適用しながらジェネレータを生成する。

なお、クイックスタートのたぐいはenumで定義されている。

io/confluent/kafka/connect/datagen/DatagenTask.java:75

```java
  protected enum Quickstart {
    CLICKSTREAM_CODES("clickstream_codes_schema.avro", "code"),
    CLICKSTREAM("clickstream_schema.avro", "ip"),
    CLICKSTREAM_USERS("clickstream_users_schema.avro", "user_id"),
    ORDERS("orders_schema.avro", "orderid"),
    RATINGS("ratings_schema.avro", "rating_id"),
    USERS("users_schema.avro", "userid"),
    USERS_("users_array_map_schema.avro", "userid"),
    PAGEVIEWS("pageviews_schema.avro", "viewtime"),
    STOCK_TRADES("stock_trades_schema.avro", "symbol"),
    INVENTORY("inventory.avro", "id"),
    PRODUCT("product.avro", "id");

    private final String schemaFilename;
    private final String keyName;

    Quickstart(String schemaFilename, String keyName) {
      this.schemaFilename = schemaFilename;
      this.keyName = keyName;
    }

    public String getSchemaFilename() {
      return schemaFilename;
    }

    public String getSchemaKeyField() {
      return keyName;
    }
  }
```

クイックスタートが設定されておらず、スキーマの文字列が与えられた場合は、
それを用いてジェネレータが生成される。

io/confluent/kafka/connect/datagen/DatagenTask.java:164

```java
    } else if (schemaString != "") {
      generator = generatorBuilder.schemaString(schemaString).build();
```

それ以外の場合、つまりスキーマ定義の書かれたファイルを指定する場合は、
以下の通り。

io/confluent/kafka/connect/datagen/DatagenTask.java:166

```java
{
      String err = "Unable to read the '" + schemaFilename + "' schema file";
      try {
        generator = generatorBuilder.schemaStream(new FileInputStream(schemaFilename)).build();
      } catch (FileNotFoundException e) {
        // also look in jars on the classpath
        try {
          generator = generatorBuilder
              .schemaStream(DatagenTask.class.getClassLoader().getResourceAsStream(schemaFilename))
              .build();
        } catch (IOException inner) {
          throw new ConnectException(err, e);
        }
      } catch (IOException e) {
        throw new ConnectException(err, e);
      }
    }
```

最後のAvroに関連する情報を生成して終了。

io/confluent/kafka/connect/datagen/DatagenTask.java:184

```java
    avroSchema = generator.schema();
    avroData = new AvroData(1);
    ksqlSchema = avroData.toConnectSchema(avroSchema);
```

`io.confluent.kafka.connect.datagen.DatagenTask#poll` メソッドもoverrideされている。
以下、ポイントを記載する。

インターバル機能あり。

io/confluent/kafka/connect/datagen/DatagenTask.java:192

```java
    if (maxInterval > 0) {
      try {
        Thread.sleep((long) (maxInterval * Math.random()));
      } catch (InterruptedException e) {
        Thread.interrupted();
        return null;
      }
    }
```

ジェネレータを利用し、オブジェクトを生成する。

io/confluent/kafka/connect/datagen/DatagenTask.java:201

```java
    final Object generatedObject = generator.generate();
    if (!(generatedObject instanceof GenericRecord)) {
      throw new RuntimeException(String.format(
          "Expected Avro Random Generator to return instance of GenericRecord, found %s instead",
          generatedObject.getClass().getName()
      ));
    }
    final GenericRecord randomAvroMessage = (GenericRecord) generatedObject;
```

生成されたオブジェクトから、スキーマ定義に基づいてフィールドの値を取り出し、
バリューのArrayListを生成する。

io/confluent/kafka/connect/datagen/DatagenTask.java:210

```java
    final List<Object> genericRowValues = new ArrayList<>();
    for (org.apache.avro.Schema.Field field : avroSchema.getFields()) {
      final Object value = randomAvroMessage.get(field.name());
      if (value instanceof Record) {
        final Record record = (Record) value;
        final Object ksqlValue = avroData.toConnectData(record.getSchema(), record).value();
        Object optionValue = getOptionalValue(ksqlSchema.field(field.name()).schema(), ksqlValue);
        genericRowValues.add(optionValue);
      } else {
        genericRowValues.add(value);
      }
    }
```

キーも同様に取り出し、Kafka Connectの形式に変換する。

io/confluent/kafka/connect/datagen/DatagenTask.java:224

```java
    SchemaAndValue key = new SchemaAndValue(DEFAULT_KEY_SCHEMA, null);
    if (!schemaKeyField.isEmpty()) {
      key = avroData.toConnectData(
          randomAvroMessage.getSchema().getField(schemaKeyField).schema(),
          randomAvroMessage.get(schemaKeyField)
      );
    }
```

先程ArrayListとして取り出したバリューもKafka Connect形式に変換する。

io/confluent/kafka/connect/datagen/DatagenTask.java:233

```java
    final org.apache.kafka.connect.data.Schema messageSchema = avroData.toConnectSchema(avroSchema);
    final Object messageValue = avroData.toConnectData(avroSchema, randomAvroMessage).value();
```

イテレートのたびに、メタデータを更新する。

io/confluent/kafka/connect/datagen/DatagenTask.java:246

```java
    // The source offsets will be the values that the next task lifetime will restore from
    // Essentially, the "next" state of the connector after this loop completes
    Map<String, Object> sourceOffset = new HashMap<>();
    // The next lifetime will be a member of the next generation.
    sourceOffset.put(TASK_GENERATION, taskGeneration + 1);
    // We will have produced this record
    sourceOffset.put(CURRENT_ITERATION, count + 1);
    // This is the seed that we just re-seeded for our own next iteration.
    sourceOffset.put(RANDOM_SEED, seed);
```

最後に、SourceRecordのリスト形式に変換し、
レコードとして生成して戻り値として返す。

io/confluent/kafka/connect/datagen/DatagenTask.java:261

```java
    final List<SourceRecord> records = new ArrayList<>();
    SourceRecord record = new SourceRecord(
        sourcePartition,
        sourceOffset,
        topic,
        null,
        key.schema(),
        key.value(),
        messageSchema,
        messageValue,
        null,
        headers
    );
    records.add(record);
    count += records.size();
    return records;
```

つづいて、 `io.confluent.kafka.connect.datagen.DatagenTask#stop` メソッドだが、
これは特に何もしない。

`io.confluent.kafka.connect.datagen.DatagenTask#getOptionalSchema` という
オプショナルなフィールドに関するスキーマを取得するためのヘルパーメソッドもある。
`io.confluent.kafka.connect.datagen.DatagenTask#getOptionalValue` メソッドもある。

### 動作確認

confluentinc-kafka-connect-datagen-0.4.0.zip をダウンロードし、
`/opt/connectors`以下に展開したものとする。

今回は以下の設定ファイルを参考に、データ生成してみる。
なお、イテレーション回数は適度に修正して用いることを推奨する。

confluentinc-kafka-connect-datagen-0.4.0/etc/connector_users.config

```json
{
  "name": "datagen-users",
  "config": {
    "connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
    "kafka.topic": "users",
    "quickstart": "users",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "max.interval": 1000,
    "iterations": 10000000,
    "tasks.max": "1"
  }
}
```

上記はconfluentコマンド用で利用する際のコンフィグファイルである。
そこで以下のようなKafka Connect用の設定ファイルを生成する。

/opt/connectors/confluentinc-kafka-connect-datagen-0.4.0/etc/connector_users.properties

```
name=users
connector.class=io.confluent.kafka.connect.datagen.DatagenConnector
kafka.topic=users
quickstart=users
key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
value.converter.schemas.enable=false
max.interval=1000
iterations=10
tasks.max=1
```

スタンドアローンモードでKafka Connectを起動する。

```shell
$ sudo -u kafka /opt/kafka_pseudo/default/bin/connect-standalone.sh \
  /opt/kafka_pseudo/default/config/connect-standalone.properties \
  /opt/connectors/confluentinc-kafka-connect-datagen-0.4.0/etc/connector_users.properties
```

停止した後、結果を確認する。
トピックが作られたことがわかる。

```shell
$ /opt/kafka_pseudo/default/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
__consumer_offsets
_confluent-command
syslog
users
```

データを確認する。

```shell
$ /opt/kafka_pseudo/default/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic users --from-beginning
{"registertime":1501850210149,"userid":"User_8","regionid":"Region_3","gender":"FEMALE"}
{"registertime":1516539876299,"userid":"User_2","regionid":"Region_7","gender":"OTHER"}
{"registertime":1505292095234,"userid":"User_4","regionid":"Region_1","gender":"OTHER"}
{"registertime":1502118362741,"userid":"User_3","regionid":"Region_1","gender":"FEMALE"}
{"registertime":1503193759324,"userid":"User_9","regionid":"Region_5","gender":"MALE"}
{"registertime":1507693509191,"userid":"User_1","regionid":"Region_8","gender":"OTHER"}
{"registertime":1497764008309,"userid":"User_1","regionid":"Region_6","gender":"OTHER"}
{"registertime":1514606256206,"userid":"User_1","regionid":"Region_3","gender":"MALE"}
{"registertime":1492595638722,"userid":"User_2","regionid":"Region_6","gender":"MALE"}
{"registertime":1500602208014,"userid":"User_3","regionid":"Region_1","gender":"MALE"}
```

ダミーデータが生成されていることが確認できた。

（WIP）

<!-- vim: set et tw=0 ts=2 sw=2: -->
