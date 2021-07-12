---

title: GradleプロジェクトをIntellijでインポート
date: 2019-06-24 22:55:09
categories:
  - Knowledge Management
  - Tools
  - Intellij
tags:
  - Intellij
  - Apache Kafka
  - Kafka
  - Gradle

---

# 参考

* [./grdlew idea 叩かなくていいよ。]

[./grdlew idea 叩かなくていいよ。]: https://tyablog.net/2018/09/24/dont-have-to-run-gradlew-idea/

# メモ

昔は `gradlew idea` とやってIdea用のプロジェクトファイルを生成してから
インポートしていたけれども、最近のIntellijは「ディレクトリを指定」してインポートすると、
Gradleプロジェクトを検知して、ウィザードを開いてくれる。

例えばApache KafkaなどのGradleプロジェクトをインポートするときには、
メニューからインポートを選択し、ディレクトリをインポートすると良い。

