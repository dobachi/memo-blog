---

title: Double count of dstat
date: 2021-04-09 08:28:03
categories:
  - Knowledge Management
  - Monitering
tags:
  - dstat

---

# 参考

* [total disk data include virtual lvm device data (so doubling the calculated values)]
* [dstat-real dstat]
* [dstatが開発終了した話]
* [dool]
* [pcp-dstatのman]

[total disk data include virtual lvm device data (so doubling the calculated values)]: https://github.com/dstat-real/dstat/issues/26
[dstat-real dstat]: https://github.com/dstat-real/dstat
[dstatが開発終了した話]: https://qiita.com/httpd443/items/e906fbcc7ca8d8d4585f
[dool]: https://github.com/scottchiefbaker/dool
[pcp-dstatのman]: https://man7.org/linux/man-pages/man1/pcp-dstat.1.html

# メモ

dstatのtotalが2倍？になる？という話があり簡単に確認。

## 結論

ディスク単位のI/Oを `total` に入れるべきなのだが、
正規表現上の仕様により、 `xvda1` などのパーティション単位のI/Oも `total` に足されている。

実は、パーティションの値を取り除く正規表現ではあるのだが、当時の実装（※）としては `xvd` で始まるディスク名に対応できていなかったようだ。
なお、その後、いくつか正規表現が改変されたような経緯がコミットログやGitHub Issueから見られた。

※CentOS7等で採用されたdstat0.7.2のリリース時期は2010年ころ

## 事象の確認

環境情報の確認。

```shell
[centos@ip-10-0-0-217 ~]$ uname -a
Linux ip-10-0-0-217.ap-northeast-1.compute.internal 3.10.0-1127.13.1.el7.x86_64 #1 SMP Tue Jun 23 15:46:38 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux

[centos@ip-10-0-0-217 ~]$ dstat --version
Dstat 0.7.2
Written by Dag Wieers <dag@wieers.com>
Homepage at http://dag.wieers.com/home-made/dstat/

Platform posix/linux2
Kernel 3.10.0-1127.13.1.el7.x86_64
Python 2.7.5 (default, Apr  2 2020, 13:16:51)
[GCC 4.8.5 20150623 (Red Hat 4.8.5-39)]

Terminal type: xterm-256color (color support)
Terminal size: 86 lines, 310 columns

Processors: 4
Pagesize: 4096
Clock ticks per secs: 100

internal:
        aio, cpu, cpu24, disk, disk24, disk24old, epoch, fs, int, int24, io, ipc, load, lock, mem, net, page, page24, proc, raw, socket, swap, swapold, sys, tcp, time, udp, unix, vm
/usr/share/dstat:
        battery, battery-remain, cpufreq, dbus, disk-tps, disk-util, dstat, dstat-cpu, dstat-ctxt, dstat-mem, fan, freespace, gpfs, gpfs-ops, helloworld, innodb-buffer, innodb-io, innodb-ops, lustre, memcache-hits, mysql-io, mysql-keys, mysql5-cmds, mysql5-conn, mysql5-io, mysql5-keys, net-packets, nfs3,
        nfs3-ops, nfsd3, nfsd3-ops, ntp, postfix, power, proc-count, qmail, rpc, rpcd, sendmail, snooze, squid, test, thermal, top-bio, top-bio-adv, top-childwait, top-cpu, top-cpu-adv, top-cputime, top-cputime-avg, top-int, top-io, top-io-adv, top-latency, top-latency-avg, top-mem, top-oom, utmp,
        vm-memctl, vmk-hba, vmk-int, vmk-nic, vz-cpu, vz-io, vz-ubc, wifi

[centos@ip-10-0-0-217 ~]$ lsblk
NAME    MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
xvda    202:0    0  60G  0 disk
└─xvda1 202:1    0  60G  0 part /
```

dstat 0.7.2は2010年にリリースされたようだ。

```shell
$ git log -1 --format=%ai 0.7.2
2010-06-14 22:25:44 +0000
```

参考までにpcpのバージョン

```shell
[centos@ip-10-0-0-217 ~]$ pcp --version
pcp version 4.3.2
```

ここから動作確認。

fioを実行。

```shell
[centos@ip-10-0-0-217 ~]$ fio -rw=randwrite -bs=16k -size=1000m -iodepth=32 -directory=/tmp -direct=1 -invalidate=1 -runtime=300 -numjobs=8 -name=iotest -ioengine=libaio -group_reporting

(snip)
```

裏でdstatを実行

```shell
[centos@ip-10-0-0-217 ~]$ dstat -td -D total,xvda                                                                                                                                                                                                                                                                     ----system---- -dsk/total----dsk/xvda-
     time     | read  writ: read  writ
09-04 08:40:50| 373k  315k: 187k  158k
09-04 08:40:51|   0    95M:   0    47M
09-04 08:40:52|   0    87M:   0    44M

(snip)
```

およそ2倍になっている。

pcp-dstatだと？

```shell
[centos@ip-10-0-0-217 ~]$ pcp dstat -td -D total,xvda
----system---- --dsk/xvda---dsk/total-
     time     | read  writ: read  writ
09-04 09:16:47|           :
09-04 09:16:48|   0    41M:   0    41M
09-04 09:16:49|   0    45M:   0    45M
09-04 09:16:50|   0    50M:   0    50M
09-04 09:16:51|   0    35M:   0    35M^

(snip)
```

ということで、2倍になっていない。

ちなみに、そもそもpcp-dstatは、上記のdstatとは全く異なる実装に見える。

doolだと？（2021/4/8時点のmasterブランチ）

```shell
[centos@ip-10-0-0-217 Sources]$ ./dool/dool -td -D total,xvda
-----system---- -dsk/total----dsk/xvda-
      time     | read  writ: read  writ
Apr-09 11:24:54| 577k 3307k: 289k 1653k
Apr-09 11:24:55|   0    66M:   0    33M
Apr-09 11:24:56|   0    25M:   0    13M
Apr-09 11:24:57|   0    44M:   0    22M^

(snip)
```

ということで、dstatと同様。

## 関連する実装は？

[dstat-real dstat] の実装を確認する。

`dstat_disk` クラスのコンストラクタに、後に用いられるフィルタ用の正規表現定義がある。

```python
 683         self.diskfilter = re.compile('^(dm-\d+|md\d+|[hsv]d[a-z]+\d+)$')
```

この正規表現を利用する箇所はいくつかあるが、その一つが `total` の値を計算するところ。
このフィルタにマッチしない場合に、 `total` に足される計算になっている。

```python
 728             if not self.diskfilter.match(name):
 729                 self.set2['total'] = ( self.set2['total'][0] + long(l[5]), self.set2['total'][1] + long(l[9]) )
```

ここで正規表現の中身を見ると、例えば `dm-0` 、 `sda1` のような「パーティション名」を表すものとマッチするようになっている。
つまり、 `not` 条件と合わせて、「パーティション名以外のものを `total` に足す」という動作になる。

このとき、よく見ると、今回使用した環境で用いている、 `xvda1` という名称は正規表現にマッチしないことがわかる。
したがって `total` に足されてしまい、なぜか `total` の表示が大きくなる、という事象が生じたと思われる。

[total disk data include virtual lvm device data (so doubling the calculated values)] にも似たような議論があるようだ。

## doolの登場

dstatの源流は今はメンテされておらず、 [dool] が開発されている。

> Dool is a Python3 compatible clone of Dstat.

また [dstatが開発終了した話] に記載されているが、他にもpcp系列のdstatが残っている。

ただし、doolにおいても、正規表現は同じようなものだった。

<!-- vim: set et tw=0 ts=2 sw=2: -->
