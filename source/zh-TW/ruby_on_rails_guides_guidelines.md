**DO NOT READ THIS FILE IN GITHUB, GUIDES ARE PUBLISHED IN http://rails.ruby.tw.**

Ruby on Rails 指南準則
===============================

本文記錄了撰寫 Ruby on Rails 指南的準則。本文是撰寫指南的範例，遵循本文自身的內容。

讀完本篇，您將了解：

* Rails 文件採用的慣例。
* 如何在本機產生指南。

--------------------------------------------------------------------------------

Markdown
-------

指南以 [GitHub 風格的 Markdown](https://help.github.com/articles/github-flavored-markdown). 寫成。這裡是[淺顯易懂的 Markdown 文件](http://daringfireball.net/projects/markdown/syntax)，一份[速查表](http://daringfireball.net/projects/markdown/basics)。

序幕
--------

每篇指南應由說明動機的內容起頭（藍色區域裡的簡介）。序幕應告訴讀者，這篇指南在講什麼，他們能學到什麼。範例請見 [Rails 路由：深入淺出](routing.html)。

標題
------

每篇指南的標題使用 `h1`，指南小節用 `h2`，子節用 `h3` 等。但產生出的 HTML 會從 `h2` 開始。

```
指南標題
===========

節
-------

### 子節
```

標題所有單字應採大寫，冠詞、介係詞、連接詞、動詞除外。

```
#### Middleware Stack is an Array
#### When are Objects Saved?
```

標題使用與內文相同的排版：

```
##### The `:content_type` Option
```

API 文件準則
----------------------------

指南與 API 應保持一致。請閱讀 [API 文件準則](api_documentation_guidelines.html)來了解更多。

* [用語](api_documentation_guidelines.html#wording)
* [範例程式](api_documentation_guidelines.html#example-code)
* [檔案名稱](api_documentation_guidelines.html#filenames)
* [字體](api_documentation_guidelines.html#fonts)

以上準則同樣適用指南。

HTML 指南
-----------

產生指南之前，先檢查是否安裝了最新版的 Bundler。本文撰寫時，Bundler 的最新版是 1.6.2。

安裝最新版的 Bundler，請執行：`gem install bundler`。

### 產生

要產生所有的指南，`cd` 到 `guides` 目錄，執行 `bundle install`，接著執行：

```
bundle exec rake guides:generate
```

或是

```
bundle exec rake guides:generate:html
```

只產生 `my_guide.md`，請用 `ONLY` 環境變數來指定：

```
touch my_guide.md
bundle exec rake guides:generate ONLY=my_guide
```

預設只會產生有修改過的指南，很少需要用 `ONLY`。

要對所有的指南做處理，請傳 `ALL=1`。

推薦使用 `WARNINGS=1`。這會找出內標裡是否有重複的 ID。

要產生英文之外的指南，可將內容放在 `source` 下的資料夾，譬如 `source/es`，再使用 `GUIDES_LANGUAGE` 環境變數來指定語言：

```
bundle exec rake guides:generate GUIDES_LANGUAGE=es
```

若想知道所有可用的環境變數，執行：

```
bundle exec rake guides:help
```

### 驗證

請驗證產生出的 HTML：

```
bundle exec rake guides:validate
```

特別要提的是，標題會自動由內容產生出 ID，ID 通常會有重複的情況。在產生的時候，加上 `WARNINGS=1` 來找出這個問題。警告內容裡有建議的解決方案。

Kindle 指南
-------------

### 產生

要產生 Kindle 版的指南，使用這個 Rake 任務：

```
bundle exec rake guides:generate:kindle
```
