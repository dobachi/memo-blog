---

title: Mount host's filesystem on KVM
date: 2019-02-03 22:31:25
categories:
  - Home server
  - Ubuntu
  - KVM
tags:
  - KVM
  - Ubuntu

---

# 参考

* [マウントの仕方を示しているブログ]

[マウントの仕方を示しているブログ]: https://qiita.com/tukiyo3/items/c72685b2a9c34442811e

# メモ

[マウントの仕方を示しているブログ] の通りで問題ない。

## 補足

「ハードウェアの追加」から「ファイルシステム」を追加する。

ゲストOSでマウントするときに、ディレクトリを作成し忘れないこと。

手動でマウント

```
$ sudo mount -t 9p -o trans=virtio hostdata /mnt/data
```

fstabには以下のように記載

```
hostdata	/mnt/data	9p	trans=virtio	0	1
```
