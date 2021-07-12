---

title: Strata Data Conference NY 2019
date: 2019-09-25 08:36:45
categories:
  - Research
  - Conference
  - Strata Data Conference
tags:
  - Strata Data Conference
  - Conference
  - Machine Learning

---


# 参考


# セッションメモ

Strata Data Conference NY 2019のカンファレンスメモ。
今回は退席時間が長かったため、部分的な聴講に閉じている。

## 概要

* 日時
  * 2019/9/23 - 26
  * セッションは25、26日
* 場所
  * Javits Center New York

## 9/25 キーノート

### 8:50am The road to an enterprise cloud

Mick Hollison (Cloudera), Hillery Hunter (IBM)

#### Mickの話

いろいろなクラウドがあり、いろいろなコンピューティング方式（エッジなど）がある。

Cloudera data platorm

#### Hilleryの話

Cloudの話。ステップについて。

複雑性を増す。

単一のCloudから、ハイブリッドへ。
マルチクラウド化。

IBMのメッセージは「マルチクラウド」。
Open、Secure、Managed。

ハイブリッドマルチクラウドプラットフォームのスタック（写真）

OpenShiftをベースとした「Cloud Pak for Data」

IBMとClouderaのパートナシップ

### 9:05am Recent trends in data and machine learning technologies

Ben Lorica (O'Reilly Media)

参加者の傾向（写真）

Data Ingestion & Processing
kafka、パルサー、Spark、などなど。

データカタログ、データガバナンス、データリネージュ。

MLがデータ品質改善に使われ始めた。

ストレージにも着目。データオーケストレーション。★

データレイクの発想。（写真）

Delta Lake、Icebergなど。新しい潮流。（写真）
データ分析観点も含まれている。

＜ここでいくつか写真＞

Strata Data Conferenceのスピーカたちの写真（写真）

### 9:15am Everything is connected and the clock is ticking: AI and big ag data for food security

Sara Menker (Gro Intelligence), Nemo Semret (Gro Intelligence)

大豆の輸出入。
中国とブラジルと米国。

大豆は飼料として使われる。

豚肉の値段は？6、12、18ヶ月後の値段は？→全ては繋がっている（写真）

「Gro」

様々な技術の上に成り立っている（写真）
Automated knowledge graphなど。NLP、NN。

農業データのチャレンジ（写真）

結局、各プロダクトごとに関係性を持っているが、そのプロダクト間の関係もあり、
掛け算の関係性になる。→つまり、将来を予測するのは非常に難しい、ということ？


### 9:30am The future of Google Cloud data processing (sponsored by Google Cloud)

James Malone (Google)

OSSについて。

k8s。
オープンソースのプロダクトを動かす基盤として。

Spark k8s operator。19年1月。

k8s + Spark

2019/9にFlinkオペレータも登場。

これらの動きが示すところ（写真）

PySparkをJupyter上で動かすdemo


### 9:40am AI isn't magic. It’s computer science.

Robert Thomas (IBM), Tim O'Reilly (O'Reilly Media)

AI、MLのチャレンジの半分は失敗する。
データが手に入らなかったり…などが理由。

```
@timoreilly
: Rob started talking about the AI ladder, and my Spidey sense went off.  
@robdthomas
: there is no AI without IA: Information Architecture. Collect, organize, analyze, infuse.  #StrataData
```

まずデータを集め、データを扱えるようにすることが出発点である、と。
それがAIプロジェクトを成功させるひとつのポイント。

何が組織に足りないと思うか。

Automate AI。
特徴抽出など機械化。

AIはマネージャを置き換えないが、AIを使うマネージャは、ただのマネージャを置き換える。

### 10:00am Unleash the power of data at scale (sponsored by Intel)

Jeremy Rader (Intel)


デジタルトランスフォーメーションの取り組みを数年前から各社始めた。

データの増え方（写真）

Intelの紹介する成功ケース（写真）

15000人のソフトウェアエンジニア。

### 10:05am How disruptive tech is reshaping the financial services industry

Swatee Singh (American Express)

もともと生体系のプロジェクトに携わっていたらしい。

レガシーの破壊。（写真）

ブロックチェーンなど、様々な技術が登場している。
fintech

