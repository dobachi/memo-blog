---

title: TensorFlowOnSparkを動作させてみる例
date: 2018-11-18 21:11:42
categories:
  - Research
  - Machine Learning
  - TensorFlow
tags:
  - TensorFlow
  - Spark
  - PySpark

---

# 参考

* [YahooのGitHub] 
* [YahooのGitHubのwiki]

[YahooのGitHub]: https://github.com/yahoo/TensorFlowOnSpark
[YahooのGitHubのwiki]: https://github.com/yahoo/TensorFlowOnSpark/wiki/GetStarted_YARN

# 前提

## HadoopとSpark

ここではHadoopクラスタ（YARN）がデプロイされ、Sparkを起動できる状態になっているものとする。
自分の手元では、HDPを使いAmbariで`hadoop_2_6_5_0_292-2.7.3.2.6.5.0-292.x86_64`をインストールした状態とした。

## TensorFlow

ここではスレーブノードにTensowFlowとTensorFlowOnSparkのインストールされたPython環境があるものとして進める。
自分の手元では、Anacondaを使って環境構築し、`conda create`で構築した環境上に上記パッケージをインストールしておいた。
また、OS標準とは異なるPythonを使用するため、PySpark実行時には、以下のようにオプションを指定することとする。

```
$ pyspark --master yarn --conf spark.pyspark.python=/usr/local/anacondace2/default/envs/tf/bin/python --conf spark.pyspark.driver.python=/usr/local/anacondace2/default/envs/tf/bin/ipython
```

# 手順

基本的には、[YahooのGitHubのwiki]の内容を参考に進める。

```
$ cd
$ mkdir mnist
$ pushd mnist >/dev/null
$ curl -O "http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz"
$ curl -O "http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz"
$ curl -O "http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz"
$ curl -O "http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz"
$ zip -r mnist.zip *
$ popd >/dev/null
```

TFonSparkのソースコードをクローンしておく。

```
git clone https://github.com/yahoo/TensorFlowOnSpark.git
```

「Convert the MNIST zip files into HDFS files」の箇所では、以下のような
シェルスクリプトを書いて`source`しておいた。

```
# set environment variables (if not already done)
export PYTHON_ROOT=/usr/local/anacondace2/default/envs/tf
export LD_LIBRARY_PATH=${PATH}
export PYSPARK_PYTHON=${PYTHON_ROOT}/bin/python
export SPARK_YARN_USER_ENV="PYSPARK_PYTHON="${PYTHON_ROOT}"/bin/python"
export PATH=${PYTHON_ROOT}/bin/:$PATH
#export QUEUE=gpu
export QUEUE=default

# set paths to libjvm.so, libhdfs.so, and libcuda*.so
#export LIB_HDFS=/opt/cloudera/parcels/CDH/lib64                      # for CDH (per @wangyum)
export LIB_HDFS=/usr/hdp/2.6.5.0-292/usr/lib              # path to libhdfs.so, for TF acccess to HDFS
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.191.b12-0.el7_5.x86_64
export LIB_JVM=$JAVA_HOME/jre/lib/amd64/server                        # path to libjvm.so
#export LIB_CUDA=/usr/local/cuda-7.5/lib64                             # for GPUs only

# for CPU mode:
# export QUEUE=default
# remove references to $LIB_CUDA
```

```
$ source env.sh
```

Sparkを使って画像を取り出し、CSV形式で保存する。

```
$ ${SPARK_HOME}/bin/spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --queue ${QUEUE} \
  --num-executors 4 \
  --executor-memory 1G \
  --archives mnist/mnist.zip#mnist \
  TensorFlowOnSpark/examples/mnist/mnist_data_setup.py \
  --output mnist/csv \
  --format csv
```

結果は以下の通り。

```
$ hdfs dfs -ls mnist/csv/train/images
Found 11 items
-rw-r--r--   3 vagrant hdfs          0 2018-11-19 22:28 mnist/csv/train/images/_SUCCESS
-rw-r--r--   3 vagrant hdfs    9338236 2018-11-19 22:28 mnist/csv/train/images/part-00000
-rw-r--r--   3 vagrant hdfs   11231804 2018-11-19 22:28 mnist/csv/train/images/part-00001
-rw-r--r--   3 vagrant hdfs   11214784 2018-11-19 22:28 mnist/csv/train/images/part-00002
-rw-r--r--   3 vagrant hdfs   11226100 2018-11-19 22:28 mnist/csv/train/images/part-00003
-rw-r--r--   3 vagrant hdfs   11212767 2018-11-19 22:28 mnist/csv/train/images/part-00004
-rw-r--r--   3 vagrant hdfs   11173834 2018-11-19 22:28 mnist/csv/train/images/part-00005
-rw-r--r--   3 vagrant hdfs   11214285 2018-11-19 22:28 mnist/csv/train/images/part-00006
-rw-r--r--   3 vagrant hdfs   11201024 2018-11-19 22:28 mnist/csv/train/images/part-00007
-rw-r--r--   3 vagrant hdfs   11194141 2018-11-19 22:28 mnist/csv/train/images/part-00008
-rw-r--r--   3 vagrant hdfs   10449019 2018-11-19 22:28 mnist/csv/train/images/part-00009
```

公式手順にはtfspark.zipを生成する流れが記載なかったので、
とりあえず以下のように生成した。

```
$ cd TensorFlowOnSpark/
$ zip -r ../tfspark.zip *
$ cd ..
```

学習を実行する。

```
$ hadoop fs -rm -r mnist_model
$ ${SPARK_HOME}/bin/spark-submit \
  --master yarn \
  --deploy-mode cluster \
  --queue ${QUEUE} \
  --num-executors 4 \
  --executor-memory 1G \
  --py-files tfspark.zip,TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py \
  --conf spark.dynamicAllocation.enabled=false \
  --conf spark.yarn.maxAppAttempts=1 \
  --conf spark.executorEnv.LD_LIBRARY_PATH=$LIB_CUDA:$LIB_JVM:$LIB_HDFS \
  TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py \
  --images mnist/csv/train/images \
  --labels mnist/csv/train/labels \
  --mode train \
  --model mnist_model
```

以下のエラーで落ちた。

```
(snip)
18/11/19 23:12:06 ERROR Executor: Exception in task 0.1 in stage 0.0 (TID 3)
org.apache.spark.SparkException: Python worker exited unexpectedly (crashed)
	at org.apache.spark.api.python.BasePythonRunner$ReaderIterator$$anonfun$1.applyOrElse(PythonRunner.scala:333)
	at org.apache.spark.api.python.BasePythonRunner$ReaderIterator$$anonfun$1.applyOrElse(PythonRunner.scala:322)
	at scala.runtime.AbstractPartialFunction.apply(AbstractPartialFunction.scala:36)
	at org.apache.spark.api.python.PythonRunner$$anon$1.read(PythonRunner.scala:443)
	at org.apache.spark.api.python.PythonRunner$$anon$1.read(PythonRunner.scala:421)
	at org.apache.spark.api.python.BasePythonRunner$ReaderIterator.hasNext(PythonRunner.scala:252)
	at org.apache.spark.InterruptibleIterator.hasNext(InterruptibleIterator.scala:37)
	at scala.collection.Iterator$class.foreach(Iterator.scala:893)
	at org.apache.spark.InterruptibleIterator.foreach(InterruptibleIterator.scala:28)
	at scala.collection.generic.Growable$class.$plus$plus$eq(Growable.scala:59)
(snip)
```

やはりデバッグしづらい感じがある。
