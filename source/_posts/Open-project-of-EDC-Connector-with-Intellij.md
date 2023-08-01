---

title: Open project of EDC Connector with Intellij
date: 2023-08-01 10:46:35
categories:
  - Knowledge Management
  - Data Spaces
  - EDC
tags:
  - Data Spaces
  - EDC

---


# 1. メモ

[EDC Connector 公式GitHub] のプロジェクトをIntellijで開くための手順メモ。
いろいろなやり方があるが一例として。

## 1.1. 準備

gitクローンしておく。
ここでは、gitプロトコルを用いているが環境に合わせて適宜変更してクローンする。

```bash
$ git clone git@github.com:eclipse-edc/Connector.git
$ cd Connector
```

なお、必要に応じて特定のタグをチェックアウトしてもよい。
ここでは、v0.2.0をチェックアウトした。

```bash
$ git checkout -b v0.2.0 refs/tags/v0.2.0
```

当該プロジェクトでは、ビルドツールにGradleを用いている。プロジェクトに `gradlew` も含まれている。
本環境では、以下のようにGradle8.0を利用した。

◇参考情報

```bash
$ cat gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-bin.zip
networkTimeout=10000
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

◇参考情報おわり

さて、ビルドに利用するOpenJDKをインストールしておく。
ここでは17系を用いた。（もともと手元の環境にあった8系を用いようとしたら互換性エラーが生じたため、17系を用いることとした）

```bash
$ sudo apt install openjdk-17-jdk
```

なお、 [Gradle Compatibility] に互換性のあるGradleとJDKのバージョンが記載されているので参考にされたし。

この状態でIntellijを使わずにビルドするには、以下のように実行する。
ここでは念のために、コマンドでビルドできることを確かめるため、あらかじめ以下を実行しておいた。

```bash
$ ./gradlew clean build
```

特に問題なければ、success表示が出て終わるはず。

## 1.2. Intellijで開く

ひとまず、プロジェクトトップでInteliljを開く。

```bash
$ <Intellijのホームディレクトリ>/bin/idea.sh . &
```

なお、IntellijにGradle拡張機能がインストールされていなければ、インストールしておく。「Files」→「Settings」→「Plugins」→「Gradleで検索」。

また使用するJDKを先にインストールしたJDK17を用いるようにする。「Files」→「Project Structure」→「Project」を開く。
「SDK:」のところで先ほどインストールしたJDKを設定する。
「Language Lavel:」も合わせて変更しておく。

開いたら、右側の「Gradle」ペインを開き、設定ボタンを押して「Gradle settings ...」を選択する。

「Build and run」章のところは、「Gradle」が選択されていることを確認する。

「Gradle」章のところは、「Use Gradle from:」でgradle wrapperの情報を用いるようになっていること、「Gradle JVM」でProject JDKを用いるようになっていることを確認する。

特に問題なければ、 `BUILD SUCCESSFUL` となるはずである。

## 1.3. トラブルシュート

### 1.3.1. Intellijのメモリ不足

ビルド中にヒープが不足することがある。
その場合は、 [Intellijのメモリを増やす設定] を参考に、ヒープサイズを増やす。

「Help」→「Memory Setting」を開き、「2024」（MB）あたりにしておく。

### 1.3.2. Gradleのメモリ不足

ビルド中にヒープが不足することがある。
プロジェクト内にある、 `gradle.properties` 内に以下を追記する。ここでは最大4GBとした。

◇diff
```diff
diff --git a/gradle.properties b/gradle.properties
index 376da414a..d8da811a9 100644
--- a/gradle.properties
+++ b/gradle.properties
@@ -7,3 +7,6 @@ edcGradlePluginsVersion=0.1.4-SNAPSHOT
 metaModelVersion=0.1.4-SNAPSHOT
 edcScmUrl=https://github.com/eclipse-edc/Connector.git
 edcScmConnection=scm:git:git@github.com:eclipse-edc/Connector.git
+
+# Increase Gradle JVM Heap size
+org.gradle.jvmargs=-Xmx4096M
```

### 1.3.3. JDKバージョンの不一致

当初、環境にあったJDK8系を用いていたが、ビルド時に構文エラー（互換性のエラー）が生じたため、JDK17を用いるようにした。

# 2. 参考

* [EDC Connector 公式GitHub]
* [Gradle Compatibility]
* [Intellijのメモリを増やす設定]

[EDC Connector 公式GitHub]: https://github.com/eclipse-edc/Connector
[Gradle Compatibility]: https://docs.gradle.org/current/userguide/compatibility.html
[Intellijのメモリを増やす設定]: https://www.jetbrains.com/help/idea/increasing-memory-heap.html


<!-- vim: set et tw=0 ts=2 sw=2: -->
