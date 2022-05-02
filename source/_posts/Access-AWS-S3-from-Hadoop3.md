---
title: Access AWS S3 from Hadoop3 and Spark3
date: 2020-09-14 23:01:29
categories:
  - Knowledge Management
  - Hadoop
tags:
  - Hadoop
  - Spark
---

# 参考

* [Hadoopの公式ドキュメント]
* [Sparkの公式ドキュメント]

[Hadoopの公式ドキュメント]: https://hadoop.apache.org/docs/current/hadoop-aws/tools/hadoop-aws/index.html
[Sparkの公式ドキュメント]: https://spark.apache.org/docs/latest/cloud-integration.html


# メモ


## パッケージインポート

[Sparkの公式ドキュメント] には、org.apache.spark:hadoop-cloud_2.12を利用するよう記載されているが、
このMavenパッケージは見当たらなかった。

そこで、 [Hadoopの公式ドキュメント] の通り、hadoop-awsをインポートすると、それに関連した依存関係をインポートすることにした。
spark-shellで試すとしたら以下の通り。

```shell
$ /opt/spark/default/bin/spark-shell --packages org.apache.hadoop:hadoop-aws:3.2.0
```

## profileを使ったクレデンシャル設定

awscliを利用しているとしたら、profileを設定しながらクレデンシャルを使い分けていることもあると思う。
その場合、起動時の環境変数でプロフィールを指定しながら、以下のようにproviderを指定することで、
profileを利用したクレデンシャル管理の仕組みを利用してアクセスできる。

```shell
$ AWS_PROFILE=s3test /opt/spark/default/bin/spark-shell --packages org.apache.hadoop:hadoop-aws:3.2.0
```

```scala
scala> spark.sparkContext.hadoopConfiguration.set("fs.s3a.aws.credentials.provider", "com.amazonaws.auth.DefaultAWSCredentialsProviderChain")
```

### （補足）パラメータと指定するクラスについて

ちなみに、上記パラメータの説明には、

>    If unspecified, then the default list of credential provider classes,
>    queried in sequence, is:
>    1. org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider:
>       Uses the values of fs.s3a.access.key and fs.s3a.secret.key.
>    2. com.amazonaws.auth.EnvironmentVariableCredentialsProvider: supports
>        configuration of AWS access key ID and secret access key in
>        environment variables named AWS_ACCESS_KEY_ID and
>        AWS_SECRET_ACCESS_KEY, as documented in the AWS SDK.
>    3. com.amazonaws.auth.InstanceProfileCredentialsProvider: supports use
>        of instance profile credentials if running in an EC2 VM.

のように記載されている。

また、「Using Named Profile Credentials with ProfileCredentialsProvider」の節には、

> Declare com.amazonaws.auth.profile.ProfileCredentialsProvider as the provider.

と書かれており、上記Default...でなくても良い。（実際に試したところ動作した）


<!-- vim: set et tw=0 ts=2 sw=2: -->
