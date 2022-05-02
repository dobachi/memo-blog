---

title: Flask on Docker
date: 2018-12-14 14:52:33
categories:
  - Knowledge Management
  - Flask
tags:
  - Docker
  - Dockerfile
  - Flask

---

# 参考

* [Flask公式]
* [Flask込みのDockerイメージを作る方法のブログ]
* [DockerコンテナでFlaskを起動し, JSONデータのPOSTとGET]
* [GitHub: FlaskOnDockerExamples]
* [GitHub: uwsgi-nginx-flask-docker]
* [GitHub: uwsgi-nginx-flask-dockerのクイックスタート]
* [GitHub: uwsgi-nginx-flask-dockerのSPA]
* [GitHub: 構造的なプロジェクトの例]
* [example-flask-package-python3.7.zip]
* [Flask + NginxでのSSL対応に関する記事]

[Flask公式]: http://flask.pocoo.org/
[Flask込みのDockerイメージを作る方法のブログ]: https://qiita.com/phorizon20/items/57277fab1fd7aa994502
[DockerコンテナでFlaskを起動し, JSONデータのPOSTとGET]: https://qiita.com/paperlefthand/items/82ab6df4a348f6070a55
[GitHub: FlaskOnDockerExamples]: https://github.com/dobachi/FlaskOnDockerExamples
[GitHub: uwsgi-nginx-flask-docker]: https://github.com/tiangolo/uwsgi-nginx-flask-docker
[GitHub: uwsgi-nginx-flask-dockerのクイックスタート]: https://github.com/tiangolo/uwsgi-nginx-flask-docker#quickstart
[GitHub: uwsgi-nginx-flask-dockerのSPA]: https://github.com/tiangolo/uwsgi-nginx-flask-docker#quickstart-for-spas
[GitHub: uwsgi-nginx-flask-dockerのテクニカル詳細]: https://github.com/tiangolo/uwsgi-nginx-flask-docker#technical-details
[GitHub: 構造的なプロジェクトの例]: https://github.com/tiangolo/uwsgi-nginx-flask-docker#quickstart-for-bigger-projects-structured-as-a-python-package
[example-flask-package-python3.7.zip]: https://github.com/tiangolo/uwsgi-nginx-flask-docker/releases/download/v0.3.10/example-flask-package-python3.7.zip
[Flask + NginxでのSSL対応に関する記事]: https://blog.miguelgrinberg.com/post/running-your-flask-application-over-https

# 自前のイメージを作って動かす手順

基本的には [Flask込みのDockerイメージを作る方法のブログ] で記載された内容で問題ない。
自身の環境向けにアレンジは必要。

## Dockerfileとビルド

Dockerfileは [Flask込みのDockerイメージを作る方法のブログ] の通り。

```
$ mkdir -p  ~/Sources/docker_flask/simple
$ cd ~/Sources/docker_flask/simple
$ cat << EOF > Dockerfile
  FROM ubuntu:latest
  
  RUN apt-get update
  RUN apt-get install python3 python3-pip -y
  
  RUN pip3 install flask
  EOF
```

ビルドコマンドは自分の環境に合わせた。

```
$ sudo docker build . -t dobachi/flask:1.0
```

インタラクティブにつなげる例も自分の環境に合わせた。

```
$ docker run -it --rm dobachi/flask:1.0 /bin/bash
```

## アプリ作成と実行

自分の環境に合わせた。
[Flask込みのDockerイメージを作る方法のブログ] では、
`/bin/bash`を起動してから、`python3 <アプリ >`としていたが、
ここでは直接指定して実行することにした。

```
$ mkdir apps
$ cat << EOF > apps/app.py
  from flask import Flask
  
  app = Flask(__name__)
  
  @app.route('/')
  def index():
      return "Hello world!!"
  EOF
$ sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps -e "FLASK_APP=app.py" -w /usr/local/apps -e "LC_ALL=C.UTF-8" -e "LANG=UTF-8" dobachi/flask:1.0 flask run --host 0.0.0.0
```

なお、もともとの [Flask込みのDockerイメージを作る方法のブログ] では、以下のようにPythonコマンドから直接実行するように記載されていたが、
今回は [Flask公式] に従い、FlaskのCLIを用いることとした。

