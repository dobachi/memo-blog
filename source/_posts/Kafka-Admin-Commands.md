---
title: Kafka Admin Commands
date: 2019-11-04 23:12:19
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka

---

# 参考

* [Kafka公式ドキュメント]
* [Confluentドキュメント]
* [Clouderaのドキュメント（Kafka Administration Using Command Line Tools）]
* [ConfluentドキュメントのAdminister章]

[Kafka公式ドキュメント]: https://kafka.apache.org/documentation/
[Confluentドキュメント]: https://docs.confluent.io/current/index.html
[Clouderaのドキュメント（Kafka Administration Using Command Line Tools）]: https://docs.cloudera.com/documentation/enterprise/latest/topics/kafka_admin_cli.html#kafka_log_dirs
[ConfluentドキュメントのAdminister章]: https://docs.confluent.io/current/administer.html


# メモ

意外とまとまった説明は [Kafka公式ドキュメント] や [Confluentドキュメント] にはない。
Getting startedや運用面のドキュメントに一部含まれている。

丁寧なのは、 [Clouderaのドキュメント（Kafka Administration Using Command Line Tools）] である。

## Confluentドキュメント

[ConfluentドキュメントのAdminister章] には、ツールとしてのまとまりではなく、
Admin作業単位で説明があり、その中にいくつかツールの説明が含まれている。

## 実装

`kafka.admin` パッケージ以下にAminコマンドの実装が含まれている。
またそれらのクラスは、 `bin`以下に含まれている。

例えば、 `kafka-log-dirs` コマンドでは、`kafka.admin.LogDirsCommand` クラスが使われている、など。



<!-- vim: set tw=0 ts=4 sw=4: -->
