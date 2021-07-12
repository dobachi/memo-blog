---

title: Hydrosphere.io
date: 2019-03-22 19:43:38
categories:
  - Knowledge Management
  - Machine Learning
tags:
  - Machine Learning
  - Model Management

---

# Hydrosphere.ioについて

## 参考

* [Hydroshpereブログの最も古い記事]

[Hydroshpereブログの最も古い記事]: https://hydrosphere.io/blog/about-hydrosphere/

## メモ

[Hydroshpereブログの最も古い記事] が投稿されたのは、2016/6/14である。
上記ブログで強調されていたのは、Big DataプロジェクトのDevOps対応。
DockerやAnsibleといった道具を使いながら。



# Hydrosphere Serving

## 参考情報

* [Hydro Servingの公式GitHub]
* [Envoy proxyについての日本語記事]
* [Hydro Servingの公式ウェブサイト]
* [Hydro ServingでTensorFlowモデルをサーブ]

[Hydro Servingの公式ウェブサイト]: https://hydrosphere.io/serving/
[Hydro Servingの公式GitHub]: https://github.com/Hydrospheredata/hydro-serving
[Envoy proxyについての日本語記事]: https://qiita.com/seikoudoku2000/items/9d54f910d6f05cbd556d
[Hydro ServingでTensorFlowモデルをサーブ]: https://hydrosphere.io/serving-docs/tensorflow.html
[Hydro Servingの公式ドキュメント]: https://hydrosphere.io/serving-docs


## 開発状況

2019/03/21現在でも、わりと活発に開発されているようだ。
https://github.com/Hydrospheredata/hydro-serving/graphs/commit-activity

開発元は、hydrosphere.io。パロアルトにある企業らしい。

### hydrosphere.ioのプロダクト

ここで取り上げているServingを含む、以下のプロダクトがある。

* Serving: モデルのサーブ、アドホック分析への対応
* Sonar: モデルやパイプラインの品質管理
* Mist: Sparkの計算リソースをREST API経由で提供する仕組み（マルチテナンシーの実現）

## 概要

GitHubのREADMEに特徴が書かれていが、その中でも個人的にポイントと思ったのは以下の通り。

* Envoyプロキシを用いてサービスメッシュ型のサービングを実現
* 複数の機械学習モデルに対応し、パイプライン化も可能
* UIがある

[Hydro Servingの公式ウェブサイト] に掲載されていた動画を見る限り、
コマンドライン経由でモデルを登録することもでき、モデルを登録したあとは、
処理フロー（ただし、シリアルなフローに見える）を定義可能。
例えば、機械学習モデルの推論器に渡す前処理・後処理も組み込めるようだ。

### セットアップ方法

Docker Composeを使う方法とk8sを使う方法があるようだ。

### 利用方法

モデルを学習させ、出力する。（例では、h5形式で出力していた）
モデルや必要なライブラリを示したテキストなどを、ペイロードとして登楼する。

必要なライブラリの指定は以下のようにする。

requirements.txt
```
Keras==2.2.0
tensorflow==1.8.0
numpy==1.13.3
```

また、それらの規約事項は、contract（定義ファイル）として保存する。
フォルダ内の構成は以下のようになる。

公式ドキュメントから引用
```
linear_regression
├── model.h5
├── model.py
├── requirements.txt
├── serving.yaml
└── src
    └── func_main.py
```

上記のようなファイル群を作り、 `hs upload`コマンドを使ってアップロードする。
アップロードしたあとは、ウェブフロントエンドから処理フローを定義する。


クエリはREST APIで以下のように投げる。

公式ウェブサイトから引用
```
$ curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
"x": [[1, 1],[1, 1]]}' 'http://localhost/gateway/applications/linear_regression/infer'
```

また上記のREST APIの他にも、gRPCを用いて推論結果を取得することも可能。
また、データ構造としてはTensorProtoを使える。

なお、TensorFlowモデルのサーブについては、
公式ウェブサイトの [Hydro ServingでTensorFlowモデルをサーブ] がわかりやすい。
また、単純にPython関数を渡すこともできる。（必ずしもTensorFlowにロックインではない）

## コンセプト

* モデル
  * Hydro Servingに渡されたモデルはバージョン管理される。
  * フレーワークは多数対応
    * ただしフレームワークによって、出力されるメタデータの情報量に差がある。
* アプリケーション
  * 単一で動かす方法とパイプラインを構成する方法がある
