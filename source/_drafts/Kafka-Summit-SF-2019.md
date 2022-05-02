---

title: Kafka Summit SF 2019
date: 2019-09-30 09:14:11
categories:
  - Research
  - Conference
  - Kafka Summit
tags:
  - Kafka Summit
  - Conference
  - DataHub
  - Stream Processing

---

# 参考

* [Kafka Summit SF 2019]

[Kafka Summit SF 2019]: https://kafka-summit.org/kafka-summit-san-francisco-2019

# メモ


## 概要

Junいわく、登録は2100人くらい。
歩留まりはだいたい6割強？とのこと。

パット見の雰囲気で、若いTシャツ族だけではない。


## 1日目キーノート

### Tim Berglund

始めてきた人もそこそこいるようだ（写真）

コミッティ（写真）

### Jun Rao

LinkedInでの歴史。

Initial Database駆動アーキテクチャ。

Event > State

もしLinkedIn上でジョブを変更したら…ダウンストリームに影響を与える。
emailサービス、レコメンデーションエンジン、サーチインデックス。

つづいて、デジタライズされたイベント処理。
トランザクショナルデータは0.1%、それ以外が99.9%

データベースはマッチしなかった。

理由1（写真）★

理由2（写真）★

複雑なメッシュ（写真）

アドホックなパイプラインを作り始めることになった。

代わりにセントラルなログシステムがあったら…？


既存システムは、

* ボリュームに対応できなかった
* 永続性に難あり

という課題があった。★


Kafkaフェーズ1：High throubhput pub/sub

理由1に対する対応1（写真）★

理由2に対する対応2（写真）★

フェーズ1のKafkaのもたらしたメリット：データ民主化 ★
データ分析者がデータを自由に使えるようになった。
リアルタイムに。

つづいて、セキュリティ機能を追加した。

Connectも登場。（写真）

Kafka StreamsとKSQLも。
Kafkaの先のイベント駆動のマイクロサービスへつなげる。

感想：
SQLでのアクセスの限界がKafka登場の一つの要因だったのにかかわらず、KSQLが登場したのは面白い。
また結局、トランザクショナルなデータも入ってきたし。

Royal Bank of Canadaの事例。（写真） ★
最初は再濾過されたのを解消し、様々なアプリケーション開発に用いていった。

ZooKeeperの依存関係を解消する！★
（拍手）

メタデータをBrokerに持たせる（写真）★

Walmart Labs Chris Kastenの登場。

5 billion messages/dayの量をさばく必要があった。
（50億のイベント処理？）

ユースケースは？
ストリーミングバックグラウンドに使用。
11;40のセッションで紹介。
セキュリティ、データ分析に利用。

サプライチェーンの構築。

グローサリ。
注文をKafkaに入れ、顧客が到着するときには商品が用意されている、という状態に。
例えば、子供がいる家では車を降りることなく、商品をピックアップ可能。

（写真）

5ビリオンイベント/dayがKafkaで処理されている。

## 1日目セッション

###11:00 AM Stream Processing vs. RPC with Kafka and TensorFlow

Kai Waehner, Confluent

key takeaways （写真）

モデルをどうやってデプロイするか、どうやって商用利用するのか課題。

いつものTechnical Debtの図

ユースケース。

Netflixのリコメンデーション。

Uber。様々なフレームワークを用いた機械学習を実施。

PayPal。異常検知。

ユースケース企業の例（写真） ★

ユースケースの樹形図（写真） ★

ストリーム処理エンジンと機械学習関連技術の連係（写真）★

モデルはバイナリ。それをどうやってデプロイすべきか？★

モデルサーバによるデプロイ。

ここではTensroFlow Servingの例。
HTTPだけではなく、gRPCでやり取りできる。

gRPC/HTTPでKafka Steamsの中からAPIを呼び出し。（写真）

エラーハンドルが必要。特にネットワークエラー、gRPCエラーが生じるため。
ストリーム処理外の処理を呼び出すのは、ストリーム処理のアンチパターンではある。★

Embeddedモデルのパターン。（写真）★

TensorFlowの場合、モデルはただのバイナリ。だからロードして用いれば良い。

ネットワーク呼び出しのエラーハンドリングがいらない。

どんなモデルが直接埋め込まれるべきか？
検討の観点（写真）★

モデルサーバが持っている特徴をどう再現するか？は課題ではある。
モデル更新、バージョニング、A/Bテスト、canaryなどなど。★

k8sに新しいモデルを使ったアプリをデプロイしていく…？（写真）

感想：一度デプロイしたストリーム処理の更新は大変だから、ブルーグリーンデプロイメントしていく、という手はあると思う。ただし、切り替えには気をつけないと…。最終的なサービング層での取り回しは大変そうだ。★

トレードオフ。（写真）

クラウドサービスとの連係（写真）★
サイドカーパターンというらしい。

エッジでの推論。

https://github.com/tensorflow/io ★

TensorFlowの入出力プラグイン。Kafkaにも対応。これでTensorFlowにデータをフィードする、という手もある。

