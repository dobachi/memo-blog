---

title: Raspberry Pi OSでCapslockをCTRLにする
date: 2025-05-18 22:26:00
tags:
- Raspberry Pi
- Linux
- keyboard

categories:
- Knowledge Management
- Raspberry Pi
- Keyboard

---

## はじめに

Raspberry Pi OSでCapslockキーをCtrlキーとして使用する方法を説明する。

## 環境

- Raspberry Pi OS (64-bit)
- Raspberry Pi 5

## 設定手順

[Raspberry Pi OS(RaspberryPi5)で、CTRLキーとCaps Lockを入れ替える方法 (Swap ctrl and capslock keys)](https://lynmock.hatenablog.com/entry/2024/02/24/014725) を参考にした。本環境では日本語キーボードではなく、USキーボードを使用しているため、設定ファイルが異なる。

`/usr/share/X11/xkb/symbols/us` を編集する。

参考設定の通り、`xkb_symbols "basic"` の中に

```jsx
 key <CAPS> {        [ Control_L                     ]       };
    modifier_map Control { <CAPS> };
```

を追記した。

その後、リブートする。

## 参考リンク

[Raspberry Pi OS(RaspberryPi5)で、CTRLキーとCaps Lockを入れ替える方法 (Swap ctrl and capslock keys)](https://lynmock.hatenablog.com/entry/2024/02/24/014725)





<!-- vim: set et tw=0 ts=2 sw=2: -->
