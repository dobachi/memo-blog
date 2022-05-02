---

title: Minio getting started
date: 2021-06-13 22:01:12
categories:
  - Knowledge Management
  - Storage Layer
  - Minio
tags:
  - Minio
  - Storage
  - S3

---

# 参考


## 公式

* [Minioの公式ウェブサイト] 
* [Minioのクライアントガイド]
* [Minioのアドミンガイド]
* [Minioのコンフィグガイド]
* [boto3 を用いて MinIO でユーザの追加と Security Token Service(STS) による一時認証情報での署名済み URL を発行する]
* [mc alias]
* [mc admin policy]
* [mc admin userを利用したユーザ作成]

[Minioの公式ウェブサイト]: https://docs.min.io/
[Minioのクライアントガイド]: https://docs.min.io/docs/minio-client-quickstart-guide
[Minioのアドミンガイド]: https://docs.min.io/docs/minio-admin-complete-guide.html
[Minioのコンフィグガイド]: https://docs.min.io/docs/minio-server-configuration-guide.html
[boto3 を用いて MinIO でユーザの追加と Security Token Service(STS) による一時認証情報での署名済み URL を発行する]: https://qiita.com/y_k/items/9c134f7be0263d64a89b
[mc alias]: https://docs.min.io/minio/baremetal/reference/minio-cli/minio-mc/mc-alias.html#mc-alias
[mc admin policy]: https://docs.min.io/minio/baremetal/reference/minio-cli/minio-mc-admin/mc-admin-policy.html
[mc admin userを利用したユーザ作成]: https://docs.min.io/minio/baremetal/reference/minio-cli/minio-mc-admin/mc-admin-user.html#create-a-new-user

## ブログ

* [MinIO オブジェクトストレージの構築]
* [開発のためにローカルにもS3が欲しいというわがまま、MINIOが叶えてくれました]

[MinIO オブジェクトストレージの構築]: https://qiita.com/Taroi_Japanista/items/7139ae983b5db2404cdb
[開発のためにローカルにもS3が欲しいというわがまま、MINIOが叶えてくれました]: https://liginc.co.jp/402383

# メモ

S3互換の仕組みを導入したく、検索してヒットしたので試した。

## 動作確認

### 前提

```shell
$ cat /etc/redhat-release
CentOS Linux release 7.9.2009 (Core)
```

### サーバ起動

[Minioの公式ウェブサイト] を確認し、


```shell
$ mkdir ~/Minio
$ cd ~/Minio
$ wget https://dl.min.io/server/minio/release/linux-amd64/minio
$ chmod +x minio
$ mkdir data
$ ./minio server data
```

http://localhost:9000/minio/ にアクセスすると、ログイン画面が出るので、
デフォルトのID、パスワードを入力する。

### コンフィグ

[Minioのコンフィグガイド] を見ると、アドミンユーザとパスワードの設定方法が載っていた。

```shell
$ export MINIO_ROOT_USER=minio
$ export MINIO_ROOT_PASSWORD=miniominio
$ ./minio server data
```

上記のようにすればよさそうである。なお、USERは3文字以上、PASSWORDは8文字以上が必要。
ここでは、ローカル環境用にお試し用のID、パスワードとした。

### mcコマンドの利用

[Minioのアドミンガイド]と[Minioのクライアントガイド] を参考に、いくつか動作確認、設定してみる。

```shell
$ cd ~/Minio
$ wget https://dl.min.io/client/mc/release/linux-amd64/mc
```

エイリアスを設定。

```shell
$ ./mc alias set myminio http://172.24.88.24:9000 minio miniominio
```

情報を確認。

```shell
$ ./mc admin info myminio
●  172.24.88.24:9000
   Uptime: 6 minutes
   Version: 2021-06-09T18:51:39Z
   Network: 1/1 OK
```

バケットを作成

```shell
$ ./mc mb myminio/test
Bucket created successfully `myminio/test`.
```

ファイルを書き込み

```shell
$ echo test > /tmp/test.txt
$ ./mc cp /tmp/test.txt myminio/test/
/tmp/test.txt:              5 B / 5 B ┃┃ 224 B/s 0s
```

### s3コマンドで利用

[開発のためにローカルにもS3が欲しいというわがまま、MINIOが叶えてくれました] を参照し、
S3としてアクセスしてみる。

```shell
$ aws --profile myminio configure
AWS Access Key ID [None]: minio
AWS Secret Access Key [None]: miniominio
Default region name [None]:
Default output format [None]:
$ aws --endpoint-url http://127.0.0.1:9000 --profile myminio s3 mb s3://test2
```

上記のように、エンドポイントを指定して利用する。

```shell
$ aws --endpoint-url http://127.0.0.1:9000 --profile myminio s3 cp /tmp/test.txt s3://test2
upload: ../../../tmp/test.txt to s3://test2/test.txt
```

## アップデート

以下のメッセージが出たので、試しにアップデートしてみた。

