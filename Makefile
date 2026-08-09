.PHONY: help build preview clean check commit push commit-push new

# デフォルトターゲット: ヘルプ表示
help:
	@echo "使い方: make <target>"
	@echo ""
	@echo "ビルド・プレビュー:"
	@echo "  build         クリーンビルドして静的ファイルを生成 (hexo clean && hexo generate)"
	@echo "  preview       ローカルサーバーを起動 (hexo server)"
	@echo "  clean         生成物を削除 (hexo clean)"
	@echo "  check         生成物の実体を検証（ローカルビルドが壊れているため現在は失敗する）"
	@echo ""
	@echo "Git 操作:"
	@echo "  commit MSG=\"...\"        ステージ済み変更をコミット"
	@echo "  push                    リモートへプッシュ"
	@echo "  commit-push MSG=\"...\"   コミット→プッシュ（ビルド検証は CI に任せる）"
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

commit-push:
	@echo "⚠️  ローカルのビルド検証は現在使えない。"
	@echo "    hexo 3.7.1 を新しい Node で動かすと生成物が全て0バイトになるため、"
	@echo "    make check は（正しく）失敗する。検証は push 後の CI と公開サイトで行う。"
	@echo ""
	@$(MAKE) commit MSG="$(MSG)"
	@$(MAKE) push
