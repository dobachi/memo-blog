---

title: Ubuntu 26でキーボードをカスタマイズ（Caps Lock⇔Ctrl入れ替えとCtrl+SpaceでIME切替）
date: 2026-05-09 22:00:00
categories:
  - Ubuntu
  - Keyboard
tags:
  - Ubuntu
  - Keyboard
  - GNOME
  - Wayland
  - Mozc
  - IBus
  - fcitx5

---

# メモ

Ubuntu 26.04 LTS (Resolute Raccoon) でキーボードを2点カスタマイズするメモ。

1. Caps LockキーとCtrlキーを入れ替える
2. Ctrl + Space で日本語入力（Mozc）と直接入力を切り替える

Ubuntu 26.04 LTSはGNOME 50を採用しており、GNOME-on-X11セッションが廃止され、デスクトップは**Waylandのみ**で動作する点に注意（XWaylandは引き続き利用可能）。これに伴い、`xmodmap` や `setxkbmap` といったX11時代の小技は使えない（XWaylandアプリにしか効かない）ため、GNOME本体の設定や低レイヤなツールを使う必要がある。

## 環境

- Ubuntu 26.04 LTS (Resolute Raccoon)
- GNOME 50 / Wayland セッション
- USキーボード（JISでも考え方は同じ）

# Caps LockとCtrlの入れ替え

## 方法1: GNOME Tweaks（GUI）

一番手軽なGUI手順。Tweaksを入れていない場合は先にインストールする。

```bash
$ sudo apt install gnome-tweaks
```

Tweaksを起動して以下を辿る。

1. 左メニューの「Keyboard」（キーボードとマウス）を開く
2. 「Additional Layout Options」をクリック
3. 「Ctrl position」を展開
4. 「Swap Ctrl and Caps Lock」を選択

設定は即時反映され、再ログインしても保持される。

## 方法2: gsettingsコマンド（CLI / Wayland対応）

Tweaksを入れたくない場合や、dotfilesで管理したい場合は `gsettings` を直接叩く。Waylandでもそのまま効く。

現状確認:

```bash
$ gsettings get org.gnome.desktop.input-sources xkb-options
```

入れ替え:

```bash
$ gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:swapcaps']"
```

代表的なオプション:

| オプション | 動作 |
|---|---|
| `ctrl:swapcaps` | Caps LockとCtrlを入れ替え |
| `ctrl:nocaps` | Caps LockをCtrlに置き換え（Caps Lockは使えなくなる） |
| `caps:ctrl_modifier` | Caps Lockを「もう一つのCtrl」として扱う（Caps Lockも残る） |

元に戻す:

```bash
$ gsettings reset org.gnome.desktop.input-sources xkb-options
```

なお、`gsettings` の値はGNOMEセッションに対する設定なので、コンソール（TTY）には効かない。コンソールでも入れ替えたい場合は `/etc/default/keyboard` の `XKBOPTIONS` に `ctrl:swapcaps` を追加し、`sudo dpkg-reconfigure keyboard-configuration` を実行する。

## 方法3（補足）: keyd によるカーネルレベルの入れ替え

GNOMEに依存せず、ログイン画面・コンソール・任意のWaylandコンポジタで一様に動かしたい場合は [keyd] を使う。`evdev` / `uinput` を経由してカーネルレベルでリマップするため、X11/Waylandを問わず動作する。

```bash
$ sudo apt install keyd
$ sudo systemctl enable --now keyd
```

`/etc/keyd/default.conf` を以下のように作成する。

```ini
[ids]
*

[main]
capslock = control
control = capslock
```

設定を反映:

```bash
$ sudo keyd reload
```

「Caps Lockをホールド時はCtrl、タップ時はEsc」のような複合動作が欲しい場合もkeydで書ける（Vim使いには定番）。

# Ctrl + Space で日本語/英語切り替え

Ubuntu 26.04 では IME フレームワークとして **IBus**（従来のデフォルト）と **fcitx5**（近年推奨されつつある）の二択になる。WaylandやAnki等のElectronアプリとの相性ではfcitx5の方が安定しているケースが多い。

どちらを使うかで設定箇所が変わるので、それぞれ書く。

## 注意: Super + Space との競合

GNOME 50のシステム既定は **Super + Space** で入力ソースを切り替える挙動。Ctrl + Space を IME 側に割り当てる場合、システム側のショートカットを変更する必要はないが、Ctrl + Space を別アプリ（Emacs の `set-mark-command`、tmuxのprefix等）で使っている場合は競合するため要注意。

## パターンA: IBus + Mozc の場合

