---
title: "EU Data Act B2B by design 2026 — 日本の電気・機械メーカーへの具体的影響"
date: 2026-07-10
categories:
  - core
topic: "EU Data Act B2B by design 2026"
tags:
  - EU Data Act
  - B2B by design
  - 日本製造業
  - FRAND
related:
  - "data-act"
  - "frand"
---

# EU Data Act B2B by design 2026 — 日本の電気・機械メーカーへの具体的影響

## 概要

EU Data Act（EU規則2023/2854）は、コネクテッド製品のデータアクセス権を段階的に義務化する規則だ。2025年9月12日のPhase 1施行に続き、2026年9月12日にはアクセス機能を製品設計段階で組み込む「access-by-design」義務が発効する。EU市場で製品を販売する日本の電気・機械メーカーは、設立地を問わず規制対象となる。対応すべき実務は、製品再設計・契約対応・法的代理人の選任の3点に整理できる。

## 詳細

### Phase 1 → Phase 2 の段階的義務化

EU Data Act の施行は二段階に分かれている。2025年9月12日のPhase 1では、EU向けコネクテッド製品のメーカーに対し、B2B・B2Cを問わずユーザーへのデータアクセス権の付与が義務付けられた[^1][^2]。データは「遅延なく、無償で、継続的かつリアルタイムに」提供しなければならない。ただし規則本文（第4条）では、継続的・リアルタイムの提供は「関連性があり技術的に可能な場合」に限られる[^2]。

2026年9月12日からのPhase 2では、この日以降にEU市場へ新規投入するコネクテッド製品に「access-by-design」義務が課される。データアクセス機能を、デフォルトで容易・安全・直接に利用できる形で製品設計段階から実装する必要がある（第3条、「関連性があり技術的に可能な場合」の限定付き）[^1]。過去に上市済みの製品を遡及的に再設計する義務ではないが、同一モデルでも2026年9月12日以降に初めて出荷する個体は本義務の対象となる。

なお「Phase 1 / Phase 2」は施行スケジュールを説明するための呼称で、規則本文が用いる法令用語ではない。

![EU Data Act の段階的義務化と日本メーカーへの適用](/memo-blog/images/eu-data-act-b2b-2026.png)

### 日本メーカーへの適用範囲

日本に法人を置くメーカーでも、EU市場でコネクテッド製品を販売する場合は規制対象となる[^1][^2]。Data Act は特定業界に限定しない水平規則で、データ収集・通信機能を持つ産業機器・農業機械・医療機器が対象に含まれる[^2]。IoT機能を搭載した工場設備や農業用機械も対象になりうる。

### B2B・B2C 双方への適用とFRAND条件

データアクセス権はビジネスユーザー（B2B）にも消費者（B2C）にも等しく適用される[^1][^2]。B2Bのデータ共有には、FRAND（公正・合理的・非差別的）条件が義務付けられる[^2]。中小企業（SME）向けのデータ提供対価は、データ提供にかかる直接コストを上限とし、利益マージンを上乗せできない（第9条2項）[^2]。

## 考察

2026年9月の「access-by-design」義務は、要求仕様を後付けで満たす「パッチ型」対応では費用対効果が悪い。製品ロードマップへ前倒しで統合する方が合理的だ。特に影響が大きいのは、「データはメーカーが保有・活用する」という前提のまま開発されてきたIoT機器群で、アーキテクチャ全体の見直しを迫られる。

FRAND条件の実装では、データ仲介レイヤーや標準API仕様の活用が実務的な選択肢になる。あわせて、EU域外企業に課される法的代理人の選任要件は、日本企業が見落としやすい実務コストであり、早めの手当てが要る。

## 参考文献

[^1]: Wilson Sonsini, "[EU Data Act September 2026 Deadline: What Businesses Need to Know](https://www.wsgrdataadvisor.com/2026/06/eu-data-act-september-2026-deadline-what-businesses-need-to-know/)", アクセス日 2026-07-10
[^2]: Faegre Drinker, "[The EU Data Act: Impact on Connected Products and Device Manufacturers](https://www.faegredrinker.com/en/insights/publications/2025/8/the-eu-data-act-impact-on-connected-products-and-device-manufacturers)", アクセス日 2026-07-10

## 更新履歴

- 2026-07-10: 初版
