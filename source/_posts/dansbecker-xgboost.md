---

title: dansbecker/xgboost
date: 2019-04-12 21:48:11
categories:
  - Knowledge Management
  - Machine Learning
  - Model
  - XGBoost
tags:
  - Machine Learning
  - Kaggle
  - Model
  - XGBoost

---

# 参考

* [Kaggleのdansbecker xgboost]
* [XGBoostの主な特徴と理論の概要]
* [XGBoostの概要]
  * この説明がわかりやすい

[Kaggleのdansbecker xgboost]: https://www.kaggle.com/dansbecker/xgboost
[XGBoostの主な特徴と理論の概要]: https://qiita.com/yh0sh/items/1df89b12a8dcd15bd5aa
[XGBoostの概要]: http://kefism.hatenablog.com/entry/2017/06/11/182959


# メモ

XGBoost自体については、[XGBoostの概要]がわかりやすい。

## チューニングパラメータ


* `n_estimators`
  * 大きさは100〜1000の間の値を用いることが多い
* `early_stopping_rounds`
  * `n_estimators` を大きめにしておいて、本パラメータで学習を止めるのが良さそう
* `learning_rate`
  * 加減しながら・・・。例では0.05あたりを使っていた。
* `n_jobs`
  * 並列処理（コア数の指定）
