---
title: Stopword with Python
date: 2019-04-06 21:47:58
categories:
  - Knowledge Management
  - Data Engineering
  - Data Transformation
tags:
  - nltk
  - Data Transformation
  - Python
---

# 参考

* [Kaggleのデータからbag of wordsを作ってみた]
* [nltkでstopwordsの設定]

[Kaggleのデータからbag of wordsを作ってみた]: https://qiita.com/nana1212/items/1eaadca32349a1314cb4
[nltkでstopwordsの設定]: http://blog.livedoor.jp/oyajieng_memo/archives/2577889.html

# メモ

今回はConda環境だったので、 `conda` コマンドでインストールした。

```
$ conda install nltk
```

ストップワードをダウンロードする。

```
import nltk
nltk.download("stopwords")
```

ここでは、仮に対象となる単語のリスト`all_words`があったとする。
そのとき、以下のようにリストからストップワードを取り除くと良い。

```
symbol = ["'", '"', ':', ';', '.', ',', '-', '!', '?', "'s"]
words_wo_stopwords = [w.lower() for w in all_words if not w in stop_words + symbol]
```

ストップワードの中には記号が含まれていないので、ここでは、`symbol`を定義して一緒に取り除いた。
次に頻度の高い単語を30件抽出してみる。

```
clean_frequency = nltk.FreqDist(words_wo_stopwords)
```

これを可視化する。

```
plt.figure(figsize=(10, 7))
clean_frequency.plot(30,cumulative=True)
```