潜在的ニーズにリーチできる、ということが、破壊的技術のポイント。

なぜ、これらの技術を競って取り入れようとするのか？

キーワードはロイヤリティ、Trust、「個人」

Financialカンパニーはエッジコンピューティングを試行錯誤。
プライバシーを考慮、など。

78%のユーザがデジタルチェンネルを継続利用。

43%のユーザがAI利用や自動化を受け入れる？

1 to 1 のペイメントなど。

将来を予測するのは難しい。

### 10:20am It’s not you; it’s your database: How to unlock the full potential of your operational data (sponsored by MemSQL)

Nikita Shamgunov (MemSQL)

memSQL。

Toyotaとパートナーシップがある。

Helios by memSQL

Single Store
ロー、カラムナ。

### 10:25am Cisco Data Intelligence Platform (sponsored by Cisco)

Siva Sivakumar (Cisco)

1982年のブレードランナーが2019年の世界だった。
いくつかは実現されている。

自動運転は、魚の群れの動きと類似。

AI/ML、Hadoop Datalake、Objectストレージ。
これらを組み合わせる。

Ciscoのプラットフォームイメージ。

### 10:30am Interactive sports analytics

Patrick Lucey (Stats Perform)

ディズニーで顔画像認識などをしていたらしい。

AIをスポーツデータに適用。

プレイ画像に対して、クエリをかける（写真）
類似したプレイを探す、など。

どんなクエリを用いるべきか？
→テキストでのクエリではないだろう。

インタラクティブにゲームを分析する例（写真）

↑
どんなプレイヤがどんなことをしようとしているのかを推定。
手で書いたプレイの様子を使用し、類似したシチュエーションも検索可能。

AlphaGoと同様に、ゲームをシミュレート可能。
ゲームにどう活かすか？

データをトラッキングする取り組みの、その先へ

OpenPoseなどを使った分析へ。

## 9/25 セッション

### 11:20am Building a multitenant data processing and model inferencing platform with Kafka Streams Navinder

Pal Singh Brar (Walmart Labs)

補足：
100名以上は入った。

Timeは非常に重要。

メールやノーティフィケーションを直ちに送る。

WalmartのAI/ML活用（写真）

サンクスギビングのケース。

すべてデータの上に成り立つ。

データサイエンスのモデルのライフサイクル（写真）

50%がデータの準備。

ミッション：
イベントを処理し、推論をサーブするためのプラットフォームを作る。

Customer Backbone(CBB)は、RocksDBとKafkaで作られている。
その上で機械学習モデルをデプロイ。

前処理等も含まれている（写真）

CBBデータパイプライン。（写真）

なぜKafka Streamsを選んだか。（写真）

感想：インタラクティブクエリが大事、と言っているが、それがKafka Streamsを選んだ理由に入っているのが不思議。
      KSQLのことも含めているのか？

マルチテナンシのチャレンジ。（写真）

マルチスレッドでJVMを動かしているとき、ひとつのモデルが他のモデルに影響を与えてしまう。（プロセスを共有している場合）

pushベースのアーキから、pullベースに変更。
シーケンシャルな処理をやめ、非同期的な処理にした？ようだ。

データモデル（写真）

ある顧客のデータを紐付けるところからスタート。

シーケンスストア。
補足：ここがKafkaっぽい？

CBBプロセッサがキューに書き込むと、モデルがそれを刈り取って処理する。
モデルごとにオフセットを設ける？（写真）

全体アーキテクチャ。
グローバルなトピックが存在。
その他Appクラスタが存在し、グローバルトピックから伝搬するようになっている。
しかい、特定のKafkaに負荷が集中してしまう。
そこで異なるKafka Streamsアプリごとにグローバルトピックを作成？？（補足：よくわからなかった）

11000店舗。27国。など（写真）

アイデンティティグラフ処理。
複数のIDから同じ人物を見つけ、統合する。
いわゆるグラフ処理になる。
ひとつの顧客がひとつのマシンで処理されるようにする。


Q）一貫性の問題はどう処理している？ユーザは正しい情報を使うとは限らない。

A）バッチ処理で改修。リアルタイム処理の方では確率的な考え方になっている。


