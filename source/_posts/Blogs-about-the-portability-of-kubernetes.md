---

title: 'Blogs about the portability of kubernetes '
date: 2022-01-07 10:48:03
categories:
  - Knowledge Management
  - Kubernetes
tags:
  - Kubernetes

---

# メモ

このメモは、Kubernetesを利用することで以下のポータビリティを得られるのではないか、という点に関する議論を列挙したものである。

* アプリケーションのポータビリティ
  * あるKubernetesクラスタ上にデプロイした or 可能なアプリケーションを異なるKubernetes環境で実行する
* Kubernetesクラスタのポータビリティ
  * Kubernetesクラスタを様々な環境で実行する

## Kubernetes を本番環境に適用するための Tips

[Kubernetes を本番環境に適用するための Tips] の中に、アプリケーションのポータビリティに関する議論が含まれている。
具体的には、

* Kubernetes環境の違い
* Kubernetesが同じバージョンでも機能の有効・無効、使える・使えないが異なる
* Kubernetesのバージョンが異なると設定ファイルの書き方が同一である保証がない
* 具体例として、LoadBalancerやVolumeが環境によって異なる

ことが挙げられた。

## Kubernetes 8 Factors - Kubernetes クラスタの移行から学んだクラスタのポータビリティの重要性と条件

[Kubernetes 8 Factors - Kubernetes クラスタの移行から学んだクラスタのポータビリティの重要性と条件] では、
KubernetesのBreaking Changeに関して言及されていた。
（アプリケーションのポータビリティの話もあるが、Kubernetesクラスタの運用に関する点が言及された記事）

そこそこの頻度（マイナーバージョンアップにおいても、という意味）でも、Breaking Changeが生じるため、アップデートしていくのが大変だ、と。
小さな規模だったらクラスタ丸ごとデプロイしなおす（※）、という対応も可能だったが、様々な業務が載ってくるとそれも大変、と。

※小さな規模でクラスタ丸ごと都度デプロイしなおす、ということだと、Kubernetesで抽象化する意味が…？ということも考えうるか？

## Twelve-Factor App

[Twelve-Factor App] にはアプリケーションのポータビリティの考えを含む、以下のような「Software as a Service 」を実現するにあたってのポイントが提言されている。

* セットアップ自動化のために 宣言的な フォーマットを使い、プロジェクトに新しく加わった開発者が要する時間とコストを最小化する。
* 下層のOSへの 依存関係を明確化 し、実行環境間での 移植性を最大化 する。
* モダンな クラウドプラットフォーム 上への デプロイ に適しており、サーバー管理やシステム管理を不要なものにする。
* 開発環境と本番環境の 差異を最小限 にし、アジリティを最大化する 継続的デプロイ を可能にする。
* ツール、アーキテクチャ、開発プラクティスを大幅に変更することなく スケールアップ できる。

## Kubernetesを採用するべき１２の理由

[Kubernetesを採用するべき１２の理由] にはアプリケーションのポータビリティに関連するKubernetesの利点が記載されている。
一部、Kubernetesクラスタのポータビリティと考えてもよい内容もある。

> 理由4 仮想サーバーやベアメタルとハイブリッド構成可能な柔軟な運用基盤

> 理由6 オンプレとクラウドの両方で利用できる運用基盤

## Kubernetes、やめました

ポータビリティの直接的な議論ではないが、[Kubernetes、やめました] にはKubernetesを採用しなかったケースの話が記載されている。
Kubernetesの学習コストと効果を天秤にかけた結果、他の技術で目的は達成できるはず、ということ。

## 多分あなたにKubernetesは必要ない

[多分あなたにKubernetesは必要ない] では、KubernetesではなくNomadを利用することにした経緯が記載されている。
Nomadは「オーケストレータ」だがそれで用が足りた、ということのようだ。

