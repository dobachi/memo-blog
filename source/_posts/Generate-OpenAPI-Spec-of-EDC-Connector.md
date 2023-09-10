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

## DSP Data Planeの実装を確認する

`data-protocols/dsp` （[dsp]）以下に、Dataspace Protocolに対応したモジュールが含まれている。

例えば、`org.eclipse.edc.protocol.dsp.dispatcher.PostDspHttpRequestFactory`、`org.eclipse.edc.protocol.dsp.dispatcher.GetDspHttpRequestFactory`などのファクトリが定義されている。
これは、前述のPOST、GETオペレーションに対応するリクエストを生成するためのファクトリである。

以下は、カタログのリクエストを送るための実装である。

org/eclipse/edc/protocol/dsp/catalog/dispatcher/DspCatalogHttpDispatcherExtension.java:54

```java
    public void initialize(ServiceExtensionContext context) {
        messageDispatcher.registerMessage(
                CatalogRequestMessage.class,
                new PostDspHttpRequestFactory<>(remoteMessageSerializer, m -> BASE_PATH + CATALOG_REQUEST),
                new CatalogRequestHttpRawDelegate()
        );
        messageDispatcher.registerMessage(
                DatasetRequestMessage.class,
                new GetDspHttpRequestFactory<>(m -> BASE_PATH + DATASET_REQUEST + "/" + m.getDatasetId()),
                new DatasetRequestHttpRawDelegate()
        );
    }
```

他にも、`org.eclipse.edc.protocol.dsp.transferprocess.dispatcher.DspTransferProcessDispatcherExtension`などが挙げられる。
これは以下のように、`org.eclipse.edc.connector.transfer.spi.types.protocol.TransferRequestMessage`が含まれており、ConsumerがProviderにデータ転送プロセスをリクエストする際のメッセージのディスパッチャが登録されていることがわかる。

org/eclipse/edc/protocol/dsp/transferprocess/dispatcher/DspTransferProcessDispatcherExtension.java:60

```java
    public void initialize(ServiceExtensionContext context) {
        messageDispatcher.registerMessage(
                TransferRequestMessage.class,
                new PostDspHttpRequestFactory<>(remoteMessageSerializer, m -> BASE_PATH + TRANSFER_INITIAL_REQUEST),
                new TransferRequestDelegate(remoteMessageSerializer)
        );
        messageDispatcher.registerMessage(
                TransferCompletionMessage.class,
                new PostDspHttpRequestFactory<>(remoteMessageSerializer, m -> BASE_PATH + m.getProcessId() + TRANSFER_COMPLETION),
                new TransferCompletionDelegate(remoteMessageSerializer)
        );
        messageDispatcher.registerMessage(
                TransferStartMessage.class,
                new PostDspHttpRequestFactory<>(remoteMessageSerializer, m -> BASE_PATH + m.getProcessId() + TRANSFER_START),
                new TransferStartDelegate(remoteMessageSerializer)
        );
        messageDispatcher.registerMessage(
                TransferTerminationMessage.class,
                new PostDspHttpRequestFactory<>(remoteMessageSerializer, m -> BASE_PATH + m.getProcessId() + TRANSFER_TERMINATION),
                new TransferTerminationDelegate(remoteMessageSerializer)
        );
    }
```


◆参考情報はじめ

このファクトリは、ディスパッチャの `org.eclipse.edc.protocol.dsp.dispatcher.DspHttpRemoteMessageDispatcherImpl#dispatch` メソッドから、間接的に呼び出されて利用される。
このメソッドは`org.eclipse.edc.spi.message.RemoteMessageDispatcher#dispatch`メソッドを実装したものである。ディスパッチャとして、リモートへ送信するメッセージ生成をディスパッチするための。メソッドである。
さらに、これは `org.eclipse.edc.connector.core.base.RemoteMessageDispatcherRegistryImpl` 内で使われている。ディスパッチャのレジストリ内で、ディスパッチ処理が起動、管理されるようだ。
なお、これは`org.eclipse.edc.spi.message.RemoteMessageDispatcherRegistry#dispatch` を実装したものである。このメソッドは、色々なところから呼び出される。

