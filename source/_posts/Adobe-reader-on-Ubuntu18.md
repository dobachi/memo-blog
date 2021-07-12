---

title: Adobe reader on Ubuntu18
date: 2018-12-11 22:34:56
categories:
  - Home server
  - Ubuntu
  - Adobe Reader
tags:
  - Adobe Reader
  - PDF

---

# 参考

* [Adobe Readerのインストール手順を記したブログ]
* [ファイラから開くときのデフォルトアプリの設定の参考にした情報]

[Adobe Readerのインストール手順を記したブログ]: https://linuxconfig.org/how-to-install-adobe-acrobat-reader-on-ubuntu-18-04-bionic-beaver-linux
[ファイラから開くときのデフォルトアプリの設定の参考にした情報]: http://www.e-webcast.net/archives/148

# 手順

[Adobe Readerのインストール手順を記したブログ] に記載の手順で基本的には問題ない。

```
$ sudo apt install libxml2:i386 gdebi-core 
$ cd ~/Downloads
$ wget ftp://ftp.adobe.com/pub/adobe/reader/unix/9.x/9.5.5/enu/AdbeRdr9.5.5-1_i386linux_enu.deb
$ sudo gdebi AdbeRdr9.5.5-1_i386linux_enu.deb
```

[ファイラから開くときのデフォルトアプリの設定の参考にした情報] を参考に設定する。

```
$ sudo vim /etc/gnome/defaults.list
```

変更内容は以下の通り。

```
--- /etc/gnome/defaults.list.2018121101	2018-12-11 22:42:03.566334756 +0900
+++ /etc/gnome/defaults.list	2018-12-11 22:42:15.970075520 +0900
@@ -5,7 +5,7 @@
 application/msword=libreoffice-writer.desktop
 application/ogg=rhythmbox.desktop
 application/oxps=evince.desktop
-application/pdf=evince.desktop
+application/pdf=acroread.desktop
 application/postscript=evince.desktop
 application/rtf=libreoffice-writer.desktop
 application/tab-separated-values=libreoffice-calc.desktop
```
