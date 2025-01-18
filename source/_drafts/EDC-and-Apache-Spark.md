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

k8s上で各種サービスを起動する。

ビルド

```bash
./gradlew build
./gradlew -Ppersistence=true dockerize
```

kind (k8s) 環境起動
```bash
# Create the cluster
kind create cluster -n mvd --config deployment/kind.config.yaml
# Load docker images into KinD
kind load docker-image controlplane:latest dataplane:latest identity-hub:latest catalog-server:latest sts:latest -n mvd
```

```bash
# 確認
docker ps
CONTAINER ID   IMAGE                  COMMAND                   CREATED         STATUS         PORTS                                                                 NAMES
b7f31408c498   kindest/node:v1.27.3   "/usr/local/bin/entr…"   2 minutes ago   Up 2 minutes   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 127.0.0.1:32825->6443/tcp   mvd-control-plane
```

ingress NGINXコントローラをk8s上にデプロイ

```bash
# Deploy an NGINX ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for the ingress controller to become available
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

今回のMVD環境をデプロイ

```bash

# Deploy the dataspace, type 'yes' when prompted
cd deployment
terraform init
terraform apply
```

確認

```bash
kubectl get pods --namespace mvd
```

結果
```
NAME                                                   READY   STATUS    RESTARTS   AGE
consumer-controlplane-68c4696c57-2qmh2                 1/1     Running   0          55s
consumer-dataplane-75d79bfd56-t5mt2                    1/1     Running   0          39s
consumer-identityhub-545fdb579c-df6bq                  1/1     Running   0          55s
consumer-postgres-687484545b-sp8xr                     1/1     Running   0          96s
consumer-sts-778bb7bb44-kfqxp                          1/1     Running   0          70s
consumer-vault-0                                       1/1     Running   0          95s
dataspace-issuer-server-7ff68bd8b4-qh7c7               1/1     Running   0          96s
provider-catalog-server-58b67bdb89-nxtvq               1/1     Running   0          54s
provider-identityhub-bb68bfcf4-bv42v                   1/1     Running   0          55s
provider-manufacturing-controlplane-86bdd7c967-b6r7h   1/1     Running   0          54s
provider-manufacturing-dataplane-7d66445bf8-dp24n      1/1     Running   0          39s
provider-postgres-7fd78d95b8-x2kzd                     1/1     Running   0          96s
provider-qna-controlplane-dc894c5ff-qxcd7              1/1     Running   0          55s
provider-qna-dataplane-8574c764fd-t2x8z                1/1     Running   0          39s
provider-sts-64cd87f4f6-n5cvq                          1/1     Running   0          70s
provider-vault-0                                       1/1     Running   0          95s
```

構成

- Consumer
  - コントロールプレーン
  - データプレーン
  - アイデンティティ・ハブ
  - PostgreSQLサーバ
  - Vault
- Provider
  - カタログ
  - QNAのコントロールプレーンとデータプレーン
  - Manufacturingのコントロールプレーンとデータプレーン
  - アイデンティティ・ハブ
  - PostgreSQLサーバ
  - Vault

プロジェクト直下の、seed-k8s.shを使うとデータを流したりできる。
以下、内容を確認。

```bash
## Seed application DATA to both connectors
echo
echo
echo "Seed data to 'provider-qna' and 'provider-manufacturing'"
for url in 'http://127.0.0.1/provider-manufacturing/cp' 'http://127.0.0.1/provider-qna/cp'
do
  newman run \
    --folder "Seed" \
    --env-var "HOST=$url" \
    ./deployment/postman/MVD.postman_collection.json
done
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
