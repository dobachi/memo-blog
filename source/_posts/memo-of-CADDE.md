---

title: memo of CADDE
date: 2024-10-21 00:03:15
categories:
  - Knowledge Management
  - Dataspace Connector
  - CADDE
tags:
  - Connector
  - Data Space

---

# メモ

[CADDE-sip/connector] のREADMEを読んでメモする。


## 前提

[CADDE-sip/connector/README 前提条件] に色々書いてある。

```
カタログ検索、データ交換、認証、認可、来歴、契約の機能を具備します。
```

これらの機能を利用するためのAPIを具備している、くらいの読み方の方が良いかも。

## 導入ガイドライン

[CADDE-sip/connector/README 導入ガイドライン] にドキュメントの置き場所が書いてある。
このあたりは、先に読んでおいたほうが良いだろう。

## 利用者コネクタ

[CADDE-sip/connector/README 利用者コネクタの構築手順] の通り、クローンしたレポジトリの `src/consumer/` 内に
利用者コネクタのソースコードがある。

### ロケーション情報　

手順では `src/consumer/connector-main/swagger_server/configs/location.json` を編集することで、
提供者コネクタのアドレス設定をするように書かれている。

このファイルは以下のような内容。

```json
{
    "connector_location": {
        "test-provider:catalog": {
            "provider_connector_url": "http://10.0.4.71:28080"
        },
        "test-provider:data": {
            "provider_connector_url": "http://10.0.4.71:38080"
        }
    }
}
```

あるデータ提供者コネクタのカタログAPI、データAPI（？）のURLが記載されている。

このファイルがどこで利用されるかというと、サービス定義内の以下。

src/consumer/connector-main/swagger_server/services/service.py:384

```python
def __get_location_info(provider, location_service_url, external_interface) -> (str):
```

> ロケーションサービスから取得ができなかった場合、
> location.jsonからコンフィグ情報を取得する。

とある通り、まずロケーションサービスから情報を取得するようにしレスポンスがあったらリターン。

src/consumer/connector-main/swagger_server/services/service.py:418

```python
    if response:
        if response.endswith('/'):
            response = response[:-1]
        provider_connector_url = response

        return provider_connector_url
```

だめな場合は、コンフィグから読み込む。

src/consumer/connector-main/swagger_server/services/service.py:425

```python
    # コンフィグから再取得を試みる
    logger.info(f'Not Found {provider} from {location_service_url}')
    try:
        config = internal_interface.config_read(__CONFIG_LOCATION_FILE_PATH)
    except Exception:  # pathミス
        raise CaddeException(message_id='020000003E')
```

この `__get_location_info` 関数は2箇所で利用されている。

```
__get_location_info(provider, location_service_url, external_interface)
  catalog_search(query_string, search, provider, authorization, external_interface=ExternalInterface())
  fetch_data(authorization, resource_url, resource_api_type, provider, options, external_interface=ExternalInterface())
```

ひとつがカタログ検索内。

src/consumer/connector-main/swagger_server/services/service.py:42

```python
def catalog_search(
        query_string: str,
        search: str,
        provider: str,
        authorization: str,
        external_interface: ExternalInterface = ExternalInterface()) -> Response:
    """
    カタログ検索I/Fに、カタログ検索を行い、検索結果を返す

    Args:
        query_string str : クエリストリング
        search str : 検索種別
        provider str: CADDEユーザID（提供者）
        authorization str: 利用者トークン
        external_interface ExternalInterface : GETリクエストを行うインタフェース

    Returns:
        Response : 取得した情報

    Raises:
        Cadde_excption: 検索種別確認時に不正な値が設定されている場合                エラーコード: 020001002E
        Cadde_excption: 認証I/F 認証トークン検証処理でエラーが発生した場合          エラーコード: 020001003E
        Cadde_excption: 提供者コネクタURLの取得に失敗した場合                       エラーコード: 020001004E
        Cadde_excption: カタログ検索I/Fのカタログ検索処理でエラーが発生した場合      エラーコード: 020001005E

    """
(snip)
```

カタログ検索機能を利用する際、もし詳細検索であれば、ロケーション情報を取得する。

src/consumer/connector-main/swagger_server/services/service.py:99

```python
    if search == 'detail':
        provider_connector_url = __get_location_info(
            provider, location_service_url, external_interface)
        if not provider_connector_url:
            raise CaddeException('020001004E')
```

もうひとつがデータの取得時。

src/consumer/connector-main/swagger_server/services/service.py:142

