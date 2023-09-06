---

title: Spark with Kata Container
date: 2022-02-03 01:47:15
categories:
    - Knowledge Management
    - Apache Spark
tags:
    - Apache Spark
    - Kubernetes

---

# メモ

## 試しにMinikube上でKata Container利用

[Installing Kata Containers in Minikube] を参考に実施する。
ドキュメント内の通り、 [KVM/Installation] の通りKVMインストール。

```shell
$ sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
$ sudo adduser `id -un` libvirt
$ sudo adduser `id -un` kvm
```

ネストVMが有効かどうか確認する。

```shell
$ cat /sys/module/kvm_intel/parameters/nested
```

基本的なパラメータを渡し、minikubeを起動

```shell
$ minikube start --vm-driver kvm2 --memory 2048 --network-plugin=cni --enable-default-cni --container-runtime=cri-o --bootstrapper=kubeadm
```

containerdを利用する場合は以下。

```shell
$ minikube start --vm-driver kvm2 --memory 4096 --container-runtime=containerd --bootstrapper=kubeadm
```

nodeを確認する。

```shell
$ minikube kubectl -- get nodes
NAME       STATUS   ROLES                  AGE   VERSION
minikube   Ready    control-plane,master   47h   v1.22.3

$ minikube ssh "egrep -c 'vmx|svm' /proc/cpuinfo"
2
```

```shell
$ git clone https://github.com/kata-containers/kata-containers.git
$ cd kata-containers/tools/packaging/kata-deploy
$ minikube kubectl -- apply -f kata-rbac/base/kata-rbac.yaml
$ minikube kubectl -- apply -f kata-deploy/base/kata-deploy.yaml
```

```shell
$ podname=$(minikube kubectl -- -n kube-system get pods -o=name | fgrep kata-deploy | sed 's?pod/??')
$ minikube kubectl -- -n kube-system exec ${podname} -- ps -ef | fgrep infinity
```

ここで、RuntimeClassの設定を行う。

```shell
$ cd runtimeclasses
$ minikube kubectl -- apply -f kata-runtimeClasses.yaml
```

サンプルを動作させる。

```shell
$ cd ../examples/
$ minikube kubectl -- apply -f test-deploy-kata-qemu.yaml
$ minikube kubectl -- rollout status deployment php-apache-kata-qemu
```


# 参考

* [Installing Kata Containers in Minikube]
* [KVM/Installation]
* [node-api]
* [api]

[Installing Kata Containers in Minikube]: https://github.com/kata-containers/kata-containers/blob/main/docs/install/minikube-installation-guide.md
[KVM/Installation]: https://help.ubuntu.com/community/KVM/Installation
[node-api]: https://github.com/kubernetes/node-api
[api]: https://github.com/kubernetes/api



<!-- vim: set et tw=0 ts=2 sw=2: -->
