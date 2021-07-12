---

title: >-
  On-the-fly Reconfiguration of Query Plans for Stateful Stream Processing
  Engines
date: 2019-08-03 19:51:29
categories:
  - Knowledge Management
  - Stream Processing
tags:
  - Stream Processing
  - Paper

---

# 参考

* [On-the-fly Reconfiguration of Query Plans for Stateful Stream Processing Engines]

[On-the-fly Reconfiguration of Query Plans for Stateful Stream Processing Engines]: https://dl.gi.de/handle/20.500.12116/21739

# メモ

Bartnik, A., Del Monte, B., Rabl, T. & Markl, V., らの論文。2019年。

多くのストリーム処理エンジンが、データ量の変動に対して対応するためにクエリの再起動を必要とし、
ステートの再構成（再度の分散化？）にコストを必要とする点に着目し、新たな手法を提案。
Apache Flinkへのアドオンとして対応し、外部のトリガを用いてオペレータの置換を行えることを示した。

Modificaton Coordinatorを導入し、RPC経由でメッセージ伝搬と同一の方法でModificationに関する情報を
各オペレータインスタンスに伝える。
またステートの保持にはCheckopintの仕組みを導入し、各オペレータインスタンスごとに
ステートを永続化する。上流・下流オペレータはその状況を見ながら動作する。

多くの先行研究に対し、以下の点が特徴的であると言える。

* 並列度の変更だけではなく、データフロー変更、オペレータの追加に対応
* ステートサイズが小さいケースに加え、大きい場合も考慮し実証
* ステートサイズが小さい場合で数秒、ステートサイズが大きい倍で数十秒のオーダで
  オペレータインスタンスのマイグレーション、オペレータの追加などに対応
* Exactly onceセマンティクスを考慮

## 1 Introduction

ストリームデータの流量について。
ソーシャルメディアの昼夜での差のように予測可能なものもあるが、
スポーツや天気の影響のように予測不可能なものもある。

最近のSPE（Stream Processing Engine）は、実行中の設定変更に一部対応し始めているが、
基本的には設定変更のためには再実行が必要。
（ここではApache Flink、Apache Storm、Apache Sparkを例にとっている）

そこで、提案手法では、実行中の設定変更を可能にする。

* ネットワークバッファのサイズ変更
* ステートフル/レスの両オペレーションのマイグレーション（オペレータをほかのノードに移す）
* 並列度の変更
* 新しいオペレーションの追加
* UDFの変更

Apache Flinkに上記内容をプロトタイプし、動作を検証。

## 2 Background

### 2.1 Data Stream Processing

近年のSPEのターゲットは、大量データの並列分散処理。
アプローチは2種類：マイクロバッチ、tuple-at-a-time。

マイクロバッチはスループット重視。

tuple-at-a-timeは入力レコードに対して、より細かな粒度での処理を可能にするが、
実際のところ物理レベルではバッチ処理のメカニズムを採用している。 [^Ca17]

[^Ca17]: Carbone, P.; Ewen, S.; Fora, G.; Haridi, S.; Richter, S.; Tzoumas, K.: State Management in
Apache Flink: Consistent Stateful Distributed Stream Processing. VLDB, 2017.

SPEでは、基本的にはデータフローの表現にDAGを利用。
Source、Processing、Sink、それをつなぐEdgeで構成される。
Processingノードはステートフル、ステートレスのどちらもあえりえる。

### 2.2 Apache Flink

FlinkはParallelization Contract (PACT)プログラミングモデルを採用。
Flinkは投稿されたクエリをコンパイル（最適化含む）したうえで実行する。

Flinkはパイプライニングとバッファリングに依存する。
オペレータがデータを送信するときにはバッファを使用しバッファが一杯になったら送るようになっている。
これによりレイテンシを抑えつつ、スループットを稼ぐ。

Flinkはオペレータのフュージョンにも対応。
フュージョンされたオペレータはプッシュベースで通信する。

バックプレッシャもある。

### 2.3 Fault Tolerance and Checkpointing in Apache Flink

チェックポイントは、状態情報を保存し、故障の際には復旧させる。
このおかげで、メッセージの送達保証の各セマンティクスを選択できるようになる。
また、セーブポイントのメカニズムを築くことになる。
これにより、計画的に停止、再起動させることができるようになる。

