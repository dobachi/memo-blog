---

title: memo of Ouranos Ecosystem IDI and data-transaction-system
date: 2024-10-26 21:41:18
categories:
  - Knowledge Management
  - Data Spaces
  - Ouranos Ecosystem
tags:
  - Data Spaces
  - Ouranos Ecosystem

---

# メモ

[ouranos-ecosystem-idi / data-transaction-system] に [Ouranos Ecosystem] の
オープンソースソフトウェアが公開されている。

このOSSの主旨は、READMEにある通り、

> 本リポジトリ（Minimum Ouranos data platform）は企業・業界・国境を跨いだデータ連携・利活用を目指すイニシアティブの 「ウラノス・エコシステム（Ouranos Ecosystem）」におけるデータ流通システムの最小実装を体験するため、 実装の一部をオープンソースとして公開する。

である。

基本的にはREADMEに書かれている通りなので、特別に補足することはないが、なんとなくメモしておく。

[README 実行環境] に実行環境の情報が記載されている。記載の通り、基本的にはGo言語を用いて実装されている。

なお、以降以下のディレクトリ内に、各種レポジトリをクローンして用いる。

```shell
mkdir -p ~/Sources/ouranos-ecosystem-idi
cd ~/Sources/ouranos-ecosystem-idi
export OE_WORKDIR=~/Sources/ouranos-ecosystem-idi
```

なお、暫定的にワーキングディレクトリを示す便宜的な環境変数を作成しておいた。

## 認証データの構成

[ユーザ認証システム] にレポジトリがあるのでクローンして、認証システムを立ち上げる。

```shell
git clone git@github.com:ouranos-ecosystem-idi/user-authentication-system.git
cd ${OE_WORKDIR}/user-authentication-system/
docker compose up -d
```

docker-compose.ymlの通り、実態はDBMS（postgres）と簡易認証用のfirebaseである。
firebaseではエミュレータを用いる。

エミュレータコンフィグ配下の通り。

```json
{
  "emulators": {
    "auth": {
      "host": "0.0.0.0",
      "port": 9099
    },
    "ui": {
      "enabled": true,
      "host": "0.0.0.0",
      "port": 4000
    },
    "singleProjectMode": true
  }
}
```

データベースのスキーマ定義。

```shell
cd ${OE_WORKDIR}/user-authentication-system/
export POSTGRESQL_URL='postgres://dhuser:passw0rd@localhost:5432/dhlocal?sslmode=disable'
migrate -path setup/migrations -database ${POSTGRESQL_URL} up
```

ダミーデータをDBに入力。

```shell
docker cp setup postgres:/setup
docker exec -it postgres bash /setup/setup_seeds.sh
```

シェルスクリプトは、`setup/seeders` に含まれているSQLを実行するというもの。

```
setup/seeders
setup/seeders/000001_seed_api_keys.sql
setup/seeders/000002_seed_operators.sql
setup/seeders/000003_seed_apikey_operators.sql
setup/seeders/000004_cidrs.sql
```

上記の通り、APIキー、オペレータのIDなどを入力している。2件ずつ。

確認。

```
docker exec -i postgres bash -c "PGPASSWORD=passw0rd psql -h 127.0.0.1 -p 5432 -U dhuser dhlocal -c 'select * from operators'"
```

```
             operator_id              | operator_name | deleted_at |     created_at      | created_user_id |     updated_at      | updated_user_id | operator_address | open_operator_id |  global_operator_id  
--------------------------------------+---------------+------------+---------------------+-----------------+---------------------+-----------------+------------------+------------------+----------------------
 b39e6248-c888-56ca-d9d0-89de1b1adc8e | A社           |            | 2024-03-26 12:00:00 | seed            | 2024-03-26 12:00:00 | seed            | 東京都渋谷区xx   | 1234567890123    | 1234ABCD5678EFGH0123
 15572d1c-ec13-0d78-7f92-dd4278871373 | B社           |            | 2024-03-26 12:00:00 | seed            | 2024-03-26 12:00:00 | seed            | 東京都渋谷区xx   | 1234567890124    | 1234ABCD5678EFGH0124
(2 rows)
```

エミュレータに事業者情報を追加。

```shell
make idp-add-local
```

```
go run cmd/add_local_user/main.go
Successfully created user with email: oem_a@example.com and set custom claims. Password: oemA&user_01
Successfully created user with email: supplier_b@example.com and set custom claims. Password: supplierB&user_01
```

Makefileの中身は以下の通り。

Makefile:78

```makefile
idp-add-local:
	go run cmd/add_local_user/main.go
```

このプログラムは、シード用CSVから事業者情報を登録する。

cmd/add_local_user/main.go:46
```go
func addOperatorFromCSV(ctx context.Context, app *firebase.App, csvPath string) {

(snip)

	// create user by each record
	for _, record := range records {
		email := record[0]
		password := record[1]
		operatorID := record[2]
		operator := Operator{operatorID, email, password}
		addOperator(ctx, authClient, operator)
	}
```

cmd/add_local_user/main.go:76

```go
func addOperator(ctx context.Context, authClient *auth.Client, operator Operator) {

(snip)

	err = authClient.SetCustomUserClaims(ctx, userRecord.UID, customClaims)
```

上記の通り、firebaseのauth.Clientを用いて登録している。

シードは、 `cmd/add_local_user/data/seed.csv` である。

```csv
oem_a@example.com,oemA&user_01,b39e6248-c888-56ca-d9d0-89de1b1adc8e
supplier_b@example.com,supplierB&user_01,15572d1c-ec13-0d78-7f92-dd4278871373
```

OperatorのIDは、先程DBとに登録したものと同じ。

## データ流通システムの起動

ビルド

```shell
cd ${OE_WORKDIR}/data-transaction-system
go build main.go
docker build -t data-spaces-backend .
```

