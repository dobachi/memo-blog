---

title: SX-AuroraやFrovedis
date: 2018-11-23 22:16:00
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

* [まとめ情報のブログ]
* [SX-Auroraの簡単な紹介]
* [SX-Auroraの物理構成の解説]


[まとめ情報のブログ]: https://vectory.work/sx-aurora-tsubasa-information/
[SX-Auroraの簡単な紹介]: https://jpn.nec.com/rd/technologies/vectorprocessor/index.html
[SX-Auroraの物理構成の解説]: https://news.mynavi.jp/article/nec_aurora_tsubasa-3/
[NECとホートンワークスの協業]: https://jpn.nec.com/press/201810/20181015_01.html

# SX-Auroraの物理構成の解説 記事に記載された感想の抜粋

[SX-Auroraの物理構成の解説] に記載されていた考察を転記する。

> 一方、DGEMMではSX-Aurora TSUBASAはXeonの1.2倍程度の性能であり、V100が3.5程度であるのに比べて性能が低い。これはV100の方がピークFlopsが高いことが効いているのではないかと思われる。一方、Perf/WではSX-Aurora TSUBASAやV100は高い効率を示している。これは演算性能の割に消費電力が低いためと思われる。

> まとめであるが、SX-Aurora TSUBASAはAuroraアーキテクチャに基づく新しいスパコンの製品ラインである。従来のように独自のプロセサを作るのではなく、x86/Linuxの環境にベクタ処理を付加した形になっている。

> チップサイズの比較はともかく、NVIDIAのV100を16個搭載するDGX-2は約40万ドルで、V100 1個当たり250万円程度である。これに対して、SX-Aurora TSUBASAは、NECの発表では1VEのA100が170万円～、64VEのA500が1億2000万円～となっており、VE 1個あたり200万円弱である。これだけを見ると、NECの方が2割程度安いことになる。
> 
> しかし、これはいわゆる定価であり、実際のビジネスでは、これからどれだけ値引きされるのかは分からない。 Post-K(ポスト「京」)のような国家プロジェクトの無いNECがスパコンを開発するのは大変であるが、SX-Aurora TSUBASAはx86サーバにベクタエンジンを付けるという面白い切り口で挑んでいる。成功を祈る。

# NECとホートンワークスの協業 記事でのポイント

現在はYARN対応がポイントのようだ。
共同研究成果は、OSSとして公開するつもりのようだ。
