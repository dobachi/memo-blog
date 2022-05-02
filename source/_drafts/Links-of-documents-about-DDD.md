---

title: Links of documents about DDD
date: 2021-09-23 23:19:21
categories:
tags:

---

# 参考

## ドメイン駆動設計のまとめ系ドキュメント

* [ドメイン駆動設計とは何なのか？ ユーザーの業務知識をコードで表現する開発手法について]
* [コンテキスト境界を定義する - Eric Evans氏のDDD Europeでの講演より]
* [Language in Context - Eric Evans - DDD Europe 2019]
* [データモデリングとドメイン駆動設計]

[ドメイン駆動設計とは何なのか？ ユーザーの業務知識をコードで表現する開発手法について]: /mnt/c/Users/dobachi/Sources/memo-blog-text/source/_posts/Links-of-documents-about-DDD.md
[コンテキスト境界を定義する - Eric Evans氏のDDD Europeでの講演より]: https://www.infoq.com/jp/news/2019/09/bounded-context-eric-evans/
[Language in Context - Eric Evans - DDD Europe 2019]: https://www.youtube.com/watch?v=xyuKx5HsGK8
[データモデリングとドメイン駆動設計]: https://zenn.dev/yamakii/articles/dd9171e85e8633

## ドメイン駆動データ基盤

* [SATURN 2019 Talk Domain-Driven Design of Big Data Systems]
* [Domain-Driven Data]
* [Memo of How to Move Beyond a Monolithic Data Lake to a Distributed Data Mesh]

[SATURN 2019 Talk Domain-Driven Design of Big Data Systems]: https://www.youtube.com/watch?v=pPjtzU2g7SU
[Domain-Driven Data]: https://www.slideshare.net/Dataversity/domaindriven-data
[Memo of How to Move Beyond a Monolithic Data Lake to a Distributed Data Mesh]: https://dobachi.github.io/memo-blog/2021/01/19/Memo-of-How-to-Move-Beyond-a-Monolithic-Data-Lake-to-a-Distributed-Data-Mesh/

# メモ

## ドメイン駆動設計

エリック・エヴァンズが提唱した、ユーザーが従事する業務に合わせてソフトウェアを開発する手法、ドメイン駆動設計。

## ドメイン駆動設計とは何なのか？ ユーザーの業務知識をコードで表現する開発手法について

[ドメイン駆動設計とは何なのか？ ユーザーの業務知識をコードで表現する開発手法について]

成瀬允宣さんの『ドメイン駆動設計入門 』から抜粋した情報。

> 利用者の問題を見極め、解決するための最善手を常に考えていく必要があります。ドメイン駆動設計はそういった洞察を繰り返しながら設計を行い、ソフトウェアの利用者を取り巻く世界と実装を結びつけることを目的としています。

> 重要なのはドメインが何かではなく、ドメインに含まれるものが何かです。

> 「彼らが直面している問題」を正確に理解することが必要

> モデルとは現実の事象あるいは概念を抽象化した概念

> 対象が同じものであっても何に重きを置くかは異なる

> どのドメインモデルをドメインオブジェクトとして実装するかは重要な問題

> ドメインの概念とドメインオブジェクトはドメインモデルを媒介に繋がり、お互いに影響し合うイテレーティブ（反復的）な開発が実現されます

リポジトリについて、

> データの永続化を抽象化することでアプリケーションは驚くほどの柔軟性を発揮します。


## SATURN 2019 Talk Domain-Driven Design of Big Data Systems

[SATURN 2019 Talk Domain-Driven Design of Big Data Systems]

Featureモデリングに基づいて、どうやってビッグデータアーキテクチャを設計するか、という話。

Domain Feature Modelを定義する。

Featureダイアグラムにまとめる。

リファレンスアーキテクチャとして、ビッグデータ基盤が有する特徴を整理。

ナレッジとビジネス要件をマッピングする。

データ、データストレージ、情報管理、データ処理、データ分析、データ仮想化を構造化（木構造化）。

つづいて、デザインルールを決める。例えば、多様なデータを扱うとなったら、メタデータ管理の仕組みを導入する、など。

## Domain-Driven Data

[Domain-Driven Data]

複雑さはテクノロジーの中ではなく、ドメインの中にある。

モデルは、ドメイン内の課題を解くためのツールである。

エンティティ、値オブジェクト、アグリゲート、レポジトリの説明。

https://www.slideshare.net/Dataversity/domaindriven-data#31

にキーワード同士の関係図がある。

オブジェクト指向プログラミングとリレーショナルデータベースは異なるモデルを利用する。

DDDの著者であるEric EvansはNoSQLに対し、以下の様に語っている。

https://www.slideshare.net/Dataversity/domaindriven-data#35

## コンテキスト境界を定義する - Eric Evans氏のDDD Europeでの講演より

[コンテキスト境界を定義する - Eric Evans氏のDDD Europeでの講演より]

コンテキスト境界（Bounded Context）について、DDD著者であるEric Evansが講演で話した内容を紹介。

> 氏が問題視する点のひとつは、マイクロサービスはすなわちコンテキスト境界である、と多くの人たちが信じていることだ。

> マイクロサービスに関連する4種類のコンテキストを取り上げている。

とのこと。「Service Internal」、「API of Service」、「Cluter of codesigned services」、「Interchange Context」

## Language in Context - Eric Evans - DDD Europe 2019

[Language in Context - Eric Evans - DDD Europe 2019]

## How to Move Beyond a Monolithic Data Lake to a Distributed Data Mesh

[Memo of How to Move Beyond a Monolithic Data Lake to a Distributed Data Mesh] に日本語メモがある。

> この文章では、ドメインが所有し、提供するデータプロダクトの相互利用に基づく「データメッシュ」の考え方を提唱するものである。 固有技術そのものではなく、アーキテクチャ検討の前の「データを基礎としたサービス開発、ソフトウェア開発のためのデータの取り回し方」に関する示唆を与えようとしたもの、という理解。

## データモデリングとドメイン駆動設計

[データモデリングとドメイン駆動設計]

渡辺幸三氏のデータモデル大全を読んで感じた所感が記載されている。

> 「ドメイン駆動設計で語られるモデリングの領域がプログラミングに関するものに限定されすぎている」

> エリック・エヴァンスのドメイン駆動設計の中では「コアドメイン」に集中することの重要さを説いています。

> 「データの入出力」がうまく出来ていないとコアドメインだけがうまくいってもシステム全体を見たときに価値を上げているとはいえません。

> 違った見方をすれば、データモデリングに精通したエンジニアになればこの「特注」の部分を抑え、初期の段階からスケールするシステムを開発できる可能性があります。



<!-- vim: set et tw=0 ts=2 sw=2: -->
