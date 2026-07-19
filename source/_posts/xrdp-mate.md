---
title: XRDPでMATE Desktopを標準で用いる
date: 2018-10-06 22:36:35
categories:
  - Home server
  - Remote desktop
tags:
  - CentOS7
  - MATE Desktop
---

# 参考

http://www.mikitechnica.com/39-xrdp-mate.html

# 基本的な手順

## 全ユーザで有効

```
$ sudo echo "PREFERRED=/usr/bin/mate-session" > /etc/sysconfig/desktop
```

vimで編集しても良い。

## ユーザごと

```
$ echo "/usr/bin/mate-session" > ~/.Xclients
$ chmod +x ~/.Xclients
```
