---

title: Use Anaconda with BitTop Docker environment
date: 2019-02-08 15:46:33
categories:
  - Knowledge Management
  - Hadoop
  - BigTop
tags:
  - BigTop
  - Anaconda
  - Python
  - Hadoop

---

# 参考

* [AnacondaをDockerで起動する手順を紹介するブログ]
* [BigTopの環境をDocker上に作る]

[AnacondaをDockerで起動する手順を紹介するブログ]: https://qiita.com/yaiwase/items/3a58313e028315004a56
[BigTopの環境をDocker上に作る]: https://dobachi.github.io/memo-blog/2019/02/07/Create-BigTop-environment-on-Docker/

# メモ

事前にBigTopのDocker環境を構築しておく。（参考：[BigTopの環境をDocker上に作る]）

```
$ <bigtopのdocker関連のディレクトリ>
$ sudo docker pull continuumio/anaconda3
$ mkdir -p jupyter-notebook/notebooks
```

## （参考）動作確認
以下のコマンドで、docker-compose化させる前に動作確認した。

```
$ sudo docker run --name jupyter-notebook -i -t -p 8888:8888 continuumio/anaconda3 /bin/bash -c "/opt/conda/bin/conda install jupyter -y --quiet && mkdir -p /opt/notebooks && /opt/conda/bin/jupyter notebook --notebook-dir=/opt/notebooks --ip='0.0.0.0' --port=8888 --no-browser --allow-root"
```
