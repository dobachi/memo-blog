---

title: Error about the memory configuration of Minikube
date: 2022-01-10 22:43:27
categories:
  - Knowledge Management
  - Kubernetes
tags:
  - Kubernetes
  - Minikube
  - Troubleshoot

---

# メモ

## 現状の結論（2022/1/10時点）

解決まで至ってはいなく、状況整理したのみ。

## 雑記

[minikube 1.23 Your cgroup does not allow setting memory #12842] にも記載されているエラーが以下の環境で生じた。

環境

```shell
dobachi@ubu18:~$ minikube version
minikube version: v1.24.0
commit: 76b94fb3c4e8ac5062daf70d60cf03ddcc0a741b

dobachi@ubu18:~$ cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=18.04
DISTRIB_CODENAME=bionic
DISTRIB_DESCRIPTION="Ubuntu 18.04.6 LTS"

dobachi@ubu18:~$ uname -a
Linux ubu18 5.4.0-92-generic #103~18.04.2-Ubuntu SMP Wed Dec 1 16:50:36 UTC 2021 x86_64 x86_64 x86_64 GNU/Linux

dobachi@ubu18:~$ grep cgroup /proc/filesystems
nodev   cgroup
nodev   cgroup2
```

上記のIssueに記載されている通り、Minikubeでは、cgroupでメモリリミットを設定できるかどうかを確認する際、
以下のような関数を利用する。 

[oci.go#L111-L124]

```go
func HasMemoryCgroup() bool {
	memcg := true
	if runtime.GOOS == "linux" {
		var memory string
		if cgroup2, err := IsCgroup2UnifiedMode(); err == nil && cgroup2 {
			memory = "/sys/fs/cgroup/memory/memsw.limit_in_bytes"
		}
		if _, err := os.Stat(memory); os.IsNotExist(err) {
			klog.Warning("Your kernel does not support memory limit capabilities or the cgroup is not mounted.")
			memcg = false
		}
	}
	return memcg
}
```

以下のファイルをstatしているのだが…

```go
			memory = "/sys/fs/cgroup/memory/memsw.limit_in_bytes"
```

これは上記環境では存在しない。

```shell
dobachi@ubu18:~$ sudo stat /sys/fs/cgroup/memory/memsw.limit_in_bytes
stat: '/sys/fs/cgroup/memory/memsw.limit_in_bytes' を stat できません: そのようなファイルやディレクトリはありません
```

一方、 `/sys/fs/cgroup/memory/memory.soft_limit_in_bytes` なら存在する。

```shell
dobachi@ubu18:~$ sudo stat /sys/fs/cgroup/memory/memory.soft_limit_in_bytes
  File: /sys/fs/cgroup/memory/memory.soft_limit_in_bytes
  Size: 0               Blocks: 0          IO Block: 4096   通常の空ファイル
Device: 23h/35d Inode: 11          Links: 1
Access: (0644/-rw-r--r--)  Uid: (    0/    root)   Gid: (    0/    root)
Access: 2022-01-10 21:39:31.409626300 +0900
Modify: 2022-01-10 21:39:31.409626300 +0900
Change: 2022-01-10 21:39:31.409626300 +0900
 Birth: -
```

なお、 エラーメッセージにある通り、 [Your kernel does not support cgroup swap limit capabilities] にしたがってGRUP設定を変更・反映し、リブートしても状況は変わらない。

PodmanのIssueではあるが、関連する議論が [podman unable to limit memory (-m flag) on Ubuntu/Debian distros #6365] に記載されている。

# 参考

* [minikube 1.23 Your cgroup does not allow setting memory #12842]
* [oci.go#L111-L124]
* [Your kernel does not support cgroup swap limit capabilities]
* [/sys/fs/cgroup/memory/memory.limit_in_bytes not present in Fedora 33]
* [podman unable to limit memory (-m flag) on Ubuntu/Debian distros #6365]

[minikube 1.23 Your cgroup does not allow setting memory #12842]: https://github.com/kubernetes/minikube/issues/12842
[oci.go#L111-L124]: https://github.com/kubernetes/minikube/blob/25d17c2dde4920c00b4fe6f42aece999ce92cd5c/pkg/drivers/kic/oci/oci.go#L111-L124
[Your kernel does not support cgroup swap limit capabilities]: https://docs.docker.com/engine/install/linux-postinstall/#your-kernel-does-not-support-cgroup-swap-limit-capabilities
[/sys/fs/cgroup/memory/memory.limit_in_bytes not present in Fedora 33]: https://stackoverflow.com/questions/65646317/sys-fs-cgroup-memory-memory-limit-in-bytes-not-present-in-fedora-33
[podman unable to limit memory (-m flag) on Ubuntu/Debian distros #6365]: https://github.com/containers/podman/issues/6365




<!-- vim: set et tw=0 ts=2 sw=2: -->
