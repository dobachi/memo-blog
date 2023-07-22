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

### EDC Connector Sampleを動かす

[EDC Connector SampleのPrerequirments] を見ると、環境としては `JDK 11+ for your OS` が必要であるとされている。

# 参考

## 概要

* [EDC公式ウェブサイト]: https://projects.eclipse.org/projects/technology.edc
* [IDS]: https://internationaldataspaces.
* [NTTデータのコネクタ調査報告書]: https://www.nttdata.com/global/ja/news/information/2022/072700/
* [EDC Conference 2022]: https://www.youtube.com/playlist?list=PLw-f_YoTxWJU_quLpk9fGpq37gzvVZGc4
* [EDC Document]: https://eclipse-edc.github.io/docs/#/
* [EDCのYoutube動画]: https://www.youtube.com/@eclipsedataspaceconnector9622/featured

## Connector動作

* [EDC Connector GitHub]: https://github.com/eclipse-edc/Connector`
* [EDC Connector Getting Started]: https://github.com/eclipse-edc/Connector#getting-started
* [EDC Connector Sample]: https://github.com/eclipse-edc/Samples
* [EDC Connector SampleのPrerequirments]: https://github.com/eclipse-edc/Samples#prerequisites




<!-- vim: set et tw=0 ts=2 sw=2: -->
