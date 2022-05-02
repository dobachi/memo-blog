---

title: >-
  Chi: a scalable and programmable control plane for distributed stream
  processing systems
date: 2019-08-14 15:55:23
categories:
  - Knowledge Management
  - Stream Processing
tags:
  - Stream Processing
  - Paper



---

# 参考

* [Chi a scalable and programmable control plane for distributed stream processing systems]
* [VLDBのダウンロードリンク]
* [Orleans]
* [Trill]
* [TrillのGitHub]

[Chi a scalable and programmable control plane for distributed stream processing systems]: https://dl.acm.org/citation.cfm?id=3242946
[VLDBのダウンロードリンク]: http://www.vldb.org/pvldb/vol11/p1303-mai.pdf
[Orleans]: https://dotnet.github.io/orleans/
[Trill]: https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/trill-vldb2015.pdf
[TrillのGitHub]: https://github.com/microsoft/Trill

# メモ

2018/6にVLDBに掲載された論文。Microsoftが中心となって執筆？

多数のパラメータがあり、調整可能性がある場合に、動的な設定を可能にするChiというControll Planeを提案。

昨今のストリーム処理エンジン（やアプリケーション？）は、様々なSLO（Service Level Objective）を目指し、
多数の調整用パラメータが存在する。
これをチューニングするのは玄人でも一筋縄ではない。

重要なのは、動的に設定できることに加え、常にモニタリングしフィードバックすること。

本論文では、非同期的にコントロールポリシーを適用するモデル（Control Plane）を提案。
ストリームデータを伝搬する機能を利用し、コントロールメッセージを伝搬する。
またコントロールメッセージを扱うためのリアクティブなプログラミングモデルを合わせて提案。これにより、ポリシーを実装するのにハイレベルAPIを利用すればよくなる。
グローバルな同期が不要であることが特徴。

過去の技術としては、Heron、Flink、Spark Streamingを例に挙げ、限定的な対応にとどまっている旨を指摘。

Chiは、 [Orleans] の上に構築されたFlare（★補足：Microsoft内部のシステムのようだ）という仕組み上に実装し、試した。
[Trill]も利用しているとのこと。

★補足：GitHub等に実装が公開されていないか軽く確認したが存在しないようだ。

## 2. MOTIVATION

メジャーなパブリッククラウド（★補足：ここではAzureのことを指しているのだと思われる）で生じるログを集めて分析したい。
サーバ台数は20万台、数十PB/日。
これはGoogleのログと同様の規模。

### ワークロードを予測しがたい

生じるログはバラエティに富んでいる。これはそれを生成するプロセス、コンポーネントがバラエティ豊かだからである。
例えば、何か障害が起きるとそのとたんにバーストトラフィックが発生する。
デバッグモードを有効にするとログ量が増える。

特徴として、ひとつの種類のストリームの量も、バラエティ豊かであることが挙げられる。
例えば、あるストリームについては1分の間に数千万イベントまで到達するケースもあった。（つまり、バーストトラフィック）

これはトラフィックが予測困難であることを示す。

### データの多様性

Skewが存在し、多様である。

### マルチテナントなコントロールポリシー

ログにはError、Infoなどのレベルがあり、要件に応じて多様である。
またそれぞれ異なるSLOを求められることがある。
例えばInfoレベルはExactly Onceだが、それ以外はベストエフォート、など。

これをひとつのストリーム処理システムで実現しようとする。

またControl Policyは、リソース使用の最適化に用いられることもある。
ある処理の中間データがほかの処理で使われるために保持されたり、
データレイアウトやストレージの使い方を最適化したり…など。

これらの個別の先行研究は存在するが、まとめて管理しようとすると、
Control Planeに柔軟性とスケーラビリティが必要になる。

## 3. BACKGROUND

ここでは、Naiad、StreamScope、Apache Flinkを例にとって説明。
いずれも、オペレータのDAG構造のモデル。

ひとつの例として、
LINQスタイルのクエリでWordCountを表現。

