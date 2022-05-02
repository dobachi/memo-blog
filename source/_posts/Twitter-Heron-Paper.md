---

title: Twitter Heronの論文
date: 2019-07-03 21:59:46
categories:
  - Knowledge Management
  - Stream Processing
  - Twitter Heron
tags:
  - Twitter Heron
  - Stream Processing
  - Twitter
  - Paper

---

# 参考

* [Twitter Heronの論文要旨]
* [Trident]
* [Apache incubation Heron]
* [Apache Heronのコミット状況]
* [Apache Heronのコントリビュータ]
* [Sanjeev Kulkarni]
* [objmagic]
* [Ning Wang]
* [slurm]
* [公式ドキュメント]
* [Storm vs. Heron]
* [Introduction to Apache Heron by Streamlio]
* [Streamlioのサポートサービス]
* [Streamlioのプロセッシングエンジンに関する説明]
* [Pulsar functions]

[Twitter Heronの論文要旨]: https://dl.acm.org/citation.cfm?id=2742788
[Trident]: https://github.com/nathanmarz/storm/wiki 
[Apache incubation Heron]: https://github.com/apache/incubator-heron
[Apache Heronのコミット状況]: https://github.com/apache/incubator-heron/graphs/commit-activity
[Apache Heronのコントリビュータ]: https://github.com/apache/incubator-heron/graphs/contributors
[Sanjeev Kulkarni]: https://twitter.com/sanjeevrk
[objmagic]: https://github.com/objmagic
[Ning Wang]: https://www.linkedin.com/in/ningwang/
[slurm]: https://slurm.schedmd.com/
[公式ドキュメント]: https://apache.github.io/incubator-heron/
[Storm vs. Heron]: https://qiita.com/takeuchikzm/items/5f21e9ec7ddf885c8e5e
[Introduction to Apache Heron by Streamlio]: https://www.slideshare.net/streamlio/introduction-to-heron
[Streamlioのサポートサービス]: https://streaml.io/support
[Streamlioのプロセッシングエンジンに関する説明]: https://streaml.io/product/technology/processing
[Pulsar functions]: https://streaml.io/blog/pulsar-functions

# 論文の要点メモ

昔のメモをコピペ。

なお、 [Storm vs. Heron] のブログに記載の通り、
本論文当時のStormは古く、現在のStormでは解消されている（可能性のある）課題が取り扱われていることに注意が必要。

## 1. Introduction

Twitterでのリアルタイム・ストリーミングのユースケースの例。

* RTAC（リアルタイム・アクティブユーザ・カウント）
  * 図1にRTACのトポロジーイメージが載っている
* リアルタイム・エンゲージメント（ツイートや広告）


大きな課題のひとつは、デバッガビリティ。性能劣化の原因を素早く探りたい。
論理単位と物理的なプロセスを結びつけてシンプルにしたかった。

クラスタ管理の仕組み（TwitterではAuroraを使用）と組み合わせたかった。

計算リソースの効率も上げたかった。

一方で既存のアプリを書き換えたくないので、Storm API、Summingbird APIに対応させたい。


## 2. Related Work

挙げられていたのは以下のような技術。

* Apache Samza
* MillWheel(2013)
* Photon(2013)
* DataTorrent
* Stormy(2012)
* S4
* Spark Streaming

またトラディショナルなデータベースに組み込まれたストリーム処理エンジンも挙げられていた。

* Microsoft StreamInsight
* IBM Inforsphere Streams
* Oracle continuous query

要件

* OSS
* 性能高い
* スケーラブル
* Storm APIとの互換性あり

## 3. Motivation for Heron

### 3.1 Storm Background

特筆なし。Stormの論理構造の説明があるだけ。

### 3.2 Storm Worker Architecture: Limitations 

Stormはプロセス内で複数のタスクを実行するし、それらのタスクは複数のトポロジーに属している。
これにより性能劣化などが発生しても、その原因を見極めるのが難しく、結果としてトポロジー「再起動」という
手段を取らざるを得なくなる。

ログが混ざって調査しづらい。

マシンリソースのリザーブが一律である点が辛い。
余分なリソースを確保してしまう。特に複雑なトポロジーを用いることになるハイレベルAPIで利用する場合。

大きなヒープを用いることもデバッグしづらさを助長する。

ワーカ内では、グローバルな送信スレッド、受信スレッド、コンピューティングスレッドがある。
その間で内外の通信を行う。これは無駄が多い。

### 3.3 Issues with the Storm Nimbus 

Stormのスケジューラは、ワーカにおいてリソース使用分割をきちんと実施しない。
Storm on YARNを導入しても十分ではなかった。

