---

title: Example application of Structured Streaming and Delta Lake
date: 2020-11-28 21:54:21
categories:
  - Knowledge Management
  - Storage Layer
  - Delta Lake
tags:
  - Spark
  - Structured Streaming
  - Delta Lake

---

# 参考

* [Table streaming reads and writes]
* [Open Images Dataset V6]
* [cp-all-in-one]
* [Confluent Platformのバージョン情報]
* [Apache Kafkaのクイックスタート]
* [Apache KafkaのExample]
* [dobachiのStructuredStreamingDeltaLakeExample]
* [Kafka Streamsのチュートリアル]
* [kafka-streams]
* [KafkaのScala DSL]

[Table streaming reads and writes]: https://docs.delta.io/latest/delta-streaming.html#ignore-updates-and-deletes
[Open Images Dataset V6]: https://storage.googleapis.com/openimages/web/download.html
[cp-all-in-one]: https://github.com/confluentinc/cp-all-in-one
[Confluent Platformのバージョン情報]: https://docs.confluent.io/platform/current/installation/versions-interoperability.html#cp-and-apache-ak-compatibility
[Apache Kafkaのクイックスタート]: https://kafka.apache.org/documentation/#quickstart
[Apache KafkaのExample]: https://github.com/apache/kafka/tree/trunk/examples
[dobachiのStructuredStreamingDeltaLakeExample]: https://github.com/dobachi/StructuredStreamingDeltaLakeExample
[Kafka Streamsのチュートリアル]: https://kafka.apache.org/26/documentation/streams/tutorial
[kafka-streams]: https://github.com/dobachi/kafka-streams.g8
[KafkaのScala DSL]: https://kafka.apache.org/26/documentation/streams/developer-guide/dsl-api.html#scala-dsl
[stream-data-generator]: https://github.com/dobachi/stream-data-generator


# メモ


## コンセプト

[Table streaming reads and writes] を参考に、ストリーム処理および分析の例を作ってみる。

大まかなシナリオは以下の通り。

### シナリオ概要

* 簡単なデータ処理と格納
  * ジェネレータからID、画像（JPEG）のペアを生成し、Kafkaに書き込み
  * Kafkaからレコードを読み取り、OpenCVで処理し、Delta Lakeに書き込む
* 機械学習を応用

### （補足）使うデータセット

[Open Images Dataset V6] から取得したデータを利用することにする。

```
$ mkdir ~/Downloads
$ cd ~/Downloads
```

ImageIDとラベルのダウンロード

```
$ wget https://storage.googleapis.com/openimages/v6/oidv6-train-annotations-human-imagelabels.csv
```

ImageIDと画像説明のダウンロード

```shell
$ wget https://storage.googleapis.com/openimages/v6/oidv6-train-images-with-labels-with-rotation.csv
```

ラベル名称のダウンロード

```
$ wget https://storage.googleapis.com/openimages/v6/oidv6-class-descriptions.csv
```

画像のダウンロードと展開

```shell
$ aws s3 --no-sign-request cp s3://open-images-dataset/tar/train_f.tar.gz train_f.tar.gz
$ tar xvzf train_f.tar.gz
```

ひとまず試しにデータを一つ確認してみる。
上記画像データに含まれていた、`f6ffd53184f58758.jpg` （ImageID: f6ffd53184f58758）を確認する。

WSL2であれば、以下のように画像を開き、確認する。

```shell
$ wslview train_f/f6ffd53184f58758.jpg
```

今回はグラスの画像だった。

この画像についているラベルを確認する。

```shell
$ grep f6ffd53184f58758 oidv6-train-annotations-human-imagelabels.csv
f6ffd53184f58758,verification,/m/024g6,1
f6ffd53184f58758,verification,/m/0271t,1
f6ffd53184f58758,verification,/m/09tvcd,1
f6ffd53184f58758,crowdsource-verification,/m/06qrr,1
```

ここではラベルが、

* /m/024g6
* /m/0271t
* /m/09tvcd
* /m/06qrr

であるということから、そのラベルの名称を確認すると・・・

```shell
$ grep /m/024g6 oidv6-class-descriptions.csv
/m/024g6,Cocktail
$ grep /m/0271t oidv6-class-descriptions.csv
/m/0271t,Drink
$ grep /m/09tvcd oidv6-class-descriptions.csv
/m/09tvcd,Wine glass
$ grep /m/06qrr oidv6-class-descriptions.csv
/m/06qrr,Soft drink
```

ということらしい。

では、反対に、ラベル `/m/024g6` を持つ画像を探してみる。
今回は、ImageIDがfで始まる画像をダウンロードしたので、以下のように探す。


