---

title: dansbecker/partial-dependence-plots
date: 2019-04-13 22:33:24
categories:
  - Knowledge Management
  - Machine Learning
  - Model
  - Partial Dependency Plot
tags:
  - Machine Learning
  - Kaggle
  - Model
  - Partial Dependency Plot

---

# 参考

* [Kaggleのdansbecker partial-dependence-plots]
* [機械学習モデルを解釈する方法 Permutation Importance / Partial Dependence Plot]

[Kaggleのdansbecker partial-dependence-plots]: https://www.kaggle.com/dansbecker/partial-dependence-plots
[機械学習モデルを解釈する方法 Permutation Importance / Partial Dependence Plot]: https://linus-mk.hatenablog.com/entry/2018/10/07/222909


# メモ

## PDPはモデルが学習されたあとに計算可能

ただし、様々なモデルに適用可能。

## PDPの計算方法

以下のような感じ。
```
my_plots = plot_partial_dependence(my_model,       
                                   features=[0, 1, 2], # column numbers of plots we want to show
                                   X=X,            # raw predictors data.
                                   feature_names=['Distance', 'Landsize', 'BuildingArea'], # labels on graphs
                                   grid_resolution=10) # number of values to plot on x axis
```

注意点として挙げられていたのは、`grid_resolution`を細かくしたときに、
乱れたグラフが見られたとしても、その細かな挙動に対して文脈を考えすぎること。
どうしてもランダム性があるので、細かな挙動にいちいち気にしているとミスリードになる。

なお、`partial_dependence`という関数を用いると、グラフを出力するのではなく、数値データそのものを得られる。
```
my_plots2 = partial_dependence(my_model,       
                                   target_variables=[0, 1, 2], # column numbers of plots we want to show
                                   X=X,            # raw predictors data.
                                   grid_resolution=10) # number of values to plot on x axis
```

なお、微妙にオプションが異なることに注意…。

## タイタニックの例

PDPを見ることで、年齢や支払い料金と生存結果の関係を解釈する例が記載されていた。

## 「考察」に関する議論

PDPで得られた結果を考察すること自体について、議論があるようだ。
意味のある・なし、という点において。




