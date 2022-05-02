---

title: 機械学習向けのFeature StoreないしStorage Layer Software
date: 2020-04-10 11:43:58
categories:
  - Knowledge Management
  - Storage Layer
tags:
  - Machine Learning
  - Storage Layer Software

---

# 参考

## プロダクト

* Feast
  * [Feast]
  * [Feast Bridging ML Models and Data]
  * メモ
    * Feature Store for Machine Learning https://feast.dev
    * GoJek/Google released Feast in early 2019 and it is built around Google Cloud services:
      Big Query (offline) and Big Table (online) and Redis (low-latency), using Beam for feature engineering.
* [Delta Lake]
  * メモ
    * Delta Lake is an open-source storage layer that brings ACID
      transactions to Apache Spark™ and big data workloads.
* Hopsworks
  * メモ
    * The Platform for Data-Intensive AI
    * Feature Storeに限らない
  * [Hopsworks]
  * [HopsworksのGitHub]
  * [Hopsworks Feature Store The missing data layer in ML pipelines?]
  * [Hopsworksの公式ドキュメントのFeature Store]
* [Metaflow]
  * メモ
    * Netflixの機械学習パイプライン管理用のライブラリ
    * 特徴量を保存するためのライブラリを内容（割と素朴に保存する仕組み）
* [Petastorm]
  * メモ
    * いろいろなフレームワークから利用できるデータ入出力のためのライブラリ
      Parquetを利用する。
* [Zadara]
  * どちらかということ純粋にストレージ
* Netapp
  * メモ
    * いわゆる「ストレージ」におけるアプローチの例
  * [Accelerated AI and deep learning pipelines across edge, core, and cloud]
  * [Edge to Core to Cloud Architecture for AI]
* Dell EMC
  * メモ
    * 単独の技術というより、コンピューティングと合わせてのソリューション、サーバ
  * [ENTERPRISE MACHINE & DEEP LEARNING WITH INTELLIGENT STORAGE]
* IBM
  * メモ
    * Watsonの名のもとに様々なソリューションを集結
  * [IBM Storage for AI and big data]
  * [IBM Spectrum Storage for AI with Power Systems]
* Kafka
  * メモ
    * 推論用のイベントをやり取りするためのハブとして用いる
    * 最近開発されているTiered Storage機能を利用し、長期保存用のストレージと組み合わせた使い方が可能になる
      つまり学習データ（ヒストリカルデータ）を含めて、Kafkaでデータをサーブすることが描かれている。
  * [Streaming Machine Learning with Tiered Storage and Without a Data Lake]
    * Tiered Storageの紹介と機械学習への応用例
* [Cognitive SSD]
  * メモ
    * USENIX ATC'19
    * 非構造データを記憶装置の階層間で移動するのが無駄。そこでSSDのNAND Flash横にDeep Learning用、グラフ検索用のエンジンを積む
* Ignite
  * [Ignite Machine Larning]
* Bandana
  * [Bandana Using Non-Volatile Memory for Storing Deep Learning Models]
  * Facebook Research
  * 深層学習モデルをストアするためのストレージの提案。
    NVMを活用。一緒に読み込まれるベクトルを物理的近く配置し、プリフェッチの効果を向上。
    キャッシュポリシーをシミュレーションに基づいて最適化。

