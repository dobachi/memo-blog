---

title: Abstract of Analytics Zoo
date: 2019-12-02 22:13:42
categories:
  - Knowledge Management
  - Machine Learning
  - Analytics Zoo
tags:
  - Machine Learning
  - Analytics Zoo
  - Intel
  - BigDL

---

# 参考

* [Analytics Zooの公式ドキュメント]
* [Analytics Zoo 0.6.0の公式ドキュメント]

[Analytics Zooの公式ドキュメント]: https://analytics-zoo.github.io/master/index.html
[Analytics Zoo 0.6.0の公式ドキュメント]: https://analytics-zoo.github.io/0.6.0/index.html


# メモ

[Analytics Zooの公式ドキュメント] の内容から、ひとことで書いてある文言を拾うと...以下の通り。

0.2.0時代：

> Analytics + AI Platform for Apache Spark and BigDL.

2019/12現在：

> A unified analytics + AI platform for distributed TensorFlow, Keras, PyTorch and BigDL on Apache Spark


とのこと。対応範囲が拡大していることがわかる。

## 動作確認

### Python環境構築

今回は簡易的にPythonから触る。

pipenvで3.6.9環境を作り、以下のライブラリをインストールした。

* numpy
* scipy
* pandas
* scikit-learn
* matplotlib
* seaborn
* wordcloud
* jupyter

pipenvファイルは以下の通り。
https://github.com/dobachi/analytics-zoo-example/blob/master/Pipfile

なお、 [Analytics Zooの公式ドキュメント] では、Hadoop YARNでローンチする方法などいくつかの方法が掲載されている。

Exampleを動かしてみようとするが、pipでインストールしたところ `jupyter-with-zoo.sh` は以下の箇所にあった。

```
$HOME/.local/share/virtualenvs/analytics-zoo-example-hS4gvn-H/lib/python3.6/site-packages/zoo/share/bin/jupyter-with-zoo.sh
```

そこで環境変数を以下のように設定した。

```
$ export ANALYTICS_ZOO_HOME=`pipenv --venv`/lib/python3.6/site-packages/zoo/share
$ export SPARK_HOME=`pipenv --venv`/lib/python3.6/site-packages/pyspark
```

この状態で、 `${ANALYTICS_ZOO_HOME}/bin/jupyter-with-zoo.sh --master local[*]` を実行しようとしたのだが、
`jupyter-with-zoo.sh` 内で用いられている `analytics-zoo-base.sh` の中で、

```
if [[ ! -f ${ANALYTICS_ZOO_PY_ZIP} ]]; then
    echo "Cannot find ${ANALYTICS_ZOO_PY_ZIP}"
    exit 1
fi
```

の箇所に引っかかりエラーになってしまう。
そもそも環境変数 `ANALYTICS_ZOO_PY_ZIP` は任意のオプションの値を指定するための環境変数であるため、このハンドリングがおかしいと思われる。
どうやら、pipenvでインストールした0.6.0では、Jupyterとの連係周りがまだ付け焼き刃のようだ。
とりあえず、今回の動作確認では利用しない環境変数であるため、関係個所をコメントアウトして実行することとする。

上記対応の後、以下のようにpipenv経由でJupyter PySparkを起動。

```
$ pipenv run ${ANALYTICS_ZOO_HOME}/bin/jupyter-with-zoo.sh --master local[*]
```

試しに実行しようとしたが、以下のエラー

```
Py4JError: com.intel.analytics.zoo.pipeline.nnframes.python.PythonNNFrames does not exist in the JVM
```


<!-- vim: set tw=0 ts=4 sw=4: -->
