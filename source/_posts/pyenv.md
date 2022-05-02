---

title: pyenv を使う
date: 2019-10-25 23:31:45
categories:
  - Knowledge Management
  - Python
  - pyenv
tags:
  - Python
  - pyenv

---

# 参考

* [環境構築 - pipenv で Python 環境の構築方法 (2018年11月版)]
* [pyenvのGitHub]
* [pyenvのインストール手順]
* [自動インストール]
* [Common-build-problems]

[環境構築 - pipenv で Python 環境の構築方法 (2018年11月版)]: https://www.pynote.info/entry/python_ubuntu_pipenv#3-pipenv-%E3%81%AE%E5%B0%8E%E5%85%A5
[pyenvのGitHub]: https://github.com/pyenv/pyenv
[pyenvのインストール手順]: https://github.com/pyenv/pyenv#installation
[自動インストール]: https://github.com/pyenv/pyenv-installer
[Common-build-problems]: https://github.com/pyenv/pyenv/wiki/Common-build-problems

# メモ

## インストール手順
WSL / WSL2にインストールするには、 [pyenvのGitHub] の通り、以下のようにインストールする。

```shell
$ git clone https://github.com/pyenv/pyenv.git ~/.pyenv
$ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
$ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
$ echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
```

## トラブルシューティング

[Common-build-problems] に載っているが、前提となるパッケージのインストールが必要なことに注意。

## 古い内容のバックアップ
[環境構築 - pipenv で Python 環境の構築方法 (2018年11月版)] ではpipenvを使う前に、pyenvを使ってPython3最新環境を導入している。

[自動インストール] に自動インストール手順が記載されている。

<!-- vim: set tw=0 ts=4 sw=4: -->
