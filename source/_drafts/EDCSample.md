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
DISTRIB_DESCRIPTION="Ubuntu 22.04.4 LTS"

$ java -version
openjdk version "17.0.12" 2024-07-16
OpenJDK Runtime Environment (build 17.0.12+7-Ubuntu-1ubuntu222.04)
OpenJDK 64-Bit Server VM (build 17.0.12+7-Ubuntu-1ubuntu222.04, mixed mode, sharing)
```

EDCで利用しているJDKに合わせてJDK17を用いている。

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

READMEの通り、Sampleプロジェクトのrootでコンパイル実行すれば良い。

```shell
./gradlew clean basic:basic-01-basic-connector:build
java -jar basic/basic-01-basic-connector/build/libs/basic-connector.jar
```

特に何があるわけではない。コンソールに起動のメッセージが出力されるはず。

## Basic/Sample2

[EDC/Samples/Basic/Basic2/README] には以下の通り説明されている。

`ServiceExtension` と `src/main/resources/META-INF/services` ディレクトリ以下のプラグインファイルで構成される。
この例では `HealthEndpointExtension` というServiceExtensionを実装。

```java
public class HealthEndpointExtension implements ServiceExtension {

    @Inject
    WebService webService;

    @Override
    public void initialize(ServiceExtensionContext context) {
        webService.registerResource(new HealthApiController(context.getMonitor()));
    }
}
```

上記の通り、 `ServiceExtension` を拡張。また、中ではWebServiceをインジェクとしている。（DIのインジェクトについてはインターネットの情報を参考）
`initialize` メソッド内で、先にインジェクとした `webService` にリソースを登録している。

`org.eclipse.edc.web.spi.WebService` インターフェースは、例えば `org.eclipse.edc.web.jersey.JerseyRestService` として実装されている。
[Jersey] はシンプルなRESTfulサービスのフレームワークである。

上記で登録されているコントローラ `HealthApiController` は以下の通り。

```java
@Consumes({MediaType.APPLICATION_JSON})
@Produces({MediaType.APPLICATION_JSON})
@Path("/")
public class HealthApiController {

    private final Monitor monitor;

    public HealthApiController(Monitor monitor) {
        this.monitor = monitor;
    }

    @GET
    @Path("health")
    public String checkHealth() {
        monitor.info("Received a health request");
        return "{\"response\":\"I'm alive!\"}";
    }
}
```

特別なことはないが、上記の通り、 `checkHealth` メソッドを叩かれるとメッセージを残す。
実行の仕方は以下の通り。

```shell
./gradlew clean basic:basic-02-health-endpoint:build
java -jar basic/basic-02-health-endpoint/build/libs/connector-health.jar
```

http://localhost:8181/api/health にアクセスすればブラウザ上でメッセージが表示されることに加え、コンソールにもメッセージが生じる。

## Basic/Sample3

[EDC/Samples/Basic/Basic3/README] に以下のような説明がある。

設定をくくりだした `ConfigurationExtension` がある。
`org.eclipse.edc.configuration.filesystem.FsConfigurationExtension` がデフォルトの設定ファイル取り扱いのクラス。
このサンプルでは、Gradleの依存関係記述にて、 以下を指定することでJarファイルを含めるようにする。

basic/basic-03-configuration/build.gradle.kts:29

```gradle
(snip)
    implementation(libs.edc.configuration.filesystem)
(snip)
```

ここでは `/etc/eclipse/EDC/config.properties` という設定ファイルを作り利用する例を示す。
ポート番号を9191に変更する例。

```shell
sudo mkdir -p /etc/eclipse/EDC
sudo sh -c 'echo "web.http.port=9191" > /etc/eclipse/EDC/config.properties'
```

プロパティファイルを作ったので、それを利用するよう引数で指定して実行する。

```shell
./gradlew clean basic:basic-03-configuration:build
java -Dedc.fs.config=/etc/eclipse/EDC/config.properties -jar basic/basic-03-configuration/build/libs/filesystem-config-connector.jar
```

起動時に以下のようなログが見えるはず。

```java
INFO 2024-08-26T16:16:38.946828558 HTTP context 'default' listening on port 9191
DEBUG 2024-08-26T16:16:38.986329567 Port mappings: {alias='default', port=9191, path='/api'}
```

ちなみに、設定ファイルのデフォルトは以下の通り。

/home/dobachi/.gradle/caches/modules-2/files-2.1/org.eclipse.edc/configuration-filesystem/0.8.1/7741c1f790be0f02a2da844cd05edb469a5d095b/configuration-filesystem-0.8.1-sources.jar!/org/eclipse/edc/configuration/filesystem/FsConfigurationExtension.java:67
```java
        var configLocation = propOrEnv(FS_CONFIG, "dataspaceconnector-configuration.properties");
