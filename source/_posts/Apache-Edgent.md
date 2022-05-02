---

title: Apache Edgent
date: 2019-07-26 21:56:26
categories:
  - Knowledge Management
  - Stream Processing
  - Apache Edgent
tags:
  - Apache Edgent
  - Stream Processing

---

# 参考

* [Apache Edgent公式ウェブサイト]
* [Orientation in the fog: differences between stream processing in edge and cloud]
* [Apache Edgent Overview]
* [公式GitHub]
* [Getting Started]
* [The Power of Apache Edgent]
* [KafkaProducer]
* [FiltersのJavadoc]
* [JIRA]
* [fluentbit公式ウェブサイト]

[Apache Edgent公式ウェブサイト]: https://edgent.apache.org/
[Orientation in the fog: differences between stream processing in edge and cloud]: https://www.slideshare.net/JulianFeinauer/orientation-in-the-fog-differences-between-stream-processing-in-edge-and-cloud
[Apache Edgent Overview]: https://edgent.apache.org/docs/overview
[公式GitHub]: https://github.com/apache/incubator-edgent
[Getting Started]: https://edgent.apache.org/docs/edgent-getting-started.html
[The Power of Apache Edgent]: https://edgent.apache.org/docs/power-of-edgent
[KafkaProducer]: https://edgent.apache.org/javadoc/latest/index.html?org/apache/edgent/connectors/kafka/KafkaProducer.html
[FiltersのJavadoc]: https://edgent.apache.org/javadoc/latest/index.html?org/apache/edgent/analytics/sensors/Filters.html
[JIRA]: https://issues.apache.org/jira/projects/EDGENT/issues
[fluentbit公式ウェブサイト]: https://fluentbit.io/

# メモ

## 所感

[JIRA] や [公式GitHub] を見る限り、ここ最近活動量が低下しているように見える。
最後のコミットが2019年4月だったり、ここ最近のコミット量が低めだったり、とか。
まじめに使うとしたら注意が必要。

ストリーム処理をエッジデバイスで…という動機は興味深い。
ただし、「エッジで動かすための特別な工夫」が何なのかを把握できておらず、
ほかのシンプルなアーキテクチャと何が違うのか、はよく考えた方がよさそう。

例えばもしエッジで「データロード」を主軸とするならば、fluentbitがコンパクトでよいのではないか、という考えもあるだろう。
一方でストリーム処理の実装という観点では、Javaの内部DSL的であるEdgentのAPIは一定の嬉しさがあるのかもしれない。
思想として、Edgentは分析のような処理までエッジで行おうとしているようだが、fluentbitはあくまで「Log Processor and Forwarder」 [^fluentbit]
を担うものとしている点が異なると考えてよいだろう。（できる・できない、ではない）

Edgentはエッジで動かす、という割にはJavaで実装されており、
それなりにリッチなデバイス（RaspberyPiなど）を動作環境として想定しているように感じる。
プアなデバイスがリッチなデバイスの先につながっており、リッチなデバイスを経由して
ストリーム処理するイメージか。

ここではエッジデバイスも含めた、ストリーム処理を考える参考として調べる。

[^fluentbit]: [fluentbit公式ウェブサイト]

## 公式ドキュメント

[Apache Edgent公式ウェブサイト] によると以下の通り。

つまり、ゲートウェイやエッジデバイスで実行されるランタイムのようだ。
Raspberry Pisやスマートホンが例として挙げられている。

> Apache Edgent is a programming model and micro-kernel style runtime that can be embedded in gateways and small footprint edge devices enabling local, real-time, analytics on the continuous streams of data coming from equipment, vehicles, systems, appliances, devices and sensors of all kinds (for example, Raspberry Pis or smart phones). Working in conjunction with centralized analytic systems, Apache Edgent provides efficient and timely analytics across the whole IoT ecosystem: from the center to the edge.

### 概要を確認する

[Apache Edgent Overview] を確認する。
以下、ポイントを記載する。

エッジからデータセンタにすべてのデータを転送するのはコストが高すぎる。
Apache Edgent（以降Edgent）はエッジでのデータ、イベントの分析を可能にする。

Edgentを使うと、エッジ上で異常検知などを実現できる。
例えばエンジンが通常より熱い、など。
これを用いると通常時はデータセンタにデータを送らず、異常時にはデータを送るようにする、などの制御が可能。

ユースケースの例：

* IoT
  * エッジで分析することでNWトラフィックを減らす
* アプリケーションサーバに埋め込む
  * エラー検知をエッジで行ってNWトラフィックを減らす
* サーバマシンあるいはマシンルーム
  * ヘルスチェック。これもNWトラフィックを減らす。

動かせる場所：

* Java 8, including Raspberry Pi B and Pi2 B
* Java 7
* Android

★補足：
エッジデバイスとしてどの程度貧弱な環境で動かせるのか？はひとつポイントになるだろう。
ここではAndroidやRaspberry Piを挙げているので、エッジのマシンとしては強力な部類を想定しているように見える。
★補足おわり：

逆に、エッジでは処理しきれないケースで、データセンタにデータを送ることもできる。
例えば…

