**DO NOT READ THIS FILE IN GITHUB, GUIDES ARE PUBLISHED IN http://rails.ruby.tw.**

在 Rails 使用 JavaScript
===============================

本篇介紹 Rails 內建的 Ajax/JavaScript 功能。輕鬆打造豐富生動的 Ajax 應用程式。

讀完本篇，您將了解：

* Ajax 的基礎。
* 如何將 JavaScript 與 HTML 分離（Unobtrusive JavaScript）。
* 如何使用 Rails 內建的幫助方法。
* 如何在伺服器端處理 Ajax。
* Turbolinks。

--------------------------------------------------------------------------------

Ajax 介紹
------------------

要理解 Ajax，首先必須先了解瀏覽器平常的工作原理。

在瀏覽器網址欄輸入 `http://localhost:3000`，並按下 Enter。瀏覽器此時便向伺服器發送請求。伺服器接收請求，去拿所有需要的資源（assets），像是 JS、CSS、圖片等，接著將這些資源，按照程式邏輯組合成網頁，返回網頁給瀏覽器。在網頁裡按下某個連結，會重複剛剛的步驟：發送請求、抓取資源、組合頁面、返回結果。這幾個步驟通常稱為“請求響應週期”（Request Response Cycle）。

JavaScript 也可向伺服器發送請求，並解析響應。JavaScript 也具有更新網頁的能力。熟悉 JavaScript 的開發者可以做到只更新部分的頁面，而無需向伺服器索要整個頁面。這個強大的技術稱為 Ajax。

Rails 出廠內建 CoffeeScript，故以下的例子皆以 CoffeeScript 撰寫。當然這些例子也可用純 JavaScript 寫出來。

以下是用 CoffeeScript 使用 jQuery 發送 Ajax 請求的例子：

```coffeescript
$.ajax(url: "/test").done (html) ->
  $("#results").append html
```

這段程式從 `/test` 獲取資料，並將資料附加在 `id` 為 `#results` 的 `div` 之後。

Rails 對於使用這種技巧來撰寫網頁，提供了相當多的官方支援。幾乎很少會需要自己寫這樣的程式。以下章節將示範，如何用點簡單的技術，便能用 Rails 寫出應用了 Ajax 的網站。

Unobtrusive JavaScript
------------------------------------

Rails 使用一種叫做 “[Unobtrusive JavaScript][ujs]” （縮寫為 UJS）的技術來處理 DOM 操作。這是來自前端社群的最佳實踐，但有些教學文件可能會用別種技術，來達成同樣的事情。

以下是撰寫 JavaScript 最簡單的方式（行內 JavaScript）：

```html
<a href="#" onclick="this.style.backgroundColor='#990000'">Paint it red</a>
```

按下連結，背景就變紅。如果按下連結後，要執行許多 JavaScript 程式碼怎麼辦？

```html
<a href="#" onclick="this.style.backgroundColor='#009900';this.style.color='#FFFFFF';">Paint it green</a>
```

尷尬吧？可以將 JavaScript 抽離出來，並用 CoffeeScript 改寫：

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor
```

接著換掉行內寫法：

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
```

看起來好一點了，但多個連結都要有同樣的效果呢？

```html
<a href="#" onclick="paintIt(this, '#990000')">Paint it red</a>
<a href="#" onclick="paintIt(this, '#009900', '#FFFFFF')">Paint it green</a>
<a href="#" onclick="paintIt(this, '#000099', '#FFFFFF')">Paint it blue</a>
```

很不 DRY 啊。可以使用事件來簡化。給每個連結加上 `data-*` 屬性，接著給每個連結的 click 事件，加上一個處理函式：

```coffeescript
paintIt = (element, backgroundColor, textColor) ->
  element.style.backgroundColor = backgroundColor
  if textColor?
    element.style.color = textColor

$ ->
  $("a[data-background-color]").click (e) ->
    e.preventDefault()

    backgroundColor = $(this).data("background-color")
    textColor = $(this).data("text-color")
    paintIt(this, backgroundColor, textColor)
```

```html
<a href="#" data-background-color="#990000">Paint it red</a>
<a href="#" data-background-color="#009900" data-text-color="#FFFFFF">Paint it green</a>
<a href="#" data-background-color="#000099" data-text-color="#FFFFFF">Paint it blue</a>
```

