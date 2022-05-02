---

title: Recent hot activities of Delta Sharing
date: 2021-08-27 09:22:38
categories:
  - Knowledge Management
  - Data Collaboration
  - Delta Sharing
tags:
  - Delta Sharing
  - Delta Lake

---

# 参考

* [Delta Sharing公式GitHub]
* [Delta Sharing Protocal]
* [delta-sharing-server.yaml.template]
* [Concept]
* [Metadata]

[Delta Sharing公式GitHub]: https://github.com/delta-io/delta-sharing
[Delta Sharing Protocal]: https://github.com/delta-io/delta-sharing/blob/main/PROTOCOL.md
[delta-sharing-server.yaml.template]: https://github.com/delta-io/delta-sharing/blob/main/server/src/universal/conf/delta-sharing-server.yaml.template
[Concept]: https://github.com/delta-io/delta-sharing/blob/main/PROTOCOL.md#concepts
[Metadata]: https://github.com/delta-io/delta-sharing/blob/main/PROTOCOL.md#metadata

* [Support writing to Delta Shares #33]
* [Add pre-signed URL request logging to server]
* [Support Azure Storage in Delta Sharing Server]
* [Delegate access with a shared access signature]
* [Support Google Cloud Storage in Delta Sharing Server]
* [署名付きURL]

[Support writing to Delta Shares #33]: https://github.com/delta-io/delta-sharing/issues/33
[Add pre-signed URL request logging to server]: https://github.com/delta-io/delta-sharing/issues/39
[Support Azure Storage in Delta Sharing Server]: https://github.com/delta-io/delta-sharing/issues/21
[Delegate access with a shared access signature]: https://docs.microsoft.com/en-us/rest/api/storageservices/delegate-access-with-shared-access-signature
[Support Google Cloud Storage in Delta Sharing Server]: https://github.com/delta-io/delta-sharing/issues/20
[署名付きURL]: https://cloud.google.com/storage/docs/access-control/signed-urls

# メモ

## いま何がどのくらいできるようになっているのか？

2021/9時点で何ができるのか？
[Delta Sharing公式GitHub] のREADMEによると以下の通り。

### クライアント、開発言語バインディング

* SQL（Spark SQL）
* Python
* Scala
* Java
* R

### サーバの参考実装

[Delta Sharing Protocal] に乗っ取ってデータ共有の動作確認が可能な
参考実装が公開されている。

ただし、この実装にはセキュリティ周りの機能が十分に実装されておらず、
もし公開して利用する場合はプロキシの裏側で使うことが推奨されている。

サーバを立ち上げるときに共有するデータの定義を渡せる。
[delta-sharing-server.yaml.template] にコンフィグのサンプルが載っている。

[Concept] にデータモデル、主要なコンポーネントが載っている。

* Share（シェア）:
  * 共有の論理的なグループ
  * このグループに含まれるものが受信者に共有される。
* Schema（スキーマ）:
  * 複数のTableを含む
* Table（テーブル）:
  * Delta Lakeのテーブルもしくはビュー
* Recipient（受信者）:
  * シェアにアクセス可能なBearerトークンをもつもの
* Sharing Server（共有サーバ）:
  * プロトコルを実装したサーバ


### プロトコル

[Delta Sharing Protocal] に載っている通り、
Delta Sharingのサーバとクライアントの間のプロトコルが規定されている。

* シェアをリスト
* シェア内のスキーマをリスト
* スキーマ内のテーブルをリスト
* テーブルのバージョン情報取得
  * おそらくDelta Lakeとしてのバージョン情報
* テーブルのメタデータ取得
* データ取得
  * データ取得時には、PredicateHint、LimitHintを渡せる

### テーブルメタデータ

[Metadata] にテーブルに付帯できるメタデータの定義が載っている。
スキーマやフォーマットなどの情報に加え、任意の説明を保持できるようだ。

## Support writing to Delta Shares

[Support writing to Delta Shares #33]

書き込みへの対応について提案がなされたが、2021/8/27現在は保留となっている。
いったん読み込みに注力、とのこと。

なお、Treasure DataのTaroさんがTreasure Dataにおける対応例を紹介している。
（が、それに対する応答はない）

## Add pre-signed URL request logging to server

[Add pre-signed URL request logging to server]

今のところ、プリサインドURLの件数を知る術がない。
そこで、DEBUGログにプリサインドURLの発行情報を出力するのはどうか、というチケットが挙がっていた。

## Support Azure Storage in Delta Sharing Server

[Support Azure Storage in Delta Sharing Server]

Azureでは、 [Delegate access with a shared access signature] の機能が提供されているので、割と対応しやすいのでは？という議論になっている。
AzureのSASは、定められたパーミッションで定められた期間だけリソースにアクセス可能にする。

なお、SASにはアカウントレベル、サービスレベル、ユーザデリゲーションの3種類がある。
それぞれスコープやできることが異なる。

Delta Sharingがストレージに特化しているのであれば、まずはBlobに対するデリゲーションURLを発行できれば良さそうである。

## Support Google Cloud Storage in Delta Sharing Server

[Support Google Cloud Storage in Delta Sharing Server]

Azureと同じく、 [署名付きURL] に対応しているため、そこまで難しくは無いだろう、というコメントがあった。

これはどうだろうか？

<!-- vim: set et tw=0 ts=2 sw=2: -->
