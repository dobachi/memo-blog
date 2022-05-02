---

title: KVM on Ubuntu18
date: 2018-11-16 23:32:19
categories:
  - Home server
  - Ubuntu
  - KVM
tags:
  - KVM
  - Ubuntu

---

# 参考

* [公式ドキュメント]
* [ネットワークインストールの方法] 
* [VMのIPアドレス確認]
* [ゲストOSにおけるコンソール設定]

[公式ドキュメント]: https://help.ubuntu.com/lts/serverguide/libvirt.html.ja
[ネットワークインストールの方法]: https://qiita.com/zhh/items/df076c4614f0238f9876
[VMのIPアドレス確認]: https://kernhack.hatenablog.com/entry/2015/07/18/154414
[ゲストOSにおけるコンソール設定]: https://www.hiroom2.com/2018/04/30/ubuntu-1804-serial-console-ja/ 

# 手順

## パッケージインストール

```
$ sudo apt install qemu-kvm libvirt-bin
```

```
$ sudo adduser $USER libvirt
```

なお、公式ドキュメント上ではlibvertdグループとされていたが、注釈にあった

```
In more recent releases (>= Yakkety) the group was renamed to libvirt. Upgraded systems get a new libvirt group with the same gid as the libvirtd group to match that.
```

に従い、libvertグループを使用した。

```
$ sudo reboot
```

## イメージの準備

今回は18.04LTSを用いることとする。

```
$ cd ~/Downloads  # ディレクトリがなかったら作成
$ wget http://ftp.jaist.ac.jp/pub/Linux/ubuntu-releases/18.04/ubuntu-18.04.1-desktop-amd64.iso
$ wget http://ftp.jaist.ac.jp/pub/Linux/ubuntu-releases/18.04/ubuntu-18.04.1-live-server-amd64.iso
```

## インストール

```
$ sudo apt install virtinst
```

[ネットワークインストールの方法]ネットワーク経由でインストールすることにした。

```
$ sudo virt-install \
  --name ubuntu1804 \
  --ram 1024 \
  --disk path=/var/lib/libvirt/images/test.img,bus=virtio,size=15 \
  --vcpus 2 \
  --os-type linux \
  --network default \
  --graphics none \
  --console pty,target_type=serial \
  --location 'http://jp.archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/' \
  --extra-args 'console=ttyS0,115200n8 serial'
```

参考までにイメージからインストールするのは以下の通り。（未動作確認）

```
sudo virt-install -n test -r 512 \
--disk path=/var/lib/libvirt/images/test.img,bus=virtio,size=4 -c \
~/Downloads/ubuntu-18.04.1-live-server-amd64.iso --network network=default,model=virtio \
--graphics none \
  --extra-args 'console=ttyS0,115200n8 serial'
```

## ゲスト側のconsole設定

`virsh console` でコンソールに接続できるよう、SSHで接続して設定する。
[VMのIPアドレス確認] を参考に、IPアドレスを確認する。

```
~$ sudo virsh net-dhcp-leases default
 Expiry Time          MAC address        Protocol  IP address                Hostname        Client ID or DUID
-------------------------------------------------------------------------------------------------------------------
 2018-11-17 03:08:52  52:54:00:b0:68:26  ipv4      192.168.122.193/24        ubuntu1804      ff:32:39:f9:b5:00:02:00:00:ab:11:97:79:8b:63:02:9c:d8:07
```
[ゲストOSにおけるコンソール設定] に従って設定する。

まず `/etc/default/grub` を修正する。


```
$ sudo echo > /etc/default/grub << EOL
  # If you change this file, run 'update-grub' afterwards to update
  # /boot/grub/grub.cfg.
  # For full documentation of the options in this file, see:
  #   info -f grub -n 'Simple configuration'
  
  GRUB_DEFAULT=0
  GRUB_TIMEOUT_STYLE=hidden
  GRUB_TIMEOUT=10
  GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
  GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
  GRUB_CMDLINE_LINUX="console=tty1 console=ttyS0,115200"
  
  # Uncomment to enable BadRAM filtering, modify to suit your needs
  # This works with Linux (no patch required) and with any kernel that obtains
  # the memory map information from GRUB (GNU Mach, kernel of FreeBSD ...)
  #GRUB_BADRAM="0x01234567,0xfefefefe,0x89abcdef,0xefefefef"
  
  # Uncomment to disable graphical terminal (grub-pc only)
  #GRUB_TERMINAL=console
  
  # The resolution used on graphical terminal
  # note that you can use only modes which your graphic card supports via VBE
  # you can see them in real GRUB with the command `vbeinfo'
  #GRUB_GFXMODE=640x480
  
  # Uncomment if you don't want GRUB to pass "root=UUID=xxx" parameter to Linux
  #GRUB_DISABLE_LINUX_UUID=true
  
  # Uncomment to disable generation of recovery mode menu entries
  #GRUB_DISABLE_RECOVERY="true"
  
  # Uncomment to get a beep at grub start
  #GRUB_INIT_TUNE="480 440 1"
  #GRUB_TERMINAL=serial
  GRUB_TERMINAL="console serial"
  GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
  EOL
```

grubの設定ファイルを再生成する。

```
$ sudo grub-mkconfig -o /boot/grub/grub.cfg
```

rebootする。

```
$ sudo reboot
```

reboot後に`virsh console <VM名>`でアクセスすればコンソールに接続できる。
抜けるときは、Ctrl + ]もしくはCtrl + 5。