> もしあなたが大規模インフラ上に同一サービス群をデプロイする計画をしているのであれば、Kubernetesという道を選んで良いでしょう。ただ、複雑性や運用コストが増えることを肝に命じてください。そしてこういったコストの一部は、Google Kubernetes EngineやAmazon EKSのようなマネージドKubernetes環境を利用することで省くことができます。


## 「あなたにKubernetesは必要ですか？」を、Kubernetes Meetup Tokyoのコアメンバーが議論

[「あなたにKubernetesは必要ですか？」を、Kubernetes Meetup Tokyoのコアメンバーが議論] では、
[多分あなたにKubernetesは必要ない] の記事を受けて行われた、
日本でKubernetesを本格運用している企業の著名エンジニアによるパネルディスカッションの様子が記載されている。

なお、個人的に気になったのは以下の下り。

> 青山氏は、Kubernetesでも、CI/CDツールなどとうまく組み合わせることで、カスタマイズできるPaaSに近い環境を作ることができるとした。また、五十嵐氏は、「開発者と運用支援担当が別チームとして役割分担しやすい」というKubernetesの特徴を生かせれば、開発者が最小限の設定で使えるようにできると話した。

> ルイス氏は、Kubernetes上でPaaSやFaaSが稼働するような動きが今後進むことで、一部の懸念は解消に向かうのではないかとしている。

PaaSやFaaSを実現する基盤技術は、単体でクラスタ構成可能なものもあるため、Kubernetes上に載せることで「抽象化の層」が増えることになる。
抽象化の恩恵と複雑性増加の辛さを天秤にかけることになるだろう。


## CNDO2021、Kubernetesがない世界とある世界の違いをインフラエンジニアが解説

ポータビリティはあまり関係ない。

[CNDO2021、Kubernetesがない世界とある世界の違いをインフラエンジニアが解説] では、
「CI/CDまではできているがKubernetesがない」場合と、Kubernetesがある場合を比較し、
「Kubernetesがなくてもクラウドネイティブ化の目的は達成できうるが、結局はKubernetesらが実現していることを自分でやらないといけない」とした。

なお、クラウドネイティブ化の目的については、CNCFの定義が引用されていた。

> 素早く継続的にユーザーに価値を届ける

# 参考

* [Kubernetes を本番環境に適用するための Tips]
* [Kubernetes 8 Factors - Kubernetes クラスタの移行から学んだクラスタのポータビリティの重要性と条件]
* [Twelve-Factor App]
* [Kubernetesを採用するべき１２の理由]
* [Kubernetes、やめました] 
* [多分あなたにKubernetesは必要ない]
* [「あなたにKubernetesは必要ですか？」を、Kubernetes Meetup Tokyoのコアメンバーが議論]
* [CNDO2021、Kubernetesがない世界とある世界の違いをインフラエンジニアが解説]

[Kubernetes を本番環境に適用するための Tips]: https://yoshio3.com/2018/12/06/kubernetes-tips-for-production/
[Kubernetes 8 Factors - Kubernetes クラスタの移行から学んだクラスタのポータビリティの重要性と条件]: https://www.wantedly.com/companies/wantedly/post_articles/222009#_=_
[Twelve-Factor App]: https://12factor.net/ja/
[Kubernetesを採用するべき１２の理由]: https://qiita.com/MahoTakara/items/39ed37449e6f0f8f65a7
[Kubernetes、やめました]: http://blog.father.gedow.net/2020/06/03/goodbye-kubernetes/
[多分あなたにKubernetesは必要ない]: https://yakst.com/ja/posts/5455
[「あなたにKubernetesは必要ですか？」を、Kubernetes Meetup Tokyoのコアメンバーが議論]: https://atmarkit.itmedia.co.jp/ait/articles/1907/23/news120.html
[CNDO2021、Kubernetesがない世界とある世界の違いをインフラエンジニアが解説]: https://thinkit.co.jp/article/18557


<!-- vim: set et tw=0 ts=2 sw=2: -->
