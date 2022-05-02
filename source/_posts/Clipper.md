---

title: Clipper
date: 2019-02-24 23:29:27
categories:
  - Knowledge Management
  - Machine Learning
  - Model Management
  - Clipper
tags:
  - Machine Learning
  - Model Management
  - Clipper

---

# 参考

* [Strata NY 2018でのClipper]
* [RISELabのページ]
* [Clipperの論文]
* [バンディットアルゴリズムについての説明]
* [GitHubページ]
* [公式ウェブサイト]
* [clipper APIドキュメント]
* [example_client.py]
* [xgboost_deployment]
* [Container Managers]
* [clipper APIドキュメント]
* [image_query]
* [image_query/example.ipynb]

[Strata NY 2018でのClipper]: https://conferences.oreilly.com/strata/strata-ny-2018/public/schedule/detail/69861
[RISELabのページ]: https://rise.cs.berkeley.edu/projects/clipper/
[Clipperの論文]: https://rise.cs.berkeley.edu/wp-content/uploads/2017/02/clipper_final.pdf
[バンディットアルゴリズムについての説明]: https://www.slideshare.net/greenmidori83/ss-28443892
[GitHubページ]: https://github.com/ucbrise/clipper
[公式ウェブサイト]: http://clipper.ai/
[example_client.py]: https://github.com/ucbrise/clipper/blob/develop/examples/basic_query/example_client.py
[xgboost_deployment]: http://clipper.ai/tutorials/xgboost_deployment/
[Container Managers]: http://clipper.ai/tutorials/container_managers/
[clipper APIドキュメント]: http://docs.clipper.ai/en/v0.3.0/
[image_query]: https://github.com/ucbrise/clipper/blob/develop/examples/image_query/example.md
[image_query/example.ipynb]: https://github.com/ucbrise/clipper/blob/develop/examples/image_query/example.ipynb

# メモ

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

### モデル選択について

複数の競合するモデルから得られる結果を扱い、動的にモデルを選択していく。
これにより、モデルの精度とロバストネスを高める。
またバンディットアルゴリズムを採用しており、複数のモデルの結果を組み合わせる。

スループットとレイテンシを保つため、キャッシングやバッチ処理を採用。
所定の（？）レイテンシを保持しながら、スループットを高めるためにバッチ処理化するようだ。

また、このあたりは、モデル抽象化層の上になりたっているから、
異なるフレームワーク発のモデルが含まれている場合でも動作するようである。

### TensorFlow Servingとの比較

機能面で充実し、スループットやレイテンシの面でも有利。

### ターゲットとなるアプリ

* 物体検知
* 音声認識
* 自動音声認識

### チャレンジポイント

* 機械学習フレームワーク、ライブラリの乱立への対応
  * モデル抽象化レイヤを設けて差異を吸収
* 高アクセス数と低レイテンシへの対応
  * スループットのレイテンシの両面を考慮してバッチ化
* A/Bテストの煩わしさと不確かさへの対応
  * 機械的なモデル選択。アンサンブル化。

### アーキテクチャと大まかな処理フロー

![リクエストが届くまで](/memo-blog/images/zzfwNAP58VNaHTod-B2159.png)
![結果が帰る流れ](/memo-blog/images/zzfwNAP58VNaHTod-892FC.png)
![フィードバック](/memo-blog/images/zzfwNAP58VNaHTod-22A04.png)

実際にはキューは、モデルの抽象化レイヤ側にあるようにも思う。
追って実装確認必要。

### キャッシュ

頻度の高いクエリのキャッシュが有効なのはわかりやすいが、頻度の低いクエリの
キャッシュも有効な面がある。
予測結果を使ったあとのフィードック（★要確認）はすぐに生じるからである。

キャッシュはrequestとfetchのAPIを持ち、ノンブロッキングである。

LRUポリシーを用いる。

### バッチ化

レイテンシに関するSLOを指定すると、それを守る範囲内で、
バッチ化を試みる。これによりスループットの向上を狙う。

バッチ化で狙うのはRPCやメモリコピーの回数削減、
フレームワークのデータ並列の仕組みの活用。