起動

```shell
docker run -v $(pwd)/config/:/app/config/ -td -i --network docker.internal --env-file config/local.env -p 8080:8080 --name data-spaces-backend data-spaces-backend
```

（このあたりはcomposeになっていない…と）

## ユーザ認証システムの起動

ビルド

```shell
cd ${OE_WORKDIR}/user-authentication-system/
go build main.go
docker build -t authenticator-backend .
```

起動

```shell
docker run -v $(pwd)/config/:/app/config/ -td -i --network docker.internal --env-file config/local.env -p 8081:8081 --name authenticator-backend authenticator-backend
```

これで一通り起動したはず。

```shell
docker ps
```

```
CONTAINER ID   IMAGE                                  COMMAND                   CREATED          STATUS                  PORTS                                                                                  NAMES
aa12c592f114   authenticator-backend                  "/app/server"             33 seconds ago   Up 33 seconds           0.0.0.0:8081->8081/tcp, :::8081->8081/tcp                                              authenticator-backend
46c1d0f82cf7   data-spaces-backend                    "/app/server"             3 minutes ago    Up 3 minutes            0.0.0.0:8080->8080/tcp, :::8080->8080/tcp                                              data-spaces-backend
7ccba96acee9   postgres:14                            "docker-entrypoint.s…"   2 hours ago      Up 2 hours              0.0.0.0:5432->5432/tcp, :::5432->5432/tcp                                              postgres
9e5bc7cf81ed   user-authentication-system-firebase    "docker-entrypoint.s…"   2 hours ago      Up 2 hours              0.0.0.0:4000->4000/tcp, :::4000->4000/tcp, 0.0.0.0:9099->9099/tcp, :::9099->9099/tcp   user-authentication-system-firebase-1
```

## A社の事業者認証

[事業者認証]の通り、

> A社がユーザ認証システムで事業者認証をした後に、自身の事業者情報を取得する例を示します。


### 認証情報取得

前提：

- PF認定を受けた事業者に発行されるAPIキーを指定しAPIを利用する
- 事業者はAcountIdとPasswordを事前に払い出されている

認証情報を取得

```shell
curl -s --location --request POST 'http://localhost:8081/auth/login' --header 'Content-Type: application/json' --header 'apiKey: Sample-APIKey1' --data-raw '{
  "operatorAccountId": "oem_a@example.com",
  "accountPassword": "oemA&user_01"
}' | jq
```

```json
{
  "accessToken": "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzMzQ1OSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzM0NTksImV4cCI6MTczMDAzNzA1OSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.",
  "refreshToken": "eyJfQXV0aEVtdWxhdG9yUmVmcmVzaFRva2VuIjoiRE8gTk9UIE1PRElGWSIsImxvY2FsSWQiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDciLCJwcm92aWRlciI6InBhc3N3b3JkIiwiZXh0cmFDbGFpbXMiOnt9LCJwcm9qZWN0SWQiOiJsb2NhbCJ9"
}

```

### 事業者情報取得

先程取得したアクセストークンを使い、事業者情報を取得してみる。
先の例と同様、APIキーも用いる。

```shell
curl -s --location --request GET 'http://localhost:8081/api/v1/authInfo?dataTarget=operator' \
--header 'apiKey: Sample-APIKey1' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzMzQ1OSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzM0NTksImV4cCI6MTczMDAzNzA1OSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.' \
| jq
```

```json
{
  "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
  "operatorName": "A社",
  "operatorAddress": "東京都渋谷区xx",
  "openOperatorId": "1234567890123",
  "operatorAttribute": {
    "globalOperatorId": "1234ABCD5678EFGH0123"
  }
}
```

## A社の部品登録およびB社への回答依頼

[部品登録] にある通り。
事業所登録、親部品情報の作成、部品構成情報の登録、CFP結果提出の依頼（A社=下流・OEMからB社=上流・サプライヤへの依頼）の順番で進める。

### 事業所登録

この時点では、事「業」所が登録されていないので登録する。
`operatorId` は先程取得した事業者情報の値を用いる。`openPlantId`、`plantAddress`、`plantNae`は任意の値。
`plantId`はNullで渡す。


```shell
curl -s --location --request PUT 'http://localhost:8081/api/v1/authInfo?dataTarget=plant' \
--header 'apiKey: Sample-APIKey1' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzMzQ1OSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzM0NTksImV4cCI6MTczMDAzNzA1OSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.' \
--data '{
  "openPlantId": "1234567890123012345",
  "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
  "plantAddress": "xx県xx市xxxx町1-1-1234",
  "plantId": null,
  "plantName": "A工場",
  "plantAttribute": {}
}' \
| jq
```

```json
{
  "plantId": "4c110e31-46a3-48d9-89d3-afdefcfcb7dc",
  "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
  "plantName": "A工場",
  "plantAddress": "xx県xx市xxxx町1-1-1234",
  "openPlantId": "1234567890123012345",
  "plantAttribute": {
    "globalPlantId": null
  }
}
```

結果中の、`plantId`が埋まっていることがわかる。

また、APIが`/v1/authInfo`であることも注意。

### 親部品情報の作成

事業所を登録できたので、その情報を使って親部品情報を登録する。
`plantId`は先程の戻り値に含まれていたものを利用。
`traceId`はNullで渡す。

```shell
curl -s --location --request PUT 'http://localhost:8080/api/v1/datatransport?dataTarget=parts' \
--header 'apiKey: Sample-APIKey1' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzMzQ1OSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzM0NTksImV4cCI6MTczMDAzNzA1OSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.' \
--data '{
  "amountRequired": null,
  "amountRequiredUnit": "kilogram",
  "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
  "partsName": "部品A",
  "plantId": "4c110e31-46a3-48d9-89d3-afdefcfcb7dc",
  "supportPartsName": "modelA",
  "terminatedFlag": false,
  "traceId": null
}' \
| jq
```

