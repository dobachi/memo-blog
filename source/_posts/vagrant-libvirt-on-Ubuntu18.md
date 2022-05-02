---

title: vagrant-libvirt on Ubuntu18
date: 2018-11-17 20:52:10
categories:
  - Home server
  - Ubuntu
  - KVM
tags:
  - KVM
  - Vagrant
  - libvirt

---

# 参考

* [vagrant-libvirt]
* [デフォルトプールに関するエラーの情報]
* [libvirtでストレージプールを作成]
* [VagrantのダウンロードURL関連エラーの情報]

[vagrant-libvirt]: https://github.com/vagrant-libvirt/vagrant-libvirt
[デフォルトプールに関するエラーの情報]: https://github.com/vagrant-libvirt/vagrant-libvirt/issues/184
[libvirtでストレージプールを作成]: https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/6/html/virtualization_administration_guide/ch13s03s03
[VagrantのダウンロードURL関連エラーの情報]: https://github.com/hashicorp/vagrant/issues/9442

# 手順

## 必要パッケージのインストール

最初に手順通り、vagrantをインストールしておく。 [vagrant-libvirt] によると、upstreamを
用いることが推奨されているので、ここではあえて1.8系を用いることにする。

## Vagrantのプラグイン追加

```
$ sudo apt install gdebi  # 念のため依存関係を解決しながらdebをインストールするため
$ cd ~/Downloads
$ wget https://releases.hashicorp.com/vagrant/1.8.7/vagrant_1.8.7_x86_64.deb
$ sudo gdebi vagrant_1.8.7_x86_64.deb
```

続いてソースリストでdeb-srcを有効化する。
diffは以下の通り。

```
$ sudo diff -u /etc/apt/sources.list{,.2018111701}
--- /etc/apt/sources.list       2018-11-17 21:06:52.975641015 +0900
+++ /etc/apt/sources.list.2018111701    2018-11-17 21:06:29.396143241 +0900
@@ -3,20 +3,20 @@
 # See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
 # newer versions of the distribution.
 deb http://jp.archive.ubuntu.com/ubuntu/ bionic main restricted
-deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic main restricted
+# deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic main restricted

 ## Major bug fix updates produced after the final release of the
 ## distribution.
 deb http://jp.archive.ubuntu.com/ubuntu/ bionic-updates main restricted
-deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic-updates main restricted
+# deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic-updates main restricted

 ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
 ## team. Also, please note that software in universe WILL NOT receive any
 ## review or updates from the Ubuntu security team.
 deb http://jp.archive.ubuntu.com/ubuntu/ bionic universe
-deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic universe
+# deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic universe
 deb http://jp.archive.ubuntu.com/ubuntu/ bionic-updates universe
-deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic-updates universe
+# deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic-updates universe

 ## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
 ## team, and may not be under a free licence. Please satisfy yourself as to
@@ -24,9 +24,9 @@
 ## multiverse WILL NOT receive any review or updates from the Ubuntu
 ## security team.
 deb http://jp.archive.ubuntu.com/ubuntu/ bionic multiverse
-deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic multiverse
+# deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic multiverse
 deb http://jp.archive.ubuntu.com/ubuntu/ bionic-updates multiverse
-deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic-updates multiverse
+# deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic-updates multiverse

 ## N.B. software from this repository may not have been tested as
 ## extensively as that contained in the main release, although it includes
@@ -34,7 +34,7 @@
 ## Also, please note that software in backports WILL NOT receive any review
 ## or updates from the Ubuntu security team.
 deb http://jp.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse
-deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse
+# deb-src http://jp.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse

 ## Uncomment the following two lines to add software from Canonical's
 ## 'partner' repository.
@@ -44,8 +44,8 @@
 # deb-src http://archive.canonical.com/ubuntu bionic partner

 deb http://security.ubuntu.com/ubuntu bionic-security main restricted
-deb-src http://security.ubuntu.com/ubuntu bionic-security main restricted
+# deb-src http://security.ubuntu.com/ubuntu bionic-security main restricted
 deb http://security.ubuntu.com/ubuntu bionic-security universe
-deb-src http://security.ubuntu.com/ubuntu bionic-security universe
+# deb-src http://security.ubuntu.com/ubuntu bionic-security universe
 deb http://security.ubuntu.com/ubuntu bionic-security multiverse
-deb-src http://security.ubuntu.com/ubuntu bionic-security multiverse
+# deb-src http://security.ubuntu.com/ubuntu bionic-security multiverse
```

```
$ sudo apt update
$ sudo apt-get build-dep vagrant ruby-libvirt
$ sudo apt-get install qemu libvirt-bin ebtables dnsmasq
$ sudo apt-get install libxslt-dev libxml2-dev libvirt-dev zlib1g-dev ruby-dev
```

Vagrantのプラグインを追加する。

```
$ vagrant plugin install vagrant-libvirt
```

## Vagrantfileの作成

続いて、以下のようなVagrantfileを用意し、vagrant upする。

※この時点のVagrantfileでは正常に動かないので注意。ここでは時系列のままに記載している。

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

#  config.vm.provider :virtualbox do |vb|
#    vb.auto_nat_dns_proxy = false
#    vb.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
#    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
#  end

  config.vm.define "hd-01" do |config|
        config.vm.box = "centos/7"
        config.vm.network :private_network, ip: "192.168.33.81"
        config.vm.hostname = "hd-01"
  end

  config.vm.define "hd-02" do |config|
        config.vm.box = "centos/7"
        config.vm.network :private_network, ip: "192.168.33.82"
        config.vm.hostname = "hd-02"
  end

  config.vm.define "hd-03" do |config|
        config.vm.box = "centos/7"
        config.vm.network :private_network, ip: "192.168.33.83"
        config.vm.hostname = "hd-03"
  end

  config.vm.define "hd-04" do |config|
        config.vm.box = "centos/7"
        config.vm.network :private_network, ip: "192.168.33.84"
        config.vm.hostname = "hd-04"
  end

end
```

## ストレージプールdefaultの不在に関連したエラー

このとき、

```
There was error while creating libvirt storage pool: Call to virStoragePoolDefineXML failed: operation failed: Storage source conflict with pool: 'images'
```

のようなエラーが生じたが、これは [デフォルトプールに関するエラーの情報] に掲載の課題のようだ。
[libvirtでストレージプールを作成] を参考に、ストレージプールを作成する。

```
$ sudo virsh pool-define-as default dir --target /var/lib/libvirt/default
$ sudo virsh pool-build default
$ sudo virsh pool-start default
$ sudo virsh pool-autostart default
```

## Vagrant BoxのダウンロードURLに関連したエラー

つづいて、`vagrant up --provider=libvirt`しようとしたら、以下のエラーが生じた。

```
The box 'centos/7' could not be found or
could not be accessed in the remote catalog. If this is a private
box on HashiCorp's Atlas, please verify you're logged in via
`vagrant login`. Also, please double-check the name. The expanded
URL and error message are shown below:

URL: ["https://atlas.hashicorp.com/centos/7"]
Error: The requested URL returned error: 404 Not Found
```

[VagrantのダウンロードURL関連エラーの情報] に記載の通り、いったん

```
Vagrant::DEFAULT_SERVER_URL.replace('https://vagrantcloud.com')
```

の記載をVagrantfileの先頭に記載する、というワークアラウンドを取り入れることにした。

