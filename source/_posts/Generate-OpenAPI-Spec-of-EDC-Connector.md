---

title: Generate OpenAPI Spec of EDC Connector
date: 2023-09-09 22:26:58
categories:
  - Knowledge Management
  - Data Spaces
  - EDC
tags:
  - Data Spaces
  - EDC
  - OpenAPI

---

# メモ

EDCのConnectorのOpenAPIスペックを出力するための手順が[Generating the OpenApi Spec (*.yaml)]に記載されている。
これに従い、試しに出力してみることにする。

ただ、このSpecはいわゆる現在EDCが採用している、Dataspace Protocol仕様ではないものが含まれている可能性が高い。
pathが`/v2`となっているのは、Dataspace Protocol準拠か？ → 実際に調べてみると、v2が必ずしも、Dataspace Protocol向けというわけではなさそうである。

ちなみに、参考までに、IDSA Dataspace ConnectorのOpenAPI Specは [Dataspace ConnectorのOpenAPI Spec] にある。
このコネクタは昨年からあまり更新されていないので注意。

## 準備

もしまだソースコードを取得していなければ取得しておく。

```bash
git pull git@github.com:eclipse-edc/Connector.git
cd Connector
```
## 生成

ビルド環境にはJDK17を利用したいので、今回はDockerで簡単に用意する。

そのまま実行する場合：

```bash
docker run --rm -v ${PWD}:/local --workdir /local openjdk:17-alpine  ./gradlew clean resolve
```

いったんシェル立ち上げる場合：

```bash
docker run -it --rm -v ${PWD}:/local --workdir /local openjdk:17-alpine sh
./gradlew clean resolve
```

`BUILD SUCCESSFUL`となったらOK。

ちなみに、このYAMLファイル生成は自前のビルドツールを用いているようだ。参考：[SwaggerGeneratorExtension]

## Data Planeの中身を軽く確認

`resources/openapi/yaml/control-api/data-plane-api.yaml` にある、Data Planeを試しに見てみる。

### 概要

description部分を機械翻訳したのが以下である。

```
Data PlaneのパブリックAPIはデータプロキシであり、データコンシューマがData Planeインスタンスを通じて、プロバイダのデータソース（バックエンドのRest APIや内部データベースなど）から能動的にデータを問い合わせることを可能にします。
Data PlaneのパブリックAPIはプロキシであるため、すべての動詞（GET、POST、PUT、PATCH、DELETEなど）をサポートしており、データソースが必要になるまでデータを転送することができます。これは、実際のデータソースがRest APIそのものである場合に特に便利です。同じように、任意のクエリパラメータ、パスパラメータ、リクエストボディのセットも（HTTPサーバによって固定された範囲内で）サポートされ、実際のデータソースに伝えることができます。
```

企業が持つデータストアをデータソースとしてデータ連携する際、そのプロキシとして働く。

### paths

APIのパスを確認する。

#### transfer

データ転送をリクエストする。
リクエストボディには、データ転送のリクエスト情報が含まれる。

```yaml
  /transfer:
    post:
      description: Initiates a data transfer for the given request. The transfer will
        be performed asynchronously.
      operationId: initiateTransfer
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/DataFlowRequest'
      responses:
        "200":
          description: Data transfer initiated
        "400":
          description: Failed to validate request
      tags:
      - Data Plane control API
```

#### transfer/{processId}

パラメータ`processId`で与えられたIDのデータ転送処理の状態を確認する。

```yaml
  /transfer/{processId}:
    get:
      description: Get the current state of a data transfer.
      operationId: getTransferState
      parameters:
      - in: path
        name: processId
        required: true
        schema:
          type: string
      responses:
        "200":
          description: Missing access token
      tags:
      - Data Plane control API
```

#### /{any}

`/{any}`以下にはDELETE、GET、PATCH、POST、PUTのOperationが定義されている。

```yaml
  /{any}:
    delete:
    (snip)
    get:
    (snip)
    patch:
    (snip)
    post:
    (snip)
    put:
```

単純にデータを取得するだけではない。

## Transfer Data Plane

`resources/openapi/yaml/control-api/transfer-data-plane.yaml` に含まれるのは以下のSpecだった。
トークンを受け取り検証するAPIのようだ。

```yaml
openapi: 3.0.1
paths:
  /token:
    get:
      description: "Checks that the provided token has been signed by the present\
        \ entity and asserts its validity. If token is valid, then the data address\
        \ contained in its claims is decrypted and returned back to the caller."
      operationId: validate
      parameters:
      - in: header
        name: Authorization
        schema:
          type: string
      responses:
        "200":
          description: Token is valid
        "400":
          description: Request was malformed
        "403":
          description: Token is invalid
      tags:
      - Consumer Pull Token Validation
components:
  schemas:
    DataAddress:
      type: object
      properties:
        properties:
          type: object
          additionalProperties:
            type: object
```

## control-plane-api

`resources/openapi/yaml/control-api/control-plane-api.yaml` にコントロールプレーンのSpecが含まれている。

### /transferprocess/{processId}/complete

転送プロセスの完了をリクエストする。
転送が非同期、処理なので、受付成功が返る。

```yaml
  /transferprocess/{processId}/complete:
    post:
      description: "Requests completion of the transfer process. Due to the asynchronous\
        \ nature of transfers, a successful response only indicates that the request\
        \ was successfully received"
      operationId: complete
      parameters:
      - in: path
        name: processId
        required: true
        schema:
          type: string
      responses:
        "400":
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/ApiErrorDetail'
          description: "Request was malformed, e.g. id was null"
      tags:
      - Transfer Process Control Api
```

