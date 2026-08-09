#!/usr/bin/env python3
"""生成物の中のローカル画像参照が、実在するファイルを指しているか検査する。

記事の画像リンクは先頭の `/` を落としやすく（`images/foo.png`）、その場合
記事ディレクトリからの相対解決になって404になる。ビルドは成功し、ページも
200を返すため、**目視でその記事を開くまで誰も気づかない**。実際に13枚が
何年も壊れたまま公開されていた（2026-08-09 に発見）。

使い方:   python3 bin/check_images.py [生成ディレクトリ]
終了コード: 0=許容内  1=新たな壊れ  2=引数エラー

外部URL（http/https/data:）は見ない。ネットワークに出ないための割り切り。
"""

import os
import re
import sys
from urllib.parse import urlparse, unquote

# ─────────── 設定: 必要に応じて書き換える ───────────
OUT_DIR = "public"
BASE = "/memo-blog/"          # サイトのルートパス（_config.yml の root）
IMG = re.compile(r'<img[^>]+src="([^"]+)"')
SKIP = ("avatar",)            # テーマ由来で常に出るもの

# 既知の壊れ。**実ファイルが失われている**もののみ列挙する。
# パスの書き間違いは直すこと。ここに足すのは最後の手段。
ALLOWED = {
    # source/images に実体が無い。org1 と org3 はあるが org2 だけ失われている
    "images/20220123_ckan_create_org2.JPG",
}
SHOW = 20
# ────────────────────────────────────────────────────


def scan(root):
    broken = {}
    total = 0
    for dirpath, _, files in os.walk(root):
        if "index.html" not in files:
            continue
        html = open(os.path.join(dirpath, "index.html"), encoding="utf-8",
                    errors="replace").read()
        for u in dict.fromkeys(IMG.findall(html)):
            if any(s in u for s in SKIP) or u.startswith(("http://", "https://", "data:")):
                continue
            total += 1
            path = unquote(urlparse(u).path)
            target = (os.path.join(root, path[len(BASE):]) if path.startswith(BASE)
                      else os.path.join(dirpath, path))
            if not os.path.isfile(target):
                broken.setdefault(u, []).append(os.path.relpath(dirpath, root))
    return total, broken


def main():
    args = sys.argv[1:]
    if len(args) > 1:
        print(__doc__)
        return 2
    root = args[0] if args else OUT_DIR
    if not os.path.isdir(root):
        print(f"{root}: ディレクトリが無い。ビルドが走っていない可能性がある")
        return 1

    total, broken = scan(root)
    new = {u: p for u, p in broken.items() if u not in ALLOWED}
    known = len(broken) - len(new)

    print(f"\n{root} — ローカル画像参照 {total}件 / 壊れ {len(broken)}種"
          f"（既知 {known} / 新規 {len(new)}）")
    for u, pages in list(new.items())[:SHOW]:
        print(f"  NG   {u}")
        print(f"       {len(pages)}ページ 例: /{pages[0]}/")
    if len(new) > SHOW:
        print(f"       … 他 {len(new) - SHOW}種")
    if not new:
        print("  OK   新たに壊れた画像参照は無い")

    print("\n保証しないこと")
    print("  - 外部URLの画像は見ない（ネットワークに出さないため）")
    print("  - 画像の中身は見ない。ファイルが在ることまで")
    print(f"  - ALLOWED{sorted(ALLOWED)} は実ファイルが失われた既知分として素通しする")
    print(f"\n判定: {'NG' if new else 'OK'}（新規 {len(new)}種）")
    return 1 if new else 0


if __name__ == "__main__":
    sys.exit(main())
