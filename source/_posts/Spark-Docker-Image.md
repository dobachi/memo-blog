---

title: Spark Docker Image
date: 2019-08-24 20:51:44
categories:
  - Knowledge Management
  - Spark
tags:
  - Spark
  - Docker

---

# 参考

* [Running Spark on Kubernetes]
* [Docker Images]
* [dockerhubのopenjdk]
* [DockerhubのAnacondaのDockerfile]
* [GitHub上のAlpine版のAnaconda公式Dockerfile]
* [GitHub上のDebianベースのOpenJDK Dockerfile]

[Running Spark on Kubernetes]: https://spark.apache.org/docs/2.4.3/running-on-kubernetes.html
[Docker Images]: https://spark.apache.org/docs/2.4.3/running-on-kubernetes.html#docker-images
[dockerhubのopenjdk]: https://hub.docker.com/_/openjdk
[DockerhubのAnacondaのDockerfile]: https://hub.docker.com/r/continuumio/anaconda/dockerfile
[GitHub上のAlpine版のAnaconda公式Dockerfile]: https://github.com/ContinuumIO/docker-images/blob/master/anaconda3/alpine/Dockerfile
[GitHub上のDebianベースのOpenJDK Dockerfile]: https://github.com/docker-library/openjdk/blob/master/8/jdk/Dockerfile

# メモ

## Spark公式のDockerfileを活用

Spark公式ドキュメントの [Running Spark on Kubernetes] 内にある [Docker Images] によると、
SparkにはDockerfileが含まれている。

以下のパッケージで確認。
```
$ cat RELEASE
Spark 2.4.3 built for Hadoop 2.7.3
Build flags: -B -Pmesos -Pyarn -Pkubernetes -Pflume -Psparkr -Pkafka-0-8 -Phadoop-2.7 -Phive -Phive-thriftserver -DzincPort=3036
```

Dockerfileは、パッケージ内の `kubernetes/dockerfiles/spark/Dockerfile` に存在する。
また、これを利用した `bin/docker-image-tool.sh` というスクリプトが存在し、
Dockerイメージをビルドして、プッシュできる。
今回はこのスクリプトを使ってみる。

ヘルプを見ると以下の通り。
```
$ ./bin/docker-image-tool.sh --help
Usage: ./bin/docker-image-tool.sh [options] [command]
Builds or pushes the built-in Spark Docker image.

Commands:
  build       Build image. Requires a repository address to be provided if the image will be
              pushed to a different registry.
  push        Push a pre-built image to a registry. Requires a repository address to be provided.

Options:
  -f file               Dockerfile to build for JVM based Jobs. By default builds the Dockerfile shipped with Spark.
  -p file               Dockerfile to build for PySpark Jobs. Builds Python dependencies and ships with Spark.
  -R file               Dockerfile to build for SparkR Jobs. Builds R dependencies and ships with Spark.
  -r repo               Repository address.
  -t tag                Tag to apply to the built image, or to identify the image to be pushed.
  -m                    Use minikube's Docker daemon.
  -n                    Build docker image with --no-cache
  -b arg      Build arg to build or push the image. For multiple build args, this option needs to
              be used separately for each build arg.

Using minikube when building images will do so directly into minikube's Docker daemon.
There is no need to push the images into minikube in that case, they'll be automatically
available when running applications inside the minikube cluster.

Check the following documentation for more information on using the minikube Docker daemon:

  https://kubernetes.io/docs/getting-started-guides/minikube/#reusing-the-docker-daemon

Examples:
  - Build image in minikube with tag "testing"
    ./bin/docker-image-tool.sh -m -t testing build

  - Build and push image with tag "v2.3.0" to docker.io/myrepo
    ./bin/docker-image-tool.sh -r docker.io/myrepo -t v2.3.0 build
    ./bin/docker-image-tool.sh -r docker.io/myrepo -t v2.3.0 push
```

つづいて最新版Sparkのバージョンをタグ付けて試す。
```
$ sudo ./bin/docker-image-tool.sh -r docker.io/dobachi -t v2.4.3 build
$ sudo ./bin/docker-image-tool.sh -r docker.io/dobachi -t v2.4.3 push
```

これは成功。
早速起動して試してみる。
なお、Sparkのパッケージは、 `/opt/spark` 以下に含まれている。

```
$ sudo docker run --rm -it dobachi/spark:v2.4.3 /bin/bash

(snip)

bash-4.4# /opt/spark/bin/spark-shell  

(snip)

Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 2.4.3
      /_/

Using Scala version 2.11.12 (OpenJDK 64-Bit Server VM, Java 1.8.0_212) 
Type in expressions to have them evaluated.
Type :help for more information.

scala>  
```

データを軽く読み込んでみる。
```
scala> val path = "/opt/spark/data/mllib/kmeans_data.txt"
scala> val textFile = spark.read.textFile(path)
scala> textFile.first
res1: String = 0.0 0.0 0.0

scala> textFile.count
res2: Long = 6

scala> val csvLike = spark.read.format("csv").
         option("sep", " ").
         option("inferSchema", "true").
         option("header", "false").
         load(path)

scala> csvLike.show
+---+---+---+
|_c0|_c1|_c2|
+---+---+---+
|0.0|0.0|0.0|
|0.1|0.1|0.1|
|0.2|0.2|0.2|
|9.0|9.0|9.0|
|9.1|9.1|9.1|
|9.2|9.2|9.2|
+---+---+---+

scala> csvLike.where($"_c0" > 5).show
+---+---+---+
|_c0|_c1|_c2|
+---+---+---+
|9.0|9.0|9.0|
|9.1|9.1|9.1|
|9.2|9.2|9.2|
+---+---+---+
```

なお、PySparkが含まれているのは、違うレポジトリであり、 `dobachi/spark-py` を用いる必要がある。

```
$ sudo docker run --rm -it dobachi/spark-py:v2.4.3 /bin/bash

(snip)

bash-4.4# /opt/spark/bin/pyspark 
Python 2.7.16 (default, May  6 2019, 19:35:26) 
[GCC 8.3.0] on linux2
Type "help", "copyright", "credits" or "license" for more information.
Could not open PYTHONSTARTUP
IOError: [Errno 2] No such file or directory: '/opt/spark/python/pyspark/shell.py'
>>>
```

この状態だと、OS標準付帯のPythonのみ使える状態に見えた。
実用を考えると、もう少し分析用途のPythonライブラリを整えた方が良さそう。

## Anaconda等も利用するとして？

上記の通り、Spark公式のDockerfileで作るDockerイメージには、Python関係の分析用のライブラリ、ツールが不足している。
そこでこれを補うために、Anaconda等を利用しようとするとして、パッと見でほんの少し議論なのは、
なにをベースにするかという点。

* 上記で紹介したSparkに含まれるDockerfileおよび [dockerhubのopenjdk] に記載の通り、当該DockerイメージはAlpine Linuxをベースとしている。
  ただし、OpenJDKのDockerイメージ自体には、 [GitHub上のDebianベースのOpenJDK Dockerfile] がある。
* AnacondaのDockerイメージは、 [DockerhubのAnacondaのDockerfile] の通り、Debianをベースとしている。
  しかし、 [GitHub上のAlpine版のAnaconda公式Dockerfile] によるとAlpine Linux版もありそう。

どっちに合わせるか悩むところだが、Debianベースに置き換えでも良いか、という気持ちではある。
Debianベースのほうが慣れているという気持ちもあり。

また、Anacondaを合わせて導入するようにしたら、環境変数 `PYSPARK_PYTHON` も設定しておいたほうが良さそう。

<!-- vim: set tw=0 ts=4 sw=4: -->
