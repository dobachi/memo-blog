---
title: Corne Chocolate
date: 2019-03-20 23:29:23
categories:
  - Knowledge Management
  - Keyboard
  - Corne Chocolate
tags:
  - Corne Chocolate
  - Keyboard
---

# 参考

* [Corne Chocolateのビルドガイド]

[Corne Chocolateのビルドガイド]: https://github.com/foostan/crkbd/blob/master/corne-chocolate/doc/buildguide_jp.md
[dobachiのキーマップ]: https://github.com/dobachi/qmk_firmware/blob/master/keyboards/crkbd/keymaps/dobachi/keymap.c

# メモ

## ビルドについて

基本的には、 [Corne Chocolateのビルドガイド] の通りで問題なかった。

## キーマップ


もともと使用していたLet's SplitやHelixとは、デフォルトのキー配置が異なる。
イメージとしては、

* Raiseレイヤに記号系が集まっている
* Lowerレイヤに数字やファンクションキーが集まっている
* 矢印キーがない？
* Ctrl、ESC、Tabあたりは好みでカスタマイズ必要そう。
* 親指エンターも好みが分かれそう

という感じ。
個人的な感想として、記号をRaiseレイヤに集めるのは良いと思った。
一方、矢印キー、Ctrlなど、エンターあたりを中心にいじった。

[dobachiのキーマップ] を参照されたし。

## OLED表示

押されたキー1個までならまだしも、入力のログがしばらく表示されるのは気になったので、
`keymap.c`を以下のように修正して表示しないようにした。

```
diff --git a/keyboards/crkbd/keymaps/dobachi/keymap.c b/keyboards/crkbd/keymaps/dobachi/keymap.c
index f80eff9..44a9137 100644
--- a/keyboards/crkbd/keymaps/dobachi/keymap.c
+++ b/keyboards/crkbd/keymaps/dobachi/keymap.c
@@ -158,7 +158,7 @@ void matrix_render_user(struct CharacterMatrix *matrix) {
     // If you want to change the display of OLED, you need to change here
     matrix_write_ln(matrix, read_layer_state());
     matrix_write_ln(matrix, read_keylog());
-    matrix_write_ln(matrix, read_keylogs());
+    //matrix_write_ln(matrix, read_keylogs());
     //matrix_write_ln(matrix, read_mode_icon(keymap_config.swap_lalt_lgui));
     //matrix_write_ln(matrix, read_host_led_state());
     //matrix_write_ln(matrix, read_timelog());
```