![LINQ風の表現とオペレータのDAG表現の例](/memo-blog/images/2dP06tOT2MlXbqGp-38F4F.png)

<!-- ![計算モデル](/memo-blog/images/2dP06tOT2MlXbqGp-64DDD.png) -->

計算モデルの前提は以下の通り。

DAGを$\displaystyle G( V,\ E)$で表す。

$\displaystyle E$はEdgeのセット、$\displaystyle V$がOperatorのセット。

$\displaystyle u\ \rightharpoonup v$はOperator $\displaystyle u$から$\displaystyle v$への有向Edgeを表す。

$\displaystyle \{\cdot \rightharpoonup v\}$が$\displaystyle v$への入力Edgeを表す。

$\displaystyle \{v\rightharpoonup \cdot \}$が$\displaystyle v$からの出力Edgeを表す。

Operator $\displaystyle v\ \in V$はトリプル$\displaystyle ( s_{v} \ ,\ f_{v} \ ,\ p_{v})$で表す。
この時、$\displaystyle s_{v}$は$\displaystyle v$のステート、$\displaystyle f_{v}$は$\displaystyle v$で実行される関数、$\displaystyle p_{v}$はステートに含まれないプロパティを表す。

$\displaystyle f_{v}$の例としては、
\begin{equation*}
f:\ s_{v} \ ,\ m_{e_{i} \in \{\cdot \ \rightharpoonup \ v\}} \rightharpoonup s'_{v} ,\ m'_{e_{i} \in \{v\ \rightharpoonup \ \cdot \}}
\end{equation*}
が挙げられていた。ここで$\displaystyle m$はメッセージを表す。

つまり、$\displaystyle m_{e_{i} \in \{\cdot \ \rightharpoonup \ v\}}$は、入力Edge $\displaystyle e_{i}$から入ってくるメッセージを表す。
また入力を受け取った時点でステート$\displaystyle s_{v}$だったものを、出力時点で$\displaystyle s'_{v}$に変える関数を表す。
また、$\displaystyle \ m'_{e_{i} \in \{v\ \rightharpoonup \ \cdot \}}$は出力メッセージを表す。

## 4. DESIGN

データ処理と同様のAPIを設け、データ処理のパイプライン（data-plane）を使う。
グローバルな同期を必要とせず、非同期的なControl Operationを可能にする。

### 4.1 Overview

前提は以下の通り。

* Operator間のチャンネルはExactly Onceであること
* メッセージはFIFOで処理されること
* 一度に処理されるメッセージは1個ずつ
* 基盤となるSPEはOperatorに関する基本的なオペレーション（起動、停止、Kill）に対応すること

Control Loopを通じて、Control Messageが伝搬される。
Control Loopの流れは以下の通り。

* Phase 1:
  * Controllerにより意思決定され、ユニークなIDが生成される
  * Control Operationはシリアライズされる
* Phase 2:
  * Source OperatorにOperationが渡される
  * データフローに沿ってControl Messageが伝搬される
  * 途中で情報が付与されることもある
  * 各OperatorはControl Messageに沿って反応する
* Phase 3:
  * SinkからControllerにフィードバックされる

[LINQ風の表現とオペレータのDAG表現の例] のDAG表現を用いた例でいえば、
もともと Reducer $\{R_1, R_2\}$ で処理していたのを $\{R_1, R_2, R_3\}$ で処理するように変更する例が載っている。
Control Messageが $\{R_1, R_2\}$ に届くと、ルーティング情報を更新しつつ、ステート情報をCheckpointする。
ステート情報は再分配され、 $R_3$ にも分配される。
 $R_3$ は、Control Messageを受け取ると入力チャンネルをブロックし、 $\{R_1, R_2\}$ からのステートがそろうのを待つ。
ステートがそろったら、マージし、新しい関数を動かし始める。

ControllerがすべてのControl Messageを受け取ったら、スケールアウトは完了である。

### 4.2 Control Mechanism

#### 4.2.1 Graph Transitions through Meta Topology

★この辺を読んでいる

＜WIP＞

<!-- vim: set tw=0 ts=4 sw=4: -->
