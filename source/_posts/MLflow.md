---

title: MLflow
date: 2019-06-06 00:33:39
categories:
  - Knowledge Management
  - Machine Learning
  - MLflow
tags:
  - MLflow
  - Machine Learning
  - Machine Learning Lifecycle
  - ML Model Management

---

# 参考

* [公式ドキュメント]
* [公式クイックスタート]
* [公式チュートリアル]
* [公式GitHub]
* [MLflowによる機械学習モデルのライフサイクルの管理]
* [Dockerでパッケージング]
* [where-runs-are-recorded]
* [mlflow-example]

[公式ドキュメント]: https://mlflow.org/docs/latest/
[公式クイックスタート]: https://www.mlflow.org/docs/latest/quickstart.html
[公式GitHub]: https://github.com/mlflow/mlflow
[MLflowによる機械学習モデルのライフサイクルの管理]: https://www.slideshare.net/maropu0804/mlflow
[公式チュートリアル]: https://mlflow.org/docs/latest/tutorial.html
[Dockerでパッケージング]: https://github.com/mlflow/mlflow/tree/master/examples/docker
[where-runs-are-recorded]: https://mlflow.org/docs/latest/tracking.html#where-runs-are-recorded
[mlflow-example]: https://github.com/mlflow/mlflow-example

# メモ

## クイックスタートを試す

[公式クイックスタート] の通り、簡単な例を試す。
手元のAnaconda環境で仮想環境を構築し、実行する。

```
$ /opt/Anaconda/default/bin/conda create -n mlflow ipython jupyter
$ source activate mlflow
$ pip install mlflow
```

サンプルコードを実装。実験のために、もともと載っていた内容を修正。
```
$ mkdir -p Sources/mlflow_quickstart
$ cd Sources/mlflow_quickstart
$ cat << EOF > quickstart.py 
> import os
> from mlflow import log_metric, log_param, log_artifact
> 
> if __name__ == "__main__":
>     # Log a parameter (key-value pair)
>     log_param("param1", 5)
> 
>     # Log a metric; metrics can be updated throughout the run
>     log_metric("foo", 1)
>     log_metric("foo", 2)
>     log_metric("foo", 3)
> 
>     # Log an artifact (output file)
>     with open("output.txt", "w") as f:
>         f.write("Hello world! 1\n")
>     with open("output.txt", "w") as f:
>         f.write("Hello world! 2\n")
>     log_artifact("output.txt")
>     with open("output.txt", "w") as f:
>         f.write("Hello world! 3\n")
>     log_artifact("output.txt")
> EOF
```

以下のようなファイルが生成される。
```
$ ls
mlruns  output.txt  quickstart.py
```

つづいてUIを試す。
```
$ mlflow ui
```

ブラウザで、 `http://localhost:5000/` にアクセスするとウェブUIを見られる。
メトリクスは複数回記録すると履歴となって時系列データとして見えるようだ。
一方、アーティファクトは複数回出力しても１回分（最後の１回？）分しか記録されない？

なお、複数回実行すると、時系列データとして登録される。
試行錯誤の履歴が残るようになる。

## クイックスタートのプロジェクト

[公式クイックスタート] には、MLflowプロジェクトとして取り回す方法の例として、
GitHubに登録されたサンプルプロジェクトをロードして実行する例が載っている。

```
$ mlflow run https://github.com/mlflow/mlflow-example.git -P alpha=5
```

GitHubからロードされたプロジェクトが実行される。
なお、ローカルファイルシステムのmlrunsには今回実行したときの履歴が保存される。

## チュートリアルの確認

[公式チュートリアル] を見ながら考える。
`examples/sklearn_elasticnet_wine/train.py` が取り上げられているのでまずは確認する。

27行目辺りからメイン関数。

最初にCSVファイルを読み込んでPandas DFを作る。
examples/sklearn_elasticnet_wine/train.py:32
```
    wine_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wine-quality.csv")
    data = pd.read_csv(wine_path)
```

入力ファイルを適当に分割したあと、MLflowのセッション（と呼べばよいのだろうか）を起動する。
examples/sklearn_elasticnet_wine/train.py:47
```
    with mlflow.start_run():
```

これにより、MLflowが動作に必要とするスタックなどが初期化される。
詳しくは `mlflow/tracking/fluent.py:71` あたりの `run` メソッドの実装を参照。

セッション開始後、モデルを定義し学習を実行する。
その後推論結果を取得し、メトリクスを計算する。
このあたりは通常のアプリと同じ実装。