```json
{
  "traceId": "675b19a3-380e-45d6-921f-38aad289e0d5",
  "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
  "plantId": "4c110e31-46a3-48d9-89d3-afdefcfcb7dc",
  "partsName": "部品A",
  "supportPartsName": "modelA",
  "terminatedFlag": false,
  "amountRequired": null,
  "amountRequiredUnit": "kilogram"
}
```

`traceId`が含まれた値が返ってきた。

### 部品構成情報の登録

親部品の登録が終わり、親部品の`traceId`も払い出されたので、その情報を使って、子部品を登録する。
この時点で子部品の`traceId`はNullだが、戻り値に含まれていることがわかる。

```shell
curl -s --location --request PUT 'http://localhost:8080/api/v1/datatransport?dataTarget=partsStructure' \
--header 'apiKey: Sample-APIKey1' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzMzQ1OSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzM0NTksImV4cCI6MTczMDAzNzA1OSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.' \
--data '{
  "parentPartsModel": {
    "amountRequired": null,
    "amountRequiredUnit": "kilogram",
    "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
    "partsName": "部品A",
    "plantId": "4c110e31-46a3-48d9-89d3-afdefcfcb7dc",
    "supportPartsName": "modelA",
    "terminatedFlag": false,
    "traceId": "8fc6aa29-5f4f-476e-85e3-2d1b54715891"
  },
  "childrenPartsModel": [
    {
      "amountRequired": 5,
      "amountRequiredUnit": "kilogram",
      "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
      "partsName": "部品A1",
      "plantId": "4c110e31-46a3-48d9-89d3-afdefcfcb7dc",
      "supportPartsName": "modelA-1",
      "terminatedFlag": false,
      "traceId": null
    }
  ]
}' \
| jq
```


```json
{
  "parentPartsModel": {
    "traceId": "8fc6aa29-5f4f-476e-85e3-2d1b54715891",
    "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
    "plantId": "4c110e31-46a3-48d9-89d3-afdefcfcb7dc",
    "partsName": "部品A",
    "supportPartsName": "modelA",
    "terminatedFlag": false,
    "amountRequired": null,
    "amountRequiredUnit": "kilogram"
  },
  "childrenPartsModel": [
    {
      "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
      "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
      "plantId": "4c110e31-46a3-48d9-89d3-afdefcfcb7dc",
      "partsName": "部品A1",
      "supportPartsName": "modelA-1",
      "terminatedFlag": false,
      "amountRequired": 5,
      "amountRequiredUnit": "kilogram"
    }
  ]
}
```
### CFP結果提出の依頼（AからBに）

`/v1/authInfo` APIを用いて、まずはB社の事業者識別子（内部）を取得する。
`openOperatorId` （事業者識別子（公開））は事前に知っているものとする。


```shell
curl -s --location --request GET 'http://localhost:8081/api/v1/authInfo?dataTarget=operator&openOperatorId=1234567890124' \
--header 'apiKey: Sample-APIKey1' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzMzQ1OSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzM0NTksImV4cCI6MTczMDAzNzA1OSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.' \
| jq
```

```json
{
  "operatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
  "operatorName": "B社",
  "operatorAddress": "東京都渋谷区xx",
  "openOperatorId": "1234567890124",
  "operatorAttribute": {
    "globalOperatorId": "1234ABCD5678EFGH0124"
  }
}
```

続いて、A社からB社に対しての取引関係を作成し、紐付け回答依頼を行う。
`downstreamTraceId`には先に取得しておいた、下流（つまり、A社 = OEM側）のもつ`traceId`を指定する。先ほど作った親子関係のうち、子部品（つまり、上流由来の部品）のIDを指定する。

```shell
curl -s --location --request PUT 'http://localhost:8080/api/v1/datatransport?dataTarget=tradeRequest' \
--header 'apiKey: Sample-APIKey1' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzMzQ1OSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzM0NTksImV4cCI6MTczMDAzNzA1OSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.' \
--data '{
  "statusModel": {
    "message": "来月中にご回答をお願いします。",
    "replyMessage": null,
    "requestStatus": {},
    "requestType": "CFP",
    "statusId": null,
    "tradeId": null
  },
  "tradeModel": {
    "downstreamOperatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
    "downstreamTraceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
    "tradeId": null,
    "upstreamOperatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
    "upstreamTraceId": null
  }
}' \
| jq
```

```json
{
  "tradeModel": {
    "tradeId": "aeb60293-2477-4f58-94ac-8b24cb32103f",
    "downstreamOperatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
    "upstreamOperatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
    "downstreamTraceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
    "upstreamTraceId": null
  },
  "statusModel": {
    "statusId": "a6e4a7f2-bb5c-4414-8026-75a46ea4436d",
    "tradeId": "aeb60293-2477-4f58-94ac-8b24cb32103f",
    "requestStatus": {
      "cfpResponseStatus": "NOT_COMPLETED",
      "tradeTreeStatus": "UNTERMINATED"
    },
    "message": "来月中にご回答をお願いします。",
    "replyMessage": null,
    "requestType": "CFP"
  }
}
```

リクエスト時はNullだった、`statusId`、`tradeId`が返ってきていることがわかる。（`traceId`と`tradeId`が紛らわしいので注意）

## B社の部品登録紐付け

[部品登録紐付け]の通り。
おおむね、B社の事業者認証（アクセストークン取得）、B社の事業所情報の登録、B社親部品登録、紐付け以来の確認、部品登録紐付けの登録、の流れ。

### 事業社認証

A社のときと同じく、B社においても認証情報を取得する。

