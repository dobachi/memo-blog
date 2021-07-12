---

title: Uber's 2019 highlights
date: 2019-12-29 23:52:34
categories:
  - Clipping
  - Uber
tags:
  - Uber

---

# 参考

* [Year in Review: 2019 Highlights from the Uber Engineering Blog]
* [Introducing Ludwig, a Code-Free Deep Learning Toolbox]
* [Uber’s Data Platform in 2019 Transforming Information to Intelligence]

[Year in Review: 2019 Highlights from the Uber Engineering Blog]: https://eng.uber.com/2019-highlights/
[Introducing Ludwig, a Code-Free Deep Learning Toolbox]: https://eng.uber.com/introducing-ludwig/
[Uber’s Data Platform in 2019 Transforming Information to Intelligence]: https://eng.uber.com/uber-data-platform-2019/


# メモ


## Ludwig

モデル開発と比較を単純にするために作られたソフトウェア。

詳しくは、 [Introducing Ludwig, a Code-Free Deep Learning Toolbox] を参照。

## AresDB

GPUを活用した処理エンジン。


## QUIC導入

TCPとHTTP/2の置き換え。

## Kotlinの性能調査

Javaとの比較など。かなり細かく調査したようだ（まだ読んでいない）

## グラフ処理と機械学習を用いたUber Eatsの改善

グラフ構造に基づいた機械学習により、
レコメンデーションの効果を向上させる取り組みについて。


## Uber’s Data Platform in 2019: Transforming Information to Intelligence

[Uber’s Data Platform in 2019 Transforming Information to Intelligence]

UberでもData Platformという言い方をするようだ。

データの用途は、スクーターの位置情報や店舗の最新メニューをトラックするだけではない。
トレンドを把握することなどにも用いられる。

データの鮮度の品質は大事。

リアルタイムの処理のニーズ・仕組み、ヒストリカルなデータの処理のニーズ・仕組み。両方ある。

補足）それぞれがあることを前提とした最適化を施すことが前提となっているようだ。

データがどこから来たのかをトラックする。
Uberの内部プロダクト uLineageにて実現。

Apache HBaseをグローバルインデックスとして利用。
これにより、高いスケーラビリティ、強い一貫性、水平方向へのスケーラビリティを獲得する。

DBEventsというプロダクトで、CDCを実現する。

トラブルシュートとプロアクティブな防止。

もしリアルタイムにデータ分析できれば、例えば利用者にドライバ替わり当たらず一定時間を過ぎてしまったケースを発見し、
オペレーションチームが助けられるかもしれない。

AresDB、Apache Pinotなど。★要確認


<!-- vim: set et tw=0 ts=2 sw=2: -->