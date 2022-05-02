---

title: Crucial implementation
date: 2020-01-21 22:00:27
categories:
  - Knowledge Management
  - Machine Learning
  - Crucial
tags:
  - FaaS
  - AWS Lambda
  - Apache Spark

---

# 参考

* [crucial-dso]
* [crucial-examples]
* [usage]
* [On the FaaS Track Building Stateful Distributed Applications with Serverless Architectures]

[crucial-dso]: https://github.com/danielBCN/crucial-dso
[usage]: https://github.com/danielBCN/crucial-dso#usage
[crucial-examples]: https://github.com/danielBCN/crucial-examples
[On the FaaS Track Building Stateful Distributed Applications with Serverless Architectures]: https://dl.acm.org/doi/10.1145/3361525.3361535

# メモ

## コンパイル

[usage] の通り、コンパイルし、 `mvn install` しようとしたところ、
エラーが生じた。

```
Caused by: org.apache.maven.plugin.checkstyle.exec.CheckstyleExecutorException: There are 4 errors reported by Checkstyle 6.11.2 with checkstyle.xml ruleset.
```

```
<?xml version="1.0" encoding="UTF-8"?>
<checkstyle version="6.11.2">
<file name="/home/ubuntu/Sources/crucial-dso/client/src/main/java/org/infinispan/crucial/CrucialClient.java">
</file>
<file name="/home/ubuntu/Sources/crucial-dso/client/src/main/java/org/infinispan/crucial/CAtomicBoolean.java">
<error line="3" severity="error" message="Using the &apos;.*&apos; form of import should be avoided - java.io.*." source="com.puppycrawl.tools.checkstyle.checks.imports.AvoidStarImportCheck"/>
</file>
<file name="/home/ubuntu/Sources/crucial-dso/client/src/main/java/org/infinispan/crucial/CFuture.java">
</file>
<file name="/home/ubuntu/Sources/crucial-dso/client/src/main/java/org/infinispan/crucial/CAtomicInt.java">
<error line="4" severity="error" message="Using the &apos;.*&apos; form of import should be avoided - java.io.*." source="com.puppycrawl.tools.checkstyle.checks.imports.AvoidStarImportCheck"/>
</file>
<file name="/home/ubuntu/Sources/crucial-dso/client/src/main/java/org/infinispan/crucial/CSemaphore.java">
</file>
<file name="/home/ubuntu/Sources/crucial-dso/client/src/main/java/org/infinispan/crucial/CAtomicByteArray.java">
<error line="3" severity="error" message="Using the &apos;.*&apos; form of import should be avoided - java.io.*." source="com.puppycrawl.tools.checkstyle.checks.imports.AvoidStarImportCheck"/>
</file>
<file name="/home/ubuntu/Sources/crucial-dso/client/src/main/java/org/infinispan/crucial/CAtomicLong.java">
<error line="4" severity="error" message="Using the &apos;.*&apos; form of import should be avoided - java.io.*." source="com.puppycrawl.tools.checkstyle.checks.imports.AvoidStarImportCheck"/>
</file>
<file name="/home/ubuntu/Sources/crucial-dso/client/src/main/java/org/infinispan/crucial/CLogger.java">
</file>
<file name="/home/ubuntu/Sources/crucial-dso/client/src/main/java/org/infinispan/crucial/CCyclicBarrier.java">
</file>
<file name="/home/ubuntu/Sources/crucial-dso/client/src/test/java/org/infinispan/crucial/test/CrucialClientTest.java">
</file>
</checkstyle>
```

上記エラーを修正し、 `mvn install` でパッケージを作成した。
パッケージを/tmp以下に展開し、ドキュメント通りその中のjgroups-ec2.xmlを修正。
`server.sh -vpc` でサーバを起動しようとした。

```
ubuntu@ubuec2:/tmp/crucial-dso-server-9.0.3.Final$ ./server.sh -vpc
AWS EC2 VPC mode
14:48:07,902 WARN  (main) [DefaultCacheManager] ISPN000435: Cache manager initialized with a default cache configuration but without a name for it. Set it in the GlobalConfiguration.
14:48:08,230 INFO  (main) [JGroupsTransport] ISPN000078: Starting JGroups channel crucial-cluster
14:48:08,419 DEBUG (main) [Configurator] set property TCP.diagnostics_addr to default value /xx.xx.xx.xx
14:48:08,424 DEBUG (main) [TCP] thread pool min/max/keep-alive: 0/200/60000 use_fork_join=false, internal pool: 0/4/30000 (4 cores available)
14:48:08,683 DEBUG (main) [GMS] address=crucial-server-xx.x.x.xx-xx, cluster=crucial-cluster, physical address=xx.xx.xx.xx:7800
14:48:08,731 DEBUG (main) [NAKACK2]
[crucial-server-xx.xx.xx.xx-xxxxx setDigest()]
existing digest:  []
new digest:       crucial-server-xx.xx.xx.xx-xxxxx: [0 (0)]
resulting digest: crucial-server-xx.xx.xx.xx-xxxxx: [0 (0)]
14:48:08,731 DEBUG (main) [GMS] crucial-server-xx.xx.xx.xx-xxxxx: installing view [crucial-server-xx.xx.xx.xx-xxxxx|0] (1) [crucial-server-xx.xx.xx.xx-xxxxx]
14:48:08,733 DEBUG (main) [STABLE] resuming message garbage collection
14:48:08,776 INFO  (main) [JGroupsTransport] ISPN000094: Received new cluster view for channel crucial-cluster: [crucial-server-xx.xx.xx.xx-xxxxx|0] (1) [crucial-server-xx.xx.xx.xx-xxxxx]
14:48:08,779 DEBUG (main) [STABLE] resuming message garbage collection
14:48:08,779 DEBUG (main) [GMS] crucial-server-xx.xx.xx.xx-xxxxx: created cluster (first member). My view is [crucial-server-xx.xx.xx.xx-xxxxx|0], impl is org.jgroups.protocols.pbcast.CoordGmsImpl
14:48:08,779 INFO  (main) [JGroupsTransport] ISPN000079: Channel crucial-cluster local address is crucial-server-xx.xx.xx.xx-xxxxx, physical addresses are [xx.xx.xx.xx:7800]
14:48:08,783 INFO  (main) [GlobalComponentRegistry] ISPN000128: Infinispan version: Infinispan 'Ruppaner' 9.0.3.Final
14:48:09,034 INFO  (main) [Factory] Factory[Cache '__crucial'@crucial-server-xx.xx.xx.xx-xxxxx] Created
14:48:09,034 INFO  (main) [Factory] AOF singleton  is Factory[Cache '__crucial'@crucial-server-xx.xx.xx.xx-xxxxx]
14:48:09,094 WARN  (main) [DefaultCacheManager] ISPN000434: Direct usage of the ___defaultcache name to retrieve the default cache is deprecated
LAUNCHED
```



<!-- vim: set et tw=0 ts=2 sw=2: -->
