---
title: "Open Semantic Interchange (OSI) 技術深掘り — スコープと利用実例"
date: 2026-07-10
categories:
  - cross
topic: "Open Semantic Interchange (OSI) 技術深掘り"
tags:
  - Open Semantic Interchange
  - セマンティック層
  - データ相互運用性
  - Apache Ossie
related:
  - "snowflake"
  - "databricks"
---

# Open Semantic Interchange (OSI) 技術深掘り — スコープと利用実例

## 概要

Open Semantic Interchange（OSI）は、セマンティック層の構成要素（データセット・メトリクス・ディメンション・関係・コンテキスト）をベンダー中立かつ拡張可能な形式で表現するオープン標準だ。Snowflake が主導し、Salesforce・dbt Labs・BlackRock らと2025年9月23日に発足、2026年1月27日に初版仕様（v0.1系）を GitHub 上で公開した[^1][^2]。「Write Once, Query Anywhere」の原則で、メトリクス定義を一度書けば BI・AI・分析ツール間で一貫して解釈できるようにする。2026年6月には Apache Software Foundation の Incubator に受け入れられ、「Apache Ossie (incubating)」として開発が続いている[^5]。

## 詳細

### 仕様概要とライセンス

OSI は YAML／JSON で宣言的にセマンティックモデルを定義する Apache 2.0 ライセンスのオープン標準である[^1][^2]。ベンダー中立な形式で構成要素を定義し、BI・AI・分析ツール間で一貫した解釈を可能にする[^1]。公開された初版はバージョン v0.1 系で、dbt の実装も document version `0.1.0` / `0.1.1` を対象としている[^3]。「v1.0」という表記が流通することがあるが、正式なバージョンタグではない点に注意したい。

### OSIのスコープ

OSI は「論理的なセマンティック層」に範囲を絞り、物理層や実行層には踏み込まない。何を対象とし、何を対象外とするかは明確に線引きされている[^4]。

| 区分 | 内容 |
|------|------|
| スコープ内 | Semantic Model（データセット・関係・メトリクスを束ねる最上位コンテナ）、Datasets（ファクト／ディメンションの論理エンティティ、主キー・一意キー）、Fields（グルーピング・フィルタ・式に使う行レベル属性）、Relationships（データセット間の外部キー、単純／複合キー）、Metrics（複数データセットにまたがる集計指標）、Custom Extensions（ベンダー固有メタデータ）、AI Context（指示・同義語・サンプルクエリ等の注釈） |
| スコープ外 | 物理データ形式（Parquet・Arrow）、クエリ／アクセスインターフェース（ODBC・JDBC）、カタログメタデータ（Hive Metastore 等）、クエリの実行そのもの |

OSI はこれらの既存標準を置き換えるものではなく、補完する位置づけを明言している[^4]。オーサリングツールを置き換えるのではなく、その出力を相互運用可能にすることが狙いだ。Custom Extensions は互換性保証の対象外だが、仕様を理解しないツールを経由しても往復変換で保持されるため、ベンダー間の変換で情報が失われない[^4]。

### 技術的イメージと利用実例

構造はハブ&スポークだ。各ツールが OSI という単一の交換フォーマットを介するため、ツール同士を N×N で個別接続する必要がなくなる。定義側（dbt/MetricFlow、Snowflake、Cube など）が OSI を出力し、利用側（Tableau・Sigma・ThoughtSpot などの BI、AI エージェント、分析ツール）が OSI を読む。

![OSIによるWrite Once, Query Anywhereのハブ&スポーク構造](/memo-blog/images/open-semantic-interchange-architecture.png)

技術的な特徴のひとつが、フィールドやメトリクスの式を SQL 方言ごとに持てることだ。同じ論理定義に対して、実行先の方言に応じた式を並記する[^4]。

```yaml
expression:
  dialects:
    - dialect: ANSI_SQL
      expression: LOWER(email)
    - dialect: SNOWFLAKE
      expression: LOWER(email)::VARCHAR
    - dialect: DATABRICKS
      expression: lower(email)
```

