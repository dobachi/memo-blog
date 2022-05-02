---

title: Basic of SQLAlchemy
date: 2018-12-24 22:54:17
categories:
  - Knowledge Management
  - SQLAlchemy
tags:
  - SQLAlchemy
  - Python
  - SQLite

---

# 参考
* [SQLAlchemy公式のチュートリアル]

[SQLAlchemy公式のチュートリアル]: https://docs.sqlalchemy.org/en/latest/core/tutorial.html

# 簡単な動作確認

エンジンの定義。（今回はSQLiteのインメモリモードを使用）
```
from sqlalchemy import create_engine
engine = create_engine('sqlite:///:memory:', echo=True)
```

テーブルの作成。今回は2種類のテーブルを作成。
ユーザのIDをプライマリキーとして使用。
```
from sqlalchemy import Table, Column, Integer, String, MetaData, ForeignKey
metadata = MetaData()
users = Table('users', metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String),
    Column('fullname', String),
)

addresses = Table('addresses', metadata,
  Column('id', Integer, primary_key=True),
  Column('user_id', None, ForeignKey('users.id')),
  Column('email_address', String, nullable=False)
 )
```

実際にSQLite内でテーブルを定義する。このとき、テーブルの存在を確認するので複数回実行してもよい。（べき等である）
```
metadata.create_all(engine)
```

## 挿入のクエリ

まずは空のクエリを定義。
```
ins = users.insert()
```

strを使うと、SQLを確認できる。
```
str(ins)
--
'INSERT INTO users (id, name, fullname) VALUES (:id, :name, :fullname)'
```

今度は値を入れてみる。
```
ins = users.insert().values(name='jack', fullname='Jack Jones')
str(ins)
--
'INSERT INTO users (name, fullname) VALUES (:name, :fullname)'
```

## 接続の取得と実行

接続の取得
```
conn = engine.connect()
```

実行
```
result = conn.execute(ins)
--
2018-12-24 14:08:34,031 INFO sqlalchemy.engine.base.Engine INSERT INTO users (name, fullname) VALUES (?, ?)
2018-12-24 14:08:34,031 INFO sqlalchemy.engine.base.Engine ('jack', 'Jack Jones')
2018-12-24 14:08:34,032 INFO sqlalchemy.engine.base.Engine COMMIT
```

挿入されたレコードのプライマリキーの確認。
```
>>> result.inserted_primary_key
--
[1]
```

## 複数ステートメントの実行

先の例と同じ1個ずつ挿入する場合。
```
ins = users.insert()
conn.execute(ins, id=2, name='wendy', fullname='Wendy Williams')
--
2018-12-24 14:12:55,688 INFO sqlalchemy.engine.base.Engine INSERT INTO users (id, name, fullname) VALUES (?, ?, ?)
2018-12-24 14:12:55,688 INFO sqlalchemy.engine.base.Engine (2, 'wendy', 'Wendy Williams')
2018-12-24 14:12:55,688 INFO sqlalchemy.engine.base.Engine COMMIT
<sqlalchemy.engine.result.ResultProxy object at 0x7f63c8ca7940>
```

複数ステートメントを一度に実行する場合。
```
conn.execute(addresses.insert(), [
   {'user_id': 1, 'email_address' : 'jack@yahoo.com'},
   {'user_id': 1, 'email_address' : 'jack@msn.com'},
   {'user_id': 2, 'email_address' : 'www@www.org'},
   {'user_id': 2, 'email_address' : 'wendy@aol.com'},
])
--
2018-12-24 14:13:42,077 INFO sqlalchemy.engine.base.Engine INSERT INTO addresses (user_id, email_address) VALUES (?, ?)
2018-12-24 14:13:42,078 INFO sqlalchemy.engine.base.Engine ((1, 'jack@yahoo.com'), (1, 'jack@msn.com'), (2, 'www@www.org'), (2, 'wendy@aol.com'))
2018-12-24 14:13:42,078 INFO sqlalchemy.engine.base.Engine COMMIT
<sqlalchemy.engine.result.ResultProxy object at 0x7f63c8ca7c18>
```

## SELECT

まずはクエリを実行。
```
from sqlalchemy.sql import select
s = select([users])
result = conn.execute(s)
--
2018-12-24 14:16:11,363 INFO sqlalchemy.engine.base.Engine SELECT users.id, users.name, users.fullname 
FROM users
2018-12-24 14:16:11,363 INFO sqlalchemy.engine.base.Engine ()
```

結果のパース。タプルライクに取得。
```
for row in result:
    print(row)
--
(1, 'jack', 'Jack Jones')
(2, 'wendy', 'Wendy Williams')
```

