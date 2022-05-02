---

title: Kafka Streamsの始め方
date: 2020-02-14 14:56:58
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka
  - Kafka Streams

---

# 参考

* [公式ドキュメント]
* [公式チュートリアル]
* [Confluent Platformドキュメント]
* [Confluent CLI]
* [公式API説明（groupBy）]
* [公式API説明（count）]
* [公式ドキュメント（Step 5: Process some data）]
* [公式ドキュメント（Developer Guide）]
* [公式ドキュメント（Kafka Streams DSL）]
* [公式ドキュメント（Kafka Streams Processor API）]
* [公式ドキュメント（Kafka Streams Test Utils）]

[公式ドキュメント]: https://kafka.apache.org/documentation/
[公式チュートリアル]: https://kafka.apache.org/24/documentation/streams/tutorial
[Confluent Platformドキュメント]: https://docs.confluent.io/current/installation/index.html
[Confluent CLI]: https://docs.confluent.io/current/cli/index.html
[公式API説明（groupBy）]: https://kafka.apache.org/24/javadoc/org/apache/kafka/streams/kstream/KStream.html#groupBy-org.apache.kafka.streams.kstream.KeyValueMapper-
[公式API説明（count）]: https://kafka.apache.org/24/javadoc/org/apache/kafka/streams/kstream/KGroupedStream.html#count-org.apache.kafka.streams.kstream.Materialized-
[公式ドキュメント（Step 5: Process some data）]: https://kafka.apache.org/24/documentation/streams/quickstart#quickstart_streams_process
[公式ドキュメント（Developer Guide）]: https://kafka.apache.org/24/documentation/streams/developer-guide/
[公式ドキュメント（Kafka Streams DSL）]: https://kafka.apache.org/24/documentation/streams/developer-guide/dsl-api.html#streams-developer-guide-dsl
[公式ドキュメント（Kafka Streams Processor API）]: https://kafka.apache.org/24/documentation/streams/developer-guide/processor-api.html#streams-developer-guide-processor-api
[公式ドキュメント（Kafka Streams Test Utils）]: https://kafka.apache.org/24/documentation/streams/developer-guide/testing.html



# メモ

まとまった情報が無いような気がするので、初心者向けのメモをここに書いておくことにする。

## はじめに読む文献

* [公式チュートリアル]
  * 最初にこのあたりを読み、イメージをつかむのが良い
* [公式ドキュメント（Developer Guide）] 
  * つづいて開発者ガイドを読むと良い

## レファレンスとして使う文献

* [公式ドキュメント（Kafka Streams DSL）]
  * チュートリアルを終えたあとくらいに使用し始めると良い
* [公式ドキュメント（Kafka Streams Processor API）]
  * Kafka Streams DSLでは対応しきれないときにProcessor APIを用いるときに使う
* [公式ドキュメント（Kafka Streams Test Utils）]
  * Kafka Streamsのテスト作るときに使用

## 環境準備

Apache Kafka、もしくはConfluent Platformで環境構築しておくことを前提とする。
Apache Kafkaであれば、 [公式ドキュメント] のインストール手順。
Confluent Platformであれば、 [Confluent Platformドキュメント]のインストール手順。

また、Confluent Platformを用いるときは、 [Confluent CLI] をインストールしておくと便利である。

```shell
$ confluent local start
```

だけでKafka関連のサービスを開発用にローカル環境に起動できる。
具体的には、以下のサービスを立ち上げられる。

```
control-center is [UP]
ksql-server is [UP]
connect is [UP]
kafka-rest is [UP]
schema-registry is [UP]
kafka is [UP]
zookeeper is [UP]
```

ちなみに、 ` org.apache.kafka.connect.cli.ConnectDistributed` が意外とメモリを使用するので注意。

また、デフォルトでは `/tmp` 以下にワーキングディレクトリを作成する。
また実行時には `/tmp/confluent.current` を作成し、その時に使用しているワーキングディレクトリを識別できるようになっている。
tmpwatch等により、ワーキングディレクトリを乱してしまい、 `confluent local start` によりKafkaクラスタを起動できなくなったときは、
`/tmp/confluent.current` を削除してもう一度起動すると良い。

以降の説明では、Confluent Platformをインストールしたものとして説明する。

## プロジェクト作成

[公式チュートリアル] が最初は参考になるはず。

