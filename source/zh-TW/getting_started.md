Rails 起步走
==========================

本文將介紹如何使用 Ruby on Rails。

在你讀過這篇之後，應可以學習到：

* 如何安裝 Rails，如何新建立一個 Rails 應用專案，並且如何連接到資料庫。
* Rails 應用專案的一般配置。
* MVC (Model, View, Controller) 跟 RESTful 設計的基本原理。
* 如何快速產生可執行的 Rails 應用程式。

--------------------------------------------------------------------------------

學前所需的知識
-----------------

本文是為了想從頭學 Rails 的初學者所寫，所以不需要具備任何 Rails 的開發經驗。當然如果你想更快上手的話，最好有以下的基礎：

* [Ruby](http://www.ruby-lang.org/en/downloads) 1.9.3 及以上版本。
* [RubyGems](http://rubygems.org) 一個伴隨 Ruby 1.9+ 安裝的套件管理程式。如果想學習更多有關於 RubyGems，請參考 [RubyGems Guides](http://guides.rubygems.org)。
* [SQLite3 資料庫](http://www.sqlite.org)。

Rails 是一個使用 Ruby 開發的 Web 框架。如果沒有 Ruby 相關的經驗就開始學 Rails，你將會發現這是一條陡峭的學習曲線。這裡提供幾個 Ruby 學習的線上資源：

* [Ruby Programming Language 官方網站](https://www.ruby-lang.org/en/documentation/)
* [reSRC 免費程式設計書單](http://resrc.io/list/10/list-of-free-programming-books/#ruby)

值得注意的，有些不錯的線上資源他們是用較常見的 Ruby 1.8 版或較舊的 1.6 版，所以 Rails 現行版本中部份語法是這些線上資源所沒有涵蓋到的。

Rails 是什麼？
--------------

Rails 是一個用 Ruby 所寫的 Web 開發框架。
它把開發過程的細節的都設想周到，讓開發 Web 應用程式變成一件簡單的事情。
與其他程式語言或開發框架比較的話，它可以讓你用更簡短的程式碼來實現相同或更完整的功能。
多數資深的 Rails 開發者認為 Rails 可以使開發 Web 應用程式變的更加有趣。

Rails 是一個有先見之明的軟體。
當事情有最好的處理方法，他的設計會傾向讓你去使用這個方法，而不是花很多時間去找尋跟嘗試。
所以當學完＂The Rails Way＂之後，那你的開發效率將會進展到另一個境界。
但前提是你不能堅持把其他程式語言的開發習慣或思維帶到 Rails 中，否則一開始對 Rails 會有不好的印象。

在 Rails 開發哲學中有著兩個主要的原則：

* **Don't Repeat Yourself(不要重複你自己):** DRY 是一個軟體工程的開發原則，是如此描述
	"Every piece of knowledge must have a single, unambiguous, authoritative
  representation within a system. (系統中每個功能的構思都必須要有單一、明確且讓人認同的表達方式)"
	儘量避免一再重複的相同資訊，所寫的程式才容易維護、有擴展性且不容易出現 bug 。
	
* **Convention Over Configuration(約定優於配置):** Rails 不希望你浪費太多時間無止境的配置設定檔，而是直接把最好的一些 Web 開發方法作為預設，讓你熟悉之後就可以上手了。

建立一個新的 Rails 專案
----------------------------

閱讀這篇教學，過程中最好照著每個步驟走，不要省略任何的程式片段或步驟，一步一步腳踏實地去實作範例程式，最後一定可以完成學習。

一開始我們會建立一個取名為 `blog` 的 Rails 專案，以一個簡易的網誌作為學習範例。不過在這之前，你要先確定是否已經裝了 Rails 。

TIP: 本文的範例中會用 `$` 來表示類 Unix 系統的命令提示字元，但實際上顯示可能因客制化而不同。如果你是 Windows 的使用者，那命令提示字元會類似於 `c:\source_code>` 。

### 安裝 Rails

首先打開命令提示視窗。在 Mac OS X 底下請打開 Terminal.app ，如果是在 Windows 下請在開始功能表選擇＂執行＂並且輸入 'cmd.exe' 後開啟命令視窗。只要是有錢號 `$` 開頭的命令都是要在命令列上執行。現在就用命令檢查是否已安裝最新的 Ruby 版本：

TIP: 其實有很多工具可以幫助你在系統上快速安裝 Ruby 或是 Ruby on Rails 。 像 Windows 使用者可以參考 [Rails Installer](http://railsinstaller.org)，而 Mac OS X 使用者則有 [Tokaido](https://github.com/tokaido/tokaidoapp) 可以選擇。

```bash
$ ruby -v
ruby 2.0.0p353
```

如果還沒安裝 Ruby ，可以看一下
[ruby-lang.org](https://www.ruby-lang.org/en/installation/) ，連結裡會有針對你所用系統的 Ruby 安裝方法。

很多熱門的類 Unix 系統都會搭載 SQLite3 的 acceptable 版本。而 Windows 或其他作業系統的安裝教學請參考 [SQLite3 的網站](http://www.sqlite.org)。
現在來確定是否有正確安裝或正確新增到 Path 環境變數中:

```bash
$ sqlite3 --version
```

SQLite 會在命令列上顯示版本資訊。

接下來使用 RubyGems 提供的命令 `gem install` 來安裝 Rails ：

```bash
$ gem install rails
```

如果不確定 Rails 是否有正確安裝的話，請輸入以下命令做確認：

```bash
$ bin/rails --version
```

如果有看到 "Rails 4.1.1" 的訊息， 那你可以繼續接下來的步驟。

### 建立一個 Blog 應用程式

Rails 中有許多被稱之為產生器（generators）的腳本（scripts），主要用來配置開發所需要的檔案及工具，讓開發可以更加順手。
而現在要用的其中一種產生器就是可以幫助我們建構出一個新的 Rails 應用專案，如此一來就不用再花時間重頭寫起。

要使用產生器之前，請先打開命令提示視窗，切換到有存取權限的目錄接著輸入：

```bash
$ rails new blog
```

執行完後會建立一個名為 `Blog` 的 Rails 應用專案，存放在 blog 目錄下，執行過程中會透過 `bundle install` 命令安裝在 `Gemfile` 上所提到的 gem 相依套件。

TIP: 你可以執行 `rails new -h` 看到所有 Rails 應用專案生成器（Rails application builder）可接受的命令列參數。

建立 blog 專案之後，切換到它的目錄下：

```bash
$ cd blog
```

在 `blog` 這個目錄中有許多自動生成的檔案和資料夾，而這些都是構成 Rails 應用專案的重要元素
本篇教學中大部份會著重在 `app` 這個資料夾，話雖如此，這裡還是附上表格，將所有預設的檔案及資料夾的功能做個簡單介紹：

| 檔案/資料夾 | 用途 |
| ----------- | ------- |
|app/|包含著應用程式的 controllers, models, views, helpers, mailers and assets。 接下來的教學中，你將會花多數的心力在這個資料夾上。|
|bin/|包含許多像是一開始建構應用專案的 rails 腳本（script）以及環境的配置（setup）、應用程式的佈署（deploy）、執行應用程式（run）的其他腳本（scripts）。|
|config/|可以設定應用程式的路由、資料庫、以及其他等等。詳細請參考 [設定 Rails 應用程式](configuring.html)。|
|config.ru|用來啟動應用程式的 Rack 設定檔|
|db/|包含現行資料庫的綱要（schema），方便日後資料庫的移轉。|
|Gemfile<br>Gemfile.lock|這兩個檔案可以指定 Rails application 所要安裝的 gem 相依套件，並且交由 Bundler gem 做管理。 更多關於 Bundler 的資訊請看 [Bundler 的網站](http://bundler.io).|
|lib/|包含應用程式的擴充模組。|
|log/|包含應用程式的log檔案。|
|public/|唯一能再網路上被檢索的目錄，裡面包含著靜態檔案和編譯過後的一些資源（assets）。|
|Rakefile|Rakefile 主要目的是找到並載入可以從命令列執行的任務。其中內建任務的定義是存在各個 Rails 元件當中。若想新增自己寫的任務，不要直接修改 Rakefile，我們傾向把自訂的任務新增到 lib/tasks 目錄下。|
|README.rdoc|這是一份應用程式的操作手冊。你可以編輯這個檔案來告訴別人你的應用程式的功能，以及如何安裝配置等等。|
|test/|包含單元測試、fixtures ( 建立模擬資料 )，還有其他的測試工具。 詳細請參考[測試 Rails 應用程式](testing.html).|
|tmp/|包含一些暫存檔（像是快取、PID、 session 暫存檔）。|
|vendor/|主要放置第三方的程式碼。 通常 Rails 應用專案會在這放置第三方的 gem 套件。|

Hello, Rails!
-------------

一開始，如果希望有個簡單的執行結果。而你必須先啟動 Rails 應用服務來執行。

### 啟動 Web 服務

事實上， Rails 應用專案已經有一個簡單功能。如果想看執行結果，那就必須在開發設備中啟動 web 服務，請在 `blog` 目錄輸入以下的命令：

```bash
$ bin/rails server
```

TIP: 從 CoffeeScript 編譯到 JavaScript 需要一個 JavaScript 直譯器。如果少了直譯器就執行，命令列就會跳出 `execjs` 錯誤。通常 Mac OS X 以及 Windows 都會搭載 JavaScript 直譯器。 如果有需要直譯器，在新增的應用專案中 Rails 會將 `therubyracer` gem 套件註解在 `Gemfile` 中，你只要將他反註解然後就可以安裝了。 `therubyrhino` 是一個 JRuby 使用者推薦的直譯器套件，所以在 JRuby 中是直接把它定義在 `Gemfile` 。
其他有支援的直譯器請參考
[ExecJS](https://github.com/sstephenson/execjs#readme).

這將會啟動 WEBrick，一個 Ruby 預設的 web 伺服器。接下來要如何看執行中的應用程式，請打開瀏覽器並在網址列上輸入 <http://localhost:3000> 。你就會看到 Rails 的預設資訊頁面。

![Welcome aboard screenshot](images/getting_started/rails_welcome.png)

TIP: 如想停止 web 服務，請在已執行中的命令視窗按下 Ctrl+C 跳回命令提示字元就可以終止服務。
大多數類 UNIX 系統，其中也包含 Mac OS X 會再次看到錢符 `$`。在開發模式中, Rails 通常是不會要求你重新起動服務；只要有修改過的檔案伺服器就會自動重新載入。

＂Welcome aboard＂這個頁面對於新建 Rails 應用程式來說是一個_煙霧測試（smoke test）_：測試設定上是否正確，來讓此頁面正確執行。你也可以透過點擊 _About your application's environment_ 連結來看應用程式環境相關資訊的摘要。

### Rails 說 "Hello" 

為了讓 Rails 可以顯示 "Hello"，你必須建立一個簡單的 _controller_ 跟 _view_。

Controller 的功能是去接收對於應用程式的 Http 請求。而 _Routing_ 則是決定由那一個 controller 去接收請求，通常一個 controller 會有一個以上的 route 的規則對應，藉由不同的 actions 來處理這些不同的 routes 所決定的請求 。Action 的功能就是收集資訊並提供給 view 使用。

View 的功能是將資訊用常人可讀的方式呈現出來。 View 跟 controller 最大的差別就是 controller 負責資訊的收集，而 view 只是負責資訊的呈現。預設的 view 模版是用 eRuby （Embedded Ruby）所寫的，這部份要在所有結果送到使用者之前才會被 Rails 中 request cycle （從 route 到 view 的一系列請求）執行到。

要建立一個 controller ，你將必須執行 controller 的產生器，並且附上 controller 名稱以及 action 名稱的參數，就像這樣子：

```bash
$ bin/rails generate controller welcome index
```

Rails 會幫你建立幾個檔案和一個 route 。

```bash
create  app/controllers/welcome_controller.rb
 route  get 'welcome/index'
invoke  erb
create    app/views/welcome
create    app/views/welcome/index.html.erb
invoke  test_unit
create    test/controllers/welcome_controller_test.rb
invoke  helper
create    app/helpers/welcome_helper.rb
invoke    test_unit
create      test/helpers/welcome_helper_test.rb
invoke  assets
invoke    coffee
create      app/assets/javascripts/welcome.js.coffee
invoke    scss
create      app/assets/stylesheets/welcome.css.scss
```

在這些檔案中最重要的當然是位於 `app/controllers/welcome_controller.rb` 的 controller 以及位於 `app/views/welcome/index.html.erb` 的 view 。

接下來用文字編輯器打開 `app/views/welcome/index.html.erb` ，並且將檔案所有內容替換成以下的程式碼：

```html
<h1>Hello, Rails!</h1>
```

### 設置應用程式首頁

現在我們已經完成了 controller 和 view ，再來就是決定什麼時候讓 Rails 執行顯示 "Hello, Rails!" 。這個例子中，我們想在連結應用程式首頁 <http://localhost:3000> 時來顯示這段訊息。不過目前畫面依舊是 "Welcome aboard" 。

所以接下來，我們要告訴 Rails 正確首頁的所在位置。

首先用文字編輯器打開 `config/routes.rb` 。

```ruby
Rails.application.routes.draw do
  get 'welcome/index'

  # The priority is based upon order of creation:
  # first created -> highest priority.
  #
  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  #
  # ...
```

這個是應用程式的 _routing file（路由檔案）_ ，內容是用特殊的 DSL (domain-specific language 專屬領域語言) 所寫的，透過這些設定，可以告訴 Rails 要如何將連進來的要求連結到 controllers 和 actions 。這個檔案包含許多已註解的 routes 規則範例，其中有一條規則是把連到網站根目錄的請求對應到特定的 controller 和 action 做處理。我們從開頭為 `root` 找到這條規則，並且反註解它，看起來會像這樣：

```ruby
root 'welcome#index'
```

這一行 `root 'welcome#index'` 是告訴 Rails 把連應用程式根目錄的請求對應到 welcome controller 的 index action 作處理。而另一行 `get 'welcome/index'` 則是告訴 Rails 把連 <http://localhost:3000/welcome/index> 的請求對應到 welcome controller 的 index action 作處理。當你執行過 controller 產生器 (`rails generate controller welcome index`) 這些設定都會被新增在檔案中。

剛剛如果你為了要執行產生器而關掉 web 伺服器，那就再次啟動它 (`rails server`) 。並且用瀏覽器連上 <http://localhost:3000> 。 你將會看到那些被你放在 `app/views/welcome/index.html.erb` 的 "Hello, Rails!" 訊息，這說明了這個新的 route 將這個請求交給 `WelcomeController` 的 `index` action 處理了，並且透過 view 把正確結果顯示出來。

TIP: 更多關於 routing 資訊，請參考 [Rails Routing from the Outside In](routing.html).

開始實作
----------------------

現在你已經知道如何建立 controller 、 action 還有 view, 接下來讓我們一起建立更實質的一些功能。

在這 Blog 應用程式中, 你將需要創造新的 _resource_. Resource 是一個類似物件的集合, 就像 articles, people 或是
animals.
對於resource的項目你可以 create建立, read讀取, update更新 and destroy刪除 而這些操作可以被簡稱為 _CRUD_ 操作.

Rails 提供一個 `resources` 方法 這個方法可以用來宣告一個標準的 REST
resource. 這裡將示範如何在 `config/routes.rb` 宣告一個 _article resource_.

```ruby
Rails.application.routes.draw do

  resources :articles

  root 'welcome#index'
end
```

如果你執行 `rake routes`, 你將會看到他對於標準的 RESTful actions 已經定義了許多 routes.  至於prefix 欄 (還有其他欄位) 的意思我們晚點再提, 但要注意到 Rails 已經對於單數型態的 `article` 有特別的解釋並且對於複數型別有意義上的區別.

```bash
$ bin/rake routes
      Prefix Verb   URI Pattern                  Controller#Action
    articles GET    /articles(.:format)          articles#index
             POST   /articles(.:format)          articles#create
 new_article GET    /articles/new(.:format)      articles#new
edit_article GET    /articles/:id/edit(.:format) articles#edit
     article GET    /articles/:id(.:format)      articles#show
             PATCH  /articles/:id(.:format)      articles#update
             PUT    /articles/:id(.:format)      articles#update
             DELETE /articles/:id(.:format)      articles#destroy
        root GET    /                            welcome#index
```

在下一個段落, 你將可以在你的應用程式新增文章並且檢視它. 這就是 CRUD 中的 "C" 跟 "R":
creation(建立) and reading(檢視). 而新增文章的表單將會長的像如此:

![The new article form](images/getting_started/new_article.png)

雖然現在看起來有些簡單，但是還可以使用. 之後如有需要再來回頭檢視樣式設計的改善.

### 建立基本功能

一開始, 在應用程式中需要一個頁面來建立新增的文章. 有一個不錯的選擇就是在 `/articles/new`. 由於應用程式已經定義了 route， 所以可以向 `/articles/new` 發送請求.
連到 <http://localhost:3000/articles/new> 你將會看到一個 routing
錯誤:

![Another routing error, uninitialized constant ArticlesController](images/getting_started/routing_error_no_controller.png)

這個錯誤會發生是因為這個route規則需要定義一個 controller 來處理請求，所以這個問題的解決方法很簡單：建立一個名為`Articlescontroller` 的 controller，你可以透過執行以下命令來完成動作。 

```bash
$ bin/rails g controller articles
```

如果你打開剛產生的 `app/controllers/articles_controller.rb`
你會看到一個還未有內容的controller:

```ruby
class ArticlesController < ApplicationController
end
```

這個 controller 是繼承於 `ApplicationController` 的一個簡單類別.
在這個類別中你必須定義 method 來做 controller 的 action. 在 blog 系統中這些 actions 將可以完成對於 articles 的 CRUD 操作.

NOTE: 在 ruby 中有這幾種 `public`, `private`, `protected` methods,
但只有 `public` methods 才能當 controllers 的 actions.
更多詳細資訊請參考 [Programming Ruby](http://www.ruby-doc.org/docs/ProgrammingRuby/).

如果現在你重新整理這個頁面 <http://localhost:3000/articles/new> , 你將又得到一個新的錯誤:

![Unknown action new for ArticlesController!](images/getting_started/unknown_action_new_for_articles.png)

這個錯誤指出 Rails 找不到剛剛產生的 `ArticlesController` 中有 `new` action
. 這是因為當 controllers 被產生在 Rails 中的時候，他們內容預設都是空的, 除非在產生controller的時候就要指定什麼名稱的 actions.

想在 controller 中手動定義一個 action, 你只要在 controller 中新增一個 method. 打開
`app/controllers/articles_controller.rb` 並且在 `ArticlesController`
類別裡面新增一個 `new` method 如此一來 controller 現在會長的像如此:

```ruby
class ArticlesController < ApplicationController
  def new
  end
end
```

由於在 `ArticlesController` 中定義了 `new` method, 如果你此時重新整理頁面
<http://localhost:3000/articles/new> 你將會看到另外一個錯誤:

![Template is missing for articles/new]
(images/getting_started/template_is_missing_articles_new.png)

你現在會得到這個錯誤是因為 Rails 希望空白的 actions 能夠跟 views 連結來展示 actions 所要呈現的資訊. 由於沒有可用的 view, Rails 則出現錯誤.

在上面圖片中的最後一行剛好被截掉. 我們一起看看完整的訊息:

<blockquote>
Missing template articles/new, application/new with {locale:[:en], formats:[:html], handlers:[:erb, :builder, :coffee]}. Searched in: * "/path/to/blog/app/views"
</blockquote>

還滿長的一段文字! 我們一起快速瀏覽並且了解每個部份的用意.

第一個部份我們可以找出缺少了什麼 template. 再這個例子中, 我們缺少的就是
`articles/new` template. Rails 一開始會試著找這個 template. 如果找不到他才會嘗試載入一個名為 `application/new` 的 template. 這是因為 `ArticlesController` 是繼承於 `ApplicationController`的關係.

下一個部份包含了一個 hash. 再這個 hash，其中 `:locale` key
簡單的指出要使用什麼國際語言的 template. 而預設是使用簡稱 "en" 的英文 template. 而下一個 key, `:formats` 是指 template 在 回覆的處理上要使用什麼格式. 預設的格式是 `:html`, 所以這邊 Rails 是在尋找一個 HTML template. 最後一個 key, `:handlers` 是告訴我們要使用什麼 _template handlers_ 來將我們的 template 編譯並把結果顯示出來. 對於 HTML templates 我們通常會使用 `:erb`,  而對於 XML templates 我們會選擇使用 `:builder`, 然而
`:coffee` 是使用 CoffeeScript 來編譯 JavaScript templates.

這段文字的最後一個部份是告訴我們 Rails 是在哪個地方尋找 templates.
Templates 在像這個簡單的 Rails 應用專案中通常會放在單一個地方, 但是比較複雜的應用專案可能會有好幾種不同的路徑.

再這個例子中位於 `app/views/articles/new.html.erb` 的簡單 template 將會執行. 然而檔案的副檔名則有特殊意義: 第一個副檔名是表示 template 的_format_, 而第二個則是表示使用什麼
_handler_ . Rails 試著在應用程式的 `app/views` 中找到一個名為`articles/new` 的 template. 
而這個 template 的 format 只能是 `html` ，不過它的 handler 只要是 `erb`, `builder` 或是 `coffee` 的其中之一就行. 但因為你想新增一個 HTML 表單, 所以你一定要用 `ERB` 語言. 因此這個檔案的名稱應該為 `articles/new.html.erb` 並且須位於應用專案的 `app/views` 目錄中.

前往該目錄然後新增此檔案 `app/views/articles/new.html.erb` 並且寫上以下內容:

```html
<h1>New Article</h1>
```

當你重新整理此頁面 <http://localhost:3000/articles/new> 你將會看到標題. 這也表示 route, controller, action 跟 view 運作的十分順利! 現來就來新增建立 article的表單.

### 開始第一個表單

想要在這個 template 中建立一個表單, 你會使用到一個 <em>form
builder</em>. 這個基本的 form builder 是由 Rails 中的 helper method 所提供，叫作 `form_for` . 
想使用這個 method 的話, 先將以下程式碼新增到 `app/views/articles/new.html.erb`:

```html+erb
<%= form_for :article do |f| %>
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>

  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <p>
    <%= f.submit %>
  </p>
<% end %>
```

如果你現在重新整理頁面, 你就會看到跟範例相同的表單了.
在rails中建立表單就是如此簡單!

當你呼叫了 `form_for`, 你必須傳遞一個 identifying object 給這個表單. 
再這個例子中, 是用symbol表示 `:article`. 這樣可以告訴 `form_for`
helper 這個表單的用途. 在這個 method 的程式區塊中，有個用 `f` 表示的 `FormBuilder` object
他是被用來建立兩個文字標籤以及兩個文字方塊, 其中兩個文字方塊一個是做為文章的標題另一個是作為文章內文. 
最後再 `f` object 上呼叫一個 `submit`，如此一來就可以再這個表單上建立一個submit按鈕.

不過這個表單仍然會有一個問題. 如果你檢視這個頁面的 HTML 原始碼, 你將會看到一個form的屬性`action`
是指向 `/articles/new`. 這會是一個問題因為route導向的頁面正是現在所在的頁面, 
而且那個route單純是用來顯示新增文章的表單而已.

這個表單而是需要一個到不同目的地的URL.
然而這其實只是簡單新增 `form_for` 的選項 `:url` 就可以完成.
通常在 Rails, action 是用來處理表單送出的資料
像這邊的動作就是 "create", 所以表單就會將資料送到create動作處理.

現在就來編輯 `app/views/articles/new.html.erb` 中的 `form_for` 那行，結果應該會像這樣:

```html+erb
<%= form_for :article, url: articles_path do |f| %>
```

再這個範例中，是將 `articles_path` helper 代入`:url` 選項中.
為了知道 Rails 將如何運行這個選項, 我們再次看 `rake routes` 的輸出結果:

```bash
$ bin/rake routes
      Prefix Verb   URI Pattern                  Controller#Action
    articles GET    /articles(.:format)          articles#index
             POST   /articles(.:format)          articles#create
 new_article GET    /articles/new(.:format)      articles#new
edit_article GET    /articles/:id/edit(.:format) articles#edit
     article GET    /articles/:id(.:format)      articles#show
             PATCH  /articles/:id(.:format)      articles#update
             PUT    /articles/:id(.:format)      articles#update
             DELETE /articles/:id(.:format)      articles#destroy
        root GET    /                            welcome#index
```

`articles_path` helper 會提示 Rails 將 form 指向 Prefix 為 `articles` 的 URI Pattern;
再加上form預設是送`POST` 請求到 route ，如此一來將會對應到目前 controller `ArticlesController` 的 `create` action

有了表單和已經定義好的 route , 你將能夠開始填表單而且還可以按下送出開始建立新文章的程序, 所以就這樣繼續. 當你送出了表單時, 你會看到一個熟悉的錯誤:

![Unknown action create for ArticlesController]
(images/getting_started/unknown_action_create_for_articles.png)

你現在必須要在 `ArticlesController` 建立一個 `create` action 來讓程式正常執行.

### 新增文章

如果想讓 "Unknown action" 錯誤消失的話, 你可以先打開 `app/controllers/articles_controller.rb` 並且在 `ArticlesController` 類別中的 `new` action 下定義一個 `create` action，如下所示：

```ruby
class ArticlesController < ApplicationController
  def new
  end

  def create
  end
end
```

如果你現在又再次送出表單, 你會看定另一個熟悉的錯誤: a template is
missing. 不過沒關係, 我們可以暫且忽略他. `create` action 所要做的是將我們新增的文章存進資料庫中.

當表單被送出時, 表單的欄位值會被當作 _parameters_ 送給 Rails . 所以這些 parameters 可以在controller 的 actions 中被使用, 通常是用來執行特定的 task . 現在來看看這些 parameters 長什麼樣子，把 `create` action 替換如下:

```ruby
def create
  render plain: params[:article].inspect
end
```

這裡的 `render` method 的設定是用 key 為 `plain` 以及 value 為 `params[:article].inspect` 的簡單 hash. 
而 `params` method 則是一種物件，它代表的是透過表單送出的 parameters (或欄位值) . 
這個 `params` method 所回傳是一種類型為 `ActiveSupport::HashWithIndifferentAccess` 的物件, 而這種物件可以讓你使用字串或symbols 表示的key 來得到hash中所相對應的值. 
目前狀況下, 我們只在乎從表單送出的 parameters.

TIP: 你要確定是否掌握了 `params` method 的用法, 因為以後會滿常用到它的. 現在來一起思考這個範例網址: **http://www.example.com/?username=dhh&email=dhh@email.com**. 在這網址中， `params[:username]` 的值應該會是 "dhh" 而 `params[:email]` 的值也應該會是 "dhh@email.com".

If you re-submit the form one more time you'll now no longer get the missing
template error. Instead, you'll see something that looks like the following:
如果你再次重送這個表單，你將不會再看到 the missing template 錯誤。而是看到如下的訊息：

```ruby
{"title"=>"First article!", "text"=>"This is my first article."}
```

這個 action 把透過表單送出的 parameters 顯示出來. 
然而，這並沒有什麼實質的用處. 是的, 你除了觀看 parameters 之外沒有其他作用.

### 建立 Article 模型

對於Rails 中的模型，我們習慣用單數來命名, 而且所對應的資料庫表格，我們習慣用複數來命名 
Rails 提供一個開發者喜歡用來創造模型的generator.
想要創造模型的話，請執行以下的命令:

```bash
$ bin/rails generate model Article title:string text:text
```

透過這個命令我們告訴 Rails 我們要一個連同型別為string的 _title_ 屬性, and 型別為text的 _text_ 屬性的`Article`模型
這些屬性會自動的新增到資料庫的 `articles` 表格中並且對應到 `Article` 模型.

執行完後 Rails 會建立一長串的檔案. 現在我們有興趣的是 `app/models/article.rb` 以及 `db/migrate/20140120191729_create_articles.rb` (檔名可能略有不同). 後面那個檔案是負責建立資料庫的結構, 這部份是我們下一步所要了解的.

TIP: Active Record 可以很聰明的將欄位名稱對應到模型的屬性, 這意思是說你不用再Rails模型中宣告屬性, 因為 Active Record 會自動處理好這部份.

### 執行一個 Migration

就如同我們所看到的, 執行 `rails generate model` 會在 `db/migrate` 的目錄中建立一個 _database migration_ 的檔案. 
Migrations 是Ruby 的一種類別 這些被設計來讓建立或修改資料庫中的表格能夠更容易.
Rails 使用 rake 命令來執行 migrations, 而且即使資料庫已經套用設定但還是可以回復migration 動作.
Migration 的檔名中包含著時間戳記，如此可以確保按造檔案建立的順序來執行.

如果你打開這個檔案`db/migrate/20140120191729_create_articles.rb` (還記得檔案名稱會有些許不同), 而你會看到:

```ruby
class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title
      t.text :text

      t.timestamps
    end
  end
end
```

再上面的 migration 建立了一個名為 `change` 的method ，當執行 這個 migration的時候會呼叫到這個method. 
再這個 method 中定義的 action 都是可逆的
這意思是 Rails 知道如何回復這個 migration 所做的更動,
以免有一天你想回復它. 當你執行這個 migration 他將會建立一個 `articles` 表格 其中包含著string型態的欄位以及text型態的欄位. 
他也建立了兩個時間戳記的欄位來讓Rails可以紀錄article建立以及更新的時間

TIP: 更多關於 migrations 的資訊, 請參考 [Rails Database Migrations]
(migrations.html).

此時, 你可以使用 rake 命令來執行 migration:

```bash
$ bin/rake db:migrate
```

Rails 將會執行這個 migration 的命令 並且顯示建立 Articles 資料表的訊息.

```bash
==  CreateArticles: migrating ==================================================
-- create_table(:articles)
   -> 0.0019s
==  CreateArticles: migrated (0.0020s) =========================================
```

NOTE. 由於你目前的所有操作都在名為development的預設環境下,
這個命令會將定義在`config/database.yml` 中的 `development` 設定區塊套用到資料庫上 
如果你想再其他環境執行 migrations, 像是 production, 你就可以明確的名稱代入到下達的命令: `rake db:migrate RAILS_ENV=production`.

### Saving data in the controller

Back in `ArticlesController`, we need to change the `create` action
to use the new `Article` model to save the data in the database.
Open `app/controllers/articles_controller.rb` and change the `create` action to
look like this:

```ruby
def create
  @article = Article.new(params[:article])

  @article.save
  redirect_to @article
end
```

Here's what's going on: every Rails model can be initialized with its
respective attributes, which are automatically mapped to the respective
database columns. In the first line we do just that (remember that
`params[:article]` contains the attributes we're interested in). Then,
`@article.save` is responsible for saving the model in the database. Finally,
we redirect the user to the `show` action, which we'll define later.

TIP: You might be wondering why the `A` in `Article.new` is capitalized above, whereas most other references to articles in this guide have used lowercase. In this context, we are referring to the class named `Article` that is defined in `\models\article.rb`. Class names in Ruby must begin with a capital letter.

TIP: As we'll see later, `@article.save` returns a boolean indicating whether
the article was saved or not.

If you now go to <http://localhost:3000/articles/new> you'll *almost* be able
to create an article. Try it! You should get an error that looks like this:

![Forbidden attributes for new article]
(images/getting_started/forbidden_attributes_for_new_article.png)

Rails has several security features that help you write secure applications,
and you're running into one of them now. This one is called `[strong_parameters]
(http://guides.rubyonrails.org/action_controller_overview.html#strong-parameters)`,
which requires us to tell Rails exactly which parameters are allowed into our
controller actions.

Why do you have to bother? The ability to grab and automatically assign all
controller parameters to your model in one shot makes the programmer's job
easier, but this convenience also allows malicious use. What if a request to
the server was crafted to look like a new article form submit but also included
extra fields with values that violated your applications integrity? They would
be 'mass assigned' into your model and then into the database along with the
good stuff - potentially breaking your application or worse.

We have to whitelist our controller parameters to prevent wrongful mass
assignment. In this case, we want to both allow and require the `title` and
`text` parameters for valid use of `create`. The syntax for this introduces
`require` and `permit`. The change will involve one line in the `create` action:

```ruby
  @article = Article.new(params.require(:article).permit(:title, :text))
```

This is often factored out into its own method so it can be reused by multiple
actions in the same controller, for example `create` and `update`. Above and
beyond mass assignment issues, the method is often made `private` to make sure
it can't be called outside its intended context. Here is the result:

```ruby
def create
  @article = Article.new(article_params)

  @article.save
  redirect_to @article
end

private
  def article_params
    params.require(:article).permit(:title, :text)
  end
```

TIP: For more information, refer to the reference above and
[this blog article about Strong Parameters]
(http://weblog.rubyonrails.org/2012/3/21/strong-parameters/).

### Showing Articles

If you submit the form again now, Rails will complain about not finding the
`show` action. That's not very useful though, so let's add the `show` action
before proceeding.

As we have seen in the output of `rake routes`, the route for `show` action is
as follows:

```
article GET    /articles/:id(.:format)      articles#show
```

The special syntax `:id` tells rails that this route expects an `:id`
parameter, which in our case will be the id of the article.

As we did before, we need to add the `show` action in
`app/controllers/articles_controller.rb` and its respective view.

NOTE: A frequent practice is to place the standard CRUD actions in each
controller in the following order: `index`, `show`, `new`, `edit`, `create`, `update`
and `destroy`. You may use any order you choose, but keep in mind that these
are public methods; as mentioned earlier in this guide, they must be placed
before any private or protected method in the controller in order to work.

Given that, let's add the `show` action, as follows:

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
  end

  def new
  end

  # snipped for brevity
```

A couple of things to note. We use `Article.find` to find the article we're
interested in, passing in `params[:id]` to get the `:id` parameter from the
request. We also use an instance variable (prefixed by `@`) to hold a
reference to the article object. We do this because Rails will pass all instance
variables to the view.

Now, create a new file `app/views/articles/show.html.erb` with the following
content:

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>
```

With this change, you should finally be able to create new articles.
Visit <http://localhost:3000/articles/new> and give it a try!

![Show action for articles](images/getting_started/show_action_for_articles.png)

### Listing all articles

We still need a way to list all our articles, so let's do that.
The route for this as per output of `rake routes` is:

```
articles GET    /articles(.:format)          articles#index
```

Add the corresponding `index` action for that route inside the
`ArticlesController` in the `app/controllers/articles_controller.rb` file.
When we write an `index` action, the usual practice is to place it as the
first method in the controller. Let's do it:

```ruby
class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    @article = Article.find(params[:id])
  end

  def new
  end

  # snipped for brevity
```

And then finally, add the view for this action, located at
`app/views/articles/index.html.erb`:

```html+erb
<h1>Listing articles</h1>

<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
  </tr>

  <% @articles.each do |article| %>
    <tr>
      <td><%= article.title %></td>
      <td><%= article.text %></td>
    </tr>
  <% end %>
</table>
```

Now if you go to `http://localhost:3000/articles` you will see a list of all the
articles that you have created.

### Adding links

You can now create, show, and list articles. Now let's add some links to
navigate through pages.

Open `app/views/welcome/index.html.erb` and modify it as follows:

```html+erb
<h1>Hello, Rails!</h1>
<%= link_to 'My Blog', controller: 'articles' %>
```

The `link_to` method is one of Rails' built-in view helpers. It creates a
hyperlink based on text to display and where to go - in this case, to the path
for articles.

Let's add links to the other views as well, starting with adding this
"New Article" link to `app/views/articles/index.html.erb`, placing it above the
`<table>` tag:

```erb
<%= link_to 'New article', new_article_path %>
```

This link will allow you to bring up the form that lets you create a new article.

Now, add another link in `app/views/articles/new.html.erb`, underneath the
form, to go back to the `index` action:

```erb
<%= form_for :article, url: articles_path do |f| %>
  ...
<% end %>

<%= link_to 'Back', articles_path %>
```

Finally, add a link to the `app/views/articles/show.html.erb` template to
go back to the `index` action as well, so that people who are viewing a single
article can go back and view the whole list again:

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<%= link_to 'Back', articles_path %>
```

TIP: If you want to link to an action in the same controller, you don't need to
specify the `:controller` option, as Rails will use the current controller by
default.

TIP: In development mode (which is what you're working in by default), Rails
reloads your application with every browser request, so there's no need to stop
and restart the web server when a change is made.

### Adding Some Validation

The model file, `app/models/article.rb` is about as simple as it can get:

```ruby
class Article < ActiveRecord::Base
end
```

There isn't much to this file - but note that the `Article` class inherits from
`ActiveRecord::Base`. Active Record supplies a great deal of functionality to
your Rails models for free, including basic database CRUD (Create, Read, Update,
Destroy) operations, data validation, as well as sophisticated search support
and the ability to relate multiple models to one another.

Rails includes methods to help you validate the data that you send to models.
Open the `app/models/article.rb` file and edit it:

```ruby
class Article < ActiveRecord::Base
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

These changes will ensure that all articles have a title that is at least five
characters long. Rails can validate a variety of conditions in a model,
including the presence or uniqueness of columns, their format, and the
existence of associated objects. Validations are covered in detail in [Active
Record Validations](active_record_validations.html).

With the validation now in place, when you call `@article.save` on an invalid
article, it will return `false`. If you open
`app/controllers/articles_controller.rb` again, you'll notice that we don't
check the result of calling `@article.save` inside the `create` action.
If `@article.save` fails in this situation, we need to show the form back to the
user. To do this, change the `new` and `create` actions inside
`app/controllers/articles_controller.rb` to these:

```ruby
def new
  @article = Article.new
end

def create
  @article = Article.new(article_params)

  if @article.save
    redirect_to @article
  else
    render 'new'
  end
end

private
  def article_params
    params.require(:article).permit(:title, :text)
  end
```

The `new` action is now creating a new instance variable called `@article`, and
you'll see why that is in just a few moments.

Notice that inside the `create` action we use `render` instead of `redirect_to`
when `save` returns `false`. The `render` method is used so that the `@article`
object is passed back to the `new` template when it is rendered. This rendering
is done within the same request as the form submission, whereas the
`redirect_to` will tell the browser to issue another request.

If you reload
<http://localhost:3000/articles/new> and
try to save an article without a title, Rails will send you back to the
form, but that's not very useful. You need to tell the user that
something went wrong. To do that, you'll modify
`app/views/articles/new.html.erb` to check for error messages:

```html+erb
<%= form_for :article, url: articles_path do |f| %>

  <% if @article.errors.any? %>
    <div id="error_explanation">
      <h2>
        <%= pluralize(@article.errors.count, "error") %> prohibited
        this article from being saved:
      </h2>
      <ul>
        <% @article.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>

  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <p>
    <%= f.submit %>
  </p>

<% end %>

<%= link_to 'Back', articles_path %>
```

A few things are going on. We check if there are any errors with
`@article.errors.any?`, and in that case we show a list of all
errors with `@article.errors.full_messages`.

`pluralize` is a rails helper that takes a number and a string as its
arguments. If the number is greater than one, the string will be automatically
pluralized.

The reason why we added `@article = Article.new` in the `ArticlesController` is
that otherwise `@article` would be `nil` in our view, and calling
`@article.errors.any?` would throw an error.

TIP: Rails automatically wraps fields that contain an error with a div
with class `field_with_errors`. You can define a css rule to make them
standout.

Now you'll get a nice error message when saving an article without title when
you attempt to do just that on the new article form
[(http://localhost:3000/articles/new)](http://localhost:3000/articles/new).

![Form With Errors](images/getting_started/form_with_errors.png)

### Updating Articles

We've covered the "CR" part of CRUD. Now let's focus on the "U" part, updating
articles.

The first step we'll take is adding an `edit` action to the `ArticlesController`,
generally between the `new` and `create` actions, as shown:

```ruby
def new
  @article = Article.new
end

def edit
  @article = Article.find(params[:id])
end

def create
  @article = Article.new(article_params)

  if @article.save
    redirect_to @article
  else
    render 'new'
  end
end
```

The view will contain a form similar to the one we used when creating
new articles. Create a file called `app/views/articles/edit.html.erb` and make
it look as follows:

```html+erb
<h1>Editing article</h1>

<%= form_for :article, url: article_path(@article), method: :patch do |f| %>

  <% if @article.errors.any? %>
    <div id="error_explanation">
      <h2>
        <%= pluralize(@article.errors.count, "error") %> prohibited
        this article from being saved:
      </h2>
      <ul>
        <% @article.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>

  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <p>
    <%= f.submit %>
  </p>

<% end %>

<%= link_to 'Back', articles_path %>
```

This time we point the form to the `update` action, which is not defined yet
but will be very soon.

The `method: :patch` option tells Rails that we want this form to be submitted
via the `PATCH` HTTP method which is the HTTP method you're expected to use to
**update** resources according to the REST protocol.

The first parameter of `form_for` can be an object, say, `@article` which would
cause the helper to fill in the form with the fields of the object. Passing in a
symbol (`:article`) with the same name as the instance variable (`@article`)
also automagically leads to the same behavior. This is what is happening here.
More details can be found in [form_for documentation]
(http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for).

Next, we need to create the `update` action in
`app/controllers/articles_controller.rb`.
Add it between the `create` action and the `private` method:

```ruby
def create
  @article = Article.new(article_params)

  if @article.save
    redirect_to @article
  else
    render 'new'
  end
end

def update
  @article = Article.find(params[:id])

  if @article.update(article_params)
    redirect_to @article
  else
    render 'edit'
  end
end

private
  def article_params
    params.require(:article).permit(:title, :text)
  end
```

The new method, `update`, is used when you want to update a record
that already exists, and it accepts a hash containing the attributes
that you want to update. As before, if there was an error updating the
article we want to show the form back to the user.

We reuse the `article_params` method that we defined earlier for the create
action.

TIP: You don't need to pass all attributes to `update`. For
example, if you'd call `@article.update(title: 'A new title')`
Rails would only update the `title` attribute, leaving all other
attributes untouched.

Finally, we want to show a link to the `edit` action in the list of all the
articles, so let's add that now to `app/views/articles/index.html.erb` to make
it appear next to the "Show" link:

```html+erb
<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
    <th colspan="2"></th>
  </tr>

  <% @articles.each do |article| %>
    <tr>
      <td><%= article.title %></td>
      <td><%= article.text %></td>
      <td><%= link_to 'Show', article_path(article) %></td>
      <td><%= link_to 'Edit', edit_article_path(article) %></td>
    </tr>
  <% end %>
</table>
```

And we'll also add one to the `app/views/articles/show.html.erb` template as
well, so that there's also an "Edit" link on an article's page. Add this at the
bottom of the template:

```html+erb
...

<%= link_to 'Back', articles_path %> |
<%= link_to 'Edit', edit_article_path(@article) %>
```

And here's how our app looks so far:

![Index action with edit link](images/getting_started/index_action_with_edit_link.png)

### Using partials to clean up duplication in views

Our `edit` page looks very similar to the `new` page; in fact, they
both share the same code for displaying the form. Let's remove this
duplication by using a view partial. By convention, partial files are
prefixed by an underscore.

TIP: You can read more about partials in the
[Layouts and Rendering in Rails](layouts_and_rendering.html) guide.

Create a new file `app/views/articles/_form.html.erb` with the following
content:

```html+erb
<%= form_for @article do |f| %>

  <% if @article.errors.any? %>
    <div id="error_explanation">
      <h2>
        <%= pluralize(@article.errors.count, "error") %> prohibited
        this article from being saved:
      </h2>
      <ul>
        <% @article.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>

  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>

  <p>
    <%= f.submit %>
  </p>

<% end %>
```

Everything except for the `form_for` declaration remained the same.
The reason we can use this shorter, simpler `form_for` declaration
to stand in for either of the other forms is that `@article` is a *resource*
corresponding to a full set of RESTful routes, and Rails is able to infer
which URI and method to use.
For more information about this use of `form_for`, see [Resource-oriented style]
(http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for-label-Resource-oriented+style).

Now, let's update the `app/views/articles/new.html.erb` view to use this new
partial, rewriting it completely:

```html+erb
<h1>New article</h1>

<%= render 'form' %>

<%= link_to 'Back', articles_path %>
```

Then do the same for the `app/views/articles/edit.html.erb` view:

```html+erb
<h1>Edit article</h1>

<%= render 'form' %>

<%= link_to 'Back', articles_path %>
```

### Deleting Articles

We're now ready to cover the "D" part of CRUD, deleting articles from the
database. Following the REST convention, the route for
deleting articles as per output of `rake routes` is:

```ruby
DELETE /articles/:id(.:format)      articles#destroy
```

The `delete` routing method should be used for routes that destroy
resources. If this was left as a typical `get` route, it could be possible for
people to craft malicious URLs like this:

```html
<a href='http://example.com/articles/1/destroy'>look at this cat!</a>
```

We use the `delete` method for destroying resources, and this route is mapped
to the `destroy` action inside `app/controllers/articles_controller.rb`, which
doesn't exist yet. The `destroy` method is generally the last CRUD action in
the controller, and like the other public CRUD actions, it must be placed
before any `private` or `protected` methods. Let's add it:

```ruby
def destroy
  @article = Article.find(params[:id])
  @article.destroy

  redirect_to articles_path
end
```

The complete `ArticlesController` in the
`app/controllers/articles_controller.rb` file should now look like this:

```ruby
class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    @article = Article.find(params[:id])
  end

  def new
    @article = Article.new
  end

  def edit
    @article = Article.find(params[:id])
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article
    else
      render 'new'
    end
  end

  def update
    @article = Article.find(params[:id])

    if @article.update(article_params)
      redirect_to @article
    else
      render 'edit'
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    redirect_to articles_path
  end

  private
    def article_params
      params.require(:article).permit(:title, :text)
    end
end
```

You can call `destroy` on Active Record objects when you want to delete
them from the database. Note that we don't need to add a view for this
action since we're redirecting to the `index` action.

Finally, add a 'Destroy' link to your `index` action template
(`app/views/articles/index.html.erb`) to wrap everything together.

```html+erb
<h1>Listing Articles</h1>
<%= link_to 'New article', new_article_path %>
<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
    <th colspan="3"></th>
  </tr>

  <% @articles.each do |article| %>
    <tr>
      <td><%= article.title %></td>
      <td><%= article.text %></td>
      <td><%= link_to 'Show', article_path(article) %></td>
      <td><%= link_to 'Edit', edit_article_path(article) %></td>
      <td><%= link_to 'Destroy', article_path(article),
              method: :delete,
              data: { confirm: 'Are you sure?' } %></td>
    </tr>
  <% end %>
</table>
```

Here we're using `link_to` in a different way. We pass the named route as the
second argument, and then the options as another argument. The `:method` and
`:'data-confirm'` options are used as HTML5 attributes so that when the link is
clicked, Rails will first show a confirm dialog to the user, and then submit the
link with method `delete`.  This is done via the JavaScript file `jquery_ujs`
which is automatically included into your application's layout
(`app/views/layouts/application.html.erb`) when you generated the application.
Without this file, the confirmation dialog box wouldn't appear.

![Confirm Dialog](images/getting_started/confirm_dialog.png)

Congratulations, you can now create, show, list, update and destroy
articles.

TIP: In general, Rails encourages using resources objects instead of
declaring routes manually. For more information about routing, see
[Rails Routing from the Outside In](routing.html).

Adding a Second Model
---------------------

It's time to add a second model to the application. The second model will handle
comments on articles.

### Generating a Model

We're going to see the same generator that we used before when creating
the `Article` model. This time we'll create a `Comment` model to hold
reference of article comments. Run this command in your terminal:

```bash
$ bin/rails generate model Comment commenter:string body:text article:references
```

This command will generate four files:

| File                                         | Purpose                                                                                                |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| db/migrate/20140120201010_create_comments.rb | Migration to create the comments table in your database (your name will include a different timestamp) |
| app/models/comment.rb                        | The Comment model                                                                                      |
| test/models/comment_test.rb                  | Testing harness for the comments model                                                                 |
| test/fixtures/comments.yml                   | Sample comments for use in testing                                                                     |

First, take a look at `app/models/comment.rb`:

```ruby
class Comment < ActiveRecord::Base
  belongs_to :article
end
```

This is very similar to the `Article` model that you saw earlier. The difference
is the line `belongs_to :article`, which sets up an Active Record _association_.
You'll learn a little about associations in the next section of this guide.

In addition to the model, Rails has also made a migration to create the
corresponding database table:

```ruby
class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :commenter
      t.text :body

      # this line adds an integer column called `article_id`.
      t.references :article, index: true

      t.timestamps
    end
  end
end
```

The `t.references` line sets up a foreign key column for the association between
the two models. An index for this association is also created on this column.
Go ahead and run the migration:

```bash
$ bin/rake db:migrate
```

Rails is smart enough to only execute the migrations that have not already been
run against the current database, so in this case you will just see:

```bash
==  CreateComments: migrating =================================================
-- create_table(:comments)
   -> 0.0115s
==  CreateComments: migrated (0.0119s) ========================================
```

### Associating Models

Active Record associations let you easily declare the relationship between two
models. In the case of comments and articles, you could write out the
relationships this way:

* Each comment belongs to one article.
* One article can have many comments.

In fact, this is very close to the syntax that Rails uses to declare this
association. You've already seen the line of code inside the `Comment` model
(app/models/comment.rb) that makes each comment belong to an Article:

```ruby
class Comment < ActiveRecord::Base
  belongs_to :article
end
```

You'll need to edit `app/models/article.rb` to add the other side of the
association:

```ruby
class Article < ActiveRecord::Base
  has_many :comments
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

These two declarations enable a good bit of automatic behavior. For example, if
you have an instance variable `@article` containing an article, you can retrieve
all the comments belonging to that article as an array using
`@article.comments`.

TIP: For more information on Active Record associations, see the [Active Record
Associations](association_basics.html) guide.

### Adding a Route for Comments

As with the `welcome` controller, we will need to add a route so that Rails
knows where we would like to navigate to see `comments`. Open up the
`config/routes.rb` file again, and edit it as follows:

```ruby
resources :articles do
  resources :comments
end
```

This creates `comments` as a _nested resource_ within `articles`. This is
another part of capturing the hierarchical relationship that exists between
articles and comments.

TIP: For more information on routing, see the [Rails Routing](routing.html)
guide.

### Generating a Controller

With the model in hand, you can turn your attention to creating a matching
controller. Again, we'll use the same generator we used before:

```bash
$ bin/rails generate controller Comments
```

This creates six files and one empty directory:

| File/Directory                               | Purpose                                  |
| -------------------------------------------- | ---------------------------------------- |
| app/controllers/comments_controller.rb       | The Comments controller                  |
| app/views/comments/                          | Views of the controller are stored here  |
| test/controllers/comments_controller_test.rb | The test for the controller              |
| app/helpers/comments_helper.rb               | A view helper file                       |
| test/helpers/comments_helper_test.rb         | The test for the helper                  |
| app/assets/javascripts/comment.js.coffee     | CoffeeScript for the controller          |
| app/assets/stylesheets/comment.css.scss      | Cascading style sheet for the controller |

Like with any blog, our readers will create their comments directly after
reading the article, and once they have added their comment, will be sent back
to the article show page to see their comment now listed. Due to this, our
`CommentsController` is there to provide a method to create comments and delete
spam comments when they arrive.

So first, we'll wire up the Article show template
(`app/views/articles/show.html.erb`) to let us make a new comment:

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Add a comment:</h2>
<%= form_for([@article, @article.comments.build]) do |f| %>
  <p>
    <%= f.label :commenter %><br>
    <%= f.text_field :commenter %>
  </p>
  <p>
    <%= f.label :body %><br>
    <%= f.text_area :body %>
  </p>
  <p>
    <%= f.submit %>
  </p>
<% end %>

<%= link_to 'Back', articles_path %> |
<%= link_to 'Edit', edit_article_path(@article) %>
```

This adds a form on the `Article` show page that creates a new comment by
calling the `CommentsController` `create` action. The `form_for` call here uses
an array, which will build a nested route, such as `/articles/1/comments`.

Let's wire up the `create` in `app/controllers/comments_controller.rb`:

```ruby
class CommentsController < ApplicationController
  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.create(comment_params)
    redirect_to article_path(@article)
  end

  private
    def comment_params
      params.require(:comment).permit(:commenter, :body)
    end
end
```

You'll see a bit more complexity here than you did in the controller for
articles. That's a side-effect of the nesting that you've set up. Each request
for a comment has to keep track of the article to which the comment is attached,
thus the initial call to the `find` method of the `Article` model to get the
article in question.

In addition, the code takes advantage of some of the methods available for an
association. We use the `create` method on `@article.comments` to create and
save the comment. This will automatically link the comment so that it belongs to
that particular article.

Once we have made the new comment, we send the user back to the original article
using the `article_path(@article)` helper. As we have already seen, this calls
the `show` action of the `ArticlesController` which in turn renders the
`show.html.erb` template. This is where we want the comment to show, so let's
add that to the `app/views/articles/show.html.erb`.

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Comments</h2>
<% @article.comments.each do |comment| %>
  <p>
    <strong>Commenter:</strong>
    <%= comment.commenter %>
  </p>

  <p>
    <strong>Comment:</strong>
    <%= comment.body %>
  </p>
<% end %>

<h2>Add a comment:</h2>
<%= form_for([@article, @article.comments.build]) do |f| %>
  <p>
    <%= f.label :commenter %><br>
    <%= f.text_field :commenter %>
  </p>
  <p>
    <%= f.label :body %><br>
    <%= f.text_area :body %>
  </p>
  <p>
    <%= f.submit %>
  </p>
<% end %>

<%= link_to 'Edit Article', edit_article_path(@article) %> |
<%= link_to 'Back to Articles', articles_path %>
```

Now you can add articles and comments to your blog and have them show up in the
right places.

![Article with Comments](images/getting_started/article_with_comments.png)

Refactoring
-----------

Now that we have articles and comments working, take a look at the
`app/views/articles/show.html.erb` template. It is getting long and awkward. We
can use partials to clean it up.

### Rendering Partial Collections

First, we will make a comment partial to extract showing all the comments for
the article. Create the file `app/views/comments/_comment.html.erb` and put the
following into it:

```html+erb
<p>
  <strong>Commenter:</strong>
  <%= comment.commenter %>
</p>

<p>
  <strong>Comment:</strong>
  <%= comment.body %>
</p>
```

Then you can change `app/views/articles/show.html.erb` to look like the
following:

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Comments</h2>
<%= render @article.comments %>

<h2>Add a comment:</h2>
<%= form_for([@article, @article.comments.build]) do |f| %>
  <p>
    <%= f.label :commenter %><br>
    <%= f.text_field :commenter %>
  </p>
  <p>
    <%= f.label :body %><br>
    <%= f.text_area :body %>
  </p>
  <p>
    <%= f.submit %>
  </p>
<% end %>

<%= link_to 'Edit Article', edit_article_path(@article) %> |
<%= link_to 'Back to Articles', articles_path %>
```

This will now render the partial in `app/views/comments/_comment.html.erb` once
for each comment that is in the `@article.comments` collection. As the `render`
method iterates over the `@article.comments` collection, it assigns each
comment to a local variable named the same as the partial, in this case
`comment` which is then available in the partial for us to show.

### Rendering a Partial Form

Let us also move that new comment section out to its own partial. Again, you
create a file `app/views/comments/_form.html.erb` containing:

```html+erb
<%= form_for([@article, @article.comments.build]) do |f| %>
  <p>
    <%= f.label :commenter %><br>
    <%= f.text_field :commenter %>
  </p>
  <p>
    <%= f.label :body %><br>
    <%= f.text_area :body %>
  </p>
  <p>
    <%= f.submit %>
  </p>
<% end %>
```

Then you make the `app/views/articles/show.html.erb` look like the following:

```html+erb
<p>
  <strong>Title:</strong>
  <%= @article.title %>
</p>

<p>
  <strong>Text:</strong>
  <%= @article.text %>
</p>

<h2>Comments</h2>
<%= render @article.comments %>

<h2>Add a comment:</h2>
<%= render 'comments/form' %>

<%= link_to 'Edit Article', edit_article_path(@article) %> |
<%= link_to 'Back to Articles', articles_path %>
```

The second render just defines the partial template we want to render,
`comments/form`. Rails is smart enough to spot the forward slash in that
string and realize that you want to render the `_form.html.erb` file in
the `app/views/comments` directory.

The `@article` object is available to any partials rendered in the view because
we defined it as an instance variable.

Deleting Comments
-----------------

Another important feature of a blog is being able to delete spam comments. To do
this, we need to implement a link of some sort in the view and a `destroy`
action in the `CommentsController`.

So first, let's add the delete link in the
`app/views/comments/_comment.html.erb` partial:

```html+erb
<p>
  <strong>Commenter:</strong>
  <%= comment.commenter %>
</p>

<p>
  <strong>Comment:</strong>
  <%= comment.body %>
</p>

<p>
  <%= link_to 'Destroy Comment', [comment.article, comment],
               method: :delete,
               data: { confirm: 'Are you sure?' } %>
</p>
```

Clicking this new "Destroy Comment" link will fire off a `DELETE
/articles/:article_id/comments/:id` to our `CommentsController`, which can then
use this to find the comment we want to delete, so let's add a `destroy` action
to our controller (`app/controllers/comments_controller.rb`):

```ruby
class CommentsController < ApplicationController
  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.create(comment_params)
    redirect_to article_path(@article)
  end

  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])
    @comment.destroy
    redirect_to article_path(@article)
  end

  private
    def comment_params
      params.require(:comment).permit(:commenter, :body)
    end
end
```

The `destroy` action will find the article we are looking at, locate the comment
within the `@article.comments` collection, and then remove it from the
database and send us back to the show action for the article.


### Deleting Associated Objects

If you delete an article, its associated comments will also need to be
deleted, otherwise they would simply occupy space in the database. Rails allows
you to use the `dependent` option of an association to achieve this. Modify the
Article model, `app/models/article.rb`, as follows:

```ruby
class Article < ActiveRecord::Base
  has_many :comments, dependent: :destroy
  validates :title, presence: true,
                    length: { minimum: 5 }
end
```

Security
--------

### Basic Authentication

If you were to publish your blog online, anyone would be able to add, edit and
delete articles or delete comments.

Rails provides a very simple HTTP authentication system that will work nicely in
this situation.

In the `ArticlesController` we need to have a way to block access to the
various actions if the person is not authenticated. Here we can use the Rails
`http_basic_authenticate_with` method, which allows access to the requested
action if that method allows it.

To use the authentication system, we specify it at the top of our
`ArticlesController` in `app/controllers/articles_controller.rb`. In our case,
we want the user to be authenticated on every action except `index` and `show`,
so we write that:

```ruby
class ArticlesController < ApplicationController

  http_basic_authenticate_with name: "dhh", password: "secret", except: [:index, :show]

  def index
    @articles = Article.all
  end

  # snipped for brevity
```

We also want to allow only authenticated users to delete comments, so in the
`CommentsController` (`app/controllers/comments_controller.rb`) we write:

```ruby
class CommentsController < ApplicationController

  http_basic_authenticate_with name: "dhh", password: "secret", only: :destroy

  def create
    @article = Article.find(params[:article_id])
    # ...
  end

  # snipped for brevity
```

Now if you try to create a new article, you will be greeted with a basic HTTP
Authentication challenge:

![Basic HTTP Authentication Challenge](images/getting_started/challenge.png)

Other authentication methods are available for Rails applications. Two popular
authentication add-ons for Rails are the
[Devise](https://github.com/plataformatec/devise) rails engine and
the [Authlogic](https://github.com/binarylogic/authlogic) gem,
along with a number of others.


### Other Security Considerations

Security, especially in web applications, is a broad and detailed area. Security
in your Rails application is covered in more depth in
the [Ruby on Rails Security Guide](security.html).


What's Next?
------------

Now that you've seen your first Rails application, you should feel free to
update it and experiment on your own. But you don't have to do everything
without help. As you need assistance getting up and running with Rails, feel
free to consult these support resources:

* The [Ruby on Rails Guides](index.html)
* The [Ruby on Rails Tutorial](http://railstutorial.org/book)
* The [Ruby on Rails mailing list](http://groups.google.com/group/rubyonrails-talk)
* The [#rubyonrails](irc://irc.freenode.net/#rubyonrails) channel on irc.freenode.net

Rails also comes with built-in help that you can generate using the rake
command-line utility:

* Running `rake doc:guides` will put a full copy of the Rails Guides in the
  `doc/guides` folder of your application. Open `doc/guides/index.html` in your
  web browser to explore the Guides.
* Running `rake doc:rails` will put a full copy of the API documentation for
  Rails in the `doc/api` folder of your application. Open `doc/api/index.html`
  in your web browser to explore the API documentation.

TIP: To be able to generate the Rails Guides locally with the `doc:guides` rake
task you need to install the RedCloth gem. Add it to your `Gemfile` and run
`bundle install` and you're ready to go.

Configuration Gotchas
---------------------

The easiest way to work with Rails is to store all external data as UTF-8. If
you don't, Ruby libraries and Rails will often be able to convert your native
data into UTF-8, but this doesn't always work reliably, so you're better off
ensuring that all external data is UTF-8.

If you have made a mistake in this area, the most common symptom is a black
diamond with a question mark inside appearing in the browser. Another common
symptom is characters like "Ã¼" appearing instead of "ü". Rails takes a number
of internal steps to mitigate common causes of these problems that can be
automatically detected and corrected. However, if you have external data that is
not stored as UTF-8, it can occasionally result in these kinds of issues that
cannot be automatically detected by Rails and corrected.

Two very common sources of data that are not UTF-8:

* Your text editor: Most text editors (such as TextMate), default to saving
  files as UTF-8. If your text editor does not, this can result in special
  characters that you enter in your templates (such as é) to appear as a diamond
  with a question mark inside in the browser. This also applies to your i18n
  translation files. Most editors that do not already default to UTF-8 (such as
  some versions of Dreamweaver) offer a way to change the default to UTF-8. Do
  so.
* Your database: Rails defaults to converting data from your database into UTF-8
  at the boundary. However, if your database is not using UTF-8 internally, it
  may not be able to store all characters that your users enter. For instance,
  if your database is using Latin-1 internally, and your user enters a Russian,
  Hebrew, or Japanese character, the data will be lost forever once it enters
  the database. If possible, use UTF-8 as the internal storage of your database.
