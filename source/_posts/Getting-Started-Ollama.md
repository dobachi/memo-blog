---

title: Ubuntu環境でのOllamaセットアップガイド：ローカルで動作するAIアシスタントの構築
date: 2025-06-08 01:17:00
tags:
  - Ubuntu
  - AI
  - Ollama
  - LLM
categories:
  - AI
  - Llama
  - Ollama

---

最近注目を集めているローカルで動作するLLM（大規模言語モデル）ランタイム「Ollama」のUbuntu環境での導入方法と基本的な使い方について解説する。Ollamaを使用することで、プライバシーを保ちながら、ローカル環境で高性能なAIアシスタントを利用することが可能である。

## 1. Ollamaとは

Ollamaは、オープンソースのLLMランタイムで、以下のような特徴を持つ：

- ローカル環境で動作する（インターネット接続不要）
- 様々なオープンソースモデルに対応
- APIを通じた柔軟な利用が可能
- システムリソースの要件が比較的低い

## 2. システム要件

Ollamaの動作には以下のようなシステム要件が必要である。

[What are the minimum hardware requirements to run an ollama model?](https://www.reddit.com/r/ollama/comments/1gwbl0k/what_are_the_minimum_hardware_requirements_to_run/?rdt=34217) あたりの情報を参考に。

### 2.1 基本要件

- RAM:
    - 7Bパラメータモデル: 最低8GB RAM
    - 13Bパラメータモデル: 最低16GB RAM
    - 70Bパラメータモデル: 最低64GB RAM

### 2.2 推奨スペック

- CPU: AVX512対応のIntel/AMD CPU、もしくはDDR5対応プロセッサ
- RAM: 16GB以上
- ストレージ: 約50GB以上の空き容量

### 2.3 GPU要件（オプション）

- NVIDIA GPU: ドライバーバージョン452.39以上
- AMD GPU: 最新のRadeonドライバー

なお、実際の必要スペックは使用するモデルのサイズや用途によって大きく異なる。特に大規模なモデルを使用する場合は、より多くのリソースが必要となる点に注意が必要である。

## 3. インストール手順

Ubuntu環境でのインストールは非常に簡単である。以下のコマンドを実行する：

```bash
curl -fsSL https://ollama.com/install.sh | sh

```

インストール後、システムサービスとして登録し、自動起動を設定する。なお、手元の環境では最初から下記の環境設定が完了していたので不要かもしれない。：

```bash
systemctl start ollama
systemctl enable ollama

```

正常にインストールされたことを確認する：

```bash
systemctl status ollama

```

## 4. 基本的な使い方

### 4.1 モデルのダウンロード

最初に使用したいモデルをダウンロードする必要がある：

```bash
# Llama 3モデルをダウンロード
ollama pull llama3

# 利用可能なモデルの確認
ollama list

# NAME             ID              SIZE      MODIFIED
# llama3:latest    365c0bd3c000    4.7 GB    6 seconds ago
```

### 4.2 対話モードでの利用

```bash
# 対話モードでモデルを起動
ollama run llama3

```

### 4.3 APIとしての利用

Ollamaは11434番ポートでHTTP APIを提供している：

```bash
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Ubuntuの主な特徴を3つ挙げよ"
}'

```

## 5. カスタマイズと応用

### 5.1 システムプロンプトのカスタマイズ

Modelfileを使用して、モデルの振る舞いをカスタマイズすることができる：

```bash
# Modelfileの作成
cat << EOF > Modelfile
FROM llama2
SYSTEM "あなたはLinuxシステムの専門家である。Ubuntuに関する質問に詳しく答えよ。"
EOF

# カスタムモデルの作成
ollama create ubuntu-expert -f Modelfile

```

### 5.2 環境変数の設定

必要に応じて以下のような環境変数を設定する：

```bash
# GPUメモリ制限の設定
export CUDA_VISIBLE_DEVICES=0

# リモートアクセスを許可
export OLLAMA_HOST=0.0.0.0

```

## 6. セキュリティ設定

### 6.1 ファイアウォールの設定

UFWを使用している場合は、必要なポートを開放する：

```bash
sudo ufw allow 11434/tcp
sudo ufw status

```

### 6.2 アクセス制限

特定のIPアドレスからのみアクセスを許可する場合の設定：

```bash
# /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=192.168.1.100"  # 特定のIPアドレスを指定

```

## 7. トラブルシューティング

### 7.1 ログの確認

問題が発生した場合は、以下のコマンドでログを確認する：

```bash
# システムログの確認
journalctl -u ollama -f

# サービスのステータス確認
systemctl status ollama

```

### 7.2 一般的な問題の解決

```bash
# サービスの再起動
systemctl restart ollama

# キャッシュのクリア
rm -rf ~/.ollama/cache/*

```

## 8. 参考情報とリソース

### 公式リソース

- [Ollama 公式サイト](https://ollama.com/)
    - 最新のドキュメントと更新情報
    - モデルのダウンロードとライブラリ
- [Ollama GitHub](https://github.com/ollama/ollama)
    - ソースコードとイシュートラッキング
    - コミュニティの貢献とディスカッション

### モデル関連

- [Llama 2](https://ai.meta.com/llama/)
    - Meta社による基本モデルの詳細
    - ライセンスと使用条件

### コミュニティリソース

- [Ollama Discord](https://discord.gg/ollama)
    - コミュニティサポート
    - ユースケースの共有
- [Ollama Reddit](https://www.reddit.com/r/Ollama/)
    - ユーザーディスカッション
    - トラブルシューティングのヒント

### 関連プロジェクト

- [LangChain](https://python.langchain.com/)
    - Ollamaとの統合例
    - アプリケーション開発フレームワーク

## まとめ

Ollamaを使用することで、プライバシーを保ちながらローカル環境で高性能なAIアシスタントを利用することが可能となる。
この記事で紹介した設定や使い方を参考に、各自の環境に合わせたAIアシスタントの構築を検討されたい。






<!-- vim: set et tw=0 ts=2 sw=2: -->
