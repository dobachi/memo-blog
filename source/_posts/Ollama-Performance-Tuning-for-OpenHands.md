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

#### AMD GPU固有の最適化
- `HSA_OVERRIDE_GFX_VERSION`: GPU世代の指定（例: 10.3.0 for RX 6900/6600シリーズ、11.0.0 for RX 7900シリーズ）
- `ROCR_VISIBLE_DEVICES`: 使用するAMD GPUの指定（例: 0）
- `GPU_MAX_ALLOC_PERCENT`: GPU メモリ割り当て上限（例: 80）
- `GPU_MAX_HEAP_SIZE`: GPU ヒープサイズ（例: 100）

#### メモリ管理
- `OLLAMA_KEEP_ALIVE`: モデル保持時間（例: 30m）
- `OLLAMA_NUM_THREADS`: CPU スレッド数（例: 8）

### 推奨設定例

#### NVIDIA GPU環境での設定例（例：RTX 4090、192GB RAM）

```bash
export OLLAMA_NUM_PARALLEL=3
export OLLAMA_MAX_LOADED_MODELS=3
export OLLAMA_MAX_QUEUE=512
export OLLAMA_GPU_LAYERS=32
export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_GPU_MEMORY_FRACTION=0.8
```

#### AMD GPU環境での設定例（例：RX 6900 XT、32GB RAM）

```bash
# ROCm基本設定
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH
export PATH=/opt/rocm/bin:$PATH

# GPU世代指定（RX 6900/6600シリーズの場合）
export HSA_OVERRIDE_GFX_VERSION=10.3.0

# Ollama最適化設定
export OLLAMA_NUM_PARALLEL=2
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_MAX_QUEUE=4
export OLLAMA_GPU_LAYERS=35
export GPU_MAX_ALLOC_PERCENT=80
export ROCR_VISIBLE_DEVICES=0
```

## WSL2環境での考慮事項

### パフォーマンスオーバーヘッド