MavenのArchetypeを使い、プロジェクトを生成する。

```shell
$ mvn archetype:generate \
    -DarchetypeGroupId=org.apache.kafka \
    -DarchetypeArtifactId=streams-quickstart-java \
    -DarchetypeVersion=2.4.0 \
    -DgroupId=net.dobachi.kafka.streams.examples \
    -DartifactId=firstapp \
    -Dversion=0.1 \
    -Dpackage=wordcount
```

適宜パッケージ名などを変更して用いること。

雛形に基づいたプロジェクトには、簡単なアプリが含まれている。
最初はこれらを修正しながら、アプリの書き方に慣れるとよい。

### wordcount/Pipe.java

Kafka Streamsのアプリは通常のJavaアプリと同様に、1プロセスからスタンドアローンで起動する。
ここでは、Pipe.javaの内容を確認しよう。
以下、ポイントとなるソースコードとその説明を並べる。

wordcount/Pipe.java:36

```java
        Properties props = new Properties();
        props.put(StreamsConfig.APPLICATION_ID_CONFIG, "streams-pipe");
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass());
        props.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass());

```

メインの中では最初にストリームを作るための設定が定義される。
上記の例では、ストリーム処理アプリの名前、Kafkaクラスタのブートストラップサーバ（つまり、Broker）、
またキーやバリューのデフォルトのシリアライゼーションの仕組みを指定します。
今回はキー・バリューともにStringであることがわかります。


wordcount/Pipe.java:42

```java
        final StreamsBuilder builder = new StreamsBuilder();

        builder.stream("streams-plaintext-input").to("streams-pipe-output");
```

つづいて、ストリームのビルダをインスタンス化。
このとき、入力・出力トピックを指定する。

wordcount/Pipe.java:46

```java
        final Topology topology = builder.build();
        final KafkaStreams streams = new KafkaStreams(topology, props);
        final CountDownLatch latch = new CountDownLatch(1);
```

ビルダでストリームをビルドし、トポロジを定義する。

wordcount/Pipe.java:46

```java
        // attach shutdown handler to catch control-c
        Runtime.getRuntime().addShutdownHook(new Thread("streams-shutdown-hook") {
            @Override
            public void run() {
                streams.close();
                latch.countDown();
            }
        });
```

シャットダウンフックを定義。

wordcount/Pipe.java:59

```java
        try {
            streams.start();
            latch.await();
        } catch (Throwable e) {
            System.exit(1);
        }
        System.exit(0);
```

ストリーム処理を開始。


上記アプリを実行するには、事前に

* streams-plaintext-input
* streams-pipe-output

の2種類のトピックを生成しておく。

```shell
$ kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic streams-plaintext-input
$ kafka-topics --create --zookeeper localhost:2181 --partitions 1 --replication-factor 1 --topic streams-pipe-output
```

トピックが作られたかどうかは、以下のように確認する。

```shell
$ kafka-topics --list --zookeeper localhost:2181
```

なお、ユーザが明示的に作るトピックの他にも、Kafkaの動作等のために作られるトピックがあるので、
上記コマンドを実行するとずらーっと出力されるはず。

コンパイル、パッケージングする。

```shell
$ mvn clean assembly:assembly -DdescriptorId=jar-with-dependencies
```

入力ファイルを作成し、入ロトピックに書き込み。

```shell
$ echo -e "all streams lead to kafka\nhello kafka streams\njoin kafka summit" > /tmp/file-input.txt
$ cat /tmp/file-input.txt | kafka-console-producer --broker-list localhost:9092 --topic streams-plaintext-input
```

アプリを実行する。

```shell
$ java -cp target/firstapp-0.1-jar-with-dependencies.jar wordcount.Pipe
```

別のターミナルを改めて開き、コンソール上に出力トピックの内容を出力する。

```shell
$ kafka-console-consumer --bootstrap-server localhost:9092 --from-beginning  --property print.key=true --topic streams-pipe-output
```

以下のような結果が見られるはずである。なお、今回はキーを使用しないアプリだから、左側（キーを表示する場所）には `null` が並ぶ。

```
null    all streams lead to kafka
null    hello kafka streams
null    join kafka summit
```

さて、ここでキーを使うようにしてみる。
今回使用したアプリをコピーし、 `wordcount/PipeWithKey.java` を作る。