実装例として、dbt Core は v1.12 以降で OSI をサポートする。プロジェクト直下の `OSI/` ディレクトリ（または `dbt_project.yml` の `osi-paths` で指定した場所）に OSI ドキュメントを置き、`dbt compile` または `dbt run` で解析させると、`target/` 配下に `osi_document.json`・`manifest.json`・`semantic_manifest.json` が生成される[^3]。OSI 由来の定義と dbt ネイティブのセマンティックモデルは同一プロジェクトで共存できる[^3]。

```json
{
  "version": "0.1.1",
  "semantic_model": [
    {
      "name": "orders",
      "datasets": [
        { "name": "orders", "source": "my_database.my_schema.fct_orders" }
      ]
    }
  ]
}
```

`source` はウェアハウス上の完全修飾名（`database.schema.table`）で、dbt は各データセットを既存の dbt モデルに突き合わせる[^3]。エクスポート側では、データカタログの Dawiso がデータプロダクトを OSI 形式へ書き出す機能を提供している。コア開発は Snowflake・dbt Labs・Dremio が担う[^5]。

### 参加組織とワーキンググループ

参加組織は50を超える。Snowflake・Databricks・Salesforce・Oracle・Alation・BlackRock・ServiceNow・Mistral AI などが名を連ねる[^1][^2]。仕様策定は、Apache Ossie の ROADMAP が「Current Efforts / Working Groups」として整理する複数のワーキンググループで進む[^6]。現在の主なグループは次のとおり[^6]。

- Metric Semantics & Core Semantic Model（メトリクス意味論とコアモデル）
- Catalog Integration & Semantic Services（カタログ統合とセマンティックサービス）
- Ontology & Semantic Interoperability（オントロジーと意味的相互運用）
- Dataset Abstraction & Logical Modeling（データセット抽象化と論理モデリング）
- Semantic Query Language & Reference Engine（セマンティッククエリ言語と参照エンジン）
- SQL Dialect, Expressions, and Execution Boundaries（SQL方言・式・実行境界）
- Dimensions, Hierarchies, and Time Semantics（ディメンション・階層・時間意味論）
- AI-Native Semantic Layer（AIネイティブなセマンティック層）
- Governance, Identity, and Validation（ガバナンス・アイデンティティ・検証）
- Industry / Domain-Specific Semantic Models（業界・ドメイン特化モデル）

初回のワーキンググループ会合は2025年10月に開かれた[^7]。業界特化の動きとして、2026年には金融サービス向けのセマンティック WG が立ち上がり、Net Asset Value のような定義の統一を進めている[^8]。

### AI統合対応

OSI は AI エージェントにセマンティックコンテキストを渡すことを設計に組み込んでいる。AI Context として、指示・同義語・サンプルクエリといった注釈をモデルに付与できる[^4]。すべてのツールとエージェントが同一の定義から動くことで、チーム間の定義不一致や重複作業を避けられる[^2]。

### 異なるセマンティックモデルをまたぐ連携

押さえるべき線引きは、OSI が与えるのは「フォーマット（構造）の相互運用」であって「意味の自動突き合わせ」ではない、という点だ。

![OSIはフォーマットを統一するが、意味の整合はマッピングと共通語彙層が担う](/memo-blog/images/open-semantic-interchange-cross-model.png)

A社とB社が別々のセマンティックモデルを持つ場合、OSI は両社のモデルを同じ文法（YAML／JSON）で表現させる。相手のメトリクス定義（式・ディメンション・関係・方言別の式）が機械可読で明示的になり、プロプライエタリなサイロや専用コネクタから解放される。ただし A社の「churn」と B社の「churn」を自動で同一視することはしない。定義が食い違えば OSI はその差分を正確に可視化するが、対応づけ（マッピングや統一定義の合意）は当事者のガバナンスに委ねられる。コア仕様にモデル間クロスウォークの仕組みはまだなく、ロードマップ上の目標にとどまる[^4]。

