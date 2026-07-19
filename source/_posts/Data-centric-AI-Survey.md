---

title: "論文解説：Data-centric Artificial Intelligence: A Survey"
date: 2026-04-05 00:00:00
categories:
  - Knowledge Management
  - AI
  - Machine Learning
  - Data Engineering
tags:
  - AI
  - Data-centric AI
  - Survey
  - Machine Learning
  - Data Engineering

---

# 論文解説：Data-centric Artificial Intelligence: A Survey

## 論文情報

* タイトル：Data-centric Artificial Intelligence: A Survey
* 著者：Daochen Zha, Zaid Pervaiz Bhat, Kwei-Herng Lai, Fan Yang, Zhimeng Jiang, Shaochen Zhong, Xia Hu
* 所属：Rice University / Texas A&M University（DATA Lab）
* 掲載誌：ACM Computing Surveys, Vol. 57, No. 5
* DOI：[10.1145/3711118]
* arXiv：[2303.10158] （初版 2023年3月、ACM掲載 2025年1月）
* 付随リソース：[data-centric-AI GitHub]

## 動機と位置づけ

従来のAI研究は「model-centric」なパラダイム、すなわち固定されたデータセットを前提にモデル設計・ハイパーパラメータ最適化を繰り返すアプローチを中心としてきた。しかしこのアプローチにはいくつかの本質的な限界がある。

* 固定データセットへの過度な依存は、実世界応用における汎化性能の低下を招く
* モデルが特定の問題・データに高度に特化するため、転移が困難
* データに潜む質的問題（欠損値・不正確なラベル・異常値）を看過しがちであり、**データカスケード**（上流の品質問題が下流に連鎖的に波及する現象）を引き起こす

Andrew Ng が提唱した **Data-centric AI（DCAI）** の概念は、この状況への応答として登場した。本論文はその概念を体系的に整理し、156本以上の文献を横断的に調査・分類した初の包括的サーベイである。

なお、「data-centric」と「data-driven」は根本的に異なる概念である。data-drivenはデータをAI開発の指針として使うことを強調するだけで、依然としてモデル開発が主体となる。これに対してdata-centricはデータそのものをエンジニアリングの主対象と置く。

## 著者について

全著者がRice大学とTexas A&M大学に所属し、Xia Hu 教授（Rice大）が率いる **DATA Lab** を中心とするグループである。筆頭著者のDaochen Zhaは本サーベイのリードを担い、NeurIPS・ICMLなどのトップ会議への掲載多数。グループはサーベイだけでなく、KDD 2023でのチュートリアル開催、関連ベンチマーク整備、GitHubでのリソースリスト継続更新など、コミュニティ形成にも積極的に関与している。

## リサーチクエスチョン

本論文が明示的に設定した4つの問いは以下の通り。

* **RQ1**：AIをdata-centricにするために必要なタスクは何か？
* **RQ2**：データの開発・維持においてなぜ自動化が重要か？
* **RQ3**：どの場面でなぜ人間の参加が不可欠か？
* **RQ4**：Data-centric AIの現在の進捗はどこまで来ているか？

## フレームワーク：3つの目標（Goal-driven Taxonomy）

論文の中核は、データライフサイクル全体を3つの目標で整理した**goal-driven taxonomy**である。

![Goal-driven Taxonomy](/memo-blog/images/dcai-taxonomy.png)

* **Training Data Development**：学習データの収集から前処理・拡張までのパイプライン
* **Inference Data Development**：モデルに入力するデータの設計・評価
* **Data Maintenance**：データの継続的なメンテナンス

以下、それぞれの目標について詳述する。

### Training Data Development

学習データの収集から前処理・拡張までのパイプラインを扱う。モデルの性能はデータの質と量に強く依存するため、このフェーズへの投資がAIシステム全体の基盤となる。

#### Data Collection

学習に必要な生データを様々なソースから収集・統合する。収集戦略がデータ品質・量の出発点を決定づける。論文は「データ収集プロセスは重要なインフラとツールのサポートを必要とする」と指摘する。

代表的なタスク・手法：Dataset discovery、Data integration、Raw data synthesis

#### Data Labeling

収集した生データに教師信号（ラベル）を付与し、教師あり学習を可能にする。「ラベリングはモデルが意図した予測を行えるようにするうえで不可欠であり、適切なラベルなしにはモデルは与えられたデータ以上の性能を発揮できない」と論文は述べる。従来は人手に依存していたが、近年は効率化手法が多数提案されている。

代表的なタスク・手法：Crowdsourced labeling、Semi-supervised labeling、Active learning、Data programming（Snorkel）、Distant supervision

#### Data Preparation

収集・ラベリング済みデータを学習に適した形式に変換・整備する。欠損値処理・外れ値除去・特徴量抽出・変換など、モデルへの入力品質を直接左右する工程である。

代表的なタスク・手法：Data cleaning、Feature extraction、Feature transformation

#### Data Reduction