* ランタイム
  * 予め実行環境を整えたDockerイメージが提供されている
  * Python、TensorFlow、Spark

## 動作確認

[Hydro Servingの公式ドキュメント] に従って動作確認する。

```
$ mkdir HydroServing
$ cd HydroServing/
$ git clone https://github.com/Hydrospheredata/hydro-serving
$ hydro-serving
$ sudo docker-compose up -d
```

起動したコンテナを確認する。

```
$ sudo docker-compose ps
  Name                 Command               State                        Ports
-----------------------------------------------------------------------------------------------------
gateway     /hydro-serving/app/start.sh      Up      0.0.0.0:29090->9090/tcp, 0.0.0.0:29091->9091/tcp
manager     /hydro-serving/app/start.sh      Up      0.0.0.0:19091->9091/tcp
managerui   /bin/sh -c envsubst '${MAN ...   Up      80/tcp, 9091/tcp
postgres    docker-entrypoint.sh postgres    Up
sidecar     /hydro-serving/start.sh          Up      0.0.0.0:80->8080/tcp, 0.0.0.0:8082->8082/tcp
```

その他CLIを導入する。

```
$ conda create -n hydro-serving python=3.6 python
$ source activate hydro-serving
$ conda install keras scikit-learn
$ pip install hs
```

エラーが生じた。

```
$ hs cluster add --name local --server http://localhost
--- Logging error ---
Traceback (most recent call last):
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/logging/__init__.py", line 992, in emit
    msg = self.format(record)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/logging/__init__.py", line 838, in format
    return fmt.format(record)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/logging/__init__.py", line 575, in format
    record.message = record.getMessage()
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/logging/__init__.py", line 338, in getMessage
    msg = msg % self.args
TypeError: not all arguments converted during string formatting
Call stack:
  File "/home/centos/.conda/envs/hydro-serving/bin/hs", line 11, in <module>
    sys.exit(hs_cli())
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/click/core.py", line 722, in __call__
    return self.main(*args, **kwargs)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/click/core.py", line 697, in main
    rv = self.invoke(ctx)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/click/core.py", line 1063, in invoke
    Command.invoke(self, ctx)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/click/core.py", line 895, in invoke
    return ctx.invoke(self.callback, **ctx.params)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/click/core.py", line 535, in invoke
    return callback(*args, **kwargs)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/click/decorators.py", line 17, in new_func
    return f(get_current_context(), *args, **kwargs)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/hydroserving/cli/hs.py", line 18, in hs_cli
    ctx.obj.services = ContextServices.with_config_path(HOME_PATH_EXPANDED)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/hydroserving/models/context_object.py", line 44, in with_config_path
    config_service = ConfigService(path)
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/hydroserving/services/config.py", line 17, in __init__
    logging.error("{} is not an existing directory", home_path)
Message: '{} is not an existing directory'
Arguments: ('/home/centos/.hs-home',)
WARNING:root:Using local as current cluster
Cluster 'local' @ http://localhost added successfully
```

エラーが出ているのに登録されたように見える。
念の為、クラスタ情報を確認する。

```
$ hs cluster
Current cluster: {'cluster': {'server': 'http://localhost'}, 'name': 'local'}
```

いったんこのまま進める。
まずはアプリを作成。

```
$ mkdir -p ~/Sources/linear_regression
$ cd ~/Sources/linear_regression
$ cat << EOF > model.py
  from keras.models import Sequential
  from keras.layers import Dense
  from sklearn.datasets import make_regression
  from sklearn.model_selection import train_test_split
  from sklearn.preprocessing import MinMaxScaler
  
  # initialize data
  n_samples = 1000
  X, y = make_regression(n_samples=n_samples, n_features=2, noise=0.5, random_state=112)
  
  scallar_x, scallar_y = MinMaxScaler(), MinMaxScaler()
  scallar_x.fit(X)
  scallar_y.fit(y.reshape(n_samples, 1))
  X = scallar_x.transform(X)
  y = scallar_y.transform(y.reshape(n_samples, 1))
  
  # create a model
  model = Sequential()
  model.add(Dense(4, input_dim=2, activation='relu'))
  model.add(Dense(4, activation='relu'))
  model.add(Dense(1, activation='linear'))
  
  model.compile(loss='mse', optimizer='adam')
  model.fit(X, y, epochs=100)
  
  # save model
  model.save('model.h5')
  EOF
```

学習し、モデルを出力。