Flinkの場合、セーブポイントから再開する際に、並列度を変えるだけではなく、
オペレータを追加・削除可能。

定期的なチェックポイントにより、状態情報が保存される。
状態情報が小さい場合は性能影響は小さい。（逆もしかり）

Flinkでは、プログラムエラーの際は実行を停止・再開し、最後にチェックポイントした
状態情報から再開する。
このとき、データソースはApache Kafkaのように再取得可能なものを想定している。
そうでないと、クエリの再開時にデータが一部失われることになる。

## 3 Protocol Description


#### 3.1 System Model

![システムの前提](/memo-blog/images/39iYCq4GlQUG0dtA-77C78.png)

Operatorはそれぞれの並列度を持つ。
論理プランは、Source、Sink、Processing OperatorでDAGを構成する。
実際にSPE上で動作する物理プランをJobと呼ぶ。

Operatorは

* 単一の下流のOperatorにレコードを送る
* すべての下流のOperatorにブロードキャストする
* 何らかのパーティションルールにより送る

のいずれかの動作をする。

CheckpointのためにMarkerも送る。
Markerは定期的か、ユーザ指定により送られる。
`i` は、`i`番目のCheckpointであることを示す。
内部通信経路でMarkerを受け取ったオペレータは、スナップショットを作成して下流のオペレータにMarkerを送る。
また、スナップショットは非同期的にバックグラウンドの永続化ストレージに保存される。

ここで、SPEはExactly Onceでの処理を保証するものとする。
SPEはControllerとWorkerで構成される。

### 3.2 Migration Protocol Description

Modification Markerを送ることで、マイグレーションを開始する。 [^DM17]

[^DM17]: Del Monte, B.: Efficient Migration of Very Large Distributed State for Scalable Stream Processing. VLDB PhD Workshop, 2017.

各Operatorは、eventualにMarkerを受けとり、マイグレーションに備えるが、
このとき枚グレート対象となるOperatorの上流・下流のOperatorにも影響することがポイント。
上流のOperatorは、バッファを駆使しつつ、Tupleの順序性を担保する。

### 3.3 Modification Protocols Description

Operatorをマイグレートするだけでなく、Operatorの追加、更新が可能。
ただし、その場合はUDFの配布が必要となる。

#### 3.3.1 Introduction of New Operators

上流OperatorはMarkerを受け取るとバッファリングし始め、その旨下流に通知する。
すべての上流Operatorのバッファリングが開始されたら、新しいOperatorのインスタンスが起動する。
ただし、実際に起動させる前に、あらかじめUDFを配布しておく。
下流Operatorは、新しく起動されたOperatorに接続を試みる。

## 4 System Architecture

試したFlinkは1.3.2。 ★

### 4.1 Vanilla Components Overview

まずクライアントがModification ControlメッセージをCoordinatorに送る。
CoordinatorはWorkerに当該情報をいきわたらせる。
このメッセージは、通常のデータとは異なり、RPCとして送られる。
ここではActorモデルに基づく。

Flinkの場合、2個のOperator間の通信はProducer/Consumer関係の下やり取りされる。

各Operatorのインスタンスは、上流からデータを取得するための通信路に責任を持つ。

![システムアーキテクチャのイメージ](/memo-blog/images/39iYCq4GlQUG0dtA-35807.png)


### 4.2 Our Changes on the Coordinator Side

Modification Coordinatorは、Modificatoinに関する一切を取り仕切る。
バリデーションも含む。
例えば、現在走っているジョブに対して適用可能か？の面など。

Modificationの大まかな状態遷移は以下の通り。

![Modificationのステート](/memo-blog/images/39iYCq4GlQUG0dtA-B9EC0.png)

Modificationに関係し、Taskの大まかな状態遷移は以下の通り。

![Taskのステート](/memo-blog/images/39iYCq4GlQUG0dtA-A7E67.png)

### 4.3 Our Changes on the Worker Side

オペレータ間の通信は、オペレータの関係に依存する。
例えば、同一マシンで動ているProducerインスタンスとConsumerインスタンスの場合はメモリを使ってデータをやり取りする。
一方、異なるマシンで動ている場合はネットワーク通信を挟む。

