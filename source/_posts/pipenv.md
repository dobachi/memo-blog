---

title: pipenvを試す
date: 2019-10-22 22:59:34
categories:
  - Knowledge Management
  - Python
  - Pipenv
tags:
  - Python
  - Pipenv

---

# 参考

* [Pipenvことはじめ]
* [pyenv、pyenv-virtualenv、venv、Anaconda、Pipenv。私はPipenvを使う。]
* [Pipenvを使ったPython開発まとめ]
* [pyenvのインストール手順]
* [Pipenvことはじめ]


[Pipenvことはじめ]: https://qiita.com/shinshin86/items/e11c1124e3e2e74556b8
[pyenv、pyenv-virtualenv、venv、Anaconda、Pipenv。私はPipenvを使う。]: https://qiita.com/KRiver1/items/c1788e616b77a9bad4dd
[Pipenvを使ったPython開発まとめ]: https://qiita.com/y-tsutsu/items/54c10e0b2c6b565c887a
[pyenvのインストール手順]: https://github.com/pyenv/pyenv#installation
[Pipenvことはじめ]: https://qiita.com/shinshin86/items/e11c1124e3e2e74556b8

# メモ

上記の参考情報を見て試した。

## WSL上でのpipenv

まずOS標準のPython環境を汚さないため、pyenvを導入した。
導入手段は、 [pyenvのインストール手順] を参照。


導入した後、pyenvを使ってPython3.7.5を導入する。
```
$ pyenv install 3.7.5
$ pyenv global 3.7.5
$ pip install pipenv
```

さて、ここでpipenvを使おうとしたらエラーが生じた。
以下の参考に、 libffi-devを導入してPythonを再インストールしたらうまくいった。

https://stackoverflow.com/questions/27022373/python3-importerror-no-module-named-ctypes-when-using-value-from-module-mul

[Pipenvことはじめ] に大まかな使い方が載っている。

<!-- vim: set tw=0 ts=4 sw=4: -->
