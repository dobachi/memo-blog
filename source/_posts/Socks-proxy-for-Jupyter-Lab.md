---

title: Socks proxy for Jupyter Lab
date: 2021-07-12 17:53:27
categories:
  - Knowledge Management
  - Python
  - Jupyter
tags:
  - Python
  - Jupyter

---

# 参考


# メモ

以下の条件に当てはまる場合に設定する項目。

* Jupyter Labをリモート環境で実行している
* Socksプロキシを使っている
* ChromeやFirefoxのエクステンションでFoxyProxyのようなURLマッチングでプロキシを差し替えている

このとき、https?に加え、wsも指定する必要があります。
具体的には以下の通り。

![Foxy Proxyでの設定例1](/memo-blog/images/20210712_foxy_example1.png)

![Foxy Proxyでの設定例2](/memo-blog/images/20210712_foxy_example2.png)

つまりは、ウェブソケットのことを忘れることなかれ、ということである。
（いつも忘れるから、備忘録として記載しておく）

<!-- vim: set et tw=0 ts=2 sw=2: -->
