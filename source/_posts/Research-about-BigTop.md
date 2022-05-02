---

title: Research about BigTop
date: 2020-04-24 21:51:36
categories:
  - Knowledge Management
  - Hadoop
  - BigTop
tags:
  - BigTop

---

# 参考

* [公式Wikiトップページ]
* [How to build Bigtop-trunk]
* [reuse_images]
* [Deployment and Integration Testing]
* [Dockerベースのデプロイ方法]
* [Puppetベースのデプロイ方法]

[公式Wikiトップページ]: https://cwiki.apache.org/confluence/display/BIGTOP/Index
[How to build Bigtop-trunk]: https://cwiki.apache.org/confluence/display/BIGTOP/How+to+build+Bigtop-trunk
[reuse_images]: https://github.com/dobachi/bigtop/tree/reuse_images
[Deployment and Integration Testing]: https://cwiki.apache.org/confluence/display/BIGTOP/Deployment+and+Integration+Testing
[Dockerベースのデプロイ方法]: https://cwiki.apache.org/confluence/display/BIGTOP/Bigtop+Provisioner+User+Guide
[Puppetベースのデプロイ方法]: https://github.com/apache/bigtop/blob/master/bigtop-deploy/puppet/README.md
[BIGTOP-3123]: https://issues.apache.org/jira/browse/BIGTOP-3123

# メモ

## Trunkのビルド方法

[How to build Bigtop-trunk] を見ると、現在ではDocker上でビルドする方法が推奨されているようだ。
ただ、

```shell
# ./gradlew spark-pkg-ind
```
で実行されるとき、都度Mavenキャッシュのない状態から開始される。
これが待ち時間長いので工夫が必要。


なお、上記コマンドで実行されるタスクは、以下の通り。

packages.gradle:629

```gradle
  task "$target-pkg-ind" (
          description: "Invoking a native binary packaging for $target in Docker. Usage: \$ ./gradlew " +
                  "-POS=[centos-7|fedora-26|debian-9|ubuntu-16.04|opensuse-42.3] " +
                  "-Pprefix=[trunk|1.2.1|1.2.0|1.1.0|...] $target-pkg-ind " +
                  "-Pnexus=[true|false]",
          group: PACKAGES_GROUP) doLast {
    def _prefix = project.hasProperty("prefix") ? prefix : "trunk"
(snip)

```

`bigtop-ci/build.sh` がタスク内で実行されるスクリプトである。
この中でDockerが呼び出されてビルドが実行される。

これをいじれば、一応ビルド時に使ったDockerコンテナを残すことができそうではある。

-> [reuse_images] というブランチに、コンテナンをリユースする機能をつけた。

## デプロイ周りを読み解いてみる

[Deployment and Integration Testing] を見る限り、 [Dockerベースのデプロイ方法] と 
[Puppetベースのデプロイ方法] があるように見える。

### Dockerベースのデプロイを試す

[Dockerベースのデプロイ方法] に従って、Dockerベースでデプロイしてみる。
ソースコードは20200427時点でのmasterを利用。

Ubuntu16でDocker、Java、Ruby環境を整え、以下を実行した。

```shell
$ sudo ./gradlew -Pconfig=config_ubuntu-16.04.yaml -Pnum_instances=1 docker-provisioner
```

なお、20200427時点で [Dockerベースのデプロイ方法] ではコンフィグファイルが `config_ubuntu_xenial.yaml` となっていたが、
BIGTOP-2814 の際に変更されたのに合わせた。

プロビジョニング完了後、コンテナを確認し、接続。

```shell
$ sudo docker ps
CONTAINER ID        IMAGE                              COMMAND             CREATED             STATUS              PORTS               NAMES
7311ae86181a        bigtop/puppet:trunk-ubuntu-16.04   "/sbin/init"        4 minutes ago       Up 4 minutes                            20200426_151302_r30103_bigtop_1
$ sudo docker exec -it 20200426_151302_r30103_bigtop_1 bash
```

以下のように `hdfs` コマンドを実行できることがわかる。