```

### 独自のプロパティの利用

本サンプルのREADMEに書いてある通り、先程のプロパティファイルに以下を追記。

```properties
edc.samples.basic.03.logprefix=MyLogPrefix
```

ログのプリフィックス文言を決めるためのプロパティを定義。

続いて、Sample2でも使用した `org.eclipse.edc.extension.health.HealthEndpointExtension` を改変。
プロパティ名を定義し、 `org.eclipse.edc.spi.system.SettingResolver#getSetting(java.lang.String, java.lang.String)`　メソッドを用いてプロパティの値を取れるようにした。

org/eclipse/edc/extension/health/HealthEndpointExtension.java:22

```java
public class HealthEndpointExtension implements ServiceExtension {

    @Inject
    WebService webService;

    private static final String LOG_PREFIX_SETTING = "edc.samples.basic.03.logprefix"; // this constant is new

    @Override
    public void initialize(ServiceExtensionContext context) {
        var logPrefix = context.getSetting(LOG_PREFIX_SETTING, "health"); //this line is new
        webService.registerResource(new HealthApiController(context.getMonitor(), logPrefix));
    }
}
```

http://localhsot:9191/health にアクセスすると、コンソールに以下のログが出る。

```java
INFO 2024-08-26T16:25:55.233519477 health :: Received a health request
```

## Transferスコープの概要

2個のコネクタ間でデータをやり取りする。プロバイダとコンシューマ。

## Transfer/Sample0（準備）

[EDC/Samples/Transfer/Transfer0/README]の通り、準備をする。
なお、このサンプルでは簡単化のために同一マシン上で、プロバイダとコンシューマを起動するが、本来は別々のところで起動するものである。

プロジェクトrootで以下を実行。
```shell
./gradlew transfer:transfer-00-prerequisites:connector:build
```

結果、ビルドされたJARファイルがここに配置される。
`transfer/transfer-00-prerequisites/connector/build/libs/connector.jar`

プロバイダとコンシューマは設定が異なるのみであり、JARは共通。
PATH配下の通り。

`transfer/transfer-00-prerequisites/resources/configuration/consumer-configuration.properties`

```properties
edc.participant.id=consumer
edc.dsp.callback.address=http://localhost:29194/protocol
web.http.port=29191
web.http.path=/api
web.http.management.port=29193
web.http.management.path=/management
web.http.protocol.port=29194
web.http.protocol.path=/protocol
edc.transfer.proxy.token.signer.privatekey.alias=private-key
edc.transfer.proxy.token.verifier.publickey.alias=public-key
web.http.public.port=29291
web.http.public.path=/public
web.http.control.port=29192
web.http.control.path=/control
```
`transfer/transfer-00-prerequisites/resources/configuration/provider-configuration.properties`

```properties
edc.participant.id=provider
edc.dsp.callback.address=http://localhost:19194/protocol
web.http.port=19191
web.http.path=/api
web.http.management.port=19193
web.http.management.path=/management
web.http.protocol.port=19194
web.http.protocol.path=/protocol
edc.transfer.proxy.token.signer.privatekey.alias=private-key
edc.transfer.proxy.token.verifier.publickey.alias=public-key
web.http.public.port=19291
web.http.public.path=/public
web.http.control.port=19192
web.http.control.path=/control
edc.dataplane.api.public.baseurl=http://localhost:19291/public
```

用いるポートを変えているのと、プロバイダ側にはデータプレーンのプロパティがあることがわかる。

プロバイダ実行：
```shell
java -Dedc.keystore=transfer/transfer-00-prerequisites/resources/certs/cert.pfx -Dedc.keystore.password=123456 -Dedc.fs.config=transfer/transfer-00-prerequisites/resources/configuration/provider-configuration.properties -jar transfer/transfer-00-prerequisites/connector/build/libs/connector.jar
```

キーやキーストアの設定、プロパティファイルのPATHを渡すのみ。

コンシューマ起動：

```shell
java -Dedc.keystore=transfer/transfer-00-prerequisites/resources/certs/cert.pfx -Dedc.keystore.password=123456 -Dedc.fs.config=transfer/transfer-00-prerequisites/resources/configuration/consumer-configuration.properties -jar transfer/transfer-00-prerequisites/connector/build/libs/connector.jar
```

プロバイダと同等。

## Transfer/Sample1（コントラクト・ネゴシエーション）

[EDC/Samples/Transfer/Transfer1/README] の通り以下のステップで進める。

