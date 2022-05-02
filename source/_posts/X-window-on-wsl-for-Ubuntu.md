---

title: X Window on wsl for Ubuntu
date: 2018-12-30 23:07:47
categories:
  - Knowledge Management
  - WSL
  - X Window
tags:
  - WSL
  - X Window

---

# 参考

* [一通りの流れが説明されたブログ]
* [VcXsrvのダウンロード]
* [VcXsrvの自動起動設定]
* [WSLを使ってWindowsでmikutterを動かす] -> こちらの方が良いかも
* [お前らのWSLはそれじゃダメだ] -> こちらの方が良いかも
* [Ubuntu 18.04 な WSL 上に日本語入力環境を構築する]
* [fcitxで作るWSL日本語開発環境]
* [WSL で gnome-terminal を動かすお話]
* [Xサーバーを自動起動しよう！]

[一通りの流れが説明されたブログ]: https://estuarine.jp/2017/11/wsl-x-window/
[VcXsrvのダウンロード]: https://sourceforge.net/projects/vcxsrv/files/latest/download
[VcXsrvの自動起動設定]: https://www.yokoweb.net/2018/03/07/windows10-wsl-xserver-appl/
[fcitxで作るWSL日本語開発環境]: https://qiita.com/dozo/items/97ac6c80f4cd13b84558
[Ubuntu 18.04 な WSL 上に日本語入力環境を構築する]: https://qiita.com/maromaro3721/items/be8ce6e3cec4cbcdac00
[WSL で gnome-terminal を動かすお話]: http://hisagi.hateblo.jp/entry/2017/10/21/234202
[WSLを使ってWindowsでmikutterを動かす]: http://moguno.hatenablog.jp/entry/2017/10/08/155023
[お前らのWSLはそれじゃダメだ]: https://xztaityozx.hatenablog.com/entry/2017/12/01/001544
[Xサーバーを自動起動しよう！]: https://demura.net/lecture/15290.html

# メモ


## Windows側

[一通りの流れが説明されたブログ] に記載の通り試した。
[VcXsrvのダウンロード]からダウンロードしたパッケージをインストールする。

なお、インストールすると「XLaunch」がスタートメニューに追加される。
これを都度起動することになるが、スタートアップメニューにショートカットを登録し、
自動起動するようにした。
（ [Xサーバーを自動起動しよう！] を参考にする）


## WSL側

### 最低限のインストール

関連パッケージのインストール
```
$ sudo apt install git build-essential libssl-dev libreadline-dev zlib1g-dev x11-apps x11-utils x11-xserver-utils libsqlite3-dev nodejs fonts-ipafont libxml2-dev libxslt1-dev
```

`~/.bashrc`に環境変数DISPLAYの値を追加
```
--- /home/dobachi/.bashrc.2018123001    2018-12-30 23:21:48.626055900 +0900
+++ /home/dobachi/.bashrc       2018-12-30 23:20:26.333894000 +0900
@@ -115,3 +115,5 @@
     . /etc/bash_completion
   fi
 fi
+
+export DISPLAY=localhost:0.0
```

### 日本語関連

上記手順だけでは日本語入力環境が整わないので、
[WSLを使ってWindowsでmikutterを動かす] と [お前らのWSLはそれじゃダメだ] を参考に日本語環境を構築する。
まず、[WSLを使ってWindowsでmikutterを動かす] のとおり、uim-anthyをインストールし、
[お前らのWSLはそれじゃダメだ] のとおり、`~/.uim`を設定する。
結局は、[お前らのWSLはそれじゃダメだ]のとおりで良さそうではある。

```
$ sudo apt install language-pack-ja
$ sudo update-locale LANG=ja_JP.UTF-8
$ sudo apt install -y uim uim-xim uim-fep uim-anthy dbus-x11
$ cat << EOF > ~/.uim
  (define default-im-name 'anthy)
  (define-key generic-on-key? '("<Control> "))
  (define-key generic-off-key? '("<Control> "))
  EOF
$ cat << EOF >> ~/.profile
  export GTK_IM_MODULE=uim
  EOF
```
### 例：GUI vimのインストール
使いたいツールをインストール。

```
$ sudo apt install vim-gui-common

(snip)

$ gvim
``` 


