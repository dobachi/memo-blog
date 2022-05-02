---

title: MillWheel Paper
date: 2019-06-14 15:38:59
categories:
  - Knowledge Management
  - Stream Processing
  - MillWheel
tags:
  - MillWheel
  - Stream Processing
  - Google
  - Paper

---

# 参考

* [Googleの公開サイト]
* [「MillWheel」から学ぶストリーミング処理の基礎]
* [The 8 Requirements of Real-Time Stream Processing]

[Googleの公開サイト]: https://ai.google/research/pubs/pub41378
[「MillWheel」から学ぶストリーミング処理の基礎]: http://www.school.ctc-g.co.jp/columns/nakai2/nakai210.html
[The 8 Requirements of Real-Time Stream Processing]: http://cs.brown.edu/~ugur/8rulesSigRec.pdf

# メモ

昔のメモをここに転記。

## 1. Introduction

故障耐性、ステート永続化、スケーラビリティが重要。
Googleでは多数の分散処理システムを運用しているので、何かしらおかしなことが置き続けている。

MillWheelはMapReduceと同様にフレームワーク。ただし、ストリーム処理やローレイテンシでの処理のため。

Spark StreamingとSonoraは、チェックポイント機能持つが、実装のためのオペレータが限られている。
S4は故障耐性が不十分。
Stormはexactly onceで動作するが、Tridentは厳密な順序保証が必要。

MapReduce的な考えをストリーム処理に持ち込んでも、妥協した柔軟性しか得られていない。
ストリーミングSQLは簡潔な手段をもたらしているが、ステートの抽象化、複雑なアプリケーションの実装しやすさという意味では、
オペレーショナルなフローに基づくアプローチのほうが有利。


* 分散処理の専門家でなくても複雑なストリーム処理を実装できること
* 実行可能性

## 2. Motivation and requirements

GoogleのZeitgeistを例にした動機の説明。

* 永続化のためのストレージ
* Low Watermark（遅れデータへの対応）
* 重複への対応（Exactly Onceの実現）

## 3. System overview

Zeitgeistの例で言えば、検索クエリが入力データであり、データ流量がスパイクしたり、凹んだりしたことが出力データ。

データ形式：key、value、timestamp

## 4. Core concept

キーごとに計算され、並列処理化される。
また、キーがアグリゲーションや比較の軸になる。
Zeitgeistの例では、例えば検索クエリそのものをキーとすることが考えられる。
また、キー抽出のための関数を定義して用いる。

ストリーム：データの流れ。
コンピューテーションは複数のストリームを出力することもある。

ウィンドウ修正するときなどに用いられるステートを保持する。
そのための抽象化の仕組みがある。
キーごとのステート。

Low Watermarkの仕組みがあり、Wall timeが進むごとにWatermarkが進む。
時間経過とともにWatermarkを越したデータに対し、計算が行われる。

タイマー機能あり。
Low Watermarkもタイマーでキックされる、と考えて良い。

## 5. API

計算APIは、キーごとのステートをフェッチ、加工し、必要に応じてレコード生成し、タイマーを
セットする。

Injector：MillWheelに外部データを入力する。
injector low watermarkも生成可能。

なお、low watermarkを逸脱するデータが生じた場合は、
ユーザアプリでは捨てるか、それとも現在の集計に組み込むか決められる。

## 6. Fault tolerance

到達保証の考え方としては、ユーザアプリで冪等性を考慮しなくて良いようにする、という点が挙げられる。

基本的にAckがなければデータが再送される設計に基づいているが、
受信者がAckを返す直前に何らかの理由で故障した場合、データが重複して処理される可能性がある。
そこでユニークIDを付与し、重複デーかどうかを確かめられるようにする。
判定にはブルームフィルタも利用する。
ID管理の仕組みにはガベージコレクションの仕組みもある。

チェックポイントの仕組みもある。
バックエンドストレージにはBigtableなどを想定。

なお、性能を重視しチェックポイントを無効化することもできるが、
そうすると何らかの故障が生じて、データ送信元へのAckが遅れることがある。
パイプラインが並列化すると、それだけシステム内のどこかで故障が生じる可能性は上がる。
そこで、滞留するデータについては部分的にチェックポイントすることで、
計算コストとエンドツーエンドレイテンシのバランスを保つ。 ★

永続化されたステートの一貫性を保つため、アトミックなオペレーションでラップする。
ただし、マシンのフェールオーバ時などにゾンビ化したWriterが存在する可能性を考慮し、
シークエンサートークンを用いるようにする。
つまり、新たに現れたWriterは古いシークエンサートークンを無効化してから、
動作を開始するようにしている。

## 7. System Implementation

MillWheelはステート管理のためにデータストア（BigTableなど）を使う。
故障発生時にはデータストアからメモリ情報を再現する。

low watermarkのジャーナルはデータストアに保存される。

感想：このあたりデータストアの性能は、最終的なパフォーマンスに大きく影響しそうだ。 ★

## 8. Evaluation

単純なシャッフル処理では、レイテンシの中央値は数ミリ秒。95パーセンタイルで30ミリ秒。
Exactly onceなどを有効化すると中央値は33.7ミリ秒。95パーセンタイルで93.8ミリ秒。

CPU数をスケールアウトしても、レイテンシに著しい劣化は見られない。（逆に言うと、99パーセンタイルではある程度の劣化が見られる）

low watermarkは処理のステージをまたぐと、実時間に対してラグが生じる。
このあたりは活発に改善を進められているところ。

ステート管理などにストレージ（BitTableなど）を使う。
これによりリード・ライトがたくさん発生する。
ワーカにおけるキャッシュは有効。

実際のユースケースは、広告関係。
そのほか、Google Street Viewでのパノラマ画像の生成など。 ★


## 9. Related work

ストリーム処理システムが必要とするものは、以下の論文に記載されている。
[The 8 Requirements of Real-Time Stream Processing]

Spark Streamingに対しては、MillWheelの方がgeneralであると主張。
RDDへの依存性がユーザに制約をもたらす、とも。
またチェックポイントの間隔はMillWheelの方が粒度が細かい。
