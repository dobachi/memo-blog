.PHONY: help build preview clean check commit push commit-push new

# デフォルトターゲット: ヘルプ表示
help:
	@echo "使い方: make <target>"
	@echo ""
	@echo "ビルド・プレビュー:"
	@echo "  build         クリーンビルドして静的ファイルを生成 (hexo clean && hexo generate)"
	@echo "  preview       ローカルサーバーを起動 (hexo server)"
	@echo "  clean         生成物を削除 (hexo clean)"
	@echo "  check         ビルドが通るか検証 (hexo generate)"
	@echo ""
	@echo "Git 操作:"
	@echo "  commit MSG=\"...\"        ステージ済み変更をコミット"
	@echo "  push                    リモートへプッシュ"
	@echo "  commit-push MSG=\"...\"   ビルド検証→コミット→プッシュ"
	@echo ""
	@echo "記事作成:"
	@echo "  new TITLE=\"title\"      新規記事を作成 (hexo new post)"

build:
	npx hexo clean && npx hexo generate

preview:
	npx hexo server -i 0.0.0.0

clean:
	npx hexo clean

check:
	@echo "🔍 ビルド検証中..."
	@npx hexo clean > /dev/null
	@npx hexo generate > /dev/null || (echo "❌ hexo generate が失敗"; exit 1)
	@python3 bin/check_build.py public || (echo "❌ 生成物が空。終了コードは0でも中身が無い"; exit 1)
	@echo "✅ ビルド成功（生成物の実体を確認）"

new:
ifndef TITLE
	$(error TITLE が指定されていません。例: make new TITLE="my-post")
endif
	npx hexo new post "$(TITLE)"

commit:
ifndef MSG
	$(error MSG が指定されていません。例: make commit MSG="blog: 記事を追加")
endif
	git commit -m "$(MSG)"

push:
	git push

commit-push: check commit push
