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

# 1. メモ

## 1.1. ひとこと概要

Eclipse Dataspace Componentsは、 [IDS] などが提唱している Data Space を実現し、参加者同士が互いにつながるためのConnector関連のソフトウェアを提供する。

[EDC公式ウェブサイト] によると、既存技術はカタログやデータ転送に注力しているが、本Dataspace Connectorはインターオペラビリティがある、組織間データ共有を実現するためのフレームワークを提供する、とされている。（2023/7現在となっては、ほかの技術も出てきているため、「もともとは」と言わざるを得ないかもしれないが）

さらに、EDCはGaia-Xで提唱されているプロトコルや要件を踏まえつつ、IDS標準を実装するものである、とされている。

[NTTデータのコネクタ調査報告書] がほどよく概要を説明しているので参照されたし。
またEDC自体のドキュメントであれば、 [EDC Document] や [EDCのYoutube動画] が参考になる。

[EDC Conference 2022] も参考になる。

## 1.2. 何はともあれ動かすには

[EDC Connector GitHub] がエントリポイントになるコネクタ実装のレポジトリである。

[EDC Connector Getting Started] あたりが参考になる。
その中に、 [EDC Connector Sample] が含まれている。なお、このレポジトリは2022/11にイニシャルコミットが行われている比較的新しいレポジトリである。

まずはクローンしておこう。

```bash
$ git clone git@github.com:eclipse-edc/Samples.git
$ cd Samples
```

## 1.3. EDC Connector Sampleを動かす

[EDC Connector SampleのPrerequirments] を見ると、環境としては `JDK 11+ for your OS` が必要であるとされている。
[EDC Connector SampleのScopes] の通り、サンプルはScopeに分けられている。

* [EDC Connector SampleのBasic]
  * Connectorをセットアップする方法、拡張機能を実装する方法を伝える
* [EDC Connector SampleのTransfer]
  * EDCにおいてのデータ転送を伝える

[EDC Connector Sample/basic] がサンプルのbasicスコープである。

## 1.4. basic/basic-01-basic-connector

まずは、 [EDC Connector Sample/basic/basic-01-basic-connector] を試そう。

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

エラーが生じた。

```gradle
A problem occurred configuring root project 'samples'.                                                                                       [55/1696]> Could not resolve all files for configuration ':classpath'.
   > Could not resolve org.eclipse.edc:edc-build:0.1.0.
     Required by:
         project : > org.eclipse.edc.edc-build:org.eclipse.edc.edc-build.gradle.plugin:0.1.0
      > No matching variant of org.eclipse.edc:edc-build:0.1.0 was found. The consumer was configured to find a library for use during runtime, compatible with Java 8, packaged as a jar, and its dependencies declared externally, as well as attribute 'org.gradle.plugin.api-version' with value '8.0' but:
          - Variant 'apiElements' capability org.eclipse.edc:edc-build:0.1.0 declares a library, packaged as a jar, and its dependencies declared externally:
              - Incompatible because this component declares a component for use during compile-time, compatible with Java 17 and the consumer needed a component for use during runtime, compatible with Java 8
              - Other compatible attribute:
                  - Doesn't say anything about org.gradle.plugin.api-version (required '8.0')
          - Variant 'javadocElements' capability org.eclipse.edc:edc-build:0.1.0 declares a component for use during runtime, and its dependencies declared externally:
              - Incompatible because this component declares documentation and the consumer needed a library
              - Other compatible attributes:
                  - Doesn't say anything about its target Java version (required compatibility with Java 8)
                  - Doesn't say anything about its elements (required them packaged as a jar)
                  - Doesn't say anything about org.gradle.plugin.api-version (required '8.0')
          - Variant 'runtimeElements' capability org.eclipse.edc:edc-build:0.1.0 declares a library for use during runtime, packaged as a jar, and its dependencies declared externally:
              - Incompatible because this component declares a component, compatible with Java 17 and the consumer needed a component, compatible with Java 8
              - Other compatible attribute:
                  - Doesn't say anything about org.gradle.plugin.api-version (required '8.0')
          - Variant 'sourcesElements' capability org.eclipse.edc:edc-build:0.1.0 declares a component for use during runtime, and its dependencies declared externally:
              - Incompatible because this component declares documentation and the consumer needed a library
              - Other compatible attributes:
                  - Doesn't say anything about its target Java version (required compatibility with Java 8)
                  - Doesn't say anything about its elements (required them packaged as a jar)
                  - Doesn't say anything about org.gradle.plugin.api-version (required '8.0')
```