なお、バックオフを設けながら、バッチサイズを変えることで、
最適なバッチサイズを探す。
AIMD=Additive-Increase-Multiplicative-decrease に基づいてサイズ変更。

また、キューに入っているバッチが少ないケースでは、
ある程度貯まるのを待ち、スループットを上げる工夫もする。

### モデルコンテナ

C++、Java、Pythonの言語バインディングが提供されている。
各言語バインディングでラッパーを実装すれば良い。

モデルコンテナのレプリカを作り、スケールアウトさせられる。

### モデル選択層

アプリケーションのライフサイクル全体に渡り、
フィードバックを考慮しながら、複数のモデルを取り扱う。
これにより、一部のモデルが失敗しても問題ない。
また複数のモデルから得られた結果を統合することでaccuracyを向上させる。

モデルへの選択の基本的なAPIは、select、combine、observe。
selectとcombineはそのままの意味だが、observeは、アプリケーションからの
フィードバックを受取り、ステートを更新するために用いるAPIである。

モデル選択については予めgeneralなアルゴリズムが実装されているが、
ユーザが実装することも可能。
ただし、計算量と精度はトレードオフになりがちなので注意。

* バンディットアルゴリズム（多腕バンディット問題）
  * ClipperではExp3アルゴリズムに対応
  * 単一の結果を利用
* アンサンブル
  * Clipperでは線形アンサンブルに対応
  * 重み計算にはExp4（バンディットアルゴリズム）を利用

なお、バンディットアルゴリズムについては [バンディットアルゴリズムについての説明] などを参照されたし。

### 信頼度とデフォルト動作

モデルから得られた推測値の信頼度が定められた閾値よりも低い場合、
所定のデフォルト動作をさせられる。
複数のモデルを取り扱う場合、信頼度の指標としてそれらのモデルが
最終的な解を採用するかどうかとする方法が挙げられる。
要は、アンサンブルを利用する、ということである。

### 落伍者モデルの影響の軽減

アンサンブルの歳、モデル抽象化層でスケールアウトさせられる。
しかし弱点として、モデルの中に落伍者がいると、それに足を引っ張られレイテンシが悪化することである。（計算結果の取得が遅くなる）

そこでClipperでは、モデル選択層で待ち時間（SLO）を設け、ベストエフォートで
結果をアグリゲートすることとした。

### ステートの管理

ステート管理には現在の実装ではRedisを用いているようだ。
なお、DockerContainerMangerでは、外部のRedisサービスを利用することもできるし、
開発用に内部でRedisのDockerコンテナを起動させることもできる。

内部的には、コンストラクタ引数にredis_ipを渡すかどうかで管理されているようだ。

clipper_admin/clipper_admin/docker/docker_container_manager.py:77
```
        if redis_ip is None:
            self.external_redis = False
```

### TensorFlow Servingとの比較

TF Servingは、TFと密結合。
Clipper同様にスループット向上のための工夫が施されている。
バッチ化も行う。
ただし、基本的に1個のモデルで推論するようになっており、
アプリケーションからのフィードバックを受取り、
モデル選択するような仕組みは無い。

TF Servingと比べると、多少スループットが劣るものの健闘。

### 制約

Clipperはモデルをブラックボックスとして扱うので、
モデル内に踏み込んだ最適化は行わない。

### 類似技術

* TF Serving
* LASER
* Velox

## 公式ドキュメント

### アーキテクチャ

http://clipper.ai/images/clipper-structure.png に公式ドキュメント上の構成イメージが記載されている。
論文と比較して、モデル選択層の部分が「Clipper Query Processor」と表現されているように見える。

またClipperは、コンテナ群をオーケストレーションし、環境を構成する。

またClipperは、実質的に「ファンクション・サーバ」であると考えられる。
実のところ、ファンクションは機械学習モデルでなくてもよい。
（公式ドキュメントのクイックスタートでも、簡単な四則演算をデプロイする例が載っている）

### モデル管理

モデルは、リストを入力し、値かJSONを出力する。
入力がリストなのは、機械学習モデルによってはデータ並列で処理し、性能向上を狙うものがあるため。

またClipperはモデル管理のためのライブラリを提供する。
これにより、ある程度決まったモデルであれば、コンテナの作成やモデルの保存などを
自前で作り込む必要がない。
現在は以下の内容に対応する。

