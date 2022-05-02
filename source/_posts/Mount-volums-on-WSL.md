---

title: Docker DesktopをWSLから利用している場合のマウントについて
date: 2019-06-09 23:59:02
categories:
  - Knowledge Management
  - WSL
  - Docker
tags:
  - WSL
  - Docker

---

# 参考

* [Docker for WindowsをWSLから使う時のVolumeの扱い方]

[Docker for WindowsをWSLから使う時のVolumeの扱い方]: https://qiita.com/gentaro/items/7dec88e663f59b472de6


# メモ

[Docker for WindowsをWSLから使う時のVolumeの扱い方] に起債されている通りだが、
うっかり `-v /tmp/hoge:/hoge` とかやると、Docker Desktopで使用しているDocker起動用の仮想マシン中の `/tmp/hoge` をマウントすることになる。
