---

title: dansbecker/handling-missing-values
date: 2019-04-12 15:15:31
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

* [Kaggleのhandling-missing-values]
* [scikit-learnのimputeの説明]

[Kaggleのhandling-missing-values]: https://www.kaggle.com/dansbecker/handling-missing-values
[scikit-learnのimputeの説明]: https://scikit-learn.org/stable/modules/impute.html

# メモ

[Kaggleのhandling-missing-values] の内容から気になった箇所をメモ。

## 欠落のあるカラムの排除

最もシンプルな方法として、欠落のあるカラムを排除する方法が挙げられていた。
```
cols_with_missing = [col for col in X_train.columns 
                                 if X_train[col].isnull().any()]
reduced_X_train = X_train.drop(cols_with_missing, axis=1)
reduced_X_test  = X_test.drop(cols_with_missing, axis=1)
```

`X_train[col].isnull().any()`のところで、カラム内の値のいずれかがNULL値かどうかを確認している。

## 欠落を埋める

欠落を埋める。
```
from sklearn.impute import SimpleImputer

my_imputer = SimpleImputer()
imputed_X_train = my_imputer.fit_transform(X_train)
imputed_X_test = my_imputer.transform(X_test)
```

なお、`SimpleImputer#fit_transform`メソッドの戻り値は、`numpy.ndarray`である。

また、[scikit-learnのimputeの説明]を見る限り、カテゴリ値にも対応しているようだ。

## 欠落を埋めつつ、欠落していたことを真理値として保持

```
imputed_X_train_plus = X_train.copy()
imputed_X_test_plus = X_test.copy()

cols_with_missing = (col for col in X_train.columns 
                                 if X_train[col].isnull().any())
for col in cols_with_missing:
    imputed_X_train_plus[col + '_was_missing'] = imputed_X_train_plus[col].isnull()
    imputed_X_test_plus[col + '_was_missing'] = imputed_X_test_plus[col].isnull()

```
