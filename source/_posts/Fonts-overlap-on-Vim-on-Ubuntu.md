---

title: Ubuntu上のgvimでフォントが重なる現象
date: 2018-12-31 00:01:08
categories:
  - Home server
  - Ubuntu
  - vim
tags:
  - vim

---

# 参考

* [現象についての議論]

[現象についての議論]: https://forums.ubuntulinux.jp/viewtopic.php?id=12459

# メモ

[現象についての議論] の通り、`~/.vimrc`に以下を追記して回避した。

```
set ambiwidth=double
```
