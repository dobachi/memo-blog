---

title: Databricks AutoML Toolkit
date: 2019-08-23 22:04:58
categories:
  - Knowledge Management
  - Machine Learning
  - AutoML
tags:
  - Machine Learning
  - AutoML

---

# 参考

* [Databricks launches AutoML Toolkit for model building and deployment]
* [GitHub databrickslabs/automl-toolkit]

[Databricks launches AutoML Toolkit for model building and deployment]: https://venturebeat.com/2019/08/20/databricks-launches-automl-toolkit-for-model-building-and-deployment/
[GitHub databrickslabs/automl-toolkit]: https://github.com/databrickslabs/automl-toolkit

# メモ

## ブログ？記事？

[Databricks launches AutoML Toolkit for model building and deployment] の内容を確認する。

MLFlowなどをベースに開発された。
ハイパーパラメタータチューニング、バッチ推論、モデルサーチを自動化する。

TensorFlowやSageMakerなどと連携。

データサイエンティストとエンジニアが連携可能という点が他のAutoMLと異なる要素。
またコード実装能力が高い人、そうでない人混ざっているケースに対し、
高い抽象度で実装なく動かせると同時に、細かなカスタマイズも可能にする。

DatabricksのAutoMLは、Azureの機械学習サービスとも連携する。（パートナーシップあり）

## GitHub

[GitHub databrickslabs/automl-toolkit] を軽く確認する。

### Readme（2019/08/23現在）

「non-supported end-to-end supervised learning solution for automating」と定義されている。
以下の内容をautomationするようだ。

* Feature clean-up（特徴選択？特徴の前処理？）
* Feature vectorization（特徴のデータのベクトル化）
* Model selection and training（モデル選択と学習）
* Hyper parameter optimization and selection（ハイパーパラメータ最適化と選択）
* Batch Prediction（バッチ処理での推論）
* Logging of model results and training runs (using MLFlow)（MLFlowを使ってロギング、学習実行）

対応している学習モデルは以下の通り。
Sparkの機械学習ライブラリを利用しているようなので、それに準ずることになりそう。

* Decision Trees (Regressor and Classifier)
* Gradient Boosted Trees (Regressor and Classifier)
* Random Forest (Regressor and Classifier)
* Linear Regression
* Logistic Regression
* Multi-Layer Perceptron Classifier
* Support Vector Machines
* XGBoost (Regressor and Classifier)

開発言語はScala（100%）

DBFS APIを前提としているように見えることから、Databricks Cloud前提か？

ハイレベルAPI（FamilyRunner）について載っている例から、ポイントを抜粋する。


```
// パッケージを見る限り、Databricksのラボとしての活動のようだ？
import com.databricks.labs.automl.executor.config.ConfigurationGenerator
import com.databricks.labs.automl.executor.FamilyRunner

val data = spark.table("ben_demo.adult_data")


// MLFlowの設定値など、最低限の上書き設定を定義する
val overrides = Map("labelCol" -> "income",
"mlFlowExperimentName" -> "My First AutoML Run",

// Databrciks Cloud上で起動するDeltaの場所を指定
"mlFlowTrackingURI" -> "https://<my shard address>",
"mlFlowAPIToken" -> dbutils.notebook.getContext().apiToken.get,
"mlFlowModelSaveDirectory" -> "/ml/FirstAutoMLRun/",
"inferenceConfigSaveLocation" -> "ml/FirstAutoMLRun/inference"
)

// コンフィグを適切に？自動生成。合わせてどのモデルを使うかを指定している。
val randomForestConfig = ConfigurationGenerator.generateConfigFromMap("RandomForest", "classifier", overrides)
val gbtConfig = ConfigurationGenerator.generateConfigFromMap("GBT", "classifier", overrides)
val logConfig = ConfigurationGenerator.generateConfigFromMap("LogisticRegression", "classifier", overrides)

// 生成されたコンフィグでランナーを生成し、実行
val runner = FamilyRunner(data, Array(randomForestConfig, gbtConfig, logConfig)).execute()
```

上記実装では、以下のようなことが裏で行われる。

* 前処理
* 特徴データのベクタライズ
* 3種類のモデルについてパラメータチューニング

### 実装を確認

エントリポイントとしては、 `com.databricks.labs.automl.executor.FamilyRunner` としてみる。

#### com.databricks.labs.automl.executor.FamilyRunner

executeメソッドが例として載っていたので確認。
当該メソッド全体は以下の通り。

com/databricks/labs/automl/executor/FamilyRunner.scala:115
```
  def execute(): FamilyFinalOutput = {

    val outputBuffer = ArrayBuffer[FamilyOutput]()

    configs.foreach { x =>
      val mainConfiguration = ConfigurationGenerator.generateMainConfig(x)

      val runner: AutomationRunner = new AutomationRunner(data)
        .setMainConfig(mainConfiguration)

      val preppedData = runner.prepData()

      val preppedDataOverride = preppedData.copy(modelType = x.predictionType)

      val output = runner.executeTuning(preppedDataOverride)

      outputBuffer += new FamilyOutput(x.modelFamily, output.mlFlowOutput) {
        override def modelReport: Array[GenericModelReturn] = output.modelReport
        override def generationReport: Array[GenerationalReport] =
          output.generationReport
        override def modelReportDataFrame: DataFrame =
          augmentDF(x.modelFamily, output.modelReportDataFrame)
        override def generationReportDataFrame: DataFrame =
          augmentDF(x.modelFamily, output.generationReportDataFrame)
      }
    }

    unifyFamilyOutput(outputBuffer.toArray)

  }
```

