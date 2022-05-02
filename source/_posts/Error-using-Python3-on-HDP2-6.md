---

title: Python3をHDP2.6のPySparkで用いたときのエラー
date: 2018-11-18 21:31:02
categories:
  - Knowledge Management
  - Hadoop
  - HDP
tags:
  - Spark
  - PySpark
  - HDP
  - Python3

---

# 参考

* [Hortonworksのコミュニティによる情報]
* [2to3を用いる方法の記事]
* [HortonworkによるSparkのvirtualenv対応]
* [SPARK-13587: Support virtualenv in PySpark]

[Hortonworksのコミュニティによる情報]: https://community.hortonworks.com/questions/184869/getting-error-in-python3-kernel-for-pyspark-with-h.html
[2to3を用いる方法の記事]: https://stackoverflow.com/questions/52874985/how-to-enable-python3-support-on-hdp-2-6
[HortonworkによるSparkのvirtualenv対応]: https://community.hortonworks.com/articles/104949/using-virtualenv-with-pyspark-1.html
[SPARK-13587: Support virtualenv in PySpark]: https://issues.apache.org/jira/browse/SPARK-13587

# メモ

以下のようなコマンドでPython3のipythonをドライバのPythonとして指定しながら起動したところ、
エラーを生じた。

```
$ pyspark --master yarn --conf spark.pyspark.driver.python=ipython

$ ipython --version
7.1.1
$ python --version
Python 3.6.7 :: Anaconda, Inc.
```

エラー内容は以下の通り。

```
18/11/18 12:30:09 WARN ScriptBasedMapping: Exception running /etc/hadoop/conf/topology_script.py 192.168.33.83
ExitCodeException exitCode=1:   File "/etc/hadoop/conf/topology_script.py", line 63
    print rack
             ^
SyntaxError: Missing parentheses in call to 'print'. Did you mean print(rack)?

        at org.apache.hadoop.util.Shell.runCommand(Shell.java:954)
        at org.apache.hadoop.util.Shell.run(Shell.java:855)
        at org.apache.hadoop.util.Shell$ShellCommandExecutor.execute(Shell.java:1163)
        at org.apache.hadoop.net.ScriptBasedMapping$RawScriptBasedMapping.runResolveComman
(snip)
```

[Hortonworksのコミュニティによる情報]によると、Python2系しか対応していないというが、本当かどうか確認が必要。
同様のことを指摘している記事として[2to3を用いる方法の記事]が挙げられるが、そこでは

* /usr/bin/hdp-select
* /etc/hadoop/conf/topology_script.py

の2ファイルがPython2でしか動作しない内容で記載されているようだ。
ためしに`/usr/bin/hdp-select`をのぞいてみたら、確かにPython2系に限定された実装の箇所がチラホラ見受けられた。

# Sparkでのvirtualenv対応

[SPARK-13587: Support virtualenv in PySpark]でHortonworkの人中心に議論されており、
ターゲットバージョンは3.0.1とされている。

[HortonworkによるSparkのvirtualenv対応]に記載の方法は、Hortonworksの独自拡張なのか。
