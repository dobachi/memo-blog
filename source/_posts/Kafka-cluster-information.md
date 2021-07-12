---
title: Kafka cluster information
date: 2019-11-05 23:55:22
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka

---

# 参考


# メモ

kafka.clusterパッケージ以下には、Kafkaクラスタの情報を格納するためのクラス群が存在している。
具体的には以下の通り。

* Broker
* BrokerEndPoint
* Cluster
* EndPoint
* Partition.scala
* Replica

## 例としてBroker

例えば `Broker` クラスについて。

case classである。

usageを確認すると、例えば以下のように `KafkaServer#createBrokerInfo` メソッド内で用いられている。

kafka/server/KafkaServer.scala:430
```
    BrokerInfo(Broker(config.brokerId, updatedEndpoints, config.rack), config.interBrokerProtocolVersion, jmxPort)
```

## その他

わかりやすい例だと、PartitionやReplicaなどが挙げられる。



<!-- vim: set tw=0 ts=4 sw=4: -->
