#/bin/bash

wget https://github.com/jgm/pandoc/releases/download/3.3/pandoc-3.3-1-amd64.deb -P /tmp
sudo apt install /tmp/pandoc-3.3-1-amd64.deb
git submodule init   # テーマの取得
git submodule update   # テーマの取得
npm install
