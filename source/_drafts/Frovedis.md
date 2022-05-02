---

title: Frovedisについて少し調べてみる
date: 2018-11-23 23:44:02
categories:
  - Research
  - SX-Aurora/Frovedis
tags:
  - SX-Aurora
  - Frovedis
  - Vector Engine
  - HPC

---

# 参考

* [FrovedisのGitHub]
* [Frovedisのリリース情報]
* [公式チュートリアル]

[FrovedisのGitHub]: https://github.com/frovedis/frovedis
[Frovedisのリリース情報]: https://github.com/frovedis/frovedis/releases
[公式チュートリアル]: https://github.com/frovedis/frovedis/blob/master/doc/tutorial/tutorial.md

# 手元の環境で動かしてみる

## RPMでインストール

[Frovedisのリリース情報] から得られた frovedis-0.8.0-3.x86_64.rpm をインストールしようとしたところ、
自分の手元の環境では以下のように広い依存関係だった。（すでにインストール済のパッケージもあるため、あくまで現状に対する
インストールの結果）

```
Installing:                                 
 frovedis                                   
Installing for dependencies:                
 agg                                        
 atlas                                      
 blas                                       
 blosc                                      
 boost                                      
 boost-atomic                               
 boost-chrono                               
 boost-context                              
 boost-devel                                
 boost-filesystem                           
 boost-graph                                
 boost-iostreams                            
 boost-locale                               
 boost-math                                 
 boost-program-options                      
 boost-python                               
 boost-random                               
 boost-regex                                
 boost-serialization                        
 boost-signals                              
 boost-test                                 
 boost-timer                                
 boost-wave                                 
 gcc                                        
 gcc-c++                                    
 gcc-gfortran                               
 glibc-devel                                
 glibc-headers                              
 hdf5                                       
 kernel-headers                             
 lapack                                     
 libaec                                     
 libgfortran                                
 libquadmath                                
 libquadmath-devel                          
 libstdc++-devel                            
 numpy                                      
 numpy-f2py                                 
 python-Bottleneck                          
 python-devel                               
 python-matplotlib                          
 python-nose                                
 python-pandas                              
 python-tables                              
 python2-numexpr                            
 scipy                                      
 suitesparse                                
 t1lib                                      
 tbb                                        
 texlive-base                               
 texlive-dvipng                             
 texlive-dvipng-bin                         
 texlive-kpathsea                           
 texlive-kpathsea-bin                       
Updating for dependencies:                  
 python                                     
 python-libs                                
```

結果として、 `/opt/nec/nosupport/frovedis` にインストールされる。

## チュートリアル実行

チュートリアル記載通り、`tut2.1`に移動して、makeし、mpirunする。
なお、チュートリアルではPATHが通っている前提のようだが、mpirunコマンド実行の際には
フルパス指定した。

```
$ cd /opt/nec/nosupport/frovedis/x86/doc/tutorial/src/tut2.1
$ make
$ /opt/nec/nosupport/frovedis/x86/opt/openmpi/bin/mpirun -np 4 ./tut
2
4
6
8
10
12
14
16
```

動いた。

## チュートリアルの説明を読んでみる

初期化のあたりが気になったので軽く眺めてみた。

src\frovedis\core\frovedis_init.hpp:10

```
  use_frovedis(int argc, char* argv[]) {
    initfrovedis(argc, argv);
  }
```

以下のように`initfrovedis`の中で、`MPI_Init`等が呼ばれていることが分かる。

src\frovedis\core\frovedis_init.hpp:351

```
void initfrovedis(int argc, char* argv[]) {
#ifdef USE_THREAD
  int provided;
  int err = MPI_Init_thread(&argc, &argv, MPI_THREAD_SERIALIZED, &provided);
  if(err != 0) {
    cerr << "MPI_THREAD_SERIALIZED is not supported. exiting." << endl;
    MPI_Finalize();
    exit(1);
  }
#else
  MPI_Init(&argc, &argv);
#endif
  MPI_Comm_dup(MPI_COMM_WORLD, &frovedis_comm_rpc);
  MPI_Comm_rank(MPI_COMM_WORLD, &frovedis_self_rank);
  MPI_Comm_size(MPI_COMM_WORLD, &frovedis_comm_size);

  if(frovedis_self_rank != 0) {
    handle_req();
  }
}
```