さて、エラー文面中の以下の記載の通り、Java 8と互換を保ちつつ、Java 17環境を使わないといけないようだ？

```
              - Incompatible because this component declares a component for use during compile-time, compatible with Java 17 and the consumer needed a component for use during runtime, compatible with Java 8
```

ということで、Dockerの環境をJDK17を用いるように変更して実行してみる。

```bash
$ docker run --rm -it -v `pwd`:/edc_sample --name edc-basic-01 openjdk:17 bash
$ cd /edc_sample
$ ./gradlew clean basic:basic-01-basic-connector:build
./gradlew: line 234: xargs: command not found
Downloading https://services.gradle.org/distributions/gradle-8.0-bin.zip
...........10%............20%............30%............40%............50%............60%...........70%............80%............90%............100%

Welcome to Gradle 8.0!

For more details see https://docs.gradle.org/8.0/release-notes.html

Starting a Gradle Daemon (subsequent builds will be faster)
```

xargsコマンドが失敗したメッセージが出ているが一応成功メッセージは得られている。
使用したDockerイメージには、xargsコマンドがなかったようなので、
コンテナ内で簡単にxargsをインストールしておく。

```bash
# microdnf install findutils
```

あらためてビルドする。

```bash
$ ./gradlew clean basic:basic-01-basic-connector:build

BUILD SUCCESSFUL in 5s
45 actionable tasks: 11 executed, 34 up-to-date
```

問題なくなったので、続いてサービスを起動する。

```bash
bash-4.4# java -jar basic/basic-01-basic-connector/build/libs/basic-connector.jar
WARNING 2023-07-30T08:50:25.444977601 The runtime is configured as an anonymous participant. DO NOT DO THIS IN PRODUCTION.
INFO 2023-07-30T08:50:25.903477626 Initialized Boot Services
INFO 2023-07-30T08:50:26.868246055 Initialized Core Default Services
INFO 2023-07-30T08:50:27.121881706 HTTPS enforcement it not enabled, please enable it in a production environment
INFO 2023-07-30T08:50:27.973503814 HTTPS enforcement it not enabled, please enable it in a production environment
INFO 2023-07-30T08:50:28.008418188 Initialized Core Services
WARNING 2023-07-30T08:50:28.038222702 Settings: No setting found for key 'edc.hostname'. Using default value 'localhost'
INFO 2023-07-30T08:50:28.047466815 Prepared Boot Services
INFO 2023-07-30T08:50:28.048738274 Prepared Core Default Services
INFO 2023-07-30T08:50:28.068155529 Prepared Core Services
INFO 2023-07-30T08:50:28.073227583 Started Boot Services
INFO 2023-07-30T08:50:28.074407755 Started Core Default Services
INFO 2023-07-30T08:50:28.092933351 Started Core Services
INFO 2023-07-30T08:50:28.11172217 edc-6914dc0e-f7e6-4cc4-890d-1d05cf7ff0c3 ready
```

READMEの説明にもあるようなメッセージが表示された。特にエラーはない。
このサンプルは本当に起動するだけのサンプルである。

## 1.5. basic-02-health-endpoint

[EDC Connector Sample/basic/basic-02-health-endpoint] を参考に進める。
このサンプルでは、HTTP GETのエンドポイントを作成する拡張機能の例を示す。

まず考え方を示す。
この拡張機能の例では、 `ServiceExtension ` を拡張してみる。
そのためには、 `basic/basic-02-health-endpoint/src/main/resources/META-INF/services` にpluginファイルを置く必要がある。その際、拡張するインタフェース名のディレクトリの下に、対象とする拡張のfully-qualifiedな名称で作成する必要がある。
今回の例では、 `ServiceExtension` を拡張するので `
basic/basic-02-health-endpoint/src/main/resources/META-INF/services/org.eclipse.edc.spi.system.ServiceExtension` というファイルを作成する。