* One to deploy arbitrary Python functions (within some constraints)
* One to deploy PySpark models along with pre- and post-processing logic
* One to deploy R models

アプリケーションとモデルの間は、必ずしも1対1でなくてもよい。

参考）
* http://clipper.ai/images/link_model.png
* http://clipper.ai/images/update_model.png

以上の通り、モデルをデプロイしながら、複数のモデルをアプリケーションにリンクして切り替えることができる。
例えばデプロイした新しいモデルが想定通り動作しなかったとき、もとのモデルに切り戻す、など。

なお、モデルを登録するときには、いくつかの引数を渡す。

* 入力型
* レイテンシのSLO（サービスレベルオブジェクト）
* デフォルトの出力

さらに、 `ClipperConnection.set_num_replicas()` を用いて、モデルのレプリカ数を決められる。

### コンテナマネージャ

[Container Managers] によると、Dockerコンテナを自前のライブラリか、k8sでオーケストレーションすることが可能。
自前のライブラリは開発向けのようである。

なお、ステートを保存するRedisもコンテナでローンチするようになっているが、
勝手にローンチしてくれるものはステートを永続化するようになっていない。
したがってコンテナが落ちるとステートが消える。
プロダクションのケースでは、きちんと可用性を考慮した構成で予めローンチしておくことが推奨されている。

注意点として、2019/2/27時点でのClipperでは、クエリフロントエンドのオートスケールには対応していない。
これは、クエリフロントエンドとモデル抽象化層のコンテナの間を長命なコネクション（TCPコネクション）で
結んでいるからである。クエリフロントエンドをスケールアウトする時に、これをリバランスする機能が
まだ存在していない。

### APIドキュメント

## クライアントのサンプル

[example_client.py]

### コネクションの生成とエンドポイント定義

```
    clipper_conn = ClipperConnection(DockerContainerManager())
    clipper_conn.start_clipper()
    python_deployer.create_endpoint(clipper_conn, "simple-example", "doubles",
                                    feature_sum)
```

ここで渡しているファンクション`feature_sum`は以下の通り。

```
def feature_sum(xs):
    return [str(sum(x)) for x in xs]
```

### 推論

```
        while True:
            if batch_size > 1:
                predict(
                    clipper_conn.get_query_addr(),
                    [list(np.random.random(200)) for i in range(batch_size)],
                    batch=True)
            else:
                predict(clipper_conn.get_query_addr(), np.random.random(200))
            time.sleep(0.2)
```

predict関数の定義は以下の通り。

```
def predict(addr, x, batch=False):
    url = "http://%s/simple-example/predict" % addr

    if batch:
        req_json = json.dumps({'input_batch': x})
    else:
        req_json = json.dumps({'input': list(x)})

    headers = {'Content-type': 'application/json'}
    start = datetime.now()
    r = requests.post(url, headers=headers, data=req_json)
    end = datetime.now()
    latency = (end - start).total_seconds() * 1000.0
    print("'%s', %f ms" % (r.text, latency))
```

与えられた入力をJSONに変換し、REST APIで渡している。

## XGBOOSTの例

```
(clipper) $ pip install xgboost
(clipper) $ ipython
```

Clipperを起動。
```
import logging, xgboost as xgb, numpy as np
from clipper_admin import ClipperConnection, DockerContainerManager
cl = ClipperConnection(DockerContainerManager())
cl.start_clipper()
```

結果
```
19-02-27:22:49:09 INFO     [docker_container_manager.py:119] Starting managed Redis instance in Docker
19-02-27:22:49:14 INFO     [clipper_admin.py:126] Clipper is running
```

アプリを登録。
```
cl.register_application('xgboost-test', 'integers', 'default_pred', 100000)
```

結果
```
19-02-27:22:49:55 INFO     [clipper_admin.py:201] Application xgboost-test was successfully registered
```