```shell
root@7311ae86181a:/# hdfs dfs -ls /
Found 7 items
drwxr-xr-x   - hdfs  hadoop          0 2020-04-26 15:15 /apps
drwxrwxrwx   - hdfs  hadoop          0 2020-04-26 15:15 /benchmarks
drwxr-xr-x   - hbase hbase           0 2020-04-26 15:15 /hbase
drwxr-xr-x   - solr  solr            0 2020-04-26 15:15 /solr
drwxrwxrwt   - hdfs  hadoop          0 2020-04-26 15:15 /tmp
drwxr-xr-x   - hdfs  hadoop          0 2020-04-26 15:15 /user
drwxr-xr-x   - hdfs  hadoop          0 2020-04-26 15:15 /var
```

なお、 `-Pnum_instances=1` の値を3に変更すると、コンテナが3個立ち上がる。

```shell
$ sudo ./gradlew -Pconfig=config_ubuntu-16.04.yaml -Pnum_instances=3 docker-provisioner
```

試しに、`dfsadmin` を実行してみる。


```shell
root@53211353deec:/# sudo -u hdfs hdfs dfsadmin -report
Configured Capacity: 374316318720 (348.61 GB)
Present Capacity: 345302486224 (321.59 GB)
DFS Remaining: 345300606976 (321.59 GB)
DFS Used: 1879248 (1.79 MB)
DFS Used%: 0.00%
Under replicated blocks: 0
Blocks with corrupt replicas: 0
Missing blocks: 0
Missing blocks (with replication factor 1): 0
Pending deletion blocks: 0

-------------------------------------------------
Live datanodes (3):

Name: 172.17.0.2:50010 (53211353deec.bigtop.apache.org)
Hostname: 53211353deec.bigtop.apache.org
Decommission Status : Normal
Configured Capacity: 124772106240 (116.20 GB)
DFS Used: 626416 (611.73 KB)
Non DFS Used: 9637679376 (8.98 GB)
DFS Remaining: 115100246016 (107.20 GB)
DFS Used%: 0.00%
DFS Remaining%: 92.25%
Configured Cache Capacity: 0 (0 B)
Cache Used: 0 (0 B)
Cache Remaining: 0 (0 B)
Cache Used%: 100.00%
Cache Remaining%: 0.00%
Xceivers: 1
Last contact: Sun Apr 26 15:33:12 UTC 2020

(snip)
```

また、 `--stack` オプションを利用し、デプロイするコンポーネントを指定できる。
ここではHadoopに加え、Sparkをプロビジョニングしてみる。

```shell
$ sudo ./gradlew -Pconfig=config_ubuntu-16.04.yaml -Pstack=hdfs,yarn,spark -Pnum_instances=1 docker-provisioner
```

コンテナに接続し、Sparkを動かす。

```shell
$ sudo docker ps
CONTAINER ID        IMAGE                              COMMAND             CREATED             STATUS              PORTS               NAMES
56e1ff5670be        bigtop/puppet:trunk-ubuntu-16.04   "/sbin/init"        3 minutes ago       Up 3 minutes                            20200426_155010_r21667_bigtop_1
$ sudo docker exec -it 20200426_155010_r21667_bigtop_1 bash
```

```shell
root@56e1ff5670be:/# spark-shell
scala> spark.sparkContext.master
res1: String = yarn
```

上記のように、マスタ=YARNで起動していることがわかる。
参考までに、 `spark-env.sh` は以下の通り。

```shell
root@56e1ff5670be:/# cat /etc/spark/conf/spark-env.sh
export SPARK_HOME=${SPARK_HOME:-/usr/lib/spark}
export SPARK_LOG_DIR=${SPARK_LOG_DIR:-/var/log/spark}
export SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=NONE"
export HADOOP_HOME=${HADOOP_HOME:-/usr/lib/hadoop}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-/etc/hadoop/conf}
export HIVE_CONF_DIR=${HIVE_CONF_DIR:-/etc/hive/conf}

export STANDALONE_SPARK_MASTER_HOST=56e1ff5670be.bigtop.apache.org
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_IP=$STANDALONE_SPARK_MASTER_HOST
export SPARK_MASTER_URL=yarn
export SPARK_MASTER_WEBUI_PORT=8080

export SPARK_WORKER_DIR=${SPARK_WORKER_DIR:-/var/run/spark/work}
export SPARK_WORKER_PORT=7078
export SPARK_WORKER_WEBUI_PORT=8081

export SPARK_DIST_CLASSPATH=$(hadoop classpath)
```