這個技術稱為 “Unobtrusive” JavaScript。因為 JavaScript 不再需要與 HTML 混在一起。之後便更容易修改，也更容易加新功能上去。任何連結只要加個 `data-` 屬性，便可以得到同樣效果。將 JavaScript 從 HTML 抽離後，JavaScript 便可透過合併壓縮工具，讓所有頁面可以共用整份 JavaScript 。也就是說，只需在第一次戴入頁面時下載一次，之後的頁面使用快取的檔案即可。Unobtrusive JavaScript 帶來的好處非常多。

Rails 團隊強烈建議採用這種風格來撰寫 CoffeeScript (JavaScript)，你會發現許多函式庫也採用這種風格。

內建的 Ajax 幫助方法
--------------------------------

Rails 在 View 提供了許多用 Ruby 寫的幫助方法來產生 HTML。會想元素加上 Ajax？沒問題，Rails 會幫助你。

Rails 的 “Ajax 幫助方法” 實際上分成用 JavaScript 所寫的幫助方法，與用 Ruby 所寫成的幫助方法。

用 JavaScript 寫的部分可以在這找到 [rails.js][rails-js]，而用 Ruby 寫的部份就是 View 的幫助方法，用來給 DOM 新增適當的標籤。rails.js 裡的 CoffeeScript 會監聽這些屬性，執行相應的處理函式。

### form_for

[`form_for`][form_for]

撰寫表單的幫助方法。接受 `:remote` 選項：

```erb
<%= form_for(@article, remote: true) do |f| %>
  ...
<% end %>
```

產生的 HTML：

```html
<form accept-charset="UTF-8" action="/articles" class="new_article" data-remote="true" id="new_article" method="post">
  ...
</form>
```

注意 `data-remote="true"`。有了這個屬性之後，表單會透過 Ajax 提交，而不是瀏覽器平常的提交機制。

除了產生出來的 `<form>` 之外，可能還想在提交成功與失敗做某些處理。可以透過 `ajax:success` 與 `ajax:error` 事件，在提交成功與失敗時，來附加內容至 DOM：

```coffeescript
$(document).ready ->
  $("#new_article").on("ajax:success", (e, data, status, xhr) ->
    $("#new_article").append xhr.responseText
  ).on "ajax:error", (e, xhr, status, error) ->
    $("#new_article").append "<p>ERROR</p>"
```

當然這只是個開始，更多可用的事件可在 [jQuery-ujs 的維基頁面][jquery-ujs-wiki]上可找到。

### form_tag

[`form_tag`][form_tag]

跟 `form_for` 非常類似，接受 `:remote` 選項：

```erb
<%= form_tag('/articles', remote: true) %>
```

產生的 HTML：

```html
<form accept-charset="UTF-8" action="/articles" data-remote="true" method="post">
  ...
</form>
```

### link_to

[`link_to`][link_to]

產生連結的幫助方法。接受 `:remote` 選項：

```erb
<%= link_to "an article", @article, remote: true %>
```

產生的 HTML：

```html
<a href="/artciles/1" data-remote="true">an article</a>
```

可以像上面 `form_for` 例子那樣，綁定相同的 Ajax 事件上去。 來看個例子，假設按個按鍵，刪除一篇文章，提示一些訊息。只需寫一些 HTML：

```erb
<%= link_to "Delete artcile", @article, remote: true, method: :delete %>
```

再寫一點 CoffeeScript：

```coffeescript
$ ->
  $("a[data-remote]").on "ajax:success", (e, data, status, xhr) ->
    alert "The article was deleted."
```

就這麼簡單。

### button_to

[`button_to`][button_to]

建立按鈕的幫助方法。接受 `:remote` 選項：

```erb
<%= button_to "An article", @article, remote: true %>
```

會產生：

```html
<form action="/articles/1" class="button_to" data-remote="true" method="post">
  <div>
    <input type="submit" value="An article">
    <input name="authenticity_token" type="hidden" value="PVXViXMJCLd717CYN5Ty7/gTLF3iaqPhL33FTeBmoVk=">
  </div>
</form>
```

由於這只是個 `<form>`，所有 `form_for` 可用的東西，也可以應用在 `button_to`。

伺服器端的考量
------------------------

Ajax 不只是客戶端的事，伺服器也要出力。人們傾向 Ajax 請求回傳 JSON，而不是 HTML，來看看如何回傳 JSON。

### 簡單的例子

假設有許多使用者，想給他們顯示建立新帳號的表單。而 Controller 的 `index` 動作：

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    @user = User.new
  end
  # ...
