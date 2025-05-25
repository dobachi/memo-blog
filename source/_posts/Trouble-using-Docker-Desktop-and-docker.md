---

title: Trouble using Docker Desktop and docker
date: 2024-11-04 00:56:32
categories:
  - Docker
tags:
  - Docker

---

# メモ

Ubuunu22で、Docker Desktopとディストリ向けパッケージのDockerを混在させたときにトラブったので備忘録。
ひとまず、Contextの指定を忘れないように。（自分向けメモ）

```shell
# コンテキストの確認
docker context ls
# コンテキスト切り替え
docker context use <任意のコンテキスト>
```

なお、DOCKER_HOSTの環境変数にも注意。
うっかり、なにかの名残で指定していることがあるので。

# 参考





<!-- vim: set et tw=0 ts=2 sw=2: -->