なお、構築したクラスタを破棄する際には以下の通り。（公式ドキュメントの通り）

```shell
$ sudo ./gradlew docker-provisioner-destroy
```

#### 仕様確認

上記のプロビジョナのタスクは、 `build.gradle` 内にある。

build.gradle:263

```gracle
task "docker-provisioner"(type:Exec,

(snip)
```

上記の中で、 `./docker-hadoop.sh` が用いられている。

build.gradle:296

```gradle
  def command = [
      './docker-hadoop.sh',
      '-C', _config,
      '--create', _num_instances,
  ]
```

`--create` オプションが用いられているので、 `create` 関数が呼ばれる。

provisioner/docker/docker-hadoop.sh:387

```shell
if [ "$READY_TO_LAUNCH" = true ]; then
    create $NUM_INSTANCES
fi
```

`create` 内では、以下のように `docker-compose` が用いられている。

provisioner/docker/docker-hadoop.sh:78

```shell
    docker-compose -p $PROVISION_ID up -d --scale bigtop=$1 --no-recreate
```

また、コンポーネントの内容に応じて、Puppetマニフェスト（正確には、hieraファイル）が生成されるようになっている。

provisioner/docker/docker-hadoop.sh:101

```shell
    generate-config "$hadoop_head_node" "$repo" "$components"
```

また、最終的には、 `provision` 関数、さらに `bigtop-puppet` 関数を通じ、各コンテナ内でpuppetが実行されるようになっている。

```gradle
bigtop-puppet() {
    if docker exec $1 bash -c "puppet --version" | grep ^3 >/dev/null ; then
      future="--parser future"
    fi
    docker exec $1 bash -c "puppet apply --detailed-exitcodes $future --modulepath=/bigtop-home/bigtop-deploy/puppet/modules:/etc/puppet/modules:/usr/share/puppet/modules /bigtop-home/bigtop-deploy/puppet/manifests"
}
```


### Ambariのモジュールを確認する。

`bigtop-deploy/puppet/modules/ambari/manifests/init.pp` にAmbariデプロイ用のモジュールがある。

内容は短い。

```puppet
class ambari {

  class deploy ($roles) {
    if ("ambari-server" in $roles) {
      include ambari::server
    }

    if ("ambari-agent" in $roles) {
      include ambari::agent
    }
  }

  class server {
    package { "ambari-server":
      ensure => latest,
    }

    exec {
        "mpack install":
           command => "/bin/bash -c 'echo yes | /usr/sbin/ambari-server install-mpack --purge --verbose --mpack=/var/lib/ambari-server/resources/odpi-ambari-mpack-1.0.0.0-SNAPSHOT.tar.gz'",
           require => [ Package["ambari-server"] ]
    }

    exec {
        "server setup":
           command => "/usr/sbin/ambari-server setup -j $(readlink -f /usr/bin/java | sed 's@jre/bin/java@@') -s",
           require => [ Package["ambari-server"], Package["jdk"], Exec["mpack install"] ]
    }

    service { "ambari-server":
        ensure => running,
        require => [ Package["ambari-server"], Exec["server setup"] ],
        hasrestart => true,
        hasstatus => true,
    }
  }

  class agent($server_host = "localhost") {
    package { "ambari-agent":
      ensure => latest,
    }

    file {
      "/etc/ambari-agent/conf/ambari-agent.ini":
        content => template('ambari/ambari-agent.ini'),
        require => [Package["ambari-agent"]],
    }

    service { "ambari-agent":
        ensure => running,
        require => [ Package["ambari-agent"], File["/etc/ambari-agent/conf/ambari-agent.ini"] ],
        hasrestart => true,
        hasstatus => true,
    }
  }
}
```

なお、上記の通り、サーバとエージェントそれぞれのマニフェストが存在する。
ODPiのMpackをインストールしているのが特徴。

逆にいうと、それをインストールしないと使えるVersionが存在しない。（ベンダ製のVDFを読み込めば使えるが）
また、ODPiのMpackをインストールした上でクラスタを構成しようとしたところ、
ODPiのレポジトリが見当たらなかった。
プライベートレポジトリを立てる必要があるのだろうか。

いったん、公式のAmbariをインストールした上で動作確認することにする。

## ホットIssue

[BIGTOP-3123] が1.5リリース向けのIssue