```
$ python model.py
```

サーブ対象となる関数のアプリを作成する。
```
$ mkdir src
$ cd src
$ cat << EOF > func_main.py
  import numpy as np
  import hydro_serving_grpc as hs
  from keras.models import load_model
  
  # 0. Load model once
  model = load_model('/model/files/model.h5')
  
  def infer(x):
      # 1. Retrieve tensor's content and put it to numpy array
      data = np.array(x.double_val)
      data = data.reshape([dim.size for dim in x.tensor_shape.dim])
  
      # 2. Make a prediction
      result = model.predict(data)
      
      # 3. Pack the answer
      y_shape = hs.TensorShapeProto(dim=[hs.TensorShapeProto.Dim(size=-1)])
      y_tensor = hs.TensorProto(
          dtype=hs.DT_DOUBLE,
          double_val=result.flatten(),
          tensor_shape=y_shape)
  
      # 4. Return the result
      return hs.PredictResponse(outputs={"y": y_tensor})
  EOF
```


```
$ cd ..
$ cat << EOF > serving.yaml
  kind: Model
  name: linear_regression
  model-type: python:3.6
  payload:
    - "src/"
    - "requirements.txt"
    - "model.h5"
  
  contract:
    infer:                    # Signature function
      inputs:
        x:                    # Input field
          shape: [-1, 2]
          type: double
          profile: numerical
      outputs:
        y:                    # Output field
          shape: [-1]
          type: double
          profile: numerical
  EOF
```

つづいて必要ライブラリを定義する。
```
$ cat << EOF > requirements.txt
  Keras==2.2.0
  tensorflow==1.8.0
  numpy==1.13.3
  EOF
```

最終的に以下のような構成になった。

```
$ tree
.
├── model.h5
├── model.py
├── requirements.txt
├── serving.yaml
└── src
    └── func_main.py

1 directory, 5 files
```

つづいてモデルなどをアップロード。
```
$ hs upload
```

ここで以下のようなエラーが生じた。
```
Using 'local' cluster
['/home/centos/Sources/linear_regression/src', '/home/centos/Sources/linear_regression/requirements.txt', '/home/centos/Sources/linear_regression/model.h5']
Packing the model  [####################################]  100%
Assembling the model  [####################################]  100%
Uploading to http://localhost
Uploading model assembly  [####################################]  100%
Traceback (most recent call last):
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/hydroserving/httpclient/remote_connection.py", line 82, in postprocess_response
    response.raise_for_status()
  File "/home/centos/.conda/envs/hydro-serving/lib/python3.6/site-packages/requests/models.py", line 940, in raise_for_status
    raise HTTPError(http_error_msg, response=self)
requests.exceptions.HTTPError: 404 Client Error: Not Found for url: http://localhost/api/v1/model/upload

During handling of the above exception, another exception occurred:

(snip)
```