ファンクション定義
```
def get_test_point():
    return [np.random.randint(255) for _ in range(784)]

# Create a training matrix.
dtrain = xgb.DMatrix(get_test_point(), label=[0])

# We then create parameters, watchlist, and specify the number of rounds
# This is code that we use to build our XGBoost Model, and your code may differ.
param = {'max_depth': 2, 'eta': 1, 'silent': 1, 'objective': 'binary:logistic'}
watchlist = [(dtrain, 'train')]
num_round = 2
bst = xgb.train(param, dtrain, num_round, watchlist)
```

結果
```
[0]     train-error:0
[1]     train-error:0
```

推論用の関数定義
```
def predict(xs):
    return bst.predict(xgb.DMatrix(xs))
```

推論用のコンテンをビルドし、ローンチ。
```
from clipper_admin.deployers import python as python_deployer
# We specify which packages to install in the pkgs_to_install arg.
# For example, if we wanted to install xgboost and psycopg2, we would use
# pkgs_to_install = ['xgboost', 'psycopg2']
python_deployer.deploy_python_closure(cl, name='xgboost-model', version=1,
     input_type="integers", func=predict, pkgs_to_install=['xgboost'])
```

なお、ここではコンテナをビルドするときに、`xgboost`をインストールするように指定している。

結果
```
19-02-27:22:54:35 INFO     [deployer_utils.py:44] Saving function to /tmp/clipper/tmpincj4sg2
19-02-27:22:54:35 INFO     [deployer_utils.py:54] Serialized and supplied predict function
19-02-27:22:54:35 INFO     [python.py:192] Python closure saved

(snip)

19-02-27:22:54:53 INFO     [docker_container_manager.py:257] Found 0 replicas for xgboost-model:1. Adding 1
19-02-27:22:55:00 INFO     [clipper_admin.py:635] Successfully registered model xgboost-model:1
19-02-27:22:55:00 INFO     [clipper_admin.py:553] Done deploying model xgboost-model:1.
```

モデルをアプリにリンク。
```
cl.link_model_to_app('xgboost-test', 'xgboost-model')
```

```
import requests, json
# Get Address
addr = cl.get_query_addr()
# Post Query
response = requests.post(
     "http://%s/%s/predict" % (addr, 'xgboost-test'),
     headers={"Content-type": "application/json"},
     data=json.dumps({
         'input': get_test_point()
     }))
result = response.json()
if response.status_code == requests.codes.ok and result["default"]:
     print('A default prediction was returned.')
elif response.status_code != requests.codes.ok:
    print(result)
    raise BenchmarkException(response.text)
else:
    print('Prediction Returned:', result)
```

結果
```
Prediction Returned: {'query_id': 2, 'output': 0.3266071, 'default': False}
```

## 実装確認

### 開発言語

```
 C++ 56.0%	 Python 24.1%	 CMake 8.1%	 Scala 3.0%	 Shell 2.5%	 Java 2.2%	 Other 4.1%
```

### コンテナの起動の流れを確認してみる

ClipperConnection#start_clipperメソッドを確認する。

ContainerManager#start_clipperメソッドが中で呼ばれる。

clipper_admin/clipper_admin/clipper_admin.py:123
```
            self.cm.start_clipper(query_frontend_image, mgmt_frontend_image,
                                  frontend_exporter_image, cache_size,
                                  num_frontend_replicas)
```

clipper_admin/clipper_admin/container_manager.py:63
```
class ContainerManager(object):
    __metaclass__ = abc.ABCMeta

    @abc.abstractmethod
    def start_clipper(self, query_frontend_image, mgmt_frontend_image,
```

ContainerManagerは親クラスであり、KubernetesContainerManagerやDockerContainerManagerのstart_clipperが実行される。
例えばDockerContainerManagerを見てみる。

Docker SDKを使い、docker networkを作る。

clipper_admin/clipper_admin/docker/docker_container_manager.py:128
```
            self.docker_client.networks.create(
                self.docker_network, check_duplicate=True)
```

Redisを起動する。