Ubuntu の伝統的な構成。IBus の「入力ソースの切り替え」ではなく、**Mozc側のキー設定でトグルを定義する**のが素直。理由は、IBusのレイヤだと「直接入力 → Mozc」の片方向しか拾わないことがあり、トグルとして機能させるには Mozc 内のモード遷移を直接書く必要があるため。

1. 画面右上の入力ソースアイコンをクリック → 「ツール」 → 「プロパティ」を開く
2. 「キー設定」の項目で「キー設定の選択」を「カスタム」にし、「編集」をクリック
3. キーマップエディタで「編集」 → 「エントリーを追加」を選び、以下の2エントリを追加する

| モード | キー | コマンド |
|---|---|---|
| 直接入力 | Ctrl + Space | IMEを有効化 |
| 入力文字なし | Ctrl + Space | IMEを無効化 |

ポイントは、IMEを有効化する側のモードを「**入力なし**」ではなく「**直接入力**」にすること（先に紹介した [UbuntuでJISとUSの両キーボードを使う] の記事と同じパターン）。

合わせて、デフォルトで Ctrl + Space に「全角スペースを挿入」が割り当てられているエントリがある場合は削除しておく。重複していると意図しない挙動になる。

設定後はログアウト/ログインで反映。反映が怪しい時は以下で再起動できる。

```bash
$ ibus-daemon -drx
```

## パターンB: fcitx5 + Mozc の場合

fcitx5 はそもそも **デフォルトのトリガキーが Ctrl + Space** だが、Ubuntu 26 + GNOME 50（Wayland）の組み合わせでは「インストールしただけでは動かない」要素が複数ある。順に潰す必要がある。

### B-1. パッケージのインストール（フロントエンド込み）

```bash
$ sudo apt install fcitx5 fcitx5-mozc fcitx5-config-qt \
    fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 \
    fcitx5-frontend-qt5 fcitx5-frontend-qt6 \
    mozc-utils-gui
$ im-config -n fcitx5
```

**フロントエンドパッケージ（gtk3/4, qt5/6）を入れ忘れる**と、fcitx5は起動するけれど対象アプリで Ctrl + Space を押しても無反応、という症状になる。最初は環境変数だけ確認しがちだが、フロントエンドが無いとそもそもアプリ側にIMモジュールが注入されない。

### B-2. `~/.config/fcitx5/profile` に `keyboard-us` と `mozc` を並べる

これが特に分かりにくい。**fcitx5のトリガキーは「IMをon/off」ではなく「グループ内の入力メソッドをトグル」**。グループに `mozc` しか居ないと、Ctrl + Space を押しても見かけ上の挙動が「mozc ⇄ inactive」となり、英語直接入力には戻らないか、fcitx5自体がオフになって入力レイアウト依存になる。

profile の最小例（USキーボード）:

```ini
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=mozc

[Groups/0/Items/0]
Name=keyboard-us

[Groups/0/Items/1]
Name=mozc

[GroupOrder]
0=Default
```

JISキーボードなら `keyboard-us` を `keyboard-jp`、`Default Layout=us` を `Default Layout=jp` に変える。

GUIで入れたい場合は `fcitx5-configtool` を起動 → 左の「Input Method」タブで `Keyboard - English (US)` と `Mozc` を **この順で** リストに登録する。

### B-3. `~/.config/fcitx5/config` の TriggerKeys は **サブセクション形式** で書く

地味だが重大なハマり所。以下は**動かない**書き方:

```ini
# NG: TriggerKeys と 0= が同じ [Hotkey] セクション内
[Hotkey]
TriggerKeys=
0=Control+space
```

正しい書き方は、`Hotkey/TriggerKeys` という独立したサブセクション:

```ini
[Hotkey/TriggerKeys]
0=Control+space

[Hotkey/AltTriggerKeys]
0=Shift_L
```

前者はfcitx5に「TriggerKeysが空のリスト」と解釈され、Ctrl + Space を押しても**沈黙**する。設定後は `fcitx5 -r` で再起動。

### B-4. fcitx5の自動起動を仕込む

Ubuntu 26 + GNOME 50 では、`im-config -n fcitx5` だけでは fcitx5 デーモンはログイン時に起動しない。`/etc/xdg/autostart/` にfcitx5のdesktopファイルが配られるパッケージ構成にもなっていないので、自分で入れる:

```bash
$ mkdir -p ~/.config/autostart
$ cat > ~/.config/autostart/fcitx5.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Fcitx 5
Exec=fcitx5 -d
X-GNOME-Autostart-enabled=true
NoDisplay=false
EOF
```

