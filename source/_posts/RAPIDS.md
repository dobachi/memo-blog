---

title: RAPIDS
date: 2019-04-16 22:40:07
categories:
  - Knowledge Management
  - Data Processing Engine
tags:
  - Machine Learning
  - Data Analysis
  - PAPIDS
  - Dask
  - Data Processing Engine

---

# 参考

* [RAPIDSの公式ウェブサイト]
* [RAPIDSの公式ドキュメント]
* [RAPIDSの公式Getting Started]
* [コンポーネントの関係図]
* [性能比較のグラフ]
* [RAPIDS0.6に関する公式ブログ記事]
* [RAPIDS on Databricks Cloudのブログ]
* [RAPIDS_PCA_demo_avro_read.ipynb]
* [Dask_with_cuDF_and_XGBoost.ipynb]
* [RMMの定義]
* [cuDFのAPI定義]

[RAPIDSの公式ウェブサイト]: https://rapids.ai/
[RAPIDSの公式ドキュメント]: https://docs.rapids.ai/
[RAPIDSの公式Getting Started]: https://docs.rapids.ai/start
[コンポーネントの関係図]: https://rapids.ai/assets/images/Pipeline-FPO-Diagram.png
[性能比較のグラフ]: https://rapids.ai/assets/images/rapids-end-to-end-performance-chart-oss-page-r4.svg
[RAPIDS0.6に関する公式ブログ記事]: https://medium.com/rapids-ai/the-road-to-1-0-building-for-the-long-haul-657ae1afdfd6
[RAPIDS on Databricks Cloudのブログ]: https://medium.com/rapids-ai/rapids-can-now-be-accessed-on-databricks-unified-analytics-platform-666e42284bd1
[RAPIDS_PCA_demo_avro_read.ipynb]: https://github.com/rapidsai/notebooks-extended/blob/master/tutorials/examples/RAPIDS_PCA_demo_avro_read.ipynb
[Dask_with_cuDF_and_XGBoost.ipynb]: https://github.com/rapidsai/notebooks-extended/blob/master/tutorials/examples/Dask_with_cuDF_and_XGBoost.ipynb
[RMMの定義]: https://docs.rapids.ai/api/rmm/stable/
[cuDFのAPI定義]: https://docs.rapids.ai/api/cudf/stable/

# メモ

## 概要

### 一言で言うと…？

PandasライクなAPI、scikit learnライクなAPIなどを提供するライブラリ群。
CUDAをレバレッジし、GPUを活用しやくしている。

### コンポーネント群

公式の [コンポーネントの関係図] がわかりやすい。
前処理から、データサイエンス（と、公式で言われている）まで一貫して手助けするものである、というのが思想のようだ。

### 処理性能に関する雰囲気

公式の [性能比較のグラフ] がわかりやすい。
2桁台数の「CPUノード」との比較。
DGX-2 1台、もしくはDGX-1 5台。
計算（ロード、特徴エンジニアリング、変換、学習）時間の比較。

### 関係者

公式ウェブサイトでは、「Contributors」、「Adopters」、「Open Source」というカテゴリで整理されていた。
Contributorsでは、AnacondaやNVIDIAなどのイメージ通りの企業から、Walmartまであった。
Adoptersでは、Databricksが入っている。

### 分散の仕組みはDaskベース？

Sparkと組み合わせての動作はまだ対応していないようだが、Daskで分散（なのか、現時点でのシングルマシンでのマルチGPU対応だけなのか）処理できるようだ。
[RAPIDS0.6に関する公式ブログ記事] によると、Dask-CUDA、Dask-cuDFに対応の様子。

また、Dask-cuMLでは、k-NNと線形回帰に関し、マルチGPU動作を可能にしたようだ。

[Dask_with_cuDF_and_XGBoost.ipynb] を見ると、DaskでcuDFを使う方法が例示されていた。

Daskのクラスタを定義し、
```
from dask_cuda import LocalCUDACluster

cluster = LocalCUDACluster()
client = Client(cluster)
```