clipper_admin/clipper_admin/docker/docker_container_manager.py:156
```
        if not self.external_redis:
            self.logger.info("Starting managed Redis instance in Docker")
            self.redis_port = find_unbound_port(self.redis_port)
            redis_labels = self.common_labels.copy()
            redis_labels[CLIPPER_DOCKER_PORT_LABELS['redis']] = str(
                self.redis_port)
            redis_container = self.docker_client.containers.run(
                'redis:alpine',
                "redis-server --port %s" % CLIPPER_INTERNAL_REDIS_PORT,
                name="redis-{}".format(random.randint(
                    0, 100000)),  # generate a random name
                ports={
                    '%s/tcp' % CLIPPER_INTERNAL_REDIS_PORT: self.redis_port
                },
                labels=redis_labels,
                **self.extra_container_kwargs)
            self.redis_ip = redis_container.name
```

マネジメントフロントエンドを起動。

clipper_admin/clipper_admin/docker/docker_container_manager.py:168
```
        mgmt_cmd = "--redis_ip={redis_ip} --redis_port={redis_port}".format(
            redis_ip=self.redis_ip, redis_port=CLIPPER_INTERNAL_REDIS_PORT)
        self.clipper_management_port = find_unbound_port(
            self.clipper_management_port)
        mgmt_labels = self.common_labels.copy()
        mgmt_labels[CLIPPER_MGMT_FRONTEND_CONTAINER_LABEL] = ""
        mgmt_labels[CLIPPER_DOCKER_PORT_LABELS['management']] = str(
            self.clipper_management_port)
        self.docker_client.containers.run(
            mgmt_frontend_image,
            mgmt_cmd,
            name="mgmt_frontend-{}".format(random.randint(
                0, 100000)),  # generate a random name
            ports={
                '%s/tcp' % CLIPPER_INTERNAL_MANAGEMENT_PORT:
                self.clipper_management_port
            },
            labels=mgmt_labels,
            **self.extra_container_kwargs)
```

なお、コンテナ起動のコマンドに、上記で起動された（もしくは外部のサービスとして与えられた）Redisの
IPアドレス、ポート等の情報が渡されていることがわかる。

クエリフロントエンドの起動。
```
        self.docker_client.containers.run(
            query_frontend_image,
            query_cmd,
            name=query_name,
            ports={
                '%s/tcp' % CLIPPER_INTERNAL_QUERY_PORT:
                self.clipper_query_port,
                '%s/tcp' % CLIPPER_INTERNAL_RPC_PORT: self.clipper_rpc_port
            },
            labels=query_labels,
            **self.extra_container_kwargs)
```

その他、メトリクスのコンテナを起動する。
```
        run_metric_image(self.docker_client, metric_labels,
                         self.prometheus_port, self.prom_config_path,
                         self.extra_container_kwargs)
```

コンテナを起動したあとは、ポートの情報を更新する。

### create_endpointメソッドを確認

公式の例でも、create_endpointメソッドがよく用いられるので確認する。

メソッド引数は以下の通り。

clipper_admin/clipper_admin/deployers/python.py:16
```
def create_endpoint(clipper_conn,
                    name,
                    input_type,
                    func,
                    default_output="None",
                    version=1,
                    slo_micros=3000000,
                    labels=None,
                    registry=None,
                    base_image="default",
                    num_replicas=1,
                    batch_size=-1,
                    pkgs_to_install=None):
 
```

基本的には、ClipperConnectionインスタンス、関数名、入力データのタイプ、関数を指定しながら利用する。

メソッド内部の処理は以下のとおり。

clipper_admin/clipper_admin/deployers/python.py:87
```
    clipper_conn.register_application(name, input_type, default_output,
                                      slo_micros)
    deploy_python_closure(clipper_conn, name, version, input_type, func,
                          base_image, labels, registry, num_replicas,
                          batch_size, pkgs_to_install)

    clipper_conn.link_model_to_app(name, name)
```

最初にregister_applicationメソッドで、アプリケーションを
Clipperに登録する。 なお、`register_applicatoin` メソッドは、Clipperの
マネジメントフロントエンドに対してリクエストを送る。

マネジメントフロントエンドのURLの指定は以下の通り。

clipper_admin/clipper_admin/clipper_admin.py:201
```
        url = "http://{host}/admin/add_app".format(
            host=self.cm.get_admin_addr())
```

マネジメントフロントエンド自体は、 `\src\management\src\management_frontend.hpp` が自体と思われる。
以下の通り、エンドポイント `add_app` が定義されている。

