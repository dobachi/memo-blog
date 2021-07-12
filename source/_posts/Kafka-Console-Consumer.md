---

title: Kafkaコンソールコンシューマを起点とした確認
date: 2019-06-23 23:03:33
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka

---

# 参考

# メモ

2019/6/23時点でのtrunkで再確認した内容。
ほぼ昔のメモのままコピペ・・・。

## ConsoleConsumer

コンシューマの実装を確認するにあたっては、コンソール・コンシューマが良いのではないか。

bin/kafka-console-consumer.sh:21
```
exec $(dirname $0)/kafka-run-class.sh kafka.tools.ConsoleConsumer "$@"
```

から、 kafka.tools.ConsoleConsumer クラスあたりを確認すると良いだろう。

mainを確認すると、ConsumerConfigのインスタンスを生成し、runメソッドに渡すことがわかる。

core/src/main/scala/kafka/tools/ConsoleConsumer.scala:54
```
    val conf = new ConsumerConfig(args)
    try {
      run(conf)
```

ここで、ConsumerConfigはコンソールからパラメータを受け取るためのクラス。
実態はrunメソッドである。

まず大事な箇所として、 KafkaConsumer クラスのインスタンスを生成している箇所がある。 ★

core/src/main/scala/kafka/tools/ConsoleConsumer.scala:67
```
    val consumer = new KafkaConsumer(consumerProps(conf), new ByteArrayDeserializer, new ByteArrayDeserializer)
```

この KafkaConsumer クラスがコンシューマの実態である。
なお、コンソール・コンシューマでは、これをラップした便利クラス ConsumerWrapper が定義されており、
そちらを通じて主に使う。

またシャットダウンフックを定義している。

core/src/main/scala/kafka/tools/ConsoleConsumer.scala:75
```
    addShutdownHook(consumerWrapper, conf)
```

core/src/main/scala/kafka/tools/ConsoleConsumer.scala:87
```
  def addShutdownHook(consumer: ConsumerWrapper, conf: ConsumerConfig) {
    Runtime.getRuntime.addShutdownHook(new Thread() {
      override def run() {
        consumer.wakeup()

        shutdownLatch.await()

        if (conf.enableSystestEventsLogging) {
          System.out.println("shutdown_complete")
        }
      }
    })
  }
```

これはグレースフルにシャットダウンするには大切。 ★

またデータ処理の実態は、以下の process メソッドである。

core/src/main/scala/kafka/tools/ConsoleConsumer.scala:77
```
    try process(conf.maxMessages, conf.formatter, consumerWrapper, System.out, conf.skipMessageOnError)
```

core/src/main/scala/kafka/tools/ConsoleConsumer.scala:101
```
  def process(maxMessages: Integer, formatter: MessageFormatter, consumer: ConsumerWrapper, output: PrintStream,
              skipMessageOnError: Boolean) {

  (snip)
```

処理するメッセージ最大数、出力ストリームに渡す形を整形するメッセージフォーマッタ、コンシューマのラッパ、出力ストリーム、
エラーのときに呼び飛ばすかどうかのフラグが渡される。

少し処理の中身を確認する。
まず以下のようにメッセージを取得する。

core/src/main/scala/kafka/tools/ConsoleConsumer.scala:104
```
      val msg: ConsumerRecord[Array[Byte], Array[Byte]] = try {
        consumer.receive()

  (snip)
```

上記の receive は、先程の通り、ラッパーのreceiveメソッドである。

receiveメソッドは以下のようにコンシューマのポール機能を使い、
メッセージを取得する。

core/src/main/scala/kafka/tools/ConsoleConsumer.scala:437
```
    def receive(): ConsumerRecord[Array[Byte], Array[Byte]] = {
      if (!recordIter.hasNext) {
        recordIter = consumer.poll(Duration.ofMillis(timeoutMs)).iterator
        if (!recordIter.hasNext)
          throw new TimeoutException()
      }

      recordIter.next
    }
```

メッセージを取得するためのイテレータが得られるので、nextメソッドで取得する。
→イテレータのnextを使って１件ずつ取り出していることがわかる。 ★

続いて、取り出されたメッセージを ConsumerRecord 化してフォーマッタに渡す。
　
core/src/main/scala/kafka/tools/ConsoleConsumer.scala:118
```
        formatter.writeTo(new ConsumerRecord(msg.topic, msg.partition, msg.offset, msg.timestamp,
                                             msg.timestampType, 0, 0, 0, msg.key, msg.value, msg.headers), output)
```

これにより出力が確定する。

## KafkaConsumer

つづいて、KafkaConsumerクラスを確認する。

