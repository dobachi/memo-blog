---

title: IDS Dataspace Protocol
date: 2023-08-31 15:56:27
categories:
  - Knowledge Management
  - Data Spaces
  - IDS
tags:
  - Data Spaces
  - IDS

---

# メモ

最近のEDCでは、IDSが提唱しているDataspace Protocolが使用されている。
[International-Data-Spaces-Association/ids-specification] を眺めてコンテンツをざっくり書き下す。

## v0.8の位置づけ

以下のような記載あり。あくまでドラフト扱い。

> Working Draft 1 February 2023

## 概要

スキーマとプロトコルの仕様を示すものである。

* データのPublish
* 利用合意形成
* データアクセス

自律エンティティ（要はコネクタか）間でデータ共有するにはメタデータの提供が必要である。
以下、メタデータ管理として挙げられていた項目。

* data assetをDCAT Catalogに入れる方法
* Usage ControlをODRLポリシーとして表現する方法
* 契約合意を構文的に電子記録する方法
* データ転送プロトコルを用いてデータアセットにアクセスする方法

仕様として挙げられていたのは以下。

* Dataspace ModelとDataspace Terminologyドキュメント
* Catalog ProtocolとCatalog HTTPS Bindings（DCATカタログの公開、アクセス方法）
* Contract Negotiation ProtocolとContract Negotiation HTTPS Bindingドキュメント
* Transfer Process ProtocolとTransfer Process HTTPS BIndingsドキュメント

概ね、モデルを明らかにし、そのうえでカタログ、契約合意、データ転送の一連の流れに沿って仕様が示されている、と言える。

注意点として、データ転送プロセス自体は言及せずプロトコルのみ示されていることである。

[Protocol Overview]に各種情報へのリンクが載っている。

## インターオペラビリティの確保

Dataspace Protocolはインターオペラビリティを確保するために用いられる、とされている。
ただし、本プロトコルによりテクニカルな側面は担保されるが、セマンティックな側面はData Space参加者により担保されるべきとしている。

なお、異なるData Spaceを跨ぐインターオペラビリティは本ドキュメントの対象外である。

全体概要は、[Protocol Overview]の図を参照されたし。

以下は本ドキュメントではスコープ外だが、Data Space Protocolにとって必要。

* Identity Provider
  * Trust Frameworkを実現するための情報を提供する
  * 参加者（のエージェント、コネクタ）のバリデーション、請求内容のバリデーションが基本的な機能であるが、
    その請求の構造・内容はData Spaceごと、もっといえばIdentity Provider毎に異なる。
* モニタリング
* Policy Engine

## Terminology

[Terminology]に記載されているが、量は多くない。

特にポリシー周りの用語には注意したい。

* Assest: Participantによって共有されるデータやテクニカルサービス
* Policy: Asset利用のためのルール、義務、制限
* Offer: とあるAssetに結びつけられたPolicy
* Agreement: とあるAssetに結びつけられた具体的なPolicy。Provier、Consumerの両Participantにより署名されている

なお、関係性という意味では、Information ModelやParticipantAgent周りのクラス設計の方がわかりやすい。

## Information Model

[Information Model]に記載されている。
[Information Modelの関係図] に関係図が載っている。

以下、ポイントのみ記載。

### Dataspace Authority

ひとつ or 複数のDataspaceを管理する。
Participantの登録も含む。Participantにビジネスサーティフィケーションの取得（提出？）を求める、など。

### Participant、Participant Agent

ParticipantがDataspaceへの参加者であり、Participant Agentが実際のタスクを担う。
Participant Agentはcredentialから生成されたverifiable presentationを用いる。credentialは第三者のissuerから発行されたものを用いる。
また第三者のIdentity providerか提供されたID tokenも用いる。

### Identity Provider

トラストアンカー。
ID tokenを払い出す。ID tokenはParticipant Agentのアイデンティティの検証を行う。

複数のIdentity ProviderがひとつのDataspaceに存在することも許容される。

ID tokenのセマンティクスは本仕様書の対象外。

Identity Providerは外部でもよいし、Participant自身（e.g. DID）でもよい。

### Credential Issuer

Verifiable Credentialを発行する。

## ParticipantAgent周りのクラス設計

[ParticipantAgent周りのクラス設計]の図に大まかな設計が書かれている。

これによると、CatalogServiceとConnectorは同じParticipantAgentの一種である。

DCAT CatalogにはAsest EntryとDCAT DataServiceが含まれる。
ちなみに、DCAT DataServiceはAssetの提供元となるConnectorへのReferenceである。

Asset EntryはODRL Offerを保持する。当該Assetに紐づけられたUsage Control Policyである。

ConnectorもParticipant Agentの一種である。
Contract NegotiationとData Transferを担う。
Contract Negotiation結果、ODRL Agreementが生成される。ODRL Agreementは、合意された当該Assetに関するUsage Control Policyと言える。

## 実態的なクラス

Dataspace AuthorityやParticipant Agentのように、実際のフローには登場しないエンティティもあるようだ。
[Classesドキュメント] に実際のフローに登場するクラスの説明が記載されている。

## Catalog Protocol仕様

[Catalog Protocolの仕様]に以下のような要素の仕様が記載されている。

* message type: メッセージの構造
* message: message typeのインスタンス
* catalog: データ提供者によりオファーされたDCAT Catalog
* catalog service: 提供されたasset（の情報）を公表するParticipant Agent
* Consumer: 提供されたassetを要望するParticipant Agent

### Message Type

JSON-LDでシリアライズされたメッセージ。なお、将来的にはシリアライズ方式が追加される可能性がるようだ。

