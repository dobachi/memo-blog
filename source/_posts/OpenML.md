---
title: OpenMLを軽く確認してみる
date: 2019-11-01 15:33:39
categories:
  - Knowledge Management
  - Machine Learning
tags:
  - Machine Learning
  - OpenML
  - ML Model Management


---

# 参考

* [OpenML公式ウェブサイト]
* [OpenML公式ドキュメント]
* [scikit-learnでの使用]
* [Pythonガイド]
* [github.ioのPythonガイド]
* [FlowとRunのチュートリアル]
* [実行に用いたpipenvの環境ファイル]
* [dobachi openml_sklearn_example]
* [公式Examples]

[OpenML公式ウェブサイト]: https://www.openml.org/
[OpenML公式ドキュメント]: https://docs.openml.org/
[scikit-learnでの使用]: https://docs.openml.org/sklearn/
[Pythonガイド]: https://openml.github.io/openml-python/develop/usage.html
[github.ioのPythonガイド]: https://openml.github.io/openml-python/develop/index.html
[FlowとRunのチュートリアル]: https://openml.github.io/openml-python/develop/examples/20_basic/simple_flows_and_runs_tutorial.html#sphx-glr-examples-20-basic-simple-flows-and-runs-tutorial-py
[実行に用いたpipenvの環境ファイル]: https://github.com/dobachi/openml_sklearn_example/blob/master/Pipfile
[dobachi openml_sklearn_example]: https://github.com/dobachi/openml_sklearn_example
[公式Examples]: https://openml.github.io/openml-python/develop/examples/index.html


# メモ

## 概要

[OpenML公式ドキュメント] によると、以下の定義。

> An open, collaborative, frictionless, automated machine learning environment.

[OpenML公式ウェブサイト] によると、

* Dataset
* Task
  * データセットと機械学習としての達成すべきこと
* Flow
  * 各種フレームワークに則った処理パイプライン
* Run
  * あるFlowについてハイパーパラメータを指定し、あるTaskに対して実行したもの

のレポジトリが提供されている。
これらはウェブサイトから探索可能。

### Dataset

Datasetが登録されると機械的にアノテーションされたり、分析されたりする。
パット見でデータの品質がわかるようになっている。

### Task

データセットに対する目標（と言ってよいのか。つまり識別、回帰など）、学習用、テスト用のデータのスプリット、
どのカラムを目的変数とするか、などが
セットになったコンテナである。

機械的に読めるようになっている。

### Flow

処理パイプラインはFlowとして登録され、再利用可能になる。
特定のTaskに紐づく処理として定義される。

フレームワークにひもづく。

### Run

OpenML APIを用いて実行ごとに自動登録される。

### scikit-learnで試す

[Pythonガイド] を参考に試してみる。
一通り、Pandas、scikit-learn、openml、pylzmaをインストールする。
なお、あらかじめliblzma-devをインストールしておくこと。
詳しくは以下の「lzmaがインポートできない」節を参照。

[実行に用いたpipenvの環境ファイル] に用いたライブラリが載っている。

[Pythonガイド] を眺めながら進めようと思ったが、
https://openml.github.io/openml-python/develop/examples/introduction_tutorial.html のリンクが切れていた。
何となく見るとgithub.ioだったので探索してみたら、 [github.ioのPythonガイド] が見つかった。

こっちを参考にしてみる。

[FlowとRunのチュートリアル] を元に、チュートリアルを実施。
また特に、 [公式Examples] あたりを参考にした。
詳しくは、  [dobachi openml_sklearn_example] 内のnotebookを参照。

### トラブルシュート

#### lzmaがインポートできない

以下の内容のエラーが生じた。

```
/home/dobachi/.local/share/virtualenvs/openml_sklearn_example-YW762zpK/lib/python3.7/site-packages/pandas/compat/__init__.py:85: UserWarning: Could not import the lzma module. Your installed Python is incomplete. Attempting to use lzma compression will result in a RuntimeError.
  warnings.warn(msg)
```

lzma関連のlibをインストールしておいてから、Python環境を構築すること。
つまりpyenvとpipenvで環境構築する前に`liblzma-dev`をインストールしておく。
```
$ sudo apt install liblzma-dev 
```

参考： [lzmaライブラリをインポートできません。]

[lzmaライブラリをインポートできません。]: https://ja.stackoverflow.com/questions/56859/lzma%E3%83%A9%E3%82%A4%E3%83%96%E3%83%A9%E3%83%AA%E3%82%92%E3%82%A4%E3%83%B3%E3%83%9D%E3%83%BC%E3%83%88%E3%81%A7%E3%81%8D%E3%81%BE%E3%81%9B%E3%82%93

## 所感

歴史があり、情報が集まっている。
ドキュメントが中途半端なせいで、初見ではとっつきづらいかもしれないが、ライブラリひとつでデータ発掘・共有に始まり、処理パイプラインの機械化まで対応しているのは有益。


<!-- vim: set tw=0 ts=4 sw=4: -->
