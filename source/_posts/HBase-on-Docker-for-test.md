---

title: HBase on Docker for test
date: 2019-06-03 00:31:51
categories:
  - Knowledge Management
  - HBase
tags:
  - HBase
  - Docker

---

# 参考

* [HariSekhon/Dockerfiles]
* [dajobe/hbase-docker]

[HariSekhon/Dockerfiles]: https://github.com/HariSekhon/Dockerfiles
[dajobe/hbase-docker]: https://github.com/dajobe/hbase-docker

# メモ

最初は、 [dajobe/hbase-docker] を試そうとしたが、後から [HariSekhon/Dockerfiles] を見つけた。
この中の `hbase` ディレクトリ以下にある手順に従ったところ、無事に起動した。

[HariSekhon/Dockerfiles] は、ほかにもビッグデータ系のプロダクトのDockerイメージを配布しているようだ。

ただ、Dockerfileを見ると割と作りこまれているようなので、動作確認にはよいがまじめな環境としてはきちんと見直してから使う方がよさそう。