```shell
curl -s --location --request POST 'http://localhost:8081/auth/login' \
--header 'Content-Type: application/json' \
--header 'apiKey: Sample-APIKey1' \
--data-raw '{
  "operatorAccountId": "supplier_b@example.com",
  "accountPassword": "supplierB&user_01"
}' \
| jq
```

```json
{
  "accessToken": "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6IjE1NTcyZDFjLWVjMTMtMGQ3OC03ZjkyLWRkNDI3ODg3MTM3MyIsImVtYWlsIjoic3VwcGxpZXJfYkBleGFtcGxlLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiYXV0aF90aW1lIjoxNzMwMDM1ODMwLCJ1c2VyX2lkIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3IiwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJzdXBwbGllcl9iQGV4YW1wbGUuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifSwiaWF0IjoxNzMwMDM1ODMwLCJleHAiOjE3MzAwMzk0MzAsImF1ZCI6ImxvY2FsIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2xvY2FsIiwic3ViIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3In0.",
  "refreshToken": "eyJfQXV0aEVtdWxhdG9yUmVmcmVzaFRva2VuIjoiRE8gTk9UIE1PRElGWSIsImxvY2FsSWQiOiJjN2FlOGYzZS1jZDhjLTRkOTUtOGE2NC02ZjRjYjJlZGQxYTciLCJwcm92aWRlciI6InBhc3N3b3JkIiwiZXh0cmFDbGFpbXMiOnt9LCJwcm9qZWN0SWQiOiJsb2NhbCJ9"
}
```

### 事業所の登録

A社のときと同じく、B社においても事業「所」情報を登録する。

```shell
curl -s --location --request PUT 'http://localhost:8081/api/v1/authInfo?dataTarget=plant' \
--header 'apiKey: Sample-APIKey1' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6IjE1NTcyZDFjLWVjMTMtMGQ3OC03ZjkyLWRkNDI3ODg3MTM3MyIsImVtYWlsIjoic3VwcGxpZXJfYkBleGFtcGxlLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiYXV0aF90aW1lIjoxNzMwMDM1ODMwLCJ1c2VyX2lkIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3IiwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJzdXBwbGllcl9iQGV4YW1wbGUuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifSwiaWF0IjoxNzMwMDM1ODMwLCJleHAiOjE3MzAwMzk0MzAsImF1ZCI6ImxvY2FsIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2xvY2FsIiwic3ViIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3In0.' \
--data '{
  "openPlantId": "1234567890124012345",
  "operatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
  "plantAddress": "xx県xx市xxxx町2-1-1234",
  "plantId": null,
  "plantName": "B工場",
  "plantAttribute": {}
}' \
| jq
```

```json
{
  "plantId": "2dbe5ede-0140-4a47-8bf7-3ab3947866c7",
  "operatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
  "plantName": "B工場",
  "plantAddress": "xx県xx市xxxx町2-1-1234",
  "openPlantId": "1234567890124012345",
  "plantAttribute": {
    "globalPlantId": null
  }
}
```

リクエストのときはNullだった、`plantId`が返っていることがわかる。

### 親部品情報の作成

A社のときと同じく、親部品情報を作成する。
認証トークンと`plantId`は先程取得したものを用いること。

```shell
curl -s --location --request PUT 'http://localhost:8080/api/v1/datatransport?dataTarget=parts' \
--header 'apiKey: Sample-APIKey1' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6IjE1NTcyZDFjLWVjMTMtMGQ3OC03ZjkyLWRkNDI3ODg3MTM3MyIsImVtYWlsIjoic3VwcGxpZXJfYkBleGFtcGxlLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiYXV0aF90aW1lIjoxNzMwMDM1ODMwLCJ1c2VyX2lkIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3IiwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJzdXBwbGllcl9iQGV4YW1wbGUuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifSwiaWF0IjoxNzMwMDM1ODMwLCJleHAiOjE3MzAwMzk0MzAsImF1ZCI6ImxvY2FsIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2xvY2FsIiwic3ViIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3In0.' \
--data '{
  "amountRequired": null,
  "amountRequiredUnit": "kilogram",
  "operatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
  "partsName": "部品B",
  "plantId": "2dbe5ede-0140-4a47-8bf7-3ab3947866c7",
  "supportPartsName": "modelB",
  "terminatedFlag": true,
  "traceId": null
}' \
| jq
```

```json
{
  "traceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f",
  "operatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
  "plantId": "2dbe5ede-0140-4a47-8bf7-3ab3947866c7",
  "partsName": "部品B",
  "supportPartsName": "modelB",
  "terminatedFlag": true,
  "amountRequired": null,
  "amountRequiredUnit": "kilogram"
}
```

リクエスト時はNullだった`traceId`が返っていることがわかる。

### 紐付け依頼確認

今回は、予めA社（OEM、下流）から回答依頼を送っているのだが、改めてB社（サプライヤ、上流）側で依頼を確認する。

```shell
curl -s --location --request GET 'http://localhost:8080/api/v1/datatransport?dataTarget=tradeResponse' \
--header 'apiKey: Sample-APIKey1' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6IjE1NTcyZDFjLWVjMTMtMGQ3OC03ZjkyLWRkNDI3ODg3MTM3MyIsImVtYWlsIjoic3VwcGxpZXJfYkBleGFtcGxlLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiYXV0aF90aW1lIjoxNzMwMDM1ODMwLCJ1c2VyX2lkIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3IiwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJzdXBwbGllcl9iQGV4YW1wbGUuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifSwiaWF0IjoxNzMwMDM1ODMwLCJleHAiOjE3MzAwMzk0MzAsImF1ZCI6ImxvY2FsIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2xvY2FsIiwic3ViIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3In0.' \
| jq
```