```
sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps dobachi/flask:1.0 python3 /usr/local/apps/app.py
```

その際、手元の環境ではLANG等の事情により、いくつか環境変数を設定しないとエラーを吐いたので、
上記のようなコマンドになった。

# 公式手順に則ったシンプルな例

上記で作ったDockerイメージを流用する。

## 準備

```
$ mkdir -p  ~/Sources/docker_flask/getting_started
$ cd ~/Sources/docker_flask/getting_started
$ mkdir apps
$ cat << EOF > apps/app.py
  from flask import Flask, url_for, request, render_template

  app = Flask(__name__)
  
  @app.route('/')
  def index():
      return 'index'

  @app.route('/user/<username>')
  def profile(username):
      return '{}\'s profile'.format(username)
  
  @app.route('/post/<int:post_id>')
  def post(post_id):
      # show the post with the given id, the id is an integer
      return 'Post %d' % post_id
  
  @app.route('/path/<path:subpath>')
  def subpath(subpath):
      # show the subpath after /path/
      return 'Subpath %s' % subpath
  
  @app.route('/projects/')
  def projects():
      return 'The project page'
  
  @app.route('/about')
  def about():
      return 'The about page'

  @app.route('/login', methods=['GET', 'POST'])
  def login():
      if request.method == 'POST':
          return do_the_login()
      else:
          return show_the_login_form()

  def do_the_login():
    return 'Do log in'

  def show_the_login_form():
    return 'This is a login form'

  @app.route('/hello/')
  @app.route('/hello/<name>')
  def hello(name=None):
      return render_template('hello.html', name=name)

  # Test for URLs
  with app.test_request_context():
      print(url_for('index'))
      print(url_for('login'))
      print(url_for('login', next='/'))
      print(url_for('profile', username='John Doe'))
  EOF
$ mkdir -p apps/templates
$ cat << EOF > apps/templates/hello.html
  <!doctype html>
  <title>Hello from Flask</title>
  {% if name %}
    <h1>Hello {{ name }}!</h1>
  {% else %}
    <h1>Hello, World!</h1>
  {% endif %}
  EOF
```

## 実行

```
$ sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps -e "FLASK_APP=app.py" -w /usr/local/apps -e "LC_ALL=C.UTF-8" -e "LANG=UTF-8" dobachi/flask:1.0 flask run --host 0.0.0.0
```

# フォームを使う例

上記で作ったDockerイメージを流用する。

## 準備

```
$ mkdir -p  ~/Sources/docker_flask/form
$ cd ~/Sources/docker_flask/form
$ mkdir apps
$ cat << EOF > apps/app.py
  from flask import Flask, url_for, request, render_template, redirect, session

  app = Flask(__name__)

  # Set the secret key to some random bytes. Keep this really secret!
  app.secret_key = b'_5#y2L"F4Q8z\n\xec]/'
  
  @app.route('/login', methods=['POST', 'GET'])
  def login():
      error = None
      if request.method == 'POST':
          if valid_login(request.form['username'],
                         request.form['password']):
              session['username'] = request.form['username']
              return redirect(url_for('welcome'))
          else:
              error = 'Invalid username/password'
      # the code below is executed if the request method
      # was GET or the credentials were invalid
      return render_template('login.html', error=error)

  @app.route('/welcome')
  def welcome():
    if 'username' in session:
      return render_template('welcome.html', username=session['username'])
    else:
      return redirect(url_for('login'))

  def valid_login(username, password):
    if username == 'hoge' and password == 'fuga':
      return True
    else:
      return False
  EOF
$ mkdir -p apps/templates
$ cat << EOF > apps/templates/welcome.html
  <!doctype html>
  <title>Hello from Flask</title>
  <h1>Hello {{ username }}!</h1>
  EOF
$ cat << EOF > apps/templates/login.html
  <!doctype html>
  <title>Question from Flask</title>
  {% if error %}
    <h1>Please use valid username and password</h1>
  {% endif %}
  <form action="/login" method="post">
    <div>username: <input type="text" name="username"></div>
    <div>password: <input type="password" name="password"></div>
    <input type="submit" value="Send">
    <input type="reset" value="Reset">
  </form>
  EOF
```

## 実行

