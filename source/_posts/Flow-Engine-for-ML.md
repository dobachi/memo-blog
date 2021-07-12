---

title: Flow Engine for ML
date: 2020-02-16 22:31:14
categories:
  - Knowledge Management
  - Machine Learning
  - Flow Engine
tags:
  - Flow Engine

---

# 参考

## 総合

* [alternativetoでAirflowを検索した結果]

[alternativetoでAirflowを検索した結果]: https://alternativeto.net/software/apache-airflow/

## Azkaban

* [Azkabanのフロー書き方]

[Azkabanのフロー書き方]: https://azkaban.readthedocs.io/en/latest/createFlows.html#flow-2-0-basics


# メモ

機械学習で利用されるフロー管理ツールを軽くさらってみる。

## よく名前の挙がるもの

* Apache Airflow
* DigDag
* Oozie

## 機械的な検索

### Airflowの代替

[alternativetoでAirflowを検索した結果] では以下の通り。

* RunDeck
  * OSSだが商用版もある。自動化ツール。ワークフローも管理できるようだ
* StackStorm
  * どちらかというとIFTTTみたいなものか？
* Zenaton
  * ワークフローエンジン。JavaScriptで記述できるようだ
* Apache Oozie
  * Hadoopエコシステムのワークフローエンジン
* Azkaban
  * ワークフローエンジン
  * [Azkabanのフロー書き方] の通り、YAMLで書ける。
  * LinkedIn が主に開発
* Metaflow ★
  * ワークフローエンジン
  * 機械学習にフォーカス
  * Netflix と AWS が主に開発
* luigi
  * ワークフローエンジン
  * Pythonモジュール
  * Spotify が主に開発



<!-- vim: set et tw=0 ts=2 sw=2: -->