```json
[
 {
    "statusModel": {
      "statusId": "a6e4a7f2-bb5c-4414-8026-75a46ea4436d",
      "tradeId": "aeb60293-2477-4f58-94ac-8b24cb32103f",
      "requestStatus": {
        "cfpResponseStatus": "NOT_COMPLETED",
        "tradeTreeStatus": "UNTERMINATED"
      },
      "message": "来月中にご回答をお願いします。",
      "replyMessage": null,
      "requestType": "CFP"
    },
    "tradeModel": {
      "tradeId": "aeb60293-2477-4f58-94ac-8b24cb32103f",
      "downstreamOperatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
      "upstreamOperatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
      "downstreamTraceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
      "upstreamTraceId": null
    },
    "partsModel": {
      "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
      "operatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
      "plantId": "4c110e31-46a3-48d9-89d3-afdefcfcb7dc",
      "partsName": "部品A",
      "supportPartsName": "modelA",
      "terminatedFlag": false,
      "amountRequired": null,
      "amountRequiredUnit": "kilogram"
    }
  }
]
```

`statusId`や`tradeId`が先程A社側で見たものと同じであることがわかる。

### 部品登録紐付けの登録

依頼に回答する。APIのパラメータ`tradeId`と`traceId`には、先程取得した依頼回答にあった値を用いる。つまり、`traddeId`は依頼回答一覧似合ったものを用いる。`traceId`には、先程B社側で作成した親部品情報を用いる。（A社側の値ではないことに注意）

```shell
curl -s --location --request PUT 'http://localhost:8080/api/v1/datatransport?dataTarget=tradeResponse&tradeId=aeb60293-2477-4f58-94ac-8b24cb32103f&traceId=28410c0f-1796-4d1b-b30b-db4aa4b8d28f' \
--header 'apiKey: Sample-APIKey1' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6IjE1NTcyZDFjLWVjMTMtMGQ3OC03ZjkyLWRkNDI3ODg3MTM3MyIsImVtYWlsIjoic3VwcGxpZXJfYkBleGFtcGxlLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiYXV0aF90aW1lIjoxNzMwMDM1ODMwLCJ1c2VyX2lkIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3IiwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJzdXBwbGllcl9iQGV4YW1wbGUuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifSwiaWF0IjoxNzMwMDM1ODMwLCJleHAiOjE3MzAwMzk0MzAsImF1ZCI6ImxvY2FsIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2xvY2FsIiwic3ViIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3In0.' \
| jq
```

```json
{
  "tradeId": "aeb60293-2477-4f58-94ac-8b24cb32103f",
  "downstreamOperatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
  "upstreamOperatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
  "downstreamTraceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
  "upstreamTraceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f"
}
```

以上で、A社とB社の間で異なる部品情報を持ったまま、それらをつなぐ関係情報が作成された。

## B社のCFP情報の伝達

[CFP情報伝達]の通り。B社が登録する。
手順書に記載があるが、ここで登録するCFP値は、アプリケーション側で自社の利用する算出されたものを登録する、という前提になっている。

`traceId`には、先程作成したB社側の親部品情報の値を用いる。

なお、本来の実装では、この作業を実施後に、A社に対してCFP情報、DQR情報を開示する手順があるのだが、本記事で紹介している手順では自動で許可されるようになっている。

```shell
curl -s --location --request PUT 'http://localhost:8080/api/v1/datatransport?dataTarget=cfp' \
--header 'apiKey: Sample-APIKey1' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6IjE1NTcyZDFjLWVjMTMtMGQ3OC03ZjkyLWRkNDI3ODg3MTM3MyIsImVtYWlsIjoic3VwcGxpZXJfYkBleGFtcGxlLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiYXV0aF90aW1lIjoxNzMwMDM1ODMwLCJ1c2VyX2lkIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3IiwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJzdXBwbGllcl9iQGV4YW1wbGUuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifSwiaWF0IjoxNzMwMDM1ODMwLCJleHAiOjE3MzAwMzk0MzAsImF1ZCI6ImxvY2FsIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2xvY2FsIiwic3ViIjoiYzdhZThmM2UtY2Q4Yy00ZDk1LThhNjQtNmY0Y2IyZWRkMWE3In0.' \
--data '[
  {
    "cfpId": null,
    "traceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f",
    "ghgEmission": 1.5,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "preProduction",
    "dqrType": "preProcessing",
    "dqrValue": {
      "TeR": 1,
      "GeR": 2,
      "TiR": 3
    }
  },
  {
    "cfpId": null,
    "traceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f",
    "ghgEmission": 10.0,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "mainProduction",
    "dqrType": "mainProcessing",
    "dqrValue": {
      "TeR": 2,
      "GeR": 3,
      "TiR": 4
    }
  },
  {
    "cfpId": null,
    "traceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f",
    "ghgEmission": 0,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "preComponent",
    "dqrType": "preProcessing",
    "dqrValue": {
      "TeR": 1,
      "GeR": 2,
      "TiR": 3
    }
  },
  {
    "cfpId": null,
    "traceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f",
    "ghgEmission": 0,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "mainComponent",
    "dqrType": "mainProcessing",
    "dqrValue": {
      "TeR": 2,
      "GeR": 3,
      "TiR": 4
    }
  }
]' \
| jq
```