ここで変更点は以下の通り。

```
--- src/main/java/wordcount/Pipe.java   2020-02-14 15:23:23.808282200 +0900
+++ src/main/java/wordcount/PipeWithKey.java    2020-02-14 16:54:17.623090500 +0900
@@ -17,10 +17,8 @@
 package wordcount;

 import org.apache.kafka.common.serialization.Serdes;
-import org.apache.kafka.streams.KafkaStreams;
-import org.apache.kafka.streams.StreamsBuilder;
-import org.apache.kafka.streams.StreamsConfig;
-import org.apache.kafka.streams.Topology;
+import org.apache.kafka.streams.*;
+import org.apache.kafka.streams.kstream.KStream;

 import java.util.Properties;
 import java.util.concurrent.CountDownLatch;
@@ -30,7 +28,7 @@
  * that reads from a source topic "streams-plaintext-input", where the values of messages represent lines of text,
  * and writes the messages as-is into a sink topic "streams-pipe-output".
  */
-public class Pipe {
+public class PipeWithKey {

     public static void main(String[] args) throws Exception {
         Properties props = new Properties();
@@ -41,7 +39,8 @@

         final StreamsBuilder builder = new StreamsBuilder();

-        builder.stream("streams-plaintext-input").to("streams-pipe-output");
+        KStream<String, String> raw = builder.stream("streams-plaintext-input");
+        raw.map((key, value ) -> new KeyValue<>(value.split(" ")[0], value)).to("streams-pipe-output");

         final Topology topology = builder.build();
         final KafkaStreams streams = new KafkaStreams(topology, props);
```

主な変更は、ストリームビルダから定義されたストリームをいったん、 `raw` にバインドし、
mapメソッドを使って変換している箇所である。
ここでは、バリューをスペースで区切り、先頭の単語をキーとすることにした。

このアプリをコンパイル、パッケージ化し実行すると、以下のような結果が得られる。

```shell
$ mvn clean assembly:assembly -DdescriptorId=jar-with-dependencies
$ cat /tmp/file-input.txt | kafka-console-producer --broker-list localhost:9092 --topic streams-plaintext-input
$ java -cp target/firstapp-0.1-jar-with-dependencies.jar wordcount.PipeWithKey
```

実行結果の例

```
all     all streams lead to kafka
hello   hello kafka streams
join    join kafka summit
```

### wordcount/LineSplit.java

先程作成したPipeWithKeyとほぼ同じ。
実行すると、 `streams-linesplit-output` というトピックに結果が出力される。

```shell
$ java -cp target/firstapp-0.1-jar-with-dependencies.jar wordcount.LineSplit
```

結果の例

```shell
$ kafka-console-consumer --bootstrap-server localhost:9092 --from-beginning  --property print.key=true --topic streams-linesplit-output
null    all
null    streams
null    lead
null    to
null    kafka
(snip)
```

### wordcount/WordCount.java

最後にWordCountを確認する。
ほぼ他のアプリと同じだが、ポイントはストリームを加工する定義の部分である。

wordcount/WordCount.java:53

```java
        builder.<String, String>stream("streams-plaintext-input")
               .flatMapValues(value -> Arrays.asList(value.toLowerCase(Locale.getDefault()).split("\\W+")))
               .groupBy((key, value) -> value)
               .count(Materialized.<String, Long, KeyValueStore<Bytes, byte[]>>as("counts-store"))
               .toStream()
               .to("streams-wordcount-output", Produced.with(Serdes.String(), Serdes.Long()));

```

以下、上記実装を説明する。

```java
        builder.<String, String>stream("streams-plaintext-input")
```

ストリームビルダを利用し、入力トピックからストリームを定義

```java
               .flatMapValues(value -> Arrays.asList(value.toLowerCase(Locale.getDefault()).split("\\W+")))
```

バリューに入っている文字列をスペース等で分割し、配列にする。
合わせて配列をflattenする。

```java
               .groupBy((key, value) -> value)
```

キーバリューから新しいキーを生成し、新しいキーに基づいてグループ化する。
今回の例では、分割されて生成された単語（バリューに入っている）をキーとしてグループ化する。
詳しくは、 [公式API説明（groupBy）]

```java
               .count(Materialized.<String, Long, KeyValueStore<Bytes, byte[]>>as("counts-store"))
```

