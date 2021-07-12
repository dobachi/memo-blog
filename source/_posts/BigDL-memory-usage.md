---

title: BigDL memory usage
date: 2020-11-13 16:04:02
categories:
  - Research
  - Machine Learning
  - BigDL
tags:
  - BigDL

---

# 参考

* [Download]
* [Issue-3070]
* [use pre-bulid libs]
* [bigdl-SPARK_2.4]
* [Run]
* [Examples]
* [Lenet Train]
* [LeNet Example]

[Download]: https://bigdl-project.github.io/master/#release-download/
[Issue-3070]: https://github.com/intel-analytics/BigDL/issues/3070
[use pre-bulid libs]: https://bigdl-project.github.io/master/#ScalaUserGuide/install-pre-built/
[bigdl-SPARK_2.4]: https://search.maven.org/artifact/com.intel.analytics.bigdl/bigdl-SPARK_2.4/0.11.1/jar
[Run]: https://bigdl-project.github.io/master/#ScalaUserGuide/run/
[Examples]: https://bigdl-project.github.io/master/#ScalaUserGuide/examples/
[LeNet Train]: https://github.com/intel-analytics/BigDL/blob/master/spark/dl/src/main/scala/com/intel/analytics/bigdl/models/lenet/Train.scala
[LeNet Example]: https://github.com/intel-analytics/BigDL/tree/master/spark/dl/src/main/scala/com/intel/analytics/bigdl/models/lenet

# メモ

## 前提

[Download] によると、Sparkは2.4系まで対応しているようだ。
[Issue-3070] によると、Spark3対応も進んでいるようだ。

## Spark起動

[Run] で記載の通り、以下のように起動した。

```
$ export SPARK_HOME=/usr/local/spark/default
$ export BIGDL_HOME=/usr/local/bigdl/default
$ ${BIGDL_HOME}/bin/spark-shell-with-bigdl.sh --master local[*]
```

```
scala> import com.intel.analytics.bigdl.utils.Engine
scala> Engine.init
```

とりあえず初期化までは動いた。

## サンプルを動かす

[Examples] に記載のサンプルを動かす。
[LeNet Train] にあるLeNetの例が良さそう。

MNISTの画像をダウンロードして、展開した。

```
$ mkdir ~/tmp
$ cd ~/tmp
$ wget http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz
$ wget http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz
$ wget http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz
$ wget http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz
$ gunzip *.gz
```

展開したディレクトリを指定しながら、LeNetの学習を実行。

```
$ spark-submit \
  --master local[6] \
  --driver-class-path ${BIGDL_HOME}/lib/bigdl-SPARK_2.4-0.11.1-jar-with-dependencies.jar \
  --class com.intel.analytics.bigdl.models.lenet.Train \
  ${BIGDL_HOME}/lib/bigdl-SPARK_2.4-0.11.1-jar-with-dependencies.jar \
  -f $HOME/tmp \
  -b 12 \
  --checkpoint ./model
```

実行中の様子は以下の通り。

![ヒストリのキャプチャ](/memo-blog/images/p5b0S1PrMD3x9YMp-31A2F.png)

今回はローカルモードで実行したが、入力された学習データと同様のサイズのキャッシュがメモリ上に展開されていることがわかる。

## サンプルの中身


2020/11/15時点のmasterブランチを確認する。

### Trainクラス

上記サンプルで実行されているTrainを見る。
モデルを定義している箇所は以下の通り。

com/intel/analytics/bigdl/models/lenet/Train.scala:48

```scala
      val model = if (param.modelSnapshot.isDefined) {
        Module.load[Float](param.modelSnapshot.get)
      } else {
        if (param.graphModel) {
          LeNet5.graph(classNum = 10)
        } else {
          Engine.getEngineType() match {
            case MklBlas => LeNet5(10)
            case MklDnn => LeNet5.dnnGraph(param.batchSize / Engine.nodeNumber(), 10)
          }
        }
      }

```

Modelインスタンスは以下の通り、Optimizerオブジェクトに渡され、
データセットに合わせたOptimizerが返される。
（例：データセットが分散データセットかどうか、など）

com/intel/analytics/bigdl/models/lenet/Train.scala:83

```scala
      val optimizer = Optimizer(
        model = model,
        dataset = trainSet,
        criterion = criterion)
```

参考までに、Optimizerの種類と判定の処理は以下の通り。

com/intel/analytics/bigdl/optim/Optimizer.scala:688

```scala
    dataset match {
      case d: DistributedDataSet[_] =>
        Engine.getOptimizerVersion() match {
          case OptimizerV1 =>
            new DistriOptimizer[T](
              _model = model,
              _dataset = d.toDistributed().asInstanceOf[DistributedDataSet[MiniBatch[T]]],
              _criterion = criterion
            ).asInstanceOf[Optimizer[T, D]]
          case OptimizerV2 =>
            new DistriOptimizerV2[T](
              _model = model,
              _dataset = d.toDistributed().asInstanceOf[DistributedDataSet[MiniBatch[T]]],
              _criterion = criterion
            ).asInstanceOf[Optimizer[T, D]]
        }
      case d: LocalDataSet[_] =>
        new LocalOptimizer[T](
          model = model,
          dataset = d.toLocal().asInstanceOf[LocalDataSet[MiniBatch[T]]],
          criterion = criterion
        ).asInstanceOf[Optimizer[T, D]]
      case _ =>
        throw new UnsupportedOperationException
    }

```