```json
[
  {
    "cfpId": "2b289894-846f-4563-916f-0c238aa5216f",
    "traceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f",
    "ghgEmission": 1.5,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "preProduction",
    "dqrType": "preProcessing",
    "dqrValue": {
      "TeR": 1,
      "GeR": 2,
      "TiR": 3
    }
  },
  {
    "cfpId": "2b289894-846f-4563-916f-0c238aa5216f",
    "traceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f",
    "ghgEmission": 10,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "mainProduction",
    "dqrType": "mainProcessing",
    "dqrValue": {
      "TeR": 2,
      "GeR": 3,
      "TiR": 4
    }
  },
  {
    "cfpId": "2b289894-846f-4563-916f-0c238aa5216f",
    "traceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f",
    "ghgEmission": 0,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "preComponent",
    "dqrType": "preProcessing",
    "dqrValue": {
      "TeR": 1,
      "GeR": 2,
      "TiR": 3
    }
  },
  {
    "cfpId": "2b289894-846f-4563-916f-0c238aa5216f",
    "traceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f",
    "ghgEmission": 0,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "mainComponent",
    "dqrType": "mainProcessing",
    "dqrValue": {
      "TeR": 2,
      "GeR": 3,
      "TiR": 4
    }
  }
]
```

## A社における回答取得

[回答取得] の通り。
A社側で、B社の回答を取得する。

### 回答依頼情報の取得

タイムアウトしてトークンが無効になっているかもしれないので、認証情報を取得

```shell
curl -s --location --request POST 'http://localhost:8081/auth/login' --header 'Content-Type: application/json' --header 'apiKey: Sample-APIKey1' --data-raw '{
  "operatorAccountId": "oem_a@example.com",
  "accountPassword": "oemA&user_01"
}' | jq
```

```json
{
  "accessToken": "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzODQ1NSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzg0NTUsImV4cCI6MTczMDA0MjA1NSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.",
  "refreshToken": "eyJfQXV0aEVtdWxhdG9yUmVmcmVzaFRva2VuIjoiRE8gTk9UIE1PRElGWSIsImxvY2FsSWQiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDciLCJwcm92aWRlciI6InBhc3N3b3JkIiwiZXh0cmFDbGFpbXMiOnt9LCJwcm9qZWN0SWQiOiJsb2NhbCJ9"
}
```

取得したアクセストークンを使いつつ、回答情報を取得。

```shell
curl -s --location --request GET 'http://localhost:8080/api/v1/datatransport?dataTarget=tradeRequest' \
--header 'apiKey: Sample-APIKey1' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzODQ1NSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzg0NTUsImV4cCI6MTczMDA0MjA1NSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.' \
| jq
```

```json
[
  {
    "tradeId": "aeb60293-2477-4f58-94ac-8b24cb32103f",
    "downstreamOperatorId": "b39e6248-c888-56ca-d9d0-89de1b1adc8e",
    "upstreamOperatorId": "15572d1c-ec13-0d78-7f92-dd4278871373",
    "downstreamTraceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
    "upstreamTraceId": "28410c0f-1796-4d1b-b30b-db4aa4b8d28f"
  }
]
```

### 依頼情報のステータス確認

* `statusTarget=REQUEST` ... A社が依頼元のステータスのみ取得
* `traceId` ... A社がB社に依頼している自社のtraceId（子部品のID）を指定する。

```shell
curl -s --location --request GET 'http://localhost:8080/api/v1/datatransport?dataTarget=status&statusTarget=REQUEST&traceId=c6e15178-90ed-4605-ad69-2abebae7d18a' \
--header 'apiKey: Sample-APIKey1' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzODQ1NSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzg0NTUsImV4cCI6MTczMDA0MjA1NSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.' \
| jq
```

```json
[
  {
    "statusId": "a6e4a7f2-bb5c-4414-8026-75a46ea4436d",
    "tradeId": "aeb60293-2477-4f58-94ac-8b24cb32103f",
    "requestStatus": {
      "cfpResponseStatus": "COMPLETED",
      "tradeTreeStatus": "TERMINATED"
    },
    "message": "来月中にご回答をお願いします。",
    "replyMessage": null,
    "requestType": "CFP"
  }
]
```

## A社において完成品のCFP値を算出する

[完成品CFP値]の通り。
本来は、アプリケーションにてCFPを計算する。
`traceId`には、A社側の子部品の`traceId`を指定する。

```shell
curl -s --location --request PUT 'http://localhost:8080/api/v1/datatransport?dataTarget=cfp' \
--header 'apiKey: Sample-APIKey1' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJvcGVyYXRvcl9pZCI6ImIzOWU2MjQ4LWM4ODgtNTZjYS1kOWQwLTg5ZGUxYjFhZGM4ZSIsImVtYWlsIjoib2VtX2FAZXhhbXBsZS5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImF1dGhfdGltZSI6MTczMDAzODQ1NSwidXNlcl9pZCI6IjhmMDVmZWY1LWE3ZGEtNGVjMS1iY2FjLTMyNTIwMzM0ODVkNyIsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsib2VtX2FAZXhhbXBsZS5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9LCJpYXQiOjE3MzAwMzg0NTUsImV4cCI6MTczMDA0MjA1NSwiYXVkIjoibG9jYWwiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vbG9jYWwiLCJzdWIiOiI4ZjA1ZmVmNS1hN2RhLTRlYzEtYmNhYy0zMjUyMDMzNDg1ZDcifQ.' \
--data '[
    {
        "cfpId": null,
        "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
        "ghgEmission": 3.0,
        "ghgDeclaredUnit": "kgCO2e/kilogram",
        "cfpType": "preProduction",
        "dqrType": "preProcessing",
        "dqrValue": {
            "TeR": 1,
            "GeR": 2,
            "TiR": 3
        }
    },
    {
        "cfpId": null,
        "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
        "ghgEmission": 20.0,
        "ghgDeclaredUnit": "kgCO2e/kilogram",
        "cfpType": "mainProduction",
        "dqrType": "mainProcessing",
        "dqrValue": {
            "TeR": 2,
            "GeR": 3,
            "TiR": 4
        }
    },
    {
        "cfpId": null,
        "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
        "ghgEmission": 0,
        "ghgDeclaredUnit": "kgCO2e/kilogram",
        "cfpType": "preComponent",
        "dqrType": "preProcessing",
        "dqrValue": {
            "TeR": 1,
            "GeR": 2,
            "TiR": 3
        }
    },
    {
        "cfpId": null,
        "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
        "ghgEmission": 0,
        "ghgDeclaredUnit": "kgCO2e/kilogram",
        "cfpType": "mainComponent",
        "dqrType": "mainProcessing",
        "dqrValue": {
            "TeR": 2,
            "GeR": 3,
            "TiR": 4
        }
    }
]' \
| jq
```