```
$ sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps -e "FLASK_APP=app.py" -w /usr/local/apps -e "LC_ALL=C.UTF-8" -e "LANG=UTF-8" dobachi/flask:1.0 flask run --host 0.0.0.0
```

# ファイルのアップロード

上記で作ったDockerイメージを流用する。

## 準備

```
$ mkdir -p  ~/Sources/docker_flask/file_upload
$ cd ~/Sources/docker_flask/file_upload
$ mkdir apps
$ cat << EOF > apps/app.py
  from flask import Flask, request, render_template, redirect, session, url_for
  from werkzeug.utils import secure_filename

  app = Flask(__name__)
  
  # Set the secret key to some random bytes. Keep this really secret!
  app.secret_key = b'_5#y2L"F4Q8z\n\xec]/'

  @app.route('/upload', methods=['GET', 'POST'])
  def upload_file():
      if request.method == 'POST':
          f = request.files['the_file']
          session['filename'] = secure_filename(f.filename)
          f.save('/tmp/' + session['filename'])
          return redirect(url_for('done'))
      elif request.method == 'GET':
          return render_template('upload.html')

  @app.route('/done')
  def done():
      return render_template('done.html')

  EOF
$ mkdir -p apps/templates
$ cat << EOF > apps/templates/upload.html
  <!doctype html>
  <title>Fileuploader by Flask</title>
  <form action="/upload" method="post" enctype="multipart/form-data">
    <div>file: <input type="file" name="the_file"></div>
    <input type="submit" value="Send">
    <input type="reset" value="Reset">
  </form>
  EOF
$ cat << EOF > apps/templates/done.html
  <!doctype html>
  <title>Fileuploader by Flask</title>
  <h1>The file: {{ filename }} was uploaded</h1>
  <a href="/upload">Got to the first page</a>
  EOF
```

## 実行

```
$ sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps -e "FLASK_APP=app.py" -w /usr/local/apps -e "LC_ALL=C.UTF-8" -e "LANG=UTF-8" dobachi/flask:1.0 flask run --host 0.0.0.0
```

# クッキー

上記で作ったDockerイメージを流用する。

## 準備

```
$ mkdir -p  ~/Sources/docker_flask/cookie
$ cd ~/Sources/docker_flask/cookie
$ mkdir apps
$ cat << EOF > apps/app.py
  from flask import Flask, url_for, request, render_template, redirect, make_response

  app = Flask(__name__)

  # Set the secret key to some random bytes. Keep this really secret!
  app.secret_key = b'_5#y2L"F4Q8z\n\xec]/'
  
  @app.route('/login', methods=['POST', 'GET'])
  def login():
      error = None
      if request.method == 'POST':
          if valid_login(request.form['username'],
                         request.form['password']):
              username = request.form['username']
              resp = make_response(render_template('success.html'))
              resp.set_cookie('username', username)
              return resp
          else:
              error = 'Invalid username/password'
      elif request.method == 'GET':
          if 'username' in request.cookies:
              return redirect(url_for('welcome'))
          else:
              return render_template('login.html', error=error)

  @app.route('/logout')
  def logout():
      resp = make_response(render_template('logout.html'))
      resp.delete_cookie('username')
      return resp

  @app.route('/welcome')
  def welcome():
    if 'username' in request.cookies:
      return render_template('welcome.html', username=request.cookies.get('username'))
    else:
      return redirect(url_for('login'))

  def valid_login(username, password):
    if username == 'hoge' and password == 'fuga':
      return True
    else:
      return False
  EOF
$ mkdir -p apps/templates
$ cat << EOF > apps/templates/welcome.html
  <!doctype html>
  <title>Hello from Flask</title>
  <h1>Hello {{ username }}!</h1>
  <a href="/logout">logout</a>
  EOF
$ cat << EOF > apps/templates/success.html
  <!doctype html>
  <title>Login Success</title>
  <h1>Login!</h1>
  <META http-equiv="Refresh" content="3;URL=/welcome">
  <p>Jump in 3 seconds</p>
  EOF
$ cat << EOF > apps/templates/logout.html
  <!doctype html>
  <title>Logout Success</title>
  <h1>Logout!</h1>
  <META http-equiv="Refresh" content="3;URL=/login">
  <p>Jump in 3 seconds</p>
  EOF
$ cat << EOF > apps/templates/login.html
  <!doctype html>
  <title>Question from Flask</title>
  {% if error %}
    <h1>Please use valid username and password</h1>
  {% endif %}
  <form action="/login" method="post">
    <div>username: <input type="text" name="username"></div>
    <div>password: <input type="password" name="password"></div>
    <input type="submit" value="Send">
    <input type="reset" value="Reset">
  </form>
  EOF
```