### 11:55 AM Using Kafka to Discover Events Hidden in your Database

Anna McDonald, SAS Institute

イベント、イベント駆動。
イベントソーシング。

イベントの種類：Primary、Derivative

Primaryの方は直接的？Derivativeのほうが間接的？
後者のほうが大変。

イベントストーミング。

Derivativeイベントは、観測されたイベント。

CDCを使って、binlogからイベントを取り出す ★

アプリケーションから、データベース自体を触ることなく、イベントを捉えることができる。

Debezium ★
https://debezium.io

CDCを使った処理のフロー（写真）

まず、オーダとプロダクト情報をマージする。
イベントの完了を検知する情報は今回の例では3個。

Kafka Streamsを使って、求める情報を得る例。
groupBy, aggregate, join, filter。

スキーマの例。


CDCは大変。

デモの例
https://github.com/jbfletch/kstreams-des-demo

プロダクションではGolden Gateを使った。

### 1:45 PM What's Inside the Black Box? Using ML to Tune and Manage Kafka

Matthew Stump, Vorstella

なぜトラブルシュートが難しいのか。（写真）

例えばCassandraは数百のメトリクスを吐き出すが、それを数百のノードで取ったら、どうやってダッシュボードに可視化すべきか？

Kafkaのメトリクス可視化ダッシュボードの例（写真）

ハイレベルアーキテクチャ（写真）
ちなみに、今回のログはGCの例。

データフローとコンセプチャルアーキテクチャ（写真）

教師あり・なし学習の両方を利用。（写真）

強化学習で、チューニングの効果を予測？
ベイズ最適化を利用。ハイパパラメータのチューニング。
JVMのチューニングなど。

クラスタのワーカ間の通信にハブとしてKafkaを利用。

Kafkaはデフォルトでうまく動作するようになっているから、そこから外れた際にチューニングするときのノウハウがドキュメント化されていない。★

Kafkaがおかしくなったときの状況（写真）

例えば…大きなサイズのメッセージを扱う際どうするか？（写真） ★

S3との組み合わせ、はよくあるソリューション。

解決策の例（写真）★

次の例は、リバランスストーム。（写真）
k8sを使っているときの、再起動オペレーションとの組み合わせのように見える。

"A smarter way to manage your data infrastructure"
https://vorstella.com

Kafka、Cassandra、などにいま対応していて、プロダクトを増やそうとしているらしい。

Consumerのパフォーマンスもベイズ最適化で改善可能。
JVMの最適化だけでかなり効果がある。

教師あり学習の学習データをどうやって集めたのか？
→エラーの数など、いくつか指標がある、との回答だった…？

### 2:40 PM From Trickle to Flood with Kafka @ ING

Filip Yonov, ING; Timor Timuri, ING

Kafkaを4年以上使っている。クラスタは1個のようだ？→ではなかった。DRも考慮されているようだ。

300チームが使っている、とのこと。

規模感のスライド（写真）

Kafkaは、ING内で非常に重要な責任を担う機能である。

オペレーション上の懸念点（写真）→そこで自動化した（写真）

Kafkaを広く使ってもらうことにした。つまりセルフサービス化（写真）

セルフサービス化のために実施したこと（写真）

メタデータ（トピック情報など）の管理サービスを独自開発。（写真）

暗号化はエンドツーエンドの方式を採用。 ★

スループットの管理なども必要になりそう。

ブローカだけの管理か？→やりたい。が、Connectは安定しているとは言い難い（笑）

DRは？→複数クラスタで構成されているのが実際。

誰がどうサブスクライブしているのかも管理している。

GDPRにはどう対応している？
→ 3日でデータが消えるようになっている。

## 2日目キーノート

### Tim Berglund

### Jay Keps

Marc Andresessen

Using & Becoming Software（写真）

Human centricな方法だと1 - 2 weeks
ソフトウェアセントリックな方法だと秒単位。

クラシックな3層（写真） → サービスメッシュ？

ではデータベースはどうか？

基本的な仮定：データはパッシブ
この場合CRUD、同期。

イベントストリーム（写真） ★
kafkaのその中央の抽象化層。

ストリームテーブルセオリ（写真）

何かが同期的。

PushとPull（写真）

今日のハイレベルアーキテクチャ（写真）★

Easy <==> Mainstream

ストリーム処理の基盤は大変。パーツも多いし、動き続けているし。

→KSQL

Connect インテグレーション
https://github.com/confluentinc/ksql/blob/e13cb46f902fecbf04b5ab9ea69fe3dcaf5d50a2/design-proposals/klip-7-connect-integration.md

Pull
https://github.com/confluentinc/ksql/blob/e13cb46f902fecbf04b5ab9ea69fe3dcaf5d50a2/design-proposals/klip-8-queryable-state-stores.md

DWHのアーキテクチャは、FactsとDimsのテーブルで構成。
マテリアライズドビュー。

イベントストリームプラットフォームを使おう、という宣伝