例えば、TransferCoreExtensionクラスではサービス起動時に、転送プロセスを管理する`org.eclipse.edc.connector.transfer.process.TransferProcessManagerImpl`を起動する。

org/eclipse/edc/connector/transfer/TransferCoreExtension.java:205

```java
    @Override
    public void start() {
        processManager.start();
    }
```

これにより、以下のようにステートマシンがビルド、起動され、各プロセッサが登録される。

org/eclipse/edc/connector/transfer/process/TransferProcessManagerImpl.java:143

```java
        stateMachineManager = StateMachineManager.Builder.newInstance("transfer-process", monitor, executorInstrumentation, waitStrategy)
                .processor(processTransfersInState(INITIAL, this::processInitial))
                .processor(processTransfersInState(PROVISIONING, this::processProvisioning))
                .processor(processTransfersInState(PROVISIONED, this::processProvisioned))
                .processor(processTransfersInState(REQUESTING, this::processRequesting))
                .processor(processTransfersInState(STARTING, this::processStarting))
                .processor(processTransfersInState(STARTED, this::processStarted))
                .processor(processTransfersInState(COMPLETING, this::processCompleting))
                .processor(processTransfersInState(TERMINATING, this::processTerminating))
                .processor(processTransfersInState(DEPROVISIONING, this::processDeprovisioning))
                .build();
        stateMachineManager.start();
```

上記のプロセッサとして登録されている`org.eclipse.edc.connector.transfer.process.TransferProcessManagerImpl#processStarting`の中では `org.eclipse.edc.connector.transfer.process.TransferProcessManagerImpl#sendTransferStartMessage` が呼び出されている。

org/eclipse/edc/connector/transfer/process/TransferProcessManagerImpl.java:376

```java
        return entityRetryProcessFactory.doSyncProcess(process, () -> dataFlowManager.initiate(process.getDataRequest(), contentAddress, policy))
                .onSuccess((p, dataFlowResponse) -> sendTransferStartMessage(p, dataFlowResponse, policy))
                .onFatalError((p, failure) -> transitionToTerminating(p, failure.getFailureDetail()))
                .onFailure((t, failure) -> transitionToStarting(t))
                .onRetryExhausted((p, failure) -> transitionToTerminating(p, failure.getFailureDetail()))
                .execute(description);
```

`org.eclipse.edc.connector.transfer.process.TransferProcessManagerImpl#sendTransferStartMessage` メソッド内では、 `org.eclipse.edc.connector.transfer.spi.types.protocol.TransferStartMessage`のメッセージがビルドされ、
ディスパッチャにメッセージとして渡される。

org/eclipse/edc/connector/transfer/process/TransferProcessManagerImpl.java:386

```java
        var message = TransferStartMessage.Builder.newInstance()
                .processId(process.getCorrelationId())
                .protocol(process.getProtocol())
                .dataAddress(dataFlowResponse.getDataAddress())
                .counterPartyAddress(process.getConnectorAddress())
                .policy(policy)
                .build();

        var description = format("Send %s to %s", message.getClass().getSimpleName(), process.getConnectorAddress());

        entityRetryProcessFactory.doAsyncStatusResultProcess(process, () -> dispatcherRegistry.dispatch(Object.class, message))
                .entityRetrieve(id -> transferProcessStore.findById(id))
                .onSuccess((t, content) -> transitionToStarted(t))
                .onFailure((t, throwable) -> transitionToStarting(t))
                .onFatalError((n, failure) -> transitionToTerminated(n, failure.getFailureDetail()))
                .onRetryExhausted((t, throwable) -> transitionToTerminating(t, throwable.getMessage(), throwable))
                .execute(description);
```