* プロバイダのアセット（共有される対象のデータ）を作成
* プロバイダでアクセスポリシーを作成
* プロバイダでコントラクト定義を作成
* その後、コンシューマからコントラクト・ネゴシエーション

まずプロバイダでアセットを作成。

```shell
curl -d @transfer/transfer-01-negotiation/resources/create-asset.json \
  -H 'content-type: application/json' http://localhost:19193/management/v3/assets \
  -s | jq
```

curlコマンドの-dataオプションに `@` でファイルを渡しをしている。中身は以下の通り。

```json
{
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/"
  },
  "@id": "assetId",
  "properties": {
    "name": "product description",
    "contenttype": "application/json"
  },
  "dataAddress": {
    "type": "HttpData",
    "name": "Test asset",
    "baseUrl": "https://jsonplaceholder.typicode.com/users",
    "proxyPath": "true"
  }
}
```

ポリシ定義。

```shell
curl -d @transfer/transfer-01-negotiation/resources/create-policy.json \
  -H 'content-type: application/json' http://localhost:19193/management/v3/policydefinitions \
  -s | jq
```
渡しているファイルの中身は以下。

```json
{
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  },
  "@id": "aPolicy",
  "policy": {
    "@context": "http://www.w3.org/ns/odrl.jsonld",
    "@type": "Set",
    "permission": [],
    "prohibition": [],
    "obligation": []
  }
}
```

ポリシの中身は空に見える。
ちなみにレスポンスは以下のような感じ。

```json
{
  "@type": "IdResponse",
  "@id": "aPolicy",
  "createdAt": 1724662296875,
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

コントラクト定義を作成。

```shell
curl -d @transfer/transfer-01-negotiation/resources/create-contract-definition.json \
  -H 'content-type: application/json' http://localhost:19193/management/v3/contractdefinitions \
  -s | jq
```

渡しているファイルの中身は以下。

```json
{
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/"
  },
  "@id": "1",
  "accessPolicyId": "aPolicy",
  "contractPolicyId": "aPolicy",
  "assetsSelector": []
}
```

アクセスポリシやコントラクトポリシのIDを渡している。

コンシューマからカタログ情報を取得する。

```shell
curl -X POST "http://localhost:29193/management/v3/catalog/request" \
    -H 'Content-Type: application/json' \
    -d @transfer/transfer-01-negotiation/resources/fetch-catalog.json -s | jq