### /transferprocess/{processId}/fail

転送プロセスを失敗で完了させるリクエストを送る。

```yaml
    post:
      description: "Requests completion of the transfer process. Due to the asynchronous\
        \ nature of transfers, a successful response only indicates that the request\
        \ was successfully received"
      operationId: fail
      parameters:
      - in: path
        name: processId
        required: true
        schema:
          type: string
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/TransferProcessFailStateDto'
      responses:
        "400":
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/ApiErrorDetail'
          description: "Request was malformed, e.g. id was null"
      tags:
      - Transfer Process Control Api
```

### マネージメントAPIの類

`resources/openapi/yaml/management-api` 以下には、マネージメント系のAPIのSpecが。含まれている。

例えば、

* カタログ: おそらくDataspace Protocolに対応している。DCATカタログのやり取り。
  * `/v2/catalog/dataset/request`
  * `/v2/catalog/request`
* データアセット: データアドレスの情報と合わせて、データアセットを登録する
  * `/v2/assets`
    * post: 登録
    * put: 更新
  * `/v2/assets/request`: クエリに従ってアセット群を取得する
  * `/v2/assets/{assetId}/dataaddress`: データアドレスの更新
  * `/v2/assets/{id}`
    * delete: 消す
    * get: アセット取得
  * `/v2/assets/{id}/dataaddress`: アドレス取得
  * `/v3/assets` ... v3とは？
    * v2とおおよそ同じ
  * `/v3/assets/request`
    * v2とおおよそ同じ

など。ただ、`/v2`としていながら、DSPではなかったりするものがある（例：`/v2/contractnegotiations`）など注意が必要。

## Dataspace Protocol Architecture

[IDS Dataspace Protocolのドキュメント] にIDSプロトコル対応の概要が記載されている。

### 後方互換性

当該ドキュメントに記載の通り、後方互換性を保証するものではない。
新しいプロトコルに対応次第、古い実装は破棄される。

### ゴール

* （将来リリースされる？）IDS-TCK（IDS Test Compatibility Kit)の必須項目をパスすること
* Dataspace Protocol仕様を満たす他のコネクタと相互運用可能であること
* Dataspace Protocolよりも前のバージョンのIDSには対応しない。
* Usage Policyは実装しない。他のプロジェクトで実装される。

### アプローチ

Dataspace ProtocolはJSON-LD、DCAT、ODRLで実現されている。
このプロトコルの対応で、Contract NegotiationとTransfer Processステートが新たに実装されることになる。
ただし、新しいプロトコルの対応が完了するまで、テストが通るようにする。

1. [JSON-LD Processing Architecture] に基きJSON-LD対応する。
2. [Dataspace Protocol Endpoints and Services Architecture] に基きエンドポイントとサービスの拡張を実装する。
3. [Dataspace Protocol Contract Negotiation Architecture] に基きContract Negotiationマネージャのステートマシンを更新する。
4. [The Dataspace Protocol Transfer Process Architecture] に基きTransfer Processのステートマシンを更新する。
5. この1から4項目が安定すると、古いモジュールとサービスが削除される。
6. Management APIを更新する。

### JSON-LD Processing Architecture

[JSON-LD Processing Architecture] に


# 参考

## ドキュメント

* [Generating the OpenApi Spec (*.yaml)]
* [IDS Dataspace Protocolのドキュメント]
* [JSON-LD Processing Architecture]
* [Dataspace Protocol Endpoints and Services Architecture]
* [Dataspace Protocol Contract Negotiation Architecture]
* [The Dataspace Protocol Transfer Process Architecture]

[Generating the OpenApi Spec (*.yaml)]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/openapi.md
[IDS Dataspace Protocolのドキュメント]: https://github.com/eclipse-edc/Connector/tree/main/docs/developer/architecture/ids-dataspace-protocol
[JSON-LD Processing Architecture]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/architecture/ids-dataspace-protocol/json-ld-processing-architecture.md
[Dataspace Protocol Endpoints and Services Architecture]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/architecture/ids-dataspace-protocol/ids-endpoints-services-architecture.md
[Dataspace Protocol Contract Negotiation Architecture]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/architecture/ids-dataspace-protocol/contract-negotiation-architecture.md
[The Dataspace Protocol Transfer Process Architecture]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/architecture/ids-dataspace-protocol/transfer-process-architecture.md

## ソースコード

* [openPartStream]
* [dsp]
* [Dataspace ConnectorのOpenAPI Spec]
* [SwaggerGeneratorExtension]

[openPartStream]: https://github.com/eclipse-edc/Connector/blob/main/extensions/data-plane/data-plane-http/src/main/java/org/eclipse/edc/connector/dataplane/http/pipeline/HttpDataSource.java#L48
[dsp]: https://github.com/eclipse-edc/Connector/tree/main/data-protocols/dsp
[Dataspace ConnectorのOpenAPI Spec]: https://github.com/International-Data-Spaces-Association/DataspaceConnector/blob/main/openapi.yaml
[SwaggerGeneratorExtension]: https://github.com/eclipse-edc/GradlePlugins/blob/main/plugins/edc-build/src/main/java/org/eclipse/edc/plugins/edcbuild/extensions/SwaggerGeneratorExtension.java



<!-- vim: set et tw=0 ts=2 sw=2: -->
