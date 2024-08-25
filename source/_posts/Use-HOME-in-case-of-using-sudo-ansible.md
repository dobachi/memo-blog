---

title: 'Use HOME in case of using sudo [ansible]'
date: 2024-08-25 21:30:22
categories:
- Knowledge Management
- Ansible
tags:
- ansible

---

# メモ

[ansible で sudo 時に実行ユーザの HOME 環境変数を取得する] を参考にした。

以下のようなロールを作っておき、プレイブックの最初の方に含めておくと良い。
以降のロール実行時に、変数 `ansible_home` に格納された値を利用できる。

roles/regsiter_home/tasks/main.yml
```yaml
  - block:
    - name: Get ansible_user home directory
      shell: 'getent passwd "{{ansible_env.SUDO_USER}}" | cut -d: -f6'
      register: ansible_home_result

    - name: Set the fact for the other scripts to use
      set_fact:
        ansible_home: '{{ansible_home_result.stdout}}'
        cacheable: true
  tags:
    - register_home
```

元記事と変えているのは、SUDO実行ユーザ名を取るところ。環境変数から取るようにしている。

プレイブックでは以下のようにする。

playbooks/something.yml
```yaml
- hosts: "{{ server | default('mypc') }}"
  roles:
    - register_home
    - something

```

# 参考

* [ansible で sudo 時に実行ユーザの HOME 環境変数を取得する]

[ansible で sudo 時に実行ユーザの HOME 環境変数を取得する]: https://qiita.com/superbrothers/items/99d444e76deacae4985d






<!-- vim: set et tw=0 ts=2 sw=2: -->