```
        lr = ElasticNet(alpha=alpha, l1_ratio=l1_ratio, random_state=42)
        lr.fit(train_x, train_y)

        predicted_qualities = lr.predict(test_x)

        (rmse, mae, r2) = eval_metrics(test_y, predicted_qualities)
```

その後パラメータ、メトリクス、モデルを記録する。
```
        mlflow.log_param("alpha", alpha)
        mlflow.log_param("l1_ratio", l1_ratio)
        mlflow.log_metric("rmse", rmse)
        mlflow.log_metric("r2", r2)
        mlflow.log_metric("mae", mae)

        mlflow.sklearn.log_model(lr, "model")
```

このあたりが、MLflowのトラッキング機能を利用している箇所。

試しにパラメータを色々渡して実行してみる。
以下のようなシェルスクリプトを用意した。

```
for alpha in 0 1 0.5
do
  for l1_ratio in 1 0.5 0.2 0
  do
    python ~/Sources/mlflow/examples/sklearn_elasticnet_wine/train.py ${alpha} ${l1_ratio}
  done
done
```

その後、`mlflow ui` コマンドでUIを表示すると、先程試行した実験の結果がわかる。
メトリクスでソートもできるので、 モデルを試行錯誤しながら最低なモデル、パラメータを探すこともできる。

### パッケージング

チュートリアルでは、以下のようなMLprojectファイル、conda.yamlが紹介されている。

MLproject
```
name: tutorial

conda_env: conda.yaml

entry_points:
  main:
    parameters:
      alpha: float
      l1_ratio: {type: float, default: 0.1}
    command: "python train.py {alpha} {l1_ratio}"
```

このファイルはプロジェクトの定義を表すものであり、
依存関係と実装へのエントリーポイントを表す。
見てのとおり、パラメータ定義やコマンド定義が記載されている。

conda.yaml
```
name: tutorial
channels:
  - defaults
dependencies:
  - python=3.6
  - scikit-learn=0.19.1
  - pip:
    - mlflow>=1.0
```

このファイルは環境の依存関係を表す。

このプロジェクトを実行するには、以下のようにする。

```
$ mlflow run ~/Sources/mlflow/examples/sklearn_elasticnet_wine -P alpha=0.5
```

これを実行すると、conda環境を構築し、その上でアプリを実行する。
もちろん、run情報が残る。

### Dockerでパッケージング

[Dockerでパッケージング] を見ると、Dockerをビルドしてその中でアプリを動かす例も載っている。

最初にDockerイメージをビルドしておく。
```
$ cd ~/Sources/mlflow/examples/docker
$ docker build -t mlflow-docker-example -f Dockerfile .
```

つづいて、プロジェクトを実行する。
```
$ sudo mlflow run ~/Sources/mlflow/examples/docker -P alpha=0.5
```

これでconda環境で実行するのと同じように、Docker環境で実行される。

ちなみにMLprojectファイルは以下の通り。
```
name: docker-example

docker_env:
  image:  mlflow-docker-example

entry_points:
  main:
    parameters:
      alpha: float
      l1_ratio: {type: float, default: 0.1}
    command: "python train.py --alpha {alpha} --l1-ratio {l1_ratio}"
```

### モデルサーブ

チュートリアルで学習したモデルをサーブできる。
`mlflow ui` でモデルの情報を確認すると、アーティファクト内にモデルが格納されていることがわかるので、
それを対象としてサーブする。
```
$ mlflow models serve -m /home/dobachi/Sources/mlflow_tutorials/mlruns/0/a87ee8c6c6f04f5c822a32e3ecae830e/artifacts/model -p 1234
```

サーブされたモデルを使った推論は、REST APIで可能。
```
$ curl -X POST -H "Content-Type:application/json; format=pandas-split" --data '{"columns":["fixed acidity","volatile acidity","citric acid","residual sugar","chlorides","free sulfur dioxide","total sulfur dioxide","density","pH","sulphates","alcohol"],"data":[[7,0.27,0.36,20.7,0.045,45,170,1.001,3,0.45,8.8]]}' http://127.0.0.1:1234/invocations
```

## Runファイルが保存される場所

[where-runs-are-recorded] によると、以下の通り。

* Local file path (specified as file:/my/local/dir), where data is just directly stored locally.
  * →ローカルファイルシステム
* Database encoded as <dialect>+<driver>://<username>:<password>@<host>:<port>/<database>. Mlflow supports the dialects mysql, mssql, sqlite, and postgresql. For more details, see SQLAlchemy database uri.
  * →データベース（SQLAlchemyが対応しているもの）