```python
def fetch_data(authorization: str,
               resource_url: str,
               resource_api_type: str,
               provider: str,
               options: dict,
               external_interface: ExternalInterface = ExternalInterface()) -> (BytesIO,
                                                                                dict):
    """
    データ交換I/Fからデータを取得する、もしくはデータ管理から直接データを取得する。

    Args:
        resource_url str : リソースURL
        resource_api_type str : リソース提供手段識別子
        provider str : CADDEユーザID（提供者）
        authorization str : 利用者トークン
        options : dict リクエストヘッダ情報 key:ヘッダ名 value:パラメータ
        external_interface ExternalInterface : GETリクエストを行うインタフェース

    Returns:
        BytesIO :取得データ
        dict: レスポンスヘッダ情報 key:ヘッダ名 value:パラメータ レスポンスヘッダがない場合は空のdictを返す

(snip)
```

提供社のCADDEユーザIDが与えられたときにロケーション情報を取得する。

src/consumer/connector-main/swagger_server/services/service.py:230

```python
    # CADDEユーザID（提供者）あり
    else:

        provider_connector_url = __get_location_info(
            provider, location_service_url, external_interface)
        if not provider_connector_url:
            raise CaddeException('020004003E')

(snip)
```

### コネクタ設定
READMEの通り、コネクタのIDやシークレットキーの設定は `src/consumer/connector-main/swagger_server/configs/connector.json` にて行う。

以下のような内容。

```json
{
    "consumer_connector_id" : "test_consumer_connector_id",
    "consumer_connector_secret" : "test_consumer_connector_secret",
    "location_service_url" : "https://testexample.com",
    "trace_log_enable" : true
}
```

また、これが用いられるのは、以下。

src/consumer/connector-main/swagger_server/services/service.py:486

```python
def __get_connector_config() -> (str, str, str, str):
    """
    connector.jsonからコンフィグ情報を取得し、
    利用者側コネクタID、利用者側コネクタのシークレット、来歴管理者用トークンを返す。

    Returns:
        str: 利用者側コネクタID
        str: 利用者側コネクタのシークレット
        str: ロケーションサービスのURL
        str: トレースログ設定

    Raises:
        Cadde_excption: コンフィグファイルの読み込みに失敗した場合                                エラーコード: 020000005E
        Cadde_excption: 必須パラメータが設定されていなかった場合（利用者コネクタID）              エラーコード: 020000006E
        Cadde_excption: 必須パラメータが設定されていなかった場合（利用者コネクタのシークレット）  エラーコード: 020000007E
        Cadde_excption: 必須パラメータが設定されていなかった場合（ロケーションサービスのURL）     エラーコード: 020000008E
        Cadde_excption: 必須パラメータが設定されていなかった場合（トレースログ設定）              エラーコード: 020000009E

    """

(snip)
```

この関数が利用されるのは以下。

```
__get_connector_config()
  catalog_search(query_string, search, provider, authorization, external_interface=ExternalInterface())
  fetch_data(authorization, resource_url, resource_api_type, provider, options, external_interface=ExternalInterface())
```

両方とも同様の使われ方。
基本的には、呼び出して必要な値を読み出す。以下は、カタログ検索での例。

src/consumer/connector-main/swagger_server/services/service.py:72

```
    consumer_connector_id, consumer_connector_secret, location_service_url, trace_log_enable = __get_connector_config()
```

得られた値は、例えば認証トークン検証などに用いられる。

src/consumer/connector-main/swagger_server/services/service.py:76

```python
    if authorization:
        # 認証トークン検証
        token_introspect_headers = {
            'Authorization': authorization,
            'x-cadde-consumer-connector-id': consumer_connector_id,
            'x-cadde-consumer-connector-secret': consumer_connector_secret
        }
        token_introspect_response = external_interface.http_get(
            __ACCESS_POINT_URL_AUTHENTICATION_AUTHORIZATION_INTROSPECT, token_introspect_headers)

        if token_introspect_response.status_code < 200 or 300 <= token_introspect_response.status_code:
            raise CaddeException(
                message_id='020001003E',
                status_code=token_introspect_response.status_code,
                replace_str_list=[
                    token_introspect_response.text])

        consumer_id = token_introspect_response.headers['x-cadde-consumer-id']

(snip)
```

### その他

NGSIの設定や、横断検索用CKAN URLの設定の説明がある。

横断検索用CKAN URL設定の使われどころ。
src/consumer/catalog-search/swagger_server/services/service.py:13

```python
def search_catalog_meta(
        q: str,
        internal_interface: InternalInterface,
        external_interface: ExternalInterface) -> Response:
    """
    横断検索を行い、横断検索サイトからカタログ情報を取得する

    Args:
        q str : 検索条件のクエリストリング
        internal_interface InternalInterface : コンフィグ情報取得処理を行うインタフェース
        external_interface ExternalInterface : GETリクエストを行うインタフェース

    Returns:
        Response : 取得した情報

    Raises:
        Cadde_excption : コンフィグファイルからCKANURLを取得できない場合、エラーコード : 020101004E
        Cadde_excption : ステータスコード2xxでない場合 エラーコード : 020101005E

    """

(snip)
```

