---
title: Install Bigtop RPMs using Yum
date: 2020-07-21 22:50:06
categories:
tags:
---

# 参考

* [Apache Bigtop 1.4.0のパッケージバージョン]
* [レポジトリ関連の資材置き場]
* [CentOS7のbigtop.repo]

[Apache Bigtop 1.4.0のパッケージバージョン]: https://cwiki.apache.org/confluence/display/BIGTOP/Bigtop+1.4.0+Release
[レポジトリ関連の資材置き場]: https://downloads.apache.org/bigtop/
[CentOS7のbigtop.repo]: https://downloads.apache.org/bigtop/bigtop-1.4.0/repos/centos7/bigtop.repo

# メモ

今回は、2020/7/21時点の最新バージョンである [Apache Bigtop 1.4.0のパッケージバージョン] の
Hadoopをインストールできるかどうかを試してみることとする。

Yumのrepoファイルは [レポジトリ関連の資材置き場] 以下にある。
例えば、今回はCentOS7を利用することにするので、 [CentOS7のbigtop.repo] あたりを利用する。

```shell
$ cd /etc/yum.repos.d
$ sudo wget https://downloads.apache.org/bigtop/bigtop-1.4.0/repos/centos7/bigtop.repo
```

ひとまずパッケージが見つかるかどうか、確認。

```shell
$ sudo yum search hadoop-conf-pseudo
読み込んだプラグイン:fastestmirror
Loading mirror speeds from cached hostfile
 * base: d36uatko69830t.cloudfront.net
 * epel: d2lzkl7pfhq30w.cloudfront.net
 * extras: d36uatko69830t.cloudfront.net
 * updates: d36uatko69830t.cloudfront.net
=========================================== N/S matched: hadoop-conf-pseudo ============================================
hadoop-conf-pseudo.x86_64 : Pseudo-distributed Hadoop configuration
```

確認できたので、試しにインストール。

```shell
$ sudo yum install hadoop-conf-pseudo
```

自分の手元の環境では、依存関係で以下のパッケージがインストールされた。

```
========================================================================================================================
 Package                                    アーキテクチャー   バージョン                      リポジトリー        容量
========================================================================================================================
インストール中:
 hadoop-conf-pseudo                         x86_64             2.8.5-1.el7                     bigtop              20 k
依存性関連でのインストールをします:
 at                                         x86_64             3.1.13-24.el7                   base                51 k
 bc                                         x86_64             1.06.95-13.el7                  base               115 k
 bigtop-groovy                              noarch             2.4.10-1.el7                    bigtop             9.8 M
 bigtop-jsvc                                x86_64             1.0.15-1.el7                    bigtop              29 k
 bigtop-utils                               noarch             1.4.0-1.el7                     bigtop              11 k
 cups-client                                x86_64             1:1.6.3-43.el7                  base               152 k
 ed                                         x86_64             1.9-4.el7                       base                72 k
 hadoop                                     x86_64             2.8.5-1.el7                     bigtop              24 M
 hadoop-hdfs                                x86_64             2.8.5-1.el7                     bigtop              24 M
 hadoop-hdfs-datanode                       x86_64             2.8.5-1.el7                     bigtop             5.7 k
 hadoop-hdfs-namenode                       x86_64             2.8.5-1.el7                     bigtop             5.8 k
 hadoop-hdfs-secondarynamenode              x86_64             2.8.5-1.el7                     bigtop             5.8 k
 hadoop-mapreduce                           x86_64             2.8.5-1.el7                     bigtop              34 M
 hadoop-mapreduce-historyserver             x86_64             2.8.5-1.el7                     bigtop             5.8 k
 hadoop-yarn                                x86_64             2.8.5-1.el7                     bigtop              20 M
 hadoop-yarn-nodemanager                    x86_64             2.8.5-1.el7                     bigtop             5.7 k
 hadoop-yarn-resourcemanager                x86_64             2.8.5-1.el7                     bigtop             5.6 k
 libpcap                                    x86_64             14:1.5.3-12.el7                 base               139 k
 m4                                         x86_64             1.4.16-10.el7                   base               256 k
 mailx                                      x86_64             12.5-19.el7                     base               245 k
 nmap-ncat                                  x86_64             2:6.40-19.el7                   base               206 k
 patch                                      x86_64             2.7.1-12.el7_7                  base               111 k
 psmisc                                     x86_64             22.20-16.el7                    base               141 k
 redhat-lsb-core                            x86_64             4.1-27.el7.centos.1             base                38 k
 redhat-lsb-submod-security                 x86_64             4.1-27.el7.centos.1             base                15 k
 spax                                       x86_64             1.5.2-13.el7                    base               260 k
 time                                       x86_64             1.7-45.el7                      base                30 k
 zookeeper                                  x86_64             3.4.6-1.el7                     bigtop             7.0 M
```

initスクリプトがインストールされていることがわかる。

```shell
$ ls -1 /etc/init.d/
README
functions
hadoop-hdfs-datanode
hadoop-hdfs-namenode
hadoop-hdfs-secondarynamenode
hadoop-mapreduce-historyserver
hadoop-yarn-nodemanager
hadoop-yarn-resourcemanager
netconsole
network
```

ひとまずHDFSをフォーマット。

```shell
$ sudo -u hdfs hdfs namenode -format
```

あとは、上記の各種Hadoopサービスを立ち上げれば良い。


<!-- vim: set et tw=0 ts=2 sw=2: -->