src/management/src/management_frontend.hpp:52

```
const std::string ADD_APPLICATION = ADMIN_PATH + "/add_app$";
```

src/management/src/management_frontend.hpp:181
```
    server_.add_endpoint(
        ADD_APPLICATION, "POST",
        [this](std::shared_ptr<HttpServer::Response> response,
               std::shared_ptr<HttpServer::Request> request) {
          try {
            clipper::log_info(LOGGING_TAG_MANAGEMENT_FRONTEND,
                              "Add application POST request");
```

create_endopintの流れ確認に戻る。


アプリケーションの登録が完了したあとは、`deploy_python_closure` メソッドを使って、

引数は以下の通り。

clipper_admin/clipper_admin/deployers/python.py:96
```
def deploy_python_closure(clipper_conn,
                          name,
                          version,
                          input_type,
                          func,
                          base_image="default",
                          labels=None,
                          registry=None,
                          num_replicas=1,
                          batch_size=-1,
                          pkgs_to_install=None):
```

このメソッドでは、最初に `save_python_function` を使って
関数をシリアライズする。

clipper_admin/clipper_admin/deployers/python.py:189
```
    serialization_dir = save_python_function(name, func)
```

つづいて、Pyhonのバージョンに従いながらベースとなるイメージを選択する。
以下にPython3.6の場合を載せる。

clipper_admin/clipper_admin/deployers/python.py:205
```
        elif py_minor_version == (3, 6):
            logger.info("Using Python 3.6 base image")
            base_image = "{}/python36-closure-container:{}".format(
                __registry__, __version__)
```

`最後にClipperConnection#build_and_deploy_model`メソッドを使って
関数を含むコンテナイメージを作成する。

clipper_admin/clipper_admin/deployers/python.py:220
```
    clipper_conn.build_and_deploy_model(
        name, version, input_type, serialization_dir, base_image, labels,
        registry, num_replicas, batch_size, pkgs_to_install)
```

`build_and_deploy_model` メソッドは以下の通り。

clipper_admin/clipper_admin/clipper_admin.py:352
```
        if not self.connected:
            raise UnconnectedException()
        image = self.build_model(name, version, model_data_path, base_image,
                                 container_registry, pkgs_to_install)
        self.deploy_model(name, version, input_type, image, labels,
                          num_replicas, batch_size)
```

`build_model` メソッドでDockerイメージをビルドし、
レポジトリに登録する。

`deploy_model` メソッドで登録されたDockerイメージからコンテナを起動する。
このとき指定された個数だけコンテナを起動する。
なお、起動時には、抽象クラス `ContainerManager` の `deploy_model` メソッドが呼ばれる。
実際には具象クラスであるKubernetesContainerManagerやDockerContainerManagerクラスのメソッドが実行される。
ここに抽象化が施されていると考えられる。


## 動作確認

### クイックスタート

[公式ウェブサイト] のクイックスタートの通り、実行してみる。
上記サイトでAnaconda上で環境構成するのを推奨する記述があったためそれに従う。
また、Pythonバージョンに指定があったので、指定された中で最も新しい3.6にした。

```
$ sudo yum install gcc
$ conda create -n clipper python=3.6 python
$ conda activate clipper
$ conda install ipython
$ pip install clipper_admin
```

ipythonを起動する。

```
(clipper) $ ipython
```

Docker環境を立てる。

```
from clipper_admin import ClipperConnection, DockerContainerManager
clipper_conn = ClipperConnection(DockerContainerManager())
clipper_conn.start_clipper()
```

結果の例

```
19-02-26:22:24:42 INFO     [docker_container_manager.py:119] Starting managed Redis instance in Docker
19-02-26:22:26:50 INFO     [clipper_admin.py:126] Clipper is running
```

簡単な例を登録。これにより、エンドポイントが有効になるようだ。
実際の処理の登録は後ほど。

```
clipper_conn.register_application(name="hello-world", input_type="doubles", default_output="-1.0", slo_micros=100000)
```

登録処理は以下の通り。

```
def feature_sum(xs):
    return [str(sum(x)) for x in xs]
```

デプロイ。

