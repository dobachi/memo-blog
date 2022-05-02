---

title: tmuxでctrl + lを押したときに改行の挙動がおかしくなる現象
date: 2018-12-30 22:26:21
categories:
  - Knowledge Management
  - Tools
  - tmux
tags:
  - tmux

---

# 参考

* [tmux-1419]

[tmux-1419]: https://github.com/tmux/tmux/issues/1419


# メモ

[tmux-1419] に記載の通り、`~/.tmux.conf`に以下のように記載すると、
強制的に改行されるようになるようだ。

```
set -as terminal-overrides ',*:indn@'
```
