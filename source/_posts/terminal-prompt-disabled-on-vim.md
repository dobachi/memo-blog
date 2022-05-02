---

title: terminal prompt disabled on vim
date: 2019-01-13 23:48:42
categories:
  - Knowledge Management
  - vim
tags:
  - vim
  - git

---

# 参考

* [CODE Q&Aの質疑応答]
* [deol.vim]

[CODE Q&Aの質疑応答]: https://code.i-harness.com/en/q/1ebd4cf
[deol.vim]: https://github.com/Shougo/deol.nvim

# メモ

gvimで [deol.vim] を使ってターミナルを開き、`git push origin master` をしたら、
以下のようなエラーが生じた。

```
fatal: could not read Password for 'https://xxxxxxxxx@github.com': terminal prompts disabled
```

[CODE Q&Aの質疑応答] にも記載があるが

```
$ GIT_TERMINAL_PROMPT=1 git push origin master
```

のように、`GIT_TERMINAL_PROMPT=1`でOK。