```
from clipper_admin.deployers import python as python_deployer
python_deployer.deploy_python_closure(clipper_conn, name="sum-model", version=1, input_type="doubles", func=feature_sum)
```

ここから、モデル抽象化層のDockerイメージが作られる。

```
19-02-26:22:30:59 INFO     [deployer_utils.py:44] Saving function to /tmp/clipper/tmp67eliqhx
19-02-26:22:30:59 INFO     [deployer_utils.py:54] Serialized and supplied predict function
19-02-26:22:30:59 INFO     [python.py:192] Python closure saved
19-02-26:22:30:59 INFO     [python.py:206] Using Python 3.6 base image

(snip)

19-02-26:22:31:26 INFO     [docker_container_manager.py:257] Found 0 replicas for sum-model:1. Adding 1
19-02-26:22:31:33 INFO     [clipper_admin.py:635] Successfully registered model sum-model:1
19-02-26:22:31:33 INFO     [clipper_admin.py:553] Done deploying model sum-model:1.
19-02-26:22:30:59 INFO     [clipper_admin.py:452] Building model Docker image with model data from /tmp/clipper/tmp67eliqhx
```

モデルをアプリケーションにリンクさせる。

```
clipper_conn.link_model_to_app(app_name="hello-world", model_name="sum-model")
```

以上で、エンドポイント`http://localhost:1337/hello-world/predict`を用いて、
推論結果（計算結果）を受け取れるようになる。

curlで結果の取得

```
$ curl -X POST --header "Content-Type:application/json" -d '{"input": [1.1, 2.2, 3.3]}' 127.0.0.1:1337/hello-world/predict
```

結果の例

```
{"query_id":0,"output":6.6,"default":false}
```

Pythonから取得するパターン。

```
import requests, json, numpy as np
headers = {"Content-type": "application/json"}
requests.post("http://localhost:1337/hello-world/predict", headers=headers, data=json.dumps({"input": list(np.random.random(10))})).json()
```

結果の例

```
Out[12]: {'query_id': 1, 'output': 4.710181343957851, 'default': False}
```

参考までに、この時点で実行されているDockerコンテナは以下の通り。

```
$ sudo docker ps
CONTAINER ID        IMAGE                               COMMAND                  CREATED             STATUS                    PORTS                                            NAMES
b041228b2a4d        sum-model:1                         "/container/containe…"   25 minutes ago      Up 25 minutes (healthy)                                                    sum-model_1-37382
6f93447357bd        prom/prometheus:v2.1.0              "/bin/prometheus --c…"   30 minutes ago      Up 30 minutes             0.0.0.0:9090->9090/tcp                           metric_frontend-37801
b3034a7352b8        clipper/frontend-exporter:0.3.0     "python /usr/src/app…"   30 minutes ago      Up 30 minutes                                                              query_frontend_exporter-33443
6b775a49e1ff        clipper/query_frontend:0.3.0        "/clipper/release/sr…"   30 minutes ago      Up 30 minutes             0.0.0.0:1337->1337/tcp, 0.0.0.0:7000->7000/tcp   query_frontend-33443
2c75406fda84        clipper/management_frontend:0.3.0   "/clipper/release/sr…"   30 minutes ago      Up 30 minutes             0.0.0.0:1338->1338/tcp                           mgmt_frontend-39690
ff14d91f313e        redis:alpine                        "docker-entrypoint.s…"   32 minutes ago      Up 32 minutes             0.0.0.0:6379->6379/tcp                           redis-28775
```

最後にコンテナを停止しておく。

```
clipper_conn.stop_all()
```

### 画像取扱のサンプル

[image_query] の通りに実行してみる。
また、 上記のノートブックが [image_query/example.ipynb] にある。

Clipperでは、REST APIでクエリが渡される。データはJSONにラップされて渡される。
そのため、ノートブック [image_query/example.ipynb] を見ると、
画像ファイルがバイト列で渡される場合と、BASE64でエンコードされて渡される場合の2種類の例が載っていた。

この例では、画像のサイズを返すような関数を定義して使っているが、
渡された画像に何らかの判定処理を加えて戻り値を返すような関数を定義すればよいだろう。

また、例では、python_deployer#create_endpointメソッドが用いられている。