返されたOptimizerの、Optimizer#optimizeメソッドを利用し学習が実行される。

com/intel/analytics/bigdl/models/lenet/Train.scala:98

```scala
      optimizer
        .setValidation(
          trigger = Trigger.everyEpoch,
          dataset = validationSet,
          vMethods = Array(new Top1Accuracy, new Top5Accuracy[Float], new Loss[Float]))
        .setOptimMethod(optimMethod)
        .setEndWhen(Trigger.maxEpoch(param.maxEpoch))
        .optimize()
```

### Optimizerの種類

上記の内容を見るに、Optimizerにはいくつか種類がありそうだ。

* DistriOptimizer
* DistriOptimizerV2
* LocalOptimizer

#### DistriOptimizer

ひとまずメモリ使用に関連する箇所ということで、入力データの準備の処理を確認する。
`com.intel.analytics.bigdl.optim.DistriOptimizer#optimize` メソッドには
以下のような箇所がある。

com/intel/analytics/bigdl/optim/DistriOptimizer.scala:870

```scala
    prepareInput()
```

これは `com.intel.analytics.bigdl.optim.DistriOptimizer#prepareInput` メソッドであり、
内部的に `com.intel.analytics.bigdl.optim.AbstractOptimizer#prepareInput` メソッドを呼び出し、
入力データをSparkのキャッシュに載せるように処理する。


com/intel/analytics/bigdl/optim/DistriOptimizer.scala:808

```scala
    if (!dataset.toDistributed().isCached) {
      DistriOptimizer.logger.info("caching training rdd ...")
      DistriOptimizer.prepareInput(this.dataset, this.validationDataSet)
    }
```

キャシュに載せると箇所は以下の通り。

com/intel/analytics/bigdl/optim/AbstractOptimizer.scala:279

```scala
  private[bigdl] def prepareInput[T: ClassTag](dataset: DataSet[MiniBatch[T]],
    validationDataSet: Option[DataSet[MiniBatch[T]]]): Unit = {
    dataset.asInstanceOf[DistributedDataSet[MiniBatch[T]]].cache()
    if (validationDataSet.isDefined) {
      validationDataSet.get.toDistributed().cache()
    }
  }
```

上記の `DistributedDataSet` の `chache` メソッドは以下の通り。

com/intel/analytics/bigdl/dataset/DataSet.scala:216

```scala
  def cache(): Unit = {
    if (originRDD() != null) {
      originRDD().count()
    }
    isCached = true
  }
```

`originRDD` の戻り値に対して、`count` を読んでいる。
ここで `count` を呼ぶのは、入力データである `originRDD` の戻り値に入っているRDDをメモリ上にマテリアライズするためである。

`count` を呼ぶだけでマテリアライズできるのは、予め入力データを定義したときに Spark RDDの `cache` を利用してキャッシュ化することを指定されているからである。
今回の例では、Optimizerオブジェクトのapplyを利用する際に渡されるデータセット `trainSet` を
定義する際に予め `cache` が呼ばれる。

com/intel/analytics/bigdl/models/lenet/Train.scala:79

```scala
      val trainSet = DataSet.array(load(trainData, trainLabel), sc) ->
        BytesToGreyImg(28, 28) -> GreyImgNormalizer(trainMean, trainStd) -> GreyImgToBatch(
        param.batchSize)
```

`trainSet` を定義する際、 `com.intel.analytics.bigdl.dataset.DataSet$#array(T[], org.apache.spark.SparkContext)` メソッドが
呼ばれるのだが、その中で以下のように Sparkの `RDD#cache` が呼ばれていることがわかる。

com/intel/analytics/bigdl/dataset/DataSet.scala:343

```scala
  def array[T: ClassTag](localData: Array[T], sc: SparkContext): DistributedDataSet[T] = {
    val nodeNumber = Engine.nodeNumber()
    new CachedDistriDataSet[T](
      sc.parallelize(localData, nodeNumber)
        // Keep this line, or the array will be send to worker every time
        .coalesce(nodeNumber, true)
        .mapPartitions(iter => {
          Iterator.single(iter.toArray)
        }).setName("cached dataset")
        .cache()
    )
  }
```

以下、一例。

具体的には、Optimizerのインスタンスを生成するための `apply` メソッドはいくつかあるが、
以下のように引数にデータセットを指定する箇所がある。（再掲）

com/intel/analytics/bigdl/optim/Optimizer.scala:619

```scala
          _dataset = (DataSet.rdd(sampleRDD) ->
```

ここで用いられている `com.intel.analytics.bigdl.dataset.DataSet#rdd` メソッドは以下の通り。

com/intel/analytics/bigdl/dataset/DataSet.scala:363

```scala
  def rdd[T: ClassTag](data: RDD[T], partitionNum: Int = Engine.nodeNumber()
    ): DistributedDataSet[T] = {
    new CachedDistriDataSet[T](
      data.coalesce(partitionNum, true)
        .mapPartitions(iter => {
          Iterator.single(iter.toArray)
        }).setName("cached dataset")
        .cache()
    )
  }
```

`com.intel.analytics.bigdl.dataset.CachedDistriDataSet#CachedDistriDataSet` のコンストラクタ引数に、
`org.apache.spark.rdd.RDD#cache` を用いてキャッシュ化することを指定したRDDを渡していることがわかる。


<!-- vim: set et tw=0 ts=2 sw=2: -->