## 実行

```
$ sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps -e "FLASK_APP=app.py" -w /usr/local/apps -e "LC_ALL=C.UTF-8" -e "LANG=UTF-8" dobachi/flask:1.0 flask run --host 0.0.0.0
```

# ロギング

上記で作ったDockerイメージを流用する。

## 準備

```
$ mkdir -p  ~/Sources/docker_flask/logging
$ cd ~/Sources/docker_flask/logging
$ mkdir apps
$ cat << EOF > apps/app.py
  from flask import Flask, url_for, request, render_template, redirect, session

  app = Flask(__name__)

  # Set the secret key to some random bytes. Keep this really secret!
  app.secret_key = b'_5#y2L"F4Q8z\n\xec]/'
  
  @app.route('/login', methods=['POST', 'GET'])
  def login():
      error = None
      if request.method == 'POST':
          if valid_login(request.form['username'],
                         request.form['password']):
              session['username'] = request.form['username']
              return redirect(url_for('welcome'))
          else:
              app.logger.warning('Failed to login as:' + request.form['username'])
              error = 'Invalid username/password'
      # the code below is executed if the request method
      # was GET or the credentials were invalid
      return render_template('login.html', error=error)
  
  @app.route('/welcome')
  def welcome():
    if 'username' in session:
      return render_template('welcome.html', username=session['username'])
    else:
      return redirect(url_for('login'))
  
  def valid_login(username, password):
    if username == 'hoge' and password == 'fuga':
      return True
    else:
      return False
  EOF
$ mkdir -p apps/templates
$ cat << EOF > apps/templates/welcome.html
  <!doctype html>
  <title>Hello from Flask</title>
  <h1>Hello {{ username }}!</h1>
  EOF
$ cat << EOF > apps/templates/login.html
  <!doctype html>
  <title>Question from Flask</title>
  {% if error %}
    <h1>Please use valid username and password</h1>
  {% endif %}
  <form action="/login" method="post">
    <div>username: <input type="text" name="username"></div>
    <div>password: <input type="password" name="password"></div>
    <input type="submit" value="Send">
    <input type="reset" value="Reset">
  </form>
  EOF
```

## 実行

```
$ sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps -e "FLASK_APP=app.py" -w /usr/local/apps -e "LC_ALL=C.UTF-8" -e "LANG=UTF-8" dobachi/flask:1.0 flask run --host 0.0.0.0
```


# JSON形式でやり取りする例

基本的には、 [DockerコンテナでFlaskを起動し, JSONデータのPOSTとGET] の通り。

## Dockerfile

dockerfileを作る。

```
$ mkdir -p  ~/Sources/docker_flask/post_json
$ cd ~/Sources/docker_flask/post_json
$ cat << EOF > Dockerfile
  fROM python:3.6
  
  aRG project_dir=/app/
  
  # ADD requirements.txt \$project_dir
  aDD reply.py \$project_dir
  
  wORKDIR \$project_dir
  
  rUN pip install flask
  # RUN pip install -r requirements.txt
  
  cMD ["python", "reply.py"]
  eOF

```

## アプリ

アプリを作る。

```
$ cat << EOF > reply.py
  from flask import Flask, jsonify, request
  import json
  app = Flask(__name__)
  
  @app.route("/", methods=['GET'])
  def hello():
      return "Hello World!"
  
  @app.route('/reply', methods=['POST'])
  def reply():
      data = json.loads(request.data)
      answer = "Yes, it is %s!\n" % data["keyword"]
      result = {
        "Content-Type": "application/json",
        "Answer":{"Text": answer}
      }
      # return answer
      return jsonify(result)
  
  if __name__ == "__main__":
      app.run(host='0.0.0.0',port=5000,debug=True)
  eOF
```

ビルドする。