```
You are running an older version of MinIO released 2 months ago
Update: Run `mc admin update`
```

まず、Minioのサーバを起動しておく。

```shell
$ ./minio server data
```

この後別のターミナルを開き、エイリアすを設定しておく。

```shell
$ ./mc alias set myminio http://172.24.32.250:9000 minioadmin minioadmin
```

アップデート実行

```shell
$ ./mc admin update myminio
Server `myminio` updated successfully from 2021-06-09T18:51:39Z to 2021-08-25T00-41-18Z
```

## 署名済みURL発行

[boto3 を用いて MinIO でユーザの追加と Security Token Service(STS) による一時認証情報での署名済み URL を発行する] を参考に、
上記環境で署名済みURLを発行してみる。
これにより、あるオブジェクトへのアクセス権をデリゲート可能になるはずである。

### S3互換サービスのためのエイリアス

前述の通り、 [mc alias] を利用して、S3互換サービスのためのエイリアスを作成済みである。
ここでは、その作成した `myminio` を利用する。

### 作業用バケット作成

今回の動作確認で使用するバケットを作成する。

```shell
$ ./mc mb myminio/share
```

### ポリシーファイルの作成

以下のファイルを作成する。

share.json

```shell
$ cat << EOF > share.json
> {
>   "Version": "2012-10-17",
>   "Statement": [
>     {
>       "Action": [
>         "s3:GetObject",
>         "s3:PutObject"
>       ],
>       "Effect": "Allow",
>       "Resource": [
>         "arn:aws:s3:::share/*"
>       ],
>       "Sid": ""
>     }
>   ]
> }
> EOF
```

### ポリシーを適用

[mc admin policy] の通り、AWSのIAM互換のポリシーを利用し、Minioのポリシーを設定する。
先程作成したファイルを用いる。

```shell
$ ./mc admin policy add myminio share share.json
```

適用されたことを確かめる

```shell
$ ./mc admin policy info  myminio share
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Action": [
    "s3:GetObject",
    "s3:PutObject"
   ],
   "Resource": [
    "arn:aws:s3:::share/*"
   ]
  }
 ]
}
```

### ユーザ作成

[mc admin userを利用したユーザ作成] を利用して、
動作確認のためのユーザを作成する。

```shell
$ ./mc admin user add myminio bob bob123456
```

なお、上記ドキュメントでは

> mc admin user add ALIAS ACCESSKEY SECRETKEY

と記載されているが、`ACCESSKEY` にしていた内容がユーザ名になるようだ。

### ユーザにポリシーを設定

```shell
$ ./mc admin policy set myminio share user=bob
```

ユーザ作成され、ポリシーが設定されたことを確かめる。

```shell
$ ./mc admin user list myminio
enabled    bob                   share
```

### 共有の動作確認用のファイルの準備

手元でファイルを作り、Minio上にアップロードしておく。

```shell
$ echo "hoge" > test.txt
$ ./mc cp test.txt myminio/share/test.txt
```

### Python botoを利用して一時アカウント発行＆署名済みURL発行

#### ウェブUIからの発行

実は、ウェブUIからも発行できるため、先にそちらを試した。

![ウェブUIからの署名済みURL発行の例](memo-blog/images/minio_presigned_url_via_gui.png)

オブジェクトブラウザから辿りオブジェクトのページを開き、共有マークを押下すると発行できた。
実際にアクセスしたところ、ファイル本体にアクセスできた。

#### 前提

- Pythonバージョン: 3.7.10
- 利用パッケージ: boto3、jupyter

#### ソースコードの例

https://github.com/dobachi/MinioPresignedURLExample にサンプルを載せておくことにする。
こちらの手順で特に問題なく、発行できた。

#### （トラブルシュート）署名済みURLにアクセスしてみたらエラー

署名済みURLを発行してアクセスしてみたら、以下のようなエラーが生じた。

```
<Error>
<Code>AccessDenied</Code>
<Message>Access Denied.</Message>
<Key>test.txt</Key>
<BucketName>share</BucketName>
<Resource>/share/test.txt</Resource>
<RequestId>16A34CDD784CBCCC</RequestId>
<HostId>baec9ee7-bfb0-441b-a70a-493bfd80d745</HostId>
</Error>
```

ひとまず、`./mc admin trace`を利用してデバッグメッセージを確認しながらアクセスしてみる。
生じたエラーメッセージは以下の通り。

