---

title: Automagicaを試してみる
date: 2019-10-22 22:07:48
categories:
  - Knowledge Management
  - Tools
  - Selenium
tags:
  - Automagica
  - RPA
  - Python

---

# 参考

* [Automagicaの公式ドキュメント]
* [AutomagicaのGetting started]
* [Example 1]

[Automagicaの公式ドキュメント]: https://automagica.readthedocs.io/
[AutomagicaのGetting started]: https://automagica.readthedocs.io/#getting-started
[Example 1]: https://automagica.readthedocs.io/#example-1


# メモ

## 総合的感想

用途ごとに個別に開発されているライブラリを統合して使えるのは便利。エントリポイントが統一化され、 `from automagica import *` ですべての機能が使えるのは画期的である。
しかし以下の点は少し課題を感じた。

* ユーザ目線で似たもの同士に感じる機能に関し、APIが異なる
  * 具体的にはWord、Excel操作
  * ただし内部的に用いられるライブラリが別々のものなので致し方ない。（うまくすれば、APIレベルでも統合可能かもしれない）
* 内部的に用いられているライブラリのAPIを直接利用したいケースがあるが少しわかりづらい
  * Automagicaが提供しているAPIよりも、内部的に用いられている元ネタのライブラリのAPIの方が機能豊富（少なくとも `docx` ライブラリはそうだと思う）
  * ということから、まずはAutomagicaのAPIを基本として使用しつつ、必要に応じて内部で用いられているライブラリのAPIを直接利用するのが良さそう。
    実際に `OpenWordDocument` メソッドの戻り値は `docx.Document` クラスのインスタンス。
    しかし1個目の課題と関連するが、その使い方を想起させるドキュメントやAPI仕様に見えない。
    Word activities以外ではどうなのか、は、細かくは未確認。
* ドキュメントにバグがちらほら見られるのと、ドキュメント化されていない機能がある。
  * これは改善されるだろう

## Getting startedを試す

### 環境構築

[AutomagicaのGetting started] を参考にしつつ、動かしてみる。
Anacondaにはパッケージが含まれていなかった（conda-forge含む）のでpipenvを使って環境づくり。

```
> pipenv.exe --python 3.7
> pipenv.exe install jupyter
> pipenv.exe install https://github.com/OakwoodAI/automagica/tarball/master
```

なお、Python3.8系では依存関係上の問題が生じたので、いったん切り分けも兼ねて3.7で環境構築している。
[AutomagicaのGetting started] では、Tesseract4のインストールもオプションとして示されていたが、いったん保留とする。

### Example 1の実行

[Example 1] に載っていた例を動かそうとしたが、一部エラーが生じたので手直しして実行した。

エラー生じた箇所1：

ドキュメント上は、以下のとおり。
```
        lookup_terms.append(ExcelReadCell(excel_path, 2, col))
```

しかし、行と列の番号で指定するAPIは、 `ExcelReadRowCol` である。
また、例に示されていたエクセルでは1行目に検索対象文字列が含まれているため、第2引数は `2` ではなく、 `1` である。
したがって、

```
    lookup_terms.append(ExcelReadRowCol(excel_path, 1, col))
```

とした。
なお、ExcelReadCellメソッド、ExcelReadRowColメソッドの実装は以下の通り。（2019/10/24現在）

automagica/activities.py:639
```
def ExcelReadCell(path, cell="A1", sheet=None):
    '''
    Read a cell from an Excel file and return its value.
    Make sure you enter a valid path e.g. "C:\\Users\\Bob\\Desktop\\RPA Examples\\data.xlsx".
    The cell you want to read needs to be defined by a cell name e.g. "A2". The third variable 
    is a string with the name of the sheet that needs to be read. If omitted, the 
    function reads the entered cell of the active sheet.
    '''
    workbook = load_workbook(path)
    if sheet:
        worksheet = workbook.get_sheet_by_name(sheet)
    else:
        worksheet = workbook.active

    return worksheet[cell].value
```

automagica/activities.py:656
```
def ExcelReadRowCol(path, r=1, c=1, sheet=None):
    '''
    Read a Cell from an Excel file and return its value.
    Make sure you enter a valid path e.g. "C:\\Users\\Bob\\Desktop\\RPA Examples\\data.xlsx".
    The cell you want to read needs to be row and a column. E.g. r = 2 and c = 3 refers to cell C3. 
    The third variable needs to be a string with the name of the sheet that needs to be read. 
    If omitted, the function reads the entered cell of the active sheet. First row is defined 
    row number 1 and first column is defined column number 1.
    '''
    workbook = load_workbook(path)
    if sheet:
        worksheet = workbook.get_sheet_by_name(sheet)
    else:
        worksheet = workbook.active

    return worksheet.cell(row=r, column=c).value
```

エラーが生じた箇所2：

ドキュメント上では、読み込んだ文字列のリストをそのまま使っているが、
そのままではリスト後半に `None` が混ざることがある。
そこで、リストをフィルタするようにした。

```
lookup_terms = list(filter(lambda x: x is not None, lookup_terms))
```

エラーが生じた箇所3：

ドキュメント上では、以下の通り。

```
        ExcelWriteCell(excel_path, row=i+2, col=j+2, write_value=url)
```

これも読み込みの場合と同様にAPIが異なる。合わせて引数名が異なる。そこで、

```
        ExcelWriteRowCol(excel_path, r=i+2, c=j+2, write_value=url)
```

とした。

<!-- vim: set tw=0 ts=4 sw=4: -->
