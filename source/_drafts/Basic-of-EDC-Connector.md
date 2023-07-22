---

title: Basic of EDC Connector
date: 2023-07-15 11:53:48
categories:
  - Knowledge Management
  - Data Spaces
  - EDC
tags:
  - Data Spaces
  - EDC

---

# メモ

## ひとこと概要

Eclipse Dataspace Componentsは、 [IDS] などが提唱している Data Space を実現し、参加者同士が互いにつながるためのConnector関連のソフトウェアを提供する。

[EDC公式ウェブサイト] によると、既存技術はカタログやデータ転送に注力しているが、本Dataspace Connectorはインターオペラビリティがある、組織間データ共有を実現するためのフレームワークを提供する、とされている。（2023/7現在となっては、ほかの技術も出てきているため、「もともとは」と言わざるを得ないかもしれないが）

さらに、EDCはGaia-Xで提唱されているプロトコルや要件を踏まえつつ、IDS標準を実装するものである、とされている。

[NTTデータのコネクタ調査報告書] がほどよく概要を説明しているので参照されたし。
またEDC自体のドキュメントであれば、 [EDC Document] や [EDCのYoutube動画] が参考になる。

[EDC Conference 2022] も参考になる。

## 何はともあれ動かすには

[EDC Connector GitHub] がエントリポイントになるコネクタ実装のレポジトリである。

[EDC Connector Getting Started] あたりが参考になる。
その中に、 [EDC Connector Sample] が含まれている。なお、このレポジトリは2022/11にイニシャルコミットが行われている比較的新しいレポジトリである。

まずはクローンしておこう。

```bash
$ git clone git@github.com:eclipse-edc/Samples.git
$ cd Samples
```

### EDC Connector Sampleを動かす

[EDC Connector SampleのPrerequirments] を見ると、環境としては `JDK 11+ for your OS` が必要であるとされている。
[EDC Connector SampleのScopes] の通り、サンプルはScopeに分けられている。

* [EDC Connector SampleのBasic]
  * Connectorをセットアップする方法、拡張機能を実装する方法を伝える
* [EDC Connector SampleのTransfer]
  * EDCにおいてのデータ転送を伝える

[EDC Connector Sample/basic] がサンプルのbasicスコープである。

#### build

GradleやJDKがある環境で動かすのがよいので、Dockerで対応しよう。

```bash
$ docker pull gradle:jdk11
$ docker run --rm -it -v `pwd`:/edc_sample --name edc-basic-01 gradle:jdk11 bash
```

Dockerを起動したので、 [EDC Connector Sample/basic/basic-01-basic-connector] のREADMEにあるように、ビルドしてみる。

```bash
$ cd /edc_sample
$ ./gradlew clean basic:basic-01-basic-connector:build
```

#### basic/basic-01-basic-connector

まずは、 [EDC Connector Sample/basic/basic-01-basic-connector] を試そう。


# 参考

## 概要

* [EDC公式ウェブサイト]: https://projects.eclipse.org/projects/technology.edc
* [IDS]: https://internationaldataspaces.
* [NTTデータのコネクタ調査報告書]: https://www.nttdata.com/global/ja/news/information/2022/072700/
* [EDC Conference 2022]: https://www.youtube.com/playlist?list=PLw-f_YoTxWJU_quLpk9fGpq37gzvVZGc4
* [EDC Document]: https://eclipse-edc.github.io/docs/#/
* [EDCのYoutube動画]: https://www.youtube.com/@eclipsedataspaceconnector9622/featured

## Connector動作

### ソースコード

* [EDC Connector GitHub]: https://github.com/eclipse-edc/Connector`
* [EDC Connector Getting Started]: https://github.com/eclipse-edc/Connector#getting-started
* [EDC Connector Sample]: https://github.com/eclipse-edc/Samples
* [EDC Connector Sample/basic]: https://github.com/eclipse-edc/Samples/tree/main/basic
* [EDC Connector Sample/basic/basic-01-basic-connector]: https://github.com/eclipse-edc/Samples/blob/main/basic/basic-01-basic-connector/README.md

### ドキュメント

* [EDC Connector SampleのPrerequirments]: https://github.com/eclipse-edc/Samples#prerequisites
* [EDC Connector SampleのScopes]: https://github.com/eclipse-edc/Samples#scopes
* [EDC Connector SampleのBasic]: https://github.com/eclipse-edc/Samples#basic
* [EDC Connector SampleのTransfer]: https://github.com/eclipse-edc/Samples#transfer


<!-- vim: set et tw=0 ts=2 sw=2: -->
