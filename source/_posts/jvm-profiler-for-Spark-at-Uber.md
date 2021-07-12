---

title: jvm profiler for Spark at Uber
date: 2020-01-07 00:20:37
categories:
  - Knowledge Management 
  - Spark
tags:
  - Java
  - Profiler
  - Apache Spark

---

# 参考

* [公式GitHub]
* [Strata NY 2019のセッション]
* [ブログ]

[公式GitHub]: https://github.com/uber-common/jvm-profiler
[Strata NY 2019のセッション]: https://conferences.oreilly.com/strata/strata-ny-2019/public/schedule/detail/77540
[ブログ]: https://eng.uber.com/jvm-profiler/


# メモ

## 概要

Sparkのエグゼキュータ等のJVMプロファイリングを行うためのライブラリ。

JVM起動時に、agentとしてアタッチするようにする。

executorプロセスのUUIDを付与しながらメトリクスを取得できるようだ。
Kafkaに流すことも可能。

[公式GitHub] のREADMEによると、オフヒープの使用量なども計測できており、チューニングに役立ちそう。

20200107時点では、2か月前ほどに更新されており、まだ生きているプロジェクトのようだ。

## 動作確認

[公式GitHub] のREADMEに記載されていた手順で、パッケージをビルドし、ローカルモードのSparkで利用してみた。

ビルド方法：

```
$ mvn clean package
```

パッケージビルド結果は、 `target/jvm-profiler-1.0.0.jar` に保存される。

これをjavaagentとして用いる。
渡すオプションは、 `--conf spark.executor.driverJavaOptions=-javaagent:${JVMPROFILER_HOME}/target/jvm-profiler-1.0.0.jar` である。
環境変数 `${JVMPROFILER_HOME}` は先ほどビルドしたレポジトリのPATHとする。

また、今回は com.uber.profiling.reporters.FileOutputReporter を用いて、ファイル出力を試みることとする。

結果的に、Sparkの起動コマンドは、以下のような感じになる。：

```
$ ${SPARK_HOME}/bin/spark-shell --conf spark.driver.extraJavaOptions=-javaagent:/home/ubuntu/Sources/jvm-profiler/target/jvm-profiler-1.0.0.jar=reporter=com.uber.profiling.reporters.FileOutputReporter,outputDir=/tmp/jvm-profile
```

ここで

* 環境変数 ${SPARK_HOME} はSparkを配備したPATHである
* ディレクトリ `/tmp/jvm-profile` は予め作成しておく

とする。

生成されるレコードは、以下のようなJSONである。CpuAndMemory.jsonの例は以下の通り。：

```
{
  "heapMemoryMax": 954728448,
  "role": "driver",
  "nonHeapMemoryTotalUsed": 156167536,
  "bufferPools": [
    {
      "totalCapacity": 20572,
      "name": "direct",
      "count": 10,
      "memoryUsed": 20575
    },
    {
      "totalCapacity": 0,
      "name": "mapped",
      "count": 0,
      "memoryUsed": 0
    }
  ],
  "heapMemoryTotalUsed": 400493400,
  "vmRSS": 812081152,
  "epochMillis": 1578408135107,
  "nonHeapMemoryCommitted": 157548544,
  "heapMemoryCommitted": 744488960,
  "memoryPools": [
    {
      "peakUsageMax": 251658240,
      "usageMax": 251658240,
      "peakUsageUsed": 37649152,
      "name": "Code Cache",
      "peakUsageCommitted": 38010880,
      "usageUsed": 37649152,
      "type": "Non-heap memory",
      "usageCommitted": 38010880
    },
    {
      "peakUsageMax": -1,
      "usageMax": -1,
      "peakUsageUsed": 104054944,
      "name": "Metaspace",
      "peakUsageCommitted": 104857600,
      "usageUsed": 104054944,
      "type": "Non-heap memory",
      "usageCommitted": 104857600
    },
    {
      "peakUsageMax": 1073741824,
      "usageMax": 1073741824,
      "peakUsageUsed": 14463440,
      "name": "Compressed Class Space",
      "peakUsageCommitted": 14680064,
      "usageUsed": 14463440,
      "type": "Non-heap memory",
      "usageCommitted": 14680064
    },
    {
      "peakUsageMax": 336592896,
      "usageMax": 243269632,
      "peakUsageUsed": 247788352,
      "name": "PS Eden Space",
      "peakUsageCommitted": 250085376,
      "usageUsed": 218352416,
      "type": "Heap memory",
      "usageCommitted": 239075328
    },
    {
      "peakUsageMax": 58195968,
      "usageMax": 55050240,
      "peakUsageUsed": 43791112,
      "name": "PS Survivor Space",
      "peakUsageCommitted": 58195968,
      "usageUsed": 43791112,
      "type": "Heap memory",
      "usageCommitted": 55050240
    },
    {
      "peakUsageMax": 716177408,
      "usageMax": 716177408,
      "peakUsageUsed": 138349872,
      "name": "PS Old Gen",
      "peakUsageCommitted": 450363392,
      "usageUsed": 138349872,
      "type": "Heap memory",
      "usageCommitted": 450363392
    }
  ],
  "processCpuLoad": 0.02584087025382403,
  "systemCpuLoad": 0.026174300837744344,
  "processCpuTime": 49500000000,
  "vmHWM": 812081152,
  "appId": "local-1578407721611",
  "vmPeak": 4925947904,
  "name": "24974@ubuec2",
  "host": "ubuec2",
  "processUuid": "38d5c63f-d70d-4e4d-9d54-a2381b9c37a7",
  "nonHeapMemoryMax": -1,
  "vmSize": 4925947904,
  "gc": [
    {
      "collectionTime": 277,
      "name": "PS Scavenge",
      "collectionCount": 16
    },
    {
      "collectionTime": 797,
      "name": "PS MarkSweep",
      "collectionCount": 4
    }
  ]
}
```

* nonヒープのメモリ使用量についても情報あり
* ヒープについては、RSSに関する情報もある
* ヒープ内の領域に関する情報もあり、GCに関する情報もある



<!-- vim: set et tw=0 ts=2 sw=2: -->
