---
title: OpenHandsでOllamaを使う際のパフォーマンスチューニング
date: 2025-07-26
categories:
  - AI
  - Technical
tags:
  - Ollama
  - OpenHands
  - Performance
  - LocalLLM
  - AI
  - WSL2
---

# メモ

# 参考





<!-- vim: set et tw=0 ts=2 sw=2: -->


## はじめに

OpenHandsでローカルLLMのOllamaを使用する際に、パフォーマンスの問題に直面することがあります。本記事では、Ollamaのパフォーマンスチューニング方法と、特にOpenHandsとの統合における最適化について調査した内容をまとめます。

<!-- more -->

## Ollamaの基本的なパフォーマンスチューニング

### 主要な環境変数

Ollamaのパフォーマンスに影響する主要な環境変数は以下の通りです：

#### 並行処理関連
- `OLLAMA_NUM_PARALLEL`: 並行して処理するリクエストの数（推奨: 3-8）
- `OLLAMA_MAX_LOADED_MODELS`: 同時にロードできるモデルの最大数（推奨: 1-5）
- `OLLAMA_MAX_QUEUE`: キューに入るリクエストの最大数（推奨: 512）

#### GPU最適化
- `OLLAMA_GPU_LAYERS`: GPUにロードするレイヤー数（例: 32）
- `OLLAMA_GPU_MEMORY_FRACTION`: GPU メモリの使用割合（例: 0.8 = 80%）
- `OLLAMA_GPU_OVERHEAD`: GPU メモリオーバーヘッド（例: 2147483648 = 2GB）
- `OLLAMA_FLASH_ATTENTION`: フラッシュアテンションの有効化（1で有効）

#### メモリ管理
- `OLLAMA_KEEP_ALIVE`: モデル保持時間（例: 30m）
- `OLLAMA_NUM_THREADS`: CPU スレッド数（例: 8）

### 推奨設定例

高性能環境（例：RTX 4090、192GB RAM）での設定例：

```bash
export OLLAMA_NUM_PARALLEL=3
export OLLAMA_MAX_LOADED_MODELS=3
export OLLAMA_MAX_QUEUE=512
export OLLAMA_GPU_LAYERS=32
export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_GPU_MEMORY_FRACTION=0.8
```

## WSL2環境での考慮事項

### パフォーマンスオーバーヘッド

WSL2では仮想化によるオーバーヘッドが発生します：
- 約10-13%のパフォーマンス低下が報告されています
- ファイルシステムのI/O速度制限による影響もあります

### ネットワーク設定の課題

WSL2は仮想化されたイーサネットアダプタを使用するため：
- ローカルネットワークからのアクセスに制限があります
- DockerコンテナからWSL2上のOllamaへの接続に問題が発生することがあります

## OpenHandsとの統合における最適化

### 一般的な問題と解決策

1. **接続エラー**
   - `host.docker.internal`を使用した接続が失敗する場合があります
   - WSL2のIPアドレスを直接指定する必要がある場合があります

2. **APIエンドポイントの設定**
   - Ollamaサーバーが404エラーを返す場合があります
   - ベースURLの設定に注意が必要です（`/v1`の有無など）

3. **認証設定**
   - APIキーの設定について混乱が生じることがあります
   - Ollamaはデフォルトでは認証を必要としません

### Docker環境での最適設定

OpenHandsをDockerで実行する場合の推奨設定：

```bash
# Ollamaの起動（WSL2内）
ollama serve

# 環境変数の設定
export OLLAMA_HOST="0.0.0.0:11434"  # 外部からのアクセスを許可

# Dockerコンテナの起動例
docker run -d \
  -p 11434:11434 \
  -v $(pwd)/models:/root/.ollama/models \
  -e OLLAMA_GPU_LAYERS=32 \
  -e OLLAMA_NUM_PARALLEL=4 \
  ollama/ollama:latest
```

## パフォーマンス監視とデバッグ

### GPU使用率の確認

```bash
# NVIDIA GPUの場合
nvidia-smi

# 継続的な監視
watch -n 1 nvidia-smi

# Ollamaの詳細情報
ollama ps --verbose
```

### デバッグモードの活用

問題の診断には以下の環境変数が有用です：

```bash
export OLLAMA_DEBUG=1
export OLLAMA_FLASH_ATTENTION=1  # パフォーマンスログを有効化
```

## よくあるトラブルシューティング

### ポートがすでに使用されているエラー

`ollama serve`を実行した際に以下のようなエラーが発生する場合があります：

```
Error: listen tcp 127.0.0.1:11434: bind: address already in use
```

これは、systemdによってOllamaがすでにバックグラウンドサービスとして起動している場合に発生します。

**解決方法：**

```bash
# Ollamaサービスの状態を確認
systemctl status ollama

# サービスを停止する場合
sudo systemctl stop ollama

# サービスを無効化する場合（自動起動を停止）
sudo systemctl disable ollama

# または、既存のサービスを使用する
# （ollama serve を実行する必要はありません）
```

既存のsystemdサービスを使用する場合は、環境変数を`/etc/systemd/system/ollama.service.d/override.conf`に設定することで、パフォーマンスチューニングを適用できます：

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf <<EOF
[Service]
Environment="OLLAMA_NUM_PARALLEL=4"
Environment="OLLAMA_GPU_LAYERS=32"
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

# サービスを再起動
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

## 実践的なチューニング手順

1. **ベースライン測定**
   - デフォルト設定でのパフォーマンスを測定

2. **段階的な最適化**
   - 保守的な設定から開始
   - システムリソースを監視しながら徐々に値を増加

3. **ハードウェアに応じた調整**
   - GPU メモリ容量に応じて`OLLAMA_GPU_LAYERS`を調整
   - CPU コア数に応じて`OLLAMA_NUM_THREADS`を設定

4. **実環境でのテスト**
   - 実際の使用パターンに基づいてテスト
   - 必要に応じて微調整

## まとめ

Ollamaのパフォーマンスチューニングは、ハードウェア構成と使用環境に大きく依存します。特にOpenHandsとの統合においては、WSL2の制限事項やDocker環境の特性を理解した上で、適切な設定を行うことが重要です。

上記の設定を参考に、自身の環境に合わせて調整を行い、最適なパフォーマンスを実現してください。実際の使用環境でのパフォーマンステストを必ず行い、必要に応じて設定を微調整することをお勧めします。

## 参考

- [Ollama公式ドキュメント - GPU設定](https://github.com/ollama/ollama/blob/main/docs/gpu.md)
- [Qiita - Ollamaのパフォーマンスチューニング](https://qiita.com/kiyotaman/items/1aeb098b5ff0d6d5e641)
- [OpenHands GitHub Issues](https://github.com/All-Hands-AI/OpenHands/issues)

<!-- vim: set et tw=0 ts=2 sw=2: -->