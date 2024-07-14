---

title: MVD_of_EDC
date: 2024-07-07 01:16:32
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

2024/7/12時点でプロジェクトのドキュメントが更新され、旧来Developer Documentとされていたものがなくなった。
その代わり、[README] に色々な記述が追加されている。今回はこれを使って試す。

## Identity & Trustについての説明

[README#Introduction] にある通り、Eclipse Dataspace Working Groupの下で、IdentityやTrustの仕様検討が行われている。
ただ、当該章に記載のリンクをたどると、Tractus-Xのサイトにたどり着く。 -> [Eclipse Tractus-X/identity-trust]
当該レポジトリのREADMEでも記載されているが、この状態は暫定のようだ。

```text
Until the first version of the specification from the working group is released and implemented, this repository contains the current specification implemented in the Catena-X data space. Maintenance is limited to urgent issues concerning the operation of this data space.
```

何はともあれ、2024/7現在は、Verifiable Credentialを用いたDecentralized Claims Protocolは絶賛仕様決定・実装中である。

## 目的

[README#Purpose] には、このデモの目的が記載されている。
このデモでは、2者のデータスペース参加者が、クレデンシャルを交換した後、DSPメッセージをやり取りする例を示す。

もちろん、旧来からの通り、このデモは商用化品質のものではなく、いくつかの [shortcut] が存在する。

## シナリオ

[management-domain] を用いたFederated Catalogsを用いている。

シナリオの概要をいかに示す。

![MVDシナリオの概要](/memo-blog/images/20240714_MVD_Scenario.png)

図の通り、Provider CorpとConsumer Corpの2種類の企業があり、　Provdier CorpにはQ&AとManufacturingという組織が存在する。Q&AとManufacturingにはそれぞれEDCが起動している。Provdier Copの親組織にはCatalogとIdentityHubが起動している。このIdentityHubはCatalog、EDC（provider-qna）、EDC（provider-manufacuturing）に共通である。また、participantIdも共通のものを使う。Consumer CorpにはEDCとIdentityHubがある。

### Data setup

図の通り、実際のデータ（assets）は各下部組織にある。そのカタログは直接外部に晒されない。その代わり、親組織であるProvider CorpのCatalog Server内のroot catalogにそのポインタ（catalog assets）が保持される。これにより、Consumer Corpはroot catalogを用いて、実際のassetの情報を解決できる。

(wip)

# 参考

* [Developer document] ... これはなくなった。
* [README]
* [README#Introduction]
* [Eclipse Tractus-X/identity-trust]
* [README#Purpose]
* [shortcut]
* [README/scenario]
* [management-domain]

[Developer document]: https://github.com/eclipse-edc/MinimumViableDataspace/tree/main/docs/developer
[README]: https://github.com/eclipse-edc/MinimumViableDataspace/blob/main/README.md
[README#Introduction]: https://github.com/eclipse-edc/MinimumViableDataspace/blob/main/README.md#introduction
[Eclipse Tractus-X/identity-trust]: https://github.com/eclipse-tractusx/identity-trust
[README#Purpose]: https://github.com/eclipse-edc/MinimumViableDataspace/blob/main/README.md#purpose-of-this-demo
[shortcut]: https://github.com/eclipse-edc/MinimumViableDataspace/blob/main/README.md#other-caveats-shortcuts-and-workarounds
[README/scenario]:https://github.com/eclipse-edc/MinimumViableDataspace/blob/main/README.md#the-scenario 
[management-domain]: https://github.com/eclipse-edc/Connector/blob/main/docs/developer/management-domains/management-domains.md


<!-- vim: set et tw=0 ts=2 sw=2: -->
