---

title: Jupyter with Spark
date: 2019-01-11 00:18:29
categories:
tags:

---

# 参考

* [Sparkのドキュメント（Configuration）] 

[Sparkのドキュメント（Configuration）]: https://spark.apache.org/docs/2.4.0/configuration.html
[Sparkのドキュメント（Environment Variables）]: https://spark.apache.org/docs/2.4.0/configuration.html#environment-variables
[GitHub上のpysparkの実装#27]: https://github.com/apache/spark/blob/e4cb42ad89307ebc5a1bd9660c86219340d71ff6/bin/pyspark#L27

# メモ

よく忘れると思われる、Jupyterをクライアントとしての起動方法をメモ。

[Sparkのドキュメント（Environment Variables）] の記載の通り、環境変数PYSPARK_DRIVER_PYTHONを使い、
ドライバが用いるPythonを指定する。
[GitHub上のpysparkの実装#27] の通り、環境変数PYSPARK_DRIVER_PYTHON_OPTSを使い、
オプションを指定する。

例

```
PYSPARK_DRIVER_PYTHON=jupyter PYSPARK_DRIVER_PYTHON_OPTS='notebook' ~/Spark/default/bin/pyspark
```

ちなみに、ガイドにも一応記載されている。

https://github.com/apache/spark/blob/9ccae0c9e7d1a0a704e8cd7574ba508419e05e30/docs/rdd-programming-guide.md#using-the-shell
