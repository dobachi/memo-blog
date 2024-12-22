---

title: EDC and Apache Spark
date: 2024-12-21 15:50:22
categories:
tags:

---

# メモ

Apache SparkからEclipse Dataspace Components（EDC）のコネクタを経由してデータを読み込むための具体例を以下に示します。

## Eclipse Dataspace Componentsのセットアップ

まず、Eclipse Dataspace Components（EDC）をセットアップします。EDCは、データスペースにおけるデータ連携を実現するためのフレームワークです。以下の手順でEDCをセットアップします。

### 準備

[必要環境] に必要となる環境が書いてある。

* Docker
* KinD (other cluster engines may work as well - not tested!)
* Terraform
* JDK 17+
* Git
* a POSIX compliant shell
* Postman (to comfortably execute REST requests)
* openssl, optional, but required to regenerate keys
* newman (to run Postman collections from the command line)
* not needed, but recommended: Kubernetes monitoring tools like K9s

#### Docker

[Docker Desktop]

#### kind

[kindのインストール方法]

#### JDK

JDK17をインストール

#### Postman

[Postmanのダウンロード]

#### openssl

```bash
sudo apt install openssl
```

#### newman

npmのインストールから必要

```bash
sudo apt install nodejs npm n
sudo n stable
sudo npm install -g newman
```

### ソースコードのクローン

今回はMVDを用います。

```bash
git clone https://github.com/eclipse-edc/MinimumViableDataspace.git
cd MinimumViableDataspace
```

公式サイトの環境構成図

![環境構成](images/20241221_edc_mvd_participants.png)

構成図の通り、今回は認証にVCを用いる。予め作られていたものを用いる。
NGINXでホストするので、Dockerで起動。

```bash
docker run -d --name nginx -p 9876:80 --rm \
  -v "$PWD"/deployment/assets/issuer/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v "$PWD"/deployment/assets/issuer/did.docker.json:/var/www/.well-known/did.json:ro \
  nginx
```

公式READMEによると、temurin-22 JDKを用いているらしいので、以下からダウンロード。
後々の開発用に用いる。

https://adoptium.net/temurin/releases/?os=linux&arch=x64&package=jdk&version=22

ダウンロードして展開し、環境変数JAVA_HOMEに設定。
なお、ここでは以下においた。

```
export JAVA_HOME=/usr/local/jdk/jdk-22.0.2+9
```

k8s上で各種サービスを起動する。

```bash
./gradlew build
./gradlew -Ppersistence=true dockerize
```

# 参考

* [必要環境]
* [Docker Desktop]
* [kindのインストール方法]
* [Postmanのダウンロード]

[必要環境]: https://github.com/eclipse-edc/MinimumViableDataspace?tab=readme-ov-file#5-running-the-demo-kubernetes
[Docker Desktop]: https://www.docker.com/ja-jp/products/docker-desktop/
[kindのインストール方法]: https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries
[Postmanのダウンロード]: https://www.postman.com/downloads/


<!-- vim: set et tw=0 ts=2 sw=2: -->
