---

title: memo of GXDCH
date: 2024-11-03 22:38:32
categories:
  - Knowledge Management
  - Trust
  - GXDCH
tags:
  - Trust
  - GXDCH

---

# メモ

[GXDCHウェブサイト]によると、GXDCHとは以下のように定義されている。

> The GXDCH is the necessary element to operationalize Gaia-X in the market. The Gaia-X Framework describes functional specifications, technical requirements, and SW assets necessary to be Gaia-X compliant. The GXDCH are a network of execution nodes for the compliance components that we have developed. This safeguards the distributed, decentralised ways of running the Gaia-X compliance, not operated centrally by the Association, and where anybody can benefit from the open, transparent, and secure federated digital ecosystem – thus making the Gaia-X mission a reality.

[Gaia-X Framework]や[Gaia-X Framework Knowledge Base]によると、
[Gaia-X Architecture DocumentのGaia-X Trust FRamework components]にGXDCHに含まれるコンポーネントが記載されている。

## Gaia-X Trust Framework components

[Gaia-X Architecture DocumentのGaia-X Trust FRamework components]の確認。

* Gaia-X Compliance
  * 参加者からVPを受取り、Reigstry内にあるSHACL shapeにより定義された条件（Gaia-Xのルール）に合致するかを確認する
* Gaia-X Registry
  * トラストアンカー、トラストアンカーのバリデーションプロセス結果、Gaia-X VCのshapeやスキーマなどを保存する
  * 技術的にはカタログの一部とも考えられる。
* Gaia-X Notary (LRN: Legal Registration Number)
  * Gaia-X VCを発行
  * 入力：LegalRegistrationNumber VC。そのVCがGaia-Xルールを満たすアイデンティフィケーション番号を少なくともひとつ有することをチェックする

## テクニカルガイドライン

[GXDCHテクニカルガイドライン]の確認。

ガイドラインに記載されている通り、Gaia-X AISBL自体はオペレーターではない。Gaia-X AISBLによって認定された組織がオペレーターになる。

必須コンポーネントは、上記に挙げた3⃣個。WizardとWalletとCatalogueは必須ではない。

* Wisard: VP内のVCにサインするためのUI。クライアント側
* Wallet: クレデンシャル保存し、サードパーティに提供できる
* Catalogue: まだ利用可能ではない、と書かれている。

V1系とV2系がある。今のところ、オペレートされているのはV1系の様子。

gx-complianceやgaia-x-notary-registrationnumberは、SSLキーペアとそのキーペアを用いて発行された証明書を求める。
証明書は、eIDAS Ecertか、EV-SSLである。日本だと、EV-SSLを用いることができるのではないかと思う。

コンポーネントの起動には、Helmチャートが提供されている。

## 動作させてみる

clone

```shell
cd ~/Sources
git clone https://gitlab.com/gaia-x/lab/gxdch.git
```

[gx-registry deployment]

# 参考

* [GXDCHウェブサイト]
* [Gaia-X Framework]
* [Gaia-X Framework Knowledge Base]
* [Gaia-X Architecture DocumentのGaia-X Trust FRamework components]
* [EUによる公式ドキュメント]
* [GXDCHテクニカルガイドライン]

* [gx-registry deployment]
* [gx-compliance deployment]
* [gaia-x-notary-registrationnumber]

[GXDCHウェブサイト]: https://gaia-x.eu/gxdch/
[Gaia-X Framework]: https://gaia-x.eu/gaia-x-framework/
[Gaia-X Framework Knowledge Base]: https://docs.gaia-x.eu/framework/
[Gaia-X Architecture DocumentのGaia-X Trust FRamework components]: https://docs.gaia-x.eu/technical-committee/architecture-document/23.10/gx_services/
[EUによる公式ドキュメント]: https://eur-lex.europa.eu/oj/direct-access.html
[GXDCHテクニカルガイドライン]: https://gitlab.com/gaia-x/lab/gxdch

[gx-registry deployment]: https://gitlab.com/gaia-x/lab/compliance/gx-registry/-/tree/main#deployment
[gx-compliance deployment]: https://gitlab.com/gaia-x/lab/compliance/gx-compliance/-/tree/main#deployment
[gaia-x-notary-registrationnumber]: https://gitlab.com/gaia-x/lab/compliance/gaia-x-notary-registrationnumber/-/tree/main#deployment



<!-- vim: set et tw=0 ts=2 sw=2: -->
