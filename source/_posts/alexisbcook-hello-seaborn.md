---

title: alexisbcook/hello-seaborn
date: 2019-04-14 22:53:56
categories:
  - Knowledge Management
  - Machine Learning
  - Visualization
  - Seaborn
tags:
  - Machine Learning
  - Kaggle
  - Visualization
  - Seaborn

---


# 参考

* [Kaggleのalexisbcook hello-seaborn]
* [Kaggleのlearn data-visualization]
* [seabornの公式]
* [seabornのギャラリー]
* [seabornのAPI]
* [Hello, Seaborn]
* [Data Visualization: from Non-Coder to Coder]

[Kaggleのalexisbcook hello-seaborn]: https://www.kaggle.com/alexisbcook/hello-seaborn
[Kaggleのlearn data-visualization]: https://www.kaggle.com/learn/data-visualization
[seabornの公式]: https://seaborn.pydata.org/
[seabornのギャラリー]: https://seaborn.pydata.org/examples/index.html
[seabornのAPI]: https://seaborn.pydata.org/api.html
[Hello, Seaborn]: https://www.kaggle.com/kernels/fork/3303713
[Data Visualization: from Non-Coder to Coder]: https://www.kaggle.com/learn/data-visualization-from-non-coder-to-coder

# メモ

[seabornの公式] から、 [seabornのギャラリー] の公式ウェブサイトを見ると、
さまざまな例が載っている。
[seabornのAPI] を見ると、各種APIが載っている。

例えば、[seaborn.barplot](https://seaborn.pydata.org/generated/seaborn.barplot.html#seaborn.barplot)を見ると、
棒グラフの使い方が記載されている。

## 基本的な使い方

基本的には、 

```
import seaborn as sns
```

して、

```
sns.lineplot(data=fifa_data)
```

のように、プロットの種類ごとに定義されたAPIを呼び出すだけ。
もし、グラフの見た目などを変えたいのであれば、matplotlibをインポートし、
設定すれば良い。

```
plt.figure(figsize=(16,6))
```

や、

```
plt.xticks(rotation=90)
```

など。

その他、[Data Visualization: from Non-Coder to Coder]を見ると、
基本的な使い方を理解できるようになっている。
