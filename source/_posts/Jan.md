---

title: Jan
date: 2024-09-28 13:14:04
categories:
  - Knowledge Management
  - AI
  - LocalLLM
tags:
  - AI
  - LocalLLM
  - Jan

---

# メモ

[LLMプラットフォームの「JAN」、様々なモデルでチャットAIを作れる] を参考に、
Janを使ってみる。

[Janの公式サイト] に掲載の通り、パッケージをダウンロードする。
ここではUbuntu環境を前提にAppImageを用いる。
このとき最新版だった、 [jan-linux-x86_64-0.5.4.AppImage] をダウンロードした。自分の環境の場合は、 `~/Applications/` 以下にダウンロードした。

実行。

```bash
$ ./Applications/jan-linux-x86_64-0.5.4.AppImage 
```

GUIからひとまず lama3.1-8b-instruct を試すことにした。

続いて、 [LLMプラットフォームの「JAN」、様々なモデルでチャットAIを作れる] の記事でも用いられている、[huggingface]からモデルを探して試す。
Huggingfaceについては、 [Hugging Faceとは？Hugging Face Hubの機能や使い方・ライブラリをわかりやすく解説！] を参照。

記事にはなかった画像生成を試す。
JanではGGUFしか対応していないので、まずは [stable-diffusion-3-medium-GGUF] を試す。



# 参考

* [LLMプラットフォームの「JAN」、様々なモデルでチャットAIを作れる]
* [Janの公式サイト]
* [jan-linux-x86_64-0.5.4.AppImage]
* [huggingface]
* [Hugging Faceとは？Hugging Face Hubの機能や使い方・ライブラリをわかりやすく解説！]
* [stable-diffusion-3-medium-GGUF]

[LLMプラットフォームの「JAN」、様々なモデルでチャットAIを作れる]: https://xtech.nikkei.com/atcl/nxt/column/18/02920/082200002/?i_cid=nbpnxt_reco_atype&utm_source=pocket_shared
[Janの公式サイト]: https://jan.ai/
[jan-linux-x86_64-0.5.4.AppImage]: https://github.com/janhq/jan/releases/download/v0.5.4/jan-linux-x86_64-0.5.4.AppImage
[huggingface]: https://huggingface.co/
[Hugging Faceとは？Hugging Face Hubの機能や使い方・ライブラリをわかりやすく解説！]: https://ai-market.jp/services/hugging-face/
[stable-diffusion-3-medium-GGUF]: https://huggingface.co/second-state/stable-diffusion-3-medium-GGUF



<!-- vim: set et tw=0 ts=2 sw=2: -->