* CPUやメモリを使う複雑な処理
* 大きなステート管理
* 複数のデータソースを混ぜあわせる

など。
そのために、通信手段は複数に対応。

* MQTT
* IBM Watson IoT Platform
* Apache Kafka
* カスタム・メッセージバス


### Apache Edgentのケーパビリティ

[The Power of Apache Edgent] を確認する。

最初に載っていたサンプルは以下の通り。

```
public class ImpressiveEdgentExample {
  public static void main(String[] args) {
    DirectProvider provider = new DirectProvider();
    Topology top = provider.newTopology();

    IotDevice iotConnector = IotpDevice.quickstart(top, "edgent-intro-device-2");
    // open https://quickstart.internetofthings.ibmcloud.com/#/device/edgent-intro-device-2

    // ingest -> transform -> publish
    TStream<Double> readings = top.poll(new SimulatedTemperatureSensor(), 1, TimeUnit.SECONDS);
    TStream<JsonObject> events = readings.map(JsonFunctions.valueOfNumber("temp"));
    iotConnector.events(events, "readingEvents", QoS.FIRE_AND_FORGET);

    provider.submit(top);
  }
}
```

IBM Watson IoT Platformに接続する。
```
    IotDevice iotConnector = IotpDevice.quickstart(top, "edgent-intro-device-2");
```

#### Connectors, Ingest and Sink

イベント処理のアプリケーションは、外部からデータを読み込む（Ingest）のと、外部にデータを書き出す（Sink）が必要。
プリミティブなコネクタはすでに存在する。

もしMQTTを用いたいのだったら、上記サンプルの代わりに以下のようになる。
```
    MqttStreams iotConnector = new MqttStreams(top, "ssl://myMqttServer:8883", "my-device-client-id");
    iotConnector.publish(events, "readingEvents", QoS.FIRE_AND_FORGET, false);
```

同じように、対Kafkaだったら、KafkaPdocuer、KafkaConsumerというクラスがそれぞれ提供されている。

★補足：
しかし、 [KafkaProducer] のJavadocを見ると、以下のようなコメントが記載されている。

> The connector uses and includes components from the Kafka 0.8.2.2 release. It has been successfully tested against kafka_2.11-0.10.1.0 and kafka_2.11-0.9.0.0 server as well. For more information about Kafka see http://kafka.apache.org

これを見る限り、使用しているKafkaのバージョンが古い。念のために、masterブランチを確認したところ、
以下の通り、1.1.0が用いられているように見える。ドキュメントが古いのか…。

connectors/kafka/pom.xml:56

```
      <groupId>org.apache.kafka</groupId>
      <artifactId>kafka_2.12</artifactId>
      <version>1.1.0</version>
      <exclusions>
        <exclusion> <!-- not transitive -->
          <groupId>*</groupId>
          <artifactId>*</artifactId>
        </exclusion>
      </exclusions>
    </dependency>
```
★補足おわり：

そのほかにも、JdbcStreamsというクラスもあるようだ。

またFileStreamsを使うと、ディレクトリ配下のファイルの監視もできる。

例としては以下のようなものが載っていた。
```
   String watchedDir = "/some/directory/path";
   List<String> csvFieldNames = ...
   TStream<String> pathnames = FileStreams.directoryWatcher(top, () -> watchedDir, null);
   TStream<String> lines = FileStreams.textFileReader(pathnames);
   TStream<JsonObject> parsedLines = lines.map(line -> Csv.toJson(Csv.parseCsv(line), csvFieldNames));
```

directoryWatcherというメソッドを使い、トポロジを構成するようだ。
これがどの程度のものなのかは要確認。

★補足：

directoryWatcherはDirectoryWatcherのインスタンスを引数にとり、sourceメソッドを使って、
TStreamインスタンスを返す。

org/apache/edgent/connectors/file/FileStreams.java:108
```
    public static TStream<String> directoryWatcher(TopologyElement te,
            Supplier<String> directory, Comparator<File> comparator) {
        return te.topology().source(() -> new DirectoryWatcher(directory, comparator));
    }
```
DirectoryWatcherクラスでは、監視対象のディレクトリに追加されたファイルのファイル名を
リストとして管理し、そのリストからイテレータを生成して用いる。
WatcherIteratorクラスは以下のようになっている。
ここで、pendingNamesがファイル名のリスト。

org/apache/edgent/connectors/file/runtime/DirectoryWatcher.java:201
```
    private class WatcherIterator implements Iterator<String> {

        @Override
        public boolean hasNext() {
            return true;
        }

        @Override
        public String next() {

            for (;;) {

                String name = pendingNames.poll();
                if (name != null)
                    return name;
```

このリストの管理はとても簡易なものである。
一応、比較のためのComparatorは渡せるようになっているが、もしリストに載せた後にファイルが削除されたとしても、
それはこのDirectoryWatcherでは関知しないようだ。

★補足おわり：

そのほか、コマンドで監視したり…。STDOUT、STDINと連携したり、という例も載っている。

#### More on Ingest