### B-5. 既存の ibus 系 autostart をユーザ側でマスクする

これも踏みやすい罠。`apt purge ibus-mozc` をしていない場合、`/etc/xdg/autostart/` には `ibus-mozc-gnome-initial-setup.desktop` や `ibus-mozc-launch-xwayland.desktop` などが残り、**毎回ログイン時に ibus-daemon が起動**する。fcitx5と並走して、フォーカスや起動順次第でキー入力を奪い合う。

ユーザ側の `~/.config/autostart/` に同名ファイルを置けば、システム側はシャドウされる。

```bash
$ for f in /etc/xdg/autostart/ibus-*.desktop; do
    name=$(basename "$f")
    cp "$f" ~/.config/autostart/"$name"
    echo 'Hidden=true' >> ~/.config/autostart/"$name"
  done
```

### B-6. GNOME側の入力ソース切替ショートカットを潰す

Ubuntu 26のGNOMEは入力ソースをデフォルトで `Super + Space` に割り当てているが、設定経路によっては `Ctrl + Space` も拾うことがある。さらに `org.gnome.desktop.input-sources sources` に複数登録があると、GNOME自体がキー入力を横取りしてfcitx5に届かなくなる。

```bash
# 入力ソースを単一に固定（fcitx5に任せる）
$ gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us')]"

# WMキーバインドの切替系を空に
$ gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
$ gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
```

### B-7. 反映と確認

ここまでやって**ログアウト/再ログイン**（または再起動）。確認:

```bash
$ env | grep -E 'IM_MODULE|XMODIFIERS'   # fcitx を指しているか
$ pgrep -a fcitx5                         # fcitx5 が起動しているか
$ pgrep -x ibus-daemon                    # 何も出ないことを確認（出るならB-5を見直し）
$ fcitx5-remote -t && fcitx5-remote -n    # CLIでトグル → mozc / keyboard-us
```

もし端末で `env` に出ないが gnome-shell 本体には入っている、というケースもある。これはGUIアプリには効いている状態なので、入力テスト本体（テキストエディタで Ctrl + Space）が成功するならOK。

## 動作確認

テキストエディタや端末で `Ctrl + Space` を叩き、画面右上のIMEインジケータが「あ」と「A」（または相当の表示）で切り替わるかを確認する。切り替わらない場合は、以下を順に確認する。

- システムショートカット（`Settings → Keyboard → View and Customize Shortcuts`）でCtrl+Spaceに別の機能が割り当たっていないか（B-6）
- Mozc側のキー設定が `直接入力` と `入力文字なし` の両方に入っているか（IBusの場合）
- fcitx5の場合は `fcitx5-diagnose` を実行して環境変数（`GTK_IM_MODULE`、`QT_IM_MODULE`、`XMODIFIERS`）が `fcitx` を指しているか
- fcitx5の `~/.config/fcitx5/config` の TriggerKeys が**サブセクション形式**で書かれているか（B-3）
- fcitx5の `~/.config/fcitx5/profile` に `keyboard-*` と `mozc` の**両方**が登録されているか（B-2）

# Ansibleで自動化する

複数台に同じ設定を繰り返し入れる場合は、手元のAnsibleコレクション [ansible-miscs] に2つのroleと1つのplaybookを追加した。

## 追加したrole

### `roles/keyboard_swapcaps_gnome`

CapsとCtrlの入れ替えをUbuntu desktop（GNOME 50 / Wayland）と仮想コンソールの両方に適用する。系統が2層あるため両方を面倒見るのが要点。

- **GUIセッション側**: `/etc/dconf/db/local.d/00-keyboard-swapcaps` をテンプレートで配置し、`dconf update` でシステム全体のGNOMEデフォルトとして反映。ユーザは次回ログイン時から有効
- **コンソール側**: `/etc/default/keyboard` の `XKBOPTIONS` に `ctrl:swapcaps` を入れ、`setupcon --force` を発火

`keyboard_swapcaps_xkb_option` を `ctrl:nocaps` や `caps:ctrl_modifier` に切り替えれば挙動を変えられる。

`gsettings set ...` をユーザDBus越しに叩く方式は、SSH越しのAnsible実行ではセッションが取れないので**意図的に避けた**（dconfシステムoverrideなら無人で確実に効く）。

### `roles/fcitx5_mozc`

`fcitx5` + `fcitx5-mozc` 一式を入れて、`~/.config/fcitx5/config` をテンプレートで上書きし `Control+space` をトリガキーに固定する。`im-config -n fcitx5` をユーザコンテキストで実行し、`/etc/environment` に `GTK_IM_MODULE=fcitx` などを書き込む。

