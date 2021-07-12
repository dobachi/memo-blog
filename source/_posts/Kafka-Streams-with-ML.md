---

title: Kafka Streams with ML
date: 2019-11-25 22:14:32
categories:
  - Knowledge Management
  - Machine Learning
  - Stream Processing
tags:
  - Machine Learning
  - Stream Processing
  - Kafka Streams
  - TensorFlow

---

# 参考

## kaiwaehner kafka-streams-machine-learning-examples

* [kaiwaehner kafka-streams-machine-learning-examples]
* [How to Build and Deploy Scalable Machine Learning in Production with Apache Kafka]
* [Using Apache Kafka to Drive Cutting-Edge Machine Learning]
* [Machine Learning with Python, Jupyter, KSQL and TensorFlow]
* [kaiwaehner ksql-udf-deep-learning-mqtt-iot]
* [Iris Prediction using a Neural Network with DeepLearning4J (DL4J)]
* [Python + Keras + TensorFlow + DeepLearning4j]

[kaiwaehner kafka-streams-machine-learning-examples]: https://github.com/kaiwaehner/kafka-streams-machine-learning-examples
[How to Build and Deploy Scalable Machine Learning in Production with Apache Kafka]: https://www.confluent.io/blog/build-deploy-scalable-machine-learning-production-apache-kafka/
[Using Apache Kafka to Drive Cutting-Edge Machine Learning]: https://www.confluent.io/blog/using-apache-kafka-drive-cutting-edge-machine-learning/
[Machine Learning with Python, Jupyter, KSQL and TensorFlow]: https://www.confluent.io/blog/machine-learning-with-python-jupyter-ksql-tensorflow/
[kaiwaehner ksql-udf-deep-learning-mqtt-iot]: https://github.com/kaiwaehner/ksql-udf-deep-learning-mqtt-iot
[kaiwaehner ksql-fork-with-deep-learning-function]: https://github.com/kaiwaehner/ksql-fork-with-deep-learning-function
[kaiwaehner tensorflow-serving-java-grpc-kafka-streams]: https://github.com/kaiwaehner/tensorflow-serving-java-grpc-kafka-streams
[Iris Prediction using a Neural Network with DeepLearning4J (DL4J)]: https://github.com/kaiwaehner/kafka-streams-machine-learning-examples/blob/master/dl4j-deeplearning-iris
[Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java]: https://github.com/kaiwaehner/kafka-streams-machine-learning-examples/blob/master/dl4j-deeplearning-iris/src/test/java/com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java
[Python + Keras + TensorFlow + DeepLearning4j]: https://github.com/kaiwaehner/kafka-streams-machine-learning-examples/tree/master/tensorflow-keras

# メモ

## kaiwaehner/kafka-streams-machine-learning-examples 

[kaiwaehner kafka-streams-machine-learning-examples] には、TensorFlow、Keras、H2O、Python、DL4JをKafka Streamsと併用するサンプルが含まれている。

上記レポジトリのREADMEには、いくつか参考文献が記載されている。

[How to Build and Deploy Scalable Machine Learning in Production with Apache Kafka] には、

* デザインの概略みたいなものが載っていた
* 学習と推論のモデルやりとりをどうつなぐのか？の考察

が記載されていた。

[Using Apache Kafka to Drive Cutting-Edge Machine Learning] にはモデルの組み込み方の種類、
AutoMLとの組み合わせについて考察（Not 具体例）が掲載されている。

[Machine Learning with Python, Jupyter, KSQL and TensorFlow] には、以下のような記述がある。
いつもの論文とセット。

> Impedance mismatch between data scientists, data engineers and production engineers

これを解決する手段としていくつか例示。

* ONNX、PMMLなどを利用
* DL4Jなど開発者視点の含まれるプロダクトの利用
* AutoML
* モデルを出力してアプリに埋め込んで利用（TensorFlowだったらJava APIでモデルを利用する、など）
* パブリッククラウドのマネージドサービス利用

ConfluentのKafka Python KSQL APIを使い、Jupyter上でKafkaからデータロードし分析する例も記載されていた。

[kaiwaehner ksql-udf-deep-learning-mqtt-iot] には、UDF内でTensorFlowを使う例が記載されている。

[kaiwaehner ksql-fork-with-deep-learning-function] には、エンドツーエンドで動作を確認してみるためのサンプル実装が載っている。

[kaiwaehner tensorflow-serving-java-grpc-kafka-streams] には、gRPC経由でKafka StreamsとTensorFlow Servingを連係する例が記載されている。


### Convolutional Neural Network (CNN) with TensorFlow for Image Recognition