さて、Modificationが生じた場合、新しいConsumerが動き始めるまで、上流のインスタンスはバッファリングしないといけない。
提案手法では、ディスクへのスピル機能を含むバッファリングの仕組みを提案。それ専用のキューを設けることとした。

### 4.4 Query Plan Modifications

あるOperatorがModificationを実現するには、上流と下流のOperatorの合わせた対応も必要。
そこでModification CoordinatorがModificationメッセージに、関連情報全体を載せ、RPCを使って各Operatorに伝搬する。

#### 4.4.1 Upstream Operators

Checkpointの間、上流から下流に向けて、Checkpointマーカーを直列に並べることで
故障耐性を実現する。
各オペレータは上流からのマーカーがそろうまでバッファリングを続ける。

もしオペレータをマイグレートしようとすると、このバッファもマイグレートする必要がある。
しかしこのバッファインの仕組みは、内部的な機能ではない（★要確認）ため、一定の手続きが必要。
Modificationメッセージには次のCheckpointのIDが含まれている。
このIDに該当するCheckpointが発動されたときには、マイグレート対象のオペレータの上流オペレータは
CheckpointバリアのメッセージをModificationメッセージと一緒に送る。
このイベント情報は、上流オペレータがレコードをストレージにフラッシュしていることを下流に示すものとなる。
また、これを通じて、マイグレート対象となるオペレータと上流オペレータの間には仕掛中のレコードがないことを確認できる。

以上を踏まえると、Modificationを安全に進めるためには、Checkpointを待つことになる。
Checkpointインターバルは様々な要因で決まるが、例えばオペレータ数とステートの大きさに依存する。
ステートが大きく、Checkpointインターバルが大きい場合は、それだけModification開始を待たなくてはならない、ということである。

#### 4.4.2 Target and Downstream Operators

下流のオペレータは、基本的には上流のオペレータの新しい情報を待つのみ。

## 5 Protocol Implementation

### 5.1 Operator Migration

Modification Coordinatorがトリガーとなるメッセージをソースオペレータから発出。
対象オペレータに加え、上流オペレータも特定する。（上流オペレータは、レコードをディスクにスピルする）

オペレータはcheckpointのマーカを待つ。
Checkpoint Coordinatorがマーカを発出し、マイグレート対象のオペレータの上流オペレータは
送信を止める。

各オペレータはPausing状態に移行するとともに、現在の状態情報をModification Coordinatorに送る。

さらに、下流のオペレータに新しいロケーションを伝える。

各オペレータがPaused状態に移行。
すべてのオペレータがPaused状態に移行したら、オペレータを再起動する。

その後、Modification Coordinatorが状態ロケーション？をアタッチし、タスクを実行開始する。

提案手法では、FlinkのCheckpointの仕組みを使用し、各オペレータの状態情報を取得し、アサインする。

### 5.2 Introduction of new Operators

オペレータのModificationと同様の流れで、新しいオペレーションの挿入にも対応する。
上流のオペレータがスピルした後、新しいオペレータが挿入される。
デプロイのペイロードには、コンパイル済のコードが含まれる。

### 5.3 Changing the Operator Function

Modification CoordinatorがModificationメッセージと一緒に、
新しいUDFを配布する。
Task Managerは非同期的にUFDを取得する。

またcallbackを用いて、グローバルCheckpointが完了したときに、新しいUDFを用いるようにする。

## 6 Evaluation

ここから先は評価となるが、ここではポイントのみ紹介する。

### 6.3 Workloads

3種類のワークロード、

* 小さなステートの場合を確認するため、要素数をカウントするワークロード（SMQ）
* 大きなステートの場合を確認するため、Nexmarkベンチマーク [^Tu18] のクエリ8（NBQ8）。（オンラインオークションのワークロード）
* 上記SMQ、NBQ8についてオペレータのマイグレートを実施

[^Tu18]: Tucker, P.; Tufte, K.; Papadimos, V.; Maier, D.: NEXMark - A Benchmark for Queries over Data Streams. 2018.

2個めのワークロードではステートサイズが大きいので、インクリメンタルCheckpointを利用。
Flinkの場合は、埋め込みのRocksDB。

### 6.4 Migration Protocol Benchmark