軽く調べると [ISSUE255](https://github.com/Hydrospheredata/hydro-serving/issues/255) が
関係していそうである。

ここでは動作確認のため、`pip install hs==2.0.0rc2`としてインストールして試した。

```
$ pip uninstall hs
$ pip install hs==2.0.0rc2
```

また、 `serving.yaml` に以下のエントリを追加した。

```
runtime: "hydrosphere/serving-runtime-python:3.6-latest"
```

再び `hs upload` したところ完了のように見えた。

ウェブUIを確認したところ以下の通り。

![ウェブUIに登録されたモデルが表示される](/memo-blog/images/01lS2mkR9Pm3g4xJ-43D69.png)


それではテストを実行してみる。
```
$ curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{   "x": [     [       1,       1     ]   ] }' 'http://10.0.0.209/gateway/application/linear_regression'
```

以下のようなエラーが生じた。
```
{"error":"InternalUncaught","information":"UNKNOWN: Exception calling application: No module named 'numpy'"}
```

ランタイム上にnumpyがインストールされなかったのだろうか・・・

WIP

# Hydro sonar

## 参考

* [Hydro Sonarの公式ウェブサイト]
* [公式のGUI画面]

[Hydro Sonarの公式ウェブサイト]: https://hydrosphere.io/sonar/
[公式のSonarのGUI画面]: https://hydrosphere.io/wp-content/uploads/2019/01/Screenshot-at-Jan-21-19-00-31-1050x755.png

## メモ

[公式のSonarのGUI画面] を見ると、モデルの性能を観測するための仕組みに見える。
モデル選択、メンテナンス、リアイアメントのために用いられる。
例えば、入力データ変化を起因したモデル精度の劣化など。

# Hydro Mist

## 参考

* [Hydro Mistの公式ウェブサイト]
* [公式のMistのアーキテクチャイメージ]
* [Hydro Mistの公式ドキュメント]
* [Hydro Mistの公式クイックスタート]
* [Hydro Mistがどうやってジョブを起動するか]
* [Hydro Mistのジョブのステート]
* [Hydro Mistのジョブローンチの流れ]
* [Hydro Mistのコンテキスト管理]
* [Hydro MIstのmist-cliのGitHub]
* [Hydro Mistのコンフィグの例]
* [Hydro MistのScala API]

[Hydro Mistの公式ウェブサイト]: https://hydrosphere.io/mist/
[公式のMistのアーキテクチャイメージ]: https://hydrosphere.io/wp-content/uploads/2016/06/Mist-scheme-1050x576.png
[Hydro Mistの公式ドキュメント]: https://hydrosphere.io/mist-docs/
[Hydro Mistの公式クイックスタート]: https://hydrosphere.io/mist-docs/quick_start.html
[Hydro Mistがどうやってジョブを起動するか]: https://hydrosphere.io/mist-docs/invocation.html
[Hydro Mistのジョブのステート]: https://hydrosphere.io/mist-docs/invocation.html#job-statuses
[Hydro Mistのジョブローンチの流れ]: https://hydrosphere.io/mist-docs/invocation.html#steps
[Hydro Mistのコンテキスト管理]: https://hydrosphere.io/mist-docs/contexts.html
[Hydro MIstのmist-cliのGitHub]: https://github.com/Hydrospheredata/mist-cli
[Hydro Mistのコンフィグの例]: https://github.com/Hydrospheredata/mist-cli/tree/master/example/my-awesome-job
[Hydro MistのScala API]: https://hydrosphere.io/mist-docs/lib_scala.html
[Hydro MistのHTTP API]: https://hydrosphere.io/mist-docs/http_api.html
[Hydro MistのReactive API]: https://hydrosphere.io/mist-docs/reactive_api.html
[Hydro MistのEMR連係]: https://hydrosphere.io/mist-docs/aws-emr.html

## メモ

[公式のMistのアーキテクチャイメージ] を見ると、
Sparkのマルチテナンシーを実現するものに見える。

特徴として挙げられていたものの中で興味深いのは以下。

* Spark Function as a Service
* ユーザのAPIをSparkのコンフィグレーションから分離する
* HTTP、Kafka、MQTTによるやりとり

[Hydro Mistの公式クイックスタート]を見ると、Scala、Java、Pythonのサンプルアプリが掲載されている。
Mistはライブラリとしてインポートし、フレームワークに則ってアプリを作成すると、
アプリ内で定義された関数を実行するジョブをローンチできるようになる。

また実際にローンチするときには、REST API等で起動することになるが、
そのときに引数を渡すこともできる。

## 動作確認

[Hydro Mistの公式クイックスタート] に従い動作を確認する。
Dockerで実行するか、バイナリで実行するかすれば良い。

### Dockerでの起動

Dockerの場合は以下の通り。

```
$ sudo docker run -p 2004:2004 \
   -v /var/run/docker.sock:/var/run/docker.sock \
   hydrosphere/mist:1.1.1-2.3.0
```

### バイナリを配備しての起動

バイナリをダウンロードして実行する場合は以下の通り。
まずSparkをダウンロードする。（なお、JDKは予めインストールされていることを前提とする）

```
$ mkdir ~/Spark
$ cd ~/Spark
$ wget http://ftp.riken.jp/net/apache/spark/spark-2.3.3/spark-2.3.3-bin-hadoop2.7.tgz
$ tar xvzf spark-2.3.3-bin-hadoop2.7.tgz
$ ln -s spark-2.3.3-bin-hadoop2.7 default
```

これで、~/Spark/default以下にSparkが配備された。
つづいて、Hydro Mistのバイナリをダウンロードし、配備する。

```
$ mkdir ~/HydroMist
$ cd ~/HydroMist
$ wget http://repo.hydrosphere.io/hydrosphere/static/mist-1.1.1.tar.gz
$ tar xvfz mist-1.1.1.tar.gz
$ ln -s mist-1.1.1 default
$ cd default
```

以上でHydro Mistが配備された。
それではHydro Mistのマスタを起動する。

```
$ SPARK_HOME=${HOME}/Spark/default ./bin/mist-master start --debug true
```

以上で、バイナリを配備したHydro Mistが起動する。

### Mistの動作確認

以降、サンプルアプリを実行している。

まずmistのCLIを導入する。

```
$ conda create -n mist python=3.6 python
$ source activate mist
$ pip install mist-cli
```

続いて、サンプルプロジェクトをcloneする。

```
$ mkdir -p ~/Sources
$ cd ~/Sources
$ git clone https://github.com/Hydrospheredata/hello_mist.git
```

試しにScala版を動かす。
（なお、SBTがインストールされていることを前提とする）

```
$ cd hello_mist/scala
$ sbt package
$ mist-cli apply -f conf -u ''
```

上記コマンドの結果、以下のような出力が得られる。

```
Process 5 file entries
updating Artifact hello-mist-scala_0.0.1.jar
Success: Artifact hello-mist-scala_0.0.1.jar
updating Context emr_ctx
Success: Context emr_ctx
updating Context emr_autoscale_ctx
Success: Context emr_autoscale_ctx
updating Context standalone
Success: Context standalone
updating Function hello-mist-scala
Success: Function hello-mist-scala


Get context info
--------------------------------------------------------------------------------
curl -H 'Content-Type: application/json' -X POST http://localhost:2004/v2/api/contexts/emr_ctx


Get context info
--------------------------------------------------------------------------------
curl -H 'Content-Type: application/json' -X POST http://localhost:2004/v2/api/contexts/emr_autoscale_ctx


Get context info
--------------------------------------------------------------------------------
curl -H 'Content-Type: application/json' -X POST http://localhost:2004/v2/api/contexts/standalone


Get info of function resource
--------------------------------------------------------------------------------
curl  -H 'Content-Type: application/json' -X GET http://localhost:2004/v2/api/functions/hello-mist-scala

Start job via mist-cli
--------------------------------------------------------------------------------
mist-cli --host localhost --port 2004 start job hello-mist-scala '{"samples": 7}'

Start job via curl
--------------------------------------------------------------------------------
curl --data '{"samples": 7}' -H 'Content-Type: application/json' -X POST http://localhost:2004/v2/api/functions/hello-mist-scala/jobs?force=true

```

試しに`standalone`のコンテキストを確認してみる。
（なお、上記メッセージではPOSTを使うよう書かれているが、GETでないとエラーになった）

```
$ curl -H 'Content-Type: application/json' -X GET http://localhost:2004/v2/api/contexts/standalone | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   252  100   252    0     0  26537      0 --:--:-- --:--:-- --:--:-- 28000
{
  "name": "standalone",
  "maxJobs": 1,
  "maxConnFailures": 1,
  "workerMode": "exclusive",
  "precreated": false,
  "sparkConf": {
    "spark.submit.deployMode": "cluster",
    "spark.master": "spark://holy-excalibur:7077"
  },
  "runOptions": "",
  "downtime": "1200s",
  "streamingDuration": "1s"
}
```

なお、サンプルアプリは以下の通り。
Piの値を簡易的に計算するものである。

```
import mist.api._
import mist.api.dsl._
import mist.api.encoding.defaults._
import org.apache.spark.SparkContext

object HelloMist extends MistFn with Logging {

  override def handle = {
    withArgs(
      arg[Int]("samples", 10000)
    )
    .withMistExtras
    .onSparkContext((n: Int, extras: MistExtras, sc: SparkContext) => {
      import extras._

      logger.info(s"Hello Mist started with samples: $n")

      val count = sc.parallelize(1 to n).filter(_ => {
        val x = math.random
        val y = math.random
        x * x + y * y < 1
      }).count()

      val pi = (4.0 * count) / n
      pi
    }).asHandle
  }
}
```

結果として、以下のようにジョブが登録される。

![ウェブUIに登録されたアプリ](/memo-blog/images/ZYlC0oO9gxFT8Ran-75ED0.png)

登録されたジョブを実行する。

![ジョブを走らせる](/memo-blog/images/ZYlC0oO9gxFT8Ran-50E61.png)

また上記で表示されていた`curl ...`をコマンドで実行することでも、ジョブを走らせることができる。
ジョブの一覧は、ウェブUIから以下のように確認できる。

![走らせたジョブ一覧](/memo-blog/images/ZYlC0oO9gxFT8Ran-38E5F.png)

ジョブ一覧からジョブを選ぶと、そのメタデータ、渡されたパラメータ、結果などを確認できる。
さらにジョブ実行時のログもウェブUIから確認できる。

![ジョブ実行時のログ](/memo-blog/images/ZYlC0oO9gxFT8Ran-9DD16.png)

Sparkのドライバログと思われるものも含まれている。

## アーキテクチャと動作

[Hydro Mistがどうやってジョブを起動するか] によると以下の通り。

Mistで実行する関数は、`mist-worker`にラップされており、当該ワーカがSparkContextを保持しているようだ。
またワーカを通じてジョブを実行する。
（参考：[Hydro Mistのジョブのステート] ）

ユーザがジョブを実行させようとしたとき、Mistのマスタはそのリクエストをキューに入れ、ワーカが空くのを待つ。
ワーカのモードには2種類がある。

* exclusive
  * ジョブごとにワーカを立ち上げる
* shared
  * ひとつのジョブが完了してもワーカを立ち上げたままにし再利用する。

これにより、ジョブの並列度、ジョブの耐障害性の面で有利になる。

また、 [Hydro Mistのジョブローンチの流れ] からジョブ登録から実行までの大まかな流れがわかる。

## コンテキストの管理

Sparkのコンテキスト管理やワーカのモード設定は、
mist-cliを通じてできるようだ。
[Hydro Mistのコンテキスト管理] 参照。

## mist-cli

[Hydro MIstのmist-cliのGitHub] 参照。
`mist-cli` は、コンフィグファイル（やコンフィグファイルが配備されたディレクトリ）を指定しながら実行する。
ディレクトリにコンフィグを置く場合は、ファイル名の先頭に2桁の数字を入れることで、
プライオリティを指定することができる。

コンフィグには、Artifact、Context、Functionの設定を記載する。
参考：[Hydro Mistのコンフィグの例]

[Hydro Mistの公式クイックスタート] を実行したあとの状態で確認してみる。
```
$ mist-cli list contexts
       ID           WORKER MODE
default             exclusiveemr_ctx             exclusiveemr_autoscale_ctx   exclusivestandalone          exclusive

$ mist-cli list functions
    FUNCTION       DEFAULT CONTEXT              PATH              CLASS NAME
hello-mist-scala   default           hello-mist-scala_0.0.1.jar   HelloMist$

$ mist-cli status
Mist version: 1.1.1
Spark version: 2.4.0
Java version: 1.8.0_201-b09
```

いくつかのコンテキストと、関数が登録されていることがわかる。
なお、GitHub上のバイナリを用いたので使用するSparkのバージョンが2.4.0になっていた。

## Scala API

[Hydro MistのScala API] とサンプルアプリ（`mist\examples\examples\src\main\scala\PiExample.scala`）を確認してみる。

### エントリポイント

MistFnがエントリポイントのようだ。

PiExample.scala:6
```
object PiExample extends MistFn {

  override def handle: Handle = {
    val samples = arg[Int]("samples").validated(_ > 0, "Samples should be positive")

(snip)
```

### 引数定義

また関数の引数設定は`mist.api.ArgsInstances#arg[A]`などで行う。
下記にサンプルに記載の例を示す。

PiExample.scala:9
```
val samples = arg[Int]("samples").validated(_ > 0, "Samples should be positive")
```

`[Int]`により引数として渡される値の型を指定する。`arg`メソッドの戻り値は`NamedUserArg`クラスだが、
当該クラスは`UserArg[A]`トレートを拡張している。
`UserArg#validated`メソッドを用いることで、値の検証を行う。

複数の引数を渡すには、`withArgs`を使うか、`combine`や`&`を使う。

例：
```
val three = withArgs(arg[Int]("n"), arg[String]("str"), arg[Boolean]("flag"))

val three = arg[Int]("n") & arg[String]("str") & arg[Boolean]("flag")
```

またドキュメントには、case classと各種Extractorを用いることで、JSON形式の入力データを
扱う方法が説明されていた。

### Sparkのコンテキスト

引数を定義したのちは、Mistのコンテキスト管理のAPIを利用し、
SparkSessionなどを取得する。
`onSparkContext`や`onSparkSession`などを利用可能。

mist/api/MistFnSyntax.scala:91
```
    def onSparkSession[F, Cmb, Out](f: F)(
      implicit
      cmb: ArgCombiner.Aux[A, SparkSession, Cmb],
      fnT: FnForTuple.Aux[Cmb, F, Out]
    ): RawHandle[Out] = args.combine(sparkSessionArg).apply(f)
```

サンプルでは以下のような使い方を示している。

PiExample.scala:10
```
    withArgs(samples).onSparkContext((n: Int, sc: SparkContext) => {
      val count = sc.parallelize(1 to n).filter(_ => {

(snip)
```

もしSparkSessionを使うならば以下の通りか。

```
import org.apache.spark.sql.SparkSession

(snip)

    withArgs(samples).onSparkSession((n: Int, spark: SparkSession) => {
      val count = spark.sparkContext.parallelize(1 to n).filter(_ => {

(snip)
```

なお、`onStreamingContext`というのもあり、Spark Streamingも実行可能のようだ。

### 結果のハンドリング

上記`onSparkContext`メソッドなどの戻り値の型は`RawHandle[Out]`である。

mist/api/MistFnSyntax.scala:58
```
    def onSparkContext[F, Cmb, Out](f: F)(
      implicit
      cmb: ArgCombiner.Aux[A, SparkContext, Cmb],
      fnT: FnForTuple.Aux[Cmb, F, Out]
    ): RawHandle[Out] = args.combine(sparkContextArg).apply(f)
```

最終的に結果をJSON形式で返すために、`asHandle`メソッドを利用する。

PiExample.scala:10
```
    withArgs(samples).onSparkContext((n: Int, sc: SparkContext) => {

    (snip)

    }).asHandle
```

asHandleメソッドは以下の通り。

mist/api/MistFnSyntax.scala:48
```
  implicit class AsHandleOps[A](raw: RawHandle[A]) {
    def asHandle(implicit enc: JsEncoder[A]): Handle = raw.toHandle(enc)
  }
```

### 余談：implicitクラスの使用

mist.api以下で複数のクラスがimplicit定義されて利用されており、一見して解析しづらい印象を覚えた。
例えば`onSparkContext`や`onSparkSession`がimplicitクラスContextsOpsクラスに定義されている。

### 考察：フレームワークの良し悪し

Sparkの単純なプロキシではなく、フレームワーク（ライブラリ）化されていることで、
ユーザはSparkのコンテキストの管理から開放される、という利点がある。

一方で、Hydro Mistのフレームワークに従って実装する必要があり、多少なり

* Sparkに加えて、Hydro Mistの学習コストがある
* Mistのフレームワークでは実装しづらいケースが存在するかもしれない
* トラブルシュートの際に、Mistの実装まで含めて確認が必要になるかもしれない

という懸念点・欠点が挙げられる。

## HTTP API

[Hydro MistのHTTP API] に一覧が載っている。

例えば関数一覧を取得する。
```
$ curl -X GET 'http://10.0.0.209:2004/v2/api/functions' | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   208  100   208    0     0  13256      0 --:--:-- --:--:-- --:--:-- 13866
[
  {
    "name": "hello-mist-scala",
    "execute": {
      "samples": {
        "type": "MOption",
        "args": [
          {
            "type": "MInt"
          }
        ]
      }
    },
    "path": "hello-mist-scala_0.0.1.jar",
    "tags": [],
    "className": "HelloMist$",
    "defaultContext": "default",
    "lang": "scala"
  }
]
```

続いて、当該関数についてジョブ一覧を取得する。
```
$ curl -X GET 'http://10.0.0.209:2004/v2/api/functions/hello-mist-scala/jobs' | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1682  100  1682    0     0  29484      0 --:--:-- --:--:-- --:--:-- 30035
[
  {
    "source": "Http",
    "startTime": 1553358512167,
    "createTime": 1553358507406,
    "context": "default",
    "params": {
      "filePath": "hello-mist-scala_0.0.1.jar",
      "className": "HelloMist$",
      "arguments": {
        "samples": 9
      },
      "action": "execute"
    },
    "endTime": 1553358513162,
    "jobResult": 2.2222222222222223,
    "status": "finished",
    "function": "hello-mist-scala",
    "jobId": "b044d08f-9554-4be9-8e22-1d687e58c52e",
    "workerId": "default_1cb3b66d-99c3-400b-ac3a-f11d72ab8124_4"
  },

(snip)
```

上記のように、ジョブのメタデータと結果が取得される。
ジョブの情報であれば、直接jobs APIを用いても取得可能。

```
$ curl -X GET 'http://10.0.0.209:2004/v2/api/jobs' | jq
```

またジョブのログを出力できる。

```
$ curl -X GET 'http://10.0.0.209:2004/v2/api/jobs/a87197c8-1692-48bc-b151-978ea89b058a/logs' | head -n 20
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0INFO 2019-03-23T16:22:44.178 [a87197c8-1692-48bc-b151-978ea89b058a] Waiting worker connectionINFO 2019-03-23T16:22:44.183 [a87197c8-1692-48bc-b151-978ea89b058a] InitializedEvent(externalId=None)
INFO 2019-03-23T16:22:44.183 [a87197c8-1692-48bc-b151-978ea89b058a] QueuedEventINFO 2019-03-23T16:22:47.991 [a87197c8-1692-48bc-b151-978ea89b058a] WorkerAssigned(workerId=default_1cb3b66d-99c3-400b-ac3a-f11d72ab8124_2)
INFO 2019-03-23T16:22:48.027 [a87197c8-1692-48bc-b151-978ea89b058a] JobFileDownloadingEvent
INFO 2019-03-23T16:22:48.885 [a87197c8-1692-48bc-b151-978ea89b058a] StartedEvent
INFO 2019-03-23T16:22:48.882 [a87197c8-1692-48bc-b151-978ea89b058a] Added JAR /home/centos/HydroMist/default/worker-default_1cb3b66d-99c3-400b-ac3a-f11d72ab8124_2/hello-mist-scala_0.0.1.jar at spark://dev:46260/jars/hello-mist-scala_0.0.1.jar with timestamp 1553358168882
INFO 2019-03-23T16:22:48.965 [a87197c8-1692-48bc-b151-978ea89b058a] Hello Mist started with samples: 8
INFO 2019-03-23T16:22:49.204 [a87197c8-1692-48bc-b151-978ea89b058a] Starting job: count at HelloMist.scala:22
INFO 2019-03-23T16:22:49.218 [a87197c8-1692-48bc-b151-978ea89b058a] Got job 0 (count at HelloMist.scala:22) with 16 output partitions
INFO 2019-03-23T16:22:49.219 [a87197c8-1692-48bc-b151-978ea89b058a] Final stage: ResultStage 0 (count at HelloMist.scala:22)
INFO 2019-03-23T16:22:49.22 [a87197c8-1692-48bc-b151-978ea89b058a] Parents of final stage: List()
INFO 2019-03-23T16:22:49.221 [a87197c8-1692-48bc-b151-978ea89b058a] Missing parents: List()
INFO 2019-03-23T16:22:49.229 [a87197c8-1692-48bc-b151-978ea89b058a] Submitting ResultStage 0 (MapPartitionsRDD[1] at filter at HelloMist.scala:18), which has
no missing parents
INFO 2019-03-23T16:22:49.438 [a87197c8-1692-48bc-b151-978ea89b058a] Block broadcast_0 stored as values in memory (estimated size 1808.0 B, free 366.3 MB)
INFO 2019-03-23T16:22:49.471 [a87197c8-1692-48bc-b151-978ea89b058a] Block broadcast_0_piece0 stored as bytes in memory (estimated size 1232.0 B, free 366.3 MB)
INFO 2019-03-23T16:22:49.473 [a87197c8-1692-48bc-b151-978ea89b058a] Added broadcast_0_piece0 in memory on dev:39976 (size: 1232.0 B, free: 366.3 MB)
INFO 2019-03-23T16:22:49.476 [a87197c8-1692-48bc-b151-978ea89b058a] Created broadcast 0 from broadcast at DAGScheduler.scala:1039
10INFO 2019-03-23T16:22:49.494 [a87197c8-1692-48bc-b151-978ea89b058a] Submitting 16 missing tasks from ResultStage 0 (MapPartitionsRDD[1] at filter at HelloMist.scala:18) (first 15 tasks are for partitions Vector(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14))
0INFO 2019-03-23T16:22:49.495 [a87197c8-1692-48bc-b151-978ea89b058a] Adding task set 0.0 with 16 tasks

(snip)
```

## Reactie API

[Hydro MistのReactive API] を見ると、MQTTやKafkaと連携して動くAPIがあるようだが、
まだドキュメントが成熟していない。
デフォルトでは無効になっている。

### EMRとの連係

[Hydro MistのEMR連係] を眺めると`hello_mist`プロジェクト等でEMRとの連係の仕方を示してくれているようだが、まだ情報が足りない。
