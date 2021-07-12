---

title: sort by timestamp with NERDTree
date: 2019-08-24 22:29:34
categories:
  - Knowledge Management
  - vim
tags:
  - vim
  - NERDTree

---

# 参考

* [Support sorting files and directories by modification time. #901]
* [NERDTree.txt]

[Support sorting files and directories by modification time. #901]: https://github.com/scrooloose/nerdtree/pull/901
[NERDTree.txt]: https://github.com/scrooloose/nerdtree/blob/master/doc/NERDTree.txt

# メモ

vimでNERDTreeを使うとき、直近ファイルを参照したいことが多いため、デフォルトのソート順を変えることにした。

[Support sorting files and directories by modification time. #901] を参照し、タイムスタンプでソートする機能が取り込まれていることがわかったので、
[NERDTree.txt] を参照して設定した。
具体的には、 `NERDTreeSortOrder` の節を参照。

vimrcには、

```
let NERDTreeSortOrder=['\/$', '*', '\.swp$',  '\.bak$', '\~$', '[[-timestamp]]']
```

を追記した。デフォルトのオーダに対し、 `[[-timestamp]]` を追加し、タイムスタンプ降順でソートするようにした。



<!-- vim: set tw=0 ts=4 sw=4: -->