ファイルの中身は以下。ServiceExtentionを拡張して作成するクラス名が記載されている。

```
org.eclipse.edc.extension.health.HealthEndpointExtension
```

では、 `basic/basic-02-health-endpoint/src/main/java/org/eclipse/edc/extension/health/HealthEndpointExtension.java` の中身を見てみよう。

```java
package org.eclipse.edc.extension.health;

import org.eclipse.edc.runtime.metamodel.annotation.Inject;
import org.eclipse.edc.spi.system.ServiceExtension;
import org.eclipse.edc.spi.system.ServiceExtensionContext;
import org.eclipse.edc.web.spi.WebService;

public class HealthEndpointExtension implements ServiceExtension {

    @Inject
    WebService webService;

    @Override
    public void initialize(ServiceExtensionContext context) {
        webService.registerResource(new HealthApiController(context.getMonitor()));
    }
}
```

`@Inject` が示すのは、この拡張がほかの拡張により定義されたサービスを必要とすることである。
今回の例だと、 `WebService.class` である。
このインタフェースは以下の説明の通り、ランタイムのウェブサービスを管理するためのものである。

```java
 * Manages the runtime web (HTTP) service.
```

拡張機能の例の中を見ると、リソースを登録している箇所がある。

org/eclipse/edc/extension/health/HealthEndpointExtension.java:29

```java
        webService.registerResource(new HealthApiController(context.getMonitor()));
```

登録されているのは、 `org.eclipse.edc.extension.health.HealthApiController#HealthApiController` である。
これは拡張機能用の例として実装されたものである。
正常性診断のための簡単なREST APIを提供する。

中では、SPIのMonitorインタフェースが利用されている。
このインターフェースはシステムモニタリングとロギングのために用いられる。

org/eclipse/edc/extension/health/HealthApiController.java:30

```java
    private final Monitor monitor;

    public HealthApiController(Monitor monitor) {
        this.monitor = monitor;
    }
```

`org.eclipse.edc.extension.health.HealthApiController#checkHealth` というメソッドが定義されている。
`GET` アノテーションがされており、以下のように、Monitorのログ機能を使ってメッセージを出力している。
その後、レスポンスを返している。

org/eclipse/edc/extension/health/HealthApiController.java:36

```java
    @GET
    @Path("health")
    public String checkHealth() {
        monitor.info("Received a health request");
        return "{\"response\":\"I'm alive!\"}";
    }
```

さて、これをビルドして実行してみる。
1個目のプロジェクトと同様に、プロジェクトトップに移動し、以下のようにビルド、実行する。

```bash
$ docker run --rm -it -v `pwd`:/edc_sample --name edc-basic-02 gradle:jdk17 bash
# cd /edc_sample/
# ./gradlew clean basic:basic-02-health-endpoint:build
# java -jar basic/basic-02-health-endpoint/build/libs/connector-health.jar
```

正常に起動したら、別の端末から以下を実行し、コンテナ内のサービスに接続して戻り値を得る。　

```bash
$ docker exec -it edc-basic-02 curl http://localhost:8181/api/health
{"response":"I'm alive!"}
```

## 1.6. basic-03-configuration

つづいて、  [EDC Connector Sample/basic/basic-03-configuration] を試す。
このサンプルでは、 `ConfigurationExtension` インターフェースを用いて設定する例を示す。
まず初めに、Jarファイルに追加するようGradleの依存関係を設定し、その後そのまま起動するような手順になっている。
このままではJavaプロファイル形式のデータストアが存在しないのでエラーになる。
その後、改めて設定する。という流れである。

まずは、 `FsConfigurationExtension.java` を用いる例である。
この実装では、Javaプロファイルを設定のストアに用いる。

02のサンプルでは、このライブラリをJarに含めていなかったので、ここでは以下のように依存関係に設定することでJarに含めるようにする。

basic/basic-03-configuration/build.gradle.kts:29