groupByにより生成された `KGroupedStream` の `count` メソッドを呼び出し、
キーごとの合計値を求める。
今回はキーはString型であり、合計値はLong型。
また集計結果を保持するストアは `counts-store` という名前とする。
詳しくは、 [公式API説明（count）]

```java
               .toStream()
               .to("streams-wordcount-output", Produced.with(Serdes.String(), Serdes.Long()));
```

`count` の結果は `KTable` になるので、これをストリームに変換し、出力先トピックを指定する。


実行してみる。

```shell
$ mvn clean assembly:assembly -DdescriptorId=jar-with-dependencies
$ java -cp target/firstapp-0.1-jar-with-dependencies.jar wordcount.WordCount
```

別のターミナルを改めて立ち上げ、入力トピックに書き込む。

```shell
$ cat /tmp/file-input.txt | kafka-console-producer --broker-list localhost:9092 --topic streams-plaintext-input
```

出力は以下のようになる。

```shell
$ kafka-console-consumer --bootstrap-server localhost:9092 --from-beginning  --property print.key=true --property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer --topic streams-wordcount-output
all     19
lead    19
to      19
hello   19
streams 38
join    19
kafka   57
summit  19
```

なお、ここでは `kafka-console-consumer` にプロパティ `value.deserializer=org.apache.kafka.common.serialization.LongDeserializer` を渡した。
アプリケーションでは集計した値はLong型だったためである。
詳しくは、 [公式ドキュメント（Step 5: Process some data）] 参照。

なお、指定しない場合は入力されたバイト列がそのまま標準出力に渡されるようになっている。
その結果、期待する出力が得られないことになるので注意。

kafka/tools/ConsoleConsumer.scala:512

```scala
    def write(deserializer: Option[Deserializer[_]], sourceBytes: Array[Byte], topic: String): Unit = {
      val nonNullBytes = Option(sourceBytes).getOrElse("null".getBytes(StandardCharsets.UTF_8))
      val convertedBytes = deserializer.map(_.deserialize(topic, nonNullBytes).toString.
        getBytes(StandardCharsets.UTF_8)).getOrElse(nonNullBytes)
      output.write(convertedBytes)
    }
```

なお、別の方法として `WordCount` の実装を修正する方法がある。以下、参考までに修正方法を紹介する。

想定と異なる表示だが、これは今回バリューの方にLongを用いたため。
kafka-console-consumer で表示させるために以下のように実装を修正する。


```diff
@@ -50,12 +44,15 @@ public class WordCount {

         final StreamsBuilder builder = new StreamsBuilder();

-        builder.<String, String>stream("streams-plaintext-input")
+        KStream<String, Long> wordCount = builder.<String, String>stream("streams-plaintext-input")
                .flatMapValues(value -> Arrays.asList(value.toLowerCase(Locale.getDefault()).split("\\W+")))
                .groupBy((key, value) -> value)
-               .count(Materialized.<String, Long, KeyValueStore<Bytes, byte[]>>as("counts-store"))
-               .toStream()
-               .to("streams-wordcount-output", Produced.with(Serdes.String(), Serdes.Long()));
+               .count(Materialized.as("counts-store"))
+               .toStream();
+
+        wordCount.foreach((key, value) -> System.out.println("key: " + key + ", value: " + value));
+
+        wordCount.map((key, value) -> new KeyValue<>(key, String.valueOf(value))).to("streams-wordcount-output", Produced.with(Serdes.String(), Serdes.String()));
```

つまり、もともと `to` で終えていたところを、いったん変数にバインドし、 `foreach` を使ってストリームの内容を標準出力に表示させるようにしている。
また、 `map` メソッドを利用し、バリューの型をLongからStringに変換してから `to` で書き出すようにしている。

上記修正を加えた上で、改めてパッケージ化して実行したところ、以下のような表示が得られる。

kafka-console-consumer での表示例

```
all     9
lead    9
to      9
hello   9
streams 18
join    9
kafka   27
summit  9
```

ストリーム処理アプリの標準出力例

```
key: all, value: 9
key: lead, value: 9
key: to, value: 9
key: hello, value: 9
key: streams, value: 18
key: join, value: 9
key: kafka, value: 27
key: summit, value: 9
```

無事に表示できたことが確かめられただろうか。

<!-- vim: set et tw=0 ts=2 sw=2: -->
