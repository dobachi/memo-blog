---

title: WSL2上のVS CodeでMCPサーバー
date: 2025-06-08 22:22:00
tags:
  - VS Code
  - AI
categories:
  - AI
  - MCP

---

## WSL2上でVS Codeの環境構成

[【WSL / WSL2】VSCode×WSLでWindows上にLinux開発環境を構築](https://qiita.com/_masa_u/items/d3c1fa7898b0783bc3ed) に記載の通り、VS Codeに拡張機能をインストールする。自分の場合は、

- Remote Development

をインストールした。これにより、4個ほどの拡張機能がインストールされる。

## VS Codeの設定

[WSL2 の VS Code で GitHub MCP Server (github-mcp-server) を動かしてみた](https://techblog.ap-com.co.jp/entry/2025/04/07/190000) にあるように、設定画面を開き、「Remote [WSL: xxxxxxx]」タブを開く。

「mcp」を検索すると、settings.jsonファイルを開けるので開く。

今回試すのは、[VS Code の設定から MCPサーバーを追加して GitHub Copilot agent mode で利用してみる（安定版でも利用可能に）](https://qiita.com/youtoy/items/adfeedeedf1309f194ce)に掲載されている、ローカルファイルを編集するためのMCPサーバー。

事前に `npm` コマンドをインストールしておくこと。

```bash
sudo apt install npm
sudo npm install -g n
sudo n stable
```

なお、Ubuntu22系にインストールされるNPMでは古すぎたので、 `n` を使って、最新版のnpmをインストールしている。ご自身の環境に合わせて実行してほしい。

さて、settings.jsonにはもともとmcp-server-timeがあったはずだが、その下に、以下を追記する。

```json
            "filesystem": {
                "command": "npx",
                "args": [
                    "-y",
                    "@modelcontextprotocol/server-filesystem",
                    "tmp"
                ],
            }
```

パスを渡している `tmp` の箇所は適宜自身の環境に合わせて書き換えてほしい。今回は、VS Codeを開いたプロジェクトディレクトリ以下に `tmp` というディレクトリを掘って作成するようになる。

あとは、[VS Code の設定から MCPサーバーを追加して GitHub Copilot agent mode で利用してみる（安定版でも利用可能に）](https://qiita.com/youtoy/items/adfeedeedf1309f194ce)にある通り、Copilotなり、任意のAIエージェントから操作すればよい。

例えば、

- 「フォルダは何？」
- 「npxの概要を記載し、/home/<user name>/tmp以下に保存して」

などとエージェントに依頼すると適宜返事をくれたり、ファイルを作成したりしてくれる。

## 参考文献

1. 【WSL / WSL2】VSCode×WSLでWindows上にLinux開発環境を構築
URL: https://qiita.com/_masa_u/items/d3c1fa7898b0783bc3ed
2. WSL2 の VS Code で GitHub MCP Server (github-mcp-server) を動かしてみた
URL: https://techblog.ap-com.co.jp/entry/2025/04/07/190000
3. VS Code の設定から MCPサーバーを追加して GitHub Copilot agent mode で利用してみる（安定版でも利用可能に）
URL: https://qiita.com/youtoy/items/adfeedeedf1309f194ce



<!-- vim: set et tw=0 ts=2 sw=2: -->
