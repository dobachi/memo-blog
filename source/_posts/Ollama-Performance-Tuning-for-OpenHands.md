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

## はじめに

OpenHandsでローカルLLMのOllamaを使用する際に、パフォーマンスの問題に直面することがあります。本記事では、Ollamaのパフォーマンスチューニング方法と、特にOpenHandsとの統合における最適化について実践的な内容をまとめます。

<!-- more -->

## 環境別アプローチの選択

### 環境の特定方法

まず、自分の環境を正確に把握することが重要です。以下のコマンドで環境を確認してください：

```bash
# 基本環境の確認
uname -a
cat /etc/os-release

# GPU環境の確認
lspci | grep -E "(VGA|3D|Display)"
ls -la /dev/dri/ /dev/dxg 2>/dev/null

# WSL2環境かどうかの確認
[ -e /dev/dxg ] && echo "WSL2環境" || echo "ネイティブLinux環境"

# GPU利用可能性の確認
nvidia-smi 2>/dev/null && echo "NVIDIA GPU利用可能"
rocm-smi 2>/dev/null && echo "AMD GPU（ROCm）利用可能"

# OpenCL確認（正確な方法）
PLATFORMS=$(clinfo 2>/dev/null | grep "Number of platforms" | awk '{print $4}')
if [ "$PLATFORMS" -gt 0 ] 2>/dev/null; then
    echo "OpenCL利用可能: $PLATFORMS プラットフォーム"
else
    echo "OpenCL利用不可: プラットフォーム数 ${PLATFORMS:-0}"
fi
```

### 推奨アプローチマトリックス

| 環境 | GPU | OpenCL | 推奨アプローチ | 期待パフォーマンス |
|------|-----|-------|---------------|-------------------|
| **WSL2** | AMD統合GPU | 0プラットフォーム | CPU専用設定 | 8-12 tokens/sec |
| **WSL2** | NVIDIA GPU | >0プラットフォーム | GPU使用（制限あり） | 15-25 tokens/sec |
| **ネイティブLinux** | AMD専用GPU | >0プラットフォーム | ROCm + GPU設定 | 25-40 tokens/sec |
| **ネイティブLinux** | NVIDIA GPU | >0プラットフォーム | CUDA + GPU設定 | 30-50 tokens/sec |
| **どの環境でも** | GPU問題時 | - | CPU専用設定 | 5-15 tokens/sec |

## 基本的なパフォーマンスチューニング

### 共通環境変数

以下の環境変数はすべての環境で有効です：

```bash
# 並行処理設定
export OLLAMA_NUM_PARALLEL=2        # 同時リクエスト数
export OLLAMA_MAX_LOADED_MODELS=1   # 同時ロードモデル数
export OLLAMA_MAX_QUEUE=4           # キューサイズ
export OLLAMA_KEEP_ALIVE=5m         # モデル保持時間

# ネットワーク設定（OpenHands連携用）
export OLLAMA_HOST="0.0.0.0:11434"  # 外部アクセス許可
```

### パフォーマンス監視方法

```bash
# GPU使用状況（NVIDIA）
nvidia-smi

# GPU使用状況（AMD - ネイティブLinux）
rocm-smi

# CPU使用状況
htop

# Ollama状況
ollama ps

# リアルタイム監視
watch -n 2 'ollama ps && echo "=== GPU ===" && nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv'
```

## 環境別詳細設定

### WSL2環境での設定

**重要**: WSL2環境では、GPU種類に関わらずCPU専用設定が最も安定します。

#### 推奨設定（CPU専用）

```bash
# WSL2環境での安定設定
export OLLAMA_GPU_LAYERS=0          # GPU使用を無効化
export OLLAMA_NUM_THREADS=$(nproc)  # 全CPUコア使用
export OLLAMA_MAX_LOADED_MODELS=1   # メモリ制限
export OLLAMA_NUM_PARALLEL=1        # 安定性重視
export OLLAMA_HOST="0.0.0.0:11434"  # Docker連携用

# 軽量モデルの使用推奨
ollama pull llama3.2:1b              # 1B - 超軽量（最新）
ollama pull phi3:mini                # 3.8B - 軽量
ollama pull qwen2.5:7b               # 7B - バランス良好
```

#### systemdでOllamaを管理する場合（WSL2）

WSL2でもsystemdを有効化している場合は、以下の方法で設定できます：

