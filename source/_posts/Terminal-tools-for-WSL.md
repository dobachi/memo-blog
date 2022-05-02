---

title: WSL向けのターミナルツール
date: 2019-01-01 23:30:45
categories:
  - Knowledge Management
  - WSL
  - Terminal tool
tags:
  - WSL
  - Hyper

---

# 参考

* [Hyper]
* [ConEmu]
* [cmder]

[Hyper]: https://hyper.is/
[ConEmu]: https://conemu.github.io/
[cmder]: http://cmder.net/

# Hyper

ウェブ界隈の技術を活用したターミナル。
[Hyper] からダウンロードできる。

インストールすると `%USERPROFILE%\.hyper.js` に設定ファイルが作成される。
デフォルトはcmd.exeが起動されるようになっているので、WSLを使うように変更する。

```
$ diff -u /mnt/c/Users/dobachi/.hyper.js{.2018010101,}
--- /mnt/c/Users/dobachi/.hyper.js.2018010101   2019-01-01 23:26:47.691869000 +0900
+++ /mnt/c/Users/dobachi/.hyper.js      2019-01-01 23:28:25.273185100 +0900
@@ -9,7 +9,7 @@
     updateChannel: 'stable',

     // default font size in pixels for all tabs
-    fontSize: 12,
+    fontSize: 15,

     // font family with optional fallbacks
     fontFamily: 'Menlo, "DejaVu Sans Mono", Consolas, "Lucida Console", monospace',
@@ -107,7 +107,7 @@

     // for setting shell arguments (i.e. for using interactive shellArgs: `['-i']`)
     // by default `['--login']` will be used
-    shellArgs: ['--login'],
+    shellArgs: ['/C', 'wsl'],

     // for environment variables
     env: {},
```

# ConEmu

[ConEmu] からダウンロードできる。
ただし、手元のGPD Pocket上のWSLで使用した時には、ctrl + lで画面クリアするときに
意図と異なる動作をした。

# cmder

[cmder] からダウンロードできる。
ただし、手元のGPD Pocket上のWSLで使用した時には、ctrl + lで画面クリアするときに
意図と異なる動作をした。

