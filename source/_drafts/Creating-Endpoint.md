---
title: Creating Endpoint
date: 2021-02-27 23:26:19
categories:
tags:
---

# 参考

## AWS API Gateway

* [Amazon API Gateway の特徴]

[Amazon API Gateway の特徴]: https://aws.amazon.com/jp/api-gateway/features/

## AWS S3 エンドポイント

* [Amazon S3 におけるエンドポイント]

[Amazon S3 におけるエンドポイント]: https://docs.aws.amazon.com/ja_jp/vpc/latest/userguide/vpc-endpoints-s3.html


# メモ

## ここでいうエンドポイントとは？

何かしらのデータを取り扱うサービス、システムをユーザがセルフサービスで利用するためのアクセスポイントとする。

## エンドポイントに求められる特徴は？

* 個別のエンドポイント作成がセルフサービス化されている
* 複数のプロトコル、バックエンドに対応
* 認証・認可

## パブリッククラウド関連

### AWS API Gateway

[Amazon API Gateway の特徴] の通り、RESTful APIとWebSocket APIを提供。

## AWS S3 エンドポイント

[Amazon S3 におけるエンドポイント] の通り、以下の特徴を持つ。

* エンドポイントの使用の管理
  * ポリシーベースの管理
* ネットワークコネクティビティ

<!-- vim: set et tw=0 ts=2 sw=2: -->
