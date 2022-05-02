---

title: CentOS on WSL
date: 2021-04-25 13:30:49
categories:
  - Knowledge Management
  - WSL
  - CentOS
tags:
  - WSL
  - CentOS

---

# 参考

* [wsl2上で無料でCentOS8を動かそう]
* [CentOS-WSL]
* [CentOS7.zip]

[wsl2上で無料でCentOS8を動かそう]: https://www.geekfeed.co.jp/geekblog/install_centos8_on_wsl2_for_free
[CentOS-WSL]: https://github.com/mishamosher/CentOS-WSL
[CentOS7.zip]: https://github.com/mishamosher/CentOS-WSL/releases/download/7.9-2009/CentOS7.zip

# メモ

Redhat系LinuxをWSL（ないしWSL2）で動かしたい、という話。

[wsl2上で無料でCentOS8を動かそう] で挙げられているレポジトリはアーカイブされているため、
代替手段で対応した。

## CentOS

### CentOS7

[CentOS-WSL] を参考に、まずは手堅くCentOS7。

[wsl2上で無料でCentOS8を動かそう] を参考にすすめる。

[CentOS7.zip] をダウンロードし解凍。
中に含まれている `rootfs.tar.gz` を解凍しておきます。
ここでは、 `C:\Users\dobachi\Downloads\CentOS7\rootfs.tar\rootfs.tar` として解凍されたものとします。

インポート先のディレクトリがなければ、予め作成。
ここでは以下にしました。（他のイメージと同じ感じで）


```
C:\Users\dobachi\AppData\Local\Packages\CentOS7
```

```powershell
wsl --import CentOS7 "C:\Users\dobachi\AppData\Local\Packages\CentOS7" "C:\Users\dobachi\Downloads\CentOS7\rootfs.tar\rootfs.tar"
```

必要に応じてWSL2用に変換。

```powershell
wsl --set-version CentOS7 2
```

その他、必要に応じてWindows Terminalの設定を行う。

また日本語とGUI利用のための設定は、UbuntuとCentOSは少し違うので注意。
日本語でのハマりポイントは以下。

* localectlが使えない
  * /etc/profileに直接ロケール情報を記載すると良い
* Ubuntuとは日本語対応方法が異なる
  * CentOSではibus-kkcを利用すると良い

### CentOS8 Stream

＜あとで書く＞

### Fedora

＜あとで書く＞

<!-- vim: set et tw=0 ts=2 sw=2: -->
