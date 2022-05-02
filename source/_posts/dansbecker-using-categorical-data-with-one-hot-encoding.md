---

title: dansbecker/using-categorical-data-with-one-hot-encoding
date: 2019-04-12 16:10:22
categories:
  - Knowledge Management
  - Machine Learning
  - Preparation
tags:
  - Machine Learning
  - Preparation
  - Kaggle

---

# 参考

* [Kaggleのusing-categorical-data-with-one-hot-encoding]

[Kaggleのusing-categorical-data-with-one-hot-encoding]: https://www.kaggle.com/dansbecker/using-categorical-data-with-one-hot-encoding

# メモ

one hot encodingについて。
Kaggleのラーニングコースを読んでみた。

## カテゴリ値の判定にカージナリティを利用

コメントにもやや恣意的な…と書かれてはいたが、
カージナリティが低く、dtypeが objectであるカラムをカテゴリ値としたようだ。

```
low_cardinality_cols = [cname for cname in candidate_train_predictors.columns if 
                                candidate_train_predictors[cname].nunique() < 10 and
                                candidate_train_predictors[cname].dtype == "object"]
numeric_cols = [cname for cname in candidate_train_predictors.columns if 
                                candidate_train_predictors[cname].dtype in ['int64', 'float64']]
```

## カラムのdtype確認

こんな感じで確かめられる。
```
train_predictors.dtypes.sample(10)
```

結果の例
```
LandContour     object
ScreenPorch      int64
BsmtFinSF2       int64
SaleType        object
BedroomAbvGr     int64
(snip)
```

## Pandasのget_dummies

```
one_hot_encoded_training_predictors = pd.get_dummies(train_predictors)
```

## 学習データとテストデータの列の並びを揃える

学習データとテストデータをそれぞれone hot encodingすると、
それぞれの列の並びが揃わないことがある。
scikit-learnは、列の並びに敏感である。
そこで、DataFrame#alignを用いて並びを揃える。

```
one_hot_encoded_training_predictors = pd.get_dummies(train_predictors)
one_hot_encoded_test_predictors = pd.get_dummies(test_predictors)
final_train, final_test = one_hot_encoded_training_predictors.align(one_hot_encoded_test_predictors,
                                                                    join='left', 
                                                                    axis=1)

```

なお、joinオプションはSQLにおけるJOINのルールと同等だと考えれば良い。