```
$ sudo docker build . -t dobachi/flask_json:1.0                                                                                                                                                                    
```

## 動作確認

ポート5000で起動する。

```
$ sudo docker run --rm -p 5000:5000 -it dobachi/flaskjson:1.0
```

動作確認する。

```
$ curl http://localhost:5000/reply -X POST -H "Content-Type: application/json" -d '{"keyword": "Keffia"}'
```

# nginxと組み合わせて動かす

[gitHub: uwsgi-nginx-flask-docker] を参考にする。
[gitHub: uwsgi-nginx-flask-dockerのクイックスタート] を見ながら試す。

## Dockerfile、アプリなど

```
$ mkdir -p  ~/Sources/docker_flask/nginx
$ cd ~/Sources/docker_flask/nginx
```

```
$ cat << EOF > Dockerfile
  fROM tiangolo/uwsgi-nginx-flask:python3.7
  
  cOPY ./app /app
  eOF
$ mkdir app
$ cat << EOF > app/main.py
  from flask import Flask
  app = Flask(__name__)
  
  @app.route("/")
  def hello():
      return "Hello World from Flask"
  
  if __name__ == "__main__":
      # Only for debugging while developing
      app.run(host='0.0.0.0', debug=True, port=80)
  eOF
```

## ビルド

```
$ sudo docker build -t dobachi/nginx-flask:1.0 .
```

## 実行

```
$ sudo docker run --rm -it -p 8080:80 dobachi/nginx-flask:1.0 
```

# nginxと組あわせてSPA

[gitHub: uwsgi-nginx-flask-dockerのSPA] を参考に進める。

## Dockerfileとアプリ

```
$ mkdir -p  ~/Sources/docker_flask/nginx_spa
$ cd ~/Sources/docker_flask/nginx_spa
$ cat << EOF > Dockerfile
  fROM tiangolo/uwsgi-nginx-flask:python3.7
  
  eNV STATIC_INDEX 1
  
  cOPY ./app /app
  eOF
$ mkdir app
$ cat << EOF > app/main.py
  import os
  from flask import Flask, send_file
  app = Flask(__name__)
  
  
  @app.route("/hello")
  def hello():
      return "Hello World from Flask"
  
  
  @app.route("/")
  def main():
      index_path = os.path.join(app.static_folder, 'index.html')
      return send_file(index_path)
  
  
  # Everything not declared before (not a Flask route / API endpoint)...
  @app.route('/<path:path>')
  def route_frontend(path):
      # ...could be a static file needed by the front end that
      # doesn't use the `static` path (like in `<script src="bundle.js">`)
      file_path = os.path.join(app.static_folder, path)
      if os.path.isfile(file_path):
          return send_file(file_path)
      # ...or should be handled by the SPA's "router" in front end
      else:
          index_path = os.path.join(app.static_folder, 'index.html')
          return send_file(index_path)
  
  
  if __name__ == "__main__":
      # Only for debugging while developing
      app.run(host='0.0.0.0', debug=True, port=80)
  eOF
```

```
$ mkdir app/static
$ cat << EOF > app/static/index.html
  <!DOCTYPE html>
  <html lang="en">
  <head>
      <meta charset="UTF-8">
      <title>Index</title>
  </head>
  <body>
  <h1>Hello World from HTML</h1>
  </body>
  </html>
  eOF
```

## ビルド

```
$ sudo docker build -t dobachi/nginx-flask-spa:1.0 .
```
## 実行

```
$ sudo docker run --rm -it -p 8080:80 dobachi/nginx-flask-spa:1.0 
```

# 構造的なプロジェクト

[gitHub: 構造的なプロジェクトの例] に記載の例を示す。
[example-flask-package-python3.7.zip] をダウンロードしてビルドしてみる。

## アーカイブをダウンロード

```
$ mkdir -p  ~/Sources/docker_flask/
$ wget https://github.com/tiangolo/uwsgi-nginx-flask-docker/releases/download/v0.3.10/example-flask-package-python3.7.zip
$ unzip example-flask-package-python3.7.zip
$ cd example-flask-package-python3.7
```

## ビルド

```
$ sudo docker build -t dobachi/nginx-flask-package:1.0 .
```
## 実行

