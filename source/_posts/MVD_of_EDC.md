---

title: MVD_of_EDC
date: 2024-12-21 15:50:22
categories:
  - Knowledge Management
  - Dataspace Connector
  - Eclipse Dataspace Components
tags:
  - Dataspace Connector
  - IDS
  - EDC

---

# メモ

MVDを用いた動作確認用のメモ

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

![環境構成](/images/20241221_edc_mvd_participants.png)


### ビルドと起動

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

### データの流し込み

プロジェクト直下の、seed-k8s.shを使うとデータを流したりできる。

```shell
bash seed-k8s.sh
```

以下、内容を確認。

seed-k8s.shでは、Postman（Newman）を使って、コネクタに各種データを登録するなどしている。
例えば以下の通り。

seed-k8s.sh:23
```shell
echo "Seed data to 'provider-qna' and 'provider-manufacturing'"
for url in 'http://127.0.0.1/provider-manufacturing/cp' 'http://127.0.0.1/provider-qna/cp'
do
  newman run \
    --folder "Seed" \
    --env-var "HOST=$url" \
    ./deployment/postman/MVD.postman_collection.json
done
```

上記の `newman` コマンドの引数に与えられているファイル `deployment/postman/MVD.postman_collection.json` にPostman（Newman）用のコンフィグファイルがある。
newmanコマンドのfolderオプションにある通り、今回は「Seed」フォルダ以下の内容を実行する。
なお、この登録処理は以下の両方のホストに実施される。
* `provider-qna`
* `provider-manufacturing`

行われる処理は以下。

* アセット登録
  * `asset-1`
  * `asset-2`
* ポリシー登録
  * `require-membership`
  * `require-dataprocessor`
  * `require-sensitive`
* コントラクト登録
  * `member-and-dataprocessor-def`
    * アクセスポリシーは `require-membership`
    * コントラクトポリシーは `require-dataprocessor`
    * 対象アセットは `asset-1`
  * `sensitive-only-def`
    * アクセスポリシーは `require-membership`
    * コントラクトポリシーは `require-sensitive`
    * 対象アセットは `asset-2`

続いて、スクリプトにある通り、`deployment/postman/MVD.postman_collection.json` の `Seed Catalog Server` フォルダ以下が実行される。
対象ホストは、 `provider-catalog-server` 。

seed-k8s.sh:35

```shell
echo "Create linked assets on the Catalog Server"
newman run \
  --folder "Seed Catalog Server" \
  --env-var "HOST=http://127.0.0.1/provider-catalog-server/cp" \
  --env-var "PROVIDER_QNA_DSP_URL=http://provider-qna-controlplane:8082" \
  --env-var "PROVIDER_MF_DSP_URL=http://provider-manufacturing-controlplane:8082" \
  ./deployment/postman/MVD.postman_collection.json
```

* カタログアセット登録
  * `linked-asset-provider-qna`
  * `linked-asset-provider-manufacturing`
* アセット登録
  * `normal-asset-1`
* ポリシー登録
  * `require-membership`
* コントラクト定義登録
  * `membership-required-def`

スクリプトを実行すると以下のような結果が得られる。

```
Seed data to 'provider-qna' and 'provider-manufacturing'          
newman                                                                                                  
                                                                                                        
MVD+IATP                                                                                                
                                                                                                        
❏ Seed                                                                                                  
↳ Create Asset 1                                                                                        
  POST http://127.0.0.1/provider-manufacturing/cp/api/management/v3/assets [200 OK, 331B, 66ms]
  ✓  Status is OK or conflict                                                                           
                                                                                                        
↳ Create Asset 2                                                                                        
  POST http://127.0.0.1/provider-manufacturing/cp/api/management/v3/assets [200 OK, 331B, 23ms]         
  ✓  Status is OK or conflict                                                                           
                                                                                                        
↳ Create Membership Policy                                                                              
  POST http://127.0.0.1/provider-manufacturing/cp/api/management/v3/policydefinitions [200 OK, 342B, 71ms]
  ✓  Status is OK or conflict                             

(snip)

┌─────────────────────────┬───────────────────┬──────────────────┐
│                         │          executed │           failed │
├─────────────────────────┼───────────────────┼──────────────────┤
│              iterations │                 1 │                0 │
├─────────────────────────┼───────────────────┼──────────────────┤
│                requests │                 7 │                0 │
├─────────────────────────┼───────────────────┼──────────────────┤
│            test-scripts │                14 │                0 │
├─────────────────────────┼───────────────────┼──────────────────┤
│      prerequest-scripts │                21 │                0 │
├─────────────────────────┼───────────────────┼──────────────────┤
│              assertions │                 7 │                0 │
├─────────────────────────┴───────────────────┴──────────────────┤
│ total run duration: 466ms                                      │
├────────────────────────────────────────────────────────────────┤
│ total data received: 1.45kB (approx)                           │
├────────────────────────────────────────────────────────────────┤
│ average response time: 34ms [min: 19ms, max: 71ms, s.d.: 21ms] │
└────────────────────────────────────────────────────────────────┘
```


