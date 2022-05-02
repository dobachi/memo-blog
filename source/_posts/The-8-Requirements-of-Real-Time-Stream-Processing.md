---

title: The 8 Requirements of Real-Time Stream Processing
date: 2019-06-22 23:35:41
categories:
  - Knowledge Management
  - Stream Processing
tags:
  - Stream Processing
  - Stonebraker
  - Paper

---

# 参照

* [The 8 Requirements of Real-Time Stream Processing]
* [ACMページ]
* [MillWheel]

[The 8 Requirements of Real-Time Stream Processing]: http://cs.brown.edu/~ugur/8rulesSigRec.pdf
[ACMページ]: https://dl.acm.org/citation.cfm?id=1107504
[MillWheel]: https://ai.google/research/pubs/pub41378

# メモ

[MillWheel] でも触れられているストリーム処理について書かれた論文。
2005年。
時代は古いが当時の考察は現在でも有用と考える。

## 1. Introduction

ウォール街のデータ処理量は大きい。
2005年時点で122,000msg/sec。年率2倍で増大。
しかも処理レイテンシが秒では遅い。
金融に限らず異常検知、センサーデータ活用などのユースケースでは同様の課題感だろう。

「メインメモリDBMS」、「ルールベースエンジン」などがこの手のユースケースのために再注目されたが、
その後いわゆる「ストリーム処理エンジン」も登場。

## 2. Eight rules for stream processing


### Rule 1: Keep the Data Moving

ストレージに書き込むなどしてレイテンシを悪化させてはならない。

ポーリングもレイテンシを悪化させる。
そこでイベント駆動のアプローチを用いることがよく考えられる。

### Rule 2: Query using SQL on Streams (StreamSQL)

ハイレベルAPIを用いることで、開発サイクルを加速し、保守性を上げる。

StreamSQL：ストリーム処理固有の機能を有するSQL
リッチなウィンドウ関数、マージなど。

### Rule 3: Handle Stream Imperfections (Delayed, Missing and Out-of-Order Data)

例えば複数のストリームからなるデータを処理する際、
あるストリームからのデータが到着しないとき、タイムアウトして結果を出す必要がある。

同じようにout-of-orderデータについてもウィンドウに応じてタイムアウトしないといけない。

### Rule 4: Generate Predictable Outcomes

結果がdeterministicであり、再現性があること。

計算そのものだけではなく、対故障性の観点でも重要。

### Rule 5:  Integrate Stored and Streaming Data

過去データに基づき、何らかのパターンなどを見つける処理はよくある。
そのためステート管理の仕組み（データストア）は重要。

例えば金融のトレーディングで、あるパターンを見つける、など。
他にも異常検知も。

過去データを使いながら、実時間のデータにキャッチアップするケースもあるだろう。

このようにヒストリカルデータとライブデータをシームレスにつなぐ機能は重要。

### Rule 6:  Guarantee Data Safety and Availability

HAは悩ましい課題。
故障が発生してフェールオーバするとして、バックアップハードウェアを
立ち上げて処理可能な状態にするような待ち時間は許容できない。

そこでタンデム構成を取ることは現実的にありえる。

### Rule 7: Partition and Scale Applications Automatically

ローレベルの実装を経ずに、分散処理できること。
またマルチスレッド処理可能なこと。

### Rule 8:  Process and Respond Instantaneously

数万メッセージ/secの量を処理する。
さらにレイテンシはマイクロ秒オーダから、ミリ秒オーダ。

そのためには極力コンポーネント間をまたぐ処理をしないこと。

## 3. SOFTWARE TECHNOLOGIES for STREAM PROCESSING

基本的なアーキテクチャは、DBMS、ルールベースエンジン、ストリーム処理エンジン。

DBMSはデータをストアしてから処理する。データを動かしつづけるわけではない。

またSPEはSQLスタイルでのストリームデータの処理を可能とする。

SPEとルールベースエンジンは、ブロックおよびタイムアウトを実現しやすい。
DBMSはそのあたりはアプリケーションに委ねられる。
仮にトリガを用いたとしても…。

いずれのアーキテクチャにおいても、予測可能な結果を得るためには、
deterministicな処理を実現しないといけない（例えばタイムスタンプの並びを利用、など）
SPEとルールベースエンジンはそれを実現しやすいが、DBMSのACID特性は
あくまでトラディショナルなデータベースのためのもであり、ストリームデータ処理のための
ものではない。

状態を保存するデータストアとしてDBMSを見たとき、サーバ・クライアントモデルのDBMSは
主にレイテンシの面で不十分である。
唯一受け入れられるとしたら、アプリケーション内に埋め込めるDBMSの場合である。
一方ルールベースエンジンはストリームデータを扱うのは得意だが、
大規模な状態管理と状態に対する柔軟なクエリが苦手である。

### 3.3 Tabular results

このあたりにまとめ表が載っている。
