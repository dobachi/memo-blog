---

title: US keyboard layout on Ubuntu22
date: 2024-09-08 23:20:17
categories:
  - Knowledge Management
  - Ubuntu
tags:
  - Ubuntu

---

# メモ

VMWare WorkstationでUbuntu 22系をインストールしたところ、物理キーボードがUS配列なのに、日本語配列で認識されてしまったので直した。

[Ubuntu 22.04 でキーボードレイアウトおかしくなる問題。] にも記載されているのだが、`/usr/share/ibus/component/mozc.xml`には以下のような記載がある。

```
<!-- Settings of <engines> and <layout> are stored in ibus_config.textproto -->
<!-- under the user configuration directory, which is either of: -->
<!-- * $XDG_CONFIG_HOME/mozc/ibus_config.textproto -->
<!-- * $HOME/.config/mozc/ibus_config.textproto -->
<!-- * $HOME/.mozc/ibus_config.textproto -->
```

自分の環境だと、以下のような場所にあった。

```shell
$ sudo find / -name *ibus_config.textproto*

(snip)

/home/dobachi/.config/mozc/ibus_config.textproto
```

以下のように`layout`を変更する。もともと`default`である。

```shell
$ cat /home/dobachi/.config/mozc/ibus_config.textproto
```

```
engines {
  name : "mozc-jp"
  longname : "Mozc"
  layout : "us"
}
```

# 参考

* [Ubuntu 22.04 でキーボードレイアウトおかしくなる問題。]
* [【Ubuntu】Ubuntu18.04で日本語入力ができなくなった時に解決した事例の紹介【備忘録]

[【Ubuntu】Ubuntu18.04で日本語入力ができなくなった時に解決した事例の紹介【備忘録]: https://zenn.dev/siganai/articles/20221110_ubuntu_mozc_error
[Ubuntu 22.04 でキーボードレイアウトおかしくなる問題。]: https://golang.hateblo.jp/entry/ubuntu22.04-keyboard-layout-mozc





<!-- vim: set et tw=0 ts=2 sw=2: -->