### コンシューマとプロバイダの登録

続いて、コンシューマ登録。

seed-k8s.sh:49

```shell
echo "Create consumer participant"
CONSUMER_CONTROLPLANE_SERVICE_URL="http://consumer-controlplane:8082"
CONSUMER_IDENTITYHUB_URL="http://consumer-identityhub:7082"
DATA_CONSUMER=$(jq -n --arg url "$CONSUMER_CONTROLPLANE_SERVICE_URL" --arg ihurl "$CONSUMER_IDENTITYHUB_URL" '{
           "roles":[],
           "serviceEndpoints":[
             {
                "type": "CredentialService",
                "serviceEndpoint": "\($ihurl)/api/presentation/v1/participants/ZGlkOndlYjpjb25zdW1lci1pZGVudGl0eWh1YiUzQTcwODM6Y29uc3VtZXI=",
                "id": "consumer-credentialservice-1"
             },
             {
                "type": "ProtocolEndpoint",
                "serviceEndpoint": "\($url)/api/dsp",
                "id": "consumer-dsp"
             }
           ],
           "active": true,
           "participantId": "did:web:consumer-identityhub%3A7083:consumer",
           "did": "did:web:consumer-identityhub%3A7083:consumer",
           "key":{
               "keyId": "did:web:consumer-identityhub%3A7083:consumer#key-1",
               "privateKeyAlias": "did:web:consumer-identityhub%3A7083:consumer#key-1",
               "keyGeneratorParams":{
                  "algorithm": "EC"
               }
           }
       }')

curl --location "http://127.0.0.1/consumer/cs/api/identity/v1alpha/participants/" \
--header 'Content-Type: application/json' \
--header "x-api-key: $API_KEY" \
--data "$DATA_CONSUMER"
```

プロバイダ登録

```shell
echo "Create provider participant"

PROVIDER_CONTROLPLANE_SERVICE_URL="http://provider-catalog-server-controlplane:8082"
PROVIDER_IDENTITYHUB_URL="http://provider-identityhub:7082"

DATA_PROVIDER=$(jq -n --arg url "$PROVIDER_CONTROLPLANE_SERVICE_URL" --arg ihurl "$PROVIDER_IDENTITYHUB_URL" '{
           "roles":[],
           "serviceEndpoints":[
             {
                "type": "CredentialService",
                "serviceEndpoint": "\($ihurl)/api/presentation/v1/participants/ZGlkOndlYjpwcm92aWRlci1pZGVudGl0eWh1YiUzQTcwODM6cHJvdmlkZXI=",
                "id": "provider-credentialservice-1"
             },
             {
                "type": "ProtocolEndpoint",
                "serviceEndpoint": "\($url)/api/dsp",
                "id": "provider-dsp"
             }
           ],
           "active": true,
           "participantId": "did:web:provider-identityhub%3A7083:provider",
           "did": "did:web:provider-identityhub%3A7083:provider",
           "key":{
               "keyId": "did:web:provider-identityhub%3A7083:provider#key-1",
               "privateKeyAlias": "did:web:provider-identityhub%3A7083:provider#key-1",
               "keyGeneratorParams":{
                  "algorithm": "EC"
               }
           }
       }')

curl --location "http://127.0.0.1/provider/cs/api/identity/v1alpha/participants/" \
--header 'Content-Type: application/json' \
--header "x-api-key: $API_KEY" \
--data "$DATA_PROVIDER"
```

上記の通り、DIDを登録している。

成功すると以下のようなメッセージが見られる。

