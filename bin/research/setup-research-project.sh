#!/bin/bash

################################################################################
# Research Project Setup Script
# 
# Description: 
#   新しいリサーチプロジェクトを初期化し、テンプレート構造を生成する
#
# Usage:
#   ./setup-research-project.sh [project-name]
#
# Example:
#   ./setup-research-project.sh ai-market-analysis
#
# Created: 2025-01-13
# Version: 1.0.0
################################################################################

set -e  # エラー時に終了

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/../../research/resources/templates"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

################################################################################
# Functions
################################################################################

print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Research Project Setup Tool v1.0.0${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# 使用方法の表示
show_usage() {
    cat << EOF
使用方法:
    $0 [project-name]

オプション:
    -h, --help      このヘルプを表示
    -f, --force     既存ディレクトリを上書き
    -i, --interactive  対話モードで実行（デフォルト）
    -q, --quiet     静かモード（確認なし）

例:
    $0 ai-market-analysis
    $0 --interactive
    $0 -f existing-project

EOF
}

# プロジェクト名の検証
validate_project_name() {
    local name="$1"
    
    # 空文字チェック
    if [ -z "$name" ]; then
        print_error "プロジェクト名を指定してください"
        return 1
    fi
    
    # 文字制限（英数字、ハイフン、アンダースコア）
    if ! [[ "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "プロジェクト名は英数字、ハイフン、アンダースコアのみ使用できます"
        return 1
    fi
    
    # 長さチェック
    if [ ${#name} -gt 50 ]; then
        print_error "プロジェクト名は50文字以内にしてください"
        return 1
    fi
    
    return 0
}

# 対話モード
interactive_setup() {
    print_header
    
    # プロジェクト名
    echo -e "${BLUE}Step 1: プロジェクト名の設定${NC}"
    echo -n "プロジェクト名を入力してください（英数字、ハイフン、アンダースコア）: "
    read -r PROJECT_NAME
    
    if ! validate_project_name "$PROJECT_NAME"; then
        exit 1
    fi
    
    echo ""
    echo -e "${BLUE}Step 2: プロジェクト詳細${NC}"
    
    # プロジェクトの説明
    echo -n "プロジェクトの簡単な説明 (1-2文): "
    read -r PROJECT_DESCRIPTION
    
    # 想定読者
    echo -n "想定読者 (例: 技術責任者、経営層): "
    read -r TARGET_AUDIENCE
    
    # 調査期間
    echo -n "調査期間（週単位、例: 4）: "
    read -r DURATION_WEEKS
    
    # 作成者名
    echo -n "あなたの名前またはチーム名: "
    read -r AUTHOR_NAME
    
    echo ""
    echo -e "${BLUE}Step 3: 追加オプション${NC}"
    
    # Git初期化
    echo -n "Gitリポジトリとして初期化しますか？ (y/n) [y]: "
    read -r INIT_GIT
    INIT_GIT=${INIT_GIT:-y}
    
    # checkpoint.sh統合
    echo -n "checkpoint.shと統合しますか？ (y/n) [y]: "
    read -r USE_CHECKPOINT
    USE_CHECKPOINT=${USE_CHECKPOINT:-y}
    
    echo ""
    echo -e "${BLUE}確認${NC}"
    echo "────────────────────────────────"
    echo "プロジェクト名: $PROJECT_NAME"
    echo "説明: $PROJECT_DESCRIPTION"
    echo "想定読者: $TARGET_AUDIENCE"
    echo "調査期間: ${DURATION_WEEKS}週間"
    echo "作成者: $AUTHOR_NAME"
    echo "Git初期化: $INIT_GIT"
    echo "checkpoint.sh統合: $USE_CHECKPOINT"
    echo "────────────────────────────────"
    echo ""
    
    echo -n "この設定で続行しますか？ (y/n) [y]: "
    read -r CONFIRM
    CONFIRM=${CONFIRM:-y}
    
    if [ "$CONFIRM" != "y" ]; then
        print_warning "キャンセルされました"
        exit 0
    fi
}

# ディレクトリ構造の作成
create_directory_structure() {
    local project_dir="$1"
    
    print_info "ディレクトリ構造を作成中..."
    
    # メインディレクトリ
    mkdir -p "$project_dir"
    
    # サブディレクトリ
    mkdir -p "$project_dir/sources/official"
    mkdir -p "$project_dir/sources/academic"
    mkdir -p "$project_dir/sources/industry"
    mkdir -p "$project_dir/sources/country_cases"
    mkdir -p "$project_dir/drafts"
    mkdir -p "$project_dir/final"
    mkdir -p "$project_dir/progress"
    mkdir -p "$project_dir/assets/images"
    mkdir -p "$project_dir/assets/data"
    
    print_success "ディレクトリ構造を作成しました"
}

# テンプレートファイルのコピーと置換
copy_and_customize_templates() {
    local project_dir="$1"
    local today=$(date +%Y-%m-%d)
    local end_date=$(date -d "+${DURATION_WEEKS} weeks" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
    
    print_info "テンプレートファイルをコピー中..."
    
    # README.mdの作成
    if [ -f "${TEMPLATE_DIR}/README.template.md" ]; then
        sed -e "s/\[プロジェクト名\]/${PROJECT_NAME}/g" \
            -e "s/\[このプロジェクトの目的と背景を2-3文で記述\]/${PROJECT_DESCRIPTION}/g" \
            -e "s/\[例：技術責任者、プロダクトマネージャー\]/${TARGET_AUDIENCE}/g" \
            -e "s/\[名前\/役割\]/${AUTHOR_NAME}/g" \
            -e "s/YYYY-MM-DD/${today}/g" \
            "${TEMPLATE_DIR}/README.template.md" > "$project_dir/README.md"
        print_success "README.md を作成しました"
    fi
    
    # INVESTIGATION_GUIDE.mdの作成
    if [ -f "${TEMPLATE_DIR}/INVESTIGATION_GUIDE.template.md" ]; then
        sed -e "s/\[プロジェクト名\]/${PROJECT_NAME}/g" \
            -e "s/YYYY-MM-DD/${today}/g" \
            "${TEMPLATE_DIR}/INVESTIGATION_GUIDE.template.md" > "$project_dir/INVESTIGATION_GUIDE.md"
        print_success "INVESTIGATION_GUIDE.md を作成しました"
    fi
    
    # citation-policy.mdのコピー
    if [ -f "${TEMPLATE_DIR}/citation-policy.template.md" ]; then
        cp "${TEMPLATE_DIR}/citation-policy.template.md" "$project_dir/citation-policy.md"
        print_success "citation-policy.md をコピーしました"
    fi
    
    # REFERENCES.mdの作成
    if [ -f "${TEMPLATE_DIR}/REFERENCES.template.md" ]; then
        sed -e "s/YYYY-MM-DD/${today}/g" \
            -e "s/\[名前\]/${AUTHOR_NAME}/g" \
            "${TEMPLATE_DIR}/REFERENCES.template.md" > "$project_dir/sources/REFERENCES.md"
        print_success "sources/REFERENCES.md を作成しました"
    fi
    
    # 追加ファイルの作成
    create_additional_files "$project_dir"
}

# 追加ファイルの作成
create_additional_files() {
    local project_dir="$1"
    local today=$(date +%Y-%m-%d)
    
    # .gitignore
    if [ "$INIT_GIT" = "y" ]; then
        cat > "$project_dir/.gitignore" << EOF
# 一時ファイル
*.tmp
*.swp
*~
.DS_Store

# ビルド成果物
/public/
/dist/
/build/

# 個人設定
.env
.env.local

# エディタ設定
.vscode/
.idea/

# ログファイル
*.log
checkpoint.log.lock
EOF
        print_success ".gitignore を作成しました"
    fi
    
    # timeline.md
    cat > "$project_dir/timeline.md" << EOF
# タイムライン - ${PROJECT_NAME}

## プロジェクト期間
- 開始日: ${today}
- 終了予定: $(date -d "+${DURATION_WEEKS} weeks" +%Y-%m-%d 2>/dev/null || echo "YYYY-MM-DD")

## マイルストーン

### Week 1-2: Phase 1 - 基礎調査
- [ ] 背景調査
- [ ] 文献収集
- [ ] スコープ定義

### Week 3-4: Phase 2 - 詳細分析
- [ ] 技術分析
- [ ] ビジネス分析
- [ ] リスク評価

### Week 5-6: Phase 3 - 統合・考察
- [ ] データ統合
- [ ] 洞察の導出
- [ ] 提言作成

### Week 7-8: Phase 4 - レポート作成
- [ ] 執筆
- [ ] レビュー
- [ ] 最終化

## 重要な日付
- ${today}: プロジェクト開始

---
最終更新: ${today}
EOF
    print_success "timeline.md を作成しました"
    
    # research-plan.md
    cat > "$project_dir/research-plan.md" << EOF
# 調査計画 - ${PROJECT_NAME}

## 概要
${PROJECT_DESCRIPTION}

## 調査目的
1. [主要目的1]
2. [主要目的2]
3. [主要目的3]

## 調査方法

### データ収集
- 文献調査
- 専門家インタビュー
- 市場データ分析
- ケーススタディ

### 分析手法
- 定性分析
- 定量分析
- 比較分析
- SWOT分析

## 期待される成果
- 包括的な調査レポート
- エグゼクティブサマリー
- 実装提言書
- プレゼンテーション資料

## リソース要件
- 調査期間: ${DURATION_WEEKS}週間
- 調査員: ${AUTHOR_NAME}
- 必要なツール: [ツールリスト]

## リスクと対策
| リスク | 影響 | 対策 |
|--------|------|------|
| 情報不足 | 高 | 追加の情報源を確保 |
| 時間制約 | 中 | スコープの優先順位付け |

---
作成日: ${today}
作成者: ${AUTHOR_NAME}
EOF
    print_success "research-plan.md を作成しました"
}

# Git初期化
init_git_repo() {
    local project_dir="$1"
    
    if [ "$INIT_GIT" = "y" ]; then
        print_info "Gitリポジトリを初期化中..."
        cd "$project_dir"
        git init
        git add .
        git commit -m "Initial commit: Research project ${PROJECT_NAME} setup"
        print_success "Gitリポジトリを初期化しました"
        cd - > /dev/null
    fi
}

# checkpoint.sh統合
setup_checkpoint() {
    local project_dir="$1"
    
    if [ "$USE_CHECKPOINT" = "y" ] && [ -f "${PROJECT_ROOT}/scripts/checkpoint.sh" ]; then
        print_info "checkpoint.shと統合中..."
        
        # checkpoint開始コマンドの生成
        cat > "$project_dir/start-research.sh" << EOF
#!/bin/bash
# Research project checkpoint integration
# Generated: $(date +%Y-%m-%d)

# プロジェクトルートへの相対パス
PROJECT_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/../.." && pwd)"

# checkpoint.shを使用してタスクを開始
if [ -f "\${PROJECT_ROOT}/scripts/checkpoint.sh" ]; then
    "\${PROJECT_ROOT}/scripts/checkpoint.sh" start "${PROJECT_NAME}-research" 4
    echo ""
    echo "タスクが開始されました。"
    echo "進捗報告には以下のコマンドを使用してください："
    echo "  \${PROJECT_ROOT}/scripts/checkpoint.sh progress [TASK-ID] [current] 4 [status] [next]"
else
    echo "checkpoint.sh が見つかりません"
fi
EOF
        chmod +x "$project_dir/start-research.sh"
        print_success "checkpoint.sh統合スクリプトを作成しました"
    fi
}

# 完了メッセージ
show_completion_message() {
    local project_dir="$1"
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  プロジェクトの作成が完了しました！${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "プロジェクトディレクトリ: ${project_dir}"
    echo ""
    echo "次のステップ:"
    echo "  1. cd ${project_dir}"
    echo "  2. README.md を編集して詳細を追加"
    echo "  3. research-plan.md で調査計画を具体化"
    
    if [ "$USE_CHECKPOINT" = "y" ]; then
        echo "  4. ./start-research.sh でタスクを開始"
    fi
    
    echo ""
    echo "構造:"
    echo "  sources/       - 情報源と参考文献"
    echo "  drafts/        - 作業中の文書"
    echo "  final/         - 完成版文書"
    echo "  progress/      - 進捗レポート"
    echo "  assets/        - 画像やデータファイル"
    echo ""
    echo "Happy researching! 📚"
}

################################################################################
# Main
################################################################################

# オプション解析
FORCE=false
INTERACTIVE=true
QUIET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            INTERACTIVE=false
            shift
            ;;
        -*)
            print_error "不明なオプション: $1"
            show_usage
            exit 1
            ;;
        *)
            PROJECT_NAME="$1"
            INTERACTIVE=false
            shift
            ;;
    esac
done

# 対話モードまたは引数チェック
if [ "$INTERACTIVE" = true ]; then
    interactive_setup
else
    if [ -z "$PROJECT_NAME" ]; then
        print_error "プロジェクト名が指定されていません"
        show_usage
        exit 1
    fi
    
    if ! validate_project_name "$PROJECT_NAME"; then
        exit 1
    fi
    
    # デフォルト値の設定
    PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-Research project}"
    TARGET_AUDIENCE="${TARGET_AUDIENCE:-Stakeholders}"
    DURATION_WEEKS="${DURATION_WEEKS:-4}"
    AUTHOR_NAME="${AUTHOR_NAME:-Research Team}"
    INIT_GIT="${INIT_GIT:-y}"
    USE_CHECKPOINT="${USE_CHECKPOINT:-y}"
fi

# プロジェクトディレクトリのパス
PROJECT_DIR="${PROJECT_ROOT}/research/topics/${PROJECT_NAME}"

# 既存ディレクトリのチェック
if [ -d "$PROJECT_DIR" ] && [ "$FORCE" = false ]; then
    print_error "ディレクトリが既に存在します: $PROJECT_DIR"
    print_info "上書きする場合は -f オプションを使用してください"
    exit 1
fi

# メイン処理
print_info "プロジェクト '${PROJECT_NAME}' を作成中..."

create_directory_structure "$PROJECT_DIR"
copy_and_customize_templates "$PROJECT_DIR"
init_git_repo "$PROJECT_DIR"
setup_checkpoint "$PROJECT_DIR"

# 完了
show_completion_message "$PROJECT_DIR"

exit 0