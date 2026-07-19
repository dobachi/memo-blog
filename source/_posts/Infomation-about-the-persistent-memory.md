---
title: 不揮発性メモリに関連する情報源調査
date: 2018-10-14 23:07:48
categories:
  - Research
  - NVM
tags:
  - NVM
  - Paper

---

# まとまった情報が得られる情報源

* http://pmem.io/
  * 引用: This site is dedicated to persistent memory programming. 
* https://docs.pmem.io/
  * 引用: Background information, getting started guide, etc
* https://www.snia.org/
  * 引用: The SNIA is a non-profit global organization dedicated to developing standards and education programs to advance storage and information technology.
* https://www.imcsummit.org/
  * 引用: The only industry-wide events, the In-Memory Computing Summits focus on IMC-related technologies and solutions. 
* https://www.usenix.org/
  * 引用: Since 1975, USENIX, the Advanced Computing Systems Association, has brought together the community of engineers, system administrators, scientists, and technicians working on the cutting edge of the computing world. 

# 日本国内ニュースの例

* https://pc.watch.impress.co.jp/docs/news/1122322.html
  * タイトル: Intel、DRAMを置き換える3D XPoint NVDIMMを年内投入
* https://pc.watch.impress.co.jp/docs/news/1137634.html
  * タイトル: Intel、DRAMを超える高コスパメモリ「Optane DC Persistent Memory」を出荷。Googleが採用
* https://tech.nikkeibp.co.jp/atcl/nxt/column/18/00001/00492/
  * タイトル: Persistent Memoryの能力引き出す、MSやSAPがインテルに協力
* https://pc.watch.impress.co.jp/docs/news/1151589.html
  * タイトル: Micron、容量32GBのサーバー向けNVDIMM
* http://jbpress.ismedia.jp/articles/-/55099
  * タイトル: 東芝メモリに期待！ NAND高密度化のイノベーション
* https://pc.watch.impress.co.jp/docs/column/semicon/1160009.html
  * タイトル: 最先端マイコン/SoC向けで復活する相変化メモリ
* http://techtarget.itmedia.co.jp/tt/news/1812/11/news05.html
  * タイトル: 東芝メモリ、YMTC、SK Hynixが語る、NANDフラッシュメモリの最新テクノロジ
* https://pc.watch.impress.co.jp/docs/news/event/1157164.html
  * タイトル: 3次元クロスポイント構造で128Gbitの大容量不揮発性メモリをSK Hynixが開発

# 着目したカンファレンス、ペーパー

いくつかの項目については、ポイントとキーワードを記載する。

## USENIX