```
(snip)

Create consumer participant                                                                             
{"apiKey":"ZGlkOndlYjpjb25zdW1lci1pZGVudGl0eWh1YiUzQTcwODM6Y29uc3VtZXI=.TfDP+lAgK+GUb7f+dNSvU9WKpZPNV1zZ/YJ8gNoNlrI3zZkcrg8b7dWAYMYD+k3qOoVdp+ZAE3C5fHWgmsQtww==","clientId":"did:web:consumer-identityhub%3A708
3:consumer","clientSecret":"IMyZ5gqsnXihiftx"}                                                          
                                                                                                        
Create provider participant                                                                             
{"apiKey":"ZGlkOndlYjpwcm92aWRlci1pZGVudGl0eWh1YiUzQTcwODM6cHJvdmlkZXI=.h7Ta9GRuNSOrD7I/BS681E7OsvsX/YEpDrz/Mj+1nJxG3xAFtwTGCFP0qF/QxWdZ/aJvi7ywehpAu/Cg/Yi37w==","clientId":"did:web:provider-identityhub%3A708
3:provider","clientSecret":"P751oqFsm4npVkai"}
```

## 動作確認

READMEの「7. Executing REST requests using Postman」を参考に実施。

変数にはローカル環境用とKubernetes環境用があるので、今回はkubernetes環境用を使用。

`deployment/postman/MVD K8S.postman_environment.json`

Postmanでインポートすると以下のように環境が見える。

![環境](images/20250119_Postman_env.png)

続いて、collectionをインポートする。

`deployment/postman/MVD K8S.postman_collection.json`

コレクションをインポートすると、以下のように各種リクエストをPostmanから送れるようになる。

![環境](images/20250119_Postman_collection.png)

### カタログ

以下のように、環境を`MVD K8S`に変更（右上）し、`Get Cached Catalogs`を実行すると、カタログ情報が見え、先程登録した`asset-1`と`asset-2`の情報が見えるはず。

`asset-1`の場合は以下のような感じ。

```json
            {
                "@id": "fcc9cefa-c31e-4155-ad59-35294044cc6d",
                "@type": "dcat:Catalog",
                "dcat:dataset": [
                    {
                        "@id": "asset-1",
                        "@type": "dcat:Dataset",
                        "odrl:hasPolicy": {
                            "@id": "bWVtYmVyLWFuZC1kYXRhcHJvY2Vzc29yLWRlZg==:YXNzZXQtMQ==:OThhZGM3OGQtZDM1Ny00MDQwLTlhYmUtYzI3YTIzYTMyNmUz",
                            "@type": "odrl:Offer",
                            "odrl:permission": [],
                            "odrl:prohibition": [],
                            "odrl:obligation": {
                                "odrl:action": {
                                    "@id": "odrl:use"
                                },
                                "odrl:constraint": {
                                    "odrl:leftOperand": {
                                        "@id": "DataAccess.level"
                                    },
                                    "odrl:operator": {
                                        "@id": "odrl:eq"
                                    },
                                    "odrl:rightOperand": "processing"
                                }
                            }
                        },
                        "dcat:distribution": [
                            {
                                "@type": "dcat:Distribution",
                                "dct:format": {
                                    "@id": "HttpData-PULL"
                                },
                                "dcat:accessService": {
                                    "@id": "6cccbc00-9fa5-4f99-a2d9-524d2881f72f",
                                    "@type": "dcat:DataService"
                                }
                            },
                            {
                                "@type": "dcat:Distribution",
                                "dct:format": {
                                    "@id": "HttpData-PUSH"
                                },
                                "dcat:accessService": {
                                    "@id": "6cccbc00-9fa5-4f99-a2d9-524d2881f72f",
                                    "@type": "dcat:DataService"
                                }
                            }
                        ],
                        "description": "This asset requires Membership to view and negotiate.",
                        "id": "asset-1"
                    },
```

README通り、今回はプロバイダのQ&A departmentに着目する。
エンドポイント情報が、上記のアセット情報の直後にあるのを見つける。

```json
                "dcat:service": {
                    "@id": "6cccbc00-9fa5-4f99-a2d9-524d2881f72f",
                    "@type": "dcat:DataService",
                    "dcat:endpointDescription": "dspace:connector",
                    "dcat:endpointUrl": "http://provider-qna-controlplane:8082/api/dsp",
                    "dcat:endpointURL": "http://provider-qna-controlplane:8082/api/dsp"
                },
```
それとアセットのIDを確認しておく、`odrl:hasPolicy.@id`にある。
今回の例だと、

asset-1

```json
                        "@id": "asset-1",
                        "@type": "dcat:Dataset",
                        "odrl:hasPolicy": {
                            "@id": "bWVtYmVyLWFuZC1kYXRhcHJvY2Vzc29yLWRlZg==:YXNzZXQtMQ==:OThhZGM3OGQtZDM1Ny00MDQwLTlhYmUtYzI3YTIzYTMyNmUz",
```

