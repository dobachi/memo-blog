---

title: Configure Python of PySpark in Zeppelin
date: 2019-12-27 23:43:45
categories:
    - Knowledge Management
    - Zeppelin

tags:
    - Zeppelin
    - Spark
    - PySpark
    - Python

---

# 参考


# メモ

ウェブフロントエンドのSpark Interpreterの設定において、
以下の2項目を設定した。

* spark.pyspark.python
* zeppelin.pyspark.python

上記2項目が同じ値で設定されていないと、実行時エラーを生じた。

## 参考）Pythonバージョンの確かめ方

ドライバのPythonバージョンの確かめ方

```
%spark.pyspark

import sys

print('Zeppelin python: {}'.format(sys.version))
```

ExecutorのPythonバージョンの確かめ方

```
%spark.pyspark

def print_version(x):
    import sys
    return sys.version

spark.sparkContext.parallelize(range(1, 3)).map(print_version).collect()
```

<!-- vim: set tw=0 ts=4 sw=4: -->