RMM（RAPIDS Memory Manager）を初期化する。
```
from librmm_cffi import librmm_config as rmm_cfg

rmm_cfg.use_pool_allocator = True
#rmm_cfg.initial_pool_size = 2<<30 # set to 2GiB. Default is 1/2 total GPU memory
import cudf
return cudf._gdf.rmm_initialize()
```

また、 [RMMの定義] にRAPIDS Memory ManagerのAPI定義が記載されている。

[cuDFのAPI定義] にもDaskでの動作について書かれている。
「Multi-GPU with Dask-cuDF」の項目。

## cuDF

[cuDFのAPI定義] に仕様が記載されている。
現状できることなどの記載がある。

線形なオペレーション、集約処理、グルーピング、結合あたりの基本的な操作対応している。


### バージョン0.7での予定

[RAPIDS0.6に関する公式ブログ記事] には一部0.7に関する記述もあった。
個人的に気になったのは、Parquetリーダが改善されてGPUを使うようになること、
デバッグメッセージが改善されること、など。

## RAPIDS on Databricks Cloud

[RAPIDS on Databricks Cloudのブログ] を見ると、Databricks CloudでRAPIDSが動くことが書かれている。
ただ、 [RAPIDS_PCA_demo_avro_read.ipynb] を見たら、SparkでロードしたデータをそのままPandasのDataFrameに変換しているようだった。

## Condaでの動作確認

### 前提

今回AWS環境を使った。
p3.2xlargeインスタンスを利用。

予めCUDA9.2をインストールしておいた。
またDockerで試す場合には、`nvidia-docker`をインストールしておく。

### 動作確認

以下の通り仮想環境を構築し、パッケージをインストールする。
```
$ conda create -n rapids python=3.6 python
$ conda install -c nvidia -c rapidsai -c pytorch -c numba -c conda-forge \
    cudf=0.6 cuml=0.6 python=3.6
```

その後、GitHubからノートブックをクローン。
```
$ git clone https://github.com/rapidsai/notebooks.git
```

ノートブックのディレクトリでJupyterを起動。
```
$ jupyter notebook --ip=0.0.0.0 --browser=""
```

つづいて、`notebooks/cuml/linear_regression_demo.ipynb`を試した。
なお、`%%time`マジックを使っている箇所の変数をバインドできなかったので、
適当にセルをコピーして実行した。

確かに学習が早くなったことは実感できた。

scikit-learn
```
%%time
skols = skLinearRegression(fit_intercept=True,
                  normalize=True)
skols.fit(X_train, y_train)
CPU times: user 21.5 s, sys: 5.33 s, total: 26.9 s
Wall time: 7.51 s
```


cudf + cuml
```
%%time
cuols = cuLinearRegression(fit_intercept=True,
                  normalize=True,
                  algorithm='eig')
cuols.fit(X_cudf, y_cudf)
CPU times: user 1.18 s, sys: 350 ms, total: 1.53 s
Wall time: 2.72 s
```

## Dockerで動作確認

つづいてDockerで試す。

```
$ sudo docker pull rapidsai/rapidsai:cuda9.2-runtime-centos7
$ sudo docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
    rapidsai/rapidsai:cuda9.2-runtime-centos7
```

Dockerコンテナが起動したら、以下の通り、Jupyter Labを起動する。
```
# bash utils/start-jupyter.sh
```

線形回帰のサンプルノートブックを試したが、大丈夫だった。

## 参考）Dockerで動作確認する際の試行錯誤

[RAPIDSの公式Getting Started] を参考に動かしてみる。

### 前提

今回は、AWS環境を使った。
予め、CUDAとnvidia-dockerをインストールしておいた。
今回は、CUDA10系を使ったので、以下のようにDockerイメージを取得。

```
$ sudo docker pull rapidsai/rapidsai:cuda10.0-runtime-ubuntu18.04
```

