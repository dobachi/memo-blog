---

title: Kafkaのグレースフルシャットダウン
date: 2019-03-13 22:29:42
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka
  - Graceful Shutdown

---

# 参考

* [Graceful Shutdownに関する公式ドキュメントの記述]

[Graceful Shutdownに関する公式ドキュメントの記述]: https://kafka.apache.org/documentation/#basic_ops_restarting

# メモ

## 公式ドキュメント

[Graceful Shutdownに関する公式ドキュメントの記述]によると、グレースフルシャットダウンの強みは以下の通り。

* ログリカバリ処理をスキップする
* シャットダウンするブローカから予めリーダを移動する

## 実装確認

以下のあたりから、グレースフルシャットダウンの実装。

kafka/server/KafkaServer.scala:422

```
  private def controlledShutdown() {

    def node(broker: Broker): Node = broker.node(config.interBrokerListenerName)

(snip)
```

コントローラを取得して接続し、コントローラに対してグレースフルシャットダウンの依頼を投げる。
なお、本メソッドはKafkaServer#shutdownメソッド内で呼び出される。

なお、当該メソッドは（KafkaServerStartableクラスでラップされているが）シャットダウンフックで適用される。

kafka/Kafka.scala:70
```
      // attach shutdown handler to catch terminating signals as well as normal termination
      Runtime.getRuntime().addShutdownHook(new Thread("kafka-shutdown-hook") {
        override def run(): Unit = kafkaServerStartable.shutdown()
      })
```
