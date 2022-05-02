---
title: MLOps Conference 2019
date: 2019-09-24 09:00:43
categories:
  - Research
  - Machine Learning
tags:
  - MLOps
  - Machine Learning
  - Conference
---

# 参考

* [MLOps Conference NYC 2019]

[MLOps Conference NYC 2019]: https://www.mlopsnyc.com


# メモ

MLOps is where science meets reality.

## キーノート

### data science @ New York Times

Chris Wiggins, Chief Data Scientist, The New York Times

Facebookにてdata scientistのロール確立。

20世紀、21世紀のニュース。21世紀にはデータが追加された。

モデルの持つべき性質:

* descriptive
* predictive
* prescriptive

気になることは…スピード？スケール？コスト？

Tool: Readerscope
https://www.erincoughlin.com/nyt-readerscope

interpritable models

読み手の意見を集めた。

アーキテクチャとフロー概要。（写真）

w/ "audience development" team
Twitter, Slack, などなど。
ユーザの反応。

キュレーション。2018年にリリース。

機械学習ニーズに関するヒエラルキー。（写真）

プライバシー。

Q）プラクティスを教えて。

A）システム・インテグレーションがチャレンジだった。AWS、Google、…。
SQLアクセスがゲームチェンジャだった。様々なデータストアにSQLでアクセスする。

Q）なぜGCPを選んだ？

A）リレーションシップ。

## セッション

### Using MLOps to Bring ML to Production

David Aronchick, Head of Open Source ML Strategy, Microsoft

MSの中でMLが使われているサービス（写真）

スケール感（写真）

モデルのビルドに時間をかけている。

フロー（写真）

GitOps = Git Dev Ops

GitOpsの肝は、VelocityとSecurityだった。

MLOps = ML Dev Ops

MLOpsの利点（写真）

同じく、VelocityとSecurityは肝。

MSも内部的にTFXを使っている。
Uberのミケランジェロも使っている。

CI/CDをまたいで、複数の環境を使い分ける（写真）
データの在り処とコードの在り処？

プロダクションにMLモデルを持っていく際の細かな課題（写真）

モデルの説明可能性は大事であるが、それだけではない。
前後の処理も含めてトレーサビリティを確保するのが重要。（写真）

モデルはコードではない。
すぐに劣化する。

### Netflix Presents: A Human-Friendly Approach to MLOps 

Julie Pitt, Director, Data Science Platform, Netflix
Ashish Rastogi, Content Machine Learning Lead, Netflix

ヒューマンセントリックアプローチ。

オーディエンスの数の推定がビジネス課題だった。

ゴール：スケーリング。意思決定者への情報提供？

ライフサイクル：

* Explore
  * 2週間
* ほげ
* Productionize
  * スケールとデプロイ
  * 12週間

METAFLOW
http://metaflow.fr/ かな？→違うようだ。

データサイエンティストが気にするものと、商用化で気にすべきもの（写真）

METAFLOWを使った実装のイメージ（写真）

気になること：ステップが多数になると見通しが悪くなるけどどうすればよいのか？

レジュームもできる。

コンポーネント（？）単位でCPU、メモリを割り当てることができる。
デコレーションで。

並列分散処理も可能。

リアルタイムスコアリングへの利用（写真）

数カ月後に登場予定？

複数人のデータサイエンティストがモデルを引き継ぎながら開発できるようになっている。（写真）
例えばフローの実行IDを引き継いだり、とか。

タグ付の機能もある。

Netflix内では着実に適用がすすんでいる。その効果も出ている（写真）

Q）どうやって古いモデルをクリーンしているのか？

A）...

Q）どのくらいのユーザ？

A）100ユーザがいる。

個人的に質問。

Q）複数のライブラリの抽象化は？

A）基本的にはMetaflowではデコレーションするだけなので、デコレートされたメソッド内で好きに書けば良い。

Q）並列分散処理の仕組みの抽象化はどうやっている？

A）これから対応。基本的には1プロセスでの処理。

Q）TensorFlow Servingなどの他のサービスとの連係は？

A）外部サービスをラップし、抽象化した上で使うことは可能だと思うが、基本的にはこれから対応。


### Data as the Enabler of Digital Transformation 

Bill Groves, Chief Data Officer, Walmart

60%から80%のAI/MLプロジェクトがローンチされないことになる。
その理由（写真）

Walmartでのユースケース（写真）

Walmartでのアプローチ（写真）

### Real-time Financial Fraud Detection 

Arthur Garmider, Architect, Payoneer

https://www.payoneer.com/ja/ →日本法人もあるようだ？

アンチマネーロンダリング

マネートランスファーソリューション。様々な企業と連携（写真）

スケール感（写真）

例えば、26Bドルの取引を担ってきた。

不正の例：

* 存在しないユーザのカード。
* マネーロンダリング。盗まれたカードで支払い、結果として金を受け取る。

ミリ秒単位でトレースバックする必要がある。

もともとは30分くらいかけて検知していたようだ。
オペレーショナルなデータベースからミラーし、そこからオフラインで特徴抽出していた。

これをAWSのラムダ、SageMaker等を使って代替。（写真）

フロー（写真）

Kafkaも使っているようだ。CDCで抜いた情報をKafkaに入れている。
イベント情報として取り出し、Sparkで処理する。

Spark、Dask、Keras、…を使っている。

KVSがメインストレージ。
Parquetファイルも使っている。

