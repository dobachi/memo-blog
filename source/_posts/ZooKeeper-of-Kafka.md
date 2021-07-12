---

title: Apache KafkaにおけるZooKeeper
date: 2019-03-05 22:03:17
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka
  - ZooKeeper

---

# 参考
* [kafka-docker]

[kafka-docker]: http://wurstmeister.github.io/kafka-docker/

# メモ

## 前提

* [kafka-docker] を使って環境を立てた
* docker-compose.yml内で環境変数で指定し、ZooKeeperじょうでは、
  /kafka以下のパスを用いるようにした。
* いったんtrunkで確認

## ZooKeeperには何が置かれるのか？

実機で確認してみる。

```
bash-4.4# zookeeper-shell.sh zookeeper:2181
Connecting to zookeeper:2181
```

```
ls /kafka
[log_dir_event_notification, isr_change_notification, admin, consumers, cluster, config, latest_producer_id_block, controller, brokers, controller_epoch]
```

トピック準備

```
bash-4.4#  kafka-topics.sh --create --topic topic --partitions 1 --zookeeper zookeeper:2181/kafka --replication-factor 1

bash-4.4# kafka-topics.sh --topic topic --zookeeper zookeeper:2181/kafka --describeTopic:topic     PartitionCount:1        ReplicationFactor:1     Configs:
        Topic: topic    Partition: 0    Leader: 1001    Replicas: 1001  Isr: 1001

bash-4.4# kafka-console-producer.sh --topic=topic --broker-list=kafka:9092
>hoge
>fuga
>hoge
>fuga

bash-4.4# kafka-console-consumer.sh --bootstrap-server kafka:9092 --from-beginning --topic topic
hoge
fuga
hoge
fuga
```

### log_dir_event_notification

handleLogDirFailureメソッド内でオフラインとなったディレクトリを取り扱うために用いられる。

kafka/server/ReplicaManager.scala:203
```
  private class LogDirFailureHandler(name: String, haltBrokerOnDirFailure: Boolean) extends ShutdownableThread(name) {
    Override def doWork() {
      val newOfflineLogDir = logDirFailureChannel.takeNextOfflineLogDir()
      if (haltBrokerOnDirFailure) {
        fatal(s"Halting broker because dir $newOfflineLogDir is offline")
        Exit.halt(1)
      }
      handleLogDirFailure(newOfflineLogDir)
    }
  }
```

### isr_change_notification


ISRに変化があったことを確認する。

kafka/server/ReplicaManager.scala:269
```
  def maybePropagateIsrChanges() {
    val now = System.currentTimeMillis()
    isrChangeSet synchronized {
      if (isrChangeSet.nonEmpty &&
        (lastIsrChangeMs.get() + ReplicaManager.IsrChangePropagationBlackOut < now ||
          lastIsrPropagationMs.get() + ReplicaManager.IsrChangePropagationInterval < now)) {
        zkClient.propagateIsrChanges(isrChangeSet)
        isrChangeSet.clear()
        lastIsrPropagationMs.set(now)
      }
    }
  }
```

### brokers

以下のように、ブローカに関するいくつかの情報を保持する。
```
ls /kafka/brokers
[seqid, topics, ids]
```

例えば、ブローカ情報を記録するのは以下の通り。

kafka/zk/KafkaZkClient.scala:95
```
  def registerBroker(brokerInfo: BrokerInfo): Long = {
    val path = brokerInfo.path
    val stat = checkedEphemeralCreate(path, brokerInfo.toJsonBytes)
    info(s"Registered broker ${brokerInfo.broker.id} at path $path with addresses: ${brokerInfo.broker.endPoints}, czxid (broker epoch): ${stat.getCzxid}")
    stat.getCzxid
  }
```

例えば、トピック・パーティション情報は以下の通り。

```
get /kafka/brokers/topics/topic/partitions/0/state
{"controller_epoch":1,"leader":1001,"version":1,"leader_epoch":0,"isr":[1001]}
```

### controller

例えば、コントローラ情報は以下の通り。

```
get /kafka/controller
{"version":1,"brokerid":1001,"timestamp":"1551794212551"}
```

KafkaZKClient#registerControllerAndIncrementControllerEpochメソッドあたり。

### updateLeaderAndIsrメソッド

リーダとISRの情報を受けとり、ZooKeeper上の情報を更新する。

### getLogConfigsメソッド

ローカルのデフォルトの設定値と、ZooKeeper上のトピックレベルの設定値をマージする。

### setOrCreateEntityConfigsメソッド

トピックを作成する際に呼ばれるメソッドだが、これ自体は何かロックを取りながら、
トピックの情報を編集するわけではないようだ。★要確認
したがって、同じトピックを作成する処理が同時に呼ばれた場合、後勝ちになる。

ただしトピックが作成された後は、トピック作成時に当該トピックが存在するかどうかの確認が行われるので問題ない。

kafka/zk/AdminZkClient.scala:101
```
  def validateTopicCreate(topic: String,
                          partitionReplicaAssignment: Map[Int, Seq[Int]],
                          config: Properties): Unit = {
```

kafka/server/AdminManager.scala:109
```
        createTopicPolicy match {
          case Some(policy) =>
            adminZkClient.validateTopicCreate(topic.name(), assignments, configs)
```

### BrokerのEpochについて

以下の通り、BrokerのEpochとしては、ZooKeeperのznodeのcZxid（※）が用いられる。

※znodeの作成に関するZooKeeper Transaction ID

kafka/zk/KafkaZkClient.scala:417
```
  def getAllBrokerAndEpochsInCluster: Map[Broker, Long] = {
    val brokerIds = getSortedBrokerList
    val getDataRequests = brokerIds.map(brokerId => GetDataRequest(BrokerIdZNode.path(brokerId), ctx = Some(brokerId)))
    val getDataResponses = retryRequestsUntilConnected(getDataRequests)
    getDataResponses.flatMap { getDataResponse =>
      val brokerId = getDataResponse.ctx.get.asInstanceOf[Int]
      getDataResponse.resultCode match {
        case Code.OK =>
          Some((BrokerIdZNode.decode(brokerId, getDataResponse.data).broker, getDataResponse.stat.getCzxid))
        case Code.NONODE => None
        case _ => throw getDataResponse.resultException.get
      }
    }.toMap
  }
```

### getAllLogDirEventNotificationsメソッド

ログディレクトリの変化に関する情報を取得する。
コントローラのイベントハンドラ内で、呼び出されるLogDirEventNotification#processメソッドで用いられる。
何か変化のあったログ（ディレクトリ）を確認し、当該ログを保持するブローカのレプリカの情報を最新化する。★要確認

### setOrCreatePartitionReassignmentメソッド

パーティションリアサインメントの情報をZooKeeperに書き込む。
このメソッドは、パーティションリアサインメントの必要があるときに呼び出される。
例えばコントローラフェールオーバ時などにも呼び出される。
