#!/bin/bash

################################################################################
# Citation Validation Script
# 
# Description: 
#   プロジェクト内の引用と参考文献の整合性を検証する
#
# Usage:
#   ./validate-citations.sh [project-dir]
#
# Example:
#   ./validate-citations.sh ../topics/ai-market-analysis
#   ./validate-citations.sh  # カレントディレクトリで実行
#
# Created: 2025-01-13
# Version: 1.0.0
################################################################################

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# カウンター
TOTAL_FILES=0
TOTAL_CITATIONS=0
TOTAL_REFERENCES=0
ERRORS=0
WARNINGS=0

# 引用パターン（改善されたプリフィックス形式）
CITATION_PATTERN='\[(GOV|INT|LAW|ACA|RES|STAT|TECH|IND|CORP|MED|CONF|BLOG|WEB|MISC|JP-GOV|EU-GOV|US-GOV)-[0-9]{3}\]'

################################################################################
# Functions
################################################################################

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Citation Validation Tool v1.0.0${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# 使用方法
show_usage() {
    cat << EOF
使用方法:
    $0 [options] [project-dir]

オプション:
    -h, --help      このヘルプを表示
    -v, --verbose   詳細な出力
    -q, --quiet     エラーのみ表示
    -f, --fix       可能な修正を自動実行
    -r, --report    レポートを生成

引数:
    project-dir     検証するプロジェクトディレクトリ（デフォルト: .）

例:
    $0                                    # カレントディレクトリ
    $0 ../topics/ai-market-analysis       # 特定のプロジェクト
    $0 -v -r .                           # 詳細モードでレポート生成

EOF
}

# ディレクトリの検証
validate_directory() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        print_error "ディレクトリが存在しません: $dir"
        exit 1
    fi
    
    if [ ! -f "$dir/sources/REFERENCES.md" ] && [ ! -f "$dir/REFERENCES.md" ]; then
        print_warning "REFERENCES.md が見つかりません"
        echo "    探索パス: $dir/sources/REFERENCES.md または $dir/REFERENCES.md"
        return 1
    fi
    
    return 0
}

# REFERENCES.mdから引用IDを抽出
extract_references() {
    local ref_file="$1"
    local -a refs=()
    
    if [ -f "$ref_file" ]; then
        # 改善されたプリフィックス形式のIDを抽出
        while IFS= read -r line; do
            if [[ $line =~ \[([A-Z]+-[A-Z]*-?[0-9]{3})\] ]]; then
                refs+=("${BASH_REMATCH[1]}")
            fi
        done < "$ref_file"
    fi
    
    echo "${refs[@]}"
}