```shell
$ grep 024g6 oidv6-train-annotations-human-imagelabels.csv  | grep -e "^f" | head
f00bb28aba61d308,verification,/m/024g6,0
f00bc68e260e3bfa,verification,/m/024g6,1
f011ed94e450c417,verification,/m/024g6,1
f026bd7f2fa415e8,verification,/m/024g6,1
f056ff09e073987c,verification,/m/024g6,1
f05c7d2e2dedb7fd,verification,/m/024g6,1
f0606ccf61c7e266,verification,/m/024g6,0
f0a8d04cb5dc5348,verification,/m/024g6,1
f0c9fc1f1a6d3503,verification,/m/024g6,0
f0cd8b2ff2677622,verification,/m/024g6,1

$ wslview train_f/f05c7d2e2dedb7fd.jpg
```

カクテルに関する画像が取得できただろうか。

## 簡単なデータ処理と格納

### 補足）DockerでKafka起動

ここでは、 [cp-all-in-one] を用いてKafkaを起動する。
[cp-all-in-one] はConfluent社が公開したDockerでConfluent Platformを立ち上げるためのdocker-composeファイルである。

```shell
$ cd cp-all-in-one
$ git checkout 6.0.1-post
$ cd cp-all-in-one
$ sudo docker-compose up -d
```

参考として、 [Confluent Platformのバージョン情報] の通り、2.6.1である。

簡単に動作確認する。
ブローカのコンテナにつなぎ、[Apache Kafkaのクイックスタート] の通り、動作確認する。

```shell
$ sudo docker exec -it broker bash
[appuser@broker ~]$ kafka-topics --zookeeper zookeeper:2181 --list  # トピックをリスト
[appuser@broker ~]$ kafka-topics --create --topic quickstart-events --bootstrap-server broker:9092
[appuser@broker ~]$ kafka-console-producer --topic quickstart-events --bootstrap-server broker:9092
>hoge
>hoge
>fuga
[appuser@broker ~]$ kafka-console-consumer --topic quickstart-events --from-beginning --bootstrap-server broker:9092
hoge
hoge
fuga
```

### 補足）Apache Kafkaサイトからダウンロードして起動

上記はConfluentのDockerイメージを利用する場合だったが、Apache Kafkaの公式サイトからパッケージをダウンロードして起動することもできる。
詳しくは、 [Apache Kafkaのクイックスタート] を参照。

以降は、こちらの方法を用いてKafkaをダウンロード、配備し、起動したものとする。

### 補足）Kafkaへの書き込みの動作確認

ひとまず、 [kafka-streams] を利用してテンプレートからプロジェクトを生成する。

```shell
$ sbt new dobachi/kafka-streams.g8
[info] welcome to sbt 1.3.13 (Private Build Java 1.8.0_265)
[info] set current project to sources (in build file:/home/dobachi/Sources/)
[info] set current project to sources (in build file:/home/dobachi/Sources/)

Streaming App

name [Kafka Streams Scala Application]: Stream Data Generator
organization [com.example]:
package [com.example.streamdatagenerator]: com.example.sdg

Template applied in /home/dobachi/Sources/./stream-data-generator
```

これに、 [KafkaのScala DSL] を参考に実装したアプリケーションを実装、実行する。

のだが、今回は実装済みのパッケージが [stream-data-generator] にある。
ひとまずKafkaの動作確認用にただのWordCountを動かす。

```shell
$ mkdir ~/Sources
$ cd ~/Sources
$ git clone --recursive https://github.com/dobachi/stream-data-generator.git
$ cd stream-data-generator
```

もしsbt環境がなければ、セットアップする。

```shell
$ ./bin/setup.sh
```

sbt環境がある場合、以下の通りビルドして実行する。

```shell
$ sbt clean assembly
$ java -cp target/scala-2.13/StreamDataGenerator-assembly-0.1.0-SNAPSHOT.jar com.example.sdg.WordCount
```

もうひとつターミナルを立ち上げ、Console Consumerを使って単語を書き込む。
ここでは、

```shell
$ ./bin/kafka-console-producer.sh --topic input-topic --bootstrap-server localhost:9092
> hoge
> hoge
> fuga
```

Console Producerを止め、書き込まれた内容を確認するため、Console Consumerを起動する。

```shell
$ ./bin/kafka-console-consumer.sh --topic streams-wordcount-output --bootstrap-server localhost:9092 --from-beginning --property print.key=true --value-deserializer "org.apache.kafka.common.serialization.LongDeserializer"
```

集計された値が表示されただろうか？

### 

<!-- vim: set et tw=0 ts=2 sw=2: -->