動作確認。このとき、runtimeにnvidiaを指定する。
```
$ sudo docker run --runtime=nvidia --rm nvidia/cuda:10.1-base nvidia-smi
Wed Apr 17 13:28:02 2019
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 418.39       Driver Version: 418.39       CUDA Version: 10.1     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla M60           Off  | 00000000:00:1E.0 Off |                    0 |
| N/A   31C    P0    42W / 150W |      0MiB /  7618MiB |     81%      Default |
+-------------------------------+----------------------+----------------------+

+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

以下のDockerfileを作り、動作確認する。
```
# FROM defines the base image
# FROM nvidia/cuda:10.0
FROM rapidsai/rapidsai:cuda10.0-runtime-ubuntu18.04

# RUN executes a shell command
# You can chain multiple commands together with &&
# A \ is used to split long lines to help with readability
# This particular instruction installs the source files
# for deviceQuery by installing the CUDA samples via apt
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-samples-$CUDA_PKG_VERSION && \    rm -rf /var/lib/apt/lists/*
# set the working directory
WORKDIR /usr/local/cuda/samples/1_Utilities/deviceQuery

RUN make
# CMD defines the default command to be run in the container
# CMD is overridden by supplying a command + arguments to
# `docker run`, e.g. `nvcc --version` or `bash`CMD ./deviceQuery
```

```
$ sudo nvidia-docker build -t device-query .
$ sudo nvidia-docker run --rm -ti device-query
$ sudo nvidia-docker run --rm -ti device-query
./deviceQuery Starting...

 CUDA Device Query (Runtime API) version (CUDART static linking)

Detected 1 CUDA Capable device(s)

Device 0: "Tesla M60"
  CUDA Driver Version / Runtime Version          10.1 / 10.0
  CUDA Capability Major/Minor version number:    5.2
  Total amount of global memory:                 7619 MBytes (7988903936 bytes)
  (16) Multiprocessors, (128) CUDA Cores/MP:     2048 CUDA Cores
  GPU Max Clock rate:                            1178 MHz (1.18 GHz)
  Memory Clock rate:                             2505 Mhz
  Memory Bus Width:                              256-bit
  L2 Cache Size:                                 2097152 bytes
  Maximum Texture Dimension Size (x,y,z)         1D=(65536), 2D=(65536, 65536), 3D=(4096, 4096, 4096)
  Maximum Layered 1D Texture Size, (num) layers  1D=(16384), 2048 layers
  Maximum Layered 2D Texture Size, (num) layers  2D=(16384, 16384), 2048 layers
  Total amount of constant memory:               65536 bytes
  Total amount of shared memory per block:       49152 bytes
  Total number of registers available per block: 65536
  Warp size:                                     32
  Maximum number of threads per multiprocessor:  2048
  Maximum number of threads per block:           1024
  Max dimension size of a thread block (x,y,z): (1024, 1024, 64)
  Max dimension size of a grid size    (x,y,z): (2147483647, 65535, 65535)
  Maximum memory pitch:                          2147483647 bytes
  Texture alignment:                             512 bytes
  Concurrent copy and kernel execution:          Yes with 2 copy engine(s)
  Run time limit on kernels:                     No  Integrated GPU sharing Host Memory:            No  Support host page-locked memory mapping:       Yes
  Alignment requirement for Surfaces:            Yes
  Device has ECC support:                        Enabled
  Device supports Unified Addressing (UVA):      Yes
  Device supports Compute Preemption:            No  Supports Cooperative Kernel Launch:            No
  Supports MultiDevice Co-op Kernel Launch:      No
  Device PCI Domain ID / Bus ID / location ID:   0 / 0 / 30
  Compute Mode:     < Default (multiple host threads can use ::cudaSetDevice() with device simultaneously) >
deviceQuery, CUDA Driver = CUDART, CUDA Driver Version = 10.1, CUDA Runtime Version = 10.0, NumDevs = 1
Result = PASS
```

### 動作確認

コンテナを起動。
```
$ sudo docker run --runtime=nvidia --rm -it -p 8888:8888 -p 8787:8787 -p 8786:8786 \
    rapidsai/rapidsai:cuda10.0-runtime-ubuntu18.04
```

```
(rapids) root@5d41281699e3:/rapids/notebooks# nvcc -V
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2018 NVIDIA Corporation
Built on Sat_Aug_25_21:08:01_CDT_2018
Cuda compilation tools, release 10.0, V10.0.130
```

ノートブックも起動してみる。（JupyterLabだった）
```
# bash utils/start-jupyter.sh
```

### サンプルノートブックの確認

回帰分析の内容を確認してみる。

`cuml/linear_regression_demo.ipynb`


冒頭部分でライブラリをロードしている。

```
import numpy as np
import pandas as pd
import cudf
import os
from cuml import LinearRegression as cuLinearRegression
from sklearn.linear_model import LinearRegression as skLinearRegression
from sklearn.datasets import make_regression

# Select a particular GPU to run the notebook  
os.environ["CUDA_VISIBLE_DEVICES"]="2"
```

`cudf`、`cuml`あたりがRAPIDSのライブラリか。


途中、cudfを使うあたりで以下のエラーが発生。
```
terminate called after throwing an instance of 'cudf::cuda_error'  what():  CUDA error encountered at: /rapids/cudf/cpp/src/bitmask/valid_ops.cu:170: 48 cudaErrorNoKernelImageForDevice no kernel image is available for execution on the device
```

## 参考）Condaで動作確認の試行錯誤メモ

切り分けも兼ねて、Condaで環境構築し、試してみる。

```
$ conda create -n rapids python=3.6 python
$ conda install -c nvidia/label/cuda10.0 -c rapidsai/label/cuda10.0 -c numba -c conda-forge -c defaults cudf
```

エラー。
```
PackageNotFoundError: Dependencies missing in current linux-64 channels:
```

Condaのバージョンが古かったようなので、`conda update conda`してから再度実行。→成功

cumlを同様にインストールしておく。
```
$ conda install -c nvidia -c rapidsai -c conda-forge -c pytorch -c defaults cuml
```


Jupyterノートブックを起動し、`cuml/linear_regression_demo`を試す。

cudaをインポートするところで以下のようなエラー。

```
OSError: cannot load library '/home/centos/.conda/envs/rapids/lib/librmm.so': libcudart.so.10.0: cannot open shared object file: No such file or directory
```

そこで、  https://github.com/rapidsai/cudf/issues/496 を参照し、cudatoolkitのインストールを試す。
状況が変化し、今度は、`libcublas.so.9.2`が必要と言われた。

```
ImportError: libcublas.so.9.2: cannot open shared object file: No such file or directory
```

CUDA9系を指定されているように見える。
しかし実際にインストールしたのはCUDA10系。
```
/home/centos/.conda/pkgs/cudatoolkit-10.0.130-0/lib/libcublas.so.10.0
```

ここでCUDA9系で試すことにする。
改めてCUDA10系をアンインストールし、CUDA9系をインストール後に以下を実行。

```
$ conda install -c nvidia -c rapidsai -c pytorch -c numba -c conda-forge \
    cudf=0.6 cuml=0.6 python=3.6
```

その後、少なくともライブラリインポートはうまくいった。

余談だが、手元のJupyterノートブック環境では、`%%time`マジックを使ったときに、
そのとき定義した変数がバインドされなかった。
（Dockerで試したときはうまく行ったような気がするが…）

cudfをつかうところで以下のエラー発生。改めてcudatoolkitをインストールする。
```
NvvmSupportError: libNVVM cannot be found. Do `conda install cudatoolkit`:
library nvvm not found
```

その後再度実行。
改めて以下のエラーを発生。

```
  what():  CUDA error encountered at: /conda/envs/gdf/conda-bld/libcudf_1553535868363/work/cpp/src/bitmask/valid_ops.cu:170: 48 cudaErrorNoKernelImageForDevice no kernel image is available for execution on the device
```

### インスタンス種類を変えてみる

基本的なことに気がついた。
g3.4xlargeではなく、p3.2xlargeに変更してみた。

うまくいった。
