---

title: Flask SQLAlchemy
date: 2018-12-23 23:29:57
categories:
  - Knowledge Management
  - Flask
tags:
  - Flask
  - SQLAlchemy

---

# 参考

* [flask-sqlalchemyのクイックスタート]
* [Flask on Dockerのブログ]

[flask-sqlalchemyのクイックスタート]: http://flask-sqlalchemy.pocoo.org/2.3/quickstart/
[Flask on Dockerのブログ]: https://dobachi.github.io/memo-blog/2018/12/14/Flask-on-Docker/

# シェルで動作確認

## Dockerコンテナのビルド

[Flask on Dockerのブログ] と同様にDockerfileを作り、ビルドする。

ファイルを作成

```
$ mkdir -p  ~/Sources/docker_flask/sqlalchemy
$ cd ~/Sources/docker_flask/sqlalchemy
$ cat << EOF > Dockerfile
  FROM ubuntu:latest
  
  RUN apt-get update
  RUN apt-get install python3 python3-pip -y
  
  RUN pip3 install flask flask_sqlalchemy
  EOF
```

ビルド

```
$ sudo docker build . -t dobachi/flask_sqlalchemy:1.0
```

## アプリ作成と実行

```
$ mkdir apps
$ cat << EOF > apps/app.py
  from flask import Flask
  from flask_sqlalchemy import SQLAlchemy
  
  app = Flask(__name__)
  app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////tmp/test.db'
  db = SQLAlchemy(app)

  class User(db.Model):
      id = db.Column(db.Integer, primary_key=True)
      username = db.Column(db.String(80), unique=True, nullable=False)
      email = db.Column(db.String(120), unique=True, nullable=False)
  
      def __repr__(self):
          return '<User %r>' % self.username
  EOF
```

シェルを起動する。

```
$ sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps -e "FLASK_APP=app.py" -w /usr/local/apps -e "LC_ALL=C.UTF-8" -e "LANG=UTF-8" dobachi/flask_sqlalchemy:1.0 /bin/bash
```

シェル内で動作確認。テーブルを作ってレコードを生成。

```
>>> from app import db
/usr/local/lib/python3.6/dist-packages/flask_sqlalchemy/__init__.py:794: FSADeprecationWarning: SQLALCHEMY_TRACK_MODIFICATIONS adds significant overhead and will be disabled by default in the future.  Set it to True or False to suppress this warning.
  'SQLALCHEMY_TRACK_MODIFICATIONS adds significant overhead and '
>>> db.create_all()
>>> from app import User
>>> admin = User(username='admin', email='admin@example.com')
>>> guest = User(username='guest', email='guest@example.com')
>>> db.session.add(admin)
>>> db.session.add(guest)
>>> db.session.commit()
>>> User.query.all()
[<User 'admin'>, <User 'guest'>]
>>> User.query.filter_by(username='admin').first()
<User 'admin'>
```

sqlite3コマンドで接続して内容を確認。

```
root@a5d5ee81df78:/usr/local/apps# apt install sqlite3
root@a5d5ee81df78:/usr/local/apps# sqlite3 /tmp/test.db
sqlite> .databases
main: /tmp/test.db
sqlite> .tables
user
sqlite> select * from user;
1|admin|admin@example.com
2|guest|guest@example.com
```

# アプリから動作確認

上記と同様の流れをアプリから動作確認する。
Dockerイメージは上記で作ったものをベースとする。

## アプリ作成

ここでは/registにアクセスすると、登録画面が出て、
登録するとリスト（/list）が表示されるアプリを作成する。

```
$ mkdir -p  ~/Sources/docker_flask/sqlalchemy_app
$ cd ~/Sources/docker_flask/sqlalchemy_app
$ mkdir apps
$ cat << EOF > apps/app.py
  from flask import Flask, url_for, request, render_template, redirect
  from flask_sqlalchemy import SQLAlchemy
  
  app = Flask(__name__)
  app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////tmp/test.db'
  db = SQLAlchemy(app)
  
  class User(db.Model):
      id = db.Column(db.Integer, primary_key=True)
      username = db.Column(db.String(80), unique=True, nullable=False)
      email = db.Column(db.String(120), unique=True, nullable=False)
  
      def __repr__(self):
          return '<User %r>' % self.username
  
  db.create_all()
  
  @app.route('/regist', methods=['POST', 'GET'])
  def regist():
      if request.method == 'POST':
          user = User(username=request.form['username'], email=request.form['email'])
          db.session.add(user)
          db.session.commit()
          return redirect(url_for('list'))
      # the code below is executed if the request method
      # was GET or the credentials were invalid
      return render_template('regist.html')
  
  @app.route('/list')
  def list():
      users = User.query.order_by(User.username).all()
      return render_template('list.html', users=users)
  EOF
$ mkdir -p apps/templates
$ cat << EOF > apps/templates/regist.html
  <!doctype html>
  <title>Registration</title>
  <form action="/regist" method="post">
    <div>username: <input type="text" name="username"></div>
    <div>email: <input type="text" name="email"></div>
    <input type="submit" value="send">
    <input type="reset" value="reset">
  </form>
  
  <a href="/list">list</a>
  EOF
$ cat << EOF > apps/templates/list.html
  <!doctype html>
  <title>List ordered by username</title>
  <table>
      <thead>
          <tr>
              <th>id</th>
              <th>username</th>
              <th>email</th>
          </tr>
        </thead>
      <tbody>
          {% for item in users %}
          <tr>
              <td>
                  {{ item.id }}
              </td>
              <td>
                  {{ item.username }}
              </td>
              <td>
                  {{ item.email }}
              </td>
          </tr>
          {% endfor %}
      </tbody>
  </table>
  <a href="/regist">registration</a>
  EOF
```

## 実行

```
$ sudo docker run -it --rm -p 5000:5000 -v $(pwd)/apps:/usr/local/apps -e "FLASK_APP=app.py" -w /usr/local/apps -e "LC_ALL=C.UTF-8" -e "LANG=UTF-8" dobachi/flask_sqlalchemy:1.0 flask run --host 0.0.0.0
```

なお、上記の実装はエラーハンドリング等を一切実施していないので
例えば同じユーザ名、メールアドレスで登録しようとすると例外が生じる。
