---

title: EclipseDataspaceConnector
date: 2022-08-05 12:48:40
categories:
  - Knowledge Management
  - Dataspace Connector
  - Eclipse Dataspace Connector
tags:
  - Dataspace Connector
  - IDS

---

# メモ

## Getting Started

[公式GitHub] に記載がある。 [Run Your First Connector] あたり。

ランチャーで起動する設計になっている。ただし、

> It is expected that everyone who wants to use the EDC will create their own launcher, customized to the implemented use cases.

とある通り、基本的にはユースケースごとにランチャーを自作することが推奨されている。

### 起動条件

[IDS Connector Launcher] に説明あり。

DAPSに接続できること、そこから得られたCertificationを利用できること。

### ローカルDAPS起動

基本的には、オフィシャルな公開DAPSを利用できないだろう、という想定で、ローカルDAPSを立ち上げる。
[Setting up a local DAPS instance] に手順がある。

[omejdn-daps] のレポジトリからクローンする。この時、サブモジュールがあるので気を付ける。

```shell
$ mkdir -p ~/Sources
$ cd ~/Sources
$ git clone --recursive https://github.com/International-Data-Spaces-Association/omejdn-daps.git
```

つづいて、環境変数の修正だが、ローカルホストで実行する限りは変更必要ない。

> Modify .env in the project root: set DAPS_DOMAIN to the URL your DAPS instance will be running at.

コネクタを登録しろ、と書かれているので含まれているスクリプトを実行する。
引数にクライアント名？を与えるようなので、とりあえず `localhost` とした。
（今回は動作確認のため、ローカルホストから接続するコネクタをクライアントとして登録するイメージ）

```
$ ./scripts/register_connector.sh localhost
```







# 参考

* [公式GitHub]
* [Run Your First Connector]
* [IDS Connector Launcher]
* [Setting up a local DAPS instance]
* [omejdn-daps]
* [Omejdn]

[公式GitHub]: https://github.com/eclipse-dataspaceconnector/DataSpaceConnector
[Run Your First Connector]: https://github.com/eclipse-dataspaceconnector/DataSpaceConnector#run-your-first-connector
[IDS Connector Launcher]: https://github.com/eclipse-dataspaceconnector/DataSpaceConnector/blob/main/launchers/ids-connector/README.md
[Setting up a local DAPS instance]: https://github.com/eclipse-dataspaceconnector/DataSpaceConnector/blob/main/launchers/ids-connector/README.md#setting-up-a-local-daps-instance
[omejdn-daps]: https://github.com/International-Data-Spaces-Association/omejdn-daps
[Omejdn]: https://github.com/International-Data-Spaces-Association/omejdn-daps



<!-- vim: set et tw=0 ts=2 sw=2: -->