`asset-2` は一旦省略

### コントラクトネゴシエーション

先の手順で確認した、`asset-1`のIDを変数に設定する。（実際には、各自の値を使用すること）

![環境](images/20250119_Postman_Policy_ID.png)

これは、リクエストボディの以下に用いられる。

```json
{
    "@context": [
        "https://w3id.org/edc/connector/management/v0.0.1"
    ],
    "@type": "ContractRequest",
    "counterPartyAddress": "{{PROVIDER_DSP_URL}}/api/dsp",
    "counterPartyId": "{{PROVIDER_ID}}",
    "protocol": "dataspace-protocol-http",
    "policy": {
        "@type": "Offer",
        "@id": "{{POLICY_ID_ASSET_1}}",
        "assigner": "{{PROVIDER_ID}}",
        "permission": [],
        "prohibition": [],
        "obligation": {
            "action": "use",
            "constraint": {
                "leftOperand": "DataAccess.level",
                "operator": "eq",
                "rightOperand": "processing"
            }
        },
        "target": "asset-1"
    },
    "callbackAddresses": []
}
```

続いて、`initiate negotiation`を実行する。

![環境](images/20250119_Postman_Contract_Nego.png)

レスポンスが見られるはず。
ただし、この状態ではまだコントラクトネゴシエーションを開始しただけ。状況確認が必要。

### 状況の確認

続いて、`Get Contract Negotiations`を実行する。

![環境](images/20250119_Postman_Get_ContractNegos.png)

ステータスが`FINALIZED`になっていることがわかる。
今回は、1回実行しただけなので、以下のとおりだが、複数回実行するとそのぶんだけ並ぶ。

```json
[
    {
        "@type": "ContractNegotiation",
        "@id": "378b9249-b869-426f-b224-7879d358d2a1",
        "type": "CONSUMER",
        "protocol": "dataspace-protocol-http",
        "state": "FINALIZED",
        "counterPartyId": "did:web:provider-identityhub%3A7083:provider",
        "counterPartyAddress": "http://provider-qna-controlplane:8082/api/dsp",
        "callbackAddresses": [],
        "createdAt": 1737304019738,
        "contractAgreementId": "59b8c0b1-a9b1-4b83-b85d-715758941595",
        "@context": {
            "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
            "edc": "https://w3id.org/edc/v0.0.1/ns/",
            "odrl": "http://www.w3.org/ns/odrl/2/"
        }
    }
]
```

上記から`contractAgreementId` がわかる。`59b8c0b1-a9b1-4b83-b85d-715758941595`である。
このあとのデータ転送において利用する。

### トランスファーの初期化

`Initiate Transfer`を実行するが、その際のリクエストボディは以下の通り。

```json
{
    "@context": [
        "https://w3id.org/edc/connector/management/v0.0.1"
    ],
    "assetId": "asset-1",
    "counterPartyAddress":  "{{PROVIDER_DSP_URL}}/api/dsp",
    "connectorId": "{{PROVIDER_ID}}",
    "contractId": "{{CONTRACT_AGREEMENT_ID}}",
    "dataDestination": {
        "type": "HttpProxy"
    },
    "protocol": "dataspace-protocol-http",
    "transferType": "HttpData-PULL"
}
```

上記の、`CONTRACT_AGREEMENT_ID`に渡す値を先ほど控えた値に書き換えて、`Initiate Transfer`を実行する。
先程控えておいた値にする。各自の値を使用すること。

![環境](images/20250119_Postman_Init_Trans.png)

戻りは以下のような内容。

```json
{
    "@type": "IdResponse",
    "@id": "0278e81e-5dea-4ab7-876f-60cd8a202e09",
    "createdAt": 1737304134741,
    "@context": {
        "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
        "edc": "https://w3id.org/edc/v0.0.1/ns/",
        "odrl": "http://www.w3.org/ns/odrl/2/"
    }
}
```

これでトランスファーの処理が開始された。ただし、実際のデータ転送が始まったわけではない。
今回は、`HttpData-PULL`プロトコルを用いることになっており、そのためには実際のデータを取得するためのエンドポイントとアクセスキーを取得しないとならない。

### EDR（EndpointDataReference）取得

`Get cached EDRs`を実行する。特に変数設定などは不要。

![環境](images/20250119_Postman_get_EDRs.png)