Q）KVSは何に使っている？

A）TrainerはKVSをデータストアに使っている。

### The Architecture That Powers Twitter’s Feature Store 

Brittany Wills, Software Engineer, Twitter

スモールチームのアドホックな対応。

特徴カタログ。
特徴にアクセスするための情報を保持している。

例（Scala…）（写真）

オフラインアクセス。

CasscadingベースのScaldingを使っているようだ。

感想：NetflixのPythonですべてを済ませようとするMetaflowとは異なるアプローチだ。

「Strato」DB、サービス、Cache への抽象化層？（写真）

Q）特徴はスタティックなデータ？

A）データベース、キャッシュなど。（つまり、動的なデータも含む、ということか）

### Serverless for ML Pipelines from A to Z 

Orit Nissan-Messing, VP of R&D, Iguazio

ライアルタイム活用のアーキテクチャ例（写真）

NuclioがETLとストリーム処理を加速する。（写真）

https://nuclio.io

https://github.com/nuclio/nuclio

印象：基本的にはk8s上にローンチする、関数を実行するためのストリーム処理エンジンか？
      ノートブックの機能を持っているので、それを使って処理をかけるのか？

現在の機能は https://github.com/nuclio/nuclio/blob/master/ROADMAP.md に記載されているっぽい。

### Deep Learning on Business Data at Uber 

Alex Sergeev, Software Engineer, Uber

Deep Learningはデータ量があるほど、他の古い機械学習アプローチよりも性能が良くなる傾向がある。

ハイレベルアーキテクチャ（写真）

TFXとSparkの両方のアプローチがある。→UberはSparkを選んだ。

One hot encodingの例。

Spark ML Pipeline。
Estimatorで前処理、各レイヤを実装する。

多くのモデルはシングルマシンで学習できる。

Petastorm: https://github.com/uber/petastorm

以上が学習。続いて推論。

推論パイプラインの図（写真）

コンテンをSpark MLのタスクの横で動かす。（同じホスト上で）

Spark MLlibのパイプラインの仕組みに乗っかるので、
既存のEstimatorとの連携も容易とのこと。

推論時は、コンテナ化されたモデルを利用。

感想：TwitterのScaldingベース、NetflixのPythonデコレーションベースの仕組みとまた異なるアプローチ。

Q）Kubeflowが出てこなかったが…？

A）Kubeflowが登場する前の仕組みだから。

### The Growth and Future of Kubeflow for ML 

Maulin Patal, Product Manager, Google
Jeremy Lewi, Lead Kubeflow Engineer, Google

様々なフレームワーク、アーキテクチャに対応しないといけない。

（略）

### Stateless ML Pipelines 

James Norman, Lead Software Engineer, Nike

Nikeの前はUCLAで研究していた。
7年ほど。

データサイエンスのスケールが課題。

コンセプト（写真）

ステートレスパイプライン（写真）

印象：基本的には、アドホックな対応をやめた、ということに近いようだ。

ライフサイクル（写真）

Airflowを利用しているようだ。
しかしAirflowを単純に利用する方法から、コンフィグレーションを書く方法に移行したようだ。

補足：つまりAirflowだと実装量がそこそこになってしまうところを、コンフィグレーションとして
シンプルに表現できるように、というようにみえた。

パイプラインはDAGで表現。
同じような処理を繰り返す場合にも対応。

独自にライブラリを開発。ノートブック上で利用できるようにした。

データサイエンティストが使いやすいように、PATH（URL）の展開ライブラリも提供。
URL内には、ステップIDが含まれるようになっている。（写真）

### The RAPIDS Ecosystem  Scaling Accelerated Data Science 

Josh Patterson, GM, Data Science, NVIDIA

RAPIDSの話。以前聞いたことがあったので略。

nuclioとRAPIDSの連携の話もちらっとあった。

### Best Practices for Multiplatform MLOps with Kubeflow and MLflow

Clemens Mewald, Director of Product Management, Machine Learning and Data Science, Databricks

David Aronchick, Head of Open Source Machine Learning Strategy, Microsoft

Thea Lamkin, Open Source Program Manager, Google

Moderated by Yaron Haviv, CTO, Iguazio

ほげflowが乱立している。

OSSなのか、マネージドサービスなのか。
Googleの立場としては、スケールさせるときにサポートできるのがマネージド、ということか。

APIをスタンダード化することが大切

AI/MLのマネージドクラスタの違いとは？
Databricksに対しては「SageMakerとの違い」を聞いていた。→オンプレへの対応がキーである、というスタンスのようだ。

### MLOps Challenges and Future 

Yaron Haviv, CTO, Iguazio

ラップアップ。

DevOpsの定義。アラインメント（対ビジネスの目的）

Feature Store as a Service

ML Function as a Service

補足：2個目はAmazon SageMakerなどか。

オープンでスタンダードな環境で動かす、ということ。

機械化がポイント（写真）

クリアなAPIとコントラクトが不足？

コントラクトの例（写真）→mlrun

https://github.com/mlrun/mlrun


特徴量の管理はチャレンジング（写真）
形態により、方式が異なる。さらにその間の同期を維持するとか…。

Feature Storeをどう設けるかがポイント。

MLOpsプラットフォームも、いずれ標準化が進むに違いない、と。
コンテナプラットフォームの標準化が進んだように。

<!-- vim: set tw=0 ts=4 sw=4: -->