また、再掲ではあるが、当該メソッドは以下のように呼び出されている。
```
// 生成されたコンフィグでランナーを生成し、実行
val runner = FamilyRunner(data, Array(randomForestConfig, gbtConfig, logConfig)).execute()
```

第1引数はデータ、第2引数は採用するアルゴリズムごとのコンフィグを含んだArray。

では、executeメソッドを少し細かく見る。

まずループとなっている箇所があるが、ここはアルゴリズムごとのコンフィグをイテレートしている。

com/databricks/labs/automl/executor/FamilyRunner.scala:119
```
    configs.foreach { x =>
```

つづいて、渡されたコンフィグを引数に取りながら、パラメータを生成する。

com/databricks/labs/automl/executor/FamilyRunner.scala:120
```
      val mainConfiguration = ConfigurationGenerator.generateMainConfig(x)

```

次は上記で生成されたパラメータを引数に取りながら、処理の自動実行用のAutomationRunnerインスタンスを生成する。

com/databricks/labs/automl/executor/FamilyRunner.scala:122
```
      val runner: AutomationRunner = new AutomationRunner(data)
        .setMainConfig(mainConfiguration)

```

つづいてデータを前処理する。

com/databricks/labs/automl/executor/FamilyRunner.scala:125
```
      val preppedData = runner.prepData()

      val preppedDataOverride = preppedData.copy(modelType = x.predictionType)
```

つづいて生成されたAutomationRunnerインスタンスを利用し、パラメータチューニングを実施する。

com/databricks/labs/automl/executor/FamilyRunner.scala:129
```
      val output = runner.executeTuning(preppedDataOverride)
```

その後、出力内容が整理される。
レポートの類にmodelFamilyの情報を付与したり、など。

com/databricks/labs/automl/executor/FamilyRunner.scala:131
```
      outputBuffer += new FamilyOutput(x.modelFamily, output.mlFlowOutput) {
        override def modelReport: Array[GenericModelReturn] = output.modelReport
        override def generationReport: Array[GenerationalReport] =
          output.generationReport
        override def modelReportDataFrame: DataFrame =
          augmentDF(x.modelFamily, output.modelReportDataFrame)
        override def generationReportDataFrame: DataFrame =
          augmentDF(x.modelFamily, output.generationReportDataFrame)
      }

```

最後に、モデルごとのチューニングのループが完了したあとに、
それにより得られた複数の出力内容をまとめ上げる。
（Arrayをまとめたり、DataFrameをunionしたり、など）

com/databricks/labs/automl/executor/FamilyRunner.scala:142
```
    unifyFamilyOutput(outputBuffer.toArray)

```

#### com.databricks.labs.automl.AutomationRunner#executeTuning

指定されたモデルごとにうチューニングを行う部分を確認する。


当該メソッド内では、modelFamilyごとの処理の仕方が定義されている。
以下にRandomForestの場合を示す。

com/databricks/labs/automl/AutomationRunner.scala:1597
```
  protected[automl] def executeTuning(payload: DataGeneration): TunerOutput = {

    val genericResults = new ArrayBuffer[GenericModelReturn]

    val (resultArray, modelStats, modelSelection, dataframe) =
      _mainConfig.modelFamily match {
        case "RandomForest" =>
          val (results, stats, selection, data) = runRandomForest(payload)
          results.foreach { x =>
            genericResults += GenericModelReturn(
              hyperParams = extractPayload(x.modelHyperParams),
              model = x.model,
              score = x.score,
              metrics = x.evalMetrics,
              generation = x.generation
            )
          }
          (genericResults, stats, selection, data)


(snip)
```

なお、2019/8/25現在対応しているモデルは以下の通り。（caseになっていたのを抜粋）
```
        case "RandomForest" =>
        case "XGBoost" =>
        case "GBT" =>
        case "MLPC" =>
        case "LinearRegression" =>
        case "LogisticRegression" =>
        case "SVM" =>
        case "Trees" =>

```

さて、モデルごとのチューニングの様子を確認する。
RandomForestを例にすると、実態は以下の `runRandomForest` メソッドに見える。

com/databricks/labs/automl/AutomationRunner.scala:1604
```
          val (results, stats, selection, data) = runRandomForest(payload)

```

`runRandomForest` メソッドは、以下のようにペイロードを引数にとり、
その中でチューニングを実施する。

com/databricks/labs/automl/AutomationRunner.scala:46
```
  private def runRandomForest(
                               payload: DataGeneration
                             ): (Array[RandomForestModelsWithResults], DataFrame, String, DataFrame) = {

(snip)

```

特徴的なのは、非常にきめ細やかに初期設定している箇所。
これらの設定を上書きしてチューニングできる、はず。

com/databricks/labs/automl/AutomationRunner.scala:58
```
    val initialize = new RandomForestTuner(cachedData, payload.modelType)
      .setLabelCol(_mainConfig.labelCol)
      .setFeaturesCol(_mainConfig.featuresCol)
      .setRandomForestNumericBoundaries(_mainConfig.numericBoundaries)
      .setRandomForestStringBoundaries(_mainConfig.stringBoundaries)

(snip)
```

実際にチューニングしているのは、以下の箇所のように見える。
`evolveWithScoringDF` 内では、 `RandomForestTuner` クラスのメソッドが呼び出され、
ストラテジ（実装上は、バッチ方式か、continuous方式か）に従ったチューニングが実施される。

com/databricks/labs/automl/AutomationRunner.scala:169
```
    val (modelResultsRaw, modelStatsRaw) = initialize.evolveWithScoringDF()
```


<!-- vim: set tw=0 ts=4 sw=4: -->
