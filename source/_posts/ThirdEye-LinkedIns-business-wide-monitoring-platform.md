---

title: ThirdEye LinkedIn’s business-wide monitoring platform
date: 2020-01-16 00:41:28
categories:
  - Knowledge Management
  - Monitering
tags:
  - Monitering
  - LinkedIn

---

# 参考

* [ThirdEye LinkedIn’s business-wide monitoring platform]
* [thirdeyeの実装]

[ThirdEye LinkedIn’s business-wide monitoring platform]: https://conferences.oreilly.com/strata/strata-ny-2019/public/schedule/detail/77219
[thirdeyeの実装]: https://github.com/apache/incubator-pinot/tree/master/thirdeye
[Analyzing anomalies with ThirdEye]: https://engineering.linkedin.com/blog/2020/analyzing-anomalies-with-thirdeye

# メモ

## セッションメモ

Strataの [ThirdEye LinkedIn’s business-wide monitoring platform] のメモ。

LinkedInで運用されている異常検知と原因分析のためのプラットフォーム。
オープンソースになっているようだ。 -> [thirdeyeの実装]

主に以下の内容が記載されていた。

* MTTD: Mean time to detect
* MTTR: Mean time to repair

50 チーム以上がThirdEyeを利用。
何千もの時系列データが監視されている？

攻撃を検知したり、AIモデル周りの監視。

アーキ図あり。

異常検知における課題：スケーラビリティ、性能

手動でのコンフィグ、監視は現実的でない。

ルールベースの単純な仕組みは不十分。
多すぎるアラートは邪魔。

## ブログメモ

[Analyzing anomalies with ThirdEye] のメモ。

データキューブについて。
LinkedInではPinotを使って事前にキューブ化されている。

ディメンジョン・ヒートマップの利用。
あるディメンジョンにおける問題の原因分析に有用。

変化の検出の仕方について。

ただし単独のディメンジョンの問題を検出するだけでは不十分。
複数のディメンジョンにまたがって分析してわかる問題を検出したい。

ディメンジョンをツリー構成。
ベースラインと現在の値でツリーを構成。

ノードの親子関係を利用。
各ノードとその親ノードの変化を式に組み入れることで、木構造に基づく傾向（？）を考慮しながら、
変化の重大さを算出する。

上記仕組みを利用することで、データマネージャのバグ、機械学習モデルサービングにおけるバグを見つけた。



<!-- vim: set et tw=0 ts=2 sw=2: -->
