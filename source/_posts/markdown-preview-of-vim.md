---

title: markdown preview of vim
date: 2019-12-21 17:04:53
categories:
  - Knowledge Management
  - vim
tags:
  - vim
  - markdown

---

# 参考

* [Vim + Markdown]
* [iamcco/markdown-preview.nvim]
* [shime/vim-livedown]
* [previm/previm]
* [iwataka/minidown.vim]

[Vim + Markdown]: https://qiita.com/iwataka/items/5355bdf03d0afd82e7a7
[iamcco/markdown-preview.nvim]: https://github.com/iamcco/markdown-preview.nvim
[shime/vim-livedown]: https://github.com/shime/vim-livedown
[previm/previm]: https://github.com/previm/previm
[iwataka/minidown.vim]: https://github.com/iwataka/minidown.vim

# メモ

[Vim + Markdown] のページに色々と載っていた。
前半はMarkdown編集のための補助ツール、後半はプレビューのツール。

プレビューとしては、結論として [iamcco/markdown-preview.nvim] を選んだ。

## 試したツール

* [shime/vim-livedown]
    * 外部ツールが必要だがnpmで導入可能なので簡易。
    * 悪くなかったが、動作が不安定だったので一旦保留。
* [iamcco/markdown-preview.nvim] 
    * 外部ツールが必要だが予めプラグインディレクトリ内にインストールされるような手順になっている
        * ただし手元のWSL環境ではnpmインストールに失敗していたため手動インストールした
    * 今のところ馴染んでいるので利用している
* [previm/previm]
    * 外部依存がなく悪くなさそうだった
    * WindowsのWSL環境で動作が不安定だったので一旦保留。

## その他試したいもの

* [iwataka/minidown.vim]
    * [Vim + Markdown] のブログ内で紹介されていた、ブログ主の作ったツール
    * ミニマムな機能で必要十分そう。外部依存が殆どないのが大きい

## iamcco/markdown-preview.nvim を試す際に気をつけたこと

プラグイン内でnodejsを利用するのだが、そのライブラリインストールにyarnを
使うようになっている。

公式READMEの文言を以下に引用。

```
call dein#add('iamcco/markdown-preview.nvim', {'on_ft': ['markdown', 'pandoc.markdown', 'rmd'],
					\ 'build': 'cd app & yarn install' })
```

個人的にはnpmを利用しているのでyarnではなくnpmでインストールするよう修正し実行した。
しかいｓ上記の通り、一部の環境ではプラグイン内にインストールする予定だったnpmライブラリが
インストールされない事象が生じた。

その際は、自身で `npm install` すればよい。

```
$ cd ~/vimfiles/bundles/repos/github.com/iamcco/markdown-preview.nvim/app
$ npm install
```

なお、 `~/vimfiles/bundles` のところは、各自のdeinレポジトリの場所を指定してほしい。

<!-- vim: set tw=0 et ts=4 sw=4: -->