```

得られるカタログ。

```json
{
  "@id": "4ce1bc3d-ce1e-4308-b03e-b6596958a69d",
  "@type": "dcat:Catalog",
  "dcat:dataset": {
    "@id": "assetId",
    "@type": "dcat:Dataset",
    "odrl:hasPolicy": {
      "@id": "MQ==:YXNzZXRJZA==:Y2ZmODc1NmYtYTRjMC00NzMxLWJlNTItM2M2ZTVlMGI2YzA3",
      "@type": "odrl:Offer",
      "odrl:permission": [],
      "odrl:prohibition": [],
      "odrl:obligation": []
    },
    "dcat:distribution": [
      {
        "@type": "dcat:Distribution",
        "dct:format": {
          "@id": "HttpData-PULL"
        },
        "dcat:accessService": {
          "@id": "bb73ab52-bd72-448d-9629-8a21624b0577",
          "@type": "dcat:DataService",
          "dcat:endpointDescription": "dspace:connector",
          "dcat:endpointUrl": "http://localhost:19194/protocol",
          "dct:terms": "dspace:connector",
          "dct:endpointUrl": "http://localhost:19194/protocol"
        }
      },
      {
        "@type": "dcat:Distribution",
        "dct:format": {
          "@id": "HttpData-PUSH"
        },
        "dcat:accessService": {
          "@id": "bb73ab52-bd72-448d-9629-8a21624b0577",
          "@type": "dcat:DataService",
          "dcat:endpointDescription": "dspace:connector",
          "dcat:endpointUrl": "http://localhost:19194/protocol",
          "dct:terms": "dspace:connector",
          "dct:endpointUrl": "http://localhost:19194/protocol"
        }
      }
    ],
    "name": "product description",
    "id": "assetId",
    "contenttype": "application/json"
  },
  "dcat:distribution": [],
  "dcat:service": {
    "@id": "bb73ab52-bd72-448d-9629-8a21624b0577",
    "@type": "dcat:DataService",
    "dcat:endpointDescription": "dspace:connector",
    "dcat:endpointUrl": "http://localhost:19194/protocol",
    "dct:terms": "dspace:connector",
    "dct:endpointUrl": "http://localhost:19194/protocol"
  },
  "dspace:participantId": "provider",
  "participantId": "provider",
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "dcat": "http://www.w3.org/ns/dcat#",
    "dct": "http://purl.org/dc/terms/",
    "odrl": "http://www.w3.org/ns/odrl/2/",
    "dspace": "https://w3id.org/dspace/v0.8/"
  }
}
```

上記の通り、DCATで定義されている。ODRLで定義されたポリシのIDが示される、など。
他にもHttpDataでデータ共有されることや、サービス情報が載っている。

ここからコンシューマからプロバイダに向けてコントラクト・ネゴシエーションを行う。大まかな流れは以下。

* コンシューマがコントラクトオファを送る。
* プロバイダが自身のオファと照らし合わせ、届いたオファを検証する。
* プロバイダがアグリメントか、リジェクションを送る。
* 検証が成功していれば、アグリメントを保存する。

`negotiate-contract.json` のうち、`{{contract-offer-id}}` となっている箇所を、先程のカタログ情報から拾って埋める。
具体的には、以下のIDで埋める。

```json
    "odrl:hasPolicy": {
      "@id": "MQ==:YXNzZXRJZA==:Y2ZmODc1NmYtYTRjMC00NzMxLWJlNTItM2M2ZTVlMGI2YzA3",
```

コントラクト・ネゴシエーション実行。

```shell
curl -d @transfer/transfer-01-negotiation/resources/negotiate-contract.json \
  -X POST -H 'content-type: application/json' http://localhost:29193/management/v3/contractnegotiations \
  -s | jq
```

以下のようなレスポンスが得られる。コントラクト・ネゴシエーション中のIDである。

```json
{
  "@type": "IdResponse",
  "@id": "4515e87b-5bd0-4c19-aa92-1968b65005e5",
  "createdAt": 1724664162792,
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

コントラクト・ネゴシエーションはプロバイダとコンシューマのそれぞれで非同期的に進む。
最終的に両者がconfirmedかdeclinedになったら終了。

コンシューマでの状態確認。先程得られたIDを使う。

```shell
curl -X GET "http://localhost:29193/management/v3/contractnegotiations/4515e87b-5bd0-4c19-aa92-1968b65005e5" \
    --header 'Content-Type: application/json' \
    -s | jq
```

以下のように、Finalized担ったことがわかる。

```json
{
  "@type": "ContractNegotiation",
  "@id": "4515e87b-5bd0-4c19-aa92-1968b65005e5",
  "type": "CONSUMER",
  "protocol": "dataspace-protocol-http",
  "state": "FINALIZED",
  "counterPartyId": "provider",
  "counterPartyAddress": "http://localhost:19194/protocol",
  "callbackAddresses": [],
  "createdAt": 1724664162792,
  "contractAgreementId": "74ed3714-3380-4888-93f9-71b948d09553",
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

## Transfer/Sample2（コンシューマPull）

[EDC/Samples/Transfer/Transfer2/README] に記載の通り、以下のステップで進める。

* コンシューマからファイル転送（の手続き）を始める。
* プロバイダが `EndpointDataReference` をコンシューマに送る。
* コンシューマがエンドポイントを使ってデータをフェッチする。 

転送開始。
前の章で得られた、コントラクト・アグリメントのIDを `transfer/transfer-02-consumer-pull/resources/start-transfer.json` に埋め込む。

```shell
curl -X POST "http://localhost:29193/management/v3/transferprocesses" \
  -H "Content-Type: application/json" \
  -d @transfer/transfer-02-consumer-pull/resources/start-transfer.json \
  -s | jq
```

結果は以下の通り。
`TransferProcess` が生成された。

```json
{
  "@type": "IdResponse",
  "@id": "0778ef5a-0999-42fb-ad16-6572ca1c04d6",
  "createdAt": 1724665640700,
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

状態を確認する。先程得られたTransferProcessのIDを利用。

```shell
curl http://localhost:29193/management/v3/transferprocesses/0778ef5a-0999-42fb-ad16-6572ca1c04d6 \
  -s | jq
```

結果の例。

```json
{
  "@id": "0778ef5a-0999-42fb-ad16-6572ca1c04d6",
  "@type": "TransferProcess",
  "state": "STARTED",
  "stateTimestamp": 1724665641835,
  "type": "CONSUMER",
  "callbackAddresses": [],
  "correlationId": "f0837ef5-999c-41dc-89b9-74d9337ecb5f",
  "assetId": "assetId",
  "contractId": "74ed3714-3380-4888-93f9-71b948d09553",
  "transferType": "HttpData-PULL",
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

`state` が `started` 担っていることがわかる。

DTRがコンシューマに送られているはず、さらにキャッシュされているはずなので、それを取得する。

```shell
curl http://localhost:29193/management/v3/edrs/0778ef5a-0999-42fb-ad16-6572ca1c04d6/dataaddress \
  -s | jq
```

結果の例。

```json
{
  "@type": "DataAddress",
  "type": "https://w3id.org/idsa/v4.1/HTTP",
  "endpoint": "http://localhost:19291/public",
  "authType": "bearer",
  "endpointType": "https://w3id.org/idsa/v4.1/HTTP",
  "authorization": "eyJraWQiOiJwdWJsaWMta2V5IiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJwcm92aWRlciIsImF1ZCI6ImNvbnN1bWVyIiwic3ViIjoicHJvdmlkZXIiLCJpYXQiOjE3MjQ2NjU2NDE3NzEsImp0aSI6ImJjNmQ1YzIzLTExMWUtNGZkZi1hMjMwLTJkZjk3NmE3NTFlOSJ9.dYBBx2z2XCjg1TgbEPiDgb2KYdUlNMd7702P4t0NgwYKhDemAKF64qGpLsU63huQ2WMb9Co4sC1euopyY-48F3UvfjK0ulKODlrfVGO-7xvSNs4qX2HVC9JyLGGbdks0wQOkv9oA7AcKxD11yTjcfbtLc-DUoOF4w4RTpI2MATSa-ETvKo_22FxMrIHgnsLOCHtjVLazJchFm4bAhVa7mRfHykkTpIIEaPuqOJpdtKcX1YUAZloFaI1ZinfXNtHjvollVC9Mjb4H12Gh1B7tLxgZ0AbP0izFeOHnQleQ09ZThajwF-xpnPQ5P5fsNiFqthW2A7Gu5-PLGT6tp2lYIg",
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

上記の通り、エンドポイントURLと認証キーがわかる。
データを取得する。

```shell
curl --location --request GET 'http://localhost:19291/public/' \
  --header 'Authorization: eyJraWQiOiJwdWJsaWMta2V5IiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJwcm92aWRlciIsImF1ZCI6ImNvbnN1bWVyIiwic3ViIjoicHJvdmlkZXIiLCJpYXQiOjE3MjQ2NjU2NDE3NzEsImp0aSI6ImJjNmQ1YzIzLTExMWUtNGZkZi1hMjMwLTJkZjk3NmE3NTFlOSJ9.dYBBx2z2XCjg1TgbEPiDgb2KYdUlNMd7702P4t0NgwYKhDemAKF64qGpLsU63huQ2WMb9Co4sC1euopyY-48F3UvfjK0ulKODlrfVGO-7xvSNs4qX2HVC9JyLGGbdks0wQOkv9oA7AcKxD11yTjcfbtLc-DUoOF4w4RTpI2MATSa-ETvKo_22FxMrIHgnsLOCHtjVLazJchFm4bAhVa7mRfHykkTpIIEaPuqOJpdtKcX1YUAZloFaI1ZinfXNtHjvollVC9Mjb4H12Gh1B7tLxgZ0AbP0izFeOHnQleQ09ZThajwF-xpnPQ5P5fsNiFqthW2A7Gu5-PLGT6tp2lYIg' \
  -s | jq
```

以下のような結果が得られる。

```json
[                                                               
  {                                               
    "id": 1,                                                                                                                                                                         
    "name": "Leanne Graham",                                                                                                                                                                                                                                                                                                                                               
    "username": "Bret",                                                                                                                                                                                                                                                                                                                                                    
    "email": "Sincere@april.biz",
    "address": {
      "street": "Kulas Light",
      "suite": "Apt. 556",
      "city": "Gwenborough",
      "zipcode": "92998-3874",
      "geo": {
        "lat": "-37.3159",
        "lng": "81.1496"
      }
    },
(snip)
```

https://jsonplaceholder.typicode.com/users にあるデータをコネクタのコントラクトを通じて得られた。

Pullするときに、以下のようにするとユーザIDを指定できる。

http://localhost:19291/public/1

## Transfer/Sample3（プロバイダPush）

[EDC/Samples/Transfer/Transfer3/README] に記載の通り、今度はプロバイダからPushする例である。
大まかな流れは以下の通り。

* ファイル転送
  * コンシューマからファイル転送（の手続き）を始める。
  * プロバイダのコントロールプレーンが実際のデータのアドレスを取得し、`DataRequest` をもとに `DataFlowRequest` を作成する。
* プロバイダデータプレーンが実際のデータソースからデータを取得。
* プロバイダデータプレーンがコンシューマサービスにデータを送る。

まずコンシューマ側のバックエンドのロガーを起動する。これがPush先になると見られる。今回はDockerで起動する。

```shell
docker build -t http-request-logger util/http-request-logger
docker run -p 4000:4000 http-request-logger
```

続いて以下のファイルを編集した上でTransferProcessを開始する。
`transfer/transfer-03-provider-push/resources/start-transfer.json`
なお、変更するのはコントラクト・アグリメントIDである。上記のケースでは、 `74ed3714-3380-4888-93f9-71b948d09553` である。

```shell
curl -X POST "http://localhost:29193/management/v3/transferprocesses" \
    -H "Content-Type: application/json" \
    -d @transfer/transfer-03-provider-push/resources/start-transfer.json \
    -s | jq
```

なお、 `start-transfer.json` で指定している `dataDestination` にHttpProxy以外のものを指定しているのがポイントのようだ。

transfer/transfer-03-provider-push/resources/start-transfer.json

```json
{
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/"
  },
  "@type": "TransferRequestDto",
  "connectorId": "provider",
  "counterPartyAddress": "http://localhost:19194/protocol",
  "contractId": "74ed3714-3380-4888-93f9-71b948d09553",
  "assetId": "assetId",
  "protocol": "dataspace-protocol-http",
  "transferType": "HttpData-PUSH",
  "dataDestination": {
    "type": "HttpData",
    "baseUrl": "http://localhost:4000/api/consumer/store"
  }
}
```

結果の例。

```json
{
  "@type": "IdResponse",
  "@id": "105477c9-dbff-4577-adb5-2e860f9be585",
  "createdAt": 1724678897615,
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

結果確認。

```shell
curl http://localhost:29193/management/v3/transferprocesses/105477c9-dbff-4577-adb5-2e860f9be585 \
  -s | jq
```

結果の例。

```json
  "@id": "105477c9-dbff-4577-adb5-2e860f9be585",
  "@type": "TransferProcess",
  "state": "COMPLETED",
  "stateTimestamp": 1724678900583,
  "type": "CONSUMER",
  "callbackAddresses": [],
  "correlationId": "657b63b0-920d-412c-9c09-edb48057e717",
  "assetId": "assetId",
  "contractId": "74ed3714-3380-4888-93f9-71b948d09553",
  "transferType": "HttpData-PUSH",
  "dataDestination": {
    "@type": "DataAddress",
    "type": "HttpData",
    "baseUrl": "http://localhost:4000/api/consumer/store"
  },
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

`Completed` である。

ロガーのコンソールに以下の表示。

```json
Incoming request                                                                         
Method: POST                                              
Path: /api/consumer/store
Body:
[
  {
    "id": 1,
    "name": "Leanne Graham",
    "username": "Bret",
    "email": "Sincere@april.biz",
    "address": {
      "street": "Kulas Light",
(snip)
```

これ、Push先のエンドポイントはどうやって知るのか。カタログ？

## Transfer/Sample4

[EDC/Samples/Transfer/Transfer4/README] の通り、コンシューマで転送完了に反応する機能を追加する。

モジュール構成は以下。

* consumer-with-listener: コンシューマ（コネクタ）のイベント・コンシューマ拡張
* listener: イベントを処理する `TransferProcessListener` の実装

ドキュメントでは、 `TransferProcessListener` の実装として `org.eclipse.edc.sample.extension.listener.TransferProcessStartedListener` を紹介。

エントリポイントは `org.eclipse.edc.sample.extension.listener.TransferProcessStartedListenerExtension` である。

org/eclipse/edc/sample/extension/listener/TransferProcessStartedListenerExtension.java:21
```java
public class TransferProcessStartedListenerExtension implements ServiceExtension {

    @Override
    public void initialize(ServiceExtensionContext context) {
        var transferProcessObservable = context.getService(TransferProcessObservable.class);
        var monitor = context.getMonitor();
        transferProcessObservable.registerListener(new TransferProcessStartedListener(monitor));
    }

}
```

上記の通り、 `org.eclipse.edc.sample.extension.listener.TransferProcessStartedListener` をリスナとして登録している。

ポイントは以下。

org/eclipse/edc/sample/extension/listener/TransferProcessStartedListener.java:34

```java
    @Override
    public void preStarted(final TransferProcess process) {
        monitor.debug("TransferProcessStartedListener received STARTED event");
        // do something meaningful before transfer start
    }
```
`START` イベントを受け取ったときに、ログに出力する。

このサンプルのビルドと実行をするのだが、その前に前の章まで使用していたコンシューマを止める。

その上で、以下を実行して、Sample4のコンシューマを起動する。

```shell
./gradlew transfer:transfer-04-event-consumer:consumer-with-listener:build
java -Dedc.keystore=transfer/transfer-00-prerequisites/resources/certs/cert.pfx -Dedc.keystore.password=123456 -Dedc.fs.config=transfer/transfer-00-prerequisites/resources/configuration/consumer-configuration.properties -jar transfer/transfer-04-event-consumer/consumer-with-listener/build/libs/connector.jar
```

続いて、新しいコントラクト・ネゴシエーション。

```shell
curl -d @transfer/transfer-01-negotiation/resources/negotiate-contract.json \
  -X POST -H 'content-type: application/json' http://localhost:29193/management/v3/contractnegotiations \
  -s | jq
```

結果例。

```json
{
  "@type": "IdResponse",
  "@id": "fe8c4f16-283c-4d74-a440-715e8371d228",
  "createdAt": 1724766448685,
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

先の例と同様にコントラクト・アグリメントIDを取得する。
直前の結果から、コントラクト・ネゴシエーションIDを抜き出して下記のコマンドに入れるのを忘れずに。

```shell
curl -X GET "http://localhost:29193/management/v3/contractnegotiations/fe8c4f16-283c-4d74-a440-715e8371d228" \
    --header 'Content-Type: application/json' \
    -s | jq
```

結果例。

```json
{
  "@type": "ContractNegotiation",
  "@id": "fe8c4f16-283c-4d74-a440-715e8371d228",
  "type": "CONSUMER",
  "protocol": "dataspace-protocol-http",
  "state": "FINALIZED",
  "counterPartyId": "provider",
  "counterPartyAddress": "http://localhost:19194/protocol",
  "callbackAddresses": [],
  "createdAt": 1724766448685,
  "contractAgreementId": "8e96f6c5-cb0e-4f06-beb0-ac553ddb160e",
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

コントラクト・アグリメントIDは `8e96f6c5-cb0e-4f06-beb0-ac553ddb160e` である。

つづいて、 `transfer/transfer-02-consumer-pull/resources/start-transfer.json` の今コントラクト・アグリメントIDを書き換えつつ、ファイル転送を開始する。
該当箇所は以下。

```json
  "contractId": "8e96f6c5-cb0e-4f06-beb0-ac553ddb160e",
```

実行コマンドは以下。

```shell
curl -X POST "http://localhost:29193/management/v3/transferprocesses" \
  -H "Content-Type: application/json" \
  -d @transfer/transfer-02-consumer-pull/resources/start-transfer.json \
  -s | jq
```

実行結果例。

```json
{
  "@type": "IdResponse",
  "@id": "b4dff4b1-dfb2-470e-a765-7bd549a1e2b6",
  "createdAt": 1724766768403,
  "@context": {
    "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
    "edc": "https://w3id.org/edc/v0.0.1/ns/",
    "odrl": "http://www.w3.org/ns/odrl/2/"
  }
}
```

先ほど起動したコンシューマのコンソールログを見ると

```
DEBUG 2024-08-27T22:52:49.930105146 TransferProcessStartedListener received STARTED event
```

のようなメッセージが見つかるはず。

## Transfer/Sample5

（このサンプルはAzureとAWSの環境が必要なのと手違いの被害が大きいことからメモだけとする）

[EDC/Samples/Transfer/Transfer5/README] に記載の通り、これまで実行したサンプルに対し、通常使うであろう機能を足していく。
この例では、具体的には「Azureのストレージから読んで、AWSのストレージに書く」というのを実現する。

なお、環境構成には、Terraformが使われている。
`transfer/transfer-05-file-transfer-cloud/terraform` にもろもろ格納されている。
中身を見ると、割といろいろとセットアップしているのがわかる。念の為、潰しても良いクリーンな環境で試すのが良い。
一応６章にて環境をクリーンナップする手順が記載されている。

READMEにある通り、クライアントIDなどはVault内に保持するようになっている。
依存関係にもVaultがある。

transfer/transfer-05-file-transfer-cloud/cloud-transfer-consumer/build.gradle.kts:31

```groovy
(snip)
    implementation(libs.edc.vault.azure)
(snip)
```

今サンプルのメインの一つは、 `org.eclipse.edc.sample.extension.transfer.CloudTransferExtension` である。

`org.eclipse.edc.sample.extension.transfer.CloudTransferExtension#registerDataEntries` メソッドがアセットを定義する。

```java
    public void registerDataEntries() {
          var dataAddress = DataAddress.Builder.newInstance()
                  .type("AzureStorage")
                  .property("account", "<storage-account-name>")
                  .property("container", "src-container")
                  .property("blobname", "test-document.txt")
                  .keyName("<storage-account-name>-key1")
                  .build();
          var asset = Asset.Builder.newInstance().id("1").dataAddress(dataAddress).build();
          assetIndex.create(asset);
```

なお、`org.eclipse.edc.connector.controlplane.policy.spi.store.PolicyDefinitionStore` と
`org.eclipse.edc.connector.controlplane.contract.spi.offer.store.ContractDefinitionStore`
があり、それぞれポリシとコントラクトを保持する。今回のサンプルではインメモリで保持する実装を利用。

このあとはいつもどおり、コントラクト・ネゴシエーションしてコントラクト・アグリメントIDを取得し、実際のデータ転送。
ほぼこれまで通りだが、dataDestinationでAWS S3を指定しているところがポイント。

```shell
curl --location --request POST 'http://localhost:9192/management/v3/transferprocesses' \
--header 'X-API-Key: password' \
--header 'Content-Type: application/json' \
--data-raw '
{
  "counterPartyAddress": "http://localhost:8282/protocol",
  "protocol": "dataspace-protocol-http",
  "connectorId": "consumer",
  "assetId": "1",
  "contractId": "<ContractAgreementId>",
  "dataDestination": {
    "type": "AmazonS3",
    "region": "us-east-1",
    "bucketName": "<Unique bucket name>"
  },
  "transferType": {
    "contentType": "application/octet-stream",
    "isFinite": true
  }
}'
```
# 参考

## レポジトリ内

* [EDC/Samples]
* [EDC/Samples/README]
* [EDC/Samples/Basic/README]
* [EDC/Samples/Basic/Basic1/README] 
* [EDC/Samples/Basic/Basic1/build.gradle.kts]
* [EDC/Samples/Basic/Basic2/README]
* [EDC/Samples/Basic/Basic3/README]
* [EDC/Samples/Transfer/Transfer0/README]
* [EDC/Samples/Transfer/Transfer1/README]
* [EDC/Samples/Transfer/Transfer2/README]
* [EDC/Samples/Transfer/Transfer3/README]
* [EDC/Samples/Transfer/Transfer4/README]
* [EDC/Samples/Transfer/Transfer5/README]

[EDC/Samples]: https://github.com/eclipse-edc/Samples
[EDC/Samples/README]: https://github.com/eclipse-edc/Samples?tab=readme-ov-file#edc-samples
[EDC/Samples/Basic/README]: https://github.com/eclipse-edc/Samples/blob/main/basic/README.md
[EDC/Samples/Basic/Basic1/README]: https://github.com/eclipse-edc/Samples/blob/main/basic/basic-01-basic-connector/README.md
[EDC/Samples/Basic/Basic1/build.gradle.kts]: https://github.com/eclipse-edc/Samples/blob/main/basic/basic-01-basic-connector/build.gradle.kts
[EDC/Samples/Basic/Basic2/README]: https://github.com/eclipse-edc/Samples/blob/main/basic/basic-02-health-endpoint/README.md
[EDC/Samples/Basic/Basic3/README]: https://github.com/eclipse-edc/Samples/blob/main/basic/basic-03-configuration/README.md
[EDC/Samples/Transfer/Transfer0/README]: https://github.com/eclipse-edc/Samples/blob/main/transfer/transfer-00-prerequisites/README.md
[EDC/Samples/Transfer/Transfer1/README]: https://github.com/eclipse-edc/Samples/blob/main/transfer/transfer-01-negotiation/README.md
[EDC/Samples/Transfer/Transfer2/README]: https://github.com/eclipse-edc/Samples/blob/main/transfer/transfer-02-consumer-pull/README.md
[EDC/Samples/Transfer/Transfer3/README]: https://github.com/eclipse-edc/Samples/blob/main/transfer/transfer-03-provider-push/README.md
[EDC/Samples/Transfer/Transfer4/README]: https://github.com/eclipse-edc/Samples/blob/main/transfer/transfer-04-event-consumer/README.md
[EDC/Samples/Transfer/Transfer5/README]: https://github.com/eclipse-edc/Samples/blob/main/transfer/transfer-05-file-transfer-cloud/README.md

## EDCレポジトリ

* [BaseRuntime]

[BaseRuntime]: https://github.com/eclipse-edc/Connector/blob/releases/core/common/boot/src/main/java/org/eclipse/edc/boot/system/runtime/BaseRuntime.java

## 外部

* [EDC/documentation]
* [EDC/YT] 
* [Jersey]

* [dobachi/EDCSampleAnsible]

[EDC/documentation]: https://eclipse-edc.github.io/docs/#/
[EDC/YT]: https://www.youtube.com/@eclipsedataspaceconnector9622/featured
[Jersey]: https://eclipse-ee4j.github.io/jersey/
[dobachi/EDCSampleAnsible]: https://github.com/dobachi/EDCSampleAnsible



<!-- vim: set et tw=0 ts=2 sw=2: -->
