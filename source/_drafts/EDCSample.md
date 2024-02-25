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

[EDC/Samples] の内容を紹介する。

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

[EDC/Samples/README] には目的、必要事項（準備）、スコープの説明がある。

本プロジェクトの目的はオンボーディングの支援。
初心者をナビゲートしやすいような順番でサンプルが構成されており、ステップバイステップで学べる。

### 必要事項（準備）

このプロジェクトでは、基本的にEclipse Dataspace Componentで用いられる用語は理解している前提で説明が進められる。
そのため、[EDC/documentation] は読んでいることが望ましい。
また、[EDC/YT]の動画も参考になる。

また、関連ツールとして、Git、Gradle、Java、HTTPあたりは押さえておきたい、とされている。

動作確認する場合は、Java11+がインストールされていることが必要。

### スコープ（Scopes）

サンプル群は、Scopeと呼ばれるグループで区分されている。
何を学びたいか、で分かれている。
ひとまず、初心者であれば`basic`が良いとのこと。

ざっと以下に解説する。

| Scope名  | 説明                                                                |
| -------- | ------------------------------------------------------------------- |
| Basic    | EDC Frameworkを使い始めるための基礎。セットアップ、起動、拡張の作成 |
| Transfer | データ転送について                                                  |
| Advanced | 高度な例                                                            |

## Basicスコープの概要

[EDC/Samples/Basic/README]には以下のサンプルが載っている。

| サンプル名     | 説明                                             |
| -------------- | ------------------------------------------------ |
| Basic Sample 1 | コネクタを起動するのに必要なことを学ぶ           |
| Basic Sample 2 | 拡張機能の作成、拡張機能の使い方を学ぶ           |
| Basic Sample 3 | プロパティファイルを用いて設定値を扱う方法を学ぶ |

## Basic/Sample1

[EDC/Samples/Basic/Basic1/README]には以下の通り説明されている。

`Runtime`とビルドファイルで構成されている。
ビルドファイルは、`build.gradle.kts`である。

このサンプルでは、EDCの[BaseRuntime]を用いている。

また、[EDC/Samples/Basic/Basic1/build.gradle.kts]を見ることでプロジェクトが依存するものがわかる。

basic/basic-01-basic-connector/build.gradle.kts:22

```gradle
dependencies {
    implementation(libs.edc.boot)
    implementation(libs.edc.connector.core)
}
```

# 参考

## レポジトリ内

* [EDC/Samples]
* [EDC/Samples/README]
* [EDC/Samples/Basic/README]
* [EDC/Samples/Basic/Basic1/README] 
* [EDC/Samples/Basic/Basic1/build.gradle.kts]

[EDC/Samples]: https://github.com/eclipse-edc/Samples
[EDC/Samples/README]: https://github.com/eclipse-edc/Samples?tab=readme-ov-file#edc-samples
[EDC/Samples/Basic/README]: https://github.com/eclipse-edc/Samples/blob/main/basic/README.md
[EDC/Samples/Basic/Basic1/README]: https://github.com/eclipse-edc/Samples/blob/main/basic/basic-01-basic-connector/README.md
[EDC/Samples/Basic/Basic1/build.gradle.kts]: https://github.com/eclipse-edc/Samples/blob/main/basic/basic-01-basic-connector/build.gradle.kts

## EDCレポジトリ

* [BaseRuntime]

[BaseRuntime]: https://github.com/eclipse-edc/Connector/blob/releases/core/common/boot/src/main/java/org/eclipse/edc/boot/system/runtime/BaseRuntime.java

## 外部

* [EDC/documentation]
* [EDC/YT] 

* [dobachi/EDCSampleAnsible]

[EDC/documentation]: https://eclipse-edc.github.io/docs/#/
[EDC/YT]: https://www.youtube.com/@eclipsedataspaceconnector9622/featured
[dobachi/EDCSampleAnsible]: https://github.com/dobachi/EDCSampleAnsible



<!-- vim: set et tw=0 ts=2 sw=2: -->
