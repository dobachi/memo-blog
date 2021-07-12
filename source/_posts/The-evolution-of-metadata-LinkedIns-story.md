---

title: 'The evolution of metadata: LinkedIn’s story'
date: 2020-01-04 15:42:04
categories:
  - Knowledge Management
  - Metadata Management
tags:
  - Metadata Management
  - LinkedIn

---

# 参考

* [The evolution of metadata LinkedIn’s story]
* [スライド]
* [LinkedInのdatahubの20200104時点での実装]
* [アーキテクチャ]
* [Generalized Metadata Architecture (GMA)]
* [Metadata Serving]
* [MAE(Metadata Audit Event)]

[The evolution of metadata LinkedIn’s story]: https://conferences.oreilly.com/strata/strata-ny-2019/public/schedule/detail/77575
[スライド]: https://cdn.oreillystatic.com/en/assets/1/event/300/The%20evolution%20of%20metadata_%20LinkedIn%E2%80%99s%20story%20Presentation.pdf
[LinkedInのdatahubの20200104時点での実装]: https://github.com/linkedin/WhereHows/tree/datahub
[アーキテクチャ]: https://github.com/linkedin/WhereHows/blob/datahub/docs/architecture/architecture.md
[Generalized Metadata Architecture (GMA)]:  https://github.com/linkedin/WhereHows/blob/datahub/docs/what/gma.md
[Metadata Serving]: https://github.com/linkedin/WhereHows/blob/datahub/docs/architecture/metadata-serving.md
[MAE(Metadata Audit Event)]: https://github.com/linkedin/WhereHows/blob/datahub/docs/what/mxe.md#metadata-audit-event-mae


# メモ

LinkedInが提唱する [Generalized Metadata Architecture (GMA)] を基盤としたメタデータ管理システム。

コンセプトは、 [スライド] に記載されているが、ざっとアーキテクチャのイメージをつかむには、
[アーキテクチャ] がよい。

## GMA

メタデータは自動収集。

これは標準化されたメタデータモデルとアクセスレイヤによるものである。

また標準モデルが、モデルファーストのアプローチを促進する。

## Metadata Serving

[Metadata Serving] に記載あり。

RESTサービスは、LinkedInが開発していると思われるREST.liが用いられており、
DAOもその中の「Pegasus」という仕組みを利用している。

Key-Value DAO、Search DAO、Query DAOが定義されている。

上記GMAの通り、この辺りのDAOによるアクセスレイヤの標準化が見て取れる。

## Metadata Ingestion Architecture

そもそも、メタデータに対する変更は [MAE(Metadata Audit Event)] としてキャプチャされる。

それがKafka Streamsのジョブで刈り取られ処理される。なお、シーケンシャルに処理されるための工夫もあるようだ。


<!-- vim: set et tw=0 ts=2 sw=2: -->