◆参考情報おわり

ということで、`org.eclipse.edc.protocol.dsp.spi.dispatcher.DspHttpRemoteMessageDispatcher`というディスパッチャは、Dataspace Protocolに基づくリモートメッセージを生成する際に用いられるディスパッチャである。

## おまけ）古い（？）Data Planeの実装を確認する（HTTPの例）

Dataspace Protocol以前の実装か？

`extensions/data-plane` 以下にData Planeの実装が拡張として含まれている。

例えば、 `extensions/data-plane/data-plane-http` には、HTTPを用いてデータ共有するための拡張の実装が含まれている。
当該拡張のREADMEの通り、 （transfer APIの）`DataFlowRequest` が`HttpData`だった場合に、

* HttpDataSourceFactory
* HttpDataSinkFactory
* HttpDataSource
* HttpDataSink

の実装が用いられる。パラメータもREADMEに（[data-plane-httpのデザイン指針]）記載されている。
基本的には、バックエンドがHTTPなのでそれにアクセスするためのパラメータが定義されている。

当該ファクトリは、 `org.eclipse.edc.connector.dataplane.http.DataPlaneHttpExtension#initialize` 内で用いられている。

org/eclipse/edc/connector/dataplane/http/DataPlaneHttpExtension.java:75

```java
        var httpRequestFactory = new HttpRequestFactory();

        var sourceFactory = new HttpDataSourceFactory(httpClient, paramsProvider, monitor, httpRequestFactory);
        pipelineService.registerFactory(sourceFactory);

        var sinkFactory = new HttpDataSinkFactory(httpClient, executorContainer.getExecutorService(), sinkPartitionSize, monitor, paramsProvider, httpRequestFactory);
        pipelineService.registerFactory(sinkFactory);
```

ここでは、試しにData Source側を確認してみる。

org/eclipse/edc/connector/dataplane/http/pipeline/HttpDataSourceFactory.java:63

```java
    @Override
    public DataSource createSource(DataFlowRequest request) {
        var dataAddress = HttpDataAddress.Builder.newInstance()
                .copyFrom(request.getSourceDataAddress())
                .build();
        return HttpDataSource.Builder.newInstance()
                .httpClient(httpClient)
                .monitor(monitor)
                .requestId(request.getId())
                .name(dataAddress.getName())
                .params(requestParamsProvider.provideSourceParams(request))
                .requestFactory(requestFactory)
                .build();
    }
```

上記の通り、まずデータのアドレスを格納するインスタンスが生成され、
つづいて、HTTPのデータソースがビルドされる。

HTTPのData Sourceの実体は `org.eclipse.edc.connector.dataplane.http.pipeline.HttpDataSource` である。
このクラスはSPIの `org.eclipse.edc.connector.dataplane.spi.pipeline.DataSource`インタフェースを実装したものである。

`org.eclipse.edc.connector.dataplane.http.pipeline.HttpDataSource#openPartStream` がオーバライドされて実装されている。
詳しくは、[openPartStream]参照。



# 参考

## ドキュメント

* [Generating the OpenApi Spec (*.yaml)]
* [data-plane-httpのデザイン指針]

[Generating the OpenApi Spec (*.yaml)]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/openapi.md
[data-plane-httpのデザイン指針]: https://github.com/eclipse-edc/Connector/blob/main/extensions/data-plane/data-plane-http/README.md#design-principles

## ソースコード

* [openPartStream]
* [dsp]

[openPartStream]: https://github.com/eclipse-edc/Connector/blob/main/extensions/data-plane/data-plane-http/src/main/java/org/eclipse/edc/connector/dataplane/http/pipeline/HttpDataSource.java#L48
[dsp]: https://github.com/eclipse-edc/Connector/tree/main/data-protocols/dsp



<!-- vim: set et tw=0 ts=2 sw=2: -->
