---

title: Trouble about Qemu when I use minikube
date: 2024-11-04 00:52:13
categories:
  - Kubenetes
  - Minikube
tags:
  - Kubenetes
  - Minikube

---

# メモ


[Problems detected in kubelet #17638]にも記載されているが、Ubuntu22上でminikubeを実行していた際、`minikube service`を利用するときに以下のエラーが生じた。

```
MK_UNIMPLEMENTED が原因で終了します: minikube サービスは現在、QEMU 上のビルトインネットワークでは実装されていません  
```

```
Exiting due to MK_UNIMPLEMENTED: minikube service is not currently implemented with the builtin network on QEMU
```

ひとまず、Dockerをドライバとして使用することにした。


```shell
# 既存のクラスタを破棄
minikube delete
# dockerを利用するよう指定して起動
minikube start --driver=docker
```

# 参考
* [Problems detected in kubelet #17638]

[Problems detected in kubelet #17638]: https://github.com/kubernetes/minikube/issues/17638





<!-- vim: set et tw=0 ts=2 sw=2: -->
