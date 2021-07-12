---

title: Ansibleでコマンド実行結果のJSONを辞書型に変換して用いる
date: 2019-02-14 22:06:57
categories:
  - Knowledge Management
  - Configuration Management
  - Ansible
tags:
  - Ansible
  - JSON
  - Windows
  - PowerShell

---

# 参考

* [Ansible で task の実行結果の json を dict オブジェクトとして後続の処理で利用する]

[Ansible で task の実行結果の json を dict オブジェクトとして後続の処理で利用する]: https://ceblog.mediba.jp/post/154705974072/ansible-%E3%81%A7-task-%E3%81%AE%E5%AE%9F%E8%A1%8C%E7%B5%90%E6%9E%9C%E3%81%AE-json-%E3%82%92-dict

# メモ

[Ansible で task の実行結果の json を dict オブジェクトとして後続の処理で利用する] に記載の内容で問題ない。
自分の場合は、AnsibleでWindows PowerShellの実行結果を受け取るときに、オブジェクトをJSONに変換し、
それを辞書型に変換した上で後々when構文で使いたかった。

例）

```
      - name: check_state_of_wsl
        win_shell: Get-WindowsOptionalFeature -Online | ? FeatureName -Match "Microsoft-Windows-Subsystem-Linux" |  ConvertTo-Json
        register: wsl_check_json

      - set_fact:
          wsl_check: "{{ wsl_check_json.stdout }}"
  
      - name: enable_wsl
        win_shell: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        when: wsl_check.State != 2

```
