---
title: KafkaのJavaバージョン
date: 2019-11-03 23:17:21
categories:
  - Knowledge Management
  - Messaging System
  - Kafka
tags:
  - Kafka

---

# 参考

* [6.4 Java Version]

[6.4 Java Version]: https://kafka.apache.org/documentation/#java

# メモ

[6.4 Java Version] の通り、JDK1.8の最新リリースバージョンを使うように、とされている。
2019/11/03時点の公式ドキュメントでは、LinkedInでは1.8u5を使っているとされているが…。

このあたりの記述が最も最近でいつ編集されたか、というと、
以下の通り2018/5/21あたり。

```
commit e70a191d3038e00790aa95fbd1e16e78c32b79a4
Author: Ismael Juma <ismael@juma.me.uk>
Date:   Mon May 21 23:17:42 2018 -0700

    KAFKA-4423: Drop support for Java 7 (KIP-118) and update deps (#5046)

(snip)

diff --git a/docs/ops.html b/docs/ops.html
index 450a268a2..95b9a9601 100644
--- a/docs/ops.html
+++ b/docs/ops.html
@@ -639,9 +639,7 @@

   From a security perspective, we recommend you use the latest released version of JDK 1.8 as older freely available versions have disclosed security vulnerabilities.

-  LinkedIn is currently running JDK 1.8 u5 (looking to upgrade to a newer version) with the G1 collector. If you decide to use the G1 collector (the current default) and you are still on JDK 1.7, make sure you are on u51 or newer. LinkedIn tried out u21 in testing, but they had a number of problems with the GC implementation in that version.
-
-  LinkedIn's tuning looks like this:
+  LinkedIn is currently running JDK 1.8 u5 (looking to upgrade to a newer version) with the G1 collector. LinkedIn's tuning looks like this:
   <pre class="brush: text;">
   -Xmx6g -Xms6g -XX:MetaspaceSize=96m -XX:+UseG1GC
   -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M
```

## 関連しそうなIssue、メーリングリストのエントリ

あまり活発な議論はない。公式ドキュメントを参照せよ、というコメントのみ。
Jay Kepsによると2013年くらいはLinkedInでは1.6を使っていた、ということらしい。
順当に更新されている。

* https://issues.apache.org/jira/browse/KAFKA-7328
* https://sematext.com/opensee/m/Kafka/uyzND19j3Ec5wqz42?subj=Re+kafka+0+9+0+java+version
* https://sematext.com/opensee/m/Kafka/uyzND138NFX1w26SP1?subj=Re+java+version+for+kafka+clients



<!-- vim: set tw=0 ts=4 sw=4: -->