[Google schalarによる検索](https://scholar.google.co.jp/scholar?hl=ja&as_sdt=0%2C5&as_ylo=2018&as_vis=1&q=usenix+non+volatile&btnG=) 等を利用して確認したいくつかの記事からピックアップする

* [Intel Andy Rudoffによるプログラミングモデルへの影響考察](https://www.usenix.org/publications/login/summer2017/rudoff)
  * 本文書ではDIMMなどシステムメモリバスに接続する不揮発性メモリを対象とする
    * なお、アクセスレイテンシがナノ秒オーダであることを前提とする
  * p.2にメモリアクセスのモデル図
  * CPUキャッシュを永続化領域に含むこともバッテリを積めば可能だが、それはいったんベンダの対応に任せる
  * （カーネルを経ずに）ユーザスペースでのフラッシュにより、永続化を行うことを「Optimized Flush」という。
    ただしOptimized Flushは安全な時にのみ使われるべき
    * LinuxはDevice-DAXを提供。ファイルシステムを経由せずにアプリケーションが直接
      不揮発性メモリを開ける
    * libpmemがいつOptimized Flushを使えるかのAPIを提供している ★要確認
  * いくつかの課題
    * アトミックな書き込み→読み出しについて（p.38）
      * インテルの場合8バイトまでならアトミックに扱える
      * 8バイトを超えるものはソフトウェアで担保必要
    * PM-Aware File Systemを用いる前提のため、スペースの管理が課題になる（p.38）
    * さらにロケーションに対して非依存であることもチャレンジ要素の一つ。
      解決方法の見込みはいくつか存在（p.38）
  * 上記「いくつかの課題」の解決をもくろむライブラリ：NVML by Intel。
    * libpmem: Basic Persistence Support
    * libpmemobj: General-Purpose Allocations and Transactions
    * libpmemblk and libpmemlog: Support for Specific Use Cases
  * p.39にはlibpmemobj使用に関する簡単なC++の実装例

* [NoveLSM](https://www.usenix.org/conference/atc18/presentation/kannan)
  * LSM(Log-structured Merge Tree)-based KVSにおける不揮発性メモリの活用
  * 以下のオーバヘッドの改善を試みた
    * シリアライズ、デシリアライズ
    * コンパクション
    * ロギング
    * 並列読み出しの欠如
  * まずはLevelDBを改造して取り組んだ
  * （補足）ユースケースに関する議論はない

* [Caching or Not: Rethinking Virtual File System for Non-Volatile Main Memory](https://www.usenix.org/system/files/conference/hotstorage18/hotstorage18-paper-wang.pdf)
* [A persistent lock-free queue for non-volatile memory](https://dl.acm.org/citation.cfm?id=3178490)
* [LAWN: Boosting the performance of NVMM File System through Reducing Write Amplification](https://ieeexplore.ieee.org/abstract/document/8465891)
* [Persistent Octrees for Parallel Mesh Refinement Through Non-Volatile Byte-Addressable Memory](https://ieeexplore.ieee.org/abstract/document/8451966/)
* [Memory and Storage System Design with Novolatile Memory Technologies](https://www.jstage.jst.go.jp/article/ipsjtsldm/8/0/8_2/_pdf)
  * 概要：2015年にリリースされた招待論文であり、その当時の革新的なメモリとストレージのデザインを紹介するもの
    * 古い論文ではあるが、複数種類の不揮発性メモリに関する調査を実施したものであり、参考にはなる。 ★本記述は削除推奨
    * 本論文で取り扱う不揮発性メモリの種類：STT-MRAM、PCM、ReRAM
    * 不揮発性メモリの注意点は下記の通り
      * 耐久性、性能特性
    * 期待される役割は下記の通り
      * プロセッサキャッシュ、メインメモリ、ストレージ
      * さらに不揮発性メモリならではの使い方（MPPのチェックポイント置き場、など）も考えられる
  * SRAMとDRAMのスケーラビリティの限界（サイズアップ困難、消費電力（漏れ電力？）増大）に際したNVMのメリットを説明あり
  * 各アプローチが以下の各課題をどう解こうとしているかの解説。キーワードは以下の通り
    * スケーラビリティと効率
    * NVMの効果を最大化するためのリ・デザイン
  * STT-MRAM、PCM、ReRAMの特徴の紹介
  * 2.4節には各不揮発性メモリの比較
    * 不揮発性メモリの利点（従来のメモリと比べて…）p.4
      * PCMはスケールする
      * STT-MRAM、PCM、ReRAMは密度を高められやすい
      * リフレッシュ動作不要のため漏れ電力の面で有利。待機電力も低い。
    * 欠点 p.4
      * 3種類ともレイテンシが大きい。また書き込みの消費電力が大きい。（旧来のメモリと比べて）
      * PCM、ReRAMは耐久性が低い
  * 3章には製品の傾向が記載されている。
  * いくつかのデザインパターン ★要相談：という表現でよいか？
  * on-chipとoff-chip
    * on-chip: CMOSと不揮発性メモリを異なるダイに載せ、ダイをつなげられる
    * off-chip: いわゆるDIMMとして
  * インダストリではMicron、AMD、SK Hynixあたりが主に開発を手掛けていたことが言及されている
  * プロセッサキャッシュとして不揮発性メモリを用いるときの解説
    * SRAMはプロセッサキャッシュとして取り扱われる
      * STT-MRAMはキャッシュに適していると考えられる不揮発性メモリ。L2、L3キャッシュそれぞれに
        用いてみる研究が行われ、一定の成果（性能、消費電力（漏れ電力？））が出ている、と考察
      * SRAMよりも消費電力（漏れ電力？）小さく、容量を大きくできる、というところがポイントである
    * 不揮発性メモリの高いレイテンシを補うため、SRAMとのハイブリッド構成も研究されている。
      * 書き込み側に低レイテンシなSRAM、読み出し側に低消費電力（漏れ電力）な不揮発性メモリ
      * 研究においては10-16%程度の性能改善（対SRAMのみ構成）が見られたと言及
    * CPUのプロセッサコアが多い場合、プロセッサコアとオフチップメモリ間のバンド幅が
      ボトルネックになりがちである。これに対し、ハイブリッドアーキテクチャを用い、
      バンド幅の使い方を最適化する研究がある
      * 最大58%の性能改善があったと言及
    * PCMやReRAMは耐久性が低い。このためキャッシュに用いづらい。書き込み頻度を
      抑える研究がある
  * メインメモリとして不揮発性メモリを用いるときの解説
    * メインメモリとして不揮発性メモリを用いる場合、期待するのはサイズの大きさと漏れ電力の小ささ。
      *　ただ、PCMをそのまま使うと旧来のDRAMと比べて1.6倍遅く、2.2倍消費電力が大きい（書き込みの消費電力が大きな要因）
      * そこでいくつかの工夫を施す研究が存在している
        * 複数のバッファに分け、必要な部分だけ更新する手法
        * DRAMと組み合わせたPCM
          * 3倍は早くなった、との言及
        * プロセッサとメインメモリを同じチップに3Dスタックする手法
          * この手法は旧来のDRAMには難しい。電力と温度の関係で。
          * 旧来のDRAMと比べ、65%しか電力消費しないことを示した
    * そのほか、PCM、ReRAMの耐久性の低さに対する対策もいくつか研究されている
  * ストレージとして不揮発性メモリを用いる観点の議論
    * PCMの密度はディスクに匹敵するほど高くなる、と予測する研究もある。
    * NANDフラッシュ型のSSDの「ログリージョン」に不揮発性メモリを用いるというアイデアもある。
  * 不揮発性メモリ特有のデザイン
    * MPPのチェックポイント先としての利用
      * チェックポイントには25%程度のフットプリントになるのだが、これをPCMにすることにより、
        4%に抑えることができた、というもの
    * 同様にチェックポイントを置く場所として活用するが、仮想メモリとしてアプリケーションに
      見せる、という方式を取った研究もある。NVMをRAMディスクとして使う方式と比べ、
      チェックポイント時間を15%減らせた、という結果が得られた
    * GPGPUにおいて消費電力の面で効率的なメモリヒエラルキーを実現できる
      * ある研究によると、STT-MRAMを用いた場合、4倍の密度を実現しながら、
        3.5倍の消費電力（？）の低減に寄与した
  * Persistent Memoryとして不揮発性メモリを用いる
    * プロセッサの揮発性キャッシュと組みあわせたとき、Persistent Memory Systemを
      実現するのは実は簡単ではない
      * ライトバックキャッシュやメモリコントローラによるリクエストのリオーダリングが生じるため。
      * 例えばリンクドリストにノードを追加するとき、先にノードのポインタを不揮発性メモリに書き、
        その直後にクラッシュした場合、キャッシュ内にのみ存在したノードの値が失われる。
	このため復旧が困難になる
      * ここではPersistent Memory Systemが満たすべき特性について記載。
        * Durability、Atomicity、Consistency
    * 旧来からあるファイルシステムやDBMSを改造
      * WAL、Copy-on-write（COW）
      * B-treeにCOWの仕組みを足した研究もある
      * ただWALとCOWはオーバヘッドがある。
        そこでプロセッサのキャッシュとメインメモリのヒエラルキーを使い、
        Atomicityを実現した研究もある。 ★要確認
    * ポイントはプロセッサで生じたリクエスト通りの並びで処理すること
      * ただメモリコントローラやキャッシュの仕組みが性能改善のために
        リオーダリングする可能性があること
      * そこで多くのPersistent Memory Systemは、キャッシュをライトスルーすることで、
        順序を保証しようとする。つまり、プロセッサキャッシュをバイパスする。
	また合わせてフラッシュ、メモリフェンス、msyncオペレーションを用いる
      * ただ、プロセッサキャッシュのバイパスは、データがメインメモリに到達するのを
        待つしかなくなる
	またフラッシュやメモリフェンスはバーストを引き起こすし、キャッシュのフラッシュは
	他のアプリケーションのワーキングメモリをはじき出す可能性がある
      * BPFSというファイルシステムは、エポックバリアを設けた。ただしデータ損失の可能性がある
      * p.8にいくつかの手法の比較表が載っている。
        * BPFS、Mnemosyne、…
	* In-place、Logging、…

## Storage Developer Conference

* [Preparing Applications for Persistent Memory](https://www.snia.org/sites/default/files/SDC15_presentations/persistant_mem/DougVoigt_Preparing_Applications_for_PM.pdf)

## Persistent Memory Summit 2019

https://www.snia.org/pm-summit

2019/1/24 @ Santa Clara, CA

* [Keynote: Realizing the Next Generation of Exabyte-scale Persistent Memory Centric Architectures and Memory Fabrics](https://www.snia.org/sites/default/files/PM-Summit/2018/presentations/02_PM_Summit_WDC_keynote_Final_Post.pdf)

  * Zvonimir Bandic, Senior Director, Research and Development Engineering, Western Digital Corporation
  * Big Data and Fast Data。アーキテクチャのダイバーシティ。（フォームファクタの差）
  * メモリファブリックのもたらす低レイテンシ（1.6 - 1.8 us）
  * メモリセントリックアーキテクチャ。つまり巨大なメモリに対し、多数の計算デバイスを接続するモデル p. 11
  * Persistent memoryのスケールアウト
  * さらなる低レイテンシ（500ns）のためにはプロトコルのイノベーションが必要

* [Persistent Memory Programming: The Current State and Future Direction
Andy Rudoff, Member, SNIA NVM Programming Technical Work Group and Persistent Memory SW Architect, Intel Corporation](https://www.snia.org/sites/default/files/PM-Summit/2018/presentations/03_PMSummit_18_Rudoff_Final_Post.pdf)

  * NVDIMMドライバを活用したプログラミングモデル
  * 標準ファイルシステムAPIを経由する場合、必ずファイルを開かないとならない。
  * DAXであればPMアウェアなファイルシステムAPIをスキップできる
  * https://pmem.io/pmdk/
  * https://github.com/pmem/pcj

    * PMDKのlibpmemobjを内部的に用いたJavaバインド

* [Persistent Memory over Fabrics (PMoF)](https://www.snia.org/sites/default/files/PM-Summit/2018/presentations/05_PM_Summit_Grun_PM_%20Final_Post_CORRECTED.pdf)

  * ユースケース

    * HA用のレプリケーション

  * リモートのPersistent Memoryを扱えるようになるとして、何を考えないといけないか

    * Streamline  the API ... メモリオペレーションのように見せないといけない
    * 非同期的な管理

      * 永続化を明示的に管理する方法が必要
      * 既存のファブリックのプロトコルに対し、同期のタイミングを作りこむ必要がある

    * FAST DATA


* [Linux Persistent Memory Support - "Ask Me Anything"](https://www.snia.org/sites/default/files/PM-Summit/2018/presentations/08_PM_Summit_Brunner_Final_Post.pdf)

* [Hype to Reality, a Panel Discussion with Leaders of Real World Persistent Memory Applications](https://www.snia.org/sites/default/files/PM-Summit/2018/presentations/09_PM_Summit_Vargas_Final_Post.pdf)

* [Quick and Painless System Performance Acceleration Using NVDIMMs](https://www.snia.org/sites/default/files/PM-Summit/2018/presentations/10_PM_Summit_Brett_Williams_NVDIMM_final_post.pdf)
  * p.2に2018時点でのPersistent Memoryの対応状況が示されている
  * まだまだ現実のワークロードで受け入れられる状態ではない
  * どうやったら適用が拡大するか？
    * ブロックエミュレーション
    * 複数層のアーキテクチャ
  * p.7にブロックIOのエミュレーションのイメージ図
    * Block Translation層が入っている
  * まとめ
    * ブロックエミュレーションとTieringによるNVDIMM利用は、アプリケーション変更せずに
      性能面での恩恵を受けられる
    * より多くの適用につながるだろう、という考察

* [Future Media](https://www.snia.org/sites/default/files/PM-Summit/2018/presentations/12_A_PMSummit_18_Gervasi_Final_Post.pdf)、[Future Media2](https://www.snia.org/sites/default/files/PM-Summit/2018/presentations/12_B_PMSummit_18_Walker_Final_Post.pdf)
  * カーボンナノチューブによるメモリ: NRAM
  * p.3に特長が書かれている
    * 読み書きはDRAM並み、スケーラブル、耐久性高い、漏れ電力も小さい（もしくはない）
    * 3Dスタックも可能との考察
  * p.6にNVDIMM-Nとの比較

* [Analysts Weigh In on Persistent Memory](https://www.snia.org/sites/default/files/PM-Summit/2018/presentations/14_PM_Summit_18_Analysts_Session_Oros_Final_Post_UPDATED_R2.pdf)
  * いくつかのセッションで構成されていた。
  * How Persistent Memory Will Succeed
    * 3D NANDからの教訓 p.8
    * 結局DRAMと勝負になるくらい安くないと…
    * 「永続性」を使うためにはソフトウェアサポートが必要
      * そこでSNIAの出番
    * ただ、コストと性能の観点から用いる、というのが一般的
    * PCM ... 3D XPoint（Intel、Micron）
    * MRAM ... TSMC、サムスン、東京エレクトロン
    * FRAM
    * ReRAM ... TSMC、UMC
    * p.14に各種の比較が載っている
      * 補足：PCM（3D XPoint）の実際のレイテンシはもっと大きいのでは？と思ったが… ★要確認
  * Analyst Perspective - IT Client
    * 容量単価だけを気にするのであれば、テープを使うべき。
  * Persistent Memory Dinamics
    * 2008年あたりにStorage Class MemoryがHDDを置き換えると話題に上ったものの、
      NAND型フラッシュSSDが流行り、SCMに対する市場の需要はいったん遅れた
    * 現在、バイトアドレッサビリティがSCMに足された
    * NVRAM
    * 2020年にはモバイルデバイスのDRAM、NANDを置き換えていくのではないか
    * トレンド
      * コグニティブコンピューティング
        * 大きなPersistent Memory
	* AIアルゴリズムはその計算時間を減らせるだろう
      * Processor In Memory

## In-Memory Computing Summit

https://www.imcsummit.org/

### IMC Summit Europe 2018

* [IN-MEMORY COMPUTING - UNLOCKING THE DIGITAL FUTURE](https://www.NRAMimcsummit.org/2018/eu/session/memory-computing-unlocking-digital-future)
  * まとめ
    * ユースケースの具体例は載っていない
    * IMC（インメモリコンピューティング）の技術が2019年 - 2022年にかけて段階的に世の中に
      受け入れられていく流れを説明
  * p.10にハーバードビジネススクールによるDigital Laggards、Digital LeadersのGross Marginなどに関する分析結果。
  * p.13にいわゆるHTAPにおけるビジネス分析、ビジネストランザクション、自動化された意思決定の関係
  * p.14に旧来の方式（Hadoop + RDBMS + ETL + ML/DL Engine + App）とIMC方式（IMC Platform + App）の比較
    * とてもシンプルになる、という考察
  * p.15：2021年にはインメモリDBMS、インメモリグリッドゲイン、ストリーム（分析）処理プラットフォーム、
    他のIMC技術はインメモリコンピューティングに収れんされていく。ガートナーによる意見。
    * 2019年 - 2022年にかけてIMCに関する技術が世の中に受け入れられていく予想が記載されている。
* [Embracing the service consumption shift in banking](https://www.imcsummit.org/2018/eu/session/embracing-service-consumption-shift-banking)
  * まとめ：INGのIMC（インメモリコンピューティング）についての概要
  * p.10 - 12に16Mトランザクション/日をさばくアーキテクチャ（SEPA DD）の説明
    * 一度Kafkaに入れて、IMC基盤に入れる
  * p.16にGridGain as a Serviceの説明。GridGainおよびAppをコンテナに入れてデプロイする。

* [Memory-Centric Architecture - a New Approach to Distributed Systems](https://www.imcsummit.org/2018/eu/session/memory-centric-architecture-new-approach-distributed-systems)
  * IMCの進化の流れを説明
    * Distributed Cache
    * In-Memory Data Grids
    * In-Memory Databases
    * Distributed Databases
    * Memory-Centric Databases
  * 最初のローカルキャッシング
  * Distributed Cache
    * シェアードナッシング。シンプルなクライアント。
    * Memcached、Redis、AWS ElastiCache
    * p.7に欠点のリスト
  * In-Memory Data Grids
    * HazelCast、GigaSpaces、Apache Ignite
    * p.11に欠点のリスト
  * In-Memory Databases
    * In-Memory Data Grids for SQLとも考えられるようだ
    * VoltDB、SAP HANA
    * p.15に欠点のリスト
  * Distributed NoSQL Databases
    * SQLではない。トランザクションに対応していない。IMCではない。
  * Distributed SQL Databases
    * IMCではない。キーバリューAPIの欠如。イベントノーティフィケーションの欠如。
  * GridGain Memory-Centric Architecture
    * Memory Centric Storageがそれより下の永続化の層を隠蔽しているように見える
      * p.21に特長をまとめた図がある
    * Ignite Native Persistenceの利用（そのほかの永続化の仕組みも利用可能なようだ）
  * HTAP

### IMC Summit San Francisco 2018

https://www.imcsummit.org/2018/us/

# ユースケース

## 書籍

* [Green Computing with Emerging Memory: Low-Power Computation for Social Innovation](https://books.google.co.jp/books?id=oUPPea6_rZYC&pg=PA198&lpg=PA198&dq=usecase+non+volatile+memory&source=bl&ots=d3FWcpgx9d&sig=vhviv7n0WePl1oEmdUXlliM0NTs&hl=ja&sa=X&ved=2ahUKEwi-8Kaek4beAhUIE4gKHUpJBaIQ6AEwB3oECAcQAQ#v=onepage&q=usecase%20non%20volatile%20memory&f=false)

## Storage Developer Conference

* [The Impact of the NVM Programming Model](http://dev.snia.org/sites/default/orig/SDC2013/presentations/GeneralSession/AndyRudoff_Impact_NVM.pdf)
  * p.20、21あたり

## In-Memory Computing Summit 2016

* [NVDIMM - CHANGES ARE HERE SO WHAT'S NEXT?](https://www.snia.org/sites/default/files/SSSI/NVDIMM%20-%20Changes%20are%20Here%20So%20What's%20Next%20-%20final.pdf) ★
  * 2016年時点での概観
    * p.6に特性による種類が掲載されている
    * p.8にエコシステムの考え方
    * p.15にユースケース

# 他者の考察

## Oracle

* [クラウド時代におけるデータベースの歩みと急速な技術進化の方向性 Transforming Data Management](http://otndnld.oracle.co.jp/ondemand/dbconnect/DBConnect2017_Session1.pdf)

## 個人？

* [Persistent memory (Benoit Hudzia, Head of Operations - Non Exec Director - Senior Architect)](https://www.slideshare.net/blopeur/persistent-memory)
  * [Usecaseの画像](https://image.slidesharecdn.com/persistentmemory-160606071021/95/persistent-memory-29-638.jpg?cb=1465197097)

## ミドルウェア関連

## OS関連
