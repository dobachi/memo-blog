---

title: check windows cpu resources
date: 2023-08-15 00:32:07
categories:
  - Knowledge Management
  - Windows
tags:
  - Windows

---

# メモ

マシンが暴走気味になることがあり、原因追跡するためにLinuxなどでいうpsコマンド相当の内容をログ取りたいと思った。
ので、軽く調べたところ、以下のウェブサイトがヒットした。

[Windows がなんか重いときにコマンドで調べる（WMIC PROCESS）]

上記サイトが丁寧に解説してくれている。
その中から、今回は [CPUの利用率でフィルタ] あたりを参考にした。

コマンド例

```powershell
WMIC PATH Win32_PerfFormattedData_PerfProc_Process WHERE "PercentUserTime > 1" GET Name,IDProcess,PercentUserTime,CommandLine /FORMAT:CSV
```

ユーザタイムが1%以上使われたものをリストしている。
もし行数制限したい場合は、 [PowerShellでhead,tail相当の処理を行う] あたりを参考にする。

コマンド例

```powershell
(WMIC PATH Win32_PerfFormattedData_PerfProc_Process WHERE "PercentUserTime > 1" GET Name,IDProcess,PercentUserTime /FORMAT:CSV)[0..10]
```

上記では、コマンドの引数が分からない。
そこで、それを詳細に調べようとすると、 [コマンドラインからプロセスを特定] を参考にするとよい。
おいおい、自動的に要素を結合できるようにしよう。

# 参考

* [Windows がなんか重いときにコマンドで調べる（WMIC PROCESS）] 
* [CPUの利用率でフィルタ] 
* [コマンドラインからプロセスを特定]

* [Windows10でCPUに負荷をかけるコマンドを紹介！]
* [PowerShellでhead,tail相当の処理を行う]

[Windows がなんか重いときにコマンドで調べる（WMIC PROCESS）]: https://qiita.com/qtwi/items/914021a8df608ab7792f
[CPUの利用率でフィルタ]: https://qiita.com/qtwi/items/914021a8df608ab7792f#cpu%E3%81%AE%E5%88%A9%E7%94%A8%E7%8E%87%E3%81%A7%E3%83%95%E3%82%A3%E3%83%AB%E3%82%BF
[コマンドラインからプロセスを特定]: https://qiita.com/qtwi/items/914021a8df608ab7792f#%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89%E3%83%A9%E3%82%A4%E3%83%B3%E3%81%8B%E3%82%89%E3%83%97%E3%83%AD%E3%82%BB%E3%82%B9%E3%82%92%E7%89%B9%E5%AE%9A

[Windows10でCPUに負荷をかけるコマンドを紹介！]: https://aprico-media.com/posts/6344
[PowerShellでhead,tail相当の処理を行う]: https://orebibou.com/ja/home/201501/20150114_001/





<!-- vim: set et tw=0 ts=2 sw=2: -->