```
172.24.32.250:9000 [REQUEST s3.GetObject] [2021-09-10T00:34:26:000] [Client IP: 172.24.32.1]
172.24.32.250:9000 GET /share/test.txt?xxxxxxxx
172.24.32.250:9000 Proto: HTTP/1.1
172.24.32.250:9000 Host: 172.24.32.250:9000
172.24.32.250:9000 Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9
172.24.32.250:9000 Accept-Encoding: gzip, deflate
172.24.32.250:9000 Cache-Control: max-age=0
172.24.32.250:9000 Content-Length: 0
172.24.32.250:9000 Dnt: 1
172.24.32.250:9000 Upgrade-Insecure-Requests: 1
172.24.32.250:9000 Accept-Language: ja,en;q=0.9,en-GB;q=0.8,en-US;q=0.7
172.24.32.250:9000 Connection: keep-alive
172.24.32.250:9000 Cookie: token=xxxxxxxxx
172.24.32.250:9000 User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36 Edg/92.0.902.84
172.24.32.250:9000 <BODY>
172.24.32.250:9000 [RESPONSE] [2021-09-10T00:34:26:000] [ Duration 387µs  ↑ 132 B  ↓ 617 B ]
172.24.32.250:9000 403 Forbidden
172.24.32.250:9000 Accept-Ranges: bytes
172.24.32.250:9000 Content-Length: 294
172.24.32.250:9000 Server: MinIO
172.24.32.250:9000 X-Content-Type-Options: nosniff
172.24.32.250:9000 X-Amz-Request-Id: 16A34EBDA67B7B88
172.24.32.250:9000 X-Xss-Protection: 1; mode=block
172.24.32.250:9000 Content-Security-Policy: block-all-mixed-content
172.24.32.250:9000 Content-Type: application/xml
172.24.32.250:9000 Strict-Transport-Security: max-age=31536000; includeSubDomains
172.24.32.250:9000 Vary: Origin
172.24.32.250:9000 <?xml version="1.0" encoding="UTF-8"?>
<Error><Code>AccessDenied</Code><Message>Request has expired</Message><Key>test.txt</Key><BucketName>share</BucketName><Resource>/share/test.txt</Resource><RequestId>16A34EBDA67B7B88</RequestId><HostId>baec9ee7-bfb0-441b-a70a-493bfd80d745</HostId></Error>
172.24.32.250:9000
172.24.32.250:9000 [REQUEST s3.ListObjectsV1] [2021-09-10T00:34:26:000] [Client IP: 172.24.32.1]
172.24.32.250:9000 GET /favicon.ico
172.24.32.250:9000 Proto: HTTP/1.1
172.24.32.250:9000 Host: 172.24.32.250:9000
172.24.32.250:9000 Accept: image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8
172.24.32.250:9000 Cache-Control: no-cache
172.24.32.250:9000 Connection: keep-alive
172.24.32.250:9000 Cookie: token=xxxxxxxxxxxxxxxxxxx
172.24.32.250:9000 User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36 Edg/92.0.902.84
172.24.32.250:9000 Accept-Encoding: gzip, deflate
172.24.32.250:9000 Accept-Language: ja,en;q=0.9,en-GB;q=0.8,en-US;q=0.7
172.24.32.250:9000 Content-Length: 0
172.24.32.250:9000 Dnt: 1
172.24.32.250:9000 Pragma: no-cache
172.24.32.250:9000 Referer: http://172.24.32.250:9000/share/test.txt?xxxxxxxxxxxxxx
172.24.32.250:9000
172.24.32.250:9000 [RESPONSE] [2021-09-10T00:34:26:000] [ Duration 184µs  ↑ 121 B  ↓ 596 B ]
172.24.32.250:9000 403 Forbidden
172.24.32.250:9000 X-Xss-Protection: 1; mode=block
172.24.32.250:9000 Content-Length: 273
172.24.32.250:9000 Content-Type: application/xml
172.24.32.250:9000 Strict-Transport-Security: max-age=31536000; includeSubDomains
172.24.32.250:9000 X-Amz-Request-Id: 16A34EBDAA2A2630
172.24.32.250:9000 X-Content-Type-Options: nosniff
172.24.32.250:9000 Accept-Ranges: bytes
172.24.32.250:9000 Content-Security-Policy: block-all-mixed-content
172.24.32.250:9000 Server: MinIO
172.24.32.250:9000 Vary: OriginAccept-Encoding
172.24.32.250:9000 <?xml version="1.0" encoding="UTF-8"?>
<Error><Code>AccessDenied</Code><Message>Access Denied.</Message><BucketName>favicon.ico</BucketName><Resource>/favicon.ico</Resource><RequestId>16A34EBDAA2A2630</RequestId><HostId>baec9ee7-bfb0-441b-a70a-493bfd80d745</HostId></Error>
172.24.32.250:9000
```

あまり追加情報はなさそう。ひとまず、いずれにせよ403 Forbidenエラーであることがわかる。

で、結論としては、PythonでURLを発行する際に指定したポリシが間違っていた。

以下のようにすべきところを、

```json
      "Resource": [
        "arn:aws:s3:::share/*"
      ],
```

以下のように `*` が抜けていた。

```json
      "Resource": [
        "arn:aws:s3:::share/"
      ],
```

結果として指定するスコープが小さすぎたということか。

<!-- vim: set et tw=0 ts=2 sw=2: -->
