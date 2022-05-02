---

title: Docker on WSL
date: 2019-01-14 21:12:59
categories:
  - Knowledge Management
  - WSL
  - Docker
tags:
  - Docker
  - WSL
  - Ubuntu

---

# 参考

* [geerlingguy/docker] 
* [WSLでDockerをインストールする手順を示したブログ]
* [docker-composeの公式ドキュメント]
* [docker-composeのインストール手順]

[geerlingguy/docker]: https://galaxy.ansible.com/geerlingguy/docker
[WSLでDockerをインストールする手順を示したブログ]: https://qiita.com/yanoshi/items/dcecbf117d9cbd14af87
[Dockerのバージョンについての言及]: https://qiita.com/guchio/items/3eb0818df44fdbab3d14
[docker-composeの公式ドキュメント]: http://docs.docker.jp/compose/gettingstarted.html
[docker-composeのインストール手順]: http://docs.docker.jp/compose/install.html

# メモ

## Docker

[WSLでDockerをインストールする手順を示したブログ]を参考に、[geerlingguy/docker] を用いてAnsibleでDockerをインストールしてみたが、

* 2019/01現在のWSLでは17.09.0以前のDockerを用いる必要がある（[Dockerのバージョンについての言及] 参照）
* 自身のUbuntu18系の環境に置ける [geerlingguy/docker] では18系のDockerしかインストールできない

ということから、 [Dockerのバージョンについての言及] を参考に17系のDockerを無理やりインストールしたところ一応動いた。

まず *管理者権限で* WSLを立ち上げる。
つづいて、以下のとおりインストールする。

```
$ curl -O https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/docker-ce_17.09.0~ce-0~debian_amd64.deb
$ sudo dpkg -i docker-ce_17.09.0\~ce-0\~debian_amd64.deb
```

サービスを起動して動作確認。

```
$ sudo service docker start
$ sudo docker run hello-world
```

なお、[WSLでDockerをインストールする手順を示したブログ] では「管理者権限でWSLを起動する」ことがポイントとあげられていたので、それは守ることにした。
が、インストール後は管理者権限でなくても動いたので、このあたり真偽の確認が必要そうだ。

## docker-compose
おおむね [docker-composeのインストール手順] のとおりにインストールする。

```
$ sudo su - -c "curl -L https://github.com/docker/compose/releases/download/1.6.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
$ sudo chmod +x /usr/local/bin/docker-compose
```

[docker-composeの公式ドキュメント] の通りためしてみるが、以下のようなエラーが生じた。

```
$ sudo docker-compose up
Creating network "composetest_default" with the default driver
ERROR: Failed to Setup IP tables: Unable to enable NAT rule:  (iptables failed: iptables --wait -t nat -I POSTROUTING -s 172.18.0.0/16 ! -o br-3a6517e292d4 -j MASQUERADE: iptables: Invalid argument. Run `dmesg' for more information.
 (exit status 1))
```

WSLがLinuxカーネルではないことに起因しているのだろう可。（iptablesまわりは期待したとおりに動かない？）
