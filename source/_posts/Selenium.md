---

title: Seleniumを試してみる
date: 2019-10-19 21:51:25
categories:
  - Knowledge Management
  - Tools
  - Selenium
tags:
  - Slenium
  - Python

---

# 参考

* [【超便利】PythonとSeleniumでブラウザを自動操作する方法まとめ]
* [ブラウザのヘッドレスモードでスクショ]
* [【WSL】にFirefox&Google-Chromeをインストールする方法！]
* [geckodriver]
* [geckodriver-v0.26.0-linux64.tar.gz]
* [PythonからSeleniumを使ってFirefoxを操作してみる]
* [selenium_getting_started]
* [PythonでSeleniumを使ってスクレイピング (基礎)]
* [Seleniumで要素を選択する方法まとめ]
* [4. 要素を見つける]
* [Pythonで取得したWebページのHTMLを解析するはじめの一歩]
* [Seleniumで待機処理するお話]

[【超便利】PythonとSeleniumでブラウザを自動操作する方法まとめ]: https://tanuhack.com/selenium/#i-3
[ブラウザのヘッドレスモードでスクショ]: https://ptsv.jp/2019/04/07/ブラウザのヘッドレスモードでスクショ/
[【WSL】にFirefox&Google-Chromeをインストールする方法！]: https://nakomii.hatenablog.com/entry/wsl_ubuntu
[geckodriver]: https://github.com/mozilla/geckodriver/releases
[geckodriver-v0.26.0-linux64.tar.gz]: https://github.com/mozilla/geckodriver/releases/download/v0.26.0/geckodriver-v0.26.0-linux64.tar.gz
[PythonからSeleniumを使ってFirefoxを操作してみる]: https://qiita.com/koikeke0911/items/e9c9516e919875e1cf55
[selenium_getting_started]: https://github.com/dobachi/selenium_getting_started
[PythonでSeleniumを使ってスクレイピング (基礎)]: https://qiita.com/kinpira/items/383b0fbee6bf229ea03d
[Seleniumで要素を選択する方法まとめ]: https://qiita.com/VA_nakatsu/items/0095755dc48ad7e86e2f
[4. 要素を見つける]: https://kurozumi.github.io/selenium-python/locating-elements.html
[Pythonで取得したWebページのHTMLを解析するはじめの一歩]: https://tonari-it.com/python-beautiful-soup-html-parse/
[Seleniumで待機処理するお話]: https://qiita.com/uguisuheiankyo/items/cec03891a86dfda12c9a

# メモ

日常生活の簡単化のために使用。
[【超便利】PythonとSeleniumでブラウザを自動操作する方法まとめ] を試す。

## 環境構築

Condaを使って環境を作り、seleniumをインストールした。
WebDriverは自分の環境に合わせて、Chrome77向けのものを使用したかっただが、
WSLでChromeを使おうとすると、--no-sandboxをつけないと行けないようだ。
詳しくは、 [ブラウザのヘッドレスモードでスクショ] 及び [【WSL】にFirefox&Google-Chromeをインストールする方法！] を参照。

[geckodriver] を使うことにした。

また、当初は [【超便利】PythonとSeleniumでブラウザを自動操作する方法まとめ] を参考にしようとしたが、
途中から [PythonからSeleniumを使ってFirefoxを操作してみる] を参考にした。

動作確認ログは、 [selenium_getting_started] を参照。

## 便利な情報源

### Selenium関連

* [PythonからSeleniumを使ってFirefoxを操作してみる]
  * Firefoxを使ってみる例
* [geckodriver]
  * FirefoxのWebDriverを得る場所
* [【WSL】にFirefox&Google-Chromeをインストールする方法！]
  * WSLにブラウザを導入する例
  * Chromeでの苦労についても触れられている
* [PythonでSeleniumを使ってスクレイピング (基礎)]
  * スクレイピングの面で使いそうな基本機能の説明
* [Seleniumで要素を選択する方法まとめ]
  * 要素選択の基本的な例
  * 汎用性が高いXPathを使う例も記載
* [4. 要素を見つける]
  * 上記のXPathを使う例なども含め、網羅的に記載されている。
* [Seleniumで待機処理するお話]
  * waitする方法

### おまけ

* [Pythonで取得したWebページのHTMLを解析するはじめの一歩]
  * おそらくBeautiful SoupによるHTML解析も伴うことが多いだろう、ということで。

<!-- vim: set tw=0 ts=4 sw=4: -->
