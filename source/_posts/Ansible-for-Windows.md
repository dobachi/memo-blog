---

title: Ansible for Windows
date: 2019-02-11 21:31:26
categories:
  - Knowledge Management
  - Windows
  - Ansible
tags:
  - Windows
  - Ansible
  - Configuration Management

---

# 参考

* [WindowsをAnsibleで管理する方法を説明するブログ]
* [Windows10 に ゼロから Ansible をインストールする(Ansible for Windows)]
* [AnsibleでWindowsのシェル実行]
* [chocolatey]
* [WSL導入手順の説明のブログ]

[WindowsをAnsibleで管理する方法を説明するブログ]: http://shigeluma-tech.hatenablog.com/entry/start-ansible-windows-server
[Windows10 に ゼロから Ansible をインストールする(Ansible for Windows)]: https://qiita.com/Tkm_Kit/items/58e1fb7990387a2e9c76
[chocolatey]: https://chocolatey.org/
[AnsibleでWindowsのシェル実行]: https://docs.ansible.com/ansible/latest/user_guide/windows_usage.html
[WSL導入手順の説明のブログ]: https://laboradian.com/simple-way-to-use-wsl-may-2018/

# メモ

[WindowsをAnsibleで管理する方法を説明するブログ]で基本的に問題ない。

## 最初の環境のはじめ方

### Ansibleのインストール、実行環境

[Windows10 に ゼロから Ansible をインストールする(Ansible for Windows)] ではDocker for Windowsで環境構築をしているが、
WSLを使う方法はどうだろうか？

### パッケージ管理

[chocolatey]を利用すればよいだろう。

## 注意点

### Ansible環境

自身の環境では、UbuntuのレポジトリからインストールしたAnsibleを使用していたが、
pywinrmを有効にする手間がかかりそうだったので、condaで環境を作った。

```
$ conda create -n ansible python
$ conda activate ansible
$ pip install ansible pywinrm
```

とした。

### Windows環境での実行ユーザ

MSアカウントに対しての実行が手間取りそうだったので、
ここではAdministratorで実験した。

Ansibleのインベントリは以下のようなものを用意した。

```
[win]
<対象となるWin環境>

[win:vars]
ansible_ssh_user=Administrator
ansible_ssh_port=5986
ansible_connection=winrm
ansible_winrm_transport=ntlm
ansible_winrm_server_cert_validation=ignore
```

Pingコマンドは以下の通り。 （パスワードを聞かれるので予め設定したAdministratorのパスワードを入れる）

```
$ ansible -i hosts.win -m win_ping win -k
```

パッケージインストールの動作確認は以下の通り。

```
$ ansible -i hosts.win -m win_chocolatey -a "name=googlechrome state=present" win -k
$ ansible -i hosts.win -m win_chocolatey -a "name=vim state=present" win -k
```

# シェルの実行

[AnsibleでWindowsのシェル実行] によると、`win_shell`、`win_command`、`script`モジュールを使うと良いようだ。

# WSL導入

[WSL導入手順の説明のブログ] の通り、PowerShellをAnsibleの`win_shell`モジュール使ってインストールする。
