---

title: Getting started of Ansible Vault
date: 2021-01-07 09:43:12
categories:
  - Knowledge Management
  - Configuration Management
  - Ansible
tags:
  - Ansible
  - Vault

---

# 参考

## 公式サイト

* [Encrypting content with Ansible Vault]

[Encrypting content with Ansible Vault]: https://docs.ansible.com/ansible/latest/user_guide/vault.html#managing-vault-passwords

## ブログ

* [Ansible-Vaultを用いた機密情報の暗号化のTips]

[Ansible-Vaultを用いた機密情報の暗号化のTips]: https://qiita.com/takuya599/items/2420fb286318c4279a02


# メモ

Ansible内で使用する変数を平文でファイルに記載し、プレイブック集に入れ込むのに不安を感じるときがある。
そのようなとき、Ansible Vaultを利用すると暗号化された状態で変数を管理できる。
Ansible Vaultで管理された変数をプレイブック内で通常の変数と同様に扱えるため見通しが良くなる。

公式サイトの [Encrypting content with Ansible Vault] が網羅的でわかりやすいのだが、
具体例が足りない気がしたので以下に一例を示しておく。
ここに挙げた以外の使い方は、公式サイトを参照されたし。

[Ansible-Vaultを用いた機密情報の暗号化のTips] も参考になった。


## 暗号化されたファイルの作成

`secret.yml` 内に変数を記述し、暗号化する。
後ほど暗号化されたファイルを変数定義ファイルとして読み込む。

ここでは以下のような内容とする。

secret.yml

```yaml
hoge:
  fuga: foo
```

ファイルを暗号化する。

```shell
$ ansible-vault create secret.yml
```

上記ファイルを作成する際、Vault用パスワードを聞かれるので適切なパスワードを入力すること。
あとでパスワードは利用する。

## （参考）復号して平文化

```shell
$ ansible-vault decrypt secret.yml
```

## （参考）暗号化されたファイルの編集

```shell
$ ansible-vault edit secret.yml
```

## （参考）Vaultパスワードをファイルとして渡す

プロンプトで入力する代わりに、どこかプレイブック集の外などにVaultパスワードを保存し利用することもできる。
ここでは、 `~/.vault_password` にパスワードを記載したファイルを準備したものとする。
編集する例を示す。

```shell
$ ansible-vault edit secret.yml --vault-password-file ~/.vault_password
```

## プレイブック内で変数として利用

変数定義ファイルとして渡し、プレイブック内で変数として利用する。
以下のようなプレイブックを作る。

test.yml

```yaml
- hosts: localhost
  vars_files:
    - secret.yml
  tasks:
    - name: debug
      debug:
        msg: "{{ hoge.fuga }}"
```

以下、簡単な説明。

* 変数定義ファイルとして `secret.yml` を指定（ `vars_files` の箇所）
* 今回はdebugモジュールを利用し、変数内の値を表示することとする。
* 暗号化された変数定義ファイル `secret.yml` に記載されたとおり、構造化された変数 `hoge.fuga` の値を利用する。
* 結果として、`foo` という内容がSTDOUTに表示されるはず。

プレイブックを実行する。

```shell
$ ansible-playbook test.yml --ask-vault-pass
```

<!-- vim: set et tw=0 ts=2 sw=2: -->
