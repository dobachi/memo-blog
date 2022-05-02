---

title: Efficient and Robust Automated Machine Learning
date: 2019-09-22 17:27:47
categories:
  - Knowledge Management
  - Machine Learning
  - AutoML
tags:
  - Machine Learning
  - Machine Learning Lifecycle/
  - AutoML

---

# 参考

* [Efficient and Robust Automated Machine Learning]
* [NIPS]
* [OpenML]
* [auto-sklearnのGitHub]
* [auto-sklearnのドキュメント]
* [インストール手段]

[Efficient and Robust Automated Machine Learning]: http://papers.nips.cc/paper/5872-efficient-and-robust-automated-machine-learning.pdf
[NIPS]: https://papers.nips.cc/paper/5872-efficient-and-robust-automated-machine-learning
[OpenML]: https://www.openml.org/
[auto-sklearnのGitHub]: https://github.com/automl/auto-sklearn
[auto-sklearnのドキュメント]: https://automl.github.io/auto-sklearn/master/
[インストール手段]: https://automl.github.io/auto-sklearn/master/installation.html#installation
[scikit-learn で No module named '_bz2' というエラーがでる問題]: https://qiita.com/kizashi1122/items/2a0abcbfab99fecf16c6

# 論文メモ

気になったところをメモする。

## 概要

いわゆるAutoMLの一種。
特徴量処理、アルゴリズム選択、ハイパーパラメータチューニングを実施。
さらに、メタ学習とアンサンブル構成も改善として対応。
scikit-learnベースのAutoML。

auto-sklearnと呼ぶ。

GitHub上にソースコードが公開されている。

同様のデータセットに対する過去の性能を考慮し、アンサンブルを構成する。

ChaLearn AutoMLチャレンジで勝利。

OpenMLのデータセットを用いて、汎用性の高さを確認した。

2019/11時点では、識別にしか対応していない？

## 1. Introduction

以下のあたりのがAutoML周りのサービスとして挙げられていた。

```
BigML.com, Wise.io, SkyTree.com, RapidMiner.com, Dato.com, Prediction.io, DataRobot.com, Microsoft’s Azure Machine
Learning, Google’s Prediction API, and Amazon Machine Learning
```

Auto-wekaをベースとしたもの。

パラメトリックな機械学習フレームワークと、ベイジアン最適化を組み合わせて用いる。

特徴

* 新しいデータセットに強い。ベイジアン最適化をウォームスタートする。
* 自動的にモデルをアンサンブルする
* 高度にパラメタライズされたフレームワーク
* 数多くのデータセットで実験

## 2 AutoML as a CASH problem

ここで扱う課題をCombined Algorithm Selection and Hyperparameter optimization (CASH) と呼ぶ。

ポイントは、

* ひとつの機械学習手法がすべてのデータセットに対して有効ではない
* 機械学習手法によってはハイパーパラメータチューニングが必要

ということ。
それらを単一の最適化問題として数式化できる。

Auto-wekaで用いられたツリーベースのベイジアン最適化は、ガウシアンプロセスモデルを用いる。
低次元の数値型のハイパパラメータには有効。
しかし、ツリーベースのアルゴリズムは高次元で離散値にも対応可能。
Hyperopt-sklearnのAutoMLシステムで用いられている。

提案手法では、ランダムフォレストベースのSMACを採用。

## 3 New methods for increasing efﬁciency and robustness of AutoML

提案手法のポイント

* ベイジアン最適化のウォームスタート
* アンサンブル構築の自動化

まずウォームスタートについて。

メタ学習は素早いが粗い。ベイジアン最適化はスタートが遅いが精度が高い。
これを組み合わせる。

既存手法でも同様の試みがあったが、複雑な機械学習モデルや多次元のパラメータには適用されていない？

[OpenML] を利用し、メタ学習。


つづいてアンサンブル構築について。

単一の結果を用いるよりも、アンサンブルを組んだほうが良い。
アンサンブル構成の際には重みを用いる。重みの学習にはいくつかの手法を試した。
Caruana et al. のensemble selectionを利用。