ZooKeeperがワーカ数の制約になる。

NimbusはSPOF。
Nimbusがとまると新しいトポロジーを投入できないし、走っているトポロジーを止められない。
エラーが起きても気づけないし、自動的にリカバーできない。

### 3.4 Lack of Backpressure 

Stormにはバックプレッシャ機能がなかった。

### 3.5 Efficiency

効率の悪さ（マシンリソースを使い切らない）が課題。
イメージで言えば…100コアのクラスタがあるとき、Utilization 90%以上のコアが30個で動いていほしいところ、Utilizaiton 30%のコアが90個になる、という具合。

## 4. Design Alternatives

Heronの他に選択肢がなかったのか、というと、なかった、ということが書かれている。
ポイントはStorm互換APIを持ち、Stormの欠点を克服するプロダクトがなかった、ということ。

## 5. Heron

### 5.1 Data Model and API 

データモデルとAPIはStormと同様。
トポロジーは論理プラン、実際に実行されるパーティション化されたスパウトやボルトが
物理プランに相当すると考えて良い。

### 5.2 Architecture overview 

ジェネラルなスケジューラであるAuroraを使用し、トポロジーをデプロイする。
Nimbusからの離脱。

以下のようなコンポーネントで成り立つ。

* トポロジマスタ（TM）（スタンバイTMを起動することも可能）
* ストリームマネージャ（SM）
* メトリクスマネージャ（MM）
* ヘロンインスタンス（HI）（要はスパウトとボルト）

コンテナは単独の物理ノードとして起動する。
なお、Twitterではcgroupsでコンテナを起動する。

メタデータはZooKeeperに保存する。

なお、HIはJavaで実装されている。

通信はProtocol Buffersで。

### 5.3 Topology Master

YARNでいうAMに近い。
ZooKeeperのエファメラルノードの機能を使い、複数のTMがマスタになるのを防ぎ、TMを探すのを助ける。

### 5.4 Stream Manager

HIは、そのローカルのSMを通じて通信する。
通信経路は `O(k^2)` である。このとき、HIの数 `n` は、
kよりもずっと大きいことが多いので、効率的に通信できるはずである。

補足：ひとつのマシンにひとつのSM、複数のコンテナ（つまりHI等）があるモデルを仮定。

バックプレッシャの方式には種類がある。

バックプレッシャについて。
複数のステージで構成されるケースにおいて、後段のステージの処理時間が長引いていると、
タプルを送るのが *つまって* バッファがあふれる可能性が生じる。
そこでそれを調整する機能が必要。

TCPバックプレッシャ。
HIの処理時間が長くなると、HIの受信バッファが埋まり始め、合わせて
SMの送信バッファも埋まり始める。
これによりSMは *つまり* 始めているのを検知し、それを上流に伝搬する。
この仕組みは実装は簡単だが、実際にはワークしない。
HI間の論理通信経路は、SM間の物理通信経路上で、
オーバーレイ構成されるためである。

スパウトバックプレッシャについて。
TCPバックプレッシャと組み合わせて用いられる。
SMがHIの処理遅延を検知すると、
スパウトのデータ読み込みを止める。
続いてスタートバックプレッシャのメッセージを他のSMに送る。これにより読み込みが抑制される。
処理遅延が解消されると、ストップバックプレッシャのメッセージを送る。
欠点は、過剰に読み込みを抑止すること、メッセージングのオーバヘッドがあること。利点は、トポロジによらず素早く対処可能なこと。

その他、ステージ・バイ・ステージバックプレッシャについて。
これはトポロジはステージの連続からなる。
バックプレッシャを伝搬させることで必要分だけ読み込み抑制する。

Heronでは、スパウトバックプレッシャ方式を用いた。

ソケットをアプリケーションレベルのバッファに対応させ、
ハイ・ウォータマークとロー・ウォータマークを定義。
ハイ・ウォータマークを超えるとバックプレッシャが発動し、
ロー・ウォータマークを下回るまでバックプレッシャが続く。

### 5.5 Heron Instance


デザインにはいくつかの選択肢がある。

#### 5.5.1 Single-threaded approach

HIはJVMであり、単独のタスクを実行する。
これによりデバッグしやすくなる。

しかし、シングルスレッドアプローチは「ユーザコードが様々な理由によりブロックする可能性がある」という欠点がある。
ブロックする理由は様々だが、例えば…

* スリープのシステムコールを実行
* ファイルやソケットI/Oのため読み書きのシステムコールを実行
* スレッド同期を実行