辞書ライクに取得。
```
result = conn.execute(s)
row = result.fetchone()
print("name:", row['name'], "; fullname:", row['fullname'])
--
name: jack ; fullname: Jack Jones
```

conn.execute()の結果はイテレータっぽく扱えるので以下のような書き方ができる。
今回は2個のテーブルのカルテシアン積を求める例。
```
for row in conn.execute(select([users, addresses])):
    print(row)
--
2018-12-24 14:20:14,164 INFO sqlalchemy.engine.base.Engine SELECT users.id, users.name, users.fullname, addresses.id, addresses.user_id, addresses.email_address 
FROM users, addresses
2018-12-24 14:20:14,164 INFO sqlalchemy.engine.base.Engine ()
(1, 'jack', 'Jack Jones', 1, 1, 'jack@yahoo.com')
(1, 'jack', 'Jack Jones', 2, 1, 'jack@msn.com')
(1, 'jack', 'Jack Jones', 3, 2, 'www@www.org')
(1, 'jack', 'Jack Jones', 4, 2, 'wendy@aol.com')
(2, 'wendy', 'Wendy Williams', 1, 1, 'jack@yahoo.com')
(2, 'wendy', 'Wendy Williams', 2, 1, 'jack@msn.com')
(2, 'wendy', 'Wendy Williams', 3, 2, 'www@www.org')
(2, 'wendy', 'Wendy Williams', 4, 2, 'wendy@aol.com')
```

どちらかというと、こちらの方がイメージに近いか。
```
for row in conn.execute(select([users, addresses]).where(users.c.id == addresses.c.user_id)):
    print(row)
--
2018-12-24 14:22:46,769 INFO sqlalchemy.engine.base.Engine SELECT users.id, users.name, users.fullname, addresses.id, addresses.user_id, addresses.email_address 
FROM users, addresses 
WHERE users.id = addresses.user_id
2018-12-24 14:22:46,769 INFO sqlalchemy.engine.base.Engine ()
(1, 'jack', 'Jack Jones', 1, 1, 'jack@yahoo.com')
(1, 'jack', 'Jack Jones', 2, 1, 'jack@msn.com')
(2, 'wendy', 'Wendy Williams', 3, 2, 'www@www.org')
(2, 'wendy', 'Wendy Williams', 4, 2, 'wendy@aol.com')
```

## オペレータの結合

`and_`などを用いる例。
```
from sqlalchemy.sql import and_, or_, not_
s = select([(users.c.fullname +
              ", " + addresses.c.email_address).
               label('title')]).\
       where(
          and_(
              users.c.id == addresses.c.user_id,
              users.c.name.between('m', 'z'),
              or_(
                 addresses.c.email_address.like('%@aol.com'),
                 addresses.c.email_address.like('%@msn.com')
              )
          )
       )
conn.execute(s).fetchall()
```

Pythonの演算子を用いる例。
```
s = select([(users.c.fullname +
              ", " + addresses.c.email_address).
               label('title')]).\
       where(
          (users.c.id == addresses.c.user_id) &
          (users.c.name.between('m', 'z')) &
          (
          addresses.c.email_address.like('%@aol.com') | \
          addresses.c.email_address.like('%@msn.com')
          )
       )
conn.execute(s).fetchall()
```

`and_`はwhere句を並べることでも実現できる。
```
s = select([(users.c.fullname +
              ", " + addresses.c.email_address).
               label('title')]).\
       where(users.c.id == addresses.c.user_id).\
       where(users.c.name.between('m', 'z')).\
       where(
              or_(
                 addresses.c.email_address.like('%@aol.com'),
                 addresses.c.email_address.like('%@msn.com')
              )
       )
conn.execute(s).fetchall()
```

## テキストで実行

基本的な使い方
```
from sqlalchemy.sql import text
s = text(
    "SELECT users.fullname || ', ' || addresses.email_address AS title "
        "FROM users, addresses "
        "WHERE users.id = addresses.user_id "
        "AND users.name BETWEEN :x AND :y "
        "AND (addresses.email_address LIKE :e1 "
            "OR addresses.email_address LIKE :e2)")
conn.execute(s, x='m', y='z', e1='%@aol.com', e2='%@msn.com').fetchall()
```

予めバインドされた値を予め定義することもできる。
```
stmt = text("SELECT * FROM users WHERE users.name BETWEEN :x AND :y")
stmt = stmt.bindparams(x="m", y="z")
# stmt = stmt.bindparams(bindparam("x", type_=String), bindparam("y", type_=String))
result = conn.execute(stmt, {"x": "m", "y": "z"})
result.fetchall()
--
[(2, 'wendy', 'Wendy Williams')]
```

