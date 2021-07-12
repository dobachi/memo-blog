---

title: Flask extension
date: 2018-12-23 21:56:25
categories:
  - Knowledge Management
  - Flask
tags:
  - Docker
  - Dockerfile
  - Flask

---

# 参考

* [Flask公式ウェブサイト]
* [flask-adminのドキュメント]
* [Flask on Dockerのブログ]

[Flask公式ウェブサイト]: http://flask.pocoo.org/extensions/
[flask-adminのドキュメント]: https://flask-admin.readthedocs.io/en/latest/introduction/
[Flask on Dockerのブログ]: https://dobachi.github.io/memo-blog/2018/12/14/Flask-on-Docker/

# flask_adminを試す
[flask-adminのドキュメント] を見ながら進める。
また[Flask on Dockerのブログ] で作成したDockerイメージを使って環境を作る。

## Dockerfileを作成してビルド

```
$ mkdir -p  ~/Sources/docker_flask/docker_admin
$ cd ~/Sources/docker_flask/docker_admin
$ cat << EOF > Dockerfile
  FROM ubuntu:latest
  
  RUN apt-get update
  RUN apt-get install python3 python3-pip -y
  
  RUN pip3 install flask flask_admin
  EOF
```

```
$ sudo docker build . -t dobachi/flask_admin:1.0
```

## アプリ作成と実行

```
$ mkdir apps
$ cat << EOF > apps/app.py
  from flask import Flask
  from flask_admin import Admin
  
  app = Flask(__name__)
  
  # set optional bootswatch theme
  app.config['FLASK_ADMIN_SWATCH'] = 'cerulean'
  
  admin = Admin(app, name='microblog', template_mode='bootstrap3')
  
  @app.route('/')
  def index():
      return "Hello world!!"
  EOF
$ sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps -e "FLASK_APP=app.py" -w /usr/local/apps -e "LC_ALL=C.UTF-8" -e "LANG=UTF-8" dobachi/flask_admin:1.0 flask run --host 0.0.0.0
```
