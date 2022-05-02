---
title: dein on windows
date: 2018-11-02 21:06:45
categories:
  - Knowledge Management
  - vim
tags:
  - vim
  - dein
  - windows

---

# 参考

* [公式GitHub]
* [windows10にdein.vimをインストールする手順を示したブログ]
* [dein.vimインストール手順や\_vimrcをまとめたレポジトリ]


[公式GitHub]: https://github.com/Shougo/dein.vim
[windows10にdein.vimをインストールする手順を示したブログ]: http://neko-mac.blogspot.com/p/windowsvim.html
[dein.vimインストール手順や\_vimrcをまとめたレポジトリ]: https://github.com/dobachi/vim_config

# Windows環境でのKaoriya版のvimへのインストール


## 基本的な手順

基本的には、 [windows10にdein.vimをインストールする手順を示したブログ] に記載の方法で問題なかった。
ただし、vim81系でないと正常動作しないことに注意。（一度、うっかり74系で使ってしまった）

ただ\_vimrcに追記する設定のうち、PATHはインストーラで出力されたものではなく、
「~」を使って相対PATH指定にした。

例:

```
" Required:
set runtimepath+=~/vimfiles/bundles/repos/github.com/Shougo/dein.vim

(snip)

```

## 設定

今のところの設定は、 [dein.vimインストール手順や\_vimrcをまとめたレポジトリ] に格納した。→ [\_vimrc]

[\_vimrc]: https://github.com/dobachi/vim_config/blob/master/_vimrc


END
