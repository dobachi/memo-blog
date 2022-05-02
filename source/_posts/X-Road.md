---

title: X-Road
date: 2021-09-03 22:58:43
categories:
  - Knowledge Management
  - Data Collaboration
  - X-Road
tags:
  - X-Road

---

# 参考

* [X-RoadのGitHub]
* [X-Roadについての簡易メモ]
* [Using LXD-hosts]
* [X Road Academy Session 1 Setting up a local X-Road development environment]
* [X-Road: Security Server Architecture]
* [X-Road Security Server Architecture Overview]
* [X-Road Security Server Architecture Process View]

[X-RoadのGitHub]: https://github.com/nordic-institute/X-Road
[X-Roadについての簡易メモ]: https://dobachi.github.io/memo-blog/#x-road
[Using LXD-hosts]: https://github.com/nordic-institute/X-Road/blob/develop/ansible/README.md#using-lxd-hosts
[X Road Academy Session 1 Setting up a local X-Road development environment]: https://www.youtube.com/watch?v=RV-Dq69yFVE
[X-Road Security Server Architecture]: https://github.com/nordic-institute/X-Road/blob/develop/doc/Architecture/arc-ss_x-road_security_server_architecture.md
[X-Road Security Server Architecture Overview]: https://github.com/nordic-institute/X-Road/blob/develop/doc/Architecture/arc-ss_x-road_security_server_architecture.md#2-component-view
[X-Road Security Server Architecture Process View]: https://github.com/nordic-institute/X-Road/blob/develop/doc/Architecture/arc-ss_x-road_security_server_architecture.md#3-process-view


# メモ

## X-Roadとは？

一言で言えば、エストニアの電子政府や公共と民間の間のデータ連携に用いられている
データ流通のためのオープンソースソフトウェアである。
他の簡単な紹介は [X-Roadについての簡易メモ] あたりを参照。

## 最初の動作確認

[X-RoadのGitHub] のREADMEによると、AnsibleのPlaybookがある。
READMEから簡単に読み解いてみる。

### Ansibleプレイブックの確認

#### インベントリ

`ansible/hosts/example_xroad_hosts.txt` によると、
central server（cs）、security server（ss）、configuration proxy、certification authorityの
グループが定義されており、csやssは複数台のノードが記載されている。冗長化されている？

`ansible/hosts/lxd_hosts.txt` はコンテナ向けに見える。

なお、エストニア等の国？エリア？に特化するかどうか、という変数がある。
該当しない場合は、 `vanilla` でよさそう。

#### プレイブック（エントリポイント）

デプロイするときは `xroad_init.yml` を利用する。

#### ロール

プレイブックの通り、 `xroad-cs` や `xroad-cp` といったロールが各種類のサーバに対応したロールである。
また、このロールは依存関係に

```yaml
dependencies:
  - { role: xroad-base }
```

のようなものを持っており、 `xroad-base` がレポジトリ等の設定をする役割を担っている。

#### LXDコンテナを利用した動作確認用のデプロイ

[Using LXD-hosts] によると、LXDコンテナを使用し動作確認用のX-Road環境を構築できる。
`ansible/hosts/lxd_hosts.txt` がインベントリファイル（の例）である。
中で定義されているコンテナは、 `ansible/roles/init-lxd` ロールで起動される。

Ubuntu18で試す。

あらかじめLXD環境をセットアップしておく。

```shell
$ sudo apt-get install lxd
$ newgrp lxd
$ sudo lxd init
```

特に問題なければLXDコンテナが起動できるはず。詳しくは、 https://linuxcontainers.org/ja/lxd/getting-started-cli あたりを参照。

Ansibleもインストールしておく。

```shell
$ sudo apt update
$ sudo apt install software-properties-common
$ sudo apt-add-repository --yes --update ppa:ansible/ansible
$ sudo apt install ansible
```

詳しくは、 https://docs.ansible.com/ansible/2.9_ja/installation_guide/intro_installation.html#ubuntu-ansible あたりを参照。

X-Roadのコンテナを準備する。

```shell
$ ansible-playbook  -i hosts/lxd_hosts.txt xroad_init.yml
```

実際に以下のようなコンテナが立ち上がる。

```
$ lxc list
+---------------+---------+-----------------------+-----------------------------------------------+------------+-----------+
|     NAME      |  STATE  |         IPV4          |                     IPV6                      |    TYPE    | SNAPSHOTS |
+---------------+---------+-----------------------+-----------------------------------------------+------------+-----------+
| xroad-lxd-cs  | RUNNING | xx.xx.xx.xx (eth0)    | xxxx:xxxx:xxxx:xxxx:xxx:xxxx:xxxx:xxxx (eth0) | PERSISTENT | 0         |
+---------------+---------+-----------------------+-----------------------------------------------+------------+-----------+
| xroad-lxd-ss1 | RUNNING | xx.xx.xx.xx (eth0)    | xxxx:xxxx:xxxx:xxxx:xxx:xxxx:xxxx:xxxx (eth0) | PERSISTENT | 0         |
+---------------+---------+-----------------------+-----------------------------------------------+------------+-----------+
```

なお、パッケージインストール（内部的にはaptを利用してインストール）している箇所の進みが遅く、一度インタラプトして手動でaptコマンドでインストールした。


#### 開発用のプレイブック

開発用のAnsibleプレイブックもある。
`ansible/xroad_dev.yml` や `ansible/xroad_dev_partial.yml` である。

### 起動した環境の動作確認

[X Road Academy Session 1 Setting up a local X-Road development environment]が参考になりそう。

## コンポーネントの確認

### Security Server

[X-Road Security Server Architecture] にSecurity Serverのアーキテクチャが記載されている。
特に [X-Road Security Server Architecture Overview] に記載されている図が分かりやすい。

Security Serverはサービスクライアントとプロバイダの仲介を担う。
電子署名と暗号を用いてメッセージのやり取りは保護される。

Proxyがメッセージを受けとるのだが、メッセージは署名と一緒に保存される。

設定情報はPostgreSQL内に保持される。
設定はユーザインターフェースを通じて行われるようになっている。

グローバルコンフィグレーションをダウンロードするConfiguration Client というのもあるようだ。

そのほかのコンポーネントは名称の通りの機能である。

[X-Road Security Server Architecture Process View] に処理の流れが記載されている。

<!-- vim: set et tw=0 ts=2 sw=2: -->