`com.github.megachucky.kafka.streams.machinelearning.Kafka_Streams_TensorFlow_Image_Recognition_Example` クラスを確認する。

#### 概要

* 本クラスは、予め学習されたTensorFlowのモデルを読み出して利用する
* 上記モデルを利用するときには、TensorFlowのJava APIを利用する
* 画像はどこかのストレージに保存されている前提となっており、そのPATHがメッセージとしてKafkaに入ってくるシナリオである
* 画像に対するラベルのProbabilityを計算し、最大のProbabilityを持つラベルを戻り値として返す

#### 詳細メモ

`main`内では特別なことはしていない。トポロジを組み立てるための `getStreamTopology` が呼ばれる。

`getStreamTopology` メソッドを確認する。

当該メソッドでは、最初にモデル本体やモデルの定義が読み込まれる。

com/github/megachucky/kafka/streams/machinelearning/Kafka_Streams_TensorFlow_Image_Recognition_Example.java:83

```
		String modelDir = "src/main/resources/generatedModels/CNN_inception5h";

		Path pathGraph = Paths.get(modelDir, "tensorflow_inception_graph.pb");
		byte[] graphDef = Files.readAllBytes(pathGraph);

		Path pathModel = Paths.get(modelDir, "imagenet_comp_graph_label_strings.txt");
		List<String> labels = Files.readAllLines(pathModel, Charset.forName("UTF-8"));

```

続いてストリームのインスタンスが生成される。
その後、ストリーム処理の内容が定義される。

最初はメッセージ内に含まれる画像のPATHを用いて、実際の画像をバイト列で読み出す。

com/github/megachucky/kafka/streams/machinelearning/Kafka_Streams_TensorFlow_Image_Recognition_Example.java:104

```
		KStream<String, Object> transformedMessage =
		imageInputLines.mapValues(value ->  {

			String imageClassification = "unknown";
			String imageProbability = "unknown";

			String imageFile = value;

			Path pathImage = Paths.get(imageFile);
			byte[] imageBytes;
			try {
				imageBytes = Files.readAllBytes(pathImage);

```

つづいていくつかのヘルパメソッドを使って、画像に対するラベル（推論結果）を算出する。

com/github/megachucky/kafka/streams/machinelearning/Kafka_Streams_TensorFlow_Image_Recognition_Example.java:117

```
				try (Tensor image = constructAndExecuteGraphToNormalizeImage(imageBytes)) {
					float[] labelProbabilities = executeInceptionGraph(graphDef, image);
					int bestLabelIdx = maxIndex(labelProbabilities);

					imageClassification = labels.get(bestLabelIdx);

					imageProbability = Float.toString(labelProbabilities[bestLabelIdx] * 100f);

					System.out.println(String.format("BEST MATCH: %s (%.2f%% likely)", imageClassification,
							labelProbabilities[bestLabelIdx] * 100f));
				}
```

`constructAndExecuteGraphToNormalizeImage` メソッドは、グラフを構成し、前処理を実行する。

com/github/megachucky/kafka/streams/machinelearning/Kafka_Streams_TensorFlow_Image_Recognition_Example.java:171

```
			final Output input = b.constant("input", imageBytes);
			final Output output = b
					.div(b.sub(
							b.resizeBilinear(b.expandDims(b.cast(b.decodeJpeg(input, 3), DataType.FLOAT),
									b.constant("make_batch", 0)), b.constant("size", new int[] { H, W })),
							b.constant("mean", mean)), b.constant("scale", scale));
			try (Session s = new Session(g)) {
				return s.runner().fetch(output.op().name()).run().get(0);
			}

```


`executeInceptionGraph` メソッドは、予め学習済みのモデルと画像を引数にとり、
ラベルごとのProbabilityを算出する。

com/github/megachucky/kafka/streams/machinelearning/Kafka_Streams_TensorFlow_Image_Recognition_Example.java:184

```
		try (Graph g = new Graph()) {

			// Model loading: Using Graph.importGraphDef() to load a pre-trained Inception
			// model.
			g.importGraphDef(graphDef);

			// Graph execution: Using a Session to execute the graphs and find the best
			// label for an image.
			try (Session s = new Session(g);
					Tensor result = s.runner().feed("input", image).fetch("output").run().get(0)) {
				final long[] rshape = result.shape();
				if (result.numDimensions() != 2 || rshape[0] != 1) {
					throw new RuntimeException(String.format(
							"Expected model to produce a [1 N] shaped tensor where N is the number of labels, instead it produced one with shape %s",
							Arrays.toString(rshape)));
				}
				int nlabels = (int) rshape[1];
				return result.copyTo(new float[1][nlabels])[0];
			}
		}

```

