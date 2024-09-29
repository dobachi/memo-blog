---

title: Llama3.2
date: 2024-09-29 22:59:17
categories:
  - Knowledge Management
  - AI
  - Llama
tags:
  - AI
  - Llama

---

# メモ

[Llama 3.2 Revolutionizing edge AI and vision with open, customizable models] にある通り、
2024/9/25にLlama3.2がリリースされた。

[Llama公式] の [Llamaダウンロード] からモデルをダウンロードして用いる。

![ダウンロードのための情報登録](/memo-blog/images/20240929_llama32/download.png)

さらに利用規約に合意すると、具体的なダウンロード手順が表示される。

![手順](/memo-blog/images/20240929_llama32/procedures.png)

この手順の中には、リクエストIDやキーなどの情報が含まれているので注意。

もし、Llama CLIをインストールしていなければ以下の通り実行。

```bash
pip install llama-stack
```

モデルのリストを確認する。

```bash
llama model list
```

結果例

```
| Llama3.2-1B                      | meta-llama/Llama-3.2-1B                  | 128K           |
| Llama3.2-3B                      | meta-llama/Llama-3.2-3B                  | 128K           |
| Llama3.2-11B-Vision              | meta-llama/Llama-3.2-11B-Vision          | 128K           |
| Llama3.2-90B-Vision              | meta-llama/Llama-3.2-90B-Vision          | 128K           |
| Llama3.2-1B-Instruct             | meta-llama/Llama-3.2-1B-Instruct         | 128K           |
| Llama3.2-3B-Instruct             | meta-llama/Llama-3.2-3B-Instruct         | 128K           |
| Llama3.2-11B-Vision-Instruct     | meta-llama/Llama-3.2-11B-Vision-Instruct | 128K           |
| Llama3.2-90B-Vision-Instruct     | meta-llama/Llama-3.2-90B-Vision-Instruct | 128K           |
```

モデルをダウンロードして用いる。ここではテストなので小さなモデルを用いる。

```bash
MODEL_ID=Llama3.2-3B
llama model download --source meta --model-id $MODEL_ID
```

上記コマンドを実行すると、キー付きのURL入力を求められる。
先程表示した手順の「4」に記載されたURLを入力する。

このメモを書いている時点では混んでいるのか、ダウンロードにそれなりに時間がかかる。

ダウンロードが完了すると、以下のディレクトリにチェックポイントがダウンロードされているはず。

```
~/.llama/checkpoints/Llama3.2-3B
```

# 参考

* [Llama 3.2 Revolutionizing edge AI and vision with open, customizable models]
* [Llama公式]
* [Llamaダウンロード]

[Llama 3.2 Revolutionizing edge AI and vision with open, customizable models]: https://ai.meta.com/blog/llama-3-2-connect-2024-vision-edge-mobile-devices/
[Llama公式]: https://www.llama.com/
[Llamaダウンロード]: https://www.llama.com/llama-downloads/



<!-- vim: set et tw=0 ts=2 sw=2: -->
