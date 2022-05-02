---

title: Getting started Spark on k8s
date: 2022-01-07 10:20:58
categories:
  - Knowledge Management
  - Spark
tags:
  - Apache Spark
  - Kubernetes

---

# メモ

このメモは、Spark3.2.0をKubernetes上で動かすことを簡単に紹介するものである。
なお、日本語での説明としては、 [Apache Spark on Kubernetes入門（Open Source Conference 2021 Online Hiroshima 発表資料）] がとても分かりやすいので参考になる。

## 基本的な流れ

公式の [Running Spark on Kubernetes] の通りでよい。

### ビルド

まずは、パッケージに含まれているDockerfileを利用して、Dockerイメージを自分でビルドする。
今回はMinikube環境で動かしているので `-m` オプションを利用した。

簡易的な例

```shell
$ /opt/spark/default/bin/docker-image-tool.sh -m -t testing build
```

Minikube内のDockerでイメージ一覧を確認すると以下の通り。

```shell
$ eval $(minikube -p minikube docker-env)
$ docker images
REPOSITORY                                TAG           IMAGE ID       CREATED          SIZE
spark                                     testing       e19cebbf23e7   44 minutes ago   602MB
(snip)
```

### クラスターモードで実行

サービスアカウントを作る。

```shell
$ minikube kubectl -- create serviceaccount spark
$ minikube kubectl -- create clusterrolebinding spark-role --clusterrole=edit --serviceaccount=default:spark --namespace=default
$ minikube kubectl -- get serviceaccount
NAME      SECRETS   AGE
default   1         179m
spark     1         2m39s
```

実行は以下の通り。先ほど作ったサービスアカウントを使用するようにする。

```shell
$ /opt/spark/default/bin/spark-submit --master k8s://https://192.168.49.2:8443 --deploy-mode cluster --name pi --class org.apache.spark.examples.SparkPi --conf spark.executor.instances=2 --conf spark.kubernetes.container.image=spark:testing --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark local:///opt/spark/examples/jars/spark-examples_2.12-3.2.0.jar
```

なお、今回はMinikube上で実行しており、Jarファイルとして指定するのはMinikube内で起動したドライバのコンテナ内のローカルファイルシステムパスである。試しに、当該近店をアタッチして起動するとわかる。

ドライバのログを確認する。

```shell
$ minikube kubectl -- logs pi-43bff77e450bdba3-driver
(snip)
22/01/10 17:32:02 INFO TaskSchedulerImpl: Killing all running tasks in stage 0: Stage finished
22/01/10 17:32:02 INFO DAGScheduler: Job 0 finished: reduce at SparkPi.scala:38, took 0.824388 s
Pi is roughly 3.142475712378562
22/01/10 17:32:02 INFO SparkUI: Stopped Spark web UI at http://pi-43bff77e450bdba3-driver-svc.default.svc:4040
22/01/10 17:32:02 INFO KubernetesClusterSchedulerBackend: Shutting down all executors
(snip)
```

pi計算の結果がログに出力されているのがわかる。

### クライアントモードで実行

[公式ドキュメントのClient Mode] でも記載されている通り、Clientモードで起動するにはいくつか選択肢がある。
ここではドライバ用のPodを立ち上げる方法を確認する。

```shell
$ minikube kubectl -- create deployment --image=spark:testing spark-client
```

headless serviceを利用し、エグゼキュータからドライバへのルートを作成する。

```shell
$ /opt/spark/default/bin/spark-submit --master k8s://https://192.168.49.2:8443 --deploy-mode client --name pi --class org.apache.spark.examples.SparkPi --conf spark.executor.instances=2 --conf spark.kubernetes.container.image=spark:testing --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark local:///opt/spark/default/examples/jars/spark-examples_2.12-3.2.0.jar
```

### （補足）ビルドされたイメージを起動して内容確認

以下は、MinikubeのDockerを利用しビルドしたイメージのコンテナを起動して、シェルをアタッチした例。

```shell
$ eval $(minikube -p minikube docker-env)
$ docker run -it --rm spark:testing /bin/bash
```

### （補足）Minikube使う場合のリソース設定についての注意事項

[Prerequisites] の通り、Minikube等を使うようであれば、リソースに対して注意がある。
以下、Minikube立ち上げ例。

```shell
$ minikube start --memory='4g' --cpus=3
```

## （補足）Kubernetes環境

動作確認のためには、Kubernetes環境が必要である。

[minikube start] あたりを参考に環境構築しておくこと。

## （補足）ボリュームのマウントについて

[volume-mounts] の通り、DriverやExecutorのPodにボリュームをマウントできるのだが、
HostPathに関するリスクがあるようだ。
[KubernetesのhostPathについて] を参照。

## （補足）上記例ではサービスアカウントを作成しているが・・・

もし `default` サービスアカウントを利用すると以下に記載されたのと同様のエラーを生じる。

[How to fix "Forbidden!Configured service account doesn't have access" with Spark on Kubernetes?]

そこで、あらかじめサービスアカウントを作成して使うようにした。

# 参考

* [Running Spark on Kubernetes]
* [volume-mounts]
* [KubernetesのhostPathについて]
* [minikube start]
* [Apache Spark on Kubernetes入門（Open Source Conference 2021 Online Hiroshima 発表資料）]
* [How to fix "Forbidden!Configured service account doesn't have access" with Spark on Kubernetes?]
* [Spark on Kubernetes Client Mode]
* [公式ドキュメントのClient Mode]

[Running Spark on Kubernetes]: https://spark.apache.org/docs/latest/running-on-kubernetes.html
[volume-mounts]: https://spark.apache.org/docs/latest/running-on-kubernetes.html#volume-mounts
[Prerequisites]: https://spark.apache.org/docs/latest/running-on-kubernetes.html#prerequisites
[KubernetesのhostPathについて]: https://kubernetes.io/docs/concepts/storage/volumes/#hostpath
[minikube start]: https://minikube.sigs.k8s.io/docs/start/

[Apache Spark on Kubernetes入門（Open Source Conference 2021 Online Hiroshima 発表資料）]: https://www.slideshare.net/nttdata-tech/apache-spark-kubernetes-osc2021-online-hiroshima-nttdata

[How to fix "Forbidden!Configured service account doesn't have access" with Spark on Kubernetes?]: https://stackoverflow.com/questions/55498702/how-to-fix-forbiddenconfigured-service-account-doesnt-have-access-with-spark

[Spark on Kubernetes Client Mode]: https://www.back2code.me/2018/12/spark-on-kubernetes-client-mode/

[公式ドキュメントのClient Mode]: https://spark.apache.org/docs/latest/running-on-kubernetes.html#client-mode

<!-- vim: set et tw=0 ts=2 sw=2: -->