#### 既存IM環境との競合に対する安全弁

Ubuntu標準は伝統的にIBus + ibus-mozcで、ユーザがすでに辞書登録やキーマップカスタマイズをしている可能性が高い。雑にfcitx5に上書きすると **ユーザのIBus側Mozcデータが孤児になる** ため、role冒頭で以下を検出する。

- `im-config -m`（現在の選択）
- `dpkg -l` で既存IMフレームワークの一覧
- `pgrep -x ibus-daemon`

別系統のIMが検出されたら `assert` で**失敗させる**。明示的に `-e fcitx5_mozc_force_switch=true` を渡したときだけ進む。`-e fcitx5_mozc_purge_ibus_mozc=true` を併用するとibus側Mozcもpurgeされる（データ喪失を伴うので別フラグに分離）。

## 追加したplaybook

`playbooks/conf/linux/ubu26_desktop.yml`：

```yaml
- hosts: "{{ server | default('localhost') }}"
  become: yes
  vars:
    fcitx5_mozc_user: "{{ lookup('env', 'SUDO_USER') | default(lookup('env', 'USER'), true) }}"
    fcitx5_mozc_user_home: "/home/{{ fcitx5_mozc_user }}"
  roles:
    - register_home
    - keyboard_swapcaps_gnome
    - fcitx5_mozc
```

実行例:

```bash
$ cd ~/Sources/ansible-miscs
$ ansible-playbook -i hosts playbooks/conf/linux/ubu26_desktop.yml \
    -e server=localhost \
    -K
```

事前検出だけ走らせたい場合（実機を変更しない）:

```bash
$ ansible-playbook -i hosts playbooks/conf/linux/ubu26_desktop.yml \
    -e server=localhost --tags fcitx5_mozc_check -K
```

## 既存roleとの整理

| Role | 用途 | 採用すべきケース |
|---|---|---|
| `keyboard_nocaps`（既存） | `/usr/share/X11/xkb/symbols/{jp,us}` を直接編集してCaps→Ctrl片方向 | Raspberry Pi OSなどX11時代の構成。dist-upgradeで戻る点は注意 |
| `keyboard_swapcaps_gnome`（新規） | dconf override + `/etc/default/keyboard` でCaps↔Ctrl入れ替え | Ubuntu 26.04などGNOME/Wayland desktop |
| `japanese`（既存） | locale設定 + fcitx4 + fcitx-mozc + WSL用GTKスケール | WSL上で日本語が要るケース |
| `fcitx5_mozc`（新規） | fcitx5 + fcitx5-mozc + Ctrl+Spaceトリガ + 既存IM検出 | Ubuntu 26.04 desktopのIME |

# ロールバック

うまく動かなかった場合や、元の構成に戻したい場合の手順。手で当てた設定とAnsibleで当てた設定で復旧の経路が違うので、それぞれ書く。

## Caps↔Ctrl入れ替えを戻す

### 方法1（GNOME Tweaks）で当てた場合

GNOME Tweaks の `Keyboard → Additional Layout Options → Ctrl position` で `Default` に戻す。

### 方法2（gsettings）で当てた場合

```bash
$ gsettings reset org.gnome.desktop.input-sources xkb-options
```

### 方法3（keyd）で当てた場合

```bash
$ sudo systemctl disable --now keyd
$ sudo rm /etc/keyd/default.conf       # 設定ごと消す場合
```

サービスを残したまま個別マシンで一時無効化したいだけなら `disable --now` のみで十分。

### Ansibleで当てた場合（`keyboard_swapcaps_gnome` role）

dconfシステムoverrideと `/etc/default/keyboard` の両方を戻す必要がある。

```bash
# GUIセッション側（dconfシステムoverride）
$ sudo rm /etc/dconf/db/local.d/00-keyboard-swapcaps
$ sudo dconf update

# コンソール側（/etc/default/keyboard）
$ sudo sed -i 's/^XKBOPTIONS=.*/XKBOPTIONS=""/' /etc/default/keyboard
$ sudo setupcon --force
```

各ユーザがログイン中の場合、GNOMEセッションには即時反映されない。一度ログアウト/ログインする。なお、ユーザ側で個別に `gsettings set ... xkb-options "['ctrl:swapcaps']"` を後から叩いている場合はそちらが優先されるので、`gsettings reset` も併せて実行する。

## IME（Ctrl+Space切替）を戻す

### IBus + Mozc を変更した場合

