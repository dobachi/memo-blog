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

## 準備

もしまだソースコードを取得していなければ取得しておく。

```bash
git pull git@github.com:eclipse-edc/Connector.git
cd Connector
```
## 生成

ビルド環境にはJDK17を利用したいので、今回はDOckerで簡単に用意する。

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

## 軽く中身確認

試しにData Planeを見てみる。

### 概要

description部分を機械翻訳したのが以下である。

```
Data PlaneのパブリックAPIはデータプロキシであり、データコンシューマがData Planeインスタンスを通じて、プロバイダのデータソース（バックエンドのRest APIや内部データベースなど）から能動的にデータを問い合わせることを可能にします。
Data PlaneのパブリックAPIはプロキシであるため、すべての動詞（GET、POST、PUT、PATCH、DELETEなど）をサポートしており、データソースが必要になるまでデータを転送することができます。これは、実際のデータソースがRest APIそのものである場合に特に便利です。同じように、任意のクエリパラメータ、パスパラメータ、リクエストボディのセットも（HTTPサーバによって固定された範囲内で）サポートされ、実際のデータソースに伝えることができます。
```

企業が持つデータストアをデータソースとしてデータ連携する際、そのプロキシとして働く。

### transfer

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

# 参考

* [Generating the OpenApi Spec (*.yaml)]

[Generating the OpenApi Spec (*.yaml)]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/openapi.md




<!-- vim: set et tw=0 ts=2 sw=2: -->