複数のソースをひとつのストリームにする例が載っていた。

また、Edgentにおいてストリームの型は自由度が高く、カスタムの型も使える。
カスタムの方を使う例が載っている。

「Simulated Sensors」を見る限り、データソースのシミュレーションもある。動作確認用か？
またEdgent自身ではセンサーライブラリを手掛けない。

#### Filtering

Topologyでpollした後、以下のようにすることでフィルタを実現できる。
```
    readings = readings.filter(tuple -> tuple < 5d || tuple > 30d);
```

また、Filters#deadbandメソッドを用いると、より細かな（便利な？）フィルタを用いることができるようだ。
このあたり

★補足：

[FiltersのJavadoc] の deadband メソッドの説明を見ると、図が掲載されている。
まず線が引かれているのが「deadband」であり、基本的にはその中に含まれたポイントはフィルタされる。
ただし、「最初のポイント」、「deadbandに入った『最初のポイント』」はフィルタされない。

これは、deadbandに入った瞬間の時刻をトレースする、などのユースケースにおいて有用と考える。
（deadbandに入った最初のポイントもフィルタしてしまうと、それが分からなくなってしますため）

★補足おわり：

#### Split

ストリームを分割可能。

#### Transforms

mapメソッドでデータ変換可能。
特に分散処理でもないので、ふつうに任意の処理を書けばよいだけ。

★補足：Sparkのようにシリアライゼーション周りで悩まされることは少なそうだ

#### Windowing and aggregation

ウィンドウにも対応。
直近10レコード、直近10秒、などの単位で集計可能。

このウィンドウは、ウィンドウがいっぱいになるまではaggregateされないようだ。

★補足：

以下のようなイメージか。

![ウィンドウのイメージ](/memo-blog/images/RjG2l2Z9zepfpYP3-00D60.png)

★補足おわり：

#### Misc

PlumbingStreams#parallelを使うと、並列処理化できるようだ。
ストリームのタプルを分割して、マルチスレッドで処理する感じだろうか。★要確認

### Getting Started

[Getting Started] を確認する。

#### Apache Edgent and streaming analytics

Edgentの基本要素は、ストリームである。
ストリームは、ローカルデバイスの制御という形で終わったり、外部出力されたりして終わる。

処理は関数のような形で表現される。Java8のlambdaみたいな感じ。

```
reading -> reading < 50 || reading > 80
```

基本的なフローは以下の通り。

```
* プロバイダを定義
* トポロジを定義し、処理グラフを定義
* 処理を実行
```

複数のトポロジからなることもあり、ほかのアプリケーションから呼び出されて実行するというケースも想定される。

（あとは、Getting Startedにはフィルタの仕方など、基本的なAPIの使い方が紹介されている。）

## GitHubで確認

### 開発言語

[公式GitHub] によると、開発言語としてはJavaが90.9%だった。（2019/7/28現在）

![開発言語の様子](/memo-blog/images/RjG2l2Z9zepfpYP3-36756.png)

Javaで作られているということは、やはりエッジといえど、それなりにリッチなものを想定していることがわかる。

## 公式ウェブサイトで紹介されていたスライドシェアを確認

[Orientation in the fog: differences between stream processing in edge and cloud] を確認する。

Industrial IoTについて。
そもそも産業界はコンサバである。

機器はPLCで制御される。
参考：Apache PLC4X

Industrial IoTの現場で登場する要素：PLC、センサー、アクター

イベントは区切られずに生成される。
時系列のイベントを取り出すためには、閾値、何らかのトリガ等々で区切る必要がある。
そこで、エッジでのストリーム処理。

ここからいくつかの例。

* サイクル検知の例。シンプルな実装に始まり、後から「あ、実はジッターがあって…」などの
  要件が足されていく。そして実装がきたなくなっていく…。
* エラーロギングの例。2300bitのビットマスクを確認し、適切な例外を上げる。
* 複雑なアクションの例。あるビットが送られてくるまで待ちアクションを取り、別のビットを待ち…の連続。

クラウドとエッジにおけるストリーム処理の違いにも触れられている。

![クラウドとエッジの違い](/memo-blog/images/JS32Z8bqn1VvtMUB-D522B.png)

この図でいう、「Fast」がエッジで「Easy」となっているのはよくわからない。

宣言的な表現へ。
CRUNCHの紹介。
https://github.com/pragmaticminds/crunch

ラムダアーキテクチャをエッジで…？

Apache Edgent。

以下のランタイムを有する。

* ストリーム処理
* リアルタイム分析
* クラウドとの通信

以上をエッジで行う。

エッジtoクラウドのソリューションもある。
しかし、これらは最初の障壁は低いが、ベンダ手動でロックイン。

そこでApache Edgentがある。
オープンソースでベンダーフリー。
ほかのApacheプロジェクトと連携。例えば、Apache PLC4X、IoTDBなど。
将来的には…

* さらにクラウド接続を充実させる。
* CRUNCHとの連携
* エッジインテグレーションパターン（？）
* ルーティング/ルールエンジンの充実

<!-- vim: set tw=0 ts=4 sw=4: -->
