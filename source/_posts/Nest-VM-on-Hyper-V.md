---

title: Nest VM on Hyper-V
date: 2022-02-03 23:47:34
categories:
    - Knowledge Management
    - Hyper-V
tags:
    - Hyper-V

---

# メモ

[Get-VM] を利用して、VMの名称を確認する。

```shell
PS C:\Windows\system32> Get-VM   

(snip)

ubu18    Running 0           9344              24.00:30:35.9900000 正常稼働中 9.0    
```

[入れ子になった仮想化による仮想マシンでの Hyper-V の実行] の通り、VM 名称を指定しながら設定変更する。

```shell
PS C:\Windows\system32> Set-VMProcessor -VMName ubu18 -ExposeVirtualizationExtensions $true
```

# 参考

* [Get-VM]
* [入れ子になった仮想化による仮想マシンでの Hyper-V の実行]

[Get-VM]: https://docs.microsoft.com/ja-jp/powershell/module/hyper-v/get-vm?view=windowsserver2019-ps
[入れ子になった仮想化による仮想マシンでの Hyper-V の実行]: https://docs.microsoft.com/ja-jp/virtualization/hyper-v-on-windows/user-guide/nested-virtualization



<!-- vim: set et tw=0 ts=2 sw=2: -->
