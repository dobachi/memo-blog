---

title: Apache Kafkaビルド時のエラー
date: 2019-06-28 10:13:33
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka

---

# 参考

* [Re: Kafka Trunk Build Failure with Gradle 5.0]

[Re: Kafka Trunk Build Failure with Gradle 5.0]: http://mail-archives.apache.org/mod_mbox/kafka-dev/201812.mbox/%3CCAHwHRrXN23vyHXz0OV2NKxN8yB7Ez8Ao3wf9WiEBfYFLmY43DA@mail.gmail.com%3E

# メモ

[Re: Kafka Trunk Build Failure with Gradle 5.0] に記載のように
Gradle 4系でエラーが出るようなので、いったん5系をインストールして実行し直した。
（現環境のUbuntuではaptインストールでのバージョンが4系だったので、
SDKMANを使って5系をインストールした）

Gradleのバージョンを上げたところ問題なく実行できた。
以下の通り。


```
$ gradle clients:test --tests org.apache.kafka.clients.producer.KafkaProducerTest
```

ここではGradleを使って、clientsサブプロジェクト以下の `org.apache.kafka.clients.producer.KafkaProducerTest` を実行する例である。