## 5 Comparing AUTO-SKLEARN to AUTO-WEKA and HYPEROPT-SKLEARN

AUTO-SKLEARNをそれぞれ既存手法であるAUTO-WEKAとHYPEROPT-SKLEARNと比較。
（エラーレート？で比較）

AUTO-WEKAに比べて概ね良好。
一方HYPEROPT-SKLEARNは正常に動かないことがあった。

## 6 Evaluation of the proposed AutoML improvements

OpenMLレポジトリのデータを使って、パフォーマンスの一般性を確認。
テキスト分類、数字や文字の認識、遺伝子やRNAの分類、広告、望遠鏡データの小片分析、組織からのがん細胞検知。

メタ学習あり・なし、アンサンブル構成あり・なしで動作確認。

## 7 Detailed analysis of AUTO-SKLEARN components

ひとつひとつの手法を解析するのは時間がかかりすぎた。

ランダムフォレスト系統、AdaBoost、Gradient boostingがもっともロバストだった。
一方、SVMが特定のデータセットで性能高かった。

どのモデルも、すべてのケースで性能が高いわけではない。

個別の前処理に対して比較してみても、AUTO-SKLEARNは良かった。

# 動作確認

## 依存ライブラリのインストール

[auto-sklearnのドキュメント] を参考に動かしてみる。

予め、ビルドツールをインストールしておく。

```
$ sudo apt-get install build-essential swig
```

## pipenv使って環境構築

pipenvを使って、おためし用の環境を作る。

```
$ pipenv --python 3.7
```

## 依存関係とパッケージをインストールしようとしたらエラーで試行錯誤

今回はpipenvを使うので、公式手順を少し修正して実行。（pip -> pipenvとした）

```
curl https://raw.githubusercontent.com/automl/auto-sklearn/master/requirements.txt | xargs -n 1 -L 1 pipenv install
```

なお、requirementsの中身は以下の通り。

```
setuptools
nose
Cython

numpy>=1.9.0
scipy>=0.14.1

scikit-learn>=0.21.0,<0.22

lockfile
joblib
psutil
pyyaml
liac-arff
pandas

ConfigSpace>=0.4.0,<0.5
pynisher>=0.4.2
pyrfr>=0.7,<0.9
smac==0.8
```

論文の通り、SMACが使われるようだ。

つづいて、auto-sklearn自体をインストール。
（最初から、これを実行するのではだめなのだろうか？勝手に依存関係を解決してくれるのでは？）

```
$ pipenv run pip install auto-sklearn
```

なお、最初に `pipenv install auto-sklearn` していたのだがエラーで失敗したので、上記のようにvirtualenv環境下でpipインストールすることにした。
エラー内容は以下の通り。

```
(snip)

[pipenv.exceptions.ResolutionFailure]:       req_dir=requirements_dir
[pipenv.exceptions.ResolutionFailure]:   File "/home/dobachi/.pyenv/versions/3.7.5/lib/python3.7/site-packages/pipenv/utils.py", line 726, in resolve_deps
[pipenv.exceptions.ResolutionFailure]:       req_dir=req_dir,
[pipenv.exceptions.ResolutionFailure]:   File "/home/dobachi/.pyenv/versions/3.7.5/lib/python3.7/site-packages/pipenv/utils.py", line 480, in actually_resolve_deps
[pipenv.exceptions.ResolutionFailure]:       resolved_tree = resolver.resolve()
[pipenv.exceptions.ResolutionFailure]:   File "/home/dobachi/.pyenv/versions/3.7.5/lib/python3.7/site-packages/pipenv/utils.py", line 395, in resolve
[pipenv.exceptions.ResolutionFailure]:       raise ResolutionFailure(message=str(e))
[pipenv.exceptions.ResolutionFailure]:       pipenv.exceptions.ResolutionFailure: ERROR: ERROR: Could not find a version that matches scikit-learn<0.20,<0.22,>=0.18.0,>=0.19,>=0.21.0

(snip)
```

作業効率を考え、Jupyterをインストールしておく。

```
$ pipenv install jupyter
```

つづいて公式ドキュメントの手順を実行。

