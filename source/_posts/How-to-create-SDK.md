---

title: How to create SDK (WIP)
date: 2023-08-27 14:11:45
categories:
  - Knowledge Management
  - SDK
tags:
  - SDK

---

# メモ

## 注意

まだ書き始めの殴り書きなので、中身の完成度や信ぴょう性がかなり低い文章である。

## 世の中でSDKと呼ばれているものには何が含まれているのか

* [開発者の強い味方！「SDK（ソフトウェア開発キット）」とは？]
  * KDDIによるブログ記事
  * 「ソフトウェアを開発する際に必要なプログラムやAPI・文書・サンプルなどをまとめてパッケージ化したもの」
* [e-WordsのSDK 【Software Development Kit】 ソフトウェア開発キット]
  * 「SDKとは、あるシステムに対応したソフトウェアを開発するために必要なプログラムや文書などをひとまとめにしたパッケージのこと。システムの開発元や販売元が希望する開発者に配布あるいは販売する。インターネットを通じて公開されているものもある。」
* [AWS SDKとは？]
  * 「特定のプラットフォーム、オペレーティングシステム、またはプログラミング言語で実行されるコードを作成するには、デバッガー、コンパイラー、ライブラリなどのコンポーネントが必要です。SDK は、ソフトウェアの開発と実行に必要なすべてを 1 か所にまとめます。」

製品により異なるのが前提ではあるが、おおむね含まれるとされるのは以下。

* 開発ツール
  * コンパイラ、デバッガ、プロファイラー、デプロイツール、IDE
* 既成のプログラム
  * クラスファイル、（APIなど）ライブラリ、モジュール、ドライバ
* 文書ファイル
  * API、通信プロトコル
* プログラムファイル
  * サンプルプログラム

## SDKの具体例

* Android SDK
  * [Android Developer情報]より
* iOS SDK
  * [Xcode]より
* JDK
  * Javaの開発キット
  * [Java Downloads]より
* DDK
  * Windowsのドライバ開発キット
  * [Windows ハードウェア開発者向けドキュメント]より
* AWS SDK
  * [AWS SDKとは？]より
  * 各言語向けのSDKが存在する

## 工夫点

### 開発ツールの提供形態

1. 開発に必要な環境ごと丸ごと提供する方法、2. 特定のIDEを前提としたプラグインを提供する方法、などがある。

| 方法例         | メリット             | デメリット           | 
| -------------- | -------------------- | -------------------- | 
| 丸ごと提供     | すぐに開発始められる | 自由度が低い         | 
| プラグイン提供 | 自由度が高い         | 環境準備が手間大きめ | 

### ライセンス

SDK自体のライセンスだけではなく、SDKに含まれるライセンスにも注意を払う必要がある。

### 各言語向けのバインディング

サービスを使うためのSDKの場合は、様々な開発言語向けのバインディングを提供することも考慮したい。

## 先人の知恵

[SDK の開発と維持の難しさ] にはAndroidやiOS向けのSDKを開発した際の経緯が書かれていた。




# 参考

## SDKとは？

* [開発者の強い味方！「SDK（ソフトウェア開発キット）」とは？]
* [e-WordsのSDK 【Software Development Kit】 ソフトウェア開発キット]

[開発者の強い味方！「SDK（ソフトウェア開発キット）」とは？]: https://cloudapi.kddi-web.com/magazine/what-is-sdk
[e-WordsのSDK 【Software Development Kit】 ソフトウェア開発キット]: https://e-words.jp/w/SDK.html

## SDKの具体例

* [Android Developer情報]
* [Xcode]
* [Java Downloads]
* [Windows ハードウェア開発者向けドキュメント]
* [AWS SDKとは？]

[Android Developer情報]: https://developer.android.com/?hl=ja
[Xcode]: https://developer.apple.com/jp/xcode/
[Java Downloads]: https://www.oracle.com/jp/java/technologies/downloads/
[Windows ハードウェア開発者向けドキュメント]: https://learn.microsoft.com/ja-jp/windows-hardware/drivers/
[AWS SDKとは？]: https://aws.amazon.com/jp/what-is/sdk/
ばいんでぃば

## 先人の知恵

* [SDK の開発と維持の難しさ]

[SDK の開発と維持の難しさ]: https://voluntas.medium.com/sdk-%E3%81%AE%E9%87%8D%E8%A6%81%E6%80%A7-3e855a4897df




<!-- vim: set et tw=0 ts=2 sw=2: -->
