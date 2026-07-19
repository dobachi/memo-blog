---

title: TFoSparkのTFManager
date: 2018-12-06 12:43:25
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

# 概要

以下の通り、マルチプロセッシング処理におけるプロセス間通信を担うマネージャ。

tensorflowonspark/TFManager.py:15
```
  """Python multiprocessing.Manager for distributed, multi-process communication."""
```

キューやキーバリューの辞書を管理。
キューは、SparkのExecutorとTFのWorkerの間の通信に用いられるようだ。


# 実装の確認

また以下の通り、BaseManagerを継承している。

tensorflowonspark/TFManager.py:14
```
class TFManager(BaseManager):
```

## startメソッド

startメソッドではリモートの接続を受け付けるかどうかを確認しながら、
BaseManager#startメソッドを使ってマネージャ機能を開始する。

tensorflowonspark/TFManager.py:60
```
  if mode == 'remote':
    mgr = TFManager(address=('', 0), authkey=authkey)
  else:
    mgr = TFManager(authkey=authkey)
  mgr.start()
```

## connectメソッド

アドレスと鍵を指定しながらTFManagerに接続する。

tensorflowonspark/TFManager.py:81
```
  m = TFManager(address, authkey=authkey)
  m.connect()
  return m
```
