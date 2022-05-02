---

title: Machine Learning Model Management Tools
date: 2019-02-09 12:54:33
categories:
  - Knowledge Management
  - Machine Learning
  - Model Management
tags:
  - Machine Learning
  - Model Management

---

# 参考

## Strata

* [Strata Model Lifecycle Management]

[Strata Model Lifecycle Management]: https://conferences.oreilly.com/strata/strata-ny-2018/public/schedule/stopic/2833?utm_medium=content+synd&utm_source=oreilly.com&utm_campaign=stny18&utm_content=mlflow+a+platform+for+managing+the+machine+learning+lifecycle+top+cta

## studio.ml

* [studio.ml]
* [studio.ml Issue-330]
* [studio.mlの公式GitHub]

[studio.ml]: https://www.studio.ml/
[studio.ml Issue-330]: https://github.com/studioml/studio/issues/330
[studio.mlの公式GitHub]: https://github.com/studioml/studio

## ModelDB

* [ModelDBの公式GitHub]
* [ModelDB紹介 at Spark Summit]
* [ModelDB Clientの例]

[ModelDBの公式GitHub]: https://github.com/mitdbg/modeldb
[ModelDB紹介 at Spark Summit]: https://databricks.com/session/modeldb-a-system-to-manage-machine-learning-models
[ModelDB BasicWorkflow.py]: https://github.com/mitdbg/modeldb/blob/master/client/python/samples/basic/BasicWorkflow.py
[ModelDB BasicSyncAll.py]: https://github.com/mitdbg/modeldb/blob/master/client/python/samples/basic/BasicSyncAll.py
[ModelDB Clientの例]: http://modeldb.csail.mit.edu:8000/user/TqNzCVawBirw/tree
[ModelDB ウェブUIの例]: http://modeldb.csail.mit.edu:3000/projects

## MLflow

