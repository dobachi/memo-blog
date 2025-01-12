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

なお、以下で実行しているnotebookの内容は、 [dobachi/gemini_test] に格納されている。
Python環境の再現のために、 `requirements.txt` も含まれているので利用されたし。

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

テスト用にJupyter、jpywidgetsをインストールする。

```shell
pip install jupyter ipywidgets
```

Jupyter起動。

```shell
jupyter lab --ip 0.0.0.0
```

# 参考

* [【開発】StreamlitでGeminiを使用したアバター音声対話＆VQAアプリ作ってみた]
* [Googleのapikey] 
* [dobachi/gemini_test]

[【開発】StreamlitでGeminiを使用したアバター音声対話＆VQAアプリ作ってみた]: https://qiita.com/Yuhei0531/items/db894a8fba9c671eb7b0

[Googleのapikey]: https://makersuite.google.com/app/apikey

[dobachi/gemini_test]: https://github.com/dobachi/gemini_test



<!-- vim: set et tw=0 ts=2 sw=2: -->
