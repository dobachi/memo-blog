---
title: Send binary data to Kafka
date: 2020-12-12 22:41:13
categories:
tags:
---

# 参考

* [Confluent Hub]
* [KIP-128 Add ByteArrayConverter for Kafka Connect]
* [DataReply kafka-connect-binary]
* [Kafka Connect API のmaven]

[Confluent Hub]: https://www.confluent.io/hub
[KIP-128 Add ByteArrayConverter for Kafka Connect]: https://cwiki.apache.org/confluence/display/KAFKA/KIP-128%3A+Add+ByteArrayConverter+for+Kafka+Connect
[DataReply kafka-connect-binary]: https://github.com/DataReply/kafka-connect-binary
[Kafka Connect API のmaven]: https://mvnrepository.com/artifact/org.apache.kafka/connect-api/2.6.0
[dobachi kafka-connect-binary]: https://github.com/dobachi/kafka-connect-binary


# メモ


## Confluent Hub

まずは、 [Confluent Hub] で関係するキーワードで調べる。
Kafka Connectのプラグインがあるかどうか、という観点。

* byte
* binary
* image
* figure
* array

あたりを確認したが関係するものはヒットしなかった。

## KIP-128 Add ByteArrayConverter for Kafka Connect

関連するKIPを探したところ、
[KIP-128 Add ByteArrayConverter for Kafka Connect] が見つかった。

目的は、もとのデータをそのままコピーするため、のようだ。

関連するコミットは以下のとおり。

```shell
dobachi@home:~/Sources/kafka$ git log --grep="KIP-128"
commit 52a15d7c0b88da11409954321463b8b57b133a23
Author: Ewen Cheslack-Postava <me@ewencp.org>
Date:   Tue Mar 14 17:20:49 2017 -0700

    KAFKA-4783: Add ByteArrayConverter (KIP-128)

    Author: Ewen Cheslack-Postava <me@ewencp.org>

    Reviewers: Guozhang Wang <wangguoz@gmail.com>

    Closes #2599 from ewencp/kafka-4783-byte-array-converter
```

その実装は単純であり、 `org.apache.kafka.connect.storage.Converter#fromConnectData` メソッドをoverrideしている。

org/apache/kafka/connect/converters/ByteArrayConverter.java:53

```java
    public byte[] fromConnectData(String topic, Schema schema, Object value) {
        if (schema != null && schema.type() != Schema.Type.BYTES)
            throw new DataException("Invalid schema type for ByteArrayConverter: " + schema.type().toString());

        if (value != null && !(value instanceof byte[]))
            throw new DataException("ByteArrayConverter is not compatible with objects of type " + value.getClass());

        return (byte[]) value;
    }
```

見ての通り、読み込んだオブジェクトをバイト列として返すようになっている。


## kafka-connect-binary

GitHub上で [DataReply kafka-connect-binary] を見つけた。

### org.apache.kafka.connect.binary.BinarySourceConnector

Kafka Connectとしてのエントリポイントは `org.apache.kafka.connect.binary.BinarySourceConnector` クラスが担う。

また、 実際のデータを読み込んでKafkaに渡す機能は、タスクである `org.apache.kafka.connect.binary.BinarySourceTask` クラスが担う。

独自実装の `org.apache.kafka.connect.binary.DirWatcher` クラスを利用し、
指定されたディレクトリ配下を監視して見つけたファイルをKafkaに送るようになっている。
（DirWatcherを使わず、ファイルパスを指定することも可能）

ここでは仮に、DirWatcherを使う場合を確認する。

org/apache/kafka/connect/binary/BinarySourceTask.java:106

```java
        if (use_dirwatcher == "true") {
            //consume here the pool
            if (!((DirWatcher) task).getQueueFiles().isEmpty()) {
                File file = ((DirWatcher) task).getQueueFiles().poll();
                // creates the record
                // no need to save offsets
                SourceRecord record = create_binary_record(file);
                records.add(record);
            }
        }
```

実際にKafkaに送るレコードを生成しているのは、
`org.apache.kafka.connect.binary.BinarySourceTask#create_binary_record` メソッドである。

org/apache/kafka/connect/binary/BinarySourceTask.java:134

```java
    private SourceRecord create_binary_record(File file) {

        byte[] data = null;
        try {
            //transform file to byte[]
            Path path = Paths.get(file.getPath());
            data = Files.readAllBytes(path);
            log.error(String.valueOf(data.length));
        } catch (IOException e) {
            e.printStackTrace();
        }

        // creates the structured message
        Struct messageStruct = new Struct(schema);
        messageStruct.put("name", file.getName());
        messageStruct.put("binary", data);
        // creates the record
        // no need to save offsets
        return new SourceRecord(Collections.singletonMap("file_binary", 0), Collections.singletonMap("0", 0), topic, messageStruct.schema(), messageStruct);
    }
```

引数として与えられた `File` のインスタンスをもとに、データを読み出して、
ファイル名とファイルパスの組み合わせのレコードを生成して返す。

なお、スキーマは `org.apache.kafka.connect.binary.BinarySourceTask#start` メソッドが呼ばれたときに生成される。
固定的なスキーマである。

org/apache/kafka/connect/binary/BinarySourceTask.java:86

```java
        schema = SchemaBuilder
                .struct()
                .name(schemaName)
                .field("name", Schema.OPTIONAL_STRING_SCHEMA)
                .field("binary", Schema.OPTIONAL_BYTES_SCHEMA)
                .build();
```

気になることとしたら、2020/12/13現在使われているKafka Connect APIの
バージョンが古いことである。

```xml
            <groupId>org.apache.kafka</groupId>
            <artifactId>connect-api</artifactId>
            <version>0.9.0.0</version>
            <scope>compile</scope>
```

[Kafka Connect API のmaven] によると最新版は2020/12/13現在で2.6.0。

試しにバージョンアップし、関連する修正を施した実装を
[dobachi kafka-connect-binary] においた。

<!-- vim: set et tw=0 ts=2 sw=2: -->
