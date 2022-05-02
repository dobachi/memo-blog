---
title: Hexoでソースファイルもデプロイする
date: 2018-11-03 23:29:45
categories:
  - Knowledge Management
  - Hexo
tags:
  - Hexo

---

# 参考

* [関連する記事] 

[関連する記事]: https://stackoverflow.com/questions/46120213/import-current-hexo-blog-to-new-pc

# 方法

[関連する記事] に記載された通り、extend_dirsを指定すればよい。
以下のようにした。

```
deploy:
  - type: git
    repo: <git repository url>
    branch: gh-pages
    extend_dirs: source
```