src/consumer/catalog-search/swagger_server/services/service.py:34

```python
    try:
        config = internal_interface.config_read(__CONFIG_CKAN_URL_FILE_PATH)
        ckan_url = config[__CONFIG_CKAN_URL]
(snip)
```

また、TLS相互認証のためフォワードプロキシを利用する手順も載っているし、利用者コネクタへのアクセス制限のためのリバースプロキシの設定手順も載っている。

## 検索について

検索は、`src/consumer/catalog-search` が担う。以下、このコンポーネントについて。

以下の通り、`search` APIがエントリポイント。

swagger_server/swagger/swagger.yaml:19

```
      operationId: search
```

ということでコントローラを見る。

swagger_server.controllers.search_controller.search

```python
def search(q=None, x_cadde_search=None, x_cadde_provider_connector_url=None, Authorization=None):  # noqa: E501
    """API. カタログ検索

    横断検索、詳細検索を判定し、 横断検索サイトまたは提供者カタログサイトからカタログ情報を取得する Response: * 処理が成功した場合は200を返す * 処理に失敗した場合は、2xx以外を返す。Responsesセクション参照。 # noqa: E501

    :param q: CKAN検索条件クエリ CKAN APIに準拠
    :type q: str
    :param x-cadde-search: 横断検索、詳細検索を指定する(横断検索:meta、詳細検索:detail)
    :type x-cadde-search: str
    :param x-cadde-provider-connector-url: 提供者コネクタURL
    :type x-cadde-provider-connector-url: str
    :param Authorization: 認証トークン
    :type Authorization: str

    :rtype: None
    """

(snip)
```

検索は、横断検索（meta）か、詳細検索（detail）か。

swagger_server/controllers/search_controller.py:39

```python
    search = connexion.request.headers['x-cadde-search']
```

横断検索は以下。

swagger_server/controllers/search_controller.py:41

```python
    if search == 'meta':
        logger.debug(get_message('020101001N', [query_string, search]))

        data = search_catalog_meta(
            query_string, internal_interface, external_interface)
```

基本的には、コンフィグ（public_ckan.json）にある、公開CKAN（横断検索用カタログ）の
情報を取得し、問い合わせを投げるのみ。
認証はされない。（認証用トークなどを渡す仕様ではない） これは「公開」なので。

詳細検索は以下。

swagger_server/controllers/search_controller.py:47

```python
    else:
        if 'x-cadde-provider-connector-url' in connexion.request.headers:
            provider_connector_url = connexion.request.headers['x-cadde-provider-connector-url']
        else:
            raise CaddeException(message_id='020101002E')

        authorization = None
        if 'Authorization' in connexion.request.headers:
            authorization = connexion.request.headers['Authorization']

        logger.debug(get_message('020101003N', [query_string, log_message_none_parameter_replace(
            provider_connector_url), log_message_none_parameter_replace(authorization), search]))

        data = search_catalog_detail(
            query_string,
            provider_connector_url,
            authorization,
            external_interface)
```

こちらは、認証情報をヘッダーから取得し、関数に渡している。
`swagger_server.services.service.search_catalog_detail` 関数が本体。
認証情報を渡しているところが違う、基本的には同様。


# 参考

* [CADDE-sip/connector]
* [CADDE-sip/connector/README 前提条件]
* [CADDE-sip/connector/README 導入ガイドライン]
* [CADDE-sip/connector/README 利用者コネクタの構築手順]

[CADDE-sip/connector]: https://github.com/CADDE-sip/connector
[CADDE-sip/connector/README 前提条件]: https://github.com/CADDE-sip/connector?tab=readme-ov-file#%E5%89%8D%E6%8F%90%E6%9D%A1%E4%BB%B6
[CADDE-sip/connector/README 導入ガイドライン]: https://github.com/CADDE-sip/connector?tab=readme-ov-file#%E5%B0%8E%E5%85%A5%E3%82%AC%E3%82%A4%E3%83%89%E3%83%A9%E3%82%A4%E3%83%B3
[CADDE-sip/connector/README 利用者コネクタの構築手順]: https://github.com/CADDE-sip/connector?tab=readme-ov-file#%E5%B0%8E%E5%85%A5%E3%82%AC%E3%82%A4%E3%83%89%E3%83%A9%E3%82%A4%E3%83%B3



<!-- vim: set et tw=0 ts=2 sw=2: -->
