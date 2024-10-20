---

title: Data Sovereignty
date: 2024-09-01 21:40:49
categories:
  - Knowledge Management
  - Data Spaces
tags:
  - Data Spaces

---

# メモ


## 世における基本的な考え方

データ主権（Data Sovereignty）については色々な解釈をされているが、
一つの考え方は特定地域で収集・保存されたデータがその地域の法律にしたがって運用されること、という考え方が挙げられる。

この考え方を示している記事が多い。

あまり量が多くなっても混乱するので、主要な話だけさらってみるようにする。

[簡単なまとめメモ](images/definition_data_sovereignty.pdf)

## セーフハーバー法

関連することとして、セーフハーバー法が挙げられる。つまり、特定の条件を満たす限り、違法行為とみなされない範囲を定めた規定である。
総務省の平成29年版白書では、 [第1部　特集　データ主導経済と社会変革] にEUと米国のセーフハーバーにちうて記載あり。
米国とEUの間では2000年に個人データ移転についての原則を記したセールハーバー協定を締結したのだが、いわゆるSnowden事件により欧州司法裁判所による無効の判断。そして、その後、2016/2にEU-USプライバシーシールが新たに制定。

## Snowden事件とデータローカライゼーション

データ保護については、Snowden事件や米国政府によるマイクロソフトのメール検閲を挙げるケースがある。
2013年ころのことである。参考： [世界を揺るがしたスノーデン事件から5年--変わったこと、変わらなかったこと]

ここから、欧州のGDPR（2016）やカナダのデータ主権措置に関する戦略（2016-2020）などのデータ越境移転に関する規定、
つまりデータローカライゼーション規定の流れが考えられる。 参考： [データローカライゼーション規制とは？必要となる背景や現状を徹底解説]
2022年当時の欧州、米国などのデータローカライゼーション規定については、経産省の「データの越境移転に関する研究会」資料がわかりやすい。
参考： [各国のデータガバナンスにおけるデータ越境流通に関連する制度調査]

著名なところだと、中国サイバーセキュリティ法（2017/6施行）の第37条が挙げられる。参考： [China’s data localization]
他にも、ベトナムのインターネットサービスとオンライン情報コンテンツの管理、提供、仕様に関する法令（2013/9制定）、インドネシアの法令では国内データセンタへのデータ配置が求められている（2014/1）、ロシアのデータローカライゼーション法（2015/9発行）など。

一方で、このようなデータローカライゼーションに関する制約はビジネスや技術発展において足かせとなるという主旨の論調もあった。
参考： [The Cloud’s Biggest Threat Are Data Sovereignty Laws]

日本からは、2019/1のスイス・ジュネーブにおける、いわゆるダボス会議にて、当時の首相だった安倍晋三からDFFTの提言があった。

## GDPRとData Act

データローカライゼーションの議論をする際には、EUにおけるGDPR（一般データ保護規則）は外せない。
個人データの移転と処理について規定したものである。2018年適用開始。参考： [GDPR（General Data Protection Regulation：一般データ保護規則）]

一方で、個人データだけではなく、非個人データを含むデータの利用促進、データへの公平なアクセスおよびその利用を目的として2020年の欧州データ戦略の一環としてData Actが成立。2024/1発効、2025/9施行。
IoT機器が生成するデータであり、非個人データも対象となる。自動車、スマート家電、などなど影響大。
参考： [EUデータ法の解説 - 適用場面ごとのルールと日本企業が講ずべき実務対応を整理] 、 [Data Act]

両者は補完関係と考えることもできる。

また、Data ActはData Governance Actとも補完関係と考えられる。

## 日本とEU・英国の間のデータ越境移転に関するセーフハーバー

欧州から日本に対しては、2019/1/23に十分性認定がされており、EU域内と同等の個人データ保護水準を持つ国と認定されている。 参考： [日EU間・日英間のデータ越境移転について]
日本は個人情報保護法第28条でEUを指定、EUはGDPR第45条に基づき日本を十分性認定。

ただし、個人情報保護法に基づき補完的ルール適用が必要。参考： [補完的ルール]
補完的ルールでは以下のような規定。

* 要配慮個人情報の範囲の拡張
* 保有個人データの範囲の拡張
* データ主体の権利保護
* データの安全管理措置

## まとめ

データ主権を議論する際には、基本的事項としてデータを収集・保存した地域における法律遵守が主旨になり、
さらにいわゆるデータローカライゼーションの原則が挙げられる。個人情報保護の観点がひとつは挙げられるが、それに限らない。
一方で経済や技術発展のためには、バランスをとったデータ越境移転が必要であり、DFFTのような提唱も行われている。

# 参考

* [Wikipediaの記載]
* [世界を揺るがしたスノーデン事件から5年--変わったこと、変わらなかったこと]
* [データローカライゼーション規制とは？必要となる背景や現状を徹底解説]
* [各国のデータガバナンスにおけるデータ越境流通に関連する制度調査]
* [China’s data localization]
* [第1部　特集　データ主導経済と社会変革]
* [日EU間・日英間のデータ越境移転について]
* [補完的ルール]
* [The Cloud’s Biggest Threat Are Data Sovereignty Laws]
* [GDPR（General Data Protection Regulation：一般データ保護規則）]
* [Data Act]
* [EUデータ法の解説 - 適用場面ごとのルールと日本企業が講ずべき実務対応を整理]

[Wikipediaの記載]: https://en.wikipedia.org/wiki/Data_sovereignty
[世界を揺るがしたスノーデン事件から5年--変わったこと、変わらなかったこと]: https://japan.zdnet.com/article/35120537/
[データローカライゼーション規制とは？必要となる背景や現状を徹底解説]: https://cybersecurity-jp.com/column/50934
[各国のデータガバナンスにおけるデータ越境流通に関連する制度調査]: https://www.meti.go.jp/shingikai/mono_info_service/data_ekkyo_iten/pdf/006_04_00.pdf
[China’s data localization]: https://www.tandfonline.com/doi/full/10.1080/17544750.2019.1649289
[第1部　特集　データ主導経済と社会変革]: https://www.soumu.go.jp/johotsusintokei/whitepaper/ja/h29/html/nc123210.html
[日EU間・日英間のデータ越境移転について]: https://www.ppc.go.jp/enforcement/cooperation/cooperation/sougoninshou/
[補完的ルール]: https://www.ppc.go.jp/files/pdf/Supplementary_Rules.pdf
[The Cloud’s Biggest Threat Are Data Sovereignty Laws]: https://techcrunch.com/2015/12/26/the-clouds-biggest-threat-are-data-sovereignty-laws/
[GDPR（General Data Protection Regulation：一般データ保護規則）]: https://www.ppc.go.jp/enforcement/infoprovision/EU/
[Data Act]: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32023R2854&qid=1704709568425
[EUデータ法の解説 - 適用場面ごとのルールと日本企業が講ずべき実務対応を整理]: https://www.businesslawyers.jp/articles/1374

<!-- vim: set et tw=0 ts=2 sw=2: -->