* [MLflowのO'Reilly記事]

[MLflowのO'Reilly記事]: https://www.oreilly.com/ideas/mlflow-a-platform-for-managing-the-machine-learning-lifecycle

## Clipper

* [Strata NY 2018でのClipper]
* [RISELabのページ]
* [Clipperの論文]
* [バンディットアルゴリズムについての説明]

[Strata NY 2018でのClipper]: https://conferences.oreilly.com/strata/strata-ny-2018/public/schedule/detail/69861
[RISELabのページ]: https://rise.cs.berkeley.edu/projects/clipper/
[Clipperの論文]: https://rise.cs.berkeley.edu/wp-content/uploads/2017/02/clipper_final.pdf
[バンディットアルゴリズムについての説明]: https://www.slideshare.net/greenmidori83/ss-28443892

## Azure Machine Learning Studio

* [Azure Machine Learning Studio]
* [Azure Machine Learning Studio公式ドキュメント]

[Azure Machine Learning Studio]: https://azure.microsoft.com/ja-jp/services/machine-learning-studio/
[Azure Machine Learning Studio公式ドキュメント]: https://docs.microsoft.com/ja-jp/azure/machine-learning/studio/

## Hydrosphere Serving

[Hydrosphere.io] のページを参照。

[Hydrosphere.io]: /memo-blog/2019/03/22/Hydrosphere-io/

# studio.ml

Pythonベースの機械学習モデル管理のフレームワーク。
対応しているのは、Keras、TensorFlow、scikit-learnあたり。

## 注意事項

[studio.mlの公式GitHub]のREADMEを読むと「Authentication」の項目があり、
studio.mlに何らかの手段で認証しないといけないようである。
ゲストモードがあるようだが極力アカウント情報を渡さずに使おうとしたが
うまく動作しなかった。

## インストールと動作確認

```
$ /opt/Anaconda/default/bin/conda create -n studioml python
$ conda activate stduioml
$ pip install studioml
```

以下のようなエラーが生じた。

```
awscli 1.16.101 has requirement rsa<=3.5.0,>=3.1.2, but you'll have rsa 4.0 which is incompatible.
```

```
$ cd ~/Sources
$ git clone https://github.com/studioml/studio.git
$ cd studio
$ cd examples/keras/
```

ここでGitHub上のREADMEに記載のとおり、`~/.studioml/config.yaml`のdatabaseセクションに
`guest: true`を追加した。

いったんUIを起動してみる。

```
$ studio ui
```

以下のようなエラーが出た。

```
  File "/home/******/.conda/envs/studioml/lib/python3.7/site-packages/flask/app.py", line 1813, in full_dispatch_request    rv = self.dispatch_request()  File "/home/******/.conda/envs/studioml/lib/python3.7/site-packages/flask/app.py", line 1799, in dispatch_request    return self.view_functions[rule.endpoint](**req.view_args)  File "/home/******/.conda/envs/studioml/lib/python3.7/site-packages/studio/apiserver.py", line 37, in dashboard    return _render('dashboard.html')  File "/home/******/.conda/envs/studioml/lib/python3.7/site-packages/studio/apiserver.py", line 518, in _render    auth = get_auth(get_auth_config())  File "/home/******/.conda/envs/studioml/lib/python3.7/site-packages/studio/apiserver.py", line 511, in get_auth_config    return get_config()['server']['authentication']

KeyError: 'server'
```

参考: [studio.ml Issue-330]

設定を以下のように変えてみた。

```
--- /home/dobachi/.studioml/config.yaml.2019021001      2019-02-10 01:04:10.751282800 +0900
+++ /home/dobachi/.studioml/config.yaml 2019-02-10 01:17:20.178761700 +0900
@@ -2,6 +2,10 @@
     type: http     serverUrl: https://zoo.studio.ml
     authentication: github
+    guest: true
+
+server:
+    authentication: None

 storage:
     type: gcloud
```

ブラウザで`http://localhost:5000`にアクセスした所、開けたような気がしたが、
GitHubの404ページが表示された。

コンソール上のエラーは以下のとおり。

```
requests.exceptions.ConnectionError: HTTPSConnectionPool(host='zoo.studio.ml', port=443): Max retries exceeded with url: /api/get_user_experiments (Caused by NewConnectionError('<urllib3.connection.VerifiedHTTPSConnection object at 0x7ff5a64a3da0>: Failed to establisha new connection: [Errno -2] Name or service not known'))
```

# ModelDB

## 注意点

[ModelDBの公式GitHub]を見ると、20190211時点で最近更新されていないようだ。（最新が6ヶ月前の更新）

## 概要

モデルの情報を構造的に管理するための仕組み。
「ModelDB's Light API」を通じて、モデルのメトリクスとメタデータを管理できるようになる。
spark.mlとscikit-learnはネイティブクライアントを利用する。 ★要確認

[ModelDBの公式GitHub]のREADMEにわかりやすいフロントエンドの紹介がある。

## Light APIの例

[ModelDB BasicWorkflow.py]がワークフローの基本が分かる例。
基本は、 `Syncer`を使ってモデルの情報を登録する。
この例では、

* データセット
* モデル
* モデルのコンフィグ
* モデルのメトリクス

をModelDBに登録する。

[ModelDB BasicSyncAll.py]がYAMLで登録する例。

## Native API利用の例

[ModelDB Clientの例]に`modeldb.sklearn_native.SyncableMetrics`の利用例が記載されている。

## ウェブUIの例

[ModelDB ウェブUIの例]に例が載っている。

# MLflow

## 概要

[MLflowのO'Reilly記事]に動機と機能概要が書かれている。
また動画でウェブUIの使い方が示されている。

### 動機

* 無数のツールを組み合わせるのが難しい
* 実験をトレースするのが難しい
* 結果の再現性担保が難しい
* デプロイが面倒

### 機能

* トラッキング
  * パラメータ、コードバージョン、メトリクス、アウトプットファイルなどを管理する
* プロジェクト
  * コードをパッケージングし、結果の再現性を担保する。またユーザ間でプロジェクトを流通できる
  * conda形式で依存関係を記述可能であり、実行コマンドも定義可能
  * もしMLflowの機能でトラッキングしていれば、バージョンやパラメータをトラックする
* モデル
  * モデルをパッケージングし、デプロイできるようにする

# Clipper

[Strata NY 2018でのClipper] が講演のようだが、スライドが公開されていない。

## Clipper: A Low-Latency Online Prediction Serving System

[Clipperの論文]によると、「A Low-Latency Online Prediction Serving System」と定義されている。
上記論文の図1を見るかぎり、モデルサービングを担い、複数の機械学習モデルをまとめ上げる「中層化」層の
役割も担うようだ。
また、モデル選択の機能、キャッシングなどの機能も含まれているようである。

これまでの研究では、学習フェーズに焦点が当たることが多かったが、
この研究では推論フェーズに焦点を当てている。

### アーキ概要

* モデル抽象化層
* モデル選択層

論文Figure 1参照。

# Azure Machine Learning Studio

[Azure Machine Learning Studio]には、「完全に管理されたクラウド サービスで、ユーザーは簡単に予測分析ソリューションを構築、デプロイ、共有できます。」と
記載されている。


# Hydrosphere Serving

[Hydrosphere.io] のページを参照。
