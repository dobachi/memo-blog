---

title: Open Policy Agent
date: 2022-11-20 22:27:56
categories:
  - Knowledge Management
  - Usage Control
  - Open Policy Agent
tags:
  - Open Policy Agent

---

# メモ

[Open Policy Agentの公式サイト] にはまず初めに以下のように定義されている。

> Policy-based control for cloud native environments
> Flexible, fine-grained control for administrators across the stack

ポリシーをサービスのコードから切り離し、可用性や性能を犠牲にすることなく、ポリシーをリリース、分析、レビューできるものであるとされている。

## 概要

[Open Policy Agentに入門する] や [Open Policy Agent とは？（OpanStandia）] に日本語で概要が分かりやすく書かれているので一読するのがおすすめ。
[OPA Echosystem] にある通り、k8sだけではなく様々なプロダクトに対応している。
例えば、身近（？）なところでは、 [Kafka Authorizationのチュートリアル] にApache Kafkaのトピックの認可に用いれる例がチュートリアルとして説明されている。
Apache KafkaのAuthorizerを指定する仕組みを利用し、OPAをAuthorizerとして指定する。チュートリアルで用いている環境変数は、 `authorizer.class.name` と思われる。

## ユースケース

[Open Policy Agent とは？（OpanStandia）] によるとユースケースの半分以上がKubernetes Admission Controlとのこと。

[Open Policy Agent (OPA) のユースケース4選] に具体例が載っている。以下の通り。

* SSH接続の認可
* Dockerのseccompプロファイルなしで実行不可にする
* KubernetesのAdmission Controllerとして活用する
* サービスメッシュのEnvoyやIstio

## 簡易的な動作確認

### 実行環境

```bash
$ uname -a
Linux home 5.15.74.2-microsoft-standard-WSL2 #1 SMP Wed Nov 2 19:50:29 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux
```

### 動作確認メモ

[Policy as Codeを実現する Open Policy Agent 、 Rego の紹介] の解説が動作確認付きで分かりやすいので参考にして試す。
[dobachi's OPA Examples] に試した資材が置いてある。

[GitHubのreleases] から実行バイナリをダウンロードし実行権限を与える。
参考 -> https://github.com/dobachi/opa_examples/blob/main/bin/get_opa.sh

サンプルポリシー https://github.com/dobachi/opa_examples/blob/main/001/example.rego とサンプルデータ https://github.com/dobachi/opa_examples/blob/main/001/input.json を用いて動作確認する。

条件満たしていないことがわかる例
```shell
$ ./bin/opa eval -i 001/input.json -d 001/example.rego --format pretty data.example.allow
false
```

条件を満たしていない対象がわかる例
```bash
$ ./bin/opa eval -i 001/input.json -d 001/example.rego --format pretty data.example.violation
[
  "busybox",
  "ci"
]
```

### トラブルシュート

#### stableではないバイナリを使用したケース

当初CentOS Linux 7.9で試したのだが、ライブラリバージョンが合わず以下のエラーを生じた。

```shell
$ ./bin/opa eval -i 001/input.json -d 001/example.rego --format pretty data.example.allow
./bin/opa: /lib64/libc.so.6: version `GLIBC_2.27' not found (required by ./bin/opa)
```

環境のglibcバージョンは以下の通り。

```shell
$ yum list installed | grep glibc
Repodata is over 2 weeks old. Install yum-cron? Or run: yum makecache fast
glibc.x86_64                       2.17-324.el7_9             @updates
glibc-common.x86_64                2.17-324.el7_9             @updates
glibc-devel.x86_64                 2.17-324.el7_9             @updates
glibc-headers.x86_64               2.17-324.el7_9             @updates
```

[Running OPA] の通り、ここは素直にstaticバイナリを使うことにする。

## 関連技術

* [Sentinel]
  * HashiCorpのプロダクトと連携するPolicy as Codeフレームワーク

# 参考

## oPAに関する公式情報

* [Open Policy Agentの公式サイト]
* [GitHubのreleases]
* [OPA Echosystem]
* [Kafka Authorizationのチュートリアル]
* [Running OPA]

[Open Policy Agentの公式サイト]: https://www.openpolicyagent.org/
[GitHubのreleases]: https://github.com/open-policy-agent/opa/releases
[OPA Echosystem]: https://www.openpolicyagent.org/docs/latest/ecosystem/
[Kafka Authorizationのチュートリアル]: https://www.openpolicyagent.org/docs/latest/kafka-authorization/
[Running OPA]: https://www.openpolicyagent.org/docs/latest/#running-opa

## OPAに関する非公式情報

* [Open Policy Agentに入門する]
* [Open Policy Agent とは？（OpanStandia）]
* [Open Policy Agent (OPA) のユースケース4選]
* [Policy as Codeを実現する Open Policy Agent 、 Rego の紹介]
* [dobachi's OPA Examples]

[Open Policy Agentに入門する]: https://techstep.hatenablog.com/entry/2020/12/27/105801
[Open Policy Agent とは？（OpanStandia）]: https://openstandia.jp/oss_info/open-policy-agent/
[Open Policy Agent (OPA) のユースケース4選]: https://qiita.com/yoshimi0227/items/84d809890c73727d734a
[Policy as Codeを実現する Open Policy Agent 、 Rego の紹介]: https://tech.isid.co.jp/entry/2021/12/05/Policy_as_Code%E3%82%92%E5%AE%9F%E7%8F%BE%E3%81%99%E3%82%8B_Open_Policy_Agent_/_Rego_%E3%81%AE%E7%B4%B9%E4%BB%8B
[dobachi's OPA Examples]: https://github.com/dobachi/opa_examples

## 関連技術

* [Sentinel]

[Sentinel]: https://www.hashicorp.com/sentinel

## Policy as Code

* [Open Policy Agentに入門する] に多少まとめが書いてある


<!-- vim: set et tw=0 ts=2 sw=2: -->
