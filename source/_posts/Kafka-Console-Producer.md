---

title: Kafkaコンソールプロデューサを起点とした確認
date: 2019-06-26 21:43:58
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka

---

# 参考

* [Confluentのトランザクションに関する説明]

[Confluentのトランザクションに関する説明]: https://www.confluent.io/blog/transactions-apache-kafka/

# メモ

2019/6/23時点でのtrunkで再確認した内容。
ほぼ昔のメモのままコピペ・・・。

## ConsoleProducer

エントリポイントとして、Kafkaのコンソールプロデューサを選ぶ。

bin/kafka-console-producer.sh:20
```
exec $(dirname $0)/kafka-run-class.sh kafka.tools.ConsoleProducer "$@"
```

コンソールプロデューサの実態は、KafkaProducerである。

kafka/tools/ConsoleProducer.scala:45
```
        val producer = new KafkaProducer[Array[Byte], Array[Byte]](producerProps(config))
```

なお、 ConsoleProducerにはsendメソッドが定義されており、
以下のように標準入力からデータを読み出してはメッセージを送信する、を繰り返す。

kafka/tools/ConsoleProducer.scala:54
```
        do {
          record = reader.readMessage()
          if (record != null)
            send(producer, record, config.sync)
        } while (record != null)
```

kafka/tools/ConsoleProducer.scala:70
```
  private def send(producer: KafkaProducer[Array[Byte], Array[Byte]],
                         record: ProducerRecord[Array[Byte], Array[Byte]], sync: Boolean): Unit = {
    if (sync)
      producer.send(record).get()
    else
      producer.send(record, new ErrorLoggingCallback(record.topic, record.key, record.value, false))
  }
```

## KafkaProducer

それでは実態であるKafkaProducerを確認する。

### コンストラクタを確認する

まずクライアントのIDが定義される。

org/apache/kafka/clients/producer/KafkaProducer.java:332
```
            String clientId = config.getString(ProducerConfig.CLIENT_ID_CONFIG);
            if (clientId.length() <= 0)
                clientId = "producer-" + PRODUCER_CLIENT_ID_SEQUENCE.getAndIncrement();
            this.clientId = clientId;
```

続いてトランザクションIDが定義される。

org/apache/kafka/clients/producer/KafkaProducer.java:337
```
            String transactionalId = userProvidedConfigs.containsKey(ProducerConfig.TRANSACTIONAL_ID_CONFIG) ?
                    (String) userProvidedConfigs.get(ProducerConfig.TRANSACTIONAL_ID_CONFIG) : null;
```

Kafkaのトランザクションについては、 [Confluentのトランザクションに関する説明] を参照。

その後、ログ設定、メトリクス設定、キー・バリューのシリアライザ設定。
その後、各種設定値を定義する。

特徴的なところとしては、メッセージを送信するときにメッセージをいったんまとめこむ accumulator も
このときに定義される。

org/apache/kafka/clients/producer/KafkaProducer.java:396
```
            this.accumulator = new RecordAccumulator(logContext,
                    config.getInt(ProducerConfig.BATCH_SIZE_CONFIG),
                    this.compressionType,
                    lingerMs(config),
                    retryBackoffMs,
                    deliveryTimeoutMs,
                    metrics,
                    PRODUCER_METRIC_GROUP_NAME,
                    time,
                    apiVersions,
                    transactionManager,
                    new BufferPool(this.totalMemorySize, config.getInt(ProducerConfig.BATCH_SIZE_CONFIG), metrics, time, PRODUCER_METRIC_GROUP_NAME));
```

他には Sendor も挙げられる。
例えば、上記で示したaccumulatorも、Sendorのコンストラクタに渡され、内部で利用される。

org/apache/kafka/clients/producer/KafkaProducer.java:422
```
            this.sender = newSender(logContext, kafkaClient, this.metadata);
```

org/apache/kafka/clients/producer/KafkaProducer.java:463
```
        return new Sender(logContext,
                client,
                metadata,
                this.accumulator,
                maxInflightRequests == 1,
                producerConfig.getInt(ProducerConfig.MAX_REQUEST_SIZE_CONFIG),
                acks,
                retries,
                metricsRegistry.senderMetrics,
                time,
                requestTimeoutMs,
                producerConfig.getLong(ProducerConfig.RETRY_BACKOFF_MS_CONFIG),
                this.transactionManager,
                apiVersions);
```

その他にはトランザクション・マネージャなども。


