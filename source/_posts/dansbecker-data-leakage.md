---

title: dansbecker/data-leakage
date: 2019-04-14 22:03:51
categories:
  - Knowledge Management
  - Machine Learning
  - Model
  - Data Leakage
tags:
  - Machine Learning
  - Kaggle
  - Model
  - Data Leakage

---

# 参考

* [Kaggleのdansbecker data-leakage]

[Kaggleのdansbecker data-leakage]: https://www.kaggle.com/dansbecker/data-leakage

# メモ

## Leaky Predictor

例では、肺炎発症と抗生物質摂取のケースが挙げられていた。

肺炎が発症したあとで、抗生物質を摂取する。
抗生物質を摂取したかどうかは、肺炎発症の前後で値が変わる。
値が変わることを考慮しないと、抗生物質を摂取しない人は肺炎にならない、というモデルが出来上がる可能性がある。

### どう対処するのか？

汎用的な対処方法はなく、データや要件に強く依存する。
Leaky Predictorを発見する **コツ** は、強い相関のある特徴同士に着目する、
とても高いaccuracyを得られたときに気をつける、など。

## Leaky Validation Strategy

例では、train-testスプリットの前に前処理を行おうケースが挙げられていた。

バリデーション対象には、前処理も含めないといけない。
そうでないと、バリデーションで高いモデル性能が得られたとしても、
実際の判定処理で期待したモデル性能が得られない可能性がある。

### どう対処するのか？

パイプラインを組むときに、例えばクロスバリデーションの処理内に、
前処理を入れるようにする、など。

## クレジットカードのデータの例

クレジットカードの使用がアプリケーションで認められたかどうか、を判定する例。
ここでは、クレジットカードの使用量の特徴が、Leaky Predictorとして挙げられていた。