Q）どのくらい顧客情報の要素は複雑？Kafkaで扱うには難しくないか？

A）CBBは別でエンティティを持つデータベースが存在。 → Kafka Stramsの外側に持っているということらしい。

Q）依存関係はどう管理？

A）Jarに入れる。

あとは、セキュリティに関する議論あった。

### 1:15pm Low-latency computing and stream processing for financial systems (sponsored by Hazelcast)

John DesJardins (Hazelcast)

前にClouderaに3年いた。とのこと。

聴衆の3/4の人が金融関係の企業に務める人だった。

レイテンシが重要。そのためインメモリのアプローチ。
ミリ秒単位の処理。

Hazelcastのプラットフォームイメージ（写真）

様々な言語から利用できる。

### 4:35pm Search logs + machine learning = autotagged inventory

John Berryman (Eventbrite)

イベント、タグ、などたくさんのデータを扱う。

GitHubに転職したところ。

タギングとはなにか？

e-コマースサーチについて。サーチはユビキタス。

eコマースはサーチで強化される。

そして、横に表示されるのがタグ（写真）
フィルタに使われる。

そして、人々はモバイルに移行した。
モバイルではタイプしたくない。テキストよりもブラウズを好む。

タギングとは、カテゴライズすることであり、自分のインベントリを明らかにすることである。

タグ付けをどうやるか？（写真）
実施者に応じて、利点・欠点がある。

では、誰もやりたくないときどうすべきか？

Eventbriteでは多くのユーザが検索する。
検索クエリを観測すると、よく検索される単語はタグに似ていることに気がついた。

最初のアプローチ（写真）

notebookのdemo

（写真）

TFIDFでベクトル化した後、分析し、テキストから適切なタグを抽出しようとする。

このアプローチの難点（写真）

次のアプローチ（写真）

シノニムを考慮する。（写真）

クエリクラスタは、Affinity Propagationで特定する。

補足：https://tjo.hatenablog.com/entry/2014/07/31/190218

単語の関係性？を考慮した空間を算出（写真）

これを使って、タグを抽出。

本アプローチの良し悪し（写真）

実際には検索窓の横にタグを設けるようにしている。おすすめのタグ？


### 5:25pm Data science and the business of Major League Baseball

Aaron Owen (Major League Baseball), Matthew Horton (Major League Baseball), Josh Hamilton (Major League Baseball)

組織の関連性（写真）

分析のユースケースはマーケティングに限らない。

将来のスケジュールの評価

単一ゲームのチケット需要の予測。（写真）

他にもファンのセグメンテーションの例。

事情によりすべてを聞けなかったが、多数のユースケースがある様子。

Q）どんな技術を使っている？

A）クラウドを使っている。Pythonなど。

Q）特徴量エンジニアリング

A）非常にたくさんの種類があるため、PCAなどを利用し、適切に絞り込んでいる。

Q）チームパフォーマンスについては？

A）いまやっている

### 3:45pm Deep learning on Apache Spark at CERN’s Large Hadron Collider with Analytics Zoo

Sajan Govindan (Intel)

Hidden Technical Debtの論文を引用。

BigDL紹介。

Analytics Zoo紹介。

Kerasの分散処理も実現可能、とのこと。
補足：https://github.com/intel-analytics/analytics-zoo#distributed-tensorflow-and-keras-on-sparkbigdl

ラップトップからスケールアウト

分散処理での学習

分散モデルサービングの例
ウェブサービス、Flink、Spark、…の中で用いることができる、とのこと。

エコシステムとユースケース（写真）

ここからCERNのユースケースの例。

大きなデータを扱う研究背景（写真）

データサイズについて（写真）

データフロー図（写真）

k8sとHadoop YARNを両方使っている（写真）

JNIを使ってHDFSのファイルシステム経由で、HDFS外のストレージと接続

特徴量変換・加工は、PySparkでやっているようだ。Spark SQL、MLlibを利用

ハイパパラメータチューニングは、Sparkを使って並列に進められる。最後に最適なパラメータが算出される。

# ブース

## Hitachi

（写真）

Pentahoの関係かな…？

## aiven（Kafka as a Service)


（写真）

<!-- vim: set tw=0 ts=4 sw=4: -->
