---

title: TensorFlowOnSparkの例を確認する
date: 2018-12-02 16:44:02
categories:
  - Research
  - Machine Learning
  - TensorFlow
tags:
  - TensorFlow
  - Spark
  - PySpark
  - TensorFlowOnSpark

---

# estimator

[オリジナルのcnn_mnist.py]: https://github.com/tensorflow/tensorflow/blob/r1.6/tensorflow/examples/tutorials/layers/cnn_mnist.py

[オリジナルのcnn_mnist.py]をTensorFlowOnSparkで動くように修正したもののようだ。

サンプルは、mnist_estimator.pyのみ。
学習・評価を実行する。

保存されたMNISTのデータを各ワーカが読んで学習する。

## mnist_estimator.pyのポイント

データロードの箇所は以下の通り。
学習データをすべて読み込むようになっていることが分かる。

examples/mnist/estimator/mnist_estimator.py:120
```
  # Load training and eval data
  mnist = tf.contrib.learn.datasets.mnist.read_data_sets(args.data_dir)
  train_data = mnist.train.images  # Returns np.array
  train_labels = np.asarray(mnist.train.labels, dtype=np.int32)
  eval_data = mnist.test.images  # Returns np.array
  eval_labels = np.asarray(mnist.test.labels, dtype=np.int32)
```

モデルの定義の箇所は以下の通り。
モデル定義は実態的にはcnn_model_fn関数が担っている。
当該関数の中でCNNの層定義が行われている。

examples/mnist/estimator/mnist_estimator.py:127
```
  mnist_classifier = tf.estimator.Estimator(
      model_fn=cnn_model_fn, model_dir=args.model)
```

学習と評価の箇所は以下の通り。
入力データ用の関数を引数に渡しつつ実行する。
（これは各ワーカで動くところか）

examples/mnist/estimator/mnist_estimator.py:158
```
  train_spec = tf.estimator.TrainSpec(input_fn=train_input_fn, max_steps=args.steps, hooks=[logging_hook])
  eval_spec = tf.estimator.EvalSpec(input_fn=eval_input_fn)
  tf.estimator.train_and_evaluate(mnist_classifier, train_spec, eval_spec)
```

# spark

## mnist_spark.pyのポイント

PySparkのアプリケーションとして、TensorFlowOnSparkを実行するアプリケーションである。

入力データの形式は、`org.tensorflow.hadoop.io.TFRecordFileInputFormat`（以降、TFRと呼ぶ）とCSVの両方に対応している。
TFRの場合は、入力されたデータをレコード単位でNumpy Array形式に変換して用いる。
CSVの場合、配列に変換する。

Executorで実行するメイン関数は、 `mnist_dist.map_fun` である。

## mnist_dist.pyのポイント

map_fun関数の定義がある。
パラメータサーバ、ワーカそれぞれのときに実行する処理が定義されている。

パラメータサーバのときは、TensorFlow Serverのjoinメソッドを呼ぶ。

ワーカのときはデバイスの指定、TensorFlow用の入力データの定義、層の定義、損失計算等が行われる。
なお学習と予測のそれぞれの動作が定義されている。

予測の時は、`DataFeed#batch_results`メソッドを使って、予測結果が戻り値のRDD向けにフィードされるようになっている。

# tf

他のサンプルとは独立したものかどうか要確認。

## examples/mnist/tf/mnist_spark.py

READMEに書かれた最初のサンプル。
SparkContextを定義し、`TFCluster#run`メソッドを呼び出す。
runに渡されるTensorFlowのメイン関数は`mnist_dist.map_fun`である。

### map_funのポイント

`_parse_csv`メソッドと`_parse_tfr`メソッドはそれぞれCSV形式、TFR形式のデータを読み、
ノーマライズし、画像データとラベルのペアを返す。

`build_model`メソッドでモデルを定義する。

パラメータサーバとして機能するExecutorではTensorFlow Serverのjoinメソッドを呼び出す。

ワーカとして機能するExecutorは以下の流れ。

* 入力データのロードと加工
* モデルのビルド
* TensorFlowまわりのセットアップ（Saverのセットアップなど）
* 予測の時
  * 出力ファイルオープン
  * 予測結果などの出力
  * 出力ファイルクローズ
* 学習の時
  * 定期的に状況をプリントしながら学習実行
  * タスクインデックスが0の場合のみ以下を実行
    * プレイスホルダ設定
    * モデルビルド
    * チェックポイントからの復元
    * エクスポート
* ワーカごとにdoneファイルを生成（完了確認のため）

## examples/mnist/tf/mnist_inference.py

TFClusterを使わず、Executor内でシングルノードのTFを使って予測結果を作る例。

### Executor内で実行される処理

* シングルノードのTFのセットアップ
* モデルロード
* 入力のための各種手続き（TFRecordを読むための関数定義、入力データの定義など）