WSL2では仮想化によるオーバーヘッドが発生します：
- 約10-13%のパフォーマンス低下が報告されています（[Quick Inference ベンチマーク](https://www.quickinference.com/2024/11/03/ollama-speed-test-windows-vs-linux-in-wsl2/)による検証）
- ファイルシステムのI/O速度制限による影響もあります
- [Ollama公式リポジトリのIssue #2529](https://github.com/ollama/ollama/issues/2529)でも複数のユーザーがWSL2でのパフォーマンス問題を報告

### ネットワーク設定の課題

WSL2は仮想化されたイーサネットアダプタを使用するため：
- ローカルネットワークからのアクセスに制限があります（[Ollama Issue #1431](https://github.com/ollama/ollama/issues/1431)で報告）
- DockerコンテナからWSL2上のOllamaへの接続に問題が発生することがあります（[Open WebUI Discussion #510](https://github.com/open-webui/open-webui/discussions/510)）
- WSL2のIPアドレスがWindows再起動時に動的に変更される問題（[Stack Overflow](https://stackoverflow.com/questions/61002681/connecting-to-wsl2-server-via-local-network)で議論）

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

#### 手動でOllamaを起動する場合

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

#### systemdでOllamaを管理する場合

systemdサービスとしてOllamaを起動している場合は、以下の方法で環境変数を設定できます：

```bash
# サービスの状態確認
sudo systemctl status ollama

# 環境変数設定用のオーバーライドディレクトリを作成
sudo mkdir -p /etc/systemd/system/ollama.service.d

# パフォーマンスチューニング用の環境変数を設定
sudo tee /etc/systemd/system/ollama.service.d/override.conf <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_NUM_PARALLEL=4"
Environment="OLLAMA_MAX_LOADED_MODELS=3"
Environment="OLLAMA_MAX_QUEUE=512"
Environment="OLLAMA_GPU_LAYERS=32"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_GPU_MEMORY_FRACTION=0.8"
EOF

# systemdの設定を再読み込み
sudo systemctl daemon-reload

# Ollamaサービスを再起動
sudo systemctl restart ollama

# サービスの状態を確認
sudo systemctl status ollama
```

この方法により、システム起動時に自動的にパフォーマンス最適化された設定でOllamaが起動します。

## AMD GPU環境での特別な考慮事項

### ROCm環境の確認とセットアップ

AMD GPUでOllamaを使用する場合、ROCm（Radeon Open Compute）の適切な設定が必要です。まず現在の環境を確認しましょう。

#### 段階的環境確認手順

**ステップ1: GPU検出の確認**
```bash
# AMD GPUが認識されているか確認
lspci | grep -i amd

# グラフィックデバイスの詳細確認
lspci -v | grep -A 10 -i amd
```

**ステップ2: ドライバーの確認**
```bash
# AMDGPUドライバーの確認
lsmod | grep amdgpu

# DRIデバイスの確認（重要）
ls -la /dev/dri/

# KFDデバイスの確認（ROCm使用時に必要）
ls -la /dev/kfd
```

**ステップ3: ROCmインストール状況の確認**
```bash
# ROCmツールの確認
which rocminfo rocm-smi

# ROCmバージョン確認
rocminfo 2>/dev/null || echo "ROCm not available"
rocm-smi --version 2>/dev/null || echo "ROCm SMI not available"

# ROCmインストールディレクトリの確認
ls -la /opt/rocm* 2>/dev/null || echo "Standard ROCm path not found"
```

**ステップ4: パッケージ確認（ディストリビューション別）**
```bash
# Ubuntu/Debian系
dpkg -l | grep rocm

# Fedora/RHEL系  
rpm -qa | grep rocm

# Arch Linux系
pacman -Q | grep rocm
```

**ステップ5: OpenCL環境の確認**
```bash
# OpenCLデバイス情報の確認（clinfo必要）
clinfo 2>/dev/null || echo "OpenCL not available - install clinfo"

# OpenCLプラットフォームの確認
clinfo | grep -E "(Platform|Device)"
```

#### ROCmが見つからない場合の対処法

**1. ディストリビューション別インストール**

Ubuntu/Debian:
```bash
# ROCmリポジトリの追加
wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/debian/ ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list

# インストール
sudo apt update
sudo apt install rocm-dev rocm-libs
```

Arch Linux:
```bash
# AURからインストール
yay -S rocm-opencl-runtime rocm-dev

# または公式パッケージ
sudo pacman -S rocm-opencl-runtime
```

**2. 代替方法: AMDGPU-PRO OpenCL**
```bash
# ヘッドレスOpenCLのみインストール（ROCm代替）
# AMD公式サイトからAMDGPU-PROドライバーをダウンロード後
sudo amdgpu-install --opencl=legacy --headless --no-dkms
```

**3. WSL2環境での特別な確認**
```bash
# WSL2でのGPUパススルー確認
ls /dev/dxg 2>/dev/null && echo "WSL2 GPU passthrough available"
ls /dev/dri/ 2>/dev/null && echo "DRI devices available"

# WSL2用OpenCLツールのインストール
sudo apt update
sudo apt install clinfo hwinfo

# ハードウェア情報の確認
hwinfo --gfxcard

# OpenCLプラットフォーム確認
clinfo | head -20
```

**4. 最小限の要件確認**
```bash
# 最低限必要なコンポーネント
# 1. AMDGPUドライバー
lsmod | grep amdgpu

# 2. DRIアクセス
ls -la /dev/dri/

# 3. 適切な権限
groups $USER | grep -E "(video|render)"

# 4. 基本的なGPU情報
inxi -Gx 2>/dev/null || echo "inxi not available"
```

#### 環境確認スクリプト例

以下のスクリプトで一括確認が可能です：

```bash
#!/bin/bash
# amd_gpu_check.sh - AMD GPU環境確認スクリプト

echo "=== AMD GPU Environment Check ==="

echo "1. GPU Detection:"
lspci | grep -i amd || echo "No AMD GPU detected"

echo -e "\n2. Driver Status:"
if lsmod | grep -q amdgpu; then
    echo "✓ AMDGPU driver loaded"
else
    echo "✗ AMDGPU driver not loaded"
fi

echo -e "\n3. Device Access:"
if [ -e /dev/dri ]; then
    echo "✓ DRI devices available: $(ls /dev/dri/)"
else
    echo "✗ No DRI devices"
fi

if [ -e /dev/kfd ]; then
    echo "✓ KFD device available"
else
    echo "✗ No KFD device (ROCm may not be installed)"
fi

echo -e "\n4. ROCm Status:"
if command -v rocminfo >/dev/null 2>&1; then
    echo "✓ ROCm tools available"
    rocm-smi --version 2>/dev/null || echo "ROCm SMI version check failed"
else
    echo "✗ ROCm tools not found"
fi

echo -e "\n5. User Permissions:"
if groups $USER | grep -q -E "(video|render)"; then
    echo "✓ User in video/render groups"
else
    echo "✗ User not in required groups - run: sudo usermod -a -G video,render $USER"
fi

echo -e "\n6. OpenCL Status:"
if command -v clinfo >/dev/null 2>&1; then
    echo "✓ clinfo available"
    clinfo 2>/dev/null | grep -E "(Platform|Device)" | head -5
else
    echo "✗ clinfo not available - install: sudo apt install clinfo"
fi

echo -e "\n7. WSL2 Check (if applicable):"
if [ -e /dev/dxg ]; then
    echo "✓ WSL2 GPU passthrough detected"
else
    echo "- Not WSL2 or GPU passthrough not enabled"
fi
```

#### 基本的なシステム設定

```bash
# ユーザーを適切なグループに追加
sudo usermod -a -G render,video $USER

# 再ログインが必要
# ログイン後、権限を確認
groups $USER | grep -E "(render|video)"
```

#### Docker環境でのAMD GPU設定

```bash
# AMD GPU対応のOllamaコンテナを使用
docker run -d --name ollama \
  --device /dev/kfd --device /dev/dri \
  -e HSA_OVERRIDE_GFX_VERSION=10.3.0 \
  -e OLLAMA_MAX_LOADED_MODELS=1 \
  -e OLLAMA_NUM_PARALLEL=2 \
  -e GPU_MAX_ALLOC_PERCENT=80 \
  -v ollama:/root/.ollama \
  -p 11434:11434 \
  ollama/ollama:rocm
```

### AMD GPU向けsystemd設定

```bash
# AMD GPU用のオーバーライド設定
sudo tee /etc/systemd/system/ollama.service.d/amd-override.conf <<EOF
[Service]
Environment="ROCM_PATH=/opt/rocm"
Environment="HIP_PATH=/opt/rocm"
Environment="HSA_OVERRIDE_GFX_VERSION=10.3.0"
Environment="ROCR_VISIBLE_DEVICES=0"
Environment="GPU_MAX_ALLOC_PERCENT=80"
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_NUM_PARALLEL=2"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_GPU_LAYERS=35"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### よくあるAMD GPU問題とトラブルシューティング

#### GPU世代の互換性問題

多くのAMD GPUは直接サポートされていないため、世代のオーバーライドが必要です：

```bash
# gfx1032（例：RX 6400）をgfx1030として認識させる
export HSA_OVERRIDE_GFX_VERSION=10.3.0

# gfx1103（例：RX 7600）をgfx1100として認識させる  
export HSA_OVERRIDE_GFX_VERSION=11.0.0

# 対応表
# RX 6000シリーズ → 10.3.0
# RX 7000シリーズ → 11.0.0
```

#### メモリ不足エラーの対処

```bash
# "HIP out of memory" エラーの場合
export GPU_MAX_ALLOC_PERCENT=70  # より保守的な設定

# 量子化モデルの使用を検討
ollama pull llama2:7b-q4_0  # 4bit量子化でメモリ使用量を削減
```

#### 統合GPU（iGPU）使用時の注意点

```bash
# iGPUを使用する場合（例：Ryzen APU）
# BIOSでiGPU専用メモリを2GB以上に設定することを推奨

# パフォーマンス期待値（例：Ryzen 5600G）
# - プロンプト処理: ~70 tokens/sec
# - テキスト生成: ~6 tokens/sec
# （CPU単体の約2-3倍の性能）
```

### AMD GPUパフォーマンス最適化のベストプラクティス

1. **適切な量子化モデルの選択**
   ```bash
   # VRAM容量に応じたモデル選択
   # 8GB VRAM → 7Bモデル（q4_0量子化）
   # 16GB VRAM → 13Bモデル（q4_0量子化）
   # 24GB VRAM → 30Bモデル（q4_0量子化）
   ```

2. **並行処理の調整**
   ```bash
   # AMD GPUでは保守的な設定を推奨
   export OLLAMA_NUM_PARALLEL=1  # 大きなモデル使用時
   export OLLAMA_NUM_PARALLEL=2  # 小さなモデル使用時
   ```

3. **定期的な健全性チェック**
   ```bash
   # GPU認識状況の確認
   rocminfo | grep "Name:"
   
   # デバイスアクセス権限の確認
   ls -la /dev/kfd /dev/dri/
   
   # Ollama GPU使用状況の確認
   curl -s http://localhost:11434/api/ps
   ```

## パフォーマンス監視とデバッグ

### GPU使用率の確認

#### NVIDIA GPUの場合

```bash
# NVIDIA GPU情報の表示
nvidia-smi

# 継続的な監視
watch -n 1 nvidia-smi
```

#### AMD GPUの場合

```bash
# ROCm SMI（推奨）- 基本情報表示
rocm-smi

# 詳細情報表示
rocm-smi --showclocks      # クロック周波数
rocm-smi --showmeminfo     # メモリ使用状況
rocm-smi --showtemp        # 温度情報
rocm-smi --showpower       # 電力消費

# AMD SMI（新しいツール、ROCm 6.0以降）
amd-smi

# radeontop（軽量な監視ツール）
radeontop

# 継続的な監視例
watch -n 1 rocm-smi
watch -n 2 'rocm-smi --showmeminfo --showtemp'

# GUI監視ツール（インストール可能な場合）
amdgpu_top  # より視覚的なインターフェース
```

#### 共通コマンド

```bash
# Ollamaの詳細情報
ollama ps --verbose

# システム全体のGPU情報
lspci | grep -E "(VGA|3D)"
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
- [Quick Inference ベンチマーク - Windows vs Linux in WSL2](https://www.quickinference.com/2024/11/03/ollama-speed-test-windows-vs-linux-in-wsl2/)
- [Ollama Issue #2529 - WSL2 パフォーマンス問題](https://github.com/ollama/ollama/issues/2529)
- [Ollama Issue #1431 - WSL2 ネットワーク制限](https://github.com/ollama/ollama/issues/1431)
- [Open WebUI Discussion #510 - Docker接続問題](https://github.com/open-webui/open-webui/discussions/510)

<!-- vim: set et tw=0 ts=2 sw=2: -->