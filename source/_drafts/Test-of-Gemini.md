---

title: Test of Gemini
date: 2024-07-25 09:23:04
categories:
  - Knowledge Management
  - GenAI
  - Gemini
tags:
  - Gemini
  - GenAI

---

# メモ

[【開発】StreamlitでGeminiを使用したアバター音声対話＆VQAアプリ作ってみた] を参考に、GoogleのGeminiを試す。

## APIキーの取得

[Googleのapikey] から任意のGoogleアカウントでログインしたうえでAPIキーを取得する。

## Gemini Pythonクライアントのインストール

テスト用のディレクトリを作り、仮想環境を作成し、pipでクライアントライブラリをインストールする。

```shell
mkdir ~/Sources/gemini_test
cd ~/Sources/gemini_test
python3 -m venv venv
. venv/bin/activate
pip install google-generativeai
```

テスト用にJupyterをインストールする。

```shell
pip install jupyter
```

Jupyter起動。

```shell
jupyter lab --ip 0.0.0.0
```

# 参考

* [【開発】StreamlitでGeminiを使用したアバター音声対話＆VQAアプリ作ってみた]
* [Googleのapikey] 

[【開発】StreamlitでGeminiを使用したアバター音声対話＆VQAアプリ作ってみた]: https://qiita.com/Yuhei0531/items/db894a8fba9c671eb7b0

[Googleのapikey]: https://makersuite.google.com/app/apikey



<!-- vim: set et tw=0 ts=2 sw=2: -->
