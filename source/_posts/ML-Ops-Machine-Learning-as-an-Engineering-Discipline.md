---

title: 'ML Ops: Machine Learning as an Engineering Discipline'
date: 2020-01-11 22:26:40
categories:
  - Knowledge Management
  - Machine Learning
  - OpML
tags:
  - ML Ops

---

# 参考

* [ML Ops Machine Learning as an Engineering Discipline]

[ML Ops Machine Learning as an Engineering Discipline]: https://towardsdatascience.com/ml-ops-machine-learning-as-an-engineering-discipline-b86ca4874a3F


# メモ

読んでみた感想をまとめる。

## 感想

結論としては、まとめ表がよくまとまっているのでそれでよい気がする。
この表をベースに、アクティビティから必要なものを追加するか？
-> [まとめ表]

演繹的ではなく、帰納的な手法であるため、もとになったコードとデータの両方が重要。

データサイエンティスト、MLエンジニア、DevOpsエンジニア、データエンジニア。
MLエンジニア。あえてエンジニアと称しているのは、ソフトウェア開発のスキルを有していることを期待するから。

フェアネスの考慮、というか機械学習の倫理考慮をどうやって機械的に実現するのか、というのはかねてより気になっていた。
フェアネスの考慮などを達成するためには、テストデータセットの作り方、メトリクスの作り方に工夫するとよい。つまり、男女でそれぞれ個別にもテストするなど。
まだ一面ではあるが、参考になった。

## 気になる文言の抜粋

以下の文言が印象に残った。
ほかのレポートでも言われていることに見える。

> Deeplearning.ai reports that “only 22 percent of companies using machine learning have successfully deployed a model”.

このレポートがどれか気になった。
[Deeplearning.aiのレポート] か。

[Deeplearning.aiのレポート]: https://info.deeplearning.ai/the-batch-companies-slipping-on-ai-goals-self-training-for-better-vision-muppets-and-models-china-vs-us-only-the-best-examples-proliferating-patents

確かに以下のように記載されている。

> Although AI budgets are on the rise, only 22 percent of companies using machine learning have successfully deployed a model, the study found. 

データが大切論：

> ML is not just code, it’s code plus data

> training data, which will affect the behavior of the model in production

![ML = Code + Dataの図](https://miro.medium.com/max/2890/1*XKk_Dc9fNLZ8VgL0v6WpYw.png)

> It never stops changing, and you can’t control how it will change. 

確かに、データはコントロールできない。

> Data Engineering

![ML Opsの概念図](https://miro.medium.com/max/2443/1*rCyvV8hAhAhqNjkLt7Wi7g.png)

チーム構成について言及あり。：

> But the most likely scenario right now is that a successful team would include a Data Scientist or ML Engineer, a DevOps Engineer and a Data Engineer.

データサイエンティストのほかに、明確にMLエンジニア、DevOpsエンジニア、データエンジニアを入れている。
基盤エンジニアはデータエンジニアに含まれるのだろうか。

> Even if an organization includes all necessary skills, it won’t be successful if they don’t work closely together.

ノートブックに殴り書かれたコードは不十分の話：

> getting a model to work great in a messy notebook is not enough.

> ML Engineers

データパイプラインの話：

> data pipeline

殴り書きのコードではなく、適切なパイプラインはメリットいくつかあるよね、と。：

> Switching to proper data pipelines provides many advantages in code reuse, run time visibility, management and scalability.

トレーニングとサービングの両方でパイプラインがあるけど、
入力データや変換内容は、場合によっては微妙に異なる可能性がある、と。：

> Most models will need 2 versions of the pipeline: one for training and one for serving.

![ML Pipelineは特定のデータから独立しているためCICDと連携可能](https://miro.medium.com/max/2920/1*U7Efc4rSPsXDTeKRzM86eg.png)


> For example, the training pipeline usually runs over batch files that contain all features, while the serving pipeline often runs online and receives only part of the features in the requests, retrieving the rest from a database.

いくつかTensorFlow関係のツールが紹介されている。確認したほうがよさそう。：

> TensorFlow Pipeline

> TensorFlow Transform

バージョン管理について：

> In ML, we also need to track model versions, along with the data used to train it, and some meta-information like training hyperparameters.

> Models and metadata can be tracked in a standard version control system like Git, but data is often too large and mutable for that to be efficient and practical.

コードのラインサイクルと、モデルのライフサイクルは異なる：

> It’s also important to avoid tying the model lifecycle to the code lifecycle, since model training often happens on a different schedule.

> It’s also necessary to version data and tie each trained model to the exact versions of code, data and hyperparameters that were used. 

> Having comprehensive automated tests can give great confidence to a team, accelerating the pace of production deployments dramatically.

モデルの検証は本質的に、統計に基づくものになる。というのも、そもそもモデルの出力が確率的だし、入力データも変動する。：

> model validation tests need to be necessarily statistical in nature

> Just as good unit tests must test several cases, model validation needs to be done individually for relevant segments of the data, known as slices. 

> Data validation is analogous to unit testing in the code domain.

> ML pipelines should also validate higher level statistical properties of the input.

> TensorFlow Data Validation

> Therefore, in addition to monitoring standard metrics like latency, traffic, errors and saturation, we also need to monitor model prediction performance.

> An obvious challenge with monitoring model performance is that we usually don’t have a verified label to compare our model’s predictions to, since the model works on new data.

![まとめ表]

[まとめ表]: https://miro.medium.com/max/2870/1*hlukfeyP-I209WBEMsBSEA.png

<!-- vim: set et tw=0 ts=2 sw=2: -->