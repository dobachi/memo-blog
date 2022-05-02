---

title: Kafkaのログ周りの調査メモ
date: 2019-03-08 13:32:23
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka
  - ZooKeeper

---

# 参考

* [Apache Kafka Core Internals: A Deep Dive]
* [How Kafka’s Storage Internals Work]
* [Confluent Platform Quick Start (Docker)]
* [kafka-connect-twitter]

[Apache Kafka Core Internals: A Deep Dive]: https://www.confluent.io/thank-you/apache-kafka-core-internals-deep-dive/
[How Kafka’s Storage Internals Work]: https://thehoard.blog/how-kafkas-storage-internals-work-3a29b02e026
[Confluent Platform Quick Start (Docker)]: https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html
[kafka-connect-twitter]: https://github.com/jcustenborder/kafka-connect-twitter

# メモ

[How Kafka’s Storage Internals Work] にログファイルの中身の読み方が載っているので試してみる。

予め、 [kafka-connect-twitter] のKafka Connectコネクタを用い、Twitterデータを投入しておいた。


トピック（パーティション）の確認
```
$ ls /var/lib/kafka/data/twitter-status-0
00000000000000000000.index  00000000000000000000.log  00000000000000000000.timeindex  leader-epoch-checkpoint
```

インデックスの確認。
```
$ kafka-run-class kafka.tools.DumpLogSegments --deep-iteration --print-data-log --files /var/lib/kafka/data/twitter-status-0/00000000000000000000.index | head

Dumping /var/lib/kafka/data/twitter-status-0/00000000000000000000.index
offset: 1 position: 16674
offset: 2 position: 33398
offset: 3 position: 50562
offset: 4 position: 67801

(snip)
```

上記の通り、オフセットと位置が記載されている。

続いて、ログ本体の確認。
```
$ kafka-run-class kafka.tools.DumpLogSegments --deep-iteration --print-data-log --files /var/lib/kafka/data/twitter-status-0/00000000000000000000.log | head -n 4

Dumping /var/lib/kafka/data/twitter-status-0/00000000000000000000.log
Starting offset: 0
offset: 0 position: 0 CreateTime: 1552055018454 isvalid: true keysize: 239 valuesize: 16362 magic: 2 compresscodec: NONE producerId: -1 producerEpoch: -1 sequence: -1 isTransactional: false headerKeys: [] key: {"schema":{"type":"struct","fields":[{"type":"int64","optional":true,"field":"Id"}],"optional":false,"name":"com.github.jcustenborder.kafka.connect.twitter.StatusKey","doc":"Key for a twitter status."

(snip)

offset: 1 position: 16674 CreateTime: 1552055018465 isvalid: true keysize: 239 valuesize: 16412 magic: 2 compresscodec: NONE producerId: -1 producerEpoch: -1 sequence: -1 isTransactional: false headerKeys: [] key: {"schema":{"type":"struct","fields":[{"type":"int64","optional":true,"field":"Id"}],"optional":false,"name":"com.github.jcustenborder.kafka.connect.twitter.StatusKey","doc":"Key for a twitter status."},"payload":{"Id":1104024860143968257}

(snip)
```

```
$ kafka-run-class kafka.tools.DumpLogSegments --deep-iteration --print-data-log --files /var/lib/kafka/data/twitter-status-0/00000000000000000000.timeindex | head -n 10

Dumping /var/lib/kafka/data/twitter-status-0/00000000000000000000.timeindextimestamp: 1552055018465 offset: 1timestamp: 1552055529166 offset: 2timestamp: 1552055536284 offset: 3timestamp: 1552055626862 offset: 4timestamp: 1552055652086 offset: 5timestamp: 1552055717443 offset: 6timestamp: 1552055788403 offset: 7timestamp: 1552055789505 offset: 8

(snip)
```

