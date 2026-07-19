---

title: Nature Remo API
date: 2019-01-18 22:27:20
categories:
  - Home server
  - Nature Remo
tags:
  - Nature Remo
  - Smart Home

---

# 参考
* [Nature Remo APIガイド]
* [ローカルAPI] 
* [グローバルAPI]
* [API解説のブログ]
* [Nature Remo で温度超過時にアラート通知をする]
* [NatureRemoのAPIを活用する準備]
* [curl to python]

[Nature Remo APIガイド]: https://developer.nature.global/
[ローカルAPI]: http://local.swagger.nature.global/
[グローバルAPI]: http://swagger.nature.global/
[API解説のブログ]: https://qiita.com/sohsatoh/items/b710ab3fa05e77ab2b0a
[home.nature.global]: https://home.nature.global/
[Nature Remo で温度超過時にアラート通知をする]: https://qiita.com/magaming/items/47739e13aec22fea60f4
[NatureRemoのAPIを活用する準備]: https://qiita.com/onm/items/8462b5b792132f42336d
[curl to python]: https://curl.trillworks.com/

# ブログもとに試す

[API解説のブログ]を参考に試してみる。

[home.nature.global] につなぎ、アクセストークンを発行する。
なお、アクセストークンは決して漏らしてはならない。
ここではローカルファイルシステムに`na.txt`として保存して利用することにする。

```
$ curl -X GET "https://api.nature.global/1/devices" -H "accept: application/json" -k --header "Authorization: Bearer `cat na.txt`" | jq
[
  {
    "name": "リビング",
    "id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "created_at": "xxxxxxxxxxxxxxxxxxxx",
    "updated_at": "xxxxxxxxxxxxxxxxxxxx",
    "mac_address": "xxxxxxxxxxxxxxxxxx",
    "serial_number": "xxxxxxxxxxxxxxxxxxxxx",
    "firmware_version": "Remo/1.0.62-gabbf5bd",
    "temperature_offset": 0,
    "humidity_offset": 0,
    "users": [
      {
        "id": "xxxxxxxxxxxxxxxxxxxxxxx",
        "nickname": "xxxxxxxxxxxxxxxxxxx",
        "superuser": xxxxxx
      }
    ],
    "newest_events": {
      "hu": {
        "val": 20,
        "created_at": "xxxxxxxxxxxxxxx"
      },
      "il": {
        "val": 104.4,
        "created_at": "xxxxxxxxxxxxxxxxxx"
      },
      "te": {
        "val": 22.2,
        "created_at": "xxxxxxxxxxxxxxxxxxxxxx"
      }
    }
  }
]
```

```
$ curl -X GET "https://api.nature.global/1/appliances" -H "accept: application/json" -k --header "Authorization: Bearer `cat na.txt`" | jq
```

## センサーの値を取り出してみる

[Nature Remo で温度超過時にアラート通知をする] を参考に試す。
先の例と同様に、/1/devicesを叩くと、その戻りの中にセンサーの値が含まれているようだ。
そこでjqコマンドを使って取り出す。

```
$ curl -X GET "https://api.nature.global/1/devices" -H "accept: application/json" -k --header "Authorization: Bearer `cat na.txt`" | jq '.[].newest_events'
```

結果の例

```
{
  "hu": {
    "val": 20,
    "created_at": "2019-01-18T15:01:43Z"
  },
  "il": {
    "val": 104.4,
    "created_at": "2019-01-18T13:26:58Z"
  },
  "te": {
    "val": 21,
    "created_at": "2019-01-18T14:24:23Z"
  }
}
```

これを保存しておけばよさそう。

## Python化

[curl to python] のサイトを利用し、上記curlをPythonスクリプトに変換した。

# ローカルAPIを試してみる

Remoを探すため、公式サイトでは以下のように示されていた。

```
% dns-sd -B _remo._tcp
```

代わりに以下のコマンドで確認した。

```
dobachi@home:~$ avahi-browse _remo._tcp
+ xxxxx IPv4 Remo-xxxxxx                                   _remo._tcp           local
```
