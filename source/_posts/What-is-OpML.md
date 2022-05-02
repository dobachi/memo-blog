---

title: What is OpML
date: 2019-09-02 22:36:25
categories:
  - Knowledge Management
  - Machine Learning
  - OpML
tags:
  - Machine Learning
  - OpML

---

# 参考

* [USENIX OpML'19]
* [The first conference of Operational Machine Learning OpML '19]

[USENIX OpML'19]: https://www.usenix.org/conference/opml19
[The first conference of Operational Machine Learning OpML '19]: https://blog.chezo.uno/the-first-conference-of-operational-machine-learning-opml-19-308baad36108

# メモ

## OpMLについて

USENIX OpML'19のテックジャイアントたちが話題にしている主要なトピックからスコープを推測。

* ヘテロジーニアスアーキテクチャの活用（エッジ・クラウドパラダイム）
* モデルサービング、レイテンシの改善
* 機械学習パイプライン
* 機械学習による運用改善（AIOps）
* 機械学習のデバッガビリティ改善


## USENIX OpML'19 の定義

[USENIX OpML'19] によると、
OpML = Operational Machine Learning の定義。

カンファレンスの定義は以下の通り。

> The 2019 USENIX Conference on Operational Machine Learning (OpML '19) provides a forum for both researchers and industry practitioners to develop and bring impactful research advances and cutting edge solutions to the pervasive challenges of ML production lifecycle management. ML production lifecycle is a necessity for wide-scale adoption and deployment of machine learning and deep learning across industries and for businesses to benefit from the core ML algorithms and research advances.

上記では、機械学習の生産ライフサイクルの管理は、機械学習や深層学習が産業により広く用いられるため、またコアとなる機械学習アルゴリズムや研究からビジネス上のメリットを享受するために必要としている。

### コミッティー

カンファレンスサイトの情報から集計すると、以下のような割合だった。

<!-- ![コミッティの集計](/memo-blog/images/td481cioc2ef3Mil-B33F5.png) -->

<iframe width='350' height='570' frameborder='0' src="https://docs.google.com/spreadsheets/d/e/2PACX-1vSNOVzsBoLT9iKX3giqeogjxRac78DEfA6x3Oe3fM4G4Cdx6m31JHO0F22YhUouzru0aAdI065DE22E/pubhtml?gid=359850931&amp;single=true&amp;widget=true&amp;headers=false"></iframe>

多様な企業、組織からコミッティを集めているが、
Googleなど一部企業からのコミッティが多い。

### セッション

カンファレンスのセッションカテゴリは以下の通り。

<!-- ![セッションカテゴリ一覧](/memo-blog/images/td481cioc2ef3Mil-59F21.png) -->

<iframe width='500' height='270' frameborder='0' src="https://docs.google.com/spreadsheets/d/e/2PACX-1vTRSGX_UWHc49DsoIxq9CdC1zsjkjCQkO-l-aL43l0sfUGfWWYtbTl9KVBHmJqDiODv_SwUP7h9OExa/pubhtml?gid=263916540&amp;single=true&amp;widget=true&amp;headers=false"></iframe>

カテゴリとしては、今回は実経験に基づく知見を披露するセッションが件数多めだった。

一方で、同じカテゴリでも話している内容がかなり異なる印象は否めない。
もう数段階だけサブ・カテゴライズできるようにも見え、まだトピックが体系化されていないことを伺わせた。


<!-- ![実経験に基づく知見のセッション一覧](/memo-blog/images/td481cioc2ef3Mil-13C5B.png) -->

<iframe width='700' height='550' frameborder='0' src="https://docs.google.com/spreadsheets/d/e/2PACX-1vTRSGX_UWHc49DsoIxq9CdC1zsjkjCQkO-l-aL43l0sfUGfWWYtbTl9KVBHmJqDiODv_SwUP7h9OExa/pubhtml?gid=0&amp;single=true&amp;widget=true&amp;headers=false"></iframe>

Google、LinkedIn、Microsoft等のテックジャイアントの主要なセッションを見ていて気になったキーワードを並べる。

* ヘテロジーニアスアーキテクチャの活用（エッジ・クラウドパラダイム）
* モデルサービング、レイテンシの改善
* 機械学習パイプライン
* 機械学習による運用改善（AIOps）
* 機械学習のデバッガビリティ改善

その他アルゴリズムの提案も存在。

小さめの企業では、ML as a Serviceを目指した取り組みがいくつか見られた。

### セッションをピックアップして紹介

実経験にもとづく知見のセッションを一部メモ。

#### Opportunities and Challenges Of Machine Learning Accelerators In Production

* タイトル: Opportunities and Challenges Of Machine Learning Accelerators In Production
* キーワード: TPU, Google, ヘテロジーニアスアーキテクチャ, 性能
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_ananthanarayanan.pdf

CPUでは近年の深層学習ワークロードの計算アルゴリズム、量において不十分（ボトルネックになりがち）だが、
TPU等のアーキテクチャにより改善。

しかしTPUが入ってくると「ヘテロジーニアスなアーキテクチャ」になる。
これをうまく使うための工夫が必要。

加えて近年のTPUについて紹介。

#### Accelerating Large Scale Deep Learning Inference through DeepCPU at Microsoft

* タイトル:  Accelerating Large Scale Deep Learning Inference through DeepCPU at Microsoft
* キーワード: モデルサービング, レイテンシの改善, Microsoft, 性能
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_zhang-minjia.pdf

Microsoft。
CPU上でRNNを高速にサーブするためのライブラリ: DeepCPU
目標としていたレイテンシを実現するためのもの。
例えばTensorFlow Servingで105msかかっていた「質問に答える」という機能に関し、
目標を超えるレイテンシ4.1msを実現した。
スループットも向上。


#### A Distributed Machine Learning For Giant Hogweed Eradication

* タイトル: A Distributed Machine Learning For Giant Hogweed Eradication
* キーワード: Big Data基盤, モデルサービング, ドローン, 事例, NTTデータ
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19-nttd.pdf

NTTデータ。
デンマークにおいて、ドローンで撮影した画像を利用し、危険外来種を見つける。
Big Data基盤と機械学習基盤の連係に関する考察。

#### AIOps: Challenges and Experiences in Azure

* タイトル: AIOps: Challenges and Experiences in Azure
* キーワード: Microsoft, 運用, 運用改善, AIOps
* スライド: 非公開

スライド非公開のため、概要から以下の内容を推測。
Microsoft。
Azureにて、AIOps（AIによるオペレーション？）を実現したユースケースの紹介。
課題と解決方法を例示。

#### Quasar: A High-Performance Scoring and Ranking Library

* タイトル: Quasar: A High-Performance Scoring and Ranking Library
* キーワード: LinkedIn, スコアリング, ランキング, 性能, フレームワーク
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_birkmanis.pdf

スコアリングやランキング生成のためにLinkedInで用いられているライブラリ。
Quasar.

#### AI from Labs to Production - Challenges and Learnings

* タイトル: AI from Labs to Production - Challenges and Learnings
* キーワード: AIの商用適用
* スライド: 非公開

エンタープライズ向けにAIを使うのはB2CにAIを適用するときとは異なる。

#### MLOp Lifecycle Scheme for Vision-based Inspection Process in Manufacturing

* タイトル: MLOp Lifecycle Scheme for Vision-based Inspection Process in Manufacturing
* キーワード: Samsung Research, 運用, 深層学習, 製造業, 運用スキーム
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_lim.pdf

Samsung Research。
製造業における画像検知？における運用スキームの提案。
異なるステークホルダが多数存在するときのスキーム。
学習、推論、それらをつなぐ管理機能を含めて提案。
ボルトの検査など。

#### Deep Learning Vector Search Service

* タイトル: Deep Learning Vector Search Service
* キーワード: Microsoft, Bing, 検索, ベクトルサーチ, ANN(Approximae Nearest Neighbor), 深層学習
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_zhu.pdf

深層学習を用いてコンテンツをベクトル化する。
ベクトル間の関係がコンテンツの関係性を表現。
スケーラビリティを追求。

#### Signal Fabric An AI-assisted Platform for Knowledge Discovery in Dynamic System

* タイトル: Signal FabricAn AI-assisted Platform for Knowledge Discovery in Dynamic System
* キーワード: Microsoft, Azure, 運用改善のためのAI活用 
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_aghajanyan.pdf

Microsoft。Azure。
動的に変化するパブリッククラウドのサービスの振る舞いを把握するためのSignal Fabric。
「AI」も含めて様々な手段を活用。

#### Relevance Debugging and Explaining at LinkedIn

* タイトル: Relevance Debugging and Explaining at LinkedIn
* キーワード: LinkedIn, AIのデバッグ, 機械学習基盤, デバッガビリティの改善
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_qiu.pdf

LinkedIn。
分散処理のシステムは複雑。AIエンジニアたちはそれを把握するのが難しい。
そこでそれを支援するツールを開発した。
様々な情報をKafkaを通じて集める。
それを可視化したり、クエリしたり。

#### Shooting the moving target: machine learning in cybersecurity

* タイトル: Shooting the moving target: machine learning in cybersecurity
* キーワード: セキュリティへの機械学習適用, 機械学習のモデル管理
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_arun.pdf 

セキュリティへの機械学習適用。
基盤はモジューライズされ？、拡張可能で、
モデルを繰り返し更新できる必要がある。

#### Deep Learning Inference Service at Microsoft

* タイトル: Deep Learning Inference Service at Microsoft
* キーワード: 深層学習, 推論, Microsoft, ヘテロジーニアスアーキテクチャ
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_soifer.pdf

Microsoft。
深層学習の推論に関する工夫。インフラ。
ヘテロジーニアス・リソースの管理、リソース分離、ルーティングなど。
数ミリ秒単位のレイテンシを目指す。
モデルコンテナをサーブする仕組み。

### ソリューション関係

#### KnowledgeNet: Disaggregated and Distributed Training and Serving of Deep Neural Networks


* タイトル: KnowledgeNet: Disaggregated and Distributed Training and Serving of Deep Neural Networks
* キーワード: エッジ・クラウドパラダイム, DNN, 分散処理, ヘテロジーニアスアーキテクチャ
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_biookaghazadeh.pdf

DNNは強化学習、物体検知、ビデオ処理、VR・ARなどに活用されている。
一方でそれらの処理はクラウド中心のパラダイムから、エッジ・クラウドパラダイムに
移りつつある。
そこでDNNの学習とサービングをエッジコンピュータにまたぐ形で提供するようにする、
KnwledgeNetを提案する。
ヘテロジーニアスアーキテクチャ上で学習、サービングする。

クラウドでTeacherモデルを学習し、エッジでStudentモデルを学習する。

#### Continuous Training for Production ML in the TensorFlow Extended (TFX) Platform

* タイトル: Continuous Training for Production ML in the TensorFlow Extended (TFX) Platform
* キーワード: Google, 継続的な機械学習, TFX（TensorFlow Extended）, 機械学習のパイプライン
* スライド: https://www.usenix.org/system/files/opml19papers-baylor.pdf

大企業は、継続的な機械学習パイプラインに支えられている。
それが止まりモデルが劣化すると、下流のシステムが影響を受ける。
TensorFlow Extendedを使ってパイプラインを構成する。

#### Reinforcement Learning Based Incremental Web Crawling

* タイトル: Reinforcement Learning Based Incremental Web Crawling
* キーワード: ウェブクロール, 機械学習？
* スライド: 非公開

#### Katib: A Distributed General AutoML Platform on Kubernetes


* タイトル: Katib: A Distributed General AutoML Platform on Kubernetes
* キーワード: AutoML, Kubernetes, ハイパーパラメータサーチ, ニューラルアーキテクチャサーチ
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_zhou.pdf

Kubernetes上に、ハイパーパラメータサーチ、ニューラルアーキテクチャサーチのためのパイプラインをローンチするAutoMLの仕組み。


#### Machine Learning Models as a Service

* タイトル: Machine Learning Models as a Service
* キーワード: 中央集権的な機械学習基盤, 機械学習基盤のセキュリティ, Kafkaを使ったビーコン
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_wenzel.pdf


データサイエンティストがモデル設計や学習よりも、デプロイメントに時間をかけている状況を受け、
中央集権的な機械学習基盤を開発。
PyPIに悪意のあるライブラリが混入した件などを考慮し、中央集権的にセキュリティを担保。
Kafkaにビーコンを流す。リアルタイムに異常検知するフロー、マイクロバッチでデータレイクに格納し、再学習をするフロー。
その他、ロギング、トレーシング（トラッキング）、モニタリング。

#### Stratum: A Serverless Framework for the Lifecycle Management of Machine Learning-based Data Analytics Tasks

* タイトル: Stratum: A Serverless Framework for the Lifecycle Management of Machine Learning-based Data Analytics Tasks
* キーワード: 機械学習向けのサーバレスアーキテクチャ, Machine Learning as a Service, 推論, エッジ・クラウド
* スライド: https://www.usenix.org/sites/default/files/conference/protected-files/opml19_slides_bhattacharjee.pdf

Stratumというサーバレスの機械学基盤を提案。
モデルのデプロイ、スケジュール、データ入力ツールの管理を提供。
機械学習ベースの予測分析のアーキテクチャ。

### その他のセッション傾向

キーワード:

* スケーラビリティ
* 監視・観測、診断
* 最適化・チューニング

## SYSML

### SYSMLの定義

公式ウェブサイトには、以下のように記載されている。

> The Conference on Systems and Machine Learning (SysML) targets research at the intersection of systems and machine learning. The conference aims to elicit new connections amongst these fields, including identifying best practices and design principles for learning systems, as well as developing novel learning methods and theory tailored to practical machine learning workflows.

以上から、「システムと機械学習の両方に関係するトピックを扱う」と解釈して良さそうである。

### SYSML'19

#### コミッティなど

<!-- ![チェア集計](/memo-blog/images/td481cioc2ef3Mil-A22B9.png) -->

チェアたちの所属する組織の構成は以下の通り。

<iframe width='450' height='500' frameborder='0'  src="https://docs.google.com/spreadsheets/d/e/2PACX-1vR6QkuyQPO-vbZxkmVtRm7Y4gGTI84PR5g7cH6ej6TBYI94CEP-LIuhNhDO1qX4xN0Y4akeQNvlae7q/pubhtml?gid=1578066349&amp;single=true&amp;widget=true&amp;headers=false"></iframe>


プログラムコミッティの所属する組織の構成は以下の通り。

<!-- ![プログラムコミッティの集計](/memo-blog/images/td481cioc2ef3Mil-FAC17.png) -->

<iframe width='450' height='870' frameborder='0' src="https://docs.google.com/spreadsheets/d/e/2PACX-1vR6QkuyQPO-vbZxkmVtRm7Y4gGTI84PR5g7cH6ej6TBYI94CEP-LIuhNhDO1qX4xN0Y4akeQNvlae7q/pubhtml?gid=1695780236&amp;single=true&amp;widget=true&amp;headers=false"></iframe>


チェア、コミッティともに、幅広い層組織からの参画が見受けられるが、大学関係者（教授等）が多い。
僅かな偏りではあるが、Stanford Univ.、Carnegie Mellon Univ.、UCBあたりの多さが目立つ。
コミッティに限れば、MITとGoogleが目立つ。

#### トピック

トピックは以下の通り。

* Parallel & Distributed Learning
* Security and Privacy
* Video Analytics
* Hardware
* Hardware & Debbuging
* Efficient Training & Inference
* Programming Models

概ねセッション数に偏りは無いようだが、1個目のParallel & Distributed Learningだけは他と比べて2倍のセッション数だった。

#### TicTac: Accelerating Distributed Deep Learning with Communication Scheduling

* タイトル: TicTac: Accelerating Distributed Deep Learning with Communication Scheduling
* キーワード: 深層学習, DNNの高速化, TensorFlow, PyTorch, 学習高速化, 推論高速化
* スライド: https://www.sysml.cc/doc/2019/199.pdf

パラメータ交換を高速化。その前提となる計算モデルを考慮して、パラメータ交換の順番を制御する。
TensorFlowを改造。パラメータサーバを改造。
モデル自体を変更することなく使用可能。
推論で37.7%、学習で19.2%の改善。

<!-- vim: set tw=0 ts=4 sw=4: -->
