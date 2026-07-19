---

title: Management Domain of EDC
date: 2024-07-14 12:09:34
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

## 概要

2024/6あたりから、 [EDC/management-domains] のドキュメントが追加された。

[EDC/management-domains/Introduction] の通り、Management Domainを利用することで、EDCコンポーネント群を組織的に管理することができる。
例えば、管理組織と下部組織にわけ、下部組織は管理組織に管理を委譲できる。

ここで言うEDCコンポーネントとは、例えば以下のようなものが挙げられている。

- Catalog Server
- Control Plane
- Data Plane
- Identity Hub

2024/7/14現在では、対象は以下のようになっている。

```
The current document will outline how management domains operate for three EDC components: the Catalog Server, Control Plane, and Data Plane.
```

## Topology

デプロイメトには種類がある。
大まかに分けて、単一構成（Single Management Domain）と分散型構成（Distributed Management Domains）である。

- 1: Single Mangement Domain
  - Catalog Server、Control Plane、Data Planeがすべて同一のプロセスもしくは同居プロセスに存在する。k8sで構成されるが、ひとつのドメインで管理される場合も含まれる。
  - [Single Management Domainの最も単純な例]
  - [Single Management Domainのクラスタの例]
- 2: Distributed Management Domains
  - 下部組織を持つ他国籍、複合企業体のような分散型のドメイン管理。この複合企業体は、ひとつのWeb DIDを用いる。当該複合企業体のデータを利用する企業は、ある下部組織のアクセス権しか持たないケースもある。
- 2a: Catalog Serverを持つ下部組織をRoot Catalogでまとめる
  - [Distributed Management DomainでCatalog Serverを持つ下部組織をまとめる例]
- 2b: 親のCatalog Serverが異なるManagement Domainを管理する
  - [Distributed Management DomainでCatalog Serverが下部組織の異なるManagement Domainを管理する例]
- 2c: 親のManagement DomainがCatalog ServerとControl Planeを持ち、下部組織のData Planeをまとめる
  - [Distributed Management Domainで親Management DomainがCatalog ServerとControl Planeをもつ例]

分散型の構成は、親Management Domainがどこまでを担うかによります。

## Architecture

EDCはDCAT3のCatalog型を利用する。Catalog型の親はDataset型である。
またCatalog型はほかの複数のCatalogを含むことができる。その際、Service型で定義する。
したがって、以下のような例になる。

```json
{
  "@context": "https://w3id.org/dspace/v0.8/context.json",
  "@id": "urn:uuid:3afeadd8-ed2d-569e-d634-8394a8836d57",
  "@type": "dcat:Catalog",
  "dct:title": "Data Provider Root Catalog",
  "dct:description": [
    "A catalog of catalogs"
  ],
  "dct:publisher": "Data Provider A",
  "dcat:catalog": {
    "@type": "dcat:Catalog",
    "dct:publisher": "Data Provider A",
    "dcat:distribution": {
      "@type": "dcat:Distribution",
      "dcat:accessService": "urn:uuid:4aa2dcc8-4d2d-569e-d634-8394a8834d77"
    },
    "dcat:service": [
      {
        "@id": "urn:uuid:4aa2dcc8-4d2d-569e-d634-8394a8834d77",
        "@type": "dcat:DataService",
        "dcat:endpointURL": "https://provder-a.com/subcatalog"
      }
    ]
  }
}
```
Sub CatalogはDCATのService型で関連付けされる。
この例は、Distributed Management Domainの2aに相当する。

アクセス管理についても考える。
2bのパターンのでは、親のCatalog Serverが下部組織のManagement Domainを管理する。そのため、ContractDefinitionにアクセス権を定義することで下部組織へのアクセス管理を実現する。

また、さらに集中型のControl Planeを設ける場合は、親のControl Planeが子のData Planeを管理する。

また、2024/7時点での設計では、複製を避けるようになっている。これは性能と単純さのためである。複合Catalogは上記の通り、ハイパーリンクを使用するようにしており、非同期のクローラで遅延ナビゲートされることも可能。
また、Catalogもそうだが、Contract NegotiationやTransfer Processのメタデータも複製されないことにも重きが置かれている。各Management Domainはそれぞれ責任を持って管理するべき、としている。
もし組織間で連携が必要な場合は読み取り専用の複製として渡すEDC拡張機能として実現可能である。
なお、個人的な所感だが、これは2aや2bであれば実現しうるが、2cだとControl Planeが親側に存在するため、Contract Negotiationの管理主体が親になってしまうのではないか、と思うがどうだろうか。Data Plane側はもしかしたら、下部組織側に残せるかもしれない。

## 実装

以上の内容を実現するため、いくつかEDCに変更が行われる。

* `Asset` にCatalogを示す真理値を追加。もし `@type` が `edc:CatalogAsset` の場合は真になる。
* Management APIが更新される。 `Asset` に `@type` を持てるように。
* `Dataset` の拡張として `Catalog` を追加
* `DatasetResolverImpl` を更新。 `Asset` のCatalogサブタイプを扱えるように。
* `JsonObjectFromDatasetTransformer ` をリファンクたリング。 `Catalog` サブタイプを扱えるように。

合わせて、Fedrated Catalog Crawler (FCC) をリファクタリング。複合カタログをナビゲートし、キャッシュできるように。
参加者ごとにCatalogの更新をアトミックに実行できるようにする必要がある。

Management APIはCatalogを要求する際、ローカルのFCCキャッシュを参照するようにリファクタリングされる。

Catalog Serverもリファクタリングされる。

# 参考

* [EDC/management-domains]
* [EDC/management-domains/Introduction]
* [Single Management Domainの最も単純な例]
* [Single Management Domainのクラスタの例]
* [Distributed Management DomainでCatalog Serverが下部組織の異なるManagement Domainを管理する例]
* [Distributed Management DomainでCatalog Serverを持つ下部組織をまとめる例]
* [Distributed Management Domainで親Management DomainがCatalog ServerとControl Planeをもつ例]

[EDC/management-domains]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/management-domains/management-domains.md
[EDC/management-domains/Introduction]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/management-domains/management-domains.md#0-introduction
[Single Management Domainの最も単純な例]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/management-domains/single.instance.svg
[Single Management Domainのクラスタの例]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/management-domains/cluster.svg
[Distributed Management DomainでCatalog Serverを持つ下部組織をまとめる例]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/management-domains/distributed.type2.a.svg
[Distributed Management DomainでCatalog Serverが下部組織の異なるManagement Domainを管理する例]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/management-domains/management-domains.md#type-2b-edc-catalog-server-and-controldata-plane-runtimes
[Distributed Management Domainで親Management DomainがCatalog ServerとControl Planeをもつ例]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/management-domains/distributed.type2.c.svg


<!-- vim: set et tw=0 ts=2 sw=2: -->