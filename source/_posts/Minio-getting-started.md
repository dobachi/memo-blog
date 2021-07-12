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

[Minioの公式ウェブサイト]: https://docs.min.io/
[Minioのクライアントガイド]: https://docs.min.io/docs/minio-client-quickstart-guide
[Minioのアドミンガイド]: https://docs.min.io/docs/minio-admin-complete-guide.html
[Minioのコンフィグガイド]: https://docs.min.io/docs/minio-server-configuration-guide.html

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

上記のようにすればよさそうである。なお、USERは3文字異常、PASSWORDは8文字以上が必要。
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






<!-- vim: set et tw=0 ts=2 sw=2: -->