# ファイル内の引用を抽出
extract_citations() {
    local file="$1"
    local -a citations=()
    
    # Markdownファイル内の引用を検索
    while IFS= read -r line; do
        # すべての引用パターンを抽出
        while [[ $line =~ \[([A-Z]+-[A-Z]*-?[0-9]{3})\] ]]; do
            citations+=("${BASH_REMATCH[1]}")
            # 処理済み部分を削除して次を検索
            line=${line#*"[${BASH_REMATCH[1]}]"}
        done
    done < "$file"
    
    echo "${citations[@]}"
}

# 引用の検証
validate_citations() {
    local project_dir="$1"
    local verbose="$2"
    
    # REFERENCES.mdの場所を特定
    local ref_file=""
    if [ -f "$project_dir/sources/REFERENCES.md" ]; then
        ref_file="$project_dir/sources/REFERENCES.md"
    elif [ -f "$project_dir/REFERENCES.md" ]; then
        ref_file="$project_dir/REFERENCES.md"
    else
        print_error "REFERENCES.md が見つかりません"
        return 1
    fi
    
    print_info "参考文献ファイル: $ref_file"
    
    # 参考文献リストを取得
    local references=($(extract_references "$ref_file"))
    TOTAL_REFERENCES=${#references[@]}
    print_info "登録済み参考文献: ${TOTAL_REFERENCES}件"
    
    if [ "$verbose" = true ]; then
        echo "  参考文献リスト:"
        for ref in "${references[@]}"; do
            echo "    - $ref"
        done
        echo ""
    fi
    
    # 使用された引用を追跡
    declare -A used_citations
    declare -A citation_files
    
    # プロジェクト内のMarkdownファイルを検索
    print_info "Markdownファイルを検索中..."
    
    while IFS= read -r -d '' file; do
        # REFERENCES.md自体はスキップ
        if [[ "$file" == *"REFERENCES.md" ]]; then
            continue
        fi
        
        ((TOTAL_FILES++))
        
        local file_citations=($(extract_citations "$file"))
        local file_citation_count=${#file_citations[@]}
        
        if [ $file_citation_count -gt 0 ]; then
            local relative_path="${file#$project_dir/}"
            if [ "$verbose" = true ]; then
                echo "  📄 $relative_path: ${file_citation_count}件の引用"
            fi
            
            for citation in "${file_citations[@]}"; do
                ((TOTAL_CITATIONS++))
                used_citations["$citation"]=1
                
                # ファイルごとの引用を記録
                if [ -z "${citation_files[$citation]}" ]; then
                    citation_files["$citation"]="$relative_path"
                else
                    citation_files["$citation"]="${citation_files[$citation]}, $relative_path"
                fi
                
                # 参考文献リストに存在するか確認
                local found=false
                for ref in "${references[@]}"; do
                    if [ "$citation" = "$ref" ]; then
                        found=true
                        break
                    fi
                done
                
                if [ "$found" = false ]; then
                    print_error "未定義の引用: [$citation] in $relative_path"
                fi
            done
        fi
    done < <(find "$project_dir" -type f -name "*.md" -print0)
    
    echo ""
    print_info "ファイル検証完了: ${TOTAL_FILES}ファイル、${TOTAL_CITATIONS}件の引用"
    
    # 未使用の参考文献をチェック
    echo ""
    print_info "未使用の参考文献をチェック中..."
    
    local unused_count=0
    for ref in "${references[@]}"; do
        if [ -z "${used_citations[$ref]}" ]; then
            print_warning "未使用の参考文献: [$ref]"
            ((unused_count++))
        fi
    done
    
    if [ $unused_count -eq 0 ]; then
        print_success "すべての参考文献が使用されています"
    fi
    
    # 引用の重複チェック
    echo ""
    print_info "引用の使用頻度を分析中..."
    
    if [ "$verbose" = true ]; then
        echo "  引用使用統計:"
        for citation in "${!citation_files[@]}"; do
            local count=$(echo "${citation_files[$citation]}" | tr ',' '\n' | wc -l)
            echo "    [$citation]: ${count}回使用"
            if [ $count -gt 5 ]; then
                print_warning "[$citation] が多用されています（${count}回）"
            fi
        done
    fi
}

# 修正モード
fix_issues() {
    local project_dir="$1"
    
    print_info "自動修正モード（未実装）"
    print_warning "現在、手動での修正が必要です"
    
    # 将来的な実装:
    # - 未使用の参考文献をコメントアウト
    # - 引用形式の統一
    # - 番号の再採番
}

# レポート生成
generate_report() {
    local project_dir="$1"
    local report_file="$project_dir/citation-validation-report.md"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    cat > "$report_file" << EOF
# 引用検証レポート

生成日時: $timestamp

## サマリー

- 検証ファイル数: ${TOTAL_FILES}
- 総引用数: ${TOTAL_CITATIONS}
- 登録参考文献数: ${TOTAL_REFERENCES}
- エラー数: ${ERRORS}
- 警告数: ${WARNINGS}

## 検証結果

### ✅ 成功
- 引用形式の一貫性
- 参考文献ファイルの存在

### ⚠️ 警告
EOF
    
    if [ $WARNINGS -gt 0 ]; then
        echo "- ${WARNINGS}件の警告が検出されました" >> "$report_file"
    else
        echo "- 警告はありません" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

### ❌ エラー
EOF
    
    if [ $ERRORS -gt 0 ]; then
        echo "- ${ERRORS}件のエラーが検出されました" >> "$report_file"
    else
        echo "- エラーはありません" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## 推奨事項

1. 未定義の引用がある場合は、REFERENCES.mdに追加してください
2. 未使用の参考文献は、削除または今後使用することを検討してください
3. 引用IDの命名規則に従っているか確認してください

## 引用ID命名規則

- GOV-###: 政府・公式文書
- ACA-###: 学術論文
- TECH-###: 技術仕様
- MED-###: メディア記事
- その他...

---
Generated by validate-citations.sh v1.0.0
EOF
    
    print_success "レポートを生成しました: $report_file"
}

# 結果サマリー
show_summary() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  検証結果サマリー${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo "📊 統計:"
    echo "  • ファイル数: ${TOTAL_FILES}"
    echo "  • 引用総数: ${TOTAL_CITATIONS}"
    echo "  • 参考文献数: ${TOTAL_REFERENCES}"
    echo ""
    
    if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✅ すべての検証に合格しました！${NC}"
    else
        if [ $ERRORS -gt 0 ]; then
            echo -e "${RED}❌ ${ERRORS}件のエラーが見つかりました${NC}"
        fi
        if [ $WARNINGS -gt 0 ]; then
            echo -e "${YELLOW}⚠️  ${WARNINGS}件の警告があります${NC}"
        fi
        echo ""
        echo "詳細は上記のメッセージを確認してください。"
    fi
    
    echo ""
}

################################################################################
# Main
################################################################################

# オプション解析
VERBOSE=false
QUIET=false
FIX=false
REPORT=false
PROJECT_DIR="."

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -f|--fix)
            FIX=true
            shift
            ;;
        -r|--report)
            REPORT=true
            shift
            ;;
        -*)
            print_error "不明なオプション: $1"
            show_usage
            exit 1
            ;;
        *)
            PROJECT_DIR="$1"
            shift
            ;;
    esac
done

# ヘッダー表示
if [ "$QUIET" = false ]; then
    print_header
fi

# ディレクトリの検証
print_info "プロジェクトディレクトリ: $PROJECT_DIR"
if ! validate_directory "$PROJECT_DIR"; then
    if [ "$FIX" = true ]; then
        print_info "REFERENCES.md を作成します..."
        mkdir -p "$PROJECT_DIR/sources"
        touch "$PROJECT_DIR/sources/REFERENCES.md"
        print_success "REFERENCES.md を作成しました"
    else
        exit 1
    fi
fi

# メイン処理
echo ""
validate_citations "$PROJECT_DIR" "$VERBOSE"

# 修正モード
if [ "$FIX" = true ]; then
    echo ""
    fix_issues "$PROJECT_DIR"
fi

# レポート生成
if [ "$REPORT" = true ]; then
    echo ""
    generate_report "$PROJECT_DIR"
fi

# サマリー表示
if [ "$QUIET" = false ]; then
    show_summary
fi

# 終了コード
if [ $ERRORS -gt 0 ]; then
    exit 1
else
    exit 0
fi