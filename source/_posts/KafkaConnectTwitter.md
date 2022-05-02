---

title: KafkaConnectでTwitterデータを取り込む
date: 2019-03-08 22:37:11
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka
  - ZooKeeper

---

# 参考

* [jcustenborder/kafka-connect-twitter]

[jcustenborder/kafka-connect-twitter]: https://github.com/jcustenborder/kafka-connect-twitter


# メモ

ここでは、 `confluent-hub` コマンドでインストールする。

```
$ confluent-hub install jcustenborder/kafka-connect-twitter
```

以下の設定ファイルを作る。

/etc/kafka/connect-twitter-source.properties
```
name=connector1
tasks.max=1
connector.class=com.github.jcustenborder.kafka.connect.twitter.TwitterSourceConnector

# Set these required values
twitter.oauth.accessTokenSecret=hoge
process.deletes=false
filter.keywords=kafka
kafka.status.topic=twitter-status
kafka.delete.topic=twitter-delete
twitter.oauth.consumerSecret=hoge
twitter.oauth.accessToken=hoge
twitter.oauth.consumerKey=hoge
```

キーのところは、適宜TwitterのDeveloper向けページで生成して記載すること。

スタンドアローンモードで実行する。

```
$ connect-standalone /etc/kafka/connect-standalone.properties /etc/kafka/connect-twitter-source.properties
```

なお、もし分散モードだったら、以下のようにする。

```
curl -H "Content-Type: application/json" -X POST http://localhost:8083/connectors -d '
{
    "name": "twitter",
    "config": {
        "tasks.max":1,
        "connector.class":"com.github.jcustenborder.kafka.connect.twitter.TwitterSourceConnector",
        "twitter.oauth.accessTokenSecret":"hoge",
        "process.deletes":"false",
        "filter.keywords":"kafka",
        "kafka.status.topic":"twitter-status",
        "kafka.delete.topic":"twitter-delete",
        "twitter.oauth.consumerSecret":"hoge",
        "twitter.oauth.accessToken":"hoge",
        "twitter.oauth.consumerKey":"hoge",
    }
}
'
```

最後に、入力されるメッセージを確認する。
```
$ kafka-console-consumer --bootstrap-server broker:9092 --topic twitter-status | jq .
```

結果は以下のような形式である。
```
{
  "schema": {
    "type": "struct",
    "fields": [
      {
        "type": "int64",
        "optional": true,
        "name": "org.apache.kafka.connect.data.Timestamp",
        "version": 1,
        "doc": "Return the created_at",
        "field": "CreatedAt"
      },

(snip)

  "payload": {
    "CreatedAt": XXXXXXXXXXXXX,
    "Id": XXXXXXXXXXXXXXXXXXX,
    "Text": "hoge",
    "Source": "<a href=\"http://twitter.com/download/android\" rel=\"nofollow\">Twitter for Android</a>",
    "Truncated": false,

(snip)
```
