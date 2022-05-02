---
title: UbuntuでビデオDVDを作る
date: 2018-10-13 23:42:59
categories:
  - Home server
  - Video processing
tags:
  - Ubuntu
---

# 試したもの

* Brasero
* Devede NG
* DVDStyler ... これで作ったら再生してくれた

## BraseroとDevede NGについて

試したものの、リージョンマスクの問題でDVDプレイヤで表示できなかった。
リージョンマスクがゼロ、つまりすべてのリージョンで使えるような設定のようだったが…。

## DVDドライブのリージョンコード確認

regionsetコマンドを用いれば良い。

## DVDメディアのリージョンコード確認

vlcをコマンドラインから起動し、DVDを開くとコンソールに表示される。

## DVDStylerインストール

[ubuntuhandbookのインストールページ] を参考にインストールした。
サードパーティのPPAを加えないとならない部分が気がかりではある。

[ubuntuhandbookのインストールページ]: http://ubuntuhandbook.org/index.php/2017/11/dvdstyler-3-0-4-released-how-to-install-it-in-ubuntu/

# 動画の編集

動画の編集には、Shotcutが用いられそうだった。


