---

title: Try Apache Superset
date: 2019-01-31 22:46:58
categories:
  - Research
  - Visualization
  - Superset
tags:
  - Superset
  - Visualization

---

# 参考

* [公式ウェブサイト]
* [公式ウェブサイトのインストール手順]
* [Issue 2205]
* [Issue 6770]

[公式ウェブサイト]: https://superset.incubator.apache.org/installation.html
[公式ウェブサイトのインストール手順]: https://superset.incubator.apache.org/installation.html
[Issue 2205]: https://github.com/apache/incubator-superset/issues/2205
[Issue 6770]: https://github.com/apache/incubator-superset/issues/6770

# 動作確認

[公式ウェブサイトのインストール手順] の「Start with Docker」のとおり、進めてみたところ、
トップ画面がうまく表示されない事象が生じたので、ここでは改めてCentOS7環境に構築してみることにする。

## 必要パッケージのインストール

以下が指定されていたが、`libsasl2-devel`だけ無いというエラーが出た。

```
gcc gcc-c++ libffi-devel python-devel python-pip python-wheel openssl-devel libsasl2-devel openldap-devel
```

[Issue 2205] を見ると、cyrus-sasl-develであれば存在するようだ。

## セットアップ

`/opt/virtualenv/superset` 以下にvirtualenv環境を作り、supersetをインストールしたものとする。
その上で、公式ドキュメントを参考に以下のようなコマンドを実行する。（極力対話設定を減らしている）

```
$ source /opt/virtualenv/superset/bin/activate
$ fabmanager create-admin --app superset --username admin --firstname admin --lastname admin --password admin --email admin@fab.org
$ superset db upgrade
```

以下のようなエラーが出た。
```
Was unable to import superset Error: cannot import name '_maybe_box_datetimelike'(superset) [vagrant@superset-01 ~]$ superset db upgrade
```

[Issue 6670] を見ると、Pandasの新しいバージョンに起因する問題らしく、バージョンを下げることで対応可能だそうだ。

```
$ pip uninstall pandas
$ pip install pandas==0.23.4
```

してから、以下の通り改めて実行。

```
$ fabmanager create-admin --app superset --username admin --firstname admin --lastname admin --password admin --email admin@fab.org
$ superset db upgrade
$ superset load_examples
$ superset init
```

上記を実行し、サーバの8088ポートをブラウザで開けば、トップが画面が表示される。