ステートメントの中でSQLテキストを用いることもできる。
```
s = select([
       text("users.fullname || ', ' || addresses.email_address AS title")
    ]).\
        where(
            and_(
                text("users.id = addresses.user_id"),
                text("users.name BETWEEN 'm' AND 'z'"),
                text(
                    "(addresses.email_address LIKE :x "
                    "OR addresses.email_address LIKE :y)")
            )
        ).select_from(text('users, addresses'))
conn.execute(s, x='%@aol.com', y='%@msn.com').fetchall()
```

## グループ

単純な例
```
from sqlalchemy import func
stmt = select([
        addresses.c.user_id,
        func.count(addresses.c.id).label('num_addresses')]).\
        group_by("user_id").order_by("user_id", "num_addresses")

conn.execute(stmt).fetchall()
```

## 結合


単純な例
```
print(users.join(addresses))
```

いろいろな表現を用いることができる。
```
print(users.join(addresses,
                addresses.c.email_address.like(users.c.name + '%')
            )
)
```

実施に実行
```
s = select([users.c.fullname]).select_from(
   users.join(addresses,
            addresses.c.email_address.like(users.c.name + '%'))
   )
conn.execute(s).fetchall()
--
2018-12-25 12:45:29,919 INFO sqlalchemy.engine.base.Engine SELECT users.fullname 
FROM users JOIN addresses ON addresses.email_address LIKE users.name || ?
2018-12-25 12:45:29,919 INFO sqlalchemy.engine.base.Engine ('%',)
[('Jack Jones',), ('Jack Jones',), ('Wendy Williams',)]
```

outer join
```
print(select([users.c.fullname]).select_from(users.outerjoin(addresses)))
--
SELECT users.fullname 
FROM users LEFT OUTER JOIN addresses ON users.id = addresses.user_id
```

## 変数バインド

単純な例
```
from sqlalchemy.sql import bindparam
s = users.select(users.c.name.like(bindparam('username', type_=String) + text("'%'")))
conn.execute(s, username='wendy').fetchall()
--
2018-12-25 13:34:19,392 INFO sqlalchemy.engine.base.Engine SELECT users.fullname 
FROM users LEFT OUTER JOIN addresses ON users.id = addresses.user_id
2018-12-25 13:34:19,392 INFO sqlalchemy.engine.base.Engine ()
[('Jack Jones',), ('Jack Jones',), ('Wendy Williams',), ('Wendy Williams',)]
```

バインドした変数は複数回使用できる。
```
s = select([users, addresses]).\
    where(
       or_(
         users.c.name.like(
                bindparam('name', type_=String) + text("'%'")),
         addresses.c.email_address.like(
                bindparam('name', type_=String) + text("'@%'"))
       )
    ).\
    select_from(users.outerjoin(addresses)).\
    order_by(addresses.c.id)
conn.execute(s, name='jack').fetchall()
--
2018-12-25 13:43:43,880 INFO sqlalchemy.engine.base.Engine SELECT users.id, users.name, users.fullname, addresses.id, addresses.user_id, addresses.email_address 
FROM users LEFT OUTER JOIN addresses ON users.id = addresses.user_id 
WHERE users.name LIKE ? || '%' OR addresses.email_address LIKE ? || '@%' ORDER BY addresses.id
2018-12-25 13:43:43,880 INFO sqlalchemy.engine.base.Engine ('jack', 'jack')
[(1, 'jack', 'Jack Jones', 1, 1, 'jack@yahoo.com'), (1, 'jack', 'Jack Jones', 2, 1, 'jack@msn.com')]
```

## その他の機能

* ファンクション
* ウィンドウファンクション
* union、except_
* Label
* Ordering, Limiting, ...

## Update

```
stmt = users.update().\
            where(users.c.name == 'jack').\
            values(name='ed')

conn.execute(stmt)
```

```
stmt = users.update().\
            where(users.c.name == bindparam('oldname')).\
            values(name=bindparam('newname'))
conn.execute(stmt, [
    {'oldname':'jack', 'newname':'ed'},
    {'oldname':'wendy', 'newname':'mary'},
    {'oldname':'jim', 'newname':'jake'},
    ])
conn.execute(select([users])).fetchall()
--
2018-12-25 15:11:08,628 INFO sqlalchemy.engine.base.Engine SELECT users.id, users.name, users.fullname 
FROM users
2018-12-25 15:11:08,628 INFO sqlalchemy.engine.base.Engine ()
[(1, 'ed', 'Jack Jones'), (2, 'mary', 'Wendy Williams')]
```

