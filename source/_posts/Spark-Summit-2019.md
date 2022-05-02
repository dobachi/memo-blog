---

title: Spark Summit 2019
date: 2019-05-17 01:21:34
categories:
  - Knowledge Management
  - Spark
tags:
  - Apache Spark
  - Spark

---

# セッションメモ

## Accelerate Your Apache Spark with Intel Optane DC Persistent Memory

[Accelerate Your Apache Spark with Intel Optane DC Persistent Memory]

[Accelerate Your Apache Spark with Intel Optane DC Persistent Memory]: https://www.slideshare.net/databricks/accelerate-your-apache-spark-with-intel-optane-dc-persistent-memory

p.12あたりにアーキイメージがある。
キャッシュを中心としたイメージ。
DCPMMを用いる。

p.14
Optimized Analytics Package（OAP）はDCMPPを用いてSpark SQLを加速する。

p.16あたりからキャシュデザインに関する課題感や考え方が記載されている。
例えば…

* 手動によるメモリ管理はフラグメンテーションを生じさせる
* libvmemcacheのリンクドリストによりロック待ちを起因としたボトルネックが生じる
  * そこでリングバッファを利用し、できるだけロック機会を減らすことにした

p.26あたりからSpark SQLを題材とした検証結果が載っている。
DRAMに乗り切るサイズであえてやってみた例、乗り切らさないサイズでやってみた例。

p.30あたりからSpark MLlibのK-meansを題材とした検証結果が載っている。 ★
DCPMMのデータに関する階層の定義がある。
DRAM+Diskの場合と比べ、間にOptain DC Persistent Memoryが入ることで性能向上を狙う。
K-meansのワークロードでは最初にHDFSからデータをロードしたあと、
エグゼキュータのローカルディスクを含むストレージを使用してイテレーティブに計算する。
このときDCPMMを用いることで大きなサイズのデータを扱うときでも、ディスクにスピルさせることなく動作可能になり、処理時間の縮小になった。（つまり、性能向上効果はデータサイズによる） ★

## Building Robust Production Data Pipelines with Databricks Delta

[Building Robust Production Data Pipelines with Databricks Delta]

[Building Robust Production Data Pipelines with Databricks Delta]: https://www.slideshare.net/databricks/building-robust-production-data-pipelines-with-databricks-delta

p.5
データレイクがあっても、信頼するデータがない（データを信頼できない）ことで
多くのデータサイエンスや機械学習が失敗している。

p.7
なぜデータが信頼できなくなるのかというと、

* 失敗したジョブが破損したデータを生成する
* スキーマを強制するすべがなく、一貫性が崩れたり、
  データの品質が悪くなる。
* 追記・読み込み、バッチとストリーム処理の混在が許されない
  （補足：これだけデータの信頼性の話とは異なるような気がした）

p.10
鍵となる特徴が載っている。
ACID（トランザクション）、スキーマ強制、バッチとストリーム処理の混在、タイムトラベル（スナップショット）

## Deploying Enterprise Scale Deep Learning in Actuarial Modeling at Nationwide

[Deploying Enterprise Scale Deep Learning in Actuarial Modeling at Nationwide]

[Deploying Enterprise Scale Deep Learning in Actuarial Modeling at Nationwide]: https://www.slideshare.net/databricks/deploying-enterprise-scale-deep-learning-in-actuarial-modeling-at-nationwide

ユースケース。

自動車保険を中心としたサービスを提供するNationwide社の事例。

p.7 ★
CDOを筆頭とし、Enterprise Data Officeを構成。
EDOは完全なデータと分析サービスをもとにソリューションを提供し、ビジネスを強化する。

p.8
Analytical Lab。
Databricksのサービスを用いて分析パイプラインを構成？

p.11
Enterprise Analytics Officeというコンセプトの下、データから叡智を取り出す方法論を提供。

p.17
Sparkを用いている理由は、並列化可能な内容がたくさんあるから。例えば以下の通り。
* データ変換がたくさん
* スコアリングも並列化可能
* ハイパーパラメータチューニングなども並列化可能

## Improving Apache Spark's Reliability with DataSourceV2