```kotolin
dependencies {
    // ...
    implementation(libs.edc.configuration.filesystem)
    // ...
```

さて、この状態でビルドして実行してみる。

```bash
$ docker run --rm -it -v `pwd`:/edc_sample --name edc-basic-02 gradle:jdk17 bash #必要であればDockerを起動する。
# cd /edc_sample/ #必要であればDockerを起動する。
# ./gradlew clean basic:basic-03-configuration:build
```

いったんそのまま実行する。

```bash
# java -jar basic/basic-03-configuration/build/libs/filesystem-config-connector.jar
WARNING 2023-08-01T06:59:36.181266486 Configuration file does not exist: dataspaceconnector-configuration.properties. Ignoring.
```

上記のように、Configurationファイルが存在しない旨の警告が出ている。

さてそれでは設定ファイルを用意してみる。
特に指定しない場合は、 `FsConfigurationExtension` は `dataspaceconnector-configuration.properties` というファイルがカレントディレクトリにあることを期待する。

しかしまずはREADME記載の通りに行ってみる。（ `/etc/eclipse/dataspaceconnector` 以下に設定ファイルを置くスタイル）

```bash
# mkdir -p /etc/eclipse/dataspaceconnector
# touch /etc/eclipse/dataspaceconnector/config.properties
```

プロパティファイルの中身は以下。
ここでは待ち受けるポートを変更してみる。

```property
web.http.port=9191
```

さて、この状態で、 `edc.fs.config` に先ほど作ったプロパティファイルのパスを渡して実行する

```bash
# java -Dedc.fs.config=/etc/eclipse/dataspaceconnector/config.properties -jar basic/basic-03-configuration/build/libs/filesystem-config-connector.jar
INFO 2023-08-01T07:14:59.316210496 Initialized FS Configuration

(snip)

INFO 2023-08-01T07:23:43.075731711 HTTP context 'default' listening on port 9191
DEBUG 2023-08-01T07:23:43.138659082 Port mappings: {alias='default', port=9191, path='/api'}
```

上記の通り、渡した設定ファイルの通り、待ち受けポートが9191に変更になっていることがわかる。

さて、ここで独自の設定値を渡すようにしよう。
ここではログのプリフィックスをつける設定をする。

先ほどの `/etc/eclipse/dataspaceconnector/config.properties` に以下の内容を追記する。

```property
edc.samples.basic.03.logprefix=MyLogPrefix
```

そして、02の例で実装したサンプル `org.eclipse.edc.extension.health.HealthEndpointExtension` を改造する。
全体を以下に示す。

org/eclipse/edc/extension/health/HealthEndpointExtension.java:22

```java
public class HealthEndpointExtension implements ServiceExtension {

    private static final String LOG_PREFIX_SETTING = "edc.samples.basic.03.logprefix";
    @Inject
    WebService webService;

    @Override
    public void initialize(ServiceExtensionContext context) {
        var logPrefix = context.getSetting(LOG_PREFIX_SETTING, "health");
        webService.registerResource(new HealthApiController(context.getMonitor(), logPrefix));
    }
}
```

まずは先ほど定義したプロパティ名を定義する。

org/eclipse/edc/extension/health/HealthEndpointExtension.java:24

```java
    private static final String LOG_PREFIX_SETTING = "edc.samples.basic.03.logprefix";
```

つづいて、 `org.eclipse.edc.spi.system.ServiceExtensionContext` を用いて、プロパティの値を取得する。
先ほど定義したプロパティ名を用いて、 `org.eclipse.edc.spi.system.SettingResolver#getSetting(java.lang.String, java.lang.String)` を用いて値を取得する。
`org.eclipse.edc.extension.health.HealthApiController#HealthApiController` メソッドの第2引数はログプリフィックスを渡せるようにする（口述）ので先ほど取得した値を渡す。

org/eclipse/edc/extension/health/HealthEndpointExtension.java:29

```java
    public void initialize(ServiceExtensionContext context) {
        var logPrefix = context.getSetting(LOG_PREFIX_SETTING, "health");
        webService.registerResource(new HealthApiController(context.getMonitor(), logPrefix));
    }
```