KSQLのSink Connector対応（写真）


### Dev Tagare, Lyft


マイクロサービス、リアルタイムの意思決定、ETLなどにKafkaを使用。

Confluent Cloudも利用。

ボリューム。
6 billion events/day？

ロケーション情報がKafkaクラスタに入る。

ロケーション情報がKafkaに入った後、
100モデルくらいができあがり、どれが良いかを判断する。

レイテンシの保証。

画像をS3に入れ、画像を機械学習処理する。
→なんの画像か聞きそびれた。

### Priya Shivakumar

Confluent Cloud

DIY KafkaとAWS Kinesis

OSS利点とクラウドの利点の間にはギャップがある。

Confluent CloudはServerless

UIからKafka環境を作り、トピックを作り、KSQLでクエリをかける、など。
Schema Registryもビルトイン。

一時的な負荷向上にも対応（追加料金がかかるようだ）


ガートナーの人のコメント
https://twitter.com/nheudecker/status/1179087060394622976?s=20

### 10:30 AM How to Build Real Time Price Adjustments in Vehicle Insurance on Streams

Dominique Rondé, freeyou AG; Kai Atenhan, freeyou AG


数字に関する写真いくつか（写真）

タリフ（写真）

料金設定は、条件の組み合わせ（写真）

リスクに対して保険料が安すぎると最悪である。

課題定義（写真）★
顧客は価格比較しながら契約するけれども、保険会社としては価格決定の仕組みに課題がある。

モンテカルロシミューレーションを通じ、保険料金を算出（写真）

最初のTry（写真）

→2個め（写真）ストリーム処理ベースにした。

KSQL

マーケットに対し、高すぎるのか低すぎるのかを考える。★

落とし穴がいくつかあった。

One System for all specialists（写真）

DXの課題は技術そのものではない。使い方である。

極力、ユーザが快適で居続けるように考慮した。

プライバシを考慮（写真）
KSQLを利用し、イベント定義、処理、必要なカラム抽出を実施。

データフロー（写真）

コンバージョンレートで判断。★

どのくらいが計算されているのか（写真）

Q.
KSQLを数学的計算に用いたか？
A.
いまはFilteringなどシンプルなケースだけに使っている。

Q.
アクセス管理はどうやっているのか？
A.
Kafkaクラスタへのアクセスは制限されている。
そもそもGDPRの適用のなるデータは入れていない。

Q.
価格決定のところをもう少し説明してほしい。
A.
Kafkaの外側で計算。

### 11:25 AM Building a Newsfeed from the Universe: Data Streams in Astronomy

Maria Patterson, High Alpha

（写真）

ペタバイトスケールのデータ。（写真）

画像から差分を抽出し、変化を検出。
アラートの上がる件数（写真）

宇宙調査のアラートシステム
観測所からデータを送る。フィルタしながら。
アーカイブもする。

XMLベースのデータフォーマットだった。色々課題があった（写真）

→Avro導入。Confluentのアドバイスより。

画像データも含む？（写真）



前は、Twistdを使っていた。
https://www.twistedmatrix.com/trac/

Kafkaを利用。
Kafka Streamsを利用していないようだ？

https://github.com/lsst-dm

https://github.com/lsst-dm/alert_stream

PythonベースのAPIのようだ。以下参照。

https://github.com/lsst-dm/alert_stream/blob/master/python/lsst/alert/stream/alertProducer.py

Kafka間のデータコピーにはMirrorMakerを利用。

アーキテクチャ図（写真）

### 1:00 PM Discovering Drugs with Kafka Streams

Ben Mabey, Recursion Pharmaceuticals; Scott Nielsen, Recursion Pharmaceutical

一つの薬にかけるコスト（時間？）は増加の一途。
ムーアの法則の反対。

健康な細胞と病気の細胞。
病気の細胞に薬を投与するとどうなるのか？をモデル化する。

308 wells/plate

ハイレベルアーキテクチャ図

データサイズの変化。（写真）

バッチベースの処理には困っていた。

マイグレーションゴール（写真）

処理フロー（写真）

daggerというフレームワークを開発した？

siteの特徴量を抽出し、Kafka Streamsで処理（分析）する。

JSON形式でワークフローを表現…？

Dagger is a compiler

Kafkaをパイプラインの中心とし、Daggerを使ってワークフローを定義し実行する。（写真）

メタデータだけをKafkaに入れる？★
画像のURLなど。

### 4:55 PM Static Membership: Rebalance Strategy Designed for the Cloud

故障時に、どうやってステートを再現するか。

故障発生時の時間を短縮するため、リバランスに要する時間を減らしたい。

時間の設定可能性（写真）

不要な再アサインメントが生じるケース

stickinessを追加

## その他

### Certification

Developerは半年前から。
Admin（Ops）は2ヶ月くらい前から。
だいたい1000人以上はいるはず。

### Kafka Meetup

来年3月予定とのこと。



<!-- vim: set tw=0 ts=4 sw=4: -->
