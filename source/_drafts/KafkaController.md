---

title: KafkaController
date: 2019-11-09 22:07:38
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka

---

# 参考

* [A Deep Dive into Kafka Controller]
* [KAFKA-5027]

[A Deep Dive into Kafka Controller]: https://www.slideshare.net/ConfluentInc/a-deep-dive-into-kafka-controller
[KAFKA-5027]: https://issues.apache.org/jira/browse/KAFKA-5027


# メモ

## 基本的なデザインについて

前提として、Jun Raoの [A Deep Dive into Kafka Controller] が参考になる。
基本的な考え方は変わっていないのだが、性能やゾンビ化したControllerへの対応改善が行われた。（バージョン1.1、2.1あたり）
詳しい改善内容は、 アンブレラチケット [KAFKA-5027] から辿れる。

## 実装の様子

2019/11/09時点のmasterブランチで確認した。

### ControllerContext

Controllerが管理すべき情報を一手に担っている。

kafka/controller/KafkaController.scala:78
```
  val controllerContext = new ControllerContext
```

メンバ変数は以下の通り。

* stats
* offlinePartitionCount
* shuttingDownBrokerIds
* liveBrokers
* liveBrokerEpochs
* epoch
* epochZkVersion
* allTopics
* partitionAssignments
* partitionLeadershipInfo
* partitionsBeingReassigned
* partitionStates
* replicaStates
* replicasOnOfflineDirs
* topicsToBeDeleted
* topicsWithDeletionStarted
* topicsIneligibleForDeletion

トピック、パーティションアサインメント、パーティションのリーダシップ情報、レプリカのステータスなど。


<!-- vim: set tw=0 ts=4 sw=4: -->
