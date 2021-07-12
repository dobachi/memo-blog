---

title: onedrive for linux
date: 2018-12-11 21:54:02
categories:
  - Home server
  - Ubuntu
  - OneDrive
tags:
  - OneDrive

---

# 参考

* [Ubuntu18での例]
* [公式GitHub]

[Ubuntu18での例]: https://www.virment.com/setup-onedrive-ubuntu18-04/
[公式GitHub]: https://github.com/abraunegg/onedrive

# 手順

インストール
```
$ sudo apt install libcurl4-openssl-dev libsqlite3-dev
$ curl -fsS https://dlang.org/install.sh | bash -s dmd
$ source ~/dlang/dmd-2.083.1/activate
$ cd ~/Sources
$ git clone https://github.com/abraunegg/onedrive.git
$ cd onedrive
$ source ~/dlang/dmd-2.083.1/activate
$ make
$ sudo make install
```


一部同期の設定
```
$ mkdir -p ~/.config/onedrive
$ vim ~/.config/onedrive/sync_list  # 中にディレクトリを並べる
```

（再）同期
```
$ onedrive --synchronize --resync
```

その後、初回同期時はウェブ認証が走るので従う。
白い画面がブラウザで現れたら、そのURLをコピーしてコンソールにペーストし、実行する。

アンインストール
```
$ sudo make uninstall
```
