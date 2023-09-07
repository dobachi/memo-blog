---

title: OpenAPI Generator for Flask
date: 2023-09-07 22:10:58
categories:
  - Knowledge Management
  - Open API
tags:
  - Open API
  - Flask
  - Python

---

# メモ

## 簡単な動作確認

ひとまず分かりやすかった [OpenAPI GeneratorでPython Web API構築] をそのまま試す。

```bash
$ mkdir -p  ~/Sources/OpenAPIGenFlaskSample/original
$ cd  ~/Sources/OpenAPIGenFlaskSample/original
$ cat << EOF > openapi.yaml

(snip)

EOF
```
`openapi.yaml`の中身は [OpenAPI GeneratorでPython Web API構築] に記載されている。

```bash
$ mkdir -p server client
$ docker run --rm -v ${PWD}:/local openapitools/openapi-generator-cli generate -i /local/openapi.yaml -g python-flask -o /local/server
$ docker run --rm -v ${PWD}:/local openapitools/openapi-generator-cli generate -i /local/openapi.yaml -g go -o /local/client
```

今回用があるのはサーバ側のPython実装（Flask）の方なので、そちらを確認する。
記事にもあるが以下のようなファイルが生成されているはず。

```bash
$ tree
.
├── Dockerfile
├── README.md
├── git_push.sh
├── openapi_server
│   ├── __init__.py
│   ├── __main__.py
│   ├── controllers
│   │   ├── __init__.py
│   │   ├── security_controller.py
│   │   └── stock_price_controller.py
│   ├── encoder.py
│   ├── models
│   │   ├── __init__.py
│   │   ├── base_model.py
│   │   ├── error.py
│   │   ├── ok.py
│   │   └── stock_price.py
│   ├── openapi
│   │   └── openapi.yaml
│   ├── test
│   │   ├── __init__.py
│   │   └── test_stock_price_controller.py
│   ├── typing_utils.py
│   └── util.py
├── requirements.txt
├── setup.py
├── test-requirements.txt
└── tox.ini
```

まずは、 `__main__.py` を見てみる。

```python
#!/usr/bin/env python3

import connexion

from openapi_server import encoder


def main():
    app = connexion.App(__name__, specification_dir='./openapi/')
    app.app.json_encoder = encoder.JSONEncoder
    app.add_api('openapi.yaml',
                arguments={'title': 'Stock API'},
                pythonic_params=True)

    app.run(port=8080)


if __name__ == '__main__':
    main()
```

上記の通り、 connexionを用いていることがわかる。
connexionはFlaskで動作する、APIとpython関数をマッピングするためのパッケージである。
connexionについては、 [connexionを使ってPython APIサーバのAPI定義と実装を関連付ける] のような記事を参考にされたし。

`openapi_server/controllers/stock_price_controller.py` を確認する。

```python
import connexion
from typing import Dict
from typing import Tuple
from typing import Union

from openapi_server.models.error import Error  # noqa: E501
from openapi_server.models.stock_price import StockPrice  # noqa: E501
from openapi_server import util


def stock_price(security_cd):  # noqa: E501
    """株価取得

    現在の株価を取得する # noqa: E501

    :param security_cd: 証券コードを指定する
    :type security_cd: str

    :rtype: Union[StockPrice, Tuple[StockPrice, int], Tuple[StockPrice, int, Dict[str, str]]
    """
    return 'do some magic!'
```

`operationId` にて指定した名称がコントローラのメソッド名に反映されている。

`parameters` にて指定したパラメータがコントローラの引数になっていることが確認できる。

`components` にて指定したスキーマに基づき、`openapi_server/models` 以下に反映されていることが分かる。
今回の例だと、戻り値用の `StockPrice` やOK、Errorが定義されている。
なお、これはOpenAPIにて生成されたものであり、それを編集して使うことはあまり想定されていないようだ。

`openapi_server/util.py` にはデシリアライザなどが含まれている。

さて、記事通り、Dockerで動かしてみる。

```bash
$ docker build -t openapi_server .
$ docker run -p 8080:8080 openapi_server
```

試しに、適当な引数を与えて動かすと、実装通り戻り値を得られる。

```bash
$ curl http://localhost:8080/v1/sc/4721/stockPrice
"do some magic!"
```

なおDockerfileはこんな感じである。

```Dockerfile
FROM python:3-alpine

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY requirements.txt /usr/src/app/

RUN pip3 install --no-cache-dir -r requirements.txt

COPY . /usr/src/app

EXPOSE 8080

ENTRYPOINT ["python3"]

CMD ["-m", "openapi_server"]
```

Docker化しなくてもそのままでも動く。
ここでは一応venvを使って仮想環境を構築しておく。

```bash
$ python -m venv venv
$ . venv/bin/activate
$ pip install -r requirements.txt
$ python -m openapi_server
```

# 参考

## 記事

* [OpenAPI GeneratorでPython Web API構築]
* [connexionを使ってPython APIサーバのAPI定義と実装を関連付ける]

[OpenAPI GeneratorでPython Web API構築]: https://future-architect.github.io/articles/20221203a/
[connexionを使ってPython APIサーバのAPI定義と実装を関連付ける]: https://qiita.com/amuyikam/items/1454177a7030e3b3ce80





<!-- vim: set et tw=0 ts=2 sw=2: -->
