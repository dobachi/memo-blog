---

title: Docker for Windows with WSL
date: 2019-02-02 00:08:22
categories:
  - Knowledge Management
  - WSL
  - Docker
tags:
  - WSL
  - Docker

---

# 参考

* [動かし方を紹介するブログ]

[動かし方を紹介するブログ]: https://qiita.com/tettekete/items/086ea3bc8a798cae33f5

# メモ

上記ブログ [動かし方を紹介するブログ] の内容で基本的に問題ない。
ただし、一般ユーザの`.bashrc`に環境変数DOCKER_HOSTを指定したので、
一般ユーザでDockerを起動できるようにしておいた。
（当該一般ユーザをdockerグループに加えた）

# コマンド

コンテナ確認

```
$ docker ps
$ docker ps -a
```

`-v`を用いてボリュームをマウント。
ついでに`--rm`を用いて停止後に削除することにする。

```
$ docker run -it --rm -v c:/Users/<user name>:/mnt/<user name> <image id> /bin/bash
```
