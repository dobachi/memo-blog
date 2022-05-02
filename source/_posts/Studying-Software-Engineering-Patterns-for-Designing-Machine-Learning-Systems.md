---

title: Studying Software Engineering Patterns for Designing Machine Learning Systems
date: 2019-11-12 22:54:19
categories:
  - Knowledge Management
  - Machine Learning
  - Software Engineering Patterns
tags:
  - Machine Learning
  - Software Engineering Patterns

---

# 参考

* [Studying Software Engineering Patterns for Designing Machine Learning Systems]
* [スライド]

[Studying Software Engineering Patterns for Designing Machine Learning Systems]: https://arxiv.org/abs/1910.04736
[スライド]: https://www.slideshare.net/hironoriwashizaki/ss-191808794

# メモ

[スライド] に大まかな内容が記載されている。

機械学習に関するソフトウェアエンジニアリングやアーキテクチャデザインパターンに関する調査。
良い/悪いソフトウェアエンジニアリングデザインパターンを調査。
「リサーチ質問」（RQ）という形でいくつか確認事項を用意し、
ヒアリングや検索エンジンによる調査を実施。
SLR（Systematic literature review）手法にのっとり、調査結果を検証。

ヒアリングは760超の開発者を対処に実施し、1%の回答者を得た。

調査は、23個の論文、追加の6個の論文、48個のグレードキュメントを調査。
アカデミックではシステムエンジニアリングデザインパターンの文献は少ない。
グレードキュメントでは多数。データマネジメント観点が多い。

パターン整理では以下の軸を用いた。

* Microsoftのパイプライン（9ステージ）
* ISO/IEC/IEEE 12207:2008 standard

ドキュメント群から69個のパターンを抽出。MLのアーキテクチャやデザインパターン関係は33個。

## 興味深かった図

業務ロジックとMLロジックを分離。
メンテナンス性が上がるだろうが、果たしてロジックを現実的に分離可能かどうかはやや疑問。

![Fig. 2. Structure of Distinguish Business Logic from ML Model pattern ](/memo-blog/images/o1CxtOXFaFpiiLor-BC508.png)

モデルに関するドキュメントが多数。

![TABLE III CLASSIFICATION OF THE IDENTIFIED PATTERNS](/memo-blog/images/o1CxtOXFaFpiiLor-A26A7.png)


<!-- vim: set tw=0 ts=4 sw=4: -->