#### 6.4.1 Stateful Map Job Performance Drill Down

レイテンシで見るとスパイクが生じるのは、ストリーム処理のジョブがリスタートするタイミング。

オペレータのMigration中、1度3500msecのレイテンシのスパイクが生じた。
またコミュニケーションオーバヘッドもあるようだ。

概ね、秒オーダ。

#### 6.4.2 Nexmark Benchmark Performance Drill Down

概ね、100～200秒オーダ。

ステートサイズは全部で13.5GBで、そのうち2.7GBがステート用のバックエンドに格納され、再現された。

80個のジェネレータのスループットは、Migration発生時も大きくは変わらなかった。

### 6.5 Introducing new operators at runtime

SMQのワークロードを用いた検証。
概ね、秒オーダ。

### 6.6 Replacing the operator function at runtime

SMQのワークロードを用いた検証。
概ね、秒オーダ。

スループットへの影響は小さい。

### 6.7 Discussion

Checkpointの同期は課題になりがち。
ステートのサイズが小さいときは高頻度で同期も可能かもしれないが、大きいときは頻度高くCheckpointすると、処理に影響が出る。
例えばステートサイズが小さい時には6秒以内にModificationを開始できたが、大きい時には60秒程度になった。

NBQ8の場合、従来のシャットダウンを伴うsavepointの仕組みと比べ、性能上の改善が見られた。

データソースが永続的であれば再取得することでExactly Onceを実現する。

実行中のジョブに対し、新しいオペレータを挿入することもできた。概ね10秒程度。

オペレータの関数を変更することもできた。概ね9秒程度。
これを突き詰めていくと、内部・外部状態に応じて挙動を変える、ということもできるようになるはず。

★補足：
とはいえ、そのような挙動変更は、最初からUDF内に組み込んでおくべきとも考える。（普通に条件文を内部に入れておけば？と）
条件分岐が問題になるほどシビアなレイテンシ要求があるユースケースで、ここで挙げられているようなストリーム処理エンジンを使うとは思えない。
★補足終わり：

## 7 Related work

★補足：特に気になった関連研究を以下に並べる。

* Schneider, S.; Hirzel, M.; Gedik, B.; Wu, K.: Auto-parallelizing stateful distributed streaming applications. ACM PACT, 2012.
  * 並列度の変更に関する先行研究
  * 本論文の提案手法では、大きなステートサイズの際のexactly onceを対象としている点が異なる
* Wu, Y.; Tan, K. L.: ChronoStream: Elastic stateful stream computation in the cloud. IEEE ICDE, 2015.
  * 弾力性の実現に関する先行研究
  * ただし別の論文の指摘によると、同期に関する課題がある
  * データフロー変更には対応していない。あくまでオペレータのマイグレーションのみ。
* Heinze, T.; Pappalardo, V.; Jerzak, Z.; Fetzer, C.: Auto-scaling techniques for elastic data stream processing. In: IEEE ICDE Workshops. 2014.
  および、 Heinze, T.; Ji, Y.; Roediger, L.; Pappalardo, V.; Meister, A.; Jerzak, Z.; Fetzer, C.: FUGU: Elastic Data Stream Processing with Latency Constraints. IEEE Data Eng. Bull., 2015.
  * オートスケールのタイミングを判断する。オンライン機械学習を利用。
  * 簡単なマイグレーションのシナリオを想定。
* Nasir, M.; Morales, G.; Kourtellis, N.; Serafini, M.: When Two Choices Are not Enough: Balancing at Scale in Distributed Stream Processing. CoRR, abs/1510.05714, 2015.
  * 並列度の調整に関する先行研究
  * 特にホットキーが存在する場合、そこにオペレータインスタンスを割り当てるように動く。
  * データフロー変更などには対応しない。
* Mai, L.; Zeng, K.; Potharaju, R.; Xu, L.; Venkataraman, S.; Costa, P.; Kim, T.; Muthukrishnan, S.; Kuppa, V.; Dhulipalla, S.; Rao, S.: Chi: A Scalable and Programmable Control Plane for Distributed Stream Processing Systems. VLDB, 2018.
  * 本論文で扱っているのに近い
  * ただしステートサイズが大きなケースは対象としていない

