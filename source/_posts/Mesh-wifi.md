---

title: Mesh wifi for Home Network
date: 2021-01-31 22:59:00
categories:
  - Knowledge Management
  - Home Network
tags:
  - WiFi
  - WiFi6
  - IPv6

---

# 参考


## メッシュWiFiルータ

* [メッシュルーターの選び方について整理した]
* [Vol.83 メッシュ（Mesh）Wi-Fiって何？メリットと活用方法を紹介]
* [MR2200ac]

[Vol.83 メッシュ（Mesh）Wi-Fiって何？メリットと活用方法を紹介]: https://www2.elecom.co.jp/network/wireless-lan/column/wifi_column/00083/
[メッシュルーターの選び方について整理した]: https://cero-t.hatenadiary.jp/entry/2019/12/02/212259
[MR2200ac]: https://www.synology.com/en-us/products/MR2200ac

## JPNE v6plus

* [v6プラス(IPv6/IPv4インターネットサービス)]
* [Synology製Wi-FiルーターMR2200acでv6プラス接続設定]

[v6プラス(IPv6/IPv4インターネットサービス)]: https://www.jpne.co.jp/service/v6plus/
[Synology製Wi-FiルーターMR2200acでv6プラス接続設定]: https://oyamadenshi.com/mr2200ac-v6plus/

## So-net

* [So-net 光 with フレッツ S 東日本]
* [So-net 光 プラスの次世代通信 v6プラス]
* [So-net 光 プラス]

[So-net 光 with フレッツ S 東日本]: https://www.so-net.ne.jp/guide/catalog/hikari/withf/e_index.html?page=tab_about
[So-net 光 プラスの次世代通信 v6プラス]: https://www.so-net.ne.jp/access/hikari/v6plus/
[So-net 光 プラスの次世代通信 v6プラスの対象サービス]: https://www.so-net.ne.jp/access/hikari/v6plus/detail.html#anc-3
[So-net 光 プラス]: https://www.so-net.ne.jp/access/hikari/collabo/

## au光

* [auひかりのホームゲートウェイはいらない? 知っておきたい不都合な真実]
* [au光で市販のルーターを使う]
* [ブリッジモードにせずDMZの下でルーターモードで利用するには]

[auひかりのホームゲートウェイはいらない? 知っておきたい不都合な真実]: https://www.lets-hikari.com/auhikari-homegateway/
[au光で市販のルーターを使う]: https://qiita.com/Barisaku/items/1fdb8be1ce4707e3229a
[ブリッジモードにせずDMZの下でルーターモードで利用するには]: https://www.tp-link.com/jp/support/faq/2000/

## 動作確認

* [ipv6 test]

[ipv6 test]: https://ipv6-test.com/speedtest/


# メモ

## メッシュWiFi

メッシュWiFiとは、Elecomの [Vol.83 メッシュ（Mesh）Wi-Fiって何？メリットと活用方法を紹介] 記事の通り。
戸建ての家などでは、広く安定してカバーできるはず、ということで。

日本国内においてどの機器を使うか？については、 [メッシュルーターの選び方について整理した] がわかりやすい。

個人的にはIPv6対応している点で、「Synology MR2200ac」が候補に上がった。
仕様は [MR2200ac] を参照されたし。

## JPNE v6プラス

[v6プラス(IPv6/IPv4インターネットサービス)] によると、


> 「v6プラス」は、NTT東西の次世代ネットワーク（NGN）を利用しインターネット接続を提供するISP事業者が、
> IPv6及びIPv4の設備を持たずに、インターネット接続をお客さま(エンドユーザ)にご提供いただくためのサービスです。

とのこと。

[Synology製Wi-FiルーターMR2200acでv6プラス接続設定] によると、MR2200acでv6plusを利用する方法が記載されている。


## auひかりのHGW（ホームゲートウェイ）

[auひかりのホームゲートウェイはいらない? 知っておきたい不都合な真実] にも記載の通り、

> 先ほどから触れてるとおり、auひかりはホームゲートウェイが無ければインターネットに接続することができません。
> その理由は、ホームゲートウェイ内に、KDDIの認証を取る機能があるからです。

とのこと。

そこで、自前のルータを利用したい場合は、
DMZ機能を利用して、ルータ機能をHGWと自前ルータの療法で動かす設定をすることもある。

[au光で市販のルーターを使う]が参考になる。
[ブリッジモードにせずDMZの下でルーターモードで利用するには] も参考になる。こちらはtp-linkのブログ。

## so-net

[So-net 光 with フレッツ S 東日本] は、フレッツ光の契約と思われる。

[So-net 光 プラスの次世代通信 v6プラス] は v6プラス を利用したサービスと思われる。
[So-net 光 プラスの次世代通信 v6プラスの対象サービス] によると、
[So-net 光 プラス] などが対応している。
その他フレッツ系のサービスが対応しているようだ。


## IPv6の動作確認

[ipv6 test] にアクセスると良い。

<!-- vim: set et tw=0 ts=2 sw=2: -->