```
$ sudo docker run --rm -it -p 8080:80 dobachi/nginx-flask-package:1.0 
```

## 一部修正してみる

apiを追加する。

ファイルを修正
```
$ cat example-flask-package-python3.7/app/app/api/api.py 
from .endpoints import user
from .endpoints import get_ip
```

ファイルを追加
```
$ cat example-flask-package-python3.7/app/app/api/endpoints/get_ip.py 
from flask import request
from flask import jsonify

from ..utils import senseless_print

from ...main import app

@app.route("/get_ip", methods=["GET"])
def get_ip():
        return jsonify({'ip': request.remote_addr}), 200
```

ビルドし、実行して、/get_ipにアクセスすると、接続元のIPアドレスが表示される。

# flask + NginxでSSLを使用（ここがうまく動かない）

## アドホックな対応

[flask + NginxでのSSL対応に関する記事] に記載された方法で試す。
また上記で使った`example-flask-package-python3.7`の例を用いてみる。

まずDockerfileを以下のように変更した。

```
$ cat Dockerfile 
froM tiangolo/uwsgi-nginx-flask:python3.7

run apt-get update
run pip install pyopenssl

copY ./app /app
```

`main.py`を以下のように修正し、アドホックなSSL対応を試せるようにする。

```
$ cat app/app/main.py 
from flask import Flask

app = Flask(__name__)

from .core import app_setup


if __name__ == "__main__":
    # Only for debugging while developing
    # app.run(host='0.0.0.0', debug=True, port=80)
    app.run(host='0.0.0.0', debug=True, ssl_context='adhoc')
```

以上の修正を加えた上で、Dockerイメージをビルドし実行した。

```
$ sudo docker build -t dobachi/nginx-flask-package:1.0 .
$ sudo docker run --rm -it -p 8080:80 dobachi/nginx-flask-package:1.0  /bin/bash

```

# gitHub: uwsgi-nginx-flask-dockerのアーキテクチャ

[gitHub: uwsgi-nginx-flask-dockerのテクニカル詳細] で書かれている通り。
以下の役割分担。

* ウェブサーバ：Nginx
* wSGIのアプリサーバ：uWSGI

またアプリはFlaskで書かれていることを前提とし、
プロセスはSupervisordで管理される。
アプリはコンテナ内の`/app`以下に配備されることを前提とし、その中にとりあえずは動く`uwsgi.ini`も含まれる。
そのため、Dockerfile内でuwsgi.iniを上書きさせるようにして用いることを想定しているようだ。

## Supervisord化について

以下のように/bin/bashを起動して確認した。

```
$ sudo docker run --rm -it -p 8080:80 dobachi/nginx-flask-package:1.0  /bin/bash
```

`/etc/supervisor/conf.d/supervisord.conf`を確認する。

```
# cat /etc/supervisor/conf.d/supervisord.conf 
[supervisord]
nodaemon=true

[program:uwsgi]
command=/usr/local/bin/uwsgi --ini /etc/uwsgi/uwsgi.ini --die-on-term --need-app
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:nginx]
command=/usr/sbin/nginx
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
# graceful stop, see http://nginx.org/en/docs/control.html
stopsignal=QUIT
```

uwsgiとnginxを起動させていることがわかる。

続いて、nginxの設定において、uwsgiと連携しているのを設定している箇所を確認。

```
# cat /etc/nginx/conf.d/nginx.conf 
server {
    listen 80;
    location / {
        try_files $uri @app;
    }
    location @app {
        include uwsgi_params;
        uwsgi_pass unix:///tmp/uwsgi.sock;
    }
    location /static {
        alias /app/static;
    }
}
```

uwsgiでは、/appディレクトリ以下のuwsgi.iniと/etc/uwsgi/uwsgi.iniの両方を確認するようだ。

```
# cat /etc/uwsgi/uwsgi.ini 
[uwsgi]
socket = /tmp/uwsgi.sock
chown-socket = nginx:nginx
chmod-socket = 664
# graceful shutdown on SIGTERM, see https://github.com/unbit/uwsgi/issues/849#issuecomment-118869386
hook-master-start = unix_signal:15 gracefully_kill_them_all
```

```
# cat /app/uwsgi.ini 
[uwsgi]
module = app.main
callable = app

```