[Feast]: https://github.com/gojek/feast
[Feast Bridging ML Models and Data]: https://blog.gojekengineering.com/feast-bridging-ml-models-and-data-efd06b7d1644
[Delta Lake]: https://delta.io/
[Hopsworks]: https://www.hopsworks.ai/
[HopsworksのGitHub]: https://github.com/logicalclocks/hopsworks
[Hopsworks Feature Store The missing data layer in ML pipelines?]: https://www.logicalclocks.com/blog/feature-store-the-missing-data-layer-in-ml-pipelines
[Hopsworksの公式ドキュメントのFeature Store]: https://hopsworks.readthedocs.io/en/1.1/featurestore/featurestore.html
[Petastorm]: https://github.com/uber/petastorm
[Zadara]: https://www.zadara.com/
[Accelerated AI and deep learning pipelines across edge, core, and cloud]: https://www.netapp.com/us/solutions/applications/ai-deep-learning.aspx
[Edge to Core to Cloud Architecture for AI]: https://www.netapp.com/us/media/wp-7271.pdf
[ENTERPRISE MACHINE & DEEP LEARNING WITH INTELLIGENT STORAGE]: https://www.dellemc.com/resources/en-us/asset/analyst-reports/products/storage/h17841_ar_enterprise_machine_and_deep_learning_with_intelligent_storage.pdf
[IBM Storage for AI and big data]: https://www.ibm.com/it-infrastructure/storage/ai-infrastructure
[IBM Spectrum Storage for AI with Power Systems]: https://www.ibm.com/downloads/cas/JPKRD1R0
[Streaming Machine Learning with Tiered Storage and Without a Data Lake]: https://www.confluent.io/blog/streaming-machine-learning-with-tiered-storage/
[Cognitive SSD]: https://www.usenix.org/conference/atc19/presentation/liang
[Ignite Machine Larning]: https://ignite.apache.org/features/machinelearning.html
[Bandana Using Non-Volatile Memory for Storing Deep Learning Models]: https://research.fb.com/publications/bandana-using-non-volatile-memory-for-storing-deep-learning-models/

## 企業アーキテクチャ

* [Pinterest - Big Data Machine Learning Platform at Pinterest]
* Michelangelo
  * メモ
    * UberのMLプラットフォーム。必ずしもFeature Storeに限らない。
    * Feature Storeに関して特筆すると、「online」と「offline」のデータを統合して扱う、という発想。
  * [Michelangelo_0]
  * [Michelangelo_1]
* Twiter
 * 特徴量をライブラリとして保持、アプリケーションから使いやすくした？
* Comcas
  * ReidsをFeature Storeに利用
* Pinterest
  * [Pinterest - Big Data Machine Learning Platform at Pinterest]
* Zipline
  * メモ
    * 特徴量エンジニアリングパイプラインを補助するライブラリ
    * バックフィルが特徴？
    * OSSではないように見える
  * [Zipline_0]
  * [Zipline_1]

[Michelangelo_0]: https://eng.uber.com/michelangelo-machine-learning-platform/
[Michelangelo_1]: https://eng.uber.com/michelangelo-machine-learning-model-representation/
[Metaflow]: https://metaflow.org/
[Zipline_0]: https://www.slideshare.net/KarthikMurugesan2/airbnb-zipline-airbnbs-machine-learning-data-management-platform 
[Zipline_1]: https://www.slideshare.net/databricks/ziplineairbnbs-declarative-feature-engineering-framework
[Pinterest - Big Data Machine Learning Platform at Pinterest]: https://www.slideshare.net/Alluxio/pinterest-big-data-machine-learning-platform-at-pinterest


## まとめ

* [Feature Stores for ML]
  * 割とよくまとまっている。観点が参考になる。
* [Rethinking Feature Stores]
  * プロダクトは、 [Feature Stores for ML] と重なっているが、考察が載っている。
* [Feature Stores Components of a Data Science Factory]
  * Feature Storeの要件を整理しようとしている
* [Accelerating Machine Learning as a Service with Automated Feature Engineering]
  * Feature Storeの定義、ビジネスメリットまで言及されている。
* [Data Storage Architectures for Machine Learning and Artificial Intelligence]
  * ベンダリストが載っていて便利そう。発行が2019/11なので比較的最近。
  * AI/ML向けのストレージアーキテクチャを「2層型」、「1層型」で分けている。
    * 2層型は性能層と容量層に別れる。また性能層は1層型として用いられることもある。
    * 各層に用いられる、ベンダ製品を例示している。
  * ベンダリスト
    * Dell EMC（Isilon、ECS）
    * Qumulo
    * WekaIO
    * Scality RING
    * DataDirect Networks
    * IBM（Spectrum Scale、COS）
    * Minio
    * Netapp
    * OpenIO
    * Pavilion Data Systems
    * Pure Storage AIRI
    * Quobyte
    * VAST Data

