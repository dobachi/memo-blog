---

title: PostgreSQLにおけるfsyncに関するバグフィックス
date: 2019-02-18 09:17:13
categories:
  - Clipping
  - PostgreSQL
tags:
  - PostgreSQL
  - fsync
  - bug

---

# 参考

* [澤田さんによる説明]
* [PostgreSQL vs. fsync How is it possible that PostgreSQL used fsync incorrectly for 20 years, and what we'll do about it.]
* [PostgreSQL 11.2, 10.7, 9.6.12, 9.5.16, and 9.4.21 Released!]

[澤田さんによる説明]: https://masahikosawada.github.io/2019/02/17/PostgreSQL-fsync-issue/
[PostgreSQL vs. fsync How is it possible that PostgreSQL used fsync incorrectly for 20 years, and what we'll do about it.]: https://fosdem.org/2019/schedule/event/postgresql_fsync/
[PostgreSQL 11.2, 10.7, 9.6.12, 9.5.16, and 9.4.21 Released!]: https://www.postgresql.org/about/news/1920/

# メモ

基本的に [澤田さんによる説明] がわかりやすいのでそれを参照されたし。
より原典を当たる意では、FOSDEM'19の講演
[PostgreSQL vs. fsync How is it possible that PostgreSQL used fsync incorrectly for 20 years, and what we'll do about it.]
を参照されたし。

fsyncに期待することの認識誤りのため発生していたバグとのこと。
