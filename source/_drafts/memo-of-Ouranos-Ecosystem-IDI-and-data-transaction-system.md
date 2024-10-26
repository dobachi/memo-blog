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

## 事業者認証



(wip)


## データ流通システムの様子

データ流通システムの `main.go` を見ると概要がわかる。

このアプリケーションは、[Echo]を使って作られている。

# 参考

* [ouranos-ecosystem-idi / data-transaction-system]
* [Ouranos Ecosystem]
* [README 実行環境]
* [ユーザ認証システム]

[Ouranos Ecosystem]: https://www.meti.go.jp/policy/mono_info_service/digital_architecture/ouranos.html
[ouranos-ecosystem-idi / data-transaction-system]: https://github.com/ouranos-ecosystem-idi/data-transaction-system
[README 実行環境]: https://github.com/ouranos-ecosystem-idi/data-transaction-system?tab=readme-ov-file#%E5%8B%95%E4%BD%9C%E7%A2%BA%E8%AA%8D%E6%B8%88%E3%81%BF%E5%AE%9F%E8%A1%8C%E7%92%B0%E5%A2%83
[ユーザ認証システム]: https://github.com/ouranos-ecosystem-idi/user-authentication-system

[Echo]: https://echo.labstack.com/




<!-- vim: set et tw=0 ts=2 sw=2: -->
