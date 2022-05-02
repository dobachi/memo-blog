---

title: Create BigTop environment on Docker
date: 2019-02-07 23:43:04
categories:
  - Knowledge Management
  - Hadoop
  - BigTop
tags:
  - BigTop
  - Hadoop

---

# 参考

* [公式の手順]
* [Dockerでのクラスタ構築を紹介するブログ]

[公式の手順]: https://github.com/apache/bigtop/tree/master/provisioner/docker 
[Dockerでのクラスタ構築を紹介するブログ]: https://qiita.com/sekikn/items/18954e9b302c38eb5b55

# メモ

[Dockerでのクラスタ構築を紹介するブログ] と [公式の手順] を参考に試した。
基本的には、前者のブログの記事通りで問題ない。

## Sparkも試す

以下のようにコンポーネントに追加してプロビジョニングするとSparkも使えるようになる。

```
diff --git a/provisioner/docker/config_centos-7.yaml b/provisioner/docker/config_centos-7.yaml
index 49f86aee..0f611a10 100644
--- a/provisioner/docker/config_centos-7.yaml
+++ b/provisioner/docker/config_centos-7.yaml
@@ -19,6 +19,6 @@ docker:

 repo: "http://repos.bigtop.apache.org/releases/1.3.0/centos/7/$basearch"
 distro: centos
-components: [hdfs, yarn, mapreduce]
+components: [hdfs, yarn, mapreduce, spark]
 enable_local_repo: false
-smoke_test_components: [hdfs, yarn, mapreduce]
+smoke_test_components: [hdfs, yarn, mapreduce, spark]
```
