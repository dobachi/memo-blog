---

title: EDCSample
date: 2024-02-24 22:15:17
categories:
  - Knowledge Management
  - Dataspace Connector
  - Eclipse Dataspace Components
tags:
  - Dataspace Connector
  - IDS
  - EDC

---

# メモ

[EDC/Sampple] の内容を紹介する。

## 動作確認環境

本プロジェクトに沿って動作確認した際の環境情報を以下に載せる。

```
$ cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=22.04
DISTRIB_CODENAME=jammy
DISTRIB_DESCRIPTION="Ubuntu 22.04.3 LTS"
```

なお、WSL環境である。

また[dobachi/EDCSampleAnsible]に環境準備などのAnsible Playbookを置く。


## README

[EDC/Sample/README] には目的、必要事項（準備）、スコープの説明がある。

本プロジェクトの目的はオンボーディングの支援。
初心者をナビゲートしやすいような順番でサンプルが構成されており、ステップバイステップで学べる。

### 必要事項（準備）

このプロジェクトでは、基本的にEclipse Dataspace Componentで用いられる用語は理解している前提で説明が進められる。
そのため、[EDC/documentation] は読んでいることが望ましい。
また、[EDC/YT]の動画も参考になる。

また、関連ツールとして、Git、Gradle、Java、HTTPあたりは押さえておきたい、とされている。

動作確認する場合は、Java11+がインストールされていることが必要。



# 参考

## レポジトリ内

* [EDC/Sampple]
* [EDC/Sample/README]

[EDC/Sampple]: https://github.com/eclipse-edc/Samples
[EDC/Sample/README]: https://github.com/eclipse-edc/Samples?tab=readme-ov-file#edc-samples

## 外部

* [EDC/documentation]
* [EDC/YT] 

* [dobachi/EDCSampleAnsible]

[EDC/documentation]: https://eclipse-edc.github.io/docs/#/
[EDC/YT]: https://www.youtube.com/@eclipsedataspaceconnector9622/featured
[dobachi/EDCSampleAnsible]: https://github.com/dobachi/EDCSampleAnsible



<!-- vim: set et tw=0 ts=2 sw=2: -->
