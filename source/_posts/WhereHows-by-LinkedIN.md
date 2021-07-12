---

title: WhereHows by LinkedIn
date: 2019-02-06 22:27:59
categories:
  - Knowledge Management
  - Data Engineering
  - Data Lineage
tags:
  - LinkedIn
  - WhereHows
  - Data Lineage

---

# 参考

* [ユースケース]
* [Wiki]
* [Architecture] 

[ユースケース]: https://github.com/linkedin/WhereHows/blob/master/wherehows-docs/use-cases.md
[Wiki]: https://github.com/LinkedIn/Wherehows/wiki
[Architecture]: https://github.com/linkedin/WhereHows/blob/master/wherehows-docs/architecture.md

# ユースケースについて

[ユースケース] に背景などが記載されている。
複数のデータソース、複数のデータストア、複数のデータ処理エンジン、そしてワークフロー管理ツール。
LinkedInの場合は以下のとおり。

* Analytics Storage system: HDFS, Teradata, Hive, Espresso, Kafka, Voldemort
* Execution: MapReduce, Pig, Hive, Teradata SQL.
* Workflow management: Azkaban, Appworx, Oozie

ユースケースは以下の通り。

* 新任の人が立ち上がりやすいようにする
* データセットを見つけられるようにする
* ジョブやデータの変更が及ぼす影響を確認する

# 機能概要

[Wiki]に画面キャプチャ付きで説明がある。
GUIの他、バックエンドAPIもあり、自動化できるようになっている。

例：https://github.com/LinkedIn/Wherehows/wiki/Backend-API#dataset-get

# アーキテクチャ

[Architecture] に記載されている。
Akkaベースでスケジューラが組まれており、スケジューラによりクローラが動く。

データセットやオペレーションデータがエンドポイトであり、リネージがそれを結ぶブリッジであると考えられる。
またこれらは極力汎用的に設計されているので、異なるプロダクトのデータを取り入れることができる。

## バックエンドのETLについて

Java、Jython、MySQLで構成。
分析ロジックの実装しやすさとほかシステムとの連携しやすさを両立。

* Dataset ETL
  * HDFS内をクロールする
* Operation data ETL
  * フロー管理ツールのログなどをクロールし、所定の形式に変換する
* Lineage ETL
  * 定期的にジョブ情報を取得し、入力データと出力データの定義から
    リネージを生成する