## チュートリアル実行（失敗例）

※注意はじまり※
以下の例では、`git clone`したソースコードに対して実行しているため、
チュートリアルで読んだ流れとは異なることに途中で気が付いた。
あくまで備忘録として残す。
※注意おわり※

[公式チュートリアル] を試してみる。
ここではFrovedisはRPMを使ってインストール済みとする。

上記チュートリアルは、いきなり `./src/tut2.1` 以下のmakeから始まるが、
`../Makefile.each` がないために失敗する。

またチュートリアルのディレクトリに移動し、make.shを実行してみたところ、以下のようなエラーになった。

```
$ cd ~/Sources/frovedis/doc/tutorial/src
$ ./make.sh
Please 'ln -s Makefile.each.[x86, ve, or sx] Makefile.each' according to your architecture
```

どうやらシンボリックリンクを作る想定らしい。

```
$ ln -s Makefile.each.x86 Makefile.each
```

続いてmakeしたところエラー。

```
$ ./make.sh
mpic++ -c -fPIC -g -Wall -O3 -std=c++11 -Wno-unknown-pragmas -Wno-sign-compare -pthread -I../../../../src/ -I../../../../third_party/cereal-1.2.2/include/ tut.cc -o tut.o
make: mpic++: Command not found
make: *** [tut.o] Error 127
```

なんとなくだが、Frovedisインストール時に配備されていないか？と思ったら、その通りだった。

```
$ sudo find / -name *mpic++*
/opt/nec/nosupport/frovedis/x86/opt/openmpi/bin/mpic++
/opt/nec/nosupport/frovedis/x86/opt/openmpi/share/man/man1/mpic++.1
/opt/nec/nosupport/frovedis/x86/opt/openmpi/share/openmpi/mpic++-wrapper-data.txt
```

もしかしたら、いったんこの手のディレクトリをPATH通した方が良いかも？

```
$ export PATH=$PATH:/opt/nec/nosupport/frovedis/x86/opt/openmpi/bin
$ export PATH=$PATH:/opt/nec/nosupport/frovedis/x86/bin
```

※なお、`/etc/profile.d/frovedis.sh`に上記PATH追加を記述することにした。

再びmakeしたところ以下のエラーが変わった。

```
$ ./make.sh

(snip)
pic++ -c -fPIC -g -Wall -O3 -std=c++11 -Wno-unknown-pragmas -Wno-sign-compare -pthread -I../../../../src/ -I../../../../third_party/cereal-1.2.2/include/ tut.cc -o tut.o
mpic++ -fPIC -g -Wall -O3 -std=c++11 -Wno-unknown-pragmas -Wno-sign-compare -pthread -I../../../../src/ -I../../../../third_party/cereal-1.2.2/include/ -o tut tut.o -L../../../../third_party/lib -L../../../../src/frovedis/core -L../../../../src/frovedis/matrix -L../../../../src/frovedis/ml -L../../../../src/frovedis/dataframe -lfrovedis_dataframe -lfrovedis_ml -lfrovedis_matrix -lfrovedis_core -lparpack -lscalapack -llapack -lcblas -lblas -lboost_program_options -lboost_serialization -lboost_system -lpthread -lgfortran -lrt `mpif90 -showme:link`
/usr/bin/ld: cannot find -lfrovedis_dataframe
/usr/bin/ld: cannot find -lfrovedis_ml
/usr/bin/ld: cannot find -lfrovedis_matrix
/usr/bin/ld: cannot find -lfrovedis_core
/usr/bin/ld: cannot find -lparpack
/usr/bin/ld: cannot find -lscalapack
/usr/bin/ld: cannot find -llapack
/usr/bin/ld: cannot find -lcblas
/usr/bin/ld: cannot find -lblas
collect2: error: ld returned 1 exit status
make: *** [tut] Error 1
(snip)
```

以下の通り、たしかにライブラリが含まれていない。

```
$ ldconfig -p | grep frovedis
```

```
# echo /opt/nec/nosupport/frovedis/x86/lib > /etc/ld.so.conf.d/frovedis.conf
```

※注意※
このあたりでふと、`/opt`配下にインストールされた方で実行すればよいのでは？と気が付いた。