これらのブロックは特にメトリクスの取り扱いにおいて問題になった。
つまり、仮にブロックされてしまうともし問題が起きていたとしてもメトリクスの伝搬が遅くなることがあり、
ユーザは信用を置けなくなってしまうからだ。

#### 5.5.2 Two-threaded approach

ゲートウェイスレオッドとタスク実行スレッドの2種類で構成する。
ゲートウェイスレッドは、HIの通信管理を担う。
TCP接続の管理など。

タスク実行スレッドはユーザコードを実行する。
スパウトか、ボルトかによって実行されるメソッドが異なる。
スパウトであれば `nextTuple` を実行してデータをフェッチするし、
ボルトであれば `execute` メソッドを実行してデータを処理する。
処理されたデータはゲートウェイスレッドに渡され、ローカルのSMに渡される。
なお、その他にも送られたタプルの数などのメトリクスが取得される。

★補足：このデザインは汎用的なので、他のプロダクトにも利用できそう。

スレッド間はいくつかのキューで結ばれる。
data-in、data-out、metrics-outである。
重要なのは、data-inとdata-outは長さが決まっており、このキューがいっぱいになるとバックプレッシャ機能が有効になる仕組みになっていること。

問題は、NWがいっぱいなときにdata-outキューが溜まった状態になることだった。
これにより、生存オブジェクトがメモリ内に大量に残り、GCによる回収ができない。
このとき、もしdata-outキューからの送信よりも、先に受信が発動すると、新しいオブジェクトが生成されることになり、
GCを発動するが回収可能なオブジェクトが少ないため、さらなる性能劣化を引き起こす。

これを軽減するため、data-out、data-inキューの長さを状況に応じて増減することにした。

### 5.6 Metrics Manager

メトリクスマネージャは、コンテナごとに1個。

### 5.7 Startup Sequence and Failure Scenarios

トポロジがサブミットされてから実際に処理が開始されるまでの流れの説明。

* スケジューラがリソースをアロケート
* TMが起動し、ZooKeeperにエファメラルノードを登録
* SMがZooKeeperからTMを確認し、SMと接続する。ハートビートを送り始める。
* SMの接続が完了すると、TMはトポロジのコンポーネントをアサインする
* SMはTMから物理プランを取得し、SM同士がつながる
* HIが立ち上がり、ローカルSMを見つけ、物理プランをダウンロードし実行開始。
* 故障時の対応のためTMは物理プランをZooKeeperに保存する。

いくつか故障シナリオが想定されている。

* TMが故障した場合、ZooKeeper上の情報を使って復旧可能である。復旧後、SMは新しいTMを見つける。
* SMが故障した場合、復旧したSMは物理プランを取得する。他のSMも新しいSMの物理プランを取得する。
* HIが故障した場合、再起動してローカルSMにつなぎにいく。その後物理プランを取得し処理を再開する。

### 5.8 Architecture Features: Summary

まとめが記載されているのみ。

## 6. Heron in Production

プロダクションで利用するため、いくつかの周辺機能を有している。

### 6.1 Heron Tracker

ヘロントラッカーはZooKeeperを利用し、トポロジのローンチ、既存トポロジの停止、
物理プランの変更を追従する。
また同様にトポロジマスタを把握し、メトリクス等を取得する。

### 6.2 Heron UI

ヘロントラッカーAPIを利用し、UIを提供する。
論文上にはUIの例が載っている。
トポロジのDAG、コンテナ、コンポーネント、メトリクスを把握できる。

### 6.3 Heron Viz

メトリクスの可視化。トラッカーAPIを利用し、新しいトポロジがローンチされたことを検知し、可視化する。

ヘルスメトリクス、リソースメトリクス、コンポーネントメトリクス、ストリームマネージャメトリクス。

ヘルスメトリクスではラグや失敗などを表示する。

リソースメトリクスでは予約されたCPU、実際に使用されたCPU、同様にメモリに関する情報を扱う。またGCなども。

コンポーネントメトリクスはスパウトではエミットされたタプル数などのコンポーネントごとに固有のメトリクスを扱う。
エンドツーエンドのレイテンシも扱う。

ストリームマネージャメトリクスは、インスタンスに送受信されたタプル数やバックプレッシャ機能に関するメトリクスを扱う。

### 6.4 Heron@Twitter

TwitterではStormではなくHeronがデファクトスタンダードである。

ユースケースは多岐にわたるが、データ加工、フィルタリング、結合、コンテンツのアグリゲーションなどなど。
機械学習も含む。例えば、回帰、アソシエーション、クラスタリングなど。

3倍ほどのリソース使用効率を得られた。


## 7. Empirical Evaluation