[Improving Apache Spark's Reliability with DataSourceV2]

[Improving Apache Spark's Reliability with DataSourceV2]: https://www.slideshare.net/databricks/improving-apache-sparks-reliability-with-datasourcev2

Neflixの事例。

S3が結果整合性。
Hiveがファイルのリスティングに依存。たまに失敗する。
Netflixの規模だと、「たまに」というのが毎日になる。

p.7
2016年当時の工夫。

p.10〜
DataFrameのDataSourceに関連するつらみ。

DataFrameWriterでは振る舞いが規定されていない。

p.17
Icebergの採用（2019）
Hive等で課題となっていたテーブルの物理構造を見直した。
くわしくは、 [Strata NY 2018でのIcebergの説明] 参照。

p.20
DataSourcedV2が登場したが、一部の課題は引き継がれた。

* 書き込みのバリデーションがない
* SaveModeの挙動がデータソースまかせ

p.21'
DSv2での活動紹介

[Strata NY 2018でのIcebergの説明]: https://cdn.oreillystatic.com/en/assets/1/event/278/Introducing%20Iceberg_%20Tables%20designed%20for%20object%20stores%20Presentation.pdf

## Lessons Learned Using Apache Spark for Self-Service Data Prep in SaaS World

[Lessons Learned Using Apache Spark for Self-Service Data Prep in SaaS World]

[Lessons Learned Using Apache Spark for Self-Service Data Prep in SaaS World]: https://www.slideshare.net/databricks/lessons-learned-using-apache-spark-for-selfservice-data-prep-in-saas-world-144261396

ユースケース。

[workday] における事例。

[workday]: https://www.workday.com/ja-jp/homepage.html'

p.13
「Prism」分析のワークフロー。

p.14
分析前の前処理はSparkで実装される。
ウェブフロントエンドを通じて処理を定義する。

インタラクティブな処理とバッチ処理の両方に対応。

p.25
Sparkのデータ型にさらにデータ型を追加。
StructType、StructFieldを利用して実装。

p.28〜
lessons learnedをいくつか。

ネストされたSQL、self joinやself unionなどの二重オペレータ、ブロードキャストJoinの効率の悪さ、
Caseセンシブなグループ化

## Using Spark Mllib Models in a Production Training and Serving Platform: Experiences and Extensions ★

[Using Spark Mllib Models in a Production Training and Serving Platform: Experiences and Extensions]

[Using Spark Mllib Models in a Production Training and Serving Platform: Experiences and Extensions]: https://www.slideshare.net/databricks/using-spark-mllib-models-in-a-production-training-and-serving-platform-experiences-and-extensions

ユースケース。

Uberの機械学習基盤 Michelangelo についてのセッション。
UberではSpark MLlibをベースとしつつも、独自の改造を施して用いている。

p.2〜
Spark MLlibのパイプラインに関する説明。
パイプラインを用いることで、一貫性をもたせることができる。

* データ変換
* 特徴抽出と前処理
* 機械学習モデルによる推論
* 推論後の処理

p.8〜
パイプラインにより複雑さを隠蔽できる。 ★
例：異なるワークフローを含むことによる複雑さ、異なるユーザニーズを含むことによる複雑さ。

p.10〜
達成したいこと。

まずは性能と一貫性の観点。

* Spark SQLをベースとした高い性能
* リアルタイムサービング（P99レイテンシ < 10ms、高いスループット）
* バッチとリアルタイム両対応

柔軟性とVelocityの観点。

* モデル定義：ライブラリやフレームワークの柔軟性
* Michelangeloの構造
* Sparkアップグレード

プロトコルバッファによるモデル表現の改善の観点。
MLeap、PMML、PFA、Spark PipelineModel。
Spark PiplelineModelを採用したかったのだが以下の観点が難点だった。

* モデルロードが遅い
* サービングAPIがオンラインサービング向けには遅い

p.15〜
改善活動。例えば、SparkのAPIを使ってメタデータをロードしていたところを
シンプルなJava APIでロードするようにする、など細かな改善を実施。
Parquet関連では、ParquetのAPIを直接利用するように変えた。

## A Journey to Building an Autonomous Streaming Data PlatformScaling to Trillion Events Monthly at Nvidia

[A Journey to Building an Autonomous Streaming Data PlatformScaling to Trillion Events Monthly at Nvidia]

[A Journey to Building an Autonomous Streaming Data PlatformScaling to Trillion Events Monthly at Nvidia]: https://www.slideshare.net/databricks/a-journey-to-building-an-autonomous-streaming-data-platformscaling-to-trillion-events-monthly-at-nvidia

NVIDIAの考えるアーキテクチャの変遷。
V1からV2へ、という形式で解説。

p.10〜
V1アーキテクチャ。
KafkaやS3を中心としたデータフロー。
p.12にワークフローイメージ。

p.13
V1で学んだこと。データ量が増えた、セルフサービス化が必要、など。 ★
状況が変わったこともある。

p.14〜
V2アーキテクチャ。
セルフサービス化のために、NV Data Bots、NV Data Appsを導入。

p.23
NV Data Appsによる機械化で課題になったのは、
スキーマ管理。
Elastic Beatsではネストされたスキーマも用いれるが、そうするとスキーマの推論が難しい。

p.29
V2でのワークフロー。
ワークフローの大部分が機械化された。 ★

p.32
スケーラビリティの課題を解くため、Databricks Deltaを導入。
PrestoからSpark + Deltaに移行。

## Apache Spark on K8S Best Practice and Performance in the Cloud

[Apache Spark on K8S Best Practice and Performance in the Cloud]

[Apache Spark on K8S Best Practice and Performance in the Cloud]: https://www.slideshare.net/databricks/apache-spark-on-k8s-best-practice-and-performance-in-the-cloud


TencentにおけるSpark on k8sに関するナレッジの紹介。

p.6
「Sparkling」について。アーキテクチャなど。

p.18〜
YARNとk8sでの性能比較結果など。
TeraSortでの動作確認では、YARNおほうがスループットが高い結果となり、
データサイズを大きくしたところk8sは処理が途中で失敗した。
ディスクへの負荷により、Evictされたため、tmpfsを使用するようにして試す例も記載されている。

p.23〜
spark-sql-perfによるベンチマーク結果。
そのままでは圧倒的に性能が悪い。これはYARNではデフォルトでyarn.local.dirにしていされた
複数のディスクを使用するのに対し、on k8sでは一つのディレクトリがマウントされるから。
これを複数ディスクを使うようにした結果も記載されている。YARNには届かないが随分改善された。


## Deep Learning on Apache Spark at CERN’s Large Hadron Collider with Intel Technologies ★

[Deep Learning on Apache Spark at CERN’s Large Hadron Collider with Intel Technologies]

[Deep Learning on Apache Spark at CERN’s Large Hadron Collider with Intel Technologies]: https://www.slideshare.net/databricks/deep-learning-on-apache-spark-at-cerns-large-hadron-collider-with-intel-technologies

p.6
CERNで扱うデータ規模。
PB/secのデータを生成することになる。

p.9〜
Sparkを実行するのにYARNとk8sの両方を使っている。
JupyterからSparkにつなぎ、その裏で様々なデータソース（データストア）にアクセスする。

p.13
物理データにアクセスする際には、Hadoop APIからxrootdプロトコルでアクセス。

p.18
Apache Spark、Analytics Zoo、BigDLを活用。
Analytics Zooを利用することでTensorFlow、BigDL、Sparkを結びつける。

また、このあとワークフロー（データフロー）に沿って個別に解説。

Kerasなどを用いてモデル開発し、その後BigDLでスケールアウトしながら分散学習。
BigDLは、よくスケールする。

p.31
推論はストリーム処理ベースで行う。
Kafka経由でデータをフィードし、サーブされたモデルをSparkで読み込んで推論。
また、FPGAも活用する。

## Elastify Cloud-Native Spark Application with Persistent Memory

[Elastify Cloud-Native Spark Application with Persistent Memory]

[Elastify Cloud-Native Spark Application with Persistent Memory]: https://www.slideshare.net/databricks/elastify-cloudnative-spark-application-with-persistent-memory

Tencentにおけるアーキテクチャの説明。

p.4
データ規模など。
100PB+

p.5
TencentにおけるBig Data / AI基盤

p.6
MemVerge：メモリ・コンバージド基盤（MCI）

p.7〜
MapReduceの時代は、データを移動するのではなくプログラムを移動する。
その後ネットワークは高速化（高速なネットワークをDC内に導入する企業の増加）
SSD導入の割合は増加。

p.10
ただし未だにDRAM、SSD、HDD/TAPEの階層は残る。
そこでIntel Optain DC Persistent Memoryが登場。（DCPMM）

p.14
MemVergeによるPMEMセントリックなデータプラットフォーム。
クラスタワイドにPMEMを共有。


p.17〜
Sparkのシャッフルとブロックマネージャについて。
現状の課題をうけ、シャッフルを再検討。

p.20
エグゼキュータでのシャッフル処理に関し、データの取扱を改善。
ストレージと計算を分離し、さらにプラガブルにした。
さらにストレージ層に、Persistent Memoryを置けるようにした。


## Geospatial Analytics at Scale with Deep Learning and Apache Spark

[Geospatial Analytics at Scale with Deep Learning and Apache Spark]

[Geospatial Analytics at Scale with Deep Learning and Apache Spark]: https://www.slideshare.net/databricks/geospatial-analytics-at-scale-with-deep-learning-and-apache-spark

p.7
新たなチャレンジ

* 立地なデータの増加（ドローンの導入など）
* トラディショナルなツールがスケーラビリティない
* パイプラインの構成

p.10
Apache Spark : glue of Big Data

p.13〜
Sparkにおける画像の取扱。
Spark2.3でImageSchemaの登場。

Spark Join
画像をXMLと結合する。
イメージのチップ作成。

p.18
Deep Learningフレームワーク。
Spark Deep Learning Pipelines

p.22
Magellan


## Improving Call Center Operations and Marketing ROI with Real-Time AI/ML Streams

[Improving Call Center Operations and Marketing ROI with Real-Time AI/ML Streams]

[Improving Call Center Operations and Marketing ROI with Real-Time AI/ML Streams]: https://databricks.com/session/improving-call-center-operations-and-marketing-roi-with-real-time-ai-ml-streams

スライドが公開されていなかった（2019/05/18時点）

## Large-Scale Malicious Domain Detection with Spark AI

[Large-Scale Malicious Domain Detection with Spark AI]

[Large-Scale Malicious Domain Detection with Spark AI]: https://www.slideshare.net/databricks/largescale-malicious-domain-detection-with-spark-ai

DDoS、暗号マイニングマルウェア。
Tencentの事例。

p.17
シーケンスを使って検知する。

p.19〜
Domain2Vec、Domainクラスタリング

p.24
Word2Vecを使って、ドメインからベクトルを生成する。
（ドメインのつながりを文字列結合してから実施？）

p.28あたり
LSHをつかった例も載っている。

## Migrating to Apache Spark at Netflix

[Migrating to Apache Spark at Netflix]

[Migrating to Apache Spark at Netflix]: https://www.slideshare.net/databricks/migrating-to-apache-spark-at-netflix

現在Netflixでは90%以上のジョブがSparkで構成されている。

p.11〜
アップストリームへの追従
複数バージョンを並行利用するようにしている

p.17〜
各バージョンで安定性の課題があり、徐々に解消されていった

p.22
メモリ管理はNetflixにおいても課題だった。
教育よって是正していた面もある。

p.23〜
Sparkを使うに当たってのベストプラクティスを列挙
設定方針、心構え、ルールなど。

## Apache Arrow-Based Unified Data Sharing and Transferring Format Among CPU and Accelerators

[Apache Arrow-Based Unified Data Sharing and Transferring Format Among CPU and Accelerators]

[Apache Arrow-Based Unified Data Sharing and Transferring Format Among CPU and Accelerators]: https://www.slideshare.net/databricks/apache-arrowbased-unified-data-sharing-and-transferring-format-among-cpu-and-accelerators

p.6
FPGAでオフロード。

p.8〜
オフロードによるオーバーヘッドは無視できない。


## Apache Spark and Sights at Speed: Streaming, Feature Management, and Execution

[Apache Spark and Sights at Speed: Streaming, Feature Management, and Execution]

[Apache Spark and Sights at Speed: Streaming, Feature Management, and Execution]: https://databricks.com/session/apache-spark-and-sights-at-speed-streaming-feature-management-and-execution

スライドが公開されていなかった（2019/05/18時点）


## Data-Driven Transformation: Leveraging Big Data at Showtime with Apache Spark

[Data-Driven Transformation: Leveraging Big Data at Showtime with Apache Spark]

[Data-Driven Transformation: Leveraging Big Data at Showtime with Apache Spark]: https://www.slideshare.net/databricks/datadriven-transformation-leveraging-big-data-at-showtime-with-apache-spark

ユースケース。

[SHOWTIME] の事例。

[SHOWTIME]: https://www.sho.com/

SHOWTIMEはスタンドアローンのストリーミングサービス。
そのため、顧客のインタラクションデータが集まる。

p.6
ビジネス上生じる疑問の例。

疑問は、答えられる量を上回って増加。

簡単な質問だったら通常のレポートで答えられるが、
複雑な質問に答えるには時間と専門的なスキルが必要。

p.10
データストラテジーチーム。 ★
データと分析を民主化する、購買者の振る舞いを理解し予測する、データ駆動のプログラミングやスケジューリングに対応する。

p.12 ★
数千のメトリクスや振る舞いを観測する。
ユーザとシリーズの関係性をトラックする。

p.14
機械学習を用いてユーザの振る舞いをモデル化する。

p.20〜
Airflowでパイプラインを最適化。
AirflowとDatabricksを組み合わせる。 ★

p.29
Databricks Deltaも利用している。 ★

## In-Memory Storage Evolution in Apache Spark

[In-Memory Storage Evolution in Apache Spark]

[In-Memory Storage Evolution in Apache Spark]: https://databricks.com/session/in-memory-storage-evolution-in-apache-spark

スライドが公開されていなかった（2019/05/18時点）


## SparkML: Easy ML Productization for Real-Time Bidding

[SparkML: Easy ML Productization for Real-Time Bidding]

[SparkML: Easy ML Productization for Real-Time Bidding]: https://www.slideshare.net/databricks/sparkml-easy-ml-productization-for-realtime-bidding

リアルタイムでの広告へのBid。
動機：機械学習を用いることで、マーケットをスマートにしたい。

p.6
スケールに関する数値。例：300億件/secのBid意思決定。

p.7
ゴール。

p.8〜
9年前からHadoopを使い、4年ほど前にSparkにTry。

p.12
SparkのMLlibにおけるパイプラインに対し拡張を加えた。
「RowModel」を扱う機能を追加。

p.13
StringIndexerを用いたカテゴリ値の変換が遅いので、独自に開発。

p.14
リソースボトルネックが、キャンペーンによって変わる。そしてうまくリソースを使い切れない。
そこでジョブを並列で立ち上げることにした。

p.15〜
モデルデプロイ（最新モデルへの切り替え）が難しい。
モデルを生成したあと、部分的にデプロイしたあと全体に反映させる。（A/Bテスト後の切り替え）

レイテンシの制約が厳しかった。 ★

補足：モデルを頻繁にデプロイするケースにおいてのレイテンシ保証は難しそうだ ★

p.18
「セルフチューニング」のためのパイプラン ★


## Best Practices for Hyperparameter Tuning with MLflow

[Best Practices for Hyperparameter Tuning with MLflow]

[Best Practices for Hyperparameter Tuning with MLflow]: https://www.slideshare.net/databricks/best-practices-for-hyperparameter-tuning-with-mlflow

p.4〜
ハイパーパラメータチューニングについて。

p.6
チューニングにおける挑戦★

p.9
データサイエンスにおけるチューニングのフロー ★

p.10
AutoMLは、ハイパーパラメータチューニングを含む。

p.13〜
チューニング方法の例 ★

* マニュアルサーチ
* グリッドサーチ
* ランダムサーチ
* ポピュレーションベースのアルゴリズム
* ベイジアンアルゴリズム
  * ハイパーパラメータをlossとして最適化？

p.37
様々なツールのハイパーパラメータチューニング手段のまとめ ★

p.40〜
MLflowの機能概要

p.42
単一のモデルではなく、パイプライン全体をチューニングすること。 ★

p.49
ハイパーパラメータチューニングの並列化。
Hyperopt、Apache Spark、MLflowインテグレーション ★

## Scaling Apache Spark on Kubernetes at Lyft

[Scaling Apache Spark on Kubernetes at Lyft]

[Scaling Apache Spark on Kubernetes at Lyft]: https://www.slideshare.net/databricks/scaling-apache-spark-on-kubernetes-at-lyft


p.6
Liftにおけるバッチ処理アーキテクチャの進化。 ★

p.7
アーキテクチャ図。
Druidも含まれている。

p.8
初期のバッチ処理アーキテクチャ図。

p.9〜
SQLでは複雑になりすぎる処理が存在する。またPythonも用いたい。
例：PythonからGeoに関するライブラリを呼び出して用いたい。

Sparkを中心としたアーキテクチャ。

p.19
残ったチャレンジ

* Spark on k8sは若い
* 単一クラスタのスケール限界
* コントロールプレーン
* ポッドChurnやIPアロケーションのスロットリング

p.22
最新アーキテクチャ★

Spark本体、ヒストリサーバ、Sparkのオペレータ、ジョブ管を含め、すべてk8s上に構成。
他にもゲートウェイ機能をk8s上に実現。

p.23〜
複数クラスタによるアーキテクチャ。
クラスタごとにラベルをつけて、ゲートウェイ経由で使い分ける。
バックエンドのストレージ（ここではS3？）、スキーマ等は共通化。

クラスタ間でローテーション。

複数のネームスペース。

ジョブ管から見たとき、ポッドを共有するアーキテクチャもありえる。

p.28
DDLをDMLから分離する。
Spark Thrift Server経由でDDLを実行。

p.29
プライオリティとプリエンプションはWIP。

p.32
Sparkジョブのコンフィグをオーバレイ構成にする。 ★

p.36
モニタリングのツールキット。★

p.38
Terraformを使った構成。Jinjaテンプレートでパラメータを扱うようだ。

p.39
今後の課題 ★
サーバレス、セルフサービス可能にする、など。
Spark3系への対応もある。

p.40

* Sparkは様々なワークロードに適用可能
* k8sを使うことで複数バージョンへの対応や依存関係への対応がやりやすくなる
* マルチクラスタ構成のメッシュアーキテクチャにすることでSpark on k8sはスケールさせられる

## A "Real-Time" Architecture for Machine Learning Execution with MLeap ★

[A "Real-Time" Architecture for Machine Learning Execution with MLeap]

[A "Real-Time" Architecture for Machine Learning Execution with MLeap]: https://www.slideshare.net/databricks/a-realtime-architecture-for-machine-learning-execution-with-mleap

p.2
機械学習におけるリアルタイムのユースケースはごく一部。

p.5
1999年から異常検知に取り組んできた企業。

p.7
データフローのイメージ図。
MLeap。

p.10
リアルタイムのアーキテクチャのオーバービュー。
ヒストリカルデータストアからHDFSにデータを取り込み、教師あり機械学習モデルを作成する。
モデルはモデル管理用のデータストアに格納され、推論のシステムに渡される。

モデルを作るところはMLeapのパイプラインで構成される。

p.12
並列処理は、メッセージバス（Kafkaなど）によって実現される。
推論結果の生データをログに書き出すこと。

p.13
モデル管理のフロー。
学習したモデルをデプロイするときには、ブルー・グリーンデプロイメントのように実施する。

p.16〜
メトリクスについて。
平均と分散。
MLeapにより、レイテンシの99パーセンタイルが改善。

## Managing Apache Spark Workload and Automatic Optimizing

[Managing Apache Spark Workload and Automatic Optimizing]

[Managing Apache Spark Workload and Automatic Optimizing]: https://www.slideshare.net/databricks/managing-apache-spark-workload-and-automatic-optimizing

## Optimizing Delta/Parquet Data Lakes for Apache Spark

スライドが公開されていなかった。

## Creating an Omni-Channel Customer Experience with ML, Apache Spark, and Azure Databricks

[Creating an Omni-Channel Customer Experience with ML, Apache Spark, and Azure Databricks]

[Creating an Omni-Channel Customer Experience with ML, Apache Spark, and Azure Databricks]: https://www.slideshare.net/databricks/creating-an-omnichannel-customer-experience-with-ml-apache-spark-and-azure-databricks

## Optimizing Performance and Computing Resource Efficiency of In-Memory Big Data Analytics with Disaggregated Persistent Memory

[Optimizing Performance and Computing Resource Efficiency of In-Memory Big Data Analytics with Disaggregated Persistent Memory]

[Optimizing Performance and Computing Resource Efficiency of In-Memory Big Data Analytics with Disaggregated Persistent Memory]: https://www.slideshare.net/databricks/optimizing-performance-and-computing-resource-efficiency-of-inmemory-big-data-analytics-with-disaggregated-persistent-memory

## Self-Service Apache Spark Structured Streaming Applications and Analytics

[Self-Service Apache Spark Structured Streaming Applications and Analytics]

[Self-Service Apache Spark Structured Streaming Applications and Analytics]: https://www.slideshare.net/databricks/selfservice-apache-spark-structured-streaming-applications-and-analytics
 
## Building Resilient and Scalable Data Pipelines by Decoupling Compute and Storage

[Building Resilient and Scalable Data Pipelines by Decoupling Compute and Storage]
[Building Resilient and Scalable Data Pipelines by Decoupling Compute and Storage]: https://www.slideshare.net/databricks/building-resilient-and-scalable-data-pipelines-by-decoupling-compute-and-storage


## Automating Real-Time Data Pipelines into Databricks Delta

[Automating Real-Time Data Pipelines into Databricks Delta]
[Automating Real-Time Data Pipelines into Databricks Delta]: https://databricks.com/session/automating-real-time-data-pipelines-into-databricks-delta

資料が公開されていなかった。

## Reimagining Devon Energy’s Data Estate with a Unified Approach to Integrations, Analytics, and Machine Learning

[Reimagining Devon Energy’s Data Estate with a Unified Approach to Integrations, Analytics, and Machine Learning]
[Reimagining Devon Energy’s Data Estate with a Unified Approach to Integrations, Analytics, and Machine Learning]: https://www.slideshare.net/databricks/reimagining-devon-energys-data-estate-with-a-unified-approach-to-integrations-analytics-and-machine-learning

## Data Prep for Data Science in MinutesA Real World Use Case Study of Telematics

[Data Prep for Data Science in MinutesA Real World Use Case Study of Telematics]
[Data Prep for Data Science in MinutesA Real World Use Case Study of Telematics]: https://www.slideshare.net/databricks/data-prep-for-data-science-in-minutesa-real-world-use-case-study-of-telematics

## A Deep Dive into Query Execution Engine of Spark SQL

[A Deep Dive into Query Execution Engine of Spark SQL]
[A Deep Dive into Query Execution Engine of Spark SQL]: https://www.slideshare.net/databricks/a-deep-dive-into-query-execution-engine-of-spark-sql

## Balancing Automation and Explanation in Machine Learning

[Balancing Automation and Explanation in Machine Learning]
[Balancing Automation and Explanation in Machine Learning]: https://www.slideshare.net/databricks/balancing-automation-and-explanation-in-machine-learning

## Enabling Data Scientists to bring their Models to Market

[Enabling Data Scientists to bring their Models to Market]
[Enabling Data Scientists to bring their Models to Market]: https://databricks.com/session/enabling-data-scientists-to-bring-their-models-to-market

Nikeの事例？
資料が公開されていなかった。

## TensorFlow Extended: An End-to-End Machine Learning Platform for TensorFlow

[TensorFlow Extended: An End-to-End Machine Learning Platform for TensorFlow]
[TensorFlow Extended: An End-to-End Machine Learning Platform for TensorFlow]: https://www.slideshare.net/databricks/tensorflow-extended-an-endtoend-machine-learning-platform-for-tensorflow

## Continuous Applications at Scale of 100 Teams with Databricks Delta and Structured Streaming

[Continuous Applications at Scale of 100 Teams with Databricks Delta and Structured Streaming]
[Continuous Applications at Scale of 100 Teams with Databricks Delta and Structured Streaming]: https://www.slideshare.net/databricks/continuous-applications-at-scale-of-100-teams-with-databricks-delta-and-structured-streaming

## How Australia’s National Health Services Directory Improved Data Quality, Reliability, and Integrity with Databricks Delta and Structured Streaming

[How Australia’s National Health Services Directory Improved Data Quality, Reliability, and Integrity with Databricks Delta and Structured Streaming]
[How Australia’s National Health Services Directory Improved Data Quality, Reliability, and Integrity with Databricks Delta and Structured Streaming]: https://www.slideshare.net/databricks/how-australias-national-health-services-directory-improved-data-quality-reliability-and-integrity-with-databricks-delta-and-structured-streaming