```json
[
  {
    "cfpId": "b626d92e-e6e3-4769-98d1-1ff8b6714230",
    "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
    "ghgEmission": 3,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "preProduction",
    "dqrType": "preProcessing",
    "dqrValue": {
      "TeR": 1,
      "GeR": 2,
      "TiR": 3
    }
  },
  {
    "cfpId": "b626d92e-e6e3-4769-98d1-1ff8b6714230",
    "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
    "ghgEmission": 20,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "mainProduction",
    "dqrType": "mainProcessing",
    "dqrValue": {
      "TeR": 2,
      "GeR": 3,
      "TiR": 4
    }
  },
  {
    "cfpId": "b626d92e-e6e3-4769-98d1-1ff8b6714230",
    "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
    "ghgEmission": 0,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "preComponent",
    "dqrType": "preProcessing",
    "dqrValue": {
      "TeR": 1,
      "GeR": 2,
      "TiR": 3
    }
  },
  {
    "cfpId": "b626d92e-e6e3-4769-98d1-1ff8b6714230",
    "traceId": "c6e15178-90ed-4605-ad69-2abebae7d18a",
    "ghgEmission": 0,
    "ghgDeclaredUnit": "kgCO2e/kilogram",
    "cfpType": "mainComponent",
    "dqrType": "mainProcessing",
    "dqrValue": {
      "TeR": 2,
      "GeR": 3,
      "TiR": 4
    }
  }
]
```

(wip)


## データ流通システムの様子

データ流通システムの `main.go` を見ると概要がわかる。

このアプリケーションは、[Echo]を使って作られている。

### Routerの様子

APIは単純で、`/api/v1/datatransport`のGETとPUTのみ。

presentation/http/echo/router/router.go:39

```go
	e.GET("/api/v1/datatransport", func(c echo.Context) error { return h.GetOuranos(c) })
	e.PUT("/api/v1/datatransport", func(c echo.Context) error { return h.PutOuranos(c) })
```

### 部品情報登録のハンドラー

`h`は`handler.AppHandler`なのだが、以下の通り。

```go
// appHandler
// Summary: This is structure which defines appHandler.
type appHandler struct {
	handler.AuthHandler
	handler.OuranosHandler
}
```

`AuthHandler`は名前の通り、認証関連。APIキーやトークンの処理。

presentation/http/echo/handler/auth_handler.go:10

```go
	AuthHandler interface {
		VerifyAPIKey(c echo.Context) error
		VerifyToken(c echo.Context) (*string, error)
	}
```

`OuranosHandler`がデータのやり取りのためのハンドラーであり、GET/PUTを扱う。
ハンドラーの定義は以下の通り。

presentation/http/echo/handler/ouranos_handler.go:5

```go
type (
	OuranosHandler interface {
		GetOuranos(c echo.Context) error
		PutOuranos(c echo.Context) error
	}

	ouranosHandler struct {
		cfpHandler              ICfpHandler
		cfpCertificationHandler ICfpCertificationHandler
		partsHandler            IPartsHandler
		partsStructureHandler   IPartsStructureHandler
		tradeHandler            ITradeHandler
		statusHandler           IStatusHandler
	}
)
```

`PutOuranos`を見てみる。

presentation/http/echo/handler/ouranos_put.go:15

```go
func (h *ouranosHandler) PutOuranos(c echo.Context) error {
	method := c.Request().Method
	operatorID := c.Get("operatorID").(string)

	dataTarget := c.QueryParam("dataTarget")

	switch dataTarget {
	case "partsStructure":
		return h.partsStructureHandler.PutPartsStructureModel(c)
	case "parts":
		return h.partsHandler.PutPartsModel(c)
	case "tradeRequest":
		return h.tradeHandler.PutTradeRequest(c)
	case "tradeResponse":
		return h.tradeHandler.PutTradeResponse(c)
	case "cfp":
		return h.cfpHandler.PutCfp(c)
	case "status":
		return h.statusHandler.PutStatus(c)
	default:
		errDetails := common.UnexpectedQueryParameter("dataTarget")
		return echo.NewHTTPError(common.HTTPErrorGenerate(http.StatusBadRequest, common.HTTPErrorSourceDataspace, common.Err400InvalidRequest, operatorID, dataTarget, method, errDetails))
	}
}
```

`dataTarget`の中身によって処理を変える。
例えば、親部品作成時には、`parts`が呼ばれていた。
インターフェース定義は以下。

presentation/http/echo/handler/ouranos_traceability_parts.go:18

```go
type IPartsHandler interface {
	// GetPartsModel
	// Summary: This is function which defines #8 GetPartsList.
	GetPartsModel(c echo.Context) error
	// PutPartsModel
	// Summary: This is function which defines #5 PutPartsItem.
	PutPartsModel(c echo.Context) error
}
```

`PutPartsModel`の実装が以下。

presentation/http/echo/handler/ouranos_traceability_parts.go:144

```go
func (h *partsHandler) PutPartsModel(c echo.Context) error {

	dataTarget := c.QueryParam("dataTarget")
	method := c.Request().Method

	operatorID := c.Get("operatorID").(string)

(snip)
```

最初に`operatorID`を取得している。

続いて入力を取得。