本論文用に組まれた動作確認。
StormとHeronの比較。
Ackあり・なしの両方。

なお、計測はデータ処理が安定してから開始するようにした。
そのため、Stormでは0mq層 [^heron_version] でほとんどドロップが起きていないときに計測することを意味し、
Heronではバックプレッシャが発動しておらず転送キューが溜まっていない状態での計測を意味する。

Ackありのケースについて、タプルのドロップは、

* Storm：0mqでのドロップもしくはタイムアウト
* Heron：タイムアウト

を要因とするものを想定する。

[^heron_version]: 0mqの記述が読み取れることから、0.8系Stormを比較対象としたように見える。

### 7.3 Word Count Topology

スパウトで高々175k単語のランダムな単語群を生成する。
それをボルトに渡し、メモリマップに保持する。

これは単純な処理なので、オーバーヘッドを計測するのに適している。

結果は、スループットで10倍〜14倍、レイテンシで5〜15倍の改善が見られた。

Heronのエンドツーエンドでのレイテンシにおけるボトルネックは、
SMのバッファでバッチ化されることであり、これは概ね数十ms程度の影響がある。

CPUコアの使用量は、2〜3倍小さくなった。
（補足：無駄にリソース確保せずに、きちんと各コアを使い切っている、というのも影響しているようだ）

Ackが有効、無効で同様の傾向。

### 7.4 RTAC Topology

Ack有効の場合、Stormで6Mタプル/min出すのに360コア必要だった。レイテンシは70ms。
対してHeronでは、36コアでよく、レイテンシも24msだった。

Ack無効の場合も同様の傾向。必要なCPUコア数に関し、10倍（つまり1/10のコアで良い）の改善が得られた。

## 8. Conclusions and Future work

Exactly oneceセマンティクスは論文執筆時点では対応されていない。
論文中では、 [Trident] が引用されていた。

# 最近のHeronはどうか？のメモ

2019/7/8現在になりどうなったかを軽く確認。

[Apache incubation Heron] が公式レポジトリである。
[Apache Heronのコミット状況] を見る限り、2019/7/8現在も活発に活動されている。

[Apache Heronのコントリビュータ] を見る限り以下の様子。

* コアの開発者はApache Pulsarの人でもある [Sanjeev Kulkarni] や [objmagic]
* ただし最近は [Ning Wang] のように見える。彼はもともと2013年あたりまでGoogleでYouTubeに携わっていたようだ。

## READMEによる「Update」

2019/7/8時点のREADMEによると、Mesos in AWS、Mesos/Aurora in AWS、ローカル（ラップトップ）の上でネイティブ動作するようになった。
またApache REEFを用いてApache YARN上で動作するように試みている。
[slurm] にも対応しようとしているとのこと。

## 公式ドキュメントを覗いてみる

[公式ドキュメント] を確認し、最近の様子を探る。

* Python APIがある
* UIがかなり進化している
* スケジューラとしては、k8s、k8s with Helm、
* メトリクス監視の仕組みには、Prometheus、Graphite、Scribeが挙げられている

### Heron's Design Goals

2019/7/8現在、以下のようなゴールを掲げている。

* 1億件/minをさばける
* 小さなエンドツーエンド・レイテンシ
* スケールによらず予測可能な挙動。またトラフィックのスパイクやパイプラインの輻輳が生じても予測可能な挙動。
* Simple administration, including:
* シンプルな運用
  * 共有インフラにデプロイ可能
  * 強力なモニタリングの仕組み
  * 細やかに設定可能
* デバッグしやすい

# 商用サポートはあるのか？

2019/7/8現在、Heronの商用サポートがあるのか？ →なさそうに見える。

[Introduction to Apache Heron by Streamlio] の通り、StreamlioがよくHeronの説明をしているように見える。
またこのスライドではユースケースとして、

* Ads
* Monitoring
* Product Safety
* Real Time Trends
* Real Time Machine Learning
* Real Time Business Intelligence

あたりを挙げている。参考までに。
また顧客（？）としては、

* Twitter
* Google
* Stanford University
* Machine Zone
* Inidiana University
* Microsoft
* Industrial.io

を挙げている。

ただし、 [Streamlioのサポートサービス] を見る限り、Apache Pulsarを対象としているがApache Heronが対象に入っているようには見えない。
また [Streamlioのプロセッシングエンジンに関する説明] を見ると、Apache Heronに言及しているが、あくまでStreamlioがApache Heronの
開発に携わっていた経験がStreamlioのストリーム処理エンジンの開発に生かされている件について触れられているだけである。
現在は、 [Pulsar functions] が彼らのコアか。