```

以及 `index` View (`app/views/users/index.html.erb`)：

```html+erb
<b>Users</b>

<ul id="users">
  <%= render @users %>
</ul>

<br>

<%= form_for(@user, remote: true) do |f| %>
  <%= f.label :name %><br>
  <%= f.text_field :name %>
  <%= f.submit %>
<% end %>
```

`app/views/users/_user.html.erb` Partial：

```erb
<li><%= user.name %></li>
```

`index` 頁面上半部列出用戶，下半部提供新建用戶的表單。

下面的表單會呼叫 `Users` Controller 的 `create` 動作。因為表單有 `remote: true` 這個選項，請求會使用 Ajax POST 到 `Users` Controller，等待 Controller 回應 JavaScript。處理這個請求的 `create` 動作會像是：

```ruby
  # app/controllers/users_controller.rb
  # ......
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.js   {}
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
```

注意 `respond_to` 區塊內的 `format.js`，這是 Controller 回應 Ajax 請求的地方。`create` 動作對應 `app/views/users/create.js.erb`：

```erb
$("<%= escape_javascript(render @user) %>").appendTo("#users");
```

Turbolinks
---------------

Rails 4 出廠內建 [Turbolinks RubyGem](https://github.com/rails/turbolinks)。Turbolinks 使用了 Ajax 技術，可以加速頁面的渲染。

### Turbolinks 工作原理

Turbolinks 給頁面上所有的 `a` 標籤添加了一個 click 處理函式。如果瀏覽器支援 [PushState][ps]，Turbolinks 會對頁面發出 Ajax 請求，解析伺服器回過來的響應，把頁面整個 `<body>` 用響應回傳的 `<body>` 換掉。接著 Turbolinks 會利用 PushState 把 URL 換成正確的，看起來就像重新整理一樣，仍保有漂亮的 URL。

啟用 Turbolinks 只需在 `Gemfile` 加入：

```ruby
gem 'turbolinks'
```

並在 CoffeeScript Manifest 檔案（`app/assets/javascripts/application.js`）裡加入：

```coffeescript
//= require turbolinks
```

若有些連結要禁用 Turbolinks，給該連結加上 `data-no-turbolink` 屬性即可：

```html
<a href="..." data-no-turbolink>No turbolinks here</a>.
```

### 頁面變化的事件

撰寫 CoffeeScript 時，通常會想在頁面加載時做些處理，搭配 jQuery，通常會寫出像是下面的程式碼：

```coffeescript
$(document).ready ->
  alert "page has loaded!"
```

而 Turbolinks 覆寫了頁面加載邏輯，依賴 `$(document).ready` 事件的程式碼不會被觸發。若是寫了類似上例的程式碼，必須改寫成：

```coffeescript
$(document).on "page:change", ->
  alert "page has loaded!"
```

關於更多細節，其他可以綁定的事件等，參考 [Turbolinks 的讀我文件](https://github.com/rails/turbolinks/blob/master/README.md)。

其他資源
------------------------

了解更多相關內容，請參考以下連結：

* [jquery-ujs wiki](https://github.com/rails/jquery-ujs/wiki)
* [jquery-ujs list of external articles](https://github.com/rails/jquery-ujs/wiki/External-articles)
* [Rails 3 Remote Links and Forms: A Definitive Guide](http://www.alfajango.com/blog/rails-3-remote-links-and-forms/)
* [Railscasts: Unobtrusive JavaScript](http://railscasts.com/episodes/205-unobtrusive-javascript)
* [Railscasts: Turbolinks](http://railscasts.com/episodes/390-turbolinks)

[jquery-ujs-wiki]: https://github.com/rails/jquery-ujs/wiki/ajax
[ps]: https://developer.mozilla.org/en-US/docs/DOM/Manipulating_the_browser_history#The_pushState(\).C2.A0method
[rails-js]: https://github.com/rails/jquery-ujs/blob/master/src/rails.js
[form_for]: http://api.rubyonrails.org/classes/ActionView/Helpers/FormHelper.html#method-i-form_for
[form_tag]: http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html#method-i-form_tag
[link_to]: http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to
[button_to]: http://api.rubyonrails.org/classes/ActionView/Helpers/UrlHelper.html#method-i-button_to
[ujs]: http://zh.wikipedia.org/zh-tw/Unobtrusive_JavaScript