presentation/http/echo/handler/ouranos_traceability_parts.go:151

```go
	if err := c.Bind(&putPartsInput); err != nil {
		logger.Set(c).Warnf(err.Error())
		errDetails := common.FormatBindErrMsg(err)

		return echo.NewHTTPError(common.HTTPErrorGenerate(http.StatusBadRequest, common.HTTPErrorSourceDataspace, common.Err400Validation, operatorID, dataTarget, method, errDetails))
	}
	fmt.Printf("PutPartsInput: %+v\n", putPartsInput)
```

domain/model/traceability/ouranos_parts_model.go:138

```go
type PutPartsInput struct {
	OperatorID         string   `json:"operatorId"`
	TraceID            *string  `json:"traceId"`
	PlantID            string   `json:"plantId"`
	PartsName          string   `json:"partsName"`
	SupportPartsName   *string  `json:"supportPartsName"`
	TerminatedFlag     *bool    `json:"terminatedFlag"`
	AmountRequired     *float64 `json:"amountRequired"`
	AmountRequiredUnit *string  `json:"amountRequiredUnit"`
}
```

バリデーション。

presentation/http/echo/handler/ouranos_traceability_parts.go:159

```go
	if err := putPartsInput.Validate(); err != nil {
		logger.Set(c).Warnf(err.Error())
		errDetails := err.Error()

		return echo.NewHTTPError(common.HTTPErrorGenerate(http.StatusBadRequest, common.HTTPErrorSourceDataspace, common.Err400Validation, operatorID, dataTarget, method, errDetails))
	}
	if operatorID != putPartsInput.OperatorID {
		logger.Set(c).Warnf(common.Err403AccessDenied)

		return echo.NewHTTPError(common.HTTPErrorGenerate(http.StatusForbidden, common.HTTPErrorSourceDataspace, common.Err403AccessDenied, operatorID, dataTarget, method))
	}
```

パーツのモデルを作成。

```go
	partsModel, err := putPartsInput.ToModel()
	if err != nil {
		logger.Set(c).Warnf(err.Error())
		errDetails := err.Error()

		return echo.NewHTTPError(common.HTTPErrorGenerate(http.StatusBadRequest, common.HTTPErrorSourceDataspace, common.Err400Validation, operatorID, dataTarget, method, errDetails))
	}
	var partsStructureModel = traceability.PartsStructureModel{
		ParentPartsModel: &partsModel,
	}
	fmt.Printf("PutParts: PartsStructureModel: %+v\n", partsStructureModel)
```

パーツモデルをPut。

presentation/http/echo/handler/ouranos_traceability_parts.go:183

```go
	res, err := h.partsStructureUsecase.PutPartsStructure(c, partsStructureModel)
```

`PUtPartsStructure`の実装のひとつは以下。

usecase/parts_structure_usecase_datastore_impl.go:55

```go
func (u *partsStructureUsecase) PutPartsStructure(c echo.Context, partsStructureModel traceability.PartsStructureModel) (traceability.PartsStructureModel, error) {

	partsStructure, err := u.OuranosRepository.PutPartsStructure(partsStructureModel)
	if err != nil {
		logger.Set(c).Errorf(err.Error())
		return traceability.PartsStructureModel{}, err
	}
	partsStructureModels, err := partsStructure.ToModel()
	if err != nil {
		logger.Set(c).Errorf(err.Error())

		return traceability.PartsStructureModel{}, err
	}
	return partsStructureModels, nil
}
```

もうひとつは、

usecase/parts_structure_usecase_traceability_impl.go:61

```go
func (u *partsStructureTraceabilityUsecase) PutPartsStructure(c echo.Context, partsStructureModel traceability.PartsStructureModel) (traceability.PartsStructureModel, error) {

(snip)
```

# 参考

* [ouranos-ecosystem-idi / data-transaction-system]
* [Ouranos Ecosystem]
* [README 実行環境]
* [ユーザ認証システム]
* [事業者認証]
* [部品登録紐付け]
* [CFP情報伝達]
* [回答取得]
* [完成品CFP値]

[Ouranos Ecosystem]: https://www.meti.go.jp/policy/mono_info_service/digital_architecture/ouranos.html
[ouranos-ecosystem-idi / data-transaction-system]: https://github.com/ouranos-ecosystem-idi/data-transaction-system
[README 実行環境]: https://github.com/ouranos-ecosystem-idi/data-transaction-system?tab=readme-ov-file#%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D%E6%B8%88%E3%81%BF%E5%AE%9F%E8%A1%8C%E7%92%B0%E5%A2%83
[ユーザ認証システム]: https://github.com/ouranos-ecosystem-idi/user-authentication-system
[事業者認証]: https://github.com/ouranos-ecosystem-idi/data-transaction-system/blob/main/docs/tutorials/OperatorIdentification.md
[部品登録]: https://github.com/ouranos-ecosystem-idi/data-transaction-system/blob/main/docs/tutorials/MakePartsStructureAndMakeTradeRequest.md
[部品登録紐付け]: https://github.com/ouranos-ecosystem-idi/data-transaction-system/blob/main/docs/tutorials/MakeTradeResponse.md
[CFP情報伝達]: https://github.com/ouranos-ecosystem-idi/data-transaction-system/blob/main/docs/tutorials/ResponseCFP.md
[回答取得]: https://github.com/ouranos-ecosystem-idi/data-transaction-system/blob/main/docs/tutorials/GetResponseAndMakeCFPReport.md
[完成品CFP値]: https://github.com/ouranos-ecosystem-idi/data-transaction-system/blob/main/docs/tutorials/GetResponseAndMakeCFPReport.md

* [Echo]

[Echo]: https://echo.labstack.com/




<!-- vim: set et tw=0 ts=2 sw=2: -->
