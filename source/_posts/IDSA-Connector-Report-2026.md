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

[[idsa|IDSA]]（International Data Spaces Association）は 2026 年 6 月 30 日付で Connector Report を更新し、[[dataspace-protocol|DSP 2025-1]] と [[decentralized-claims-protocol|DCP 1.0]] という節目のリリースを軸にコネクタエコシステムの成熟を報告した。TCK テスト合格コネクタ数は 8 件に達し、産業横断型の [[eclipse-tractus-x|Tractus-X]] は multi-industry 戦略へ転換するなど、データスペース基盤は導入フェーズから拡張フェーズへと移行しつつある。

## 詳細

### プロトコル標準 of 確立: DSP 2025-1 と後方互換性

DSP 2025-1 は主要コネクタの共通標準として採択され、旧バージョン（DSP 0.8）との後方互換性も維持されている[^1]。これにより既存コネクタ資産を持つ組織が段階的に移行できる経路が確保された。

![DSPとDCPによるコネクタエコシステム](/memo-blog/images/idsa-connector-report-2026.png)

### DCP 1.0 と TCK 合格エコシステム

[[dsp-tck|TCK]] テストに合格したコネクタは 8 件に達し、[[eclipse-dataspace-components|EDC]] フレームワーク上に DCP 1.0 と DSP 2025-1 サポートが構築されている[^1]。分散クレーム認証が本番利用可能な水準となり、デジタルアイデンティティと接続性の統合が現実的になった。

### EDC の本番導入障壁の低下（単一ソース情報）

EDR トークンリフレッシュ機能の追加と [[kubernetes|Kubernetes]]/Helm Chart 対応により、EDC の本番導入ハードルが低下したと報告されている（単一ソース情報）[^1]。コンテナ環境での運用標準化が採用を後押しする見込みだ。

### Tractus-X の multi-industry 転換と EDWG 提携

Tractus-X は multi-dataspace・multi-industry 戦略へ転換し、[[eclipse-dataspace-working-group|EDWG]] との公式提携が [[data-spaces-symposium-2026|Data Spaces Symposium 2026]]（マドリード、2 月）で正式化された[^2]。複数産業をサポートする拡張可能なアーキテクチャへの移行が進んでおり、Catena-X（自動車）に限らず、製造業・半導体・建設・化学など複数セクターへの横展開が設計上想定されている[^2]。また、IDS 認証 Level 1〜2 の段階的認定スキームが整備された[^1]。

## 考察

DSP 2025-1 と DCP 1.0 の同時成熟は、データスペースの技術スタックが「プロトコル策定期」から「実装検証期」へ移行したことを示す象徴的な出来事だ。特に DCP 1.0 が分散クレーム認証を本番利用可能にしたことで、コネクタ間のアイデンティティ連携が規格化され、異なる組織・産業間の信頼基盤が具体的に整いつつある。

Tractus-X の multi-industry 転換は、[[catena-x|Catena-X]] を超えた水平展開の準備として重要だ。単一産業向けデータスペースが複数産業のポータブルな基盤へ進化することで、IDSA/[[gaia-x|Gaia-X]] エコシステムが目指す「欧州データ経済の共通インフラ」という構想が現実的な射程に入る。

一方で、TCK 合格コネクタが 8 件という数字は成熟の証左である半面、産業規模での普及にはまだ量的拡大が必要だ。認定プロセスのスループット向上と、非 EDC ベースの多様なコネクタ実装の認定が今後の課題となる。

## 参考文献

[^1]: IDSA, "[IDSA Data Space Connector Report](https://internationaldataspaces.org/idsa-data-space-connector-report/)", アクセス日 2026-07-11
[^2]: Eclipse Tractus-X, "[Tractus-X Blog](https://eclipse-tractusx.github.io/blog/)", アクセス日 2026-07-11

## 更新履歴

- 2026-07-11: 初版

---

> この議題にフィードバック → [Issue を作成](https://github.com/dobachi/daily-curation-reports/issues/new?labels=feedback&title=%5B2026-07-11%2F01-idsa-connector-report-2026%5D+&body=%23%23+%E5%AF%BE%E8%B1%A1%E8%A8%98%E4%BA%8B%0Areports%2F2026%2F07%2F11%2F01-idsa-connector-report-2026.md%0A%0A%23%23+%E7%A8%AE%E5%88%A5%0A-+%5B+%5D+%E8%A8%82%E6%AD%A3%2F%E8%A3%9C%E8%B6%B3%0A-+%5B+%5D+%E7%B6%9A%E7%B7%A8%E5%B8%8C%E6%9C%9B%0A-+%5B+%5D+%E6%96%B0%E3%83%88%E3%83%94%E3%83%83%E3%82%AF%E7%A4%BA%E5%94%86%0A%0A%23%23+%E5%86%85%E5%AE%B9%0A%0A)
