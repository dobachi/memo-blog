---

title: PubNub
date: 2021-05-06 13:28:14
categories:
  - Knowledge Management
  - BaaS
tags:
  - Messaging System
  - BaaS

---

# 参考

aa

## 公式ドキュメント

* [The PubNub Platform Overview]
* [SDK]
* [PubNubのGitHub]
* [Pythonチュートリアル]
* [Python API]
* [サインアップ]
* [プライシング]
* [Files API for PubNub Python SDK]
* [download-file]
* [send-file]


[The PubNub Platform Overview]: https://www.pubnub.com/docs/
[SDK]: https://www.pubnub.com/docs/sdks
[PubNubのGitHub]: https://github.com/pubnub
[Pythonチュートリアル]: https://www.pubnub.com/docs/quickstarts/python
[Python API]: https://www.pubnub.com/docs/sdks/python
[サインアップ]: https://dashboard.pubnub.com/signup
[プライシング]: https://www.pubnub.com/pricing/
[Files API for PubNub Python SDK]: https://www.pubnub.com/docs/sdks/python/api-reference/files
[download-file]: https://www.pubnub.com/docs/sdks/python/api-reference/files#download-file
[send-file]: https://www.pubnub.com/docs/sdks/python/api-reference/files#send-file

## blog

* [PubNubで5分でリアルタイムWebこと初め]

[PubNubで5分でリアルタイムWebこと初め]: https://qiita.com/n0bisuke/items/36e4b334d17174446df7

## サンプル

* [PubNubExample]

[PubNubExample]: https://github.com/dobachi/PubNubExample



# メモ

## 概要

[The PubNub Platform Overview] によると、

![クイックスタートの一覧](/memo-blog/images/20210506_PubNub_quickstarts.png)

とのこと。
概要にIoTと記載されている通り、小型のデバイス利用も想定されているようだ。
主な用途は「メッセージング」と「シグナリング」。

特徴は以下の通り。

![特徴の一覧](/memo-blog/images/20210506_PubNub_features.png)

サイズの小さなメッセージに限らず、画像、動画、ファイルを対象に含めているのがポイントか。

ユースケースは以下の通り。

![ユースケースの一覧](/memo-blog/images/20210506_PubNub_usecases.png)

これ自体に特筆すべきポイントはない。

[SDK] に記載のある通り、非常に幅広いSDKを提供している。

[PubNubのGitHub] を見る限り、多様なクライアントライブラリがOSSとして公開、開発されているようだ。

## 動作確認

[プライシング] によるとアカウントを作ってお試しする限りでは無料のようだ。
ということで、[Pythonチュートリアル] の通り実行してみる。

このチュートリアルでは、PubSubモデルのメッセージングを試せる。

### アカウント作成

[サインアップ] からアカウント作成。
もろもろ情報入れて登録したら、Demo Keysetが得られた。

### （補足）公式チュートリアルのソースコード

以下のようにクローンできる。

```shell
[dobachi@home Sources]$ git clone git@github.com:pubnub/python-quickstart-platform.git
```

今回はゼロから作ってみるので、これは参考とする。

### プロジェクトディレクトリ作成

適当なところに空ディレクトリを作り、プロジェクトのルートとする。

```shell
[dobachi@home Sources]$ mkdir pubnub_example
[dobachi@home Sources]$ cd pubnub_example/
```

今回は、pyenvを利用してインストールしたPython3.8.10を利用し、venvで環境構築する。

```shell
[dobachi@home pubnub_example]$ pyenv local 3.8.10
[dobachi@home pubnub_example]$ python -m venv venv
[dobachi@home pubnub_example]$ . ./venv/bin/activate
(venv) [dobachi@home pubnub_example]$ pip install 'pubnub>=4.5.1'
```

ここで、[Pythonチュートリアル] に従い、2個の実装pub.py、sub.pyを作成する。
このとき、ソースコードのキーのところに先ほどアカウント作成した際に得られたキーを記載するようにする。

ここから端末を2個立ち上げる。

1個目でサブスクライバーを起動

```shell
(venv) [dobachi@home pubnub_example]$ python sub.py
***************************************************
* Waiting for updates to The Guide about Earth... *
***************************************************
[STATUS: PNConnectedCategory]
connected to channels: ['the_guide', 'the_guide-pnpres']
[PRESENCE: join]
uuid: serverUUID-SUB, channel: the_guide
```

2個目でパブリッシャーを起動

```shell
(venv) [dobachi@home pubnub_example]$ python pub.py
*****************************************
* Submit updates to The Guide for Earth *
*     Enter 42 to exit this process     *
*****************************************
Enter an update for Earth: Harmless
[PUBLISH: sent]
timetoken: 16202911568484264
```

プロンプトが表示されるので、「Harmless」と入力してエンターキーを押下。

サブスクライバーに以下のように表示される。

```
[MESSAGE received]
Earth: Harmless
```

[Pythonチュートリアル] に実装の説明があるが、
基本的には

* サブスクライバーはハンドラの実装のみ
* パブリッシャーは標準入力からメッセージを受け取り、それを送信するのみ

という単純な仕組み。

パブリッシャー側のポイントは、

```python
    envelope = pubnub.publish().channel(CHANNEL).message(the_message).sync()
```

まだ詳しくは分からないが、チャンネルやエントリという概念がありそう。
チャンネルを使うと同報できるのだろうか。

[Python API] あたりを読むと記載ありそう。

### ファイル

[Files API for PubNub Python SDK] を読むと、ファイルを取り扱うAPIがあった。
5MBまでのファイルをアップロードできるようだ。
アプリケーションで画像を取り扱う場合などを想定している様子。

これを簡単に動作確認してみる。
[Pythonチュートリアル] のサンプルコードpub.pyとsub.pyを参考に実装する。
参考実装を [PubNubExample] にまとめておいた。
READMEを参照。

メッセージングのAPIとは異なるが、簡単に小さなファイルを登録できるのは便利ではある。

またファイルを登録したことを通知するAPIもあるようだ。
これは使い方としては

* ファイルを送信し、合わせてファイル送信したことをチャンネルにメッセージ送信
* 受信者は、メッセージを受領したら、その情報を使ってファイル受信

ということだと思われる。
ファイルの送受信自体は、メッセージングのようにSubscribeできず、
単発実行のAPIであり、かつ受信についてはIDを引数に渡さないといけないから、と考えられる。

### （補足）ERROR: Could not find a version that satisfies the requirement pubnub>=4.5.1

以下のようなエラーが出たら、

```
ERROR: Could not find a version that satisfies the requirement pubnub>=4.5.1
```

`libffi-devel` をインストールしたうえで、Pythonをビルドするようにするとよい。

```shell
(venv) [dobachi@home pubnub_example]$ pyenv uninstall 3.8.10
(venv) [dobachi@home pubnub_example]$ sudo yum install -y libffi-devel
(venv) [dobachi@home pubnub_example]$ pyenv install 3.8.10
```


<!-- vim: set et tw=0 ts=2 sw=2: -->
