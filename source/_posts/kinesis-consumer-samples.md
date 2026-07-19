---
title: AWS Kinesisのコンシューマのサンプルを探す
date: 2018-09-20 00:52:29
categories:
  - Research
  - AWS
tags:
  - AWS
  - Kinesis
---

# 公式ドキュメント

[Amazon Kinesis Data Streams コンシューマーの開発](https://docs.aws.amazon.com/ja_jp/streams/latest/dev/shared-fan-out-consumers.html) を見ると、

* Kinesis Client Library 1.x を使う場合
* Kinesis Data Streams API および AWS SDK for Javaを使う場合

の2種類があることが分かりました。

一旦、 [Kinesis Client Library 1.x を使う場合] を見てみることにします。

[Kinesis Client Library 1.x を使う場合]: https://docs.aws.amazon.com/ja_jp/streams/latest/dev/kinesis-record-processor-implementation-app-java.html

## Kinesis Clinet Library

[Kinesis Client Library 1.x を使う場合] によると、以下の言語に対応しているように見えます。

* Java
* Node.js
* .NET
* Python
* Ruby

### Javaでの実装例
[Java での Kinesis Client Library コンシューマーの開発] を見ると、Javaライブラリの使い方が載っていました。
Kinesisから読んでどこかに書き出すときに使えそうです。

[Java での Kinesis Client Library コンシューマーの開発]: https://docs.aws.amazon.com/ja_jp/streams/latest/dev/kinesis-record-processor-implementation-app-java.html

### C言語のバインディングはないのか？

少々気になるのは、c言語のバインディングがないかもしれない、ことです。
[Amazon KCL support for other languages] を参照すると、MultiLangDaemonなるものを立てて使え、とありました。
他にも、 [Python での Kinesis Client Library コンシューマーの開発] においても、

> KCL は Java ライブラリです。Java 以外の言語のサポートは、MultiLangDaemon という多言語インターフェイスを使用して提供されます。

と記載されています。

[Amazon KCL support for other languages]: https://github.com/awslabs/amazon-kinesis-client#amazon-kcl-support-for-other-languages
[Python での Kinesis Client Library コンシューマーの開発]: https://docs.aws.amazon.com/ja_jp/streams/latest/dev/kinesis-record-processor-implementation-app-py.html

いずれにせよ、Java以外の開発では一癖ありそうな予感がしました。