この線引きは Apache Ossie の ROADMAP でも明言されている。「現状は構造的相互運用は解けている（どのツールも共通フォーマットでモデルを読み書きできる）が、概念的相互運用（conceptual interoperability）はまだ解けていない」という認識だ[^6]。差分を可視化した先を担う取り組みも進む。「Dataset Abstraction & Logical Modeling」はモデルをまたいだデータセット・関係の再利用（composability）を、「Ontology & Semantic Interoperability」は業務概念を物理レイアウトから切り離し、オントロジーベースのモデルとモデル間の概念的アラインメントを可能にすることを目標に掲げる[^6]。

業界横断では「業界が OSI の上に共通ドメイン語彙を作る」パターンになる。金融サービス向けのセマンティック WG は、Net Asset Value のような定義を業界で揃えようとする例だ[^8]。異なる業界どうしなら、双方が参照する共通リファレンス・オントロジー（金融の FIBO など）へのマッピングが鍵になるが、これは現時点ではロードマップであり、完成したスキーマ機能ではない[^6]。

要するに、OSI は共通の文法・ファイル形式であって共通の意味辞書ではない。「同じ単語で違う意味」を自動解決はしないが、各自の意味を交渉可能なほど明示化し、Composability や Ontology 層で整合を積み上げる土台を与える。

## 考察

OSI が解くのは「セマンティック層の断片化」という古くて新しい問題だ。BI 時代にはメトリクス定義の不統一がダッシュボード間の数字の食い違いを生んでいた。AI エージェントが普及した今、定義の不統一はエージェントの判断誤りに直結するため、共通の定義基盤の価値は質的に高まる。

一方で普及の速度は、5つの WG が実装ガイドと相互運用テストをどれだけ早く整備できるかに依存する。ここで効いてくるのが Apache Incubator への移管だ。特定ベンダーのイニシアチブから中立な財団のガバナンス下に移ったことで、参加ベンダーが安心して実装へ投資しやすくなる。dbt Core のように import が実際に動く実装が出てきた段階であり、今後は Snowflake・Cube・BI 各社の export/import がどこまで揃うかが分岐点になる。

## 参考文献

[^1]: Open Semantic Interchange, "[Open Semantic Interchange](https://open-semantic-interchange.org/)", アクセス日 2026-07-10
[^2]: Snowflake, "[Open Semantic Interchange (OSI) Specification Finalized](https://www.snowflake.com/en/blog/open-semantic-interchanges-specs-finalized/)", アクセス日 2026-07-10
[^3]: dbt Labs, "[OSI semantic layer documents](https://docs.getdbt.com/docs/build/osi-semantic-models)", アクセス日 2026-07-12
[^4]: Apache Ossie, "[Apache Ossie (旧 OSI) 仕様リポジトリ](https://github.com/apache/ossie)", アクセス日 2026-07-13
[^5]: Apache Incubator, "[Apache Ossie (incubating)](https://incubator.apache.org/clutch/ossie.html)", アクセス日 2026-07-12
[^6]: Apache Ossie, "[ROADMAP.md — Current Efforts / Working Groups](https://github.com/apache/ossie/blob/main/ROADMAP.md)", アクセス日 2026-07-13
[^7]: Snowflake, "[OSI Further Expands Partner Ecosystem and Holds First Working Group Meeting](https://www.snowflake.com/en/blog/osi-initiative-expands-partners/)", アクセス日 2026-07-13
[^8]: Open Semantic Interchange, "[Updates（金融サービス向けWG ほか）](https://open-semantic-interchange.org/updates/)", アクセス日 2026-07-13

## 更新履歴

- 2026-07-10: 初版
- 2026-07-13: ワーキンググループの記述を最新の Apache Ossie ROADMAP に合わせて修正し、WG関連の出典（ROADMAP・初回WG会合・金融WG）を追加。仕様リポジトリのURLを Apache Ossie に更新
