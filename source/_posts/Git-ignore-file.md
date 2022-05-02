---

title: Gitのgitignore
date: 2018-12-23 22:10:41
categories:
  - Knowledge Management
  - Tools
  - Git
tags:
  - Git

---

# 参考

* [GitHubのgitignoreファイルの雛形]
* [後からまとめてignoreする方法]

[GitHubのgitignoreファイルの雛形]: https://github.com/github/gitignore
[後からまとめてignoreする方法]: https://qiita.com/yuuAn/items/b1d1df2e810fd6b92574

# 手順

[後からまとめてignoreする方法] の通りで問題ない。

## gitignoreファイルのダウンロード

[GitHubのgitignoreファイルの雛形] からダウンロード。

Pythonの例

```
$ cd <レポジトリ>
$ wget https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore
```

必要に応じて既存の.gitignoreとマージしたり、mvして.gitignoreとしたり。

```
$ mv Python.gitignore .gitignore
```

コミット。

```
$ git add .gitignore
$ git commit -m "Add ignore pattern"
```

すでにコミットしてしまったファイルがあればまとめて削除。

```
$ git rm --cached `git ls-files --full-name -i --exclude-from=.gitignore`
```
