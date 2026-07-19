---
title: "Apache Iceberg と REST Catalog の仕組み — 調べて、動かして確かめた"
date: 2026-07-19
categories:
  - Storage Layer
topic: "Apache Iceberg と REST Catalog"
tags:
  - Apache Iceberg
  - Iceberg REST Catalog
  - Apache Polaris
  - PyIceberg
  - レイクハウス
related:
  - "apache-iceberg"
  - "apache-polaris"
---

# Apache Iceberg と REST Catalog の仕組み — 調べて、動かして確かめた

## 概要

Apache Iceberg とその REST Catalog について、一次情報の裏取りを前提に調べ、あわせてローカル環境で実際に動かして確かめた。結果は2つのサイトに公開している。

- [Apache Iceberg 調査報告書](https://dobachi.github.io/iceberg-research/)[^1] — 仕様・カタログ実装・エンジン対応・運用の文献調査
- [Iceberg REST Lab](https://dobachi.github.io/iceberg-rest-lab/)[^2] — Apache Polaris と PyIceberg を使った実験記録

本記事はその要点で、Iceberg の中核である**メタデータ構造とコミットの仕組み**を中心にまとめる。どちらも個人的な調査メモであり、本番環境での利用を想定したものではない。

調べる過程で強く感じたのは、Iceberg では**仕様と実装の距離が大きい**ということだ。仕様が定めていることと、ある実装が実際にできることは一致しない。この記事でも、仕様の記述と、手元で観測した挙動を分けて書く。

検証環境は Apache Iceberg 1.11.0 / PyIceberg 0.11.1 / Apache Polaris 1.6.0、検証基準日は 2026-07-17 である。

## 詳細

### Iceberg とは何か（そして何でないか）

Iceberg はデータの保存形式ではない。データ本体は Parquet や ORC、Avro のままで、Iceberg が定めるのは**そのファイル群を1つのテーブルとして扱うための取り決め**、つまりテーブル仕様である[^3]。

実体はオブジェクトストレージ上のファイル群だ。データも、スキーマも、スナップショットの履歴も、すべて S3 上に置かれる。ではカタログは何を持っているのかというと、**「このテーブルの最新の metadata.json はどれか」というポインタ1本だけ**である。

この一点を押さえると、後の仕組みがつながる。Iceberg のコミットとは、カタログが持つポインタを新しい metadata.json に差し替えることに他ならない。

### 三層のメタデータ構造

ポインタの先は次のように連なる。

```
catalog → metadata.json → manifest list → manifest → data file
```

なぜ間に2層も挟むのか。**クエリプランニングで段階的に枝刈りするため**である。

第1段では manifest list に記録された各 manifest のパーティション要約統計だけを見て、manifest ファイル自体を開かずにスキップを判定する。第2段で残った manifest を開き、第3段で data file ごとの列統計（lower_bound / upper_bound）を使ってファイル単位で除外する。述語に合致しないファイルは、開かれることなく落ちる。

裏を返すと、**統計が効かない条件ではこの枝刈りが働かない**。既定値には注意が要る。

- `write.metadata.metrics.default = truncate(16)` — 文字列の境界値は16文字で切り詰められる。URL のように共通プレフィックスが長い列では、`https://example.` までしか記録されず、ファイル間で境界値が同一になる。どの述語を投げても1ファイルも枝刈りできない
- `write.metadata.metrics.max-inferred-column-defaults = 100` — 101列目以降には既定でメトリクスが収集されない。ワイドテーブルで後方の列に述語をかけると全ファイル読みになる

どちらも「遅い」という形でしか表面化せず、原因にたどり着きにくい。

メタデータの肥大も構造上の帰結だ。手元の実験では、5行のデータを3回に分けて書いただけで、**manifest ファイル（4434〜4438バイト）のほうが、それが記述する data file（1746〜1753バイト）より大きい**状態になった。append 1回がスナップショット1個と metadata JSON 1個を生むためで、これは最適化の余地ではなく原子性のための要件である。高頻度コミットがメタデータを膨らませるのはこのためだ。

### コミットは「ポインタの差し替え」

REST Catalog のコミットは `POST /v1/{prefix}/namespaces/{namespace}/tables/{table}` で行う。ボディは2つの配列でできている[^4]。

- `requirements` — コミット前に成り立っていなければならない条件の表明（`assert-table-uuid`、`assert-ref-snapshot-id` など）
- `updates` — 適用したい変更（`set-properties`、`add-snapshot`、`set-snapshot-ref` など）

サーバは requirements を現在の状態と突き合わせ、**すべて満たされる場合にだけ** updates を適用する。requirements は「自分が読んだ版はこれだ」という宣言であり、その版が変わっていればコミットは拒否される。

これが compare-and-swap による楽観的並行制御である。ロックを取らずに書きに行き、書く瞬間に「読んだときから変わっていないこと」を条件として付ける。衝突がまれであれば、ロックの管理コストを払わずに済む。

実際に古いスナップショット ID を表明して投げると、次のように拒否された。

```json
{
  "error": {
    "message": "Requirement failed: branch main has changed: expected id 1234567890123456789 != 1472481652836649450",
    "type": "CommitFailedException",
    "code": 409
  }
}
```

エラーメッセージが期待値と実際の値の両方を含んでいる。同時に送った `set-properties` は適用されていなかった。requirements が1つでも失敗すれば updates は一切適用されず、中途半端な状態が残ることはない。

requirements を正しい値に直して再送すると成功し、`metadata-location` が `00001-...` から `00002-...` へ移った。これがコミットの実体である。

なお仕様は、未知の requirement や update を受け取ったサーバは 400 で失敗しなければならないと定めている[^4]。黙って読み飛ばす実装があると、クライアントは検証されたつもりでコミットが通ってしまうためだ。

### 409 と 500 を分ける理由

コミットの失敗には、意味がまったく違う2種類がある。この区別を誤るとデータが壊れる。

| ステータス | 型 | 意味 | リトライ |
|---|---|---|---|
| 409 | `CommitFailedException` | requirements が満たされなかった。**確実に適用されていない** | 安全。読み直して再送 |
| 500 | `CommitStateUnknownException` | サーバが結果を確定できなかった。**適用されたか不明** | 危険。そのまま再送してはいけない |

500 が厄介なのは、成功したかもしれないことだ。ポインタを書き換えたあと応答を返す前に落ちた場合がこれにあたる。単純にリトライすると、同じスナップショットをもう一度追加してしまう。

これを解消するのが `Idempotency-Key` ヘッダで、同じ鍵のリクエストをサーバが2回目以降は処理せず1回目の結果を返す。ただし対応は必須ではない。仕様は `GET /v1/config` のレスポンスに `idempotency-key-lifetime` が無ければ非対応とみなせと定めており[^4]、**フィールドの有無そのものが対応可否の宣言**になっている。手元の Polaris 1.6.0 はこのフィールドを返さなかったため、500 を受けたらクライアント側でテーブルを読み直し、自分のコミットが入っているか確認する経路が要る。

紛らわしい点をもう1つ挙げると、**同じ 409 が別の意味でも使われる**。namespace 作成時の 409 は「すでに存在する」で、何度リトライしても結果は変わらない。ステータスコードだけで分岐すると無限にリトライする実装になるので、エラーボディの `type` を見る必要がある。

### credential vending

クライアントが S3 上のデータを読むには、S3 の資格情報が要る。しかしそれを全クライアントに配ると、**テーブル単位の権限管理が成立しない**。カタログ側で「このユーザはこのテーブルだけ」と決めても、鍵を持っていればバケット全体を直接触れてしまうからだ。

credential vending はこの矛盾を解く。クライアントは S3 の鍵を持たず、カタログにテーブルを要求する。カタログは権限を確認したうえで、**そのテーブルのパスにだけ有効な期限付きの鍵**を発行する。

手元で loadTable を叩いたところ、実際に払い出された。

```
storage-credentials が 1 個返りました:
  prefix: s3://warehouse/lab_catalog/lab/rest_demo
    s3.access-key-id = ***
    s3.secret-access-key = ***
    s3.session-token = ***
    expiration-time = 1784386178000
```

`prefix` がテーブル1つ分のパスになっている。カタログ全体でも namespace 単位でもない。`s3.session-token` が付いていることから、静的な鍵ではなく一時的な資格情報だと分かる。

ただし仕様上、これは要求であって保証ではない。クライアントが `X-Iceberg-Access-Delegation` ヘッダで要求しても、サーバは応じない選択ができる[^4]。

### テーブル仕様のバージョンと、実装との距離

テーブル仕様は版で管理されている。v1 が基本形、v2 で position delete / equality delete による merge-on-read が入り、v3 で deletion vector と row lineage が加わった[^3]。

ここで冒頭の「仕様と実装の距離」が効いてくる。**新規テーブルの既定は今も v2 である。** v3 が定義されていることと、v3 が使えることは別だ。

PyIceberg 0.11.1 では v3 テーブルを作れない。試すと `ValueError: Unsupported table format version: 3` になる。ソースを追うと二重にガードされていて、手前の `upgrade_table_version` が `format_version not in {1, 2}` で弾いている[^5]。その奥には「Writing V3 is not yet supported」という `NotImplementedError` もあるが[^6]、手前で止まるため通常は到達しない。追跡 issue は 2026年7月時点で Open のままである[^7]。

紛らわしいのは型定義で、`typedef.py` の `TableVersion = Literal[1, 2, 3]` は v3 を許容しているように読める[^8]。しかし実際に書けるのは v2 までだ。**型定義だけを見て対応状況を判断すると誤る。**

さらに v4 は仕様として未採択でありながら、Java 実装は 1.10.0 以降 `format-version=4` を設定できる。つまり「仕様が定めている」と「実装ができる」がどちらの方向にもずれる。

実装の制約は他にもある。PyIceberg で確認したものを挙げる。

| できないこと | 実態 |
|---|---|
| format-version 3 の書き込み | 上記のとおり。deletion vector も row lineage も使えない |
| equality delete の読み取り | 書けないだけでなく**読めない**。Flink の UPSERT は equality delete ベースなので、その組み合わせは実害が出る |
| merge-on-read での書き込み | プロパティを設定しても警告を出して copy-on-write に落ちる |
| compaction / orphan file 削除 | `MaintenanceTable` は `expire_snapshots` のみ |

「Python だけで Iceberg を運用する」は現時点で成立しない。読み取りと軽い書き込みは PyIceberg、メンテナンスと重い DML は Spark、という分担が現実的である。

### カタログ実装を選ぶときに見るもの

REST Catalog は「サーバが仕様どおりの HTTP を話しさえすれば、クライアントは実装を知らずに済む」という差し替え可能性のために生まれた。実装は増えており、選定の観点も整理が要る。

調査の過程で、活動の活発さを測る指標に落とし穴があった。**GitHub のコミット数は依存更新ボットで水増しされる。** ある実装は直近365日で1,652コミットあったが、そのうち85.2%が renovate ボットで、人間のコミットは245件、しかも実質1人に集中していた。リリース頻度が高いのも、依存更新を自動リリースしているためだった。ボットを除いた数字で見ないと評価を誤る。

ストレージ側でも想定外があった。ローカル検証で定番だった MinIO は、2026-04-25 にリポジトリがアーカイブされている[^9]。入手可能な最新の公開イメージは、2025年10月の権限昇格の修正を含まない。Apache Polaris 公式も MinIO ガイドに maintenance mode の警告を出し、RustFS の例を追加している[^10]。ここで流通している「ライセンスを AGPLv3 に変更したのが理由」という説明は誤りで、**ライセンスは AGPLv3 のまま変わっていない**。変わったのは保守方針と配布形態である。

なお実験では、Polaris の権限まわりでも仕様と挙動のずれに行き当たった。OAuth2 の `scope` は「どの principal role を有効化するか」の指定として使われるが、存在しないロール名を指定して**有効ロールが空になったトークンでも、テーブルを新規作成できた**。実装を確認すると、ロール名は確かに解釈され絞り込みも働いており、ログにも `roles=[]` と警告が出ている[^11]。それでも書き込みが通る理由までは追えていない。スコープを権限の絞り込み手段として当てにしないほうが安全だと考えている。

## まとめ

Iceberg の中核設計は、確かめた範囲では一貫していた。field ID による列の解決、manifest を書いた時点の spec で解釈する規則、ポインタ差し替えによるコミット。これらは互いに噛み合っており、スキーマ進化とパーティション進化が既存データを書き換えずに成立する理由になっている。

一方で、**「Iceberg が対応している」という表現は、どの仕様バージョンの、どの実装の話かを伴わなければ意味を持たない**。仕様は v3 で deletion vector を定義し v4 が議論されているが、PyIceberg は v3 を書けず、Java 実装は未採択の v4 を既に受け付ける。仕様・実装・記事の3つは一致しないという前提で読む必要がある。

判断に使う数値やバージョンは、この記事も含めて一次情報で確認してほしい。調べた範囲と、確かめられなかったことは公開したサイト[^1][^2]に明記してある。

## 参考文献

[^1]: dobachi, "[Apache Iceberg 調査報告書](https://dobachi.github.io/iceberg-research/)", アクセス日 2026-07-19
[^2]: dobachi, "[Iceberg REST Lab](https://dobachi.github.io/iceberg-rest-lab/)", アクセス日 2026-07-19
[^3]: Apache Iceberg, "[Iceberg Table Spec](https://iceberg.apache.org/spec/)", アクセス日 2026-07-19
[^4]: Apache Iceberg, "[Iceberg REST Catalog OpenAPI 仕様](https://github.com/apache/iceberg/blob/main/open-api/rest-catalog-open-api.yaml)", アクセス日 2026-07-19
[^5]: PyIceberg, "[table/__init__.py L338（upgrade_table_version のバージョン検証）](https://github.com/apache/iceberg-python/blob/pyiceberg-0.11.1/pyiceberg/table/__init__.py#L338)", アクセス日 2026-07-19
[^6]: PyIceberg, "[table/metadata.py L578（Writing V3 is not yet supported）](https://github.com/apache/iceberg-python/blob/pyiceberg-0.11.1/pyiceberg/table/metadata.py#L578)", アクセス日 2026-07-19
[^7]: apache/iceberg-python, "[Issue #1551: Support writing V3 metadata](https://github.com/apache/iceberg-python/issues/1551)", アクセス日 2026-07-19
[^8]: PyIceberg, "[typedef.py L212（TableVersion の定義）](https://github.com/apache/iceberg-python/blob/pyiceberg-0.11.1/pyiceberg/typedef.py#L212)", アクセス日 2026-07-19
[^9]: MinIO, "[minio/minio リポジトリ（アーカイブ済み）](https://github.com/minio/minio)", アクセス日 2026-07-19
[^10]: apache/polaris, "[PR #3482: RustFS の例を追加](https://github.com/apache/polaris/pull/3482)", アクセス日 2026-07-19
[^11]: Apache Polaris, "[DefaultAuthenticator.java（principal role の解決）](https://github.com/apache/polaris/blob/apache-polaris-1.6.0/runtime/service/src/main/java/org/apache/polaris/service/auth/DefaultAuthenticator.java)", アクセス日 2026-07-19

## 更新履歴

- 2026-07-19: 初版
