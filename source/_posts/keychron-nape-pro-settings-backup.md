---
title: Keychron Nape Pro の設定をバックアップ・復元する（非公式ツール NapeProConfiguration）
date: 2026-07-11 20:45:00
categories:
  - Keyboard
tags:
  - Keychron
  - Nape Pro
  - WebHID
  - Backup
  - Tampermonkey
---

# はじめに

Keychron Nape Pro は、専用のブラウザアプリ「Keychron Launcher」からキーマップやエンコーダ、DPI などを設定できるキーボードである。
ただし現時点の Launcher には、設定内容をファイルとして書き出す「エクスポート」や、書き戻す「インポート」の機能が用意されていない。

このため、次のような場面で困ることがある。

- 設定をリセットしてしまい、また一から手作業でやり直す羽目になった
- 別の Nape Pro でも同じ設定を再現したいが、手で写すしかない
- 気に入った配列を「プロファイル」として残しておきたい

この課題を補うために、非公式のツール群として [NapeProConfiguration](https://github.com/dobachi/NapeProConfiguration) を用意した。設定を JSON としてバックアップし、必要なときに復元するための手順をまとめる。

> **免責事項**
> 本記事で紹介するツールは Keychron 公式の機能ではなく、ブラウザの WebHID API を通じてキーボードを直接操作する非公式のものである。
> 公式サポートの対象外であり、利用はすべて自己責任で行っていただきたい。

# 背景：なぜ設定のバックアップが難しいのか

Nape Pro の設定は、Launcher と キーボードの間で HID（Human Interface Device）というプロトコルを通じてやり取りされている。
キーボードによっては設定を JSON として書き出し・読み込みできるものもあるが、Nape Pro の Launcher にはその入口がなく、また通信仕様も公開されていない。

そこで NapeProConfiguration では、ブラウザ標準の **WebHID API** を通じて Launcher と同じようにキーボードと通信し、設定内容を JSON ファイルとして取り出す・書き戻すという方法を採っている。

# NapeProConfiguration の概要

リポジトリは大きく次の3つで構成されている。

| ディレクトリ | 内容 |
| --- | --- |
| `tools/` | エクスポート/インポートを行うスクリプト（ユーザースクリプト・ブックマークレット・コンソール貼り付け用） |
| `docs/` | HID プロトコルのリファレンスや調査データ |
| `configs/` | テーマ別の設定プロファイル（テンプレート） |

利用者としてまず触れるのは `tools/` で、実行方法として次の3通りが用意されている。

1. **ユーザースクリプト**（Tampermonkey 等）— Launcher に Export/Import ボタンを常時表示する。**おすすめ**
2. **ブックマークレット** — 拡張機能のインストール不要で使える
3. **コンソール手動貼り付け** — スクリプトを開発者ツールに貼って実行する

# 動作確認環境

以下の環境で動作を確認している。バージョンが異なると、内部の設定構造が変わっていて動かないことがある。

- Keychron Launcher: **V1.3.8**
- Nape Pro ファームウェア: **v1.2.3-ZK** / **v1.2.5-ZK**

WebHID API に対応したブラウザ（Google Chrome や Microsoft Edge など Chromium 系）が必要である。

# 仕組み（概要）

NapeProConfiguration の動作イメージは以下の通りである。

![NapeProConfiguration 仕組み概要](/memo-blog/images/nape-pro-architecture.jpg)

- Launcher のページ上で動くスクリプトが、WebHID API 経由でキーボードに接続する
- **エクスポート**時は、キーマップ・エンコーダ・DPI などの現在値を読み出し、バージョン情報を添えて JSON ファイルとしてダウンロードする
- **インポート**時は、JSON を読み込み、その内容をキーボードへ書き戻す

HID プロトコルの詳細は `docs/` にリファレンスとしてまとめてある。

なお、WebHID のデバイス権限は Launcher のページに紐づく。そのため、どの実行方法であっても、スクリプトは **`launcher.keychron.com` を開いたそのページ上**で動かす必要がある。別タブやローカルの HTML ファイルからはデバイスにアクセスできない。

# 使い方1：ユーザースクリプト（おすすめ）

Launcher を開くたびに Export/Import ボタンが表示されるため、日常的に使うならこの方法が最も手軽である。

1. ブラウザに **Tampermonkey**（または Violentmonkey）拡張をインストールする
2. 拡張のメニューから「新規スクリプト」を選び、`tools/nape-pro-export.user.js` の内容を貼り付けて保存する
3. Keychron Launcher のページを開き、Nape Pro を接続する
4. 画面右下に表示される **「⬇ Export / ⬆ Import」** ボタンを使う
   - **エクスポート**: ボタンをクリックすると JSON が自動的にダウンロードされる
   - **インポート**: ボタンをクリックし、ファイル選択ダイアログで JSON を指定する

# 使い方2：ブックマークレット（インストール不要）

拡張機能を入れたくない場合は、ブックマークレットが使える。

1. ブラウザに2つのブックマークを登録する
   - 名前「Nape Pro Export」／ URL に `tools/export-bookmarklet.txt` の内容を貼り付ける
   - 名前「Nape Pro Import」／ URL に `tools/import-bookmarklet.txt` の内容を貼り付ける
2. Launcher を開き、Nape Pro を接続する
3. 目的に応じてブックマークをクリックする
   - **エクスポート**: `nape-pro-settings-YYYY-MM-DD.json` が自動的にダウンロードされる
   - **インポート**: ファイル選択ダイアログで JSON を選ぶと、デバイスに書き込まれる

# 使い方3：コンソール手動貼り付け

一度きりの作業なら、スクリプトを開発者ツールに貼り付けて実行する方法もある。

**エクスポート**

1. Launcher を開き、Nape Pro を接続する
2. 開発者ツールを開き（`F12` または `Ctrl+Shift+I`）、Console タブを選ぶ
3. 初回のみ、貼り付けに関するセキュリティ警告が出るので、指示に従って `allow pasting` と入力する
4. `tools/export-nape-pro-settings.js` の内容を貼り付けて Enter を押す
5. JSON が自動的にダウンロードされる

**インポート**

1. Console に `tools/import-nape-pro-settings.js` の内容を貼り付けて Enter を押す
2. ファイル選択ダイアログで JSON を選ぶ
3. キーマップ・エンコーダ・DPI などがデバイスに書き込まれる
4. Launcher の画面をリロードすると反映が確認できる

# 出力される JSON と設定プロファイル

エクスポートで得られるのは JSON ファイルで、キーマップ・エンコーダ・DPI などの設定値に加えて、**ファームウェアや Launcher のバージョン情報**も記録される。
バージョンが記録されているため、後から「どの環境で取ったバックアップか」を判断しやすい。

また `configs/` には、あらかじめ用意された設定プロファイル（例: `main-side-and-presentation`）が置かれている。
一から作らず、こうしたテンプレートを取り込んで出発点にすることもできる。

# 注意点

- **バージョン差異**: 動作確認環境と Launcher／ファームウェアのバージョンが違う場合、設定構造の変更により正しく動作しないことがある。まずは自分の環境のバージョンを確認しておきたい。なおインポート時には、書き込み前にデバイスの現在のバージョンとファイルに記録されたバージョンを照合し、食い違えば確認ダイアログが出て続行するかどうかを選べる（Launcher バージョンは取得できないと照合をスキップすることがある）。
- **バックアップを先に取る**: インポートは設定を上書きする操作である。試す前に、現在の設定をエクスポートして手元に残しておく。
- **非公式・自己責任**: 公式サポートの対象外である。うまくいかない場合は、Launcher からの手動設定に切り替える判断も必要になる。

# まとめ

Keychron Nape Pro の Launcher には設定の書き出し・読み込み機能がないが、WebHID を利用した非公式ツール NapeProConfiguration を使えば、設定を JSON としてバックアップし、必要なときに復元できる。日常的に使うならボタンが常時出るユーザースクリプト方式が手軽で、インストールを避けたいならブックマークレット、一度きりならコンソール貼り付けを選ぶとよい。

# 参考リンク

- NapeProConfiguration リポジトリ: <https://github.com/dobachi/NapeProConfiguration>
- WebHID API（MDN Web Docs）: <https://developer.mozilla.org/en-US/docs/Web/API/WebHID_API>
- Tampermonkey: <https://www.tampermonkey.net/>