[Feature Stores for ML]: http://featurestore.org/
[Rethinking Feature Stores]: https://medium.com/@changshe/rethinking-feature-stores-74963c2596f0
[Feature Stores Components of a Data Science Factory]: https://towardsdatascience.com/feature-stores-components-of-a-data-science-factory-f0f1f73d39b8
[Accelerating Machine Learning as a Service with Automated Feature Engineering]: https://www.cognizant.com/whitepapers/accelerating-machine-learning-as-a-service-with-automated-feature-engineering-codex4971.pdf
[Data Storage Architectures for Machine Learning and Artificial Intelligence]: https://qumulo.com/wp-content/uploads/2019/11/data-storage-architectures-for-machine-learning-and-artificial-intelligence.pdf

# メモ

## 傾向

* Google Big Query、Big Table、Redisあたりを特徴量置き場として使っている例が見られた。

## Feature Storeとして挙げられている特徴・機能

### 主に、featuer storeとしての特徴

#### 機能・分析補助

* オンライン・オフライン統合（一貫性の実現、共通API）
  * [Feature Stores for ML]
  * [Rethinking Feature Stores]
  * [Feature Stores Components of a Data Science Factory]
  * [Feast Bridging ML Models and Data]
  * [Hopsworksの公式ドキュメントのFeature Store]
    * Hopsworksではオンライン用にMySQL、オフライン用にHiveを利用
    * また一方でHudiにも対応
* バージョンニング、point-in-time correctness（特定のタイミングのレコードに対するラベルの更新）、タイムトラベル
  * [Feature Stores for ML]
  * [Rethinking Feature Stores]
  * [Hopsworksの公式ドキュメントのFeature Store]
* ストレージレイヤ（実体の保存方法）
  * [Hopsworks Feature Store The missing data layer in ML pipelines?]
* 自動特徴量分析、ドキュメンテーション、特徴量のテスト
  * [Hopsworks Feature Store The missing data layer in ML pipelines?]
  * [Hopsworksの公式ドキュメントのFeature Store]
    * HopsworksではDeequを使った特徴量のユニットテストが可能
* マルチテナンシ（ネームスペース、リソース)
  * [Hopsworks Feature Store The missing data layer in ML pipelines?]
  * [Feast Bridging ML Models and Data]
* 読み書きAPI
  * [Hopsworks Feature Store The missing data layer in ML pipelines?]
* アクセス管理
  * [Hopsworksの公式ドキュメントのFeature Store]
* クエリプランナ（複数の特徴量グループの自動結合）
  * [Hopsworksの公式ドキュメントのFeature Store]
* 必要な特徴量だけ選んでデータセットを定義（DBMSでいうビュー）
  * [Hopsworksの公式ドキュメントのFeature Store]

#### 計算

* 遅延評価（必要なタイイングでの計算実行）
  * [Rethinking Feature Stores]
* 自動再計算（auto backfill）
  * [Hopsworks Feature Store The missing data layer in ML pipelines?]
  * [Hopsworksの公式ドキュメントのFeature Store]

#### 性能

* オンラインFeature Storeとしての良いレスポンス、スケーラビリティ
  * [Feature Stores for ML]
  * [Feature Stores Components of a Data Science Factory]
  * [Feast Bridging ML Models and Data]
  * [Hopsworksの公式ドキュメントのFeature Store]
* オフラインデータストアの性能（スケーラビリティ）
  * [Feature Stores Components of a Data Science Factory]
  * [Feast Bridging ML Models and Data]
  * [Hopsworksの公式ドキュメントのFeature Store]
* 特徴量サービングの分散化・非中央集権化（サービングのコピー）
  * [Feast Bridging ML Models and Data]

#### 連係

