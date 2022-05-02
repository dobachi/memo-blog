---

title: ZooKeeperをスーパバイザでセルフヒーリングする
date: 2019-07-08 22:35:59
categories:
  - Knowledge Management
  - ZooKeeper
tags:
  - ZooKeeper
  - Supervision

---

# 参考

* [zookeeperAdmin.html#sc_supervision]

[zookeeperAdmin.html#sc_supervision]: http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_supervision

# メモ

Heron公式ドキュメントを参照していて改めて気づいたのだが、
ZooKeeperはSupervisor機能で自浄作用を持たせた方がよいだろう。

公式ドキュメントの [zookeeperAdmin.html#sc_supervision] では、
daemontoolsやSMFをスーパバイザの例として挙げていた。
