---
title: "IDSA Connector Report 2026 — DSP 2025-1 と DCP 1.0 でコネクタエコシステムが成熟段階へ"
date: 2026-07-11
categories:
  - core
topic: "IDSA Connector Report 2026"
tags:
  - データスペース
  - コネクタ
  - DSP
  - DCP
  - Eclipse EDC
related:
  - "[[idsa]]"
  - "[[dataspace-protocol]]"
  - "[[eclipse-dataspace-components]]"
---

# IDSA Connector Report 2026 — DSP 2025-1 と DCP 1.0 でコネクタエコシステムが成熟段階へ

> [← 目次に戻る](README.md)

## 概要

[[idsa|IDSA]]（International Data Spaces Association）が2026年6月30日付で「Connector Report」を更新した。今回は [[dataspace-protocol|DSP 2025-1]] と [[decentralized-claims-protocol|DCP 1.0]] のリリースが主軸であり、テスト（[[dsp-tck|TCK]]）合格コネクタ数が8件に達するなど、データスペースのインフラが実装・拡張フェーズへ移行したことを示している。また、自動車業界主導だった [[eclipse-tractus-x|Tractus-X]] も他産業へ展開する「multi-industry」戦略へ舵を切った。

## 詳細

### プロトコル標準の確立: DSP 2025-1 と後方互換性

主要コネクタが共通標準として [[dataspace-protocol|DSP 2025-1]] を採択した。旧バージョン（DSP 0.8）との後方互換性も維持されており、既存のコネクタ資産を段階的に移行できる[^1]。

![DSPとDCPによるコネクタエコシステム](/memo-blog/images/idsa-connector-report-2026.png)

### DCP 1.0 と TCK 合格エコシステム

TCK合格コネクタは8件。[[eclipse-dataspace-components|EDC]]フレームワークをベースに、DCP 1.0およびDSP 2025-1のサポートが実装されている[^1]。特にDCP 1.0による分散クレーム認証（Decentralized Claims）が実用レベルに達したことで、データスペースにおけるアイデンティティ管理とコネクタ接続の統合が現実的になった。

### EDC の本番導入障壁の低下（単一ソース情報）

EDCの本番運用に向けた改善として、EDR（Endpoint Data Reference）トークンのリフレッシュ機能追加や、[[kubernetes|Kubernetes]]用Helm Chartの整備が挙げられている[^1]。これによりコンテナ環境での運用が標準化され、導入のハードルが下がった。

### Tractus-X の multi-industry 転換と EDWG 提携

Tractus-Xはこれまでの自動車業界（[[catena-x|Catena-X]]）特化から、複数産業や異なるデータスペースを繋ぐ「multi-dataspace / multi-industry」戦略へシフトした。2026年2月にマドリードで開催されたData Spaces Symposiumにおいて、[[eclipse-dataspace-working-group|EDWG]]との公式連携が合意されている[^2]。アーキテクチャは製造業、半導体、建設、化学などの他セクターへの横展開を見据えた設計に変更された[^2]。あわせて、IDS認証（Level 1〜2）の段階的な認定スキームも整備された[^1]。

## 考察

DSP 2025-1とDCP 1.0の同時リリースは、データスペースの技術レイヤーが仕様策定から実用フェーズへ入ったことを意味する。これまで各プロジェクトで個別実装されがちだったアイデンティティ連携がDCP 1.0として規格化され、異なるデータスペース間でも共通の信頼基盤を構築しやすくなった点は大きい。

Tractus-Xの他産業展開も、この技術的標準化が背景にある。Catena-Xで培った仕組みをポータブルな基盤として化学や半導体といった他業界に水平展開することで、IDSAや[[gaia-x|Gaia-X]]が描く「欧州データスペースの共通インフラ」という構想の実効性が高まる。

ただし、TCK合格コネクタがまだ8件に留まっている点は課題だ。実運用を広げるには、認定プロセスの効率化はもちろん、EDC以外の独自実装コネクタ（例えば国産コネクタや他ベンダーの軽量コネクタなど）の合格例が増える必要がある。

## 参考文献

[^1]: IDSA, "[IDSA Data Space Connector Report](https://internationaldataspaces.org/idsa-data-space-connector-report/)", アクセス日 2026-07-11
[^2]: Eclipse Tractus-X, "[Tractus-X Blog](https://eclipse-tractusx.github.io/blog/)", アクセス日 2026-07-11

## 更新履歴

- 2026-07-11: 初版

---

> この議題にフィードバック → [Issue を作成](https://github.com/dobachi/daily-curation-reports/issues/new?labels=feedback&title=%5B2026-07-11%2F01-idsa-connector-report-2026%5D+&body=%23%23+%E5%AF%BE%E8%B1%A1%E8%A8%98%E4%BA%8B%0Areports%2F2026%2F07%2F11%2F01-idsa-connector-report-2026.md%0A%0A%23%23+%E7%A8%AE%E5%88%A5%0A-+%5B+%5D+%E8%A8%82%E6%AD%A3%2F%E8%A3%9C%E8%B6%B3%0A-+%5B+%5D+%E7%B6%9A%E7%B7%A8%E5%B8%8C%E6%9C%9B%0A-+%5B+%5D+%E6%96%B0%E3%83%88%E3%83%94%E3%83%83%E3%82%AF%E7%A4%BA%E5%94%86%0A%0A%23%23+%E5%86%85%E5%AE%B9%0A%0A)