### トピックアサイン

ここではトピックへの登録を確認する。 ★

コンシューマグループを使って自動で行うアサインメントを使用する場合。リバランスも行われる。

clients/src/main/java/org/apache/kafka/clients/consumer/KafkaConsumer.java:936
```
    public void subscribe(Collection<String> topics, ConsumerRebalanceListener listener) {

  (snip)
```

上記はトピックのコレクションを渡すメソッドだが、パターンを指定する方法もある。

clients/src/main/java/org/apache/kafka/clients/consumer/KafkaConsumer.java:1008
```
    public void subscribe(Pattern pattern, ConsumerRebalanceListener listener) {

  (snip)
```

なお、何らかの理由（詳しくはJavadoc参照）により、リバランスが必要になったら、
第2引数に渡されているリスナがまず呼び出される。

コンシューマ・グループを利用せず、手動で行うアサインメントの場合は以下の通り。

clients/src/main/java/org/apache/kafka/clients/consumer/KafkaConsumer.java:1083
```
    public void assign(Collection<TopicPartition> partitions) {
```

いずれの場合も内部的には SubscriptionState が管理のために用いられる。
タイプは以下の通り。
clients/src/main/java/org/apache/kafka/clients/consumer/internals/SubscriptionState.java:72
```
    private enum SubscriptionType {
        NONE, AUTO_TOPICS, AUTO_PATTERN, USER_ASSIGNED
    }
```

またコンシューマの管理を行う ConsumerCoordinator には、 updatePatternSubscription メソッドがある。

org/apache/kafka/clients/consumer/internals/ConsumerCoordinator.java:192
```
    public void updatePatternSubscription(Cluster cluster) {
        final Set<String> topicsToSubscribe = cluster.topics().stream()
                .filter(subscriptions::matchesSubscribedPattern)
                .collect(Collectors.toSet());
        if (subscriptions.subscribeFromPattern(topicsToSubscribe))
            metadata.requestUpdateForNewTopics();
    }
```

matchesSubscribedPattern を用いて、現在クラスタが抱えているトピックの中から、
サブスクライブ対象のトピックをフィルタして取得し、SubscriptionState#subscribeFromPattern メソッドを呼ぶ。
これにより、当該コンシューマの購読するトピックが更新される。
この更新はいくつかのタイミングで発動するが、例えば KafkaConsumer#poll(java.time.Duration) の
中で呼ばれる updateAssignmentMetadataIfNeeded メソッドを通じて呼び出される。

### コンシューマ故障の検知

基本的にはハートビート（ heartbeat.interval.ms で設定）が session.timeout.ms を
超えて届かなくなると、故障したとみなされる。
その結果、当該クライアント（この場合はコンシューマ）がグループから外され、
リバランスが起きる。

なお、ハートビートはコーディネータに対して送られる。
コーディネータは以下のように定義されている。
org/apache/kafka/clients/consumer/internals/AbstractCoordinator.java:128
```
    private Node coordinator = null;
```

org/apache/kafka/clients/consumer/internals/AbstractCoordinator.java:692
```
                    AbstractCoordinator.this.coordinator = new Node(
                            coordinatorConnectionId,
                            findCoordinatorResponse.data().host(),
                            findCoordinatorResponse.data().port());
```

AbstractCoordinator#sendFindCoordinatorRequest メソッドが呼ばれる契機は複数あるが、
例えば、コンシューマがポールするときなどにコーディネータが更新される。

なお、コーディネータにクライアントを登録する際、
セッションタイムアウトの値も渡され、対応される。
予め定められた group.min.session.timeout.ms や group.max.session.timeout.ms を満たす
セッションタイムアウトが用いられる。

セッションタイムアウトの値は、例えば以下のように設定される。

kafka/coordinator/group/GroupCoordinator.scala:146
```
              doJoinGroup(group, memberId, groupInstanceId, clientId, clientHost, rebalanceTimeoutMs, sessionTimeoutMs, protocolType, protocols, responseCallback)
```

この値は、最終的に MemberMetadata に渡されて用いられる。
例えばハートビートのデッドラインの計算などに用いられることになる。

kafka/coordinator/group/MemberMetadata.scala:56
```
private[group] class MemberMetadata(var memberId: String,
                                    val groupId: String,
                                    val groupInstanceId: Option[String],
                                    val clientId: String,
                                    val clientHost: String,
                                    val rebalanceTimeoutMs: Int,
                                    val sessionTimeoutMs: Int,
                                    val protocolType: String,
                                    var supportedProtocols: List[(String, Array[Byte])]) {
```
