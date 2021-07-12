---

title: Open Messaging Benchmark
date: 2019-01-16 00:25:15
categories:
  - Knowledge Management
  - Messaging System
tags:
  - Open Messaging Benchmark
  - Kafka
  - Pulsar

---

# 参考

* [Open Messaging Benchmarkのウェブサイト]
* [openmessaging-benchmarkのGitHub]
* [Kafkaのドライバ]
* [Kafka構築のAnsible Playbook]
* [Kafka構築のTerraformコンフィグ]

[Open Messaging Benchmarkのウェブサイト]: http://openmessaging.cloud/docs/benchmarks/
[openmessaging-benchmarkのGitHub]: https://github.com/openmessaging/openmessaging-benchmark
[Kafkaのドライバ]: https://github.com/openmessaging/openmessaging-benchmark/tree/master/driver-kafka
[Kafka構築のAnsible Playbook]: https://github.com/openmessaging/openmessaging-benchmark/blob/master/driver-kafka/deploy/deploy.yaml
[Kafka構築のTerraformコンフィグ]: https://github.com/openmessaging/openmessaging-benchmark/blob/master/driver-kafka/deploy/provision-kafka-aws.tf
[BenchmarkDriver]: https://github.com/openmessaging/openmessaging-benchmark/blob/master/driver-api/src/main/java/io/openmessaging/benchmark/driver/BenchmarkDriver.java
[benchmark]: https://github.com/openmessaging/openmessaging-benchmark/blob/master/bin/benchmark
[contributors]: https://github.com/openmessaging/openmessaging-benchmark/graphs/contributors
[issues]: https://github.com/openmessaging/specification/issues

# メモ

ウェブサイトを確認してみる。

## 所感

あくまでメッセージングシステムに負荷をかけ、その特性を見るためのベンチマークに見える。
したがって負荷をかけるクライアントはシンプルであり、ただしワークロードを調整するための
パラメータは一通り揃っている、という様子。

## パラメータ

* The number of topics
* The size of the messages being produced and consumed
* The number of subscriptions per topic
* The number of producers per topic
* The rate at which producers produce messages (per second). Note: a value of 0 means that messages are produced as quickly as possible, with no rate limiting.
* The size of the consumer’s backlog (in gigabytes)
* The total duration of the test (in minutes)

「BENCHMARKING WORKLOADS」の章に代表的な組み合わせパターンの記載がある。

## その他

* 「warm-up」とあったが、何をしているのだろう。
* 構成はTerraformとAnsibleでやるようだ

# GitHubを見てみる

## Kafkaのドライバ

[openmessaging-benchmarkのGitHub]  を眺めてみる。
[Kafkaのドライバ] を除くとデプロイ用のTerraformコンフィグとAnsibleプレイブックがあった。

[Kafka構築のTerraformコンフィグ] の通り、一通りAWSインスタンスをデプロイ。
[Kafka構築のAnsible Playbook] の通り、ひととおりKafkaクラスタから負荷がけクライアントまで構成。

なお、ソースコードとしてベンチマークのドライバが含まれているが、
その親クラスが [BenchmarkDriver] だった。

## bin

bin以下には、ベンチマークを実行すると思われる、 [benchmark]が含まれていた。

## Benchmarkクラス

以下の通り、ワークロードごとに、指定されたドライバのコンフィグレーションに基づき、
負荷をかけるようになっているようだ。

io/openmessaging/benchmark/Benchmark.java:126

```
        workloads.forEach((workloadName, workload) -> {
            arguments.drivers.forEach(driverConfig -> {
```

また以下の通り、WorkloadGeneratorを通じて、ワークロードがかけられるようだ。

io/openmessaging/benchmark/Benchmark.java:140

```
                    WorkloadGenerator generator = new WorkloadGenerator(driverConfiguration.name, workload, worker);

                    TestResult result = generator.run();
```

## コントリビュータ

yahoo、alibaba、streamlioあたりからコントリビュータが出ている。
ただし主要な開発者は数名。
最初にYahooの若干名が活発に開発し、それに加わった人がいるようだ。

## イシュー

エンハンスを中心に、いくつか挙げられていた（2019/1/18時点）