* CatalogRequestMessage: ConsumerからCatalog Serviceに送られる要望メッセージ。filterプロパティあり。
* Catalog: Providerから送られるAsset Entiry
* CatalogEror: ConsumerもしくはProviderから送られるエラーメッセージ
* DatasetRequestMessage: ConsumerからCatalog Serviceに送られる要望メッセージ。Catalog ServiceはDataset（DCAT Dataset）を答える。それにはデータセットのIDが含まれる。

### DCATとIDS Informationモデルの対応関係

* Asset Entity: DCAT Dataset
* Distributions: DCAT Distributions
* DataService: ConnectorのようなIDSサービスエンドポイント。なお、dataServiceTypeが定義されている。現状ではdspace:connectorのみか。

### Technical Consideration

[Technical Considerations]としてはクエリやフィルタ、レプリケーションプロトコル、セキュリティ、ブローカについて言及されている。

## Catalog HTTPS Binding

## Contract Negotiation仕様

ProviderとConsumerの間のContract Negotiation（CN）。
CNは、 https://www.w3.org/International/articles/idn-and-iri/ にてユニークに識別できる。
CNは状態遷移を経る。それらはProviderとConsumerにトラックされる。

### ステート変化

[Contract Negotiationのステート変化の図] にステート変化の概要が描かれている。

| ステート   | 説明                                                                                                                                                        | 
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | 
| REQUESTED  | ConsumerからOfferに基づいてリクエストが送られた状態。ProviderがAckを返した後。                                                                              | 
| OFFERED    | ProviderがConsumerにOfferを送った状態。ConsumerがAckを返した後。                                                                                            | 
| ACCEPTED   | Consumerが最新のContract Offerを承諾した状態。ProviderがAckを返した後。                                                                                     | 
| AGREED     | Providerが最新のContract Offerに承諾し、Consumerに合意を送った状態。ConsumerがAckを返した後。                                                               | 
| VERIFIED   | ConsumerがProviderに合意検証結果を返した状態。ProviderがAckを返した後。                                                                                     | 
| FINALIZED  | Providerが自身の合意検証結果を含むファイナライズのメッセージをConsumerに送った状態。ConsumerがAckを返した後。データがConsumerに利用可能な状態になっている。 | 
| TERMINATED | ProviderかConsumerがCNを終了させた状態。どちらからか終了メッセージが送られ、Ackが返る。                                                                     | 

### メッセージタイプ

[Contract NegotiationのMessage Types] に上記ステート変化における各種メッセージの説明が記載されている。
ほぼ名称通りの意味。

## Contract Negotiation HTTPS Bindings

## Transfer Process仕様

CNと同じく、Transfer Process (TP) もProviderとConsumerの両方に関係する。
またCNと同じくステート変化が定義されている。

### Control and Data Plane

TPはConnectorにより管理される。Connectorは2個のロジカルコンポーネントで成り立つ。

* Control Plane: 対抗のメッセージを受領し、TPステートを管理する
* Data Plane: 実際の転送を担う

これらはロジカルなものであり、実装では単独プロセスとしてもよい。

### アセット転送のタイプ

* push / pull
* finite / non-finite

[Push Transferの流れ] と [Pull Transferの流れ] にそれぞれの流れのイメージが載っている。
基本的な流れは同じだが、実際のデータやり取りの部分だけ異なる。

finiteデータの場合、データの転送が終わったらTPが終わる。
一方、non-finiteデータの場合は明示的に終了させる必要がある。
non-finiteデータはストリームデータ、APIエンドポイントが例として挙げられている。

### ステート変化

[Trasnfer Processのステート変化] にステート変化の様子が描かれている。

ステートはREQUESTED、STARTED、COMPLETED、SUSPENDED、TERMINATED。

### Message Type

[Transfer ProcessのMessage Type] にメッセージタイプが記載されている。
特筆すべきものはない。



# 参考

* [International-Data-Spaces-Association/ids-specification]
* [Protocol Overview]
* [Summary]
* [Terminology]
* [Information Model]
* [Information Modelの関係図]
* [ParticipantAgent周りのクラス設計]
* [Classesドキュメント]
* [Catalog Protocolの仕様]
* [Technical Considerations]
* [Contract Negotiationのステート変化の図]
* [Contract NegotiationのMessage Types]
* [Push Transferの流れ]
* [Pull Transferの流れ]
* [Trasnfer Processのステート変化]
* [Transfer ProcessのMessage Type]

[International-Data-Spaces-Association/ids-specification]: https://github.com/International-Data-Spaces-Association/ids-specification
[Protocol Overview]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/resources/figures/ProtocolOverview.png
[Summary]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/SUMMARY.md
[Terminology]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/model/terminology.md
[Information Model]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/model/model.md
[Information Modelの関係図]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/model/m.dataspace.relationships.png
[ParticipantAgent周りのクラス設計]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/model/m.participant.entities.png
[Classesドキュメント]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/model/model.md#22-classes
[Catalog Protocolの仕様]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/catalog/catalog.protocol.md
[Technical Considerations]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/catalog/catalog.protocol.md#4-technical-considerations
[Contract Negotiationのステート変化の図]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/negotiation/contract.negotiation.state.machine.png
[Contract NegotiationのMessage Types]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/negotiation/contract.negotiation.protocol.md#message-types
[Push Transferの流れ]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/transfer/push-transfer-process.png
[Pull Transferの流れ]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/transfer/pull-transfer-process.png
[Trasnfer Processのステート変化]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/transfer/transfer-process-state-machine.png
[Transfer ProcessのMessage Type]: https://github.com/International-Data-Spaces-Association/ids-specification/blob/main/transfer/transfer.process.protocol.md#message-types



<!-- vim: set et tw=0 ts=2 sw=2: -->