以下を実行したらエラーが出た。

```
import autosklearn.classification
```

```
ModuleNotFoundError: No module named '_bz2'
```

[scikit-learn で No module named '_bz2' というエラーがでる問題] の通り、
bzip2に関する開発ライブラリが足りていない、ということらしい。
パッケージをインストールし、Pythonを再インストール。pipenvのvirtualenv環境も削除。
その後、pipenvで環境を再構築。

```
$ sudo apt install libbz2-dev
$ pyenv install 3.7.5
$ pipenv --rm
$ pipenv install
```

なお、sklearnのバージョンでやはり失敗する？
よくみたら、pypiから2019/11/1時点でインストールできるライブラリは0.5.2であるが、
公式ドキュメントは0.6.0がリリースされているように見えた。
また対応するscikit-learnのバージョンが変わっている…。

## 依存関係のインストールとパッケージのインストール（2度め）

致し方ないので、依存関係のライブラリはpipenvのPipfileからインストールし、
auto-sklearnはGitHubからダウンロードしたmasterブランチ一式をインストールすることにした。

```
$ pipenv install
$ pipenv install ~/Downloads.win/auto-sklearn-master.zip
```

改めてJupyter notebookを起動

```
$ pipenv run jupyter notebook
```

以下を実行したら、一応動いたけど…

```
import autosklearn.classification
```

少し警告

```
Could not import the lzma module. Your installed Python is incomplete. 
```

sklearn関係もインポート成功。

```
import sklearn.model_selection
import sklearn.datasets
import sklearn.metrics
```

学習データ等の準備

```
X, y = sklearn.datasets.load_digits(return_X_y=True)
X_train, X_test, y_train, y_test = \
    sklearn.model_selection.train_test_split(X, y, random_state=1)
```

学習実行

```
automl = autosklearn.classification.AutoSklearnClassifier()
automl.fit(X_train, y_train)
```

実行したらPCのCPUが100%に張り付いた！


```
y_hat = automl.predict(X_test)
print("Accuracy score", sklearn.metrics.accuracy_score(y_test, y_hat))
```

### 参考）CentOS7ではSwig3をインストールすること

CentOSで依存関係をインストールするときには、 `swig` ではなく `swig3` を対象とすること。

でないと、以下のようなエラーが生じる。

```
(snip)

----------------------------------------', 'ERROR: Command errored out with exit status 1: /home/centos/.local/share/virtualenvs/auto-sklearn-example-hzZc_yaE/bin/python3.7m -u -c \'import sys, setuptools, tokenize; sys.argv[0] = \'"\'"\'/tmp/pip-install-53cbwkis/pyrfr/setup.py\'"\'"\'; __file__=\'"\'"\'/tmp/pip-install-53cbwkis/pyrfr/setup.py\'"\'"\';f=getattr(tokenize, \'"\'"\'open\'"\'"\', open)(__file__);code=f.read().replace(\'"\'"\'\\r\\n\'"\'"\', \'"\'"\'\\n\'"\'"\');f.close();exec(compile(code, __file__, \'"\'"\'exec\'"\'"\'))\' install --record /tmp/pip-record-udozwz5v/install-record.txt --single-version-externally-managed --compile --install-headers /home/centos/.local/share/virtualenvs/auto-sklearn-example-hzZc_yaE/include/site/python3.7/pyrfr Check the logs for full command output.']

(snip)
```

## メモリエラー

EC2インスタンス上で改めて実行したところ、以下のようなエラーを生じた。

```
(snip)

  File "/home/centos/.local/share/virtualenvs/auto-sklearn-example-hzZc_yaE/lib/python3.7/site-packages/autosklearn/smbo.py", line 352, in _calculate_metafeatures_encoded
  
(snip)

ImportError: /home/centos/.local/share/virtualenvs/auto-sklearn-example-hzZc_yaE/lib/python3.7/site-packages/sklearn/tree/_criterion.cpython-37m-x86_64-linux-gnu.so: failed to map segment from shared object: Cannot allocate memory

(snip)
```

これから切り分ける。

<!-- vim: set tw=0 ts=4 sw=4: -->