org/eclipse/edc/extension/health/HealthApiController.java:35

```java
    public HealthApiController(Monitor monitor, String logPrefix) {
        this.monitor = monitor;
        this.logPrefix = logPrefix;
    }
```

上記のログプリフィックスの変数を扱うため、 `org.eclipse.edc.extension.health.HealthApiController` も改造する。

org/eclipse/edc/extension/health/HealthApiController.java:30

```java
public class HealthApiController {

    private final Monitor monitor;
    private final String logPrefix;

    public HealthApiController(Monitor monitor, String logPrefix) {
        this.monitor = monitor;
        this.logPrefix = logPrefix;
    }

    @GET
    @Path("health")
    public String checkHealth() {
        monitor.info(format("%s :: Received a health request", logPrefix));
        return "{\"response\":\"I'm alive!\"}";
    }
}
```

上記の通り、 `logPrefix` を取り扱うための実装が追加されている。

READMEにはいくつか考慮点が言及されていた。

* 設定値は定数として定義されるべき。また階層型構造を持てるようにすべき。
* デフォルト値を設けるか、もしくは例外（EdcException）を発するべき
* Extension自体はビジネスロジックを含まないようにすべき
* ビジネスロジックに設置値を直接渡せるようにすべき

つづいて、Management APIを実装する。


# 2. 参考

## 2.1. 概要

* [EDC公式ウェブサイト]
* [IDS]
* [NTTデータのコネクタ調査報告書]
* [EDC Conference 2022]
* [EDC Document]
* [EDCのYoutube動画]

[EDC公式ウェブサイト]: https://projects.eclipse.org/projects/technology.edc
[IDS]: https://internationaldataspaces.
[NTTデータのコネクタ調査報告書]: https://www.nttdata.com/global/ja/news/information/2022/072700/
[EDC Conference 2022]: https://www.youtube.com/playlist?list=PLw-f_YoTxWJU_quLpk9fGpq37gzvVZGc4
[EDC Document]: https://eclipse-edc.github.io/docs/#/
[EDCのYoutube動画]: https://www.youtube.com/@eclipsedataspaceconnector9622/featured

## 2.2. Connector動作

### 2.2.1. ソースコード

* [EDC Connector GitHub]
* [EDC Connector Getting Started]
* [EDC Connector Sample]
* [EDC Connector Sample/basic]
* [EDC Connector Sample/basic/basic-01-basic-connector]
* [EDC Connector Sample/basic/basic-02-health-endpoint]
* [EDC Connector Sample/basic/basic-03-configuration]

[EDC Connector GitHub]: https://github.com/eclipse-edc/Connector`
[EDC Connector Getting Started]: https://github.com/eclipse-edc/Connector#getting-started
[EDC Connector Sample]: https://github.com/eclipse-edc/Samples
[EDC Connector Sample/basic]: https://github.com/eclipse-edc/Samples/tree/main/basic
[EDC Connector Sample/basic/basic-01-basic-connector]: https://github.com/eclipse-edc/Samples/blob/main/basic/basic-01-basic-connector/README.md
[EDC Connector Sample/basic/basic-02-health-endpoint]: https://github.com/eclipse-edc/Samples/tree/main/basic/basic-02-health-endpoint
[EDC Connector Sample/basic/basic-03-configuration]: https://github.com/eclipse-edc/Samples/tree/main/basic/basic-03-configuration

### 2.2.2. ドキュメント

* [EDC Connector SampleのPrerequirments]
* [EDC Connector SampleのScopes]
* [EDC Connector SampleのBasic]
* [EDC Connector SampleのTransfer]

[EDC Connector SampleのPrerequirments]: https://github.com/eclipse-edc/Samples#prerequisites
[EDC Connector SampleのScopes]: https://github.com/eclipse-edc/Samples#scopes
[EDC Connector SampleのBasic]: https://github.com/eclipse-edc/Samples#basic
[EDC Connector SampleのTransfer]: https://github.com/eclipse-edc/Samples#transfer


<!-- vim: set et tw=0 ts=2 sw=2: -->