データの次元や量を削減しつつ、モデル性能を維持または向上させる。不要な特徴量を除去することで計算コストを下げ、過学習を抑制する。「特徴選択は数十年前から研究されてきた古典的テーマ」と論文は位置づけている。

代表的なタスク・手法：Feature selection、Dimensionality reduction、Instance selection

#### Data Augmentation

手元のデータセットに対して変換・合成を施し、データの多様性と量を拡大する。追加収集なしにデータ分布を豊かにし、モデルの汎化性能を高める。クラス不均衡への対応（SMOTE・ADASYN）も含む。

代表的なタスク・手法：Basic manipulation（回転・フリップ等）、GAN・拡散モデルによる合成、Upsampling

#### Pipeline Search

前処理・削減・拡張など複数工程を横断的に統合し、エンドツーエンドで最適な構成を探索する。個別工程の局所最適ではなく全体最適を目指す。AutoSklearnを先駆けとし、DARPAのD3Mプログラムがインフラ整備を牽引してきた。

代表的なタスク・手法：AutoSklearn、DARPA D3M、End-to-end AutoML

### Inference Data Development

モデルに入力するデータの設計・評価を扱う。model-centricパラダイムではほぼ看過されていた領域だが、大規模言語モデルの台頭によりその重要性が急上昇している。

#### In-distribution Evaluation

学習データ分布の範囲内で、モデルの挙動を細粒度に把握・診断する。特定のデータスライス（属性の組み合わせ等）でモデルが弱い箇所を特定したり、モデル判断の「反事実的な境界」（Algorithmic recourse）を可視化する。潜在的なバイアスの検出にも有効である。

代表的なタスク・手法：Data slicing（Slice Finder）、Algorithmic recourse（反事実的説明）

#### Out-of-distribution Evaluation

学習分布から外れた入力に対するモデルの脆弱性・頑健性を評価する。敵対的サンプルを用いたAIセキュリティ研究の基盤であり、実世界展開時のリスク把握に直結する。

代表的なタスク・手法：Adversarial samples生成、Distribution shiftのシミュレーション

#### Prompt Engineering

学習済みの大規模モデルをパラメータ更新なしに活用するため、入力データ（プロンプト）を最適化する。「モデルが十分に強力な場合、推論データ（プロンプト）を調整するだけで目的を達成できる」と論文は示す。手動設計から自動探索（Automated Prompt Search）まで幅広い手法が対象である。

代表的なタスク・手法：Manual prompt design、Automated prompt search

### Data Maintenance

実世界ではデータは一度作成して終わりではなく、継続的なメンテナンスが必要である。このフェーズはトレーニング・推論データの正確性と信頼性を動的環境の中で保証するための役割を担う。

#### Data Understanding

複雑なデータセットを人間が洞察を得やすい形に可視化・要約する。また **Data valuation**（各データポイントがモデルに対してどれだけ貢献しているかの定量評価）により、取捨選択や改善優先度の判断を支援する。

代表的なタスク・手法：Visual summarization、Clustering for visualization、Visualization recommendation、Data valuation

#### Data Quality Assurance

データの品質を定量的に評価し、問題箇所を検出・修復する。動的環境でのデータドリフト検知や継続的な品質モニタリングを含む。データカスケード（品質問題の連鎖的伝播）を防ぐ最重要プロセスである。

代表的なタスク・手法：Quality assessment、Quality improvement

#### Data Storage & Retrieval

必要なデータを効率的に供給するためのインフラ最適化。クエリ性能の向上・インデックス自動選択・DBの自律チューニングなど、大規模データを実用速度で扱うための基盤技術である。機械学習を用いてDB管理システム自体を自律化する方向性（Self-driving DB）も含まれる。

代表的なタスク・手法：Query index selection、Query rewriting、Resource allocation、DB自律チューニング

なお、各サブゴールのうち、Data Preparation・Data Reduction・Data Storage & Retrieval の説明については、論文のフレームワーク定義とTable 1の分類を根拠として補足している。論文ではこれらの項目は手法列挙が主であり、目的の散文的説明は省略されているため、論文のコンテキストから解釈・補完した部分がある。

## 横断的な分析視点：自動化 vs. 人間協働

各タスクを「自動化の程度」と「人間の関与度」という2軸でさらに分類している点が本論文の独自性の一つである。2軸はそれぞれ独立したスペクトラムであり、論文内の各手法はいずれかに分類される。

![自動化 vs. 人間協働の2軸](/memo-blog/images/dcai-axes.png)

### 自動化の3レベル

自動化軸はコスト・複雑さが低い方から高い方に向かって以下の3レベルに分かれる。

* **Programmatic**（人間コスト：低）：ヒューリスティクスや統計的ルールでデータを自動処理する。設計が単純で高速だが、柔軟性は低い。
* **Learning-based**（人間コスト：中）：目的関数を最適化することで自動化戦略自体を学習する。より柔軟・適応的だが、学習コストが発生する。
* **Pipeline**（人間コスト：高）：前処理〜拡張など複数工程を横断して最適構成を一括探索する。全体最適を狙えるが、探索コストが大幅に増大する。

