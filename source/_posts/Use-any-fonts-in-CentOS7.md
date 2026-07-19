---
title: Use any fonts in CentOS7
date: 2021-04-30 10:55:16
categories:
tags:
---

# 参考

* [Microsoft Windows用TrueTypeフォントを使用する]

[Microsoft Windows用TrueTypeフォントを使用する]: http://park1.wakwak.com/~ima/centos4_truetypefont0001.html


# メモ

/usr/share/fonts以下に適当なディレクトリを作成。

```shell
$ sudo mkdir /usr/share/fonts/original
```

フォントを格納

```shell
$ sudo cp ＜何かしらのフォント＞ /usr/share/fonts/original
```

更新。


```shell
$ cd /usr/share/fonts/original
$ sudo mkfontdir
$ sudo mkfontscale
```

## 元ネタ

[Microsoft Windows用TrueTypeフォントを使用する] が参考になった。
（が、MS社フォントは今回は用いていない）


<!-- vim: set et tw=0 ts=2 sw=2: -->