```bash
# Ollamaサービスの状態確認
systemctl status ollama

# 環境変数設定用のオーバーライドディレクトリを作成
sudo mkdir -p /etc/systemd/system/ollama.service.d

# WSL2 CPU専用設定
sudo tee /etc/systemd/system/ollama.service.d/wsl2-override.conf <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_GPU_LAYERS=0"
Environment="OLLAMA_NUM_THREADS=$(nproc)"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_KEEP_ALIVE=5m"
EOF

# systemdの設定を再読み込み
sudo systemctl daemon-reload

# Ollamaサービスを再起動
sudo systemctl restart ollama

# 設定が反映されているか確認
sudo systemctl show ollama | grep Environment

# ポート使用中エラーが出る場合
# すでにOllamaがsystemdで起動している可能性が高い
# 手動で`ollama serve`を実行する必要はない
```

**注意**: WSL2でsystemdを使用している場合、Ollamaは自動起動するため、手動での`ollama serve`は不要です。

#### WSL2の制限事項

- 仮想化による10-13%のパフォーマンス低下（[ベンチマーク](https://www.quickinference.com/2024/11/03/ollama-speed-test-windows-vs-linux-in-wsl2/)より）
- ネットワーク設定の複雑さ（[Issue #1431](https://github.com/ollama/ollama/issues/1431)）
- **OpenCLプラットフォーム制限**: 通常0個のため、GPU加速困難
- **Mesa D3D12の限界**: OpenGL描画は可能だが、OllamaのCUDA/ROCm加速には対応不可

### ネイティブLinux + NVIDIA GPU

#### 推奨設定

```bash
# NVIDIA GPU最適化設定
export CUDA_VISIBLE_DEVICES=0
export OLLAMA_GPU_LAYERS=32          # モデルサイズに応じて調整
export OLLAMA_NUM_PARALLEL=4        # 高性能GPU用
export OLLAMA_MAX_LOADED_MODELS=2   # VRAM容量に応じて
export OLLAMA_FLASH_ATTENTION=1     # パフォーマンス向上
export OLLAMA_GPU_MEMORY_FRACTION=0.8
```

#### systemd設定

```bash
# /etc/systemd/system/ollama.service.d/nvidia.conf
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/nvidia.conf <<EOF
[Service]
Environment="CUDA_VISIBLE_DEVICES=0"
Environment="OLLAMA_GPU_LAYERS=32"
Environment="OLLAMA_NUM_PARALLEL=4"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### ネイティブLinux + AMD GPU

#### 前提条件

```bash
# ROCmインストール確認
rocminfo 2>/dev/null || echo "ROCm未インストール"

# ユーザー権限設定
sudo usermod -a -G render,video $USER
# 再ログイン後確認
groups $USER | grep -E "(render|video)"
```

#### 推奨設定

```bash
# ROCm基本設定
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH

# GPU世代指定（重要）
export HSA_OVERRIDE_GFX_VERSION=10.3.0  # RX 6000シリーズ
# export HSA_OVERRIDE_GFX_VERSION=11.0.0  # RX 7000シリーズ

# Ollama最適化
export OLLAMA_GPU_LAYERS=35
export OLLAMA_NUM_PARALLEL=2        # AMD GPUは保守的設定
export OLLAMA_MAX_LOADED_MODELS=1   # メモリ制限重要
export GPU_MAX_ALLOC_PERCENT=80
export ROCR_VISIBLE_DEVICES=0
```

#### systemd設定

```bash
# /etc/systemd/system/ollama.service.d/amd.conf
sudo tee /etc/systemd/system/ollama.service.d/amd.conf <<EOF
[Service]
Environment="ROCM_PATH=/opt/rocm"
Environment="HSA_OVERRIDE_GFX_VERSION=10.3.0"
Environment="OLLAMA_GPU_LAYERS=35"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="GPU_MAX_ALLOC_PERCENT=80"
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
```

## OpenHandsとの統合

### Docker環境での設定

#### 基本的なDocker設定

```bash
# OpenHandsからOllama（WSL2）への接続
docker run -d \
  --name openhands \
  -e OLLAMA_BASE_URL="http://host.docker.internal:11434" \
  -e OLLAMA_API_KEY="" \
  -p 3000:3000 \
  all-hands-ai/openhands
```

#### WSL2特有の接続設定

```bash
# WSL2のIPアドレス確認
ip addr show eth0 | grep inet

# 直接IP指定での接続（host.docker.internalが失敗する場合）
export WSL2_IP=$(ip addr show eth0 | grep -Po 'inet \K[\d.]+')
docker run -d \
  --name openhands \
  -e OLLAMA_BASE_URL="http://${WSL2_IP}:11434" \
  all-hands-ai/openhands
```

### 一般的な問題と解決策

#### 1. 接続エラー

**症状**: OpenHandsがOllamaに接続できない

**解決方法**:
```bash
# Ollamaサーバー状態確認
systemctl status ollama
curl http://localhost:11434/api/version

# ファイアウォール確認
sudo ufw status
sudo ufw allow 11434
```

#### 2. APIエンドポイントエラー

**症状**: 404エラーや不正なエンドポイント

**解決方法**:
```bash
# 正しいエンドポイント設定
OLLAMA_BASE_URL="http://localhost:11434"    # /v1は不要
OLLAMA_API_KEY=""                           # 空文字列
```

#### 3. パフォーマンス問題

**症状**: レスポンスが非常に遅い

**解決方法**:
```bash
# デバッグモード有効化
export OLLAMA_DEBUG=1
export OLLAMA_FLASH_ATTENTION=1

# 軽量モデルでテスト
ollama pull llama3.2:1b
ollama run llama3.2:1b "Hello, test"
```

## トラブルシューティング

### よくある問題

#### ポート使用中エラー

```bash
# 症状
Error: listen tcp 127.0.0.1:11434: bind: address already in use

# 解決方法
systemctl status ollama           # サービス状態確認
sudo systemctl stop ollama       # 必要に応じて停止
# または既存サービスを使用
```

#### GPU認識されない

```bash
# AMD GPU確認
lspci | grep -i amd
ls -la /dev/dri/
rocminfo 2>/dev/null

# NVIDIA GPU確認
lspci | grep -i nvidia
nvidia-smi

# 代替案: CPU専用設定
export OLLAMA_GPU_LAYERS=0
export OLLAMA_NUM_THREADS=$(nproc)
```

#### メモリ不足

```bash
# 症状: "HIP out of memory" or "CUDA out of memory"

# 解決方法
export OLLAMA_GPU_LAYERS=10       # レイヤー数削減
export GPU_MAX_ALLOC_PERCENT=70   # メモリ使用量制限

# より小さいモデルを使用
ollama pull llama2:7b              # 7Bモデル
ollama pull gemma:2b               # 2Bモデル（超軽量）
```

### 環境診断スクリプト

プロジェクトに含まれる診断スクリプトを使用してください：

```bash
# 環境情報収集
./scripts/environment_info.sh > my_environment.txt

# 主要な確認項目
- OS・カーネル情報
- GPU認識状況
- ドライバー状態
- OpenCL/ROCm状況
- Ollama設定
```

## 実践例

### WSL2 + AMD Radeon 890M環境（検証済み）

**環境詳細**:
- OS: Ubuntu 22.04.5 LTS (WSL2)
- CPU: 24コア (AMD Ryzen 9 7940HS相当)
- RAM: 29GB
- GPU: AMD Radeon 890M Graphics (統合GPU)
- OpenCL: 0プラットフォーム（GPU加速不可）
- OpenGL: Mesa D3D12対応（描画のみ、計算処理不可）

**実際の設定**:
```bash
# CPU専用設定（推奨・安定）
export OLLAMA_GPU_LAYERS=0
export OLLAMA_NUM_THREADS=24
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_HOST="0.0.0.0:11434"
```

**パフォーマンス結果**:
- llama3.1:8b: 10 tokens/sec
- qwen2.5:7b: 12 tokens/sec
- llama3.2:1b: 20-25 tokens/sec
- プロンプト処理: 120 tokens/sec

## まとめ

### 環境別推奨設定まとめ

1. **WSL2環境**: GPU種類に関わらずCPU専用設定が最安定
2. **ネイティブLinux + NVIDIA**: GPU最大活用でCUDA設定
3. **ネイティブLinux + AMD**: ROCm必須、世代指定重要

### 実践的なアプローチ

1. **環境確認**: 診断スクリプトで現状把握
2. **保守的設定**: 軽量モデル + CPU専用から開始
3. **段階的最適化**: 安定性確認後にGPU設定追加
4. **パフォーマンステスト**: 実際の使用パターンで検証

適切な設定により、OpenHandsとOllamaの組み合わせで効率的なAI開発環境を構築できます。環境に応じて段階的に最適化を進めることをお勧めします。

## 参考

- [Ollama公式ドキュメント - GPU設定](https://github.com/ollama/ollama/blob/main/docs/gpu.md)
- [OpenHands GitHub Issues](https://github.com/All-Hands-AI/OpenHands/issues)
- [Quick Inference ベンチマーク - Windows vs Linux in WSL2](https://www.quickinference.com/2024/11/03/ollama-speed-test-windows-vs-linux-in-wsl2/)
- [Ollama Issue #2529 - WSL2 パフォーマンス問題](https://github.com/ollama/ollama/issues/2529)
- [Ollama Issue #1431 - WSL2 ネットワーク制限](https://github.com/ollama/ollama/issues/1431)
- [Open WebUI Discussion #510 - Docker接続問題](https://github.com/open-webui/open-webui/discussions/510)

<!-- vim: set et tw=0 ts=2 sw=2: -->