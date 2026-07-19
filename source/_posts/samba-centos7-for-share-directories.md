---
title: CentOS7でテキトーにSambaで共有するディレクトリを作成する
date: 2018-10-01 21:02:34
categories:
  - Home server
  - File server
tags:
  - Samba
  - CentOS7
---

# 参考情報

* [CentOS 7とsambaでWindows用ファイルサーバーを設定する。古いサーバーの有効利用に最適]
* [Mac と Windows からパスワードなしで Samba サーバーにアクセスする]

[CentOS 7とsambaでWindows用ファイルサーバーを設定する。古いサーバーの有効利用に最適]: https://www.rem-system.com/centos-samba/ 
[Mac と Windows からパスワードなしで Samba サーバーにアクセスする]: https://ryogan.org/blog/2012/12/31/mac-%E3%81%A8-windows-%E3%81%8B%E3%82%89%E3%83%91%E3%82%B9%E3%83%AF%E3%83%BC%E3%83%89%E3%81%AA%E3%81%97%E3%81%A7-samba-%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%81%AB%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9/

# 基本的な流れ

[CentOS 7とsambaでWindows用ファイルサーバーを設定する。古いサーバーの有効利用に最適] の流れで
基本的に問題なかったのですが、上記ブログでは匿名ユーザの利用を前提としていませんでした。
そこで、 [Mac と Windows からパスワードなしで Samba サーバーにアクセスする] を参考に匿名ユーザでのアクセスを許可しました。