* 特徴量エンジニアリング手段との連係
  * [Feature Stores for ML]
  * [Hopsworks Feature Store The missing data layer in ML pipelines?]
* 共通フォーマットでのデータのマテリアライズ、複数のフレームワークから読み書き可能なフォーマット
  * [Feature Stores for ML]
  * [Hopsworksの公式ドキュメントのFeature Store]
* メタデータ管理との統合、データカタログ、登録・探索、探索用のGUI
  * [Feature Stores for ML]
  * [Feature Stores Components of a Data Science Factory]
  * [Hopsworks Feature Store The missing data layer in ML pipelines?]
  * [Hopsworksの公式ドキュメントのFeature Store]

### rawデータストアを含めた特徴

* 画像、動画、音声など非テキストデータとテキストデータの統合的な取り扱い

### 特徴量エンジニアリングの例

[Hopsworks Feature Store The missing data layer in ML pipelines?] に一例が載っていたのでついでに転記。

* Converting categorical data into numeric data;
* Normalizing data (to alleviate ill-conditioned optimization when features originate from different distributions);
* One-hot-encoding/binarization;
* Feature binning (e.g., convert continuous features into discrete);
* Feature hashing (e.g., to reduce the memory footprint of one-hot-encoded features);
* Computing polynomial features;
* Representation learning (e.g.,  extract features using clustering, embeddings, or generative models);
* Computing aggregate features (e.g., count, min, max, stdev).

### feature storeにおける画像の取扱は？

feature storeのレベルになると行列化されているので、画像を特別なものとして扱わない？
rawデータストア上では画像は画像として扱う。

## Feastにおけるデータフロー概要

※Feastから幾つか図を引用。

[Feast Bridging ML Models and Data] に載っていたイメージ。

![Feastのデータフローから引用](/memo-blog/images/IhhINZxPsyQx25yZ-F676F.png)

データオーナ側はストリームデータ（Kafka）、DWH（BigQuery）、File（BigQuery）が書かれている。
また真ん中にはApache Beamが書かれており、ストリームETLを経ながらデータがサービングシステムに渡されている。
データは基本的にはストリームとして扱うようだ。

また特徴量を取得するときは以下のようにする。

![特徴量の取得](/memo-blog/images/IhhINZxPsyQx25yZ-A94FA.png)

## hopsworksにおけるfeature store

※Hopsworksから幾つか図を引用。

[Hopsworksの公式ドキュメントのFeature Store] に掲載されていたイメージは以下の通り。
Rawデータストアとは異なる位置づけ。

![hopsworksでのfeature storeの位置づけ](/memo-blog/images/BSBzSj1E5pwx3uqN-C9B87.png)

Feastでも言われているが、データエンジニアとデータサイエンティストの間にあるもの、とされている。

データストアする部分の全体アーキテクチャ。

![feature storeのアーキテクチャ](/memo-blog/images/BSBzSj1E5pwx3uqN-EA1F7.png)

![feature storeのレイヤ構成](/memo-blog/images/BSBzSj1E5pwx3uqN-86B00.png)

複数のコンポーネントを組み合わせて、ひとつのfeature storeを構成しているようである。

## ストレージ製品の動向

### Netapp

[Accelerated AI and deep learning pipelines across edge, core, and cloud] では、

* Create a smooth, secure flow of data for your AI workloads.
* Unify AI compute and data silos across sites and regions.​
* Your data, always available: right place, right time.

が挙げられている。
また、クラウド・オンプレ、エッジ・センタを統合する、というのが重要なアピールポイントに見えた。
詳しくは、 [Edge to Core to Cloud Architecture for AI] を読めばわかりそう。

### Dell EMC

単独の技術というより、コンピューティングの工夫を含めてのソリューションのようにみえる。
[ENTERPRISE MACHINE & DEEP LEARNING WITH INTELLIGENT STORAGE] に思想が書いてありそう。まだ読んでいない。

<!-- vim: set et tw=0 ts=2 sw=2: -->