* HTTP server (specified as https://my-server:5000), which is a server hosting an MLFlow tracking server.
  * →MLflowトラッキングサーバ
* Databricks workspace (specified as databricks or as databricks://<profileName>, a Databricks CLI profile.

### トラッキングサーバを試す

まずはトラッキングサーバを起動しておく。
```
$ mlflow server --backend-store-uri /tmp/hoge --default-artifact-root /tmp/fuga --host 0.0.0.0
```

つづいて、学習を実行する。
```
$ MLFLOW_TRACKING_URI=http://localhost:5000 mlflow run ~/Sources/mlflow/examples/sklearn_elasticnet_wine -P alpha=0.5
```

前の例と違い、環境変数MLFLOW_TRACKING_URIが利用され、上記で起動したトラッキングサーバが指定されていることがわかる。
改めてブラウザで、http://localhost:5000にアクセスすると、先程実行した学習の履歴を確認できる。

## mlflowコマンドを確認する

mlflowコマンドの実態は以下のようなPythonスクリプトである。
```
import re
import sys

from mlflow.cli import cli

if __name__ == '__main__':
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    sys.exit(cli())
```

mlflow.cliは、clickを使って実装されている。
コマンドとしては、

* run
* ui
* server

あたりに加え、以下のようなものが定義されていた。

mlflow/cli.py:260
```
cli.add_command(mlflow.models.cli.commands)
cli.add_command(mlflow.sagemaker.cli.commands)
cli.add_command(mlflow.experiments.commands)
cli.add_command(mlflow.store.cli.commands)
cli.add_command(mlflow.azureml.cli.commands)
cli.add_command(mlflow.runs.commands)
cli.add_command(mlflow.db.commands)
```

## start_runについて

mlflowを使うときには、以下のようにstart_runメソッドを呼び出す。

```
    with mlflow.start_run():
        lr = ElasticNet(alpha=alpha, l1_ratio=l1_ratio, random_state=42)
        lr.fit(train_x, train_y)

```

start_runメソッドの実態は以下のように定義されている。

mlflow/__init__.py:54
```
start_run = mlflow.tracking.fluent.start_run
```

なお、start_runの戻り値は `mlflow.ActiveRun` とのこと。

mlflow/tracking/fluent.py:155
```
    _active_run_stack.append(ActiveRun(active_run_obj))
    return _active_run_stack[-1]

```

mlflow/tracking/fluent.py:61
```
class ActiveRun(Run):  # pylint: disable=W0223
    """Wrapper around :py:class:`mlflow.entities.Run` to enable using Python ``with`` syntax."""

    def __init__(self, run):
        Run.__init__(self, run.info, run.data)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        status = RunStatus.FINISHED if exc_type is None else RunStatus.FAILED
        end_run(RunStatus.to_string(status))
        return exc_type is None

```

ActiveRunクラスは上記のような実装なので、withステートメントで用いる際には、終了処理をするようになっている。
ステータスを変更し、アクティブな実行（ActiveRun）を終了させる。

上記の構造から見るに、アクティブな実行（ActiveRun）はネスト構造？が可能なように見える。

## uiの実装

cli.pyのuiコマンドを確認すると、どうやら手元で気軽に確認するたのコマンドのようだった。

mlflow/cli.py:158
```
def ui(backend_store_uri, default_artifact_root, port):
    """
    Launch the MLflow tracking UI for local viewing of run results. To launch a production
    server, use the "mlflow server" command instead.

    The UI will be visible at http://localhost:5000 by default.
```

実際には簡易設定で、serverを起動しているようだ。

mlflow/cli.py:184
```
        _run_server(backend_store_uri, default_artifact_root, "127.0.0.1", port, 1, None, [])
```

mlflow/server/__init__.py:51
```
def _run_server(file_store_path, default_artifact_root, host, port, workers, static_prefix,
                gunicorn_opts):
    """
    Run the MLflow server, wrapping it in gunicorn
    :param static_prefix: If set, the index.html asset will be served from the path static_prefix.
                          If left None, the index.html asset will be served from the root path.
    :return: None
    """
    env_map = {}
    if file_store_path:
        env_map[BACKEND_STORE_URI_ENV_VAR] = file_store_path
    if default_artifact_root:
        env_map[ARTIFACT_ROOT_ENV_VAR] = default_artifact_root
    if static_prefix:
        env_map[STATIC_PREFIX_ENV_VAR] = static_prefix
    bind_address = "%s:%s" % (host, port)
    opts = shlex.split(gunicorn_opts) if gunicorn_opts else []
    exec_cmd(["gunicorn"] + opts + ["-b", bind_address, "-w", "%s" % workers, "mlflow.server:app"],
             env=env_map, stream_output=True)
```

なお、serverのヘルプを見ると以下の通り。
```
Usage: mlflow server [OPTIONS]

  Run the MLflow tracking server.

  The server which listen on http://localhost:5000 by default, and only
  accept connections from the local machine. To let the server accept
  connections from other machines, you will need to pass --host 0.0.0.0 to
  listen on all network interfaces (or a specific interface address).

Options:
  --backend-store-uri PATH     URI to which to persist experiment and run
                               data. Acceptable URIs are SQLAlchemy-compatible
                               database connection strings (e.g.
                               'sqlite:///path/to/file.db') or local
                               filesystem URIs (e.g.
                               'file:///absolute/path/to/directory'). By
                               default, data will be logged to the ./mlruns
                               directory.
  --default-artifact-root URI  Local or S3 URI to store artifacts, for new
                               experiments. Note that this flag does not
                               impact already-created experiments. Default:
                               Within file store, if a file:/ URI is provided.
                               If a sql backend is used, then this option is
                               required.
  -h, --host HOST              The network address to listen on (default:
                               127.0.0.1). Use 0.0.0.0 to bind to all
                               addresses if you want to access the tracking
                               server from other machines.
  -p, --port INTEGER           The port to listen on (default: 5000).
  -w, --workers INTEGER        Number of gunicorn worker processes to handle
                               requests (default: 4).
  --static-prefix TEXT         A prefix which will be prepended to the path of
                               all static paths.
  --gunicorn-opts TEXT         Additional command line options forwarded to
                               gunicorn processes.
  --help                       Show this message and exit.
```

なお、上記ヘルプを見ると、runデータを保存するのはデフォルトではローカルファイルシステムだが、
SQLAlchemyでアクセス可能なRDBMSでも良いようだ。

サーバとして、gunicornを使っているようだ。
多数のリクエストをさばくため、複数のワーカを使うこともできるようだ。

mlflow/server/__init__.py:68
```
    exec_cmd(["gunicorn"] + opts + ["-b", bind_address, "-w", "%s" % workers, "mlflow.server:app"],
             env=env_map, stream_output=True)
```

上記の通り、 `mlflow.server:app` が実態なので確認する。
このアプリケーションはFlaskが用いられている。
いったん、 `/` の定義から。

mlflow/server/__init__.py:45
```
# Serve the index.html for the React App for all other routes.
@app.route(_add_static_prefix('/'))
def serve():
    return send_from_directory(STATIC_DIR, 'index.html')
```

mlflow/server/__init__.py:16
```
REL_STATIC_DIR = "js/build"

app = Flask(__name__, static_folder=REL_STATIC_DIR)
STATIC_DIR = os.path.join(app.root_path, REL_STATIC_DIR)
```

以上のように、 `mlflow/server/js` 以下にアプリが存在するようだが、
そのREADME.mdを見ると、当該アプリは https://github.com/facebook/create-react-app を
使って開発されたように見える。

## mlflow-exampleプロジェクトを眺めてみる

[mlflow-example] には、mlflow公式のサンプルプロジェクトが存在する。
この中身を軽く眺めてみる。

### MLproject

ファイルの内容は以下の通り。

```
name: tutorial

conda_env: conda.yaml

entry_points:
  main:
    parameters:
      alpha: float
      l1_ratio: {type: float, default: 0.1}
    command: "python train.py {alpha} {l1_ratio}"

```

プロジェクト名は `tutorial` であり、condaによる環境構成情報は別途 conda.yaml に定義されていることがわかる。

エントリポイントには複数を定義可能だが、ここでは1個のみ（`main`のみ）定義されている。
パラメータは2個（`alpha`、`l1_ratio`）与えられている。
それらのパラメータは、実行コマンド定義内でコマンドライン引数として渡されることになっている。

なお、実行されるPythonスクリプト内では以下のように、コマンドライン引数を処理している。

train.py:44
```
    alpha = float(sys.argv[1]) if len(sys.argv) > 1 else 0.5
    l1_ratio = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5
```

### conda.yaml

本ファイルには、condaを使ってインストールするライブラリが指定されている。

```
name: tutorial
channels:
  - defaults
dependencies:
  - numpy=1.14.3
  - pandas=0.22.0
  - scikit-learn=0.19.1
  - pip:
    - mlflow
```

numpy、pandas、scikit-learnあたりの基本的なライブラリをcondaで導入し、
最後にpipでmlflowを導入していることがわかる。

またチャンネルの設定もできるようであるが、ここではデフォルトのみ使用することになっている。

### train.py

ここでは、ハイライトを確認する。

最初に入力データの読み出しと分割等。

train.py:31
```
    # Read the wine-quality csv file (make sure you're running this from the root of MLflow!)
    wine_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wine-quality.csv")
    data = pd.read_csv(wine_path)

    # Split the data into training and test sets. (0.75, 0.25) split.
    train, test = train_test_split(data)

    # The predicted column is "quality" which is a scalar from [3, 9]
    train_x = train.drop(["quality"], axis=1)
    test_x = test.drop(["quality"], axis=1)
    train_y = train[["quality"]]
    test_y = test[["quality"]]
```

MLflowのセッションを開始

train.py:47
```
    with mlflow.start_run():
```

モデルを定義し、学習。その後テストデータを用いて予測値を算出し、メトリクスを計算する。

train.py:48
```
        lr = ElasticNet(alpha=alpha, l1_ratio=l1_ratio, random_state=42)
        lr.fit(train_x, train_y)

        predicted_qualities = lr.predict(test_x)

        (rmse, mae, r2) = eval_metrics(test_y, predicted_qualities)

```

上記のメトリクスは標準出力にも出されるようにもなっている。
手元で試した例では、以下のような感じ。

```
Elasticnet model (alpha=5.000000, l1_ratio=0.100000):
  RMSE: 0.8594260117338262
  MAE: 0.6480675144220314
  R2: 0.046025292604596424
```

最後に、メトリクスを記録し、モデルを保存する。

train.py:60
```
        mlflow.log_param("alpha", alpha)
        mlflow.log_param("l1_ratio", l1_ratio)
        mlflow.log_metric("rmse", rmse)
        mlflow.log_metric("r2", r2)
        mlflow.log_metric("mae", mae)

        mlflow.sklearn.log_model(lr, "model")

```

## 【ボツ】Dockeでクイックスタートを実行

※以下の手順は、UIを表示させようとしたところでエラーになっている。まだ原因分析していない。 -> おおかたバインドするアドレスが127.0.0.1になっており、外部から参照できなくなっているのでは、と。->  `mlflow ui` の実装をぱっと見る限り、そうっぽい。

[公式GitHub] からCloneし、Dockerイメージをビルドする。
これを実行環境とする。

```
$ cd Sources
$ git clone https://github.com/mlflow/mlflow.git
$ cd mlflow/examples/docker
```

なお、実行時に便利なようにDockerfileを以下のように修正し、ipython等をインストールしておく。

```
diff --git a/examples/docker/Dockerfile b/examples/docker/Dockerfileindex e436f49..686e0e2 100644--- a/examples/docker/Dockerfile+++ b/examples/docker/Dockerfile@@ -1,5 +1,7 @@ FROM continuumio/miniconda:4.5.4+RUN conda install ipython jupyter
+ RUN pip install mlflow>=1.0 \
     && pip install azure-storage==0.36.0 \
     && pip install numpy==1.14.3
```

ではビルドする。
```
$ sudo -i docker build -t "dobachi/mlflow:latest" `pwd`
```

チュートリアルのサンプルアプリを作成する。
```
$ cat << EOF > tutorial.py
> import os
> from mlflow import log_metric, log_param, log_artifact
>
> if __name__ == "__main__":
>     # Log a parameter (key-value pair)
>     log_param("param1", 5)
>
>     # Log a metric; metrics can be updated throughout the run
>     log_metric("foo", 1)
>     log_metric("foo", 2)
>     log_metric("foo", 3)
>
>     # Log an artifact (output file)
>     with open("output.txt", "w") as f:
>         f.write("Hello world!")
>     log_artifact("output.txt")
> EOF
```

起動する。
このとき、サンプルアプリも `/apps` 以下にマウントするようにする。

```
$ sudo -i docker run -v `pwd`:/apps --rm -it dobachi/mlflow:latest  /bin/bash
```

先程作成したアプリを実行する。
```
# cd apps
# python tutorial.py
```

結果は以下の通り。
```
# cat output.txt  
Hello world!
```

ここで `mlflow ui` を起動して見ようと持ったが、ウェブフロントエンドに繋がらなかった。
デバッグを試みる。
