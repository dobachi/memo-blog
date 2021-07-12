---
title: qmk_firmware_202009
date: 2020-09-06 03:14:27
categories:
  - Knowledge Management
  - Keyboard
  - QMK

tags:
  - QMK
  - keyboard
---


# 参考

* [QMK Firmwareでファームウェアをビルドしようとしたらavr-gccでコケた話]
* [公式の環境構築手順]
* [公式のコンパイル手順]

[QMK Firmwareでファームウェアをビルドしようとしたらavr-gccでコケた話]: https://qiita.com/huequica/items/6067d3a022c7cd719ab2
[公式の環境構築手順]: https://docs.qmk.fm/#/newbs_building_firmware
[公式のコンパイル手順]: https://docs.qmk.fm/#/newbs_flashing


# メモ

2020/9に久しぶりにコンパイルしようとしたら、だいぶ勝手が変わっていた。

[公式の環境構築手順] に従って環境を構築した。
なお、インストールするよう指定されていたパッケージだけでは足りなかったので、
以下のようにインストールした。

```shell
$ pacman --needed --noconfirm --disable-download-timeout -S git mingw-w64-x86_64-toolchain mingw-w64-x86_64-python3-pip python3 python3-pip make diffutils
```

最初、以下を忘れたため、失敗したので注意・・・。

```shell
$ qmk setup
```

[公式のコンパイル手順] に従うと、qmkコマンドを利用してコンパイル、フラッシュするようだ。

ただ、 [QMK Firmwareでファームウェアをビルドしようとしたらavr-gccでコケた話] に記載されているのと同様に、
`make git-submodules` が必要だった。

<!-- vim: set et tw=0 ts=2 sw=2: -->