`executeInceptionGraph` メソッドにより、ある画像に対するラベルごとのProbabilityが得られた後、
最大のProbabilityを持つラベルを算出。
それを戻り値とする。

### Iris Prediction using a Neural Network with DeepLearning4J (DL4J)

[Iris Prediction using a Neural Network with DeepLearning4J (DL4J)] を確認する。

`com.github.megachucky.kafka.streams.machinelearning.models.DeepLearning4J_CSV_Model_Inference` クラスを確認したが、これはKafka Streamsアプリには見えなかった。
中途半端な状態で止まっている？
これをベースに Kafka Streams のアプリを作ってみろ、ということか。

もしくはunitテスト側を見ろ、ということか？ -> そのようだ。 [Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java]

クラスの内容を確認する。

まずテストのセットアップ。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java:46

```
	@ClassRule
	public static final EmbeddedKafkaCluster CLUSTER = new TestEmbeddedKafkaCluster(1);

	private static final String inputTopic = "IrisInputTopic";
	private static final String outputTopic = "IrisOutputTopic";

	// Generated DL4J model
	private File locationDL4JModel = new File("src/main/resources/generatedModels/DL4J/DL4J_Iris_Model.zip");

	// Prediction Value
	private static String irisPrediction = "unknown";
```

TestEmbeddedKafkaClusterはテスト用のKafkaクラスタを起動するヘルパークラス。
内部的には、Kafka Streamsのテストに用いられている補助機能である `org.apache.kafka.streams.integration.utils.EmbeddedKafkaCluster` クラスを継承して作られている。

機械学習モデルは、予め学習済みのものが含まれているのでそれを読み込んで用いる

テストコードの実態は、  `com.github.megachucky.kafka.streams.machinelearning.test.Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest#shouldPredictIrisFlowerType` である。
以降、当該メソッド内を確認する。


メソッドの冒頭で、Kafka Streamsの設定を定義している。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java:67

```
		// Iris input data (the model returns probabilities for input being each of Iris
		// Type 1, 2 and 3)
		List<String> inputValues = Arrays.asList("5.4,3.9,1.7,0.4", "7.0,3.2,4.7,1.4", "4.6,3.4,1.4,0.3");

(snip)

		streamsConfiguration.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());
		streamsConfiguration.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());

```

このサンプルは動作確認用のため簡易な設定になっている。
実際のアプリケーション開発時にはきちんと設定必要。

なお、途中でDL4Jのモデルを読み込んでいる。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java:86

```
		// Create DL4J object (see DeepLearning4J_CSV_Model.java)
		MultiLayerNetwork model = ModelSerializer.restoreMultiLayerNetwork(locationDL4JModel);
```

その後、ビルダのインスタンスを生成し、Irisデータを入力とするストリームを定義する。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java:97, 104
```
		final StreamsBuilder builder = new StreamsBuilder();
		final KStream<String, String> irisInputLines = builder.stream(inputTopic);
```

その後はストリームのメッセージに対し、DL4Jのモデルによる推論を実行する。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java:108

```
		irisInputLines.foreach((key, value) -> {

			if (value != null && !value.equals("")) {
				System.out.println("#####################");
				System.out.println("Iris Input:" + value);

				// TODO Easier way to map from String[] to double[] !!!
				String[] stringArray = value.split(",");
				Double[] doubleArray = Arrays.stream(stringArray).map(Double::valueOf).toArray(Double[]::new);
				double[] irisInput = Stream.of(doubleArray).mapToDouble(Double::doubleValue).toArray();

				// Inference
				INDArray input = Nd4j.create(irisInput);
				INDArray result = model.output(input);

				System.out.println("Probabilities: " + result.toString());

				irisPrediction = result.toString();

			}

		});
```

ここでは入力されたテキストデータをDouble型の配列に変換し、さらにND4JのINDArrayに変換する。
それをモデルに入力し、推論を得る。

その後、テキストを整形し、出力用トピックに書き出し。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java:132
```
		// Transform message: Add prediction information
		KStream<String, Object> transformedMessage = irisInputLines
				.mapValues(value -> "Prediction: Iris Probability => " + irisPrediction);

		// Send prediction information to Output Topic
		transformedMessage.to(outputTopic);
```

