---

title: PixieDustを試してみる
date: 2018-12-13 22:30:57
categories:
  - Research
  - Data Analytics
  - Tools
tags:
  - Data Analytics
  - Tools
  - Python
  - Jupyter

---

# 参考

* [公式GitHub]
* [Qiitaの紹介ブログ]

[公式GitHub]: https://github.com/pixiedust/pixiedust
[Qiitaの紹介ブログ]: https://qiita.com/ishida330/items/53f1b0df2247fab5c6dd?fbclid=IwAR0fc_xvmkX2dIo9BYYcwygdCc8s1CtCDXkY_-qsmFQOWK0d5QZH-OZ2mtI
[Use in python or scala]: https://github.com/pixiedust/pixiedust#use-in-python-or-scala
[公式ウェブサイトのインストール手順]: https://pixiedust.github.io/pixiedust/install.html

# 公式サイトの確認

ここでは気になったことを記しておく。

## Scalaでも使える？

公式GitHubのREADMEには、 [Use in python or scala] という項目があり、
そこには以下のような記述がある。

```
PixieDust lets you bring robust Python visualization options to your Scala notebooks.
```

```
Scala Bridge. Use Scala directly in your Python notebook. Variables are automatically transfered from Python to Scala and vice-versa. Learn more.
```

```
Spark progress monitor. Track the status of your Spark job. No more waiting in the dark. Notebook users can now see how a cell's code is running behind the scenes.
```

## Jupyterに独自のカーネルをインストールして使う

カーネルを追加することで、ユーザが自身の環境に依存するライブラリ（Sparkなど）をインストールしなくても
簡単に使えるようになっているようだ？ ★要確認

# 動作確認

まずは、[公式ウェブサイトのインストール手順] を読みつつ、
[Qiitaの紹介ブログ] を読みながら、軽く試してみることにした。
Anacondaを使っているものとし、Condaで環境を作る。

```
$ conda create -n PixieDustExample python=3.5 jupyter
$ conda activate PixieDustExample
```

また [公式ウェブサイトのインストール手順] には、以下のような記述があり、
Pythonは2.7もしくは3.5が良いようだ。

```
Note PixieDust supports both Python 2.7 and Python 3.5.
```

pipでpixiedustを探すと、エコシステムが形成されているようだった。

```
$ pip search pixiedust
pixiedust-node (0.2.5)                    - Pixiedust extension for Node.js
pixiedust-flightpredict (0.12)            - Flight delay predictor application with PixieDust
pixiedust-wordcloud (0.2.2)               - Word Cloud Visualization Plugin for PixieDust
pixiedust-twitterdemo1 (0.1)              - Pixiedust demo of the Twitter Sentiment Analysis tutorials
pixiedust-twitterdemo (0.4)               - Pixiedust demo of the Twitter Sentiment Analysis tutorials
pixiedust (1.1.14)                        - Productivity library for Jupyter Notebook
pixiedust-optimus (1.4.0)                 - Productivity library for Spark Python Notebook
pixiegateway (0.8)                        - Server for sharing PixieDust chart and running PixieApps
stem-ladiespixiedust-twitterdemo (0.2.2)  - Pixiedust demo of the Twitter Sentiment Analysis tutorialsfor the STEM activity wall
```

そのまま入れることとする。依存関係でいくつかライブラリが入る。

```
$ pip install pixiedust
```

エラー。

```
twisted 18.7.0 requires PyHamcrest>=1.9.0, which is not installed.
```

condaでインストールする。

```
$ conda install PyHamcrest
```

PixieDust向けのJupyterカーネルをインストールする。
なお、本手順の前に、JDKがインストールされ、JAVA_HOMEがインストールされていることを前提とする。

```
$ jupyter pixiedust install
```

エラー。

```
$ jupyter pixiedust install
Step 1: PIXIEDUST_HOME: /home/dobachi/pixiedust
        Keep y/n [y]? y
Step 2: SPARK_HOME: /home/dobachi/pixiedust/bin/spark
        Keep y/n [y]? y
Directory /home/dobachi/pixiedust/bin/spark does not contain a valid SPARK install
        Download Spark y/n [y]? y
What version would you like to download? 1.6.3, 2.0.2, 2.1.0, 2.2.0, 2.3.0 [2.3.0]: 
SPARK_HOME will be set to /home/dobachi/pixiedust/bin/spark/spark-2.3.0-bin-hadoop2.7
Downloading Spark 2.3.0
Traceback (most recent call last):

(snip)

  File "/home/dobachi/.conda/envs/PixieDustExample/lib/python3.7/site-packages/install/createKernel.py", line 408, in download_spark
    temp_file = self.download_file(spark_download_url)
  File "/home/dobachi/.conda/envs/PixieDustExample/lib/python3.7/site-packages/install/createKernel.py", line 455, in download_file
    raise Exception("{}".format(response.status_code))
Exception: 404
```

Sparkのダウンロードで失敗しているようだ。
軽くデバッグしたところ、URLとして渡されているのは、
`http://apache.claz.org/spark/spark-2.3.0/spark-2.3.0-bin-hadoop2.7.tgz`のようだった。
確かに、リンク切れ？のようだった。いったん、Spark公式サイトのダウンロードページで
指定されるURLからダウンロードするよう、createKernel.pyを修正して実行することにした。

なお、上記手順により、指定したディレクトリにSparkとScalaがインストールされる。
成功すると、以下のようなメッセージが見られる。

```
(snip)

####################################################################################################
#       Congratulations: Kernel Python-with-Pixiedust_Spark-2.3 was successfully created in /home/dobachi/.local/share/jupyter/kernels/pythonwithpixiedustspark23
#       You can start the Notebook server with the following command:
#               jupyter notebook /home/dobachi/pixiedust/notebooks
####################################################################################################
```

なお、そのまま実行したら、以下のライブラリが足りないと言われたので予めインストールすることとする。
（bokeh、seabornはついでにインストール。インストールしないとRendererの選択肢が出てこない）

```
$ conda install matplotlib pandas PyYaml bokeh seaborn
```

さて、 [Qiitaの紹介ブログ] では、PixieDustのカーネルインストール時に一緒にインストールされるノートブックではなく、
日本語でわかりやすい紹介記事が書かれているが、ここではいったん、上記のインストール時のメッセージに従うこととする。

Jupyterを起動

```
$ jupyter notebook /home/dobachi/pixiedust/notebooks
```

あとは、適当にノートブックを眺めて実行する。

## PixieDust 1 - Easy Visualizationsで気になったこと

`Loading External Data`節でD3 Rendererを試したところ、以下のようなエラー。

```
Object of type ndarray is not JSON serializable
```