```json
[
    {
        "@id": "0278e81e-5dea-4ab7-876f-60cd8a202e09",
        "@type": "EndpointDataReferenceEntry",
        "providerId": "did:web:provider-identityhub%3A7083:provider",
        "assetId": "asset-1",
        "agreementId": "59b8c0b1-a9b1-4b83-b85d-715758941595",
        "transferProcessId": "0278e81e-5dea-4ab7-876f-60cd8a202e09",
        "createdAt": 1737304136114,
        "contractNegotiationId": "378b9249-b869-426f-b224-7879d358d2a1",
        "@context": {
            "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
            "edc": "https://w3id.org/edc/v0.0.1/ns/",
            "odrl": "http://www.w3.org/ns/odrl/2/"
        }
    }
]
```

今回は有効なEDRが1個なので上記の通り。
EDRのIDがわかる。`0278e81e-5dea-4ab7-876f-60cd8a202e09`

### アクセストークンの取得

先程確認したEDRのIDを用いて、EDRを取得する。

![環境](images/20250119_Postman_get_EDR.png)

```json
{
    "@type": "DataAddress",
    "type": "https://w3id.org/idsa/v4.1/HTTP",
    "endpoint": "http://provider-qna-dataplane:11002/api/public",
    "authType": "bearer",
    "endpointType": "https://w3id.org/idsa/v4.1/HTTP",
    "authorization": "eyJraWQiOiJkaWQ6d2ViOnByb3ZpZGVyLWlkZW50aXR5aHViJTNBNzA4Mzpwcm92aWRlciNrZXktMSIsImFsZyI6IkVTMjU2In0.eyJpc3MiOiJkaWQ6d2ViOnByb3ZpZGVyLWlkZW50aXR5aHViJTNBNzA4Mzpwcm92aWRlciIsImF1ZCI6ImRpZDp3ZWI6Y29uc3VtZXItaWRlbnRpdHlodWIlM0E3MDgzOmNvbnN1bWVyIiwic3ViIjoiZGlkOndlYjpwcm92aWRlci1pZGVudGl0eWh1YiUzQTcwODM6cHJvdmlkZXIiLCJpYXQiOjE3MzczMDQxMzU3OTQsImp0aSI6IjI3Y2Y0ODFlLTQ5YWYtNDI0YS1iNjc5LTk2YzQ4MmY4ODAyNyJ9.whzgJzBy9ydxontusqowd_wG33KjSfzjxqXxb600csDUdrGHFl45CEQtbRdOfSvffjQTaincEKZpAovS9b2gqg",
    "@context": {
        "@vocab": "https://w3id.org/edc/v0.0.1/ns/",
        "edc": "https://w3id.org/edc/v0.0.1/ns/",
        "odrl": "http://www.w3.org/ns/odrl/2/"
    }
}
```

上記の通り、エンドポイント情報とアクセストークが得られた。

```json
(snip)
    "endpoint": "http://provider-qna-dataplane:11002/api/public",
(snip)
    "authorization": "eyJraWQiOiJkaWQ6d2ViOnByb3ZpZGVyLWlkZW50aXR5aHViJTNBNzA4Mzpwcm92aWRlciNrZXktMSIsImFsZyI6IkVTMjU2In0.eyJpc3MiOiJkaWQ6d2ViOnByb3ZpZGVyLWlkZW50aXR5aHViJTNBNzA4Mzpwcm92aWRlciIsImF1ZCI6ImRpZDp3ZWI6Y29uc3VtZXItaWRlbnRpdHlodWIlM0E3MDgzOmNvbnN1bWVyIiwic3ViIjoiZGlkOndlYjpwcm92aWRlci1pZGVudGl0eWh1YiUzQTcwODM6cHJvdmlkZXIiLCJpYXQiOjE3MzczMDQxMzU3OTQsImp0aSI6IjI3Y2Y0ODFlLTQ5YWYtNDI0YS1iNjc5LTk2YzQ4MmY4ODAyNyJ9.whzgJzBy9ydxontusqowd_wG33KjSfzjxqXxb600csDUdrGHFl45CEQtbRdOfSvffjQTaincEKZpAovS9b2gqg",
(snip)
```

### データの取得

先程確認したトークンを用いてデータを取得する。

![環境](images/20250119_Postman_Get_Data_Token.png)

```json
[
    {
        "userId": 1,
        "id": 1,
        "title": "delectus aut autem",
        "completed": false
    },
    {
        "userId": 1,
        "id": 2,
        "title": "quis ut nam facilis et officia qui",
        "completed": false
    },
    {
        "userId": 1,
        "id": 3,
        "title": "fugiat veniam minus",
        "completed": false
    },
    {
(snip)
```
(wip)

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