Mozcのプロパティ → キー設定 → 「カスタム」のエントリから、追加した `Ctrl + Space` の2エントリ（直接入力時：IMEを有効化／入力文字なし時：IMEを無効化）を削除する。デフォルトの「全角スペース挿入」を消していた場合は元に戻す。

設定後:

```bash
$ ibus-daemon -drx
```

### fcitx5 を変更した場合

`~/.config/fcitx5/config` の `[Hotkey/TriggerKeys]` を編集して元に戻すか、ファイル自体を消して再起動するとfcitx5デフォルト（Ctrl+Space）に戻る。

```bash
$ rm ~/.config/fcitx5/config
$ fcitx5 -r &     # restart
```

### IBusに完全に戻したい（fcitx5を入れた後）

```bash
$ im-config -n ibus
$ sudo systemctl reboot     # 環境変数の再読込のため再ログイン or 再起動
```

### Ansibleで当てた場合（`fcitx5_mozc` role）

`/etc/environment` への追記をブロックマーカーで囲んでいるので、マーカーごと削除する。

```bash
# /etc/environment に追記したIM環境変数を削除
$ sudo sed -i '/# BEGIN ANSIBLE MANAGED: fcitx5/,/# END ANSIBLE MANAGED: fcitx5/d' /etc/environment

# fcitx5パッケージを完全に外す場合
$ sudo apt purge fcitx5 fcitx5-mozc fcitx5-config-qt mozc-utils-gui
$ sudo apt autoremove

# IBusに戻す
$ im-config -n ibus

# 再ログイン or 再起動
$ systemctl reboot
```

`fcitx5_mozc_purge_ibus_mozc=true` で `ibus-mozc` をpurgeしていた場合、ユーザの個人辞書（`~/.config/mozc/` 以下）はパッケージ削除では消えていないので、再インストール後にそのまま使える。ただしibus-mozcとfcitx5-mozcで個人辞書のパスは共有なので、移行時にデータ重複や上書きが起きていないかは要確認。

## まとめてロールバックしたい場合

Ansibleでまとめて当てた構成を一気に戻すワンライナー的な手順は用意していない（破壊的すぎるため）。上記の「Caps↔Ctrl」と「IME」を順に手で実行する。安全に戻したい場合は、playbook適用前に該当設定ファイルのバックアップを取っておくのが確実。

```bash
$ sudo tar czf ~/keyboard_backup_$(date +%F).tgz \
    /etc/default/keyboard \
    /etc/dconf/db/local.d/ \
    /etc/environment \
    ~/.config/fcitx5/ \
    ~/.config/mozc/ \
    ~/.xinputrc 2>/dev/null
```

# 参考

- [Ubuntu 26.04 LTS release notes]
- [Swap control and caps lock on Wayland Ubuntu 23.04]（`gsettings` の手順。Ubuntu 26でも同様に動く）
- [Remap your Caps Lock key on Linux | Opensource.com]
- [How I use keyd to remap my keyboard in Ubuntu 22.04 with Wayland]
- [Toggling between Japanese input modes in Ubuntu with a non-Japanese keyboard]（Mozcキーマップの編集手順）
- [Fcitx5 - ArchWiki]
- [UbuntuでJISとUSの両キーボードを使う]（過去記事）
- [Raspberry Pi OSでCapslockをCTRLにする]（過去記事、X11時代の手法との比較に）

[Ubuntu 26.04 LTS release notes]: https://documentation.ubuntu.com/release-notes/26.04/
[Swap control and caps lock on Wayland Ubuntu 23.04]: https://gist.github.com/gtello/a4cccae4efaa14c1646396e95f6de549
[Remap your Caps Lock key on Linux | Opensource.com]: https://opensource.com/article/21/5/remap-caps-lock-key-linux
[How I use keyd to remap my keyboard in Ubuntu 22.04 with Wayland]: https://wiki.ethanppl.com/blog/2024/09/08/keyd
[Toggling between Japanese input modes in Ubuntu with a non-Japanese keyboard]: https://datalowe.com/post/ubuntu-japanese-shortcuts/
[Fcitx5 - ArchWiki]: https://wiki.archlinux.org/title/Fcitx5
[UbuntuでJISとUSの両キーボードを使う]: /2018/10/13/Use-US-and-JIS-keyboard-on-Ubuntu/
[Raspberry Pi OSでCapslockをCTRLにする]: /2025/05/18/Raspberry-Pi-OS-Capslock-to-Ctrl/
[keyd]: https://github.com/rvaiya/keyd

<!-- vim: set et tw=0 ts=2 sw=2: -->