ビルダを渡し、ストリーム処理をスタート。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java:140
```
		final KafkaStreams streams = new KafkaStreams(builder.build(), streamsConfiguration);
		streams.cleanUp();
		streams.start();
		System.out.println("Iris Prediction Microservice is running...");
		System.out.println("Input to Kafka Topic 'IrisInputTopic'; Output to Kafka Topic 'IrisOutputTopic'");
```

その後、これはテストコードなので、入力となるデータをアプリケーション内で生成し、入力トピックに書き込む。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_MachineLearning_DL4J_DeepLearning_Iris_IntegrationTest.java:149
```
		Properties producerConfig = new Properties();
		producerConfig.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, CLUSTER.bootstrapServers());
		producerConfig.put(ProducerConfig.ACKS_CONFIG, "all");
		producerConfig.put(ProducerConfig.RETRIES_CONFIG, 0);
		producerConfig.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
		producerConfig.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
		IntegrationTestUtils.produceValuesSynchronously(inputTopic, inputValues, producerConfig, new MockTime());
```

ここでは結合テスト用のヘルパーメソッドを利用。

その後、出力トピックから結果を取り出し、確認する。（実装解説は省略）

### Python + Keras + TensorFlow + DeepLearning4j

例のごとく、テスト側が実装本体。
`Kafka_Streams_TensorFlow_Keras_Example_IntegrationTest` クラスを確認する。

実態は `shouldPredictValues` メソッド。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_TensorFlow_Keras_Example_IntegrationTest.java:64

```
	public void shouldPredictValues() throws Exception {
```

上記メソッド内では、最初にモデルを読み込む。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_TensorFlow_Keras_Example_IntegrationTest.java:69

```
		String simpleMlp = new ClassPathResource("generatedModels/Keras/simple_mlp.h5").getFile().getPath();
		System.out.println(simpleMlp.toString());

		MultiLayerNetwork model = KerasModelImport.importKerasSequentialModelAndWeights(simpleMlp);
```

上記では、HDF形式で予め保存されたモデルを読み込む。
読み込みの際にはDeeplearning4Jの `KerasModelImport#importKerasSequentialModelAndWeights` メソッドが用いられる。

続いて、Kafka Streamsのコンフィグを定める。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_TensorFlow_Keras_Example_IntegrationTest.java:81

```
		Properties streamsConfiguration = new Properties();
		streamsConfiguration.put(StreamsConfig.APPLICATION_ID_CONFIG,
				"kafka-streams-tensorflow-keras-integration-test");
		streamsConfiguration.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, CLUSTER.bootstrapServers());

		streamsConfiguration.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());
		streamsConfiguration.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.String().getClass().getName());

```

次にKafka Streamsのビルダを定義し、入力トピックを渡して入力ストリームを定義する。

```
		final StreamsBuilder builder = new StreamsBuilder();

		final KStream<String, String> inputEvents = builder.stream(inputTopic);

```

以降、メッセージを入力とし、推論を行う処理の定義が続く。

先程定義したストリームの中は、カンマ区切りのテキストになっている。
これをカンマで区切り、配列に変換する。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_TensorFlow_Keras_Example_IntegrationTest.java:104

```
		inputEvents.foreach((key, value) -> {

			// Transform input values (list of Strings) to expected DL4J parameters (two
			// Integer values):
			String[] valuesAsArray = value.split(",");
			INDArray input = Nd4j.create(Integer.parseInt(valuesAsArray[0]), Integer.parseInt(valuesAsArray[1]));
```

配列への変換には、Nd4Jを用いる。

配列の定義が完了したら、それを入力としてモデルを用いた推論を行う処理を定義する。


```

			output = model.output(input);
			prediction = output.toString();

		});

```

最後は出力メッセージに変換し、出力トピックへの書き出しを定義する。
その後、独自のユーティリティクラスを使って、ビルダーに基づいてストリームをビルド。
ストリーム処理を開始する。

com/github/megachucky/kafka/streams/machinelearning/test/Kafka_Streams_TensorFlow_Keras_Example_IntegrationTest.java:118

```
		// Transform message: Add prediction result
		KStream<String, Object> transformedMessage = inputEvents.mapValues(value -> "Prediction => " + prediction);

		// Send prediction result to Output Topic
		transformedMessage.to(outputTopic);

		// Start Kafka Streams Application to process new incoming messages from
		// Input Topic
		final KafkaStreams streams = new TestKafkaStreams(builder.build(), streamsConfiguration);
		streams.cleanUp();
		streams.start();
		System.out.println("Prediction Microservice is running...");
		System.out.println("Input to Kafka Topic " + inputTopic + "; Output to Kafka Topic " + outputTopic);
```

<!-- vim: set tw=0 ts=4 sw=4: -->
