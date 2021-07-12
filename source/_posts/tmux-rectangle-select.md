---

title: tmux_rectangle_select
date: 2018-12-23 22:58:52
categories:
  - Knowledge Management
  - Tools
  - tmux
tags:
  - tmux

---

# 参考

* [矩形選択にも言及のあるブログ]

[矩形選択にも言及のあるブログ]: https://qiita.com/ijiest/items/4a42e8543df373babcf2

# 方法

tmuxを使ってコピーするとき、矩形選択したいときがある。
[矩形選択にも言及のあるブログ] にも記載あるが、 `<prefix> + [` でコピーモードに入った後、
該当箇所まで移動し、スペースキーを押して選択開始、その後 `v` を押すと矩形選択になる。
（初期状態では、行選択になっているはず）