### 人間協働の3段階

人間協働軸は人間の関与度が低い方から高い方に向かって以下の3段階に分かれる。

* **Minimum participation**（人間コスト：低）：手法がプロセス全体を制御し、必要なときのみ人間に判断を求める。
* **Partial participation**（人間コスト：中）：手法が主導しつつ、人間が継続的にフィードバックを提供し続ける。
* **Full participation**（人間コスト：高）：人間がプロセスを完全制御し、手法は補助ツールに徹する。

自動化・人間協働のどちらのレベルも「高い方が優れている」わけではない。効率（人間労力の削減）と有効性（人間の意図との整合）はトレードオフであり、ドメイン・ステークホルダーのニーズに応じた使い分けが前提となる。たとえば Pipeline automation はシナリオによっては過複雑となり、単純な Programmatic 手法の方が実用的なケースも多い。

## 調査対象論文の範囲と時代的分布

本サーベイが対象とする文献は、古典的な研究から最新の動向まで幅広い時代にわたる。

* **古典的・確立領域**：Feature selection、Data augmentation（基本的手法）、Active learning
* **2010年代後半**：Crowdsourcing（MTurk系）、AutoML（AutoSklearn等）、GAN系データ拡張
* **2020年代前半**：Data programming（Snorkel）、Prompt engineering、RLHF、Adversarial robustness
* **最新動向（2023年時点）**：Foundation models活用、Automated prompt search、Algorithmic recourse

個別テーマに絞った既存サーベイ（データ拡張、ラベリング、特徴選択等）はすでに存在していたが、データライフサイクル全体を横断するgoal-driven taxonomyによる統合的整理は本論文が初である。

## 主要な考察結果

### Data-centric と Model-centric は対立しない

model-centricの価値を否定するのではなく、**相互補完的なパラダイム**として捉える。GANや拡散モデル等のモデル技術がデータ拡張を支援し、逆に拡充されたデータがモデル設計の進化を促す。本番環境ではデータとモデルは絶えず変化する環境の中で交互に進化していく。

### データカスケード問題の深刻さ

データ品質を軽視すると、上流の問題が下流に連鎖的に波及し、精度低下・持続的バイアスなどを引き起こす。高リスク領域（医療・金融等）ではこの影響が特に甚大である。

### 大規模言語モデルの成功はData-centric AIの証左

GPT-2からGPT-3への進化はアーキテクチャの変更ではなく、高品質・大規模なデータの収集によって達成された。ChatGPTもGPT-3と同等アーキテクチャのまま、RLHFによる高品質ラベルデータの活用が成功の鍵となっている。

### 評価フェーズの再定義

Data-centric AIパラダイムにおける評価は、精度指標だけでなく、データの動的な性質・攻撃者の存在・説明可能性（right of explanation）など多面的な側面を考慮すべきである。

## 将来の研究課題（Future Directions）

* **Foundation Models との統合**：大規模事前学習モデルがラベリング・拡張・品質保証などのData-centric AIタスクをどう変革するか
* **プライバシー保護との両立**：連合学習・差分プライバシー等を組み合わせた、データ品質向上とプライバシー保護の共立
* **統一ベンチマーク整備**：個別タスクに偏った既存ベンチマーク（DataPerf等）を超える、データライフサイクル全体を評価できる指標の構築
* **高リスクドメインへの展開**：医療・金融・法律等における体系的なデータエンジニアリングの適用と検証
* **データカスケードの予防**：上流品質管理の自動化・定量化手法の確立

## 総評

本論文の最大の貢献は、**従来は独立して議論されていた多数のデータ関連タスクを、データライフサイクルという統一的な視座のもとに再配置し、自動化と人間協働という実践的な軸を加えて整理した**点にある。単なるサーベイにとどまらず、コミュニティへの方向付けを意図した「教科書的」な役割を担う論文として位置づけられる。

ただし、本論文が主に扱うのはアルゴリズム・手法レベルの分類であり、**システムアーキテクチャ（データスペース設計・分散インフラ等）については対象外**である点は留意が必要である。データエコシステムや主権保護的なデータ流通の文脈でこの論文を読む際は、Data Maintenanceのサブゴール（品質保証・データ理解）との接続点を中心に参照するのが実用的である。

## 参考情報

* [arXiv]
* [ACM Digital Library]
* [data-centric-AI GitHub]
* [KDD 2023 チュートリアル]

[10.1145/3711118]: https://dl.acm.org/doi/10.1145/3711118
[2303.10158]: https://arxiv.org/abs/2303.10158
[data-centric-AI GitHub]: https://github.com/daochenzha/data-centric-AI
[arXiv]: https://arxiv.org/abs/2303.10158
[ACM Digital Library]: https://dl.acm.org/doi/10.1145/3711118
[KDD 2023 チュートリアル]: https://dcaitutorial.github.io/
