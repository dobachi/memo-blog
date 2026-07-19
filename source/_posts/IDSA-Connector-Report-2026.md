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
  - "idsa"
  - "dataspace-protocol"
  - "eclipse-dataspace-components"
---

# IDSA Connector Report 2026 — DSP 2025-1 と DCP 1.0 でコネクタエコシステムが成熟段階へ

## 概要

IDSA（International Data Spaces Association）が2026年6月30日付で「Connector Report」を更新した。今回は DSP 2025-1 と DCP 1.0 のリリースが主軸であり、テスト（TCK）合格コネクタ数が8件に達するなど、データスペースのインフラが実装・拡張フェーズへ移行したことを示している。また、自動車業界主導だった Tractus-X も他産業へ展開する「multi-industry」戦略へ舵を切った。

## 詳細

### プロトコル標準の確立: DSP 2025-1 と後方互換性

主要コネクタが共通標準として DSP 2025-1 を採択した。旧バージョン（DSP 0.8）との後方互換性も維持されており、既存のコネクタ資産を段階的に移行できる[^1]。

![DSPとDCPによるコネクタエコシステム](/memo-blog/images/idsa-connector-report-2026.png)

### DCP 1.0 と TCK 合格エコシステム

TCK合格コネクタは8件。EDCフレームワークをベースに、DCP 1.0およびDSP 2025-1のサポートが実装されている[^1]。特にDCP 1.0による分散クレーム認証（Decentralized Claims）が実用レベルに達したことで、データスペースにおけるアイデンティティ管理とコネクタ接続の統合が現実的になった。

### DSP 2025-1 と DCP 1.0 の役割分担

DSP と DCP は、いずれも Eclipse Dataspace Working Group（EDWG）が管理する別々の仕様だが、レイヤーが異なり互いを補完する。

| 仕様 | 担うレイヤー | 標準化する範囲 |
|------|-------------|----------------|
| DSP 2025-1 | データ取引の制御 | カタログ（アセットとODRLポリシーの公開・発見）、契約交渉のステートマシン、データ転送プロセスの制御 |
| DCP 1.0 | アイデンティティと信頼 | Verifiable Presentation の提示・検証、クレデンシャル発行、自己署名アイデンティティトークンの形式 |

DSP は認証方式に対して中立で、HTTPSリクエストは `Authorization` ヘッダにトークンを載せる（SHOULD）とだけ定め、「トークンの意味づけは本仕様の対象外」としている。中身が OAuth2 か OIDC か分散IDかは問わない[^3]。DCP はそこに載せるトークンとして、W3C の Verifiable Credential / Presentation や自己署名アイデンティティトークンの生成・検証手順を定める[^4]。

EDCベースのコネクタでは、両者は次のように組み合わさる。消費者コネクタが Credential Service（Identity Hub）で DCP 準拠のトークンを生成し、DSP の各メッセージ（カタログ取得・契約交渉・転送要求）の `Authorization` ヘッダに載せて送る。受け取ったプロバイダは DCP の手順でトークンとクレデンシャルを検証し、相手がデータスペースの正規メンバーか、契約を結ぶ属性を満たすかを判定してから、DSP のカタログ・交渉・転送処理を実行する[^4]。検証は特定の一点ではなく、カタログ要求・契約交渉・データ転送の各段階で行われる。

なお DSP 2025-1 は DCP を規範的に必須とはしていない。OAuth2 や OIDC といった集中型・フェデレーション型の認証と組み合わせることも仕様上は可能である[^3]。ただし分散・主権型のデータスペースを構築する EDC や Catena-X の実装では、DSP と DCP をペアで導入する構成が事実上の標準になっている[^4]。

### EDC の本番導入障壁の低下（単一ソース情報）

EDCの本番運用に向けた改善として、EDR（Endpoint Data Reference）トークンのリフレッシュ機能追加や、Kubernetes用Helm Chartの整備が挙げられている[^1]。これによりコンテナ環境での運用が標準化され、導入のハードルが下がった。

### Tractus-X の multi-industry 転換と EDWG 提携

Tractus-Xはこれまでの自動車業界（Catena-X）特化から、複数産業や異なるデータスペースを繋ぐ「multi-dataspace / multi-industry」戦略へシフトした。2026年2月にマドリードで開催されたData Spaces Symposiumにおいて、EDWGとの公式連携が合意されている[^2]。アーキテクチャは製造業、半導体、建設、化学などの他セクターへの横展開を見据えた設計に変更された[^2]。あわせて、IDS認証（Level 1〜2）の段階的な認定スキームも整備された[^1]。

## 考察

DSP 2025-1とDCP 1.0の同時リリースは、データスペースの技術レイヤーが仕様策定から実用フェーズへ入ったことを意味する。これまで各プロジェクトで個別実装されがちだったアイデンティティ連携がDCP 1.0として規格化され、異なるデータスペース間でも共通の信頼基盤を構築しやすくなった点は大きい。

Tractus-Xの他産業展開も、この技術的標準化が背景にある。Catena-Xで培った仕組みをポータブルな基盤として化学や半導体といった他業界に水平展開することで、IDSAやGaia-Xが描く「欧州データスペース of 共通インフラ」という構想の実効性が高まる。

ただし、TCK合格コネクタがまだ8件に留まっている点は課題だ。実運用を広げるには、認定プロセスの効率化はもちろん、EDC以外の独自実装コネクタ（例えば国産コネクタや他ベンダーの軽量コネクタなど）の合格例が増える必要がある。

## 参考文献

[^1]: IDSA, "[IDSA Data Space Connector Report](https://internationaldataspaces.org/idsa-data-space-connector-report/)", アクセス日 2026-07-11
[^2]: Eclipse Tractus-X, "[Tractus-X Blog](https://eclipse-tractusx.github.io/blog/)", アクセス日 2026-07-11
[^3]: Eclipse Dataspace Working Group, "[Dataspace Protocol](https://github.com/eclipse-dataspace-protocol-base/DataspaceProtocol)", アクセス日 2026-07-12
[^4]: Eclipse Dataspace Working Group, "[Decentralized Claims Protocol](https://github.com/eclipse-dataspace-dcp/decentralized-claims-protocol)", アクセス日 2026-07-12

## 更新履歴

- 2026-07-11: 初版
- 2026-07-12: 「DSP 2025-1 と DCP 1.0 の役割分担」章を追加
