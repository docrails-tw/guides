**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://rails.ruby.tw.**

Action View 表單輔助方法
=======================

表單是 Web 應用程式裡，供使用者輸入的基本介面。然而表單的各種名稱與屬性，撰寫表單很快便變得繁瑣與難以維護。Rails 透過 Action View 提供輔助方法，來簡化表單的撰寫。但各種輔助方法的應用場景不盡相同，開發者需要知道輔助方法之間的差異，才能完善的使用這些輔助方法。

讀完本篇，您將了解：

* 如何建立搜索表單與其它常見的通用表單。
* 如何替 Model 打造出編輯與建立資料庫記錄的表單。
* 如何從多種類型的資料產生下拉選單。
* Rails 提供的日期與時間輔助方法。
* 上傳檔案表單的特別之處。
* 打造供外部資源使用的表單。
* 如何打造複雜表單。

--------------------------------------------------------------------------------

NOTE: 本篇不是表單輔助方法完整的文件，完整文件請參考 [Rails API 文件](http://api.rubyonrails.org/)。


處理簡單的表單
------------------------

最基本的表單輔助方法是 `form_tag`。

```erb
<%= form_tag do %>
  Form contents
<% end %>
```

像這樣不傳參數呼叫時，會建立出 `<form>` 標籤。按下送出時，會對目前的頁面做 POST。舉例來說，假設目前的頁面是 `/home/index`，上例產生的 HTML 會像是（加了某些斷行提高可讀性）：

```html
<form accept-charset="UTF-8" action="/" method="post">
  <input name="utf8" type="hidden" value="&#x2713;" />
  <input name="authenticity_token" type="hidden" value="J7CBxfHalt49OSHp27hblqK20c9PgwJ108nDHX/8Cts=" />
  Form contents
</form>
```

注意到 HTML 裡有個隱藏的 `input`，這個隱藏的 `input` 很重要，沒有這個 `input` 表單便無法順利送出。第一個 `name` 屬性為 `utf8` 的 `input`，強制瀏覽器正確採用表單指定的編碼，所有 HTTP 動詞為 GET 或 POST 表單，Rails 都會產生這個 input。第二個 `name` 屬性為 `authenticity_token` 的 `input`，是 Rails 內建用來防止 CSRF (cross-site request forgery protection) 攻擊的安全機制，任何非 GET 的表單，Rails 都會產生一個這樣的 `input`（安全機制有啟用的話）。詳情請閱讀[安全指南](security.html#cross-site-request-forgery-csrf)。

### 通用搜索表單

Web 世界最基本的表單之一是「搜索表單」。通常由以下元素組成：

* 一個有 GET 動詞的表單
* 供輸入的文字欄位
* 輸入有標籤
* 送出元素

要建立這樣的搜索表單，可以使用 `form_tag`、`label_tag`、`text_field_tag` 以及 `submit_tag`：

```erb
<%= form_tag("/search", method: "get") do %>
  <%= label_tag(:q, "Search for:") %>
  <%= text_field_tag(:q) %>
  <%= submit_tag("Search") %>
<% end %>
```

會產生出如下 HTML：

```html
<form accept-charset="UTF-8" action="/search" method="get">
  <input name="utf8" type="hidden" value="&#x2713;" />
  <label for="q">Search for:</label>
  <input id="q" name="q" type="text" />
  <input name="commit" type="submit" value="Search" />
</form>
```

TIP: 每個表單的輸入 `input`，都會根據 `name` 屬性來產生 ID 屬性（上例為 `q`）。有了 ID，CSS 要新增樣式、或 JavaScript 要操作表單都很方便。

除了 `text_field_tag` 與 `submit_tag` 之外，每個表單元素都有對應的輔助方法。

IMPORTANT: 搜索表單永遠使用 GET 動詞。這允許使用者可以把搜索結果加入書籤，之後便能透過書籤瀏覽。Rails 普遍鼓勵使用正確的 HTTP 動詞。

### 呼叫表單輔助方法同時傳多個 Hash

`form_tag` 輔助方法接受 2 個參數：表單送出的目標路徑和 Hash 選項。Hash 選項用來指定表單所使用的方法，以及其它 HTML 選項，如指定表單的 `class`。

和 `link_to` 輔助方法類似，路徑不需要是字串。可以是 Rails Router 看的懂的 URL Hash，Rails 的路由機制會把 Hash 轉換為有效的 URL。但由於傳給 `form_tag` 的兩個參數都是 Hash 時，同時指定會碰到下例所演示的問題：

```ruby
form_tag(controller: "people", action: "search", method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search?class=nifty_form&amp;method=get" method="post">'
```

這裡 `method` 與 `class` 變成了 URL 的查詢字串，因為 Rails 將這四個參數認成了一個 Hash。需要把第一組 Hash 放在大括號裡（或明確使用大括號亦可），才會產生出正確的 HTML：

```ruby
form_tag({ controller: "people", action: "search" }, method: "get", class: "nifty_form")
# => '<form accept-charset="UTF-8" action="/people/search" class="nifty_form" method="get">'
```

### 產生表單元素的輔助方法

Rails 提供一系列的輔助方法，用來產生表單元素，像是多選方框（checkboxes）、文字欄位（text fields）以及單選按鈕（radio button）。名字以 `_tag` 結尾的輔助方法（譬如 `text_field_tag` 與 `check_box_tag`）只會產生一個 `<input>` 元素。這些輔助方法的第一個參數都是 `input` 的名稱（name）。表單送出時，`name` 會與表單資料一起送出，使用者輸入的資料會存在 `params` Hash 裡，可在 Controller 取用。舉個例子，若表單的 `input` 是 `<%= text_field_tag(:query) %>`，則可在 Controller 用 `params[:query]` 來獲得使用者的輸入。

Rails 使用特定的慣例來命名 `input`，使得送出像是陣列與 Hash 的值，也可以在 `params` 裡取用。了解更多可閱讀本文第七章：[理解參數命名慣例](#理解參數命名慣例)。這些輔助方法更精確的用途，請參考 [API 文件](http://api.rubyonrails.org/classes/ActionView/Helpers/FormTagHelper.html)。

#### 多選方框

多選方框是一種表單控件，給使用者一組可啟用停用的選項：

```erb
<%= check_box_tag(:pet_dog) %>
<%= label_tag(:pet_dog, "I own a dog") %>
<%= check_box_tag(:pet_cat) %>
<%= label_tag(:pet_cat, "I own a cat") %>
```

會產生出如下 HTML：

```html
<input id="pet_dog" name="pet_dog" type="checkbox" value="1" />
<label for="pet_dog">I own a dog</label>
<input id="pet_cat" name="pet_cat" type="checkbox" value="1" />
<label for="pet_cat">I own a cat</label>
```

`checkbox_box_tag` 第一個參數是 `input` 的 `name`，第二個參數通常是 `input` 的 `value`，當該多選方框被選中時，`value` 會被包含在表單資料一併送出，便可在 `params` 取用。

#### Radio Buttons

單選按鈕與多選方框類似，但每個選項是互斥的（也就是只能選一個）：

```erb
<%= radio_button_tag(:age, "child") %>
<%= label_tag(:age_child, "I am younger than 21") %>
<%= radio_button_tag(:age, "adult") %>
<%= label_tag(:age_adult, "I'm over 21") %>
```

會產生出如下 HTML：

```html
<input id="age_child" name="age" type="radio" value="child" />
<label for="age_child">I am younger than 21</label>
<input id="age_adult" name="age" type="radio" value="adult" />
<label for="age_adult">I'm over 21</label>
```

和 `check_box_tag` 類似，`radio_button_tag` 的第二個參數同樣是 `input` 的 `value`。因為這兩個單選按鈕的 `name` 都是 `age`，使用者只能選一個， `params[:age]` 的值會是 `"child"` 或 `"adult"`。

NOTE: 永遠記得幫多選方框與單選按鈕加上 `label`。`label` 可以為特定的輸入新增說明文字，也會加大可按範圍，讓使用者更容易選中。

### 其它相關輔助方法

其它值得一提的表單控件有：textareas、password fields、hidden fields、search fields、telephone fields、date fields、time fields、color fields、datetime fields、datetime-local fields、month fields、week fields、url fields、email fields、number fields 以及 range fields：

```erb
<%= text_area_tag(:message, "Hi, nice site", size: "24x6") %>
<%= password_field_tag(:password) %>
<%= hidden_field_tag(:parent_id, "5") %>
<%= search_field(:user, :name) %>
<%= telephone_field(:user, :phone) %>
<%= date_field(:user, :born_on) %>
<%= datetime_field(:user, :meeting_time) %>
<%= datetime_local_field(:user, :graduation_day) %>
<%= month_field(:user, :birthday_month) %>
<%= week_field(:user, :birthday_week) %>
<%= url_field(:user, :homepage) %>
<%= email_field(:user, :address) %>
<%= color_field(:user, :favorite_color) %>
<%= time_field(:task, :started_at) %>
<%= number_field(:product, :price, in: 1.0..20.0, step: 0.5) %>
<%= range_field(:product, :discount, in: 1..100) %>
```

產生的 HTML：

```html
<textarea id="message" name="message" cols="24" rows="6">Hi, nice site</textarea>
<input id="password" name="password" type="password" />
<input id="parent_id" name="parent_id" type="hidden" value="5" />
<input id="user_name" name="user[name]" type="search" />
<input id="user_phone" name="user[phone]" type="tel" />
<input id="user_born_on" name="user[born_on]" type="date" />
<input id="user_meeting_time" name="user[meeting_time]" type="datetime" />
<input id="user_graduation_day" name="user[graduation_day]" type="datetime-local" />
<input id="user_birthday_month" name="user[birthday_month]" type="month" />
<input id="user_birthday_week" name="user[birthday_week]" type="week" />
<input id="user_homepage" name="user[homepage]" type="url" />
<input id="user_address" name="user[address]" type="email" />
<input id="user_favorite_color" name="user[favorite_color]" type="color" value="#000000" />
<input id="task_started_at" name="task[started_at]" type="time" />
<input id="product_price" max="20.0" min="1.0" name="product[price]" step="0.5" type="number" />
<input id="product_discount" max="100" min="1" name="product[discount]" type="range" />
```

隱藏的 `input` 不會顯示給使用者，但和其它文字輸入一樣可以存放資料。隱藏的 `input` 的值可以使用 JavaScript 來修改。

IMPORTANT: search、telephone、date、time、color、datetime、datetime-local、month、week、URL、email、number 以及 range inputs 是 HTML5 控件。若需要應用程式在舊版的瀏覽器也有一致的瀏覽體驗，需要使用 HTML5 polyfill（由 CSS 或 JavaScript 提供）。[雖然 polyfill 很好](https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-Browser-Polyfills)，但目前主流工具是 [Modernizr](http://www.modernizr.com/) 以及 [yepnope](http://yepnopejs.com/)，這兩個工具提供一種簡單的方式，用來新增 HTML5 的新功能。

TIP: 若使用了 password input fields（不論用途），輸入的值可能不要記錄在 Log。詳細做法請參考安全指南：[logging 一節](security.html#logging)。

處理 Model 物件
--------------------------

### Model 物件輔助方法

表單通常拿來新建或編輯 Model 物件。可以使用 `*_tag` 這些輔助方法來處理，但太繁瑣了，參數名稱和預設值都得正確才行。Rails 提供更多方便的輔助方法（沒有 `_tag` 字尾），像是 `text_field`、`text_area` 等，專門用來處理 Model 物件。

這些輔助方法的第一個參數是實體變數的名字，第二個參數是要對實體變數呼叫的方法名稱（通常是屬性）。Rails 會將呼叫的結果存成 `input` 的 `value`，並幫你給 `input` 的 `name` 取個好名字。假設 Controller 已經定義了 `@person`，`@person.name` 是 `Henry`，則：

```erb
<%= text_field(:person, :name) %>
```

會產生

```erb
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

送出表單時，使用者的輸入會存在 `params[:person][:name]`，`params[:person]` 可傳給 `Person.new`；若 `@person` 是 `Person` 的實體，則可傳給 `Person#update`。通常第二個參數是屬性名稱，實在是太常用了，通常可省略不寫，只要該物件有實作 `name` 與 `name=` 方法即可。

WARNING: 第一個參數必須是實體變數的“名稱”，如：`:person` 或 `"person"`，而不是傳實際的實體物件進去。

Rails 還提供了用來顯示與 Model 物件驗證錯誤訊息的輔助方法。這些方法在 [Active Record 驗證](/active_record_validations.html#在-view-顯示驗證失敗訊息)一文裡詳細說明。

### 將表單綁定到物件

雖然這些去掉 `_tag` 的輔助方法很方便，但還不夠好。若 `Person` 有很多屬性時，得一直重複傳入要編輯的物件名稱，來生成對應的表單。Rails 提供了 `form_for`，用來將表單綁定至 Model 的物件。

假設有處理文章的 Controller `app/controllers/articles_controller.rb`：

```ruby
def new
  @article = Article.new
end
```

對應的 View `app/views/articles/new.html.erb`，使用了 `form_for` 看起來會像是這樣：

```erb
<%= form_for @article, url: {action: "create"}, html: {class: "nifty_form"} do |f| %>
  <%= f.text_field :title %>
  <%= f.text_area :body, size: "60x12" %>
  <%= f.submit "Create" %>
<% end %>
```

有幾件要說明的事情：

* `@article` 是實際被編輯的物件。
& `form_for` 接受一個 Hash 選項。路由相關選項放在 `:url` 傳入，HTML 相關選項放在 `html:` 選項傳入。還可以提供 `:namespace` 選項，用來確保 ID 的唯一性。`namespace` 的值會自動成為 HTML ID 的前綴。

* `form_for` 方法會產生一個 **表單構造器（Form Builder）** 物件（`f` 變數）。
* 輔助方法皆在 `f`，表單構造器上呼叫。

產生的 HTML 為：

```html
<form accept-charset="UTF-8" action="/articles/create" method="post" class="nifty_form">
  <input id="article_title" name="article[title]" type="text" />
  <textarea id="article_body" name="article[body]" cols="60" rows="12"></textarea>
  <input name="commit" type="submit" value="Create" />
</form>
```

傳給 `form_for` 的名稱會成為在 `params` 取用表單數值的鍵。上例名稱為 `article`，因此所有的 `name` 都是 `article[attribute_name]`。在 `create` 動作裡的 `params[:article]` 會是有著 `:title` 與 `:body` 鍵的 Hash。輸入名稱的重要性，可參閱[理解參數命名慣例](#理解參數命名慣例)一節。

對表單構造器呼叫輔助方法，和對 Model 物件上呼叫的效果相同。但不需要指定編輯的物件，因為編輯的物件即表單構造器。

使用 `fields_for` 輔助方法也可以達到上面的效果，但不會產生出 `<form>` 標籤。同個表單用來編輯多個 Model 物件時很有用。譬如 `Person` Model 有個關聯的 `ContactDetail` Model，下面的表單可以同時建立初兩個 Model 的物件：

```erb
<%= form_for @person, url: {action: "create"} do |person_form| %>
  <%= person_form.text_field :name %>
  <%= fields_for @person.contact_detail do |contact_details_form| %>
    <%= contact_details_form.text_field :phone_number %>
  <% end %>
<% end %>
```

會產生出以下輸出：

```html
<form accept-charset="UTF-8" action="/people/create" class="new_person" id="new_person" method="post">
  <input id="person_name" name="person[name]" type="text" />
  <input id="contact_detail_phone_number" name="contact_detail[phone_number]" type="text" />
</form>
```

`fields_for` 給出的物件也是個表單構造器，和 `form_for` 一樣（實際上 `form_for` 內部呼叫的是 `fields_for`）。

### 記錄自動識別技術

如使用者可以直接操作 `Article` Model，則依據 Rails 開發的最佳實踐，應將 `Article` 視為**一個資源**。

```ruby
resources :articles
```

TIP: 宣告成資源有許多副作用。見 [Rails 路由：深入淺出〈資源式路由：Rails 的預設路由〉](routing.html#資源式路由：rails-的預設路由)來瞭解更多關於設定與使用資源的資訊。

處理 RESTful 資源時，若用了記錄自動識別技術，則呼叫 `form_for` 便很容易使用。簡單的說，可以只把 Model 實體傳進去，Rails 會自己處理好 Model 名稱與其它內容：

```ruby
## Creating a new article
# long-style:
form_for(@article, url: articles_path)
# same thing, short-style (record identification gets used):
form_for(@article)

## Editing an existing article
# long-style:
form_for(@article, url: article_path(@article), html: {method: "patch"})
# short-style:
form_for(@article)
```

無論記錄是否存在，使用簡短風格的 `form_for` 呼叫都長得一樣。記錄自動識別技術很聰明，會對紀錄呼叫 `record.new_record?` 來檢查是否是新紀錄。也能根據物件的類別，選出正確的送出路徑與名稱。

Rails 也會自動幫表單設定適當的 `class` 與 `id`。新增文章的表單 `id` 與 `class` 可能是 `new_article`。若編輯 ID 為 23 的文章，`class` 則會設為 `edit_article`、`id` 設為 `edit_article_23`。為求行文簡潔，這些屬性後文忽略不計。

WARNING: 使用 STI（單表繼承）時，如父類宣告為資源，則子類便不能依賴記錄自動識別技術。必須要明確指定 Model 的名稱、`:url` 以及 `:method`。

#### 處理命名空間

若建立的路由有命名空間，`form_for` 也有對應的簡寫形式。假設應用程式有 `admin` 命名空間：

```ruby
form_for [:admin, @article]
```

會在 `admin` 命名空間裡，建立出對 `ArticlesController` 提交的表單，送出結果到 `admin_article_path(@article)`（假設是更新文章的情況）。若有多層命名空間，語法類推：

```ruby
form_for [:admin, :management, @article]
```

關於 Rails 路由系統的更多資訊以及有關的慣例，請參見：[Rails 路由：深入淺出]。

### PATCH、PUT、DELETE 表單的工作原理

Rails 框架鼓勵用 RESTful 風格來設計應用程式，這表示會用到許多 “PATCH” 與 “DELETE” 請求（而不只是 GET 與 POST）。但多數瀏覽器 **只支援** 用 GET 或 POST 來送出表單。

Rails 透過使用 POST 請求模擬出其它 HTTP 方法來解決這個問題。在表單裡新增一個 `name` 為 `_method`、`value` 為真正希望使用的方法名稱的隱藏輸入：

```ruby
form_tag(search_path, method: "patch")
```

輸出：

```html
<form accept-charset="UTF-8" action="/search" method="post">
  <input name="_method" type="hidden" value="patch" />
  <input name="utf8" type="hidden" value="&#x2713;" />
  <input name="authenticity_token" type="hidden" value="f755bb0ed134b76c432144748a6d4b7a7ddf2b71" />
  ...
</form>
```

解析 POST 過來的資料時，Rails 會將特殊的 `_method` 參數考慮進去，以 `value` 的值作為 HTTP 方法（上例為 “PATCH”）。

輕鬆製作下拉式選單
-----------------------------

HTML 的下拉選單需要大量的 Markup（一個選項就要一個 `OPTION` 元素），非常適合動態產生這些選項。

以下是可能的 Markup：

```html
<select name="city_id" id="city_id">
  <option value="1">Lisbon</option>
  <option value="2">Madrid</option>
  ...
  <option value="12">Berlin</option>
</select>
```

這裡有一組給使用者選擇的城市清單。應用程式內部只需要處理各選項的 ID，因此把 `option` 的 `value` 設為 ID。接著看 Rails 如何化繁為簡。

### Select 與 Option 標籤

最通用的輔助方法是 `select_tag`，從名字就可以看出來，是用來產生封裝了選項字串的 `select` 標籤：

```erb
<%= select_tag(:city_id, '<option value="1">Lisbon</option>...') %>
```

這只是剛開始而已，上面把字串封裝在 `select_tag` 裡面，無法動態生成 `option` 標籤，於是有了 `options_for_select`：

```html+erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...]) %>

輸出：

<option value="1">Lisbon</option>
<option value="2">Madrid</option>
...
```

`options_for_select` 的第一個參數是選項組成的嵌套陣列，每個選項有兩個元素，選項文字（城市名稱）與選項數值（城市 ID）。選項數值會送給 Controller 處理。通常會是資料庫對應物件的 ID，但也不強迫一定要用 ID。

瞭解之後，可以結合 `select_tag` 與 `options_for_select` 來實作完整的 Markup：

```erb
<%= select_tag(:city_id, options_for_select(...)) %>
```

`options_for_select` 的第二個參數可以設定預設選項。

```html+erb
<%= options_for_select([['Lisbon', 1], ['Madrid', 2], ...], 2) %>

輸出：

<option value="1">Lisbon</option>
<option value="2" selected="selected">Madrid</option>
...
```

Rails 在發現屬性值與 `options_for_select` 第二個參數的值相同時，便會給該選項新增 `selected` 屬性。

TIP: `options_for_select` 的第二個參數，必須與需要選中選項的值完全相等。特別注意若該選項的值是整數 `2`，`options_for_select` 第二個參數的值便不可以是 `"2"`，必須是 `2`。需要注意的是從 `params` 取出的數值都是字串。

可以用 Hash 給每個選項加上任意的屬性：

```html+erb
<%= options_for_select(
  [
    ['Lisbon', 1, { 'data-size' => '2.8 million' }],
    ['Madrid', 2, { 'data-size' => '3.2 million' }]
  ], 2
) %>

輸出：

<option value="1" data-size="2.8 million">Lisbon</option>
<option value="2" selected="selected" data-size="3.2 million">Madrid</option>
...
```

### 處理 Models 的下拉選單

多數情況下表單控件與特定的資料庫模型綁在一起，可能會好奇 Rails 有沒有針對 Model 提供 的輔助方法可用呢？答案是有。針對 Model 的輔助方法和其它的表單輔助方法相同，名稱去掉 `select_tag` 的 `_tag` 即可：

```ruby
# controller:
@person = Person.new(city_id: 2)
```

```erb
# view:
<%= select(:person, :city_id, [['Lisbon', 1], ['Madrid', 2], ...]) %>
```

注意 `select` 的第三個參數，由選項組成的陣列，跟傳給 `options_for_select` 的參數一樣。好處是無需煩惱預選的城市是那個，Rails 會自己去讀取 `@person.city_id` 來決定預選城市是那個。

和其它輔助方法一樣，對表單構造器也可以使用，語法是：

```erb
# select on a form builder
<%= f.select(:city_id, ...) %>
```

`select` 也接受區塊：

```erb
<%= f.select(:city_id) do %>
  <% [['Lisbon', 1], ['Madrid', 2]].each do |c| -%>
    <%= content_tag(:option, c.first, value: c.last) %>
  <% end %>
<% end %>
```

上例 Person 與 City Model 存在 `belongs_to` 關係，在使用 `select` 時必須傳入 foreign key，否則會報這個錯誤：`ActiveRecord::AssociationTypeMismatch`。

若使用 `select` （或其它類似的輔助方法，像是 `collection_select`、`select_tag`）來設定 `belongs_to` 關聯，則必須傳入外鍵的名稱（上例須傳入 `city_id`），而不是關聯名稱。若指定的是 `city` 而不是 `city_id`，把 `params` 傳給 `Person.new` 或 `Person.update` 時，Active Record 會拋出錯誤： `ActiveRecord::AssociationTypeMismatch: City(#17815740) expected, got String(#1138750)`。換句話說也就是表單輔助方法只能編輯屬性。應該要注意讓使用者直接編輯外鍵，所存在的安全性風險。

### 從任何物件集合產生選項

用 `options_for_select` 來產生選項，需要先建立陣列，陣列裡有選項文字與數值。但要是已經有了 City Model（假設是個繼承自 Active Record 的 Model），想要直接從 Model 的實體產生出這些選項該怎麼做？解法之一是迭代這些物件，產生出嵌套的陣列：

```erb
<% cities_array = City.all.map { |city| [city.name, city.id] } %>
<%= options_for_select(cities_array) %>
```

這個方法完美可行，但 Rails 提供更簡潔的解法：`options_from_collection_for_select`。這個輔助方法接受一組任意物件的集合和兩個額外的參數：用來讀取選項 **數值** 與 **文字** 的方法名稱。

```erb
<%= options_from_collection_for_select(City.all, :id, :name) %>
```

從名字可以看出來，`options_from_collection_for_select` 只會產生出 `option` 標籤。要產生出會動的 `select`，需要與 `select_tag` 一起使用。就跟 `options_for_select` 需要與 `select_tag` 同時使用的情況相同。在處理 Model 物件時，`select` 結合了 `select_tag` 與 `options_for_select`；`collection_select` 則結合了 `select_tag` 與 `options_from_collection_for_select`。

```erb
<%= collection_select(:person, :city_id, City.all, :id, :name) %>
```

和其他輔助方法一樣，若想在 form builder 的作用在 `@person` 物件裡使用 `collection_select`，應當這麼寫：

```erb
<%= f.collection_select(:city_id, City.all, :id, :name) %>
```

複習一下，`options_from_collection_for_select` 與 `collection_select` 的關係，和 `options_for_select` 與 `select` 之間的關係一樣。

NOTE: 傳給 `options_for_select` 的陣列需要先傳 `name`，再傳 `id`；而 `options_from_collection_for_select` 則是先傳 `id`，再傳 `name`。

### 時區與國家選單

要完善利用 Rails 支援的時區功能，首先要詢問使用者所在的時區為何。要詢問時區得先產生所有的時區選項，再傳給 `collection_select` 來產生選單，但可以直接使用 `time_zone_select` 輔助方法，已經包裝好了：

```erb
<%= time_zone_select(:person, :time_zone) %>
```

還有一個 `time_zone_options_for_select` 輔助方法，這個的客製性更高。關於這個方法的使用方法，請查閱 API 文件，來了解 `time_zone_select` 與 `time_zone_options_for_select` 可用的參數有那些。

Rails 曾有過 `country_select` 輔助方法，用來選擇國家。但已經抽出來變成 [country_select](https://github.com/stefanpenner/country_select) 套件。使用這個套件時，請注意清單裡的國家名稱，有些國家有列在清單裡、有些沒有、有些有爭議。這也是為什麼 Rails 不內建這個功能的原因。

日期與時間的表單輔助方法
--------------------------------

可選擇不用會產生出 HTML5 日期與時間輸入欄位的輔助方法，而使用替代的日期與時間輔助方法。這些日期與時間方法和其它的表單輔助方法主要有以下兩點不同：

* 日期與時間不代表單一的 `input` 元素，而是多個 `input`，每個有每個的用途（年份、月份、日等）。所以 `params` 裡的日期與時間不會是個單獨的數值。
* 其它的表單輔助方法用 `_tag` 來區分，這個方法是個準方法，或是針對 Model 物件的輔助方法。而日期與時間的輔助方法有：`select_date`、`select_time` 以及 `select_datetime` 是準方法；而 `date_select`、`time_select` 以及 `datetime_select` 則是針對 Model 物件的輔助方法。

準方法和針對 Model 物件的方法，都會針對不同的時間單位（年、月、日等）來建出選單。

### 準方法

`select_*` 家族的輔助方法，第一個參數接受的是日期的實體，`Date`、`Time` 或 `DateTime`，用來作為目前選中的日期。第一個參數可以忽略，預設會選擇當下日期。舉個例子：

```erb
<%= select_date Date.today, prefix: :start_date %>
```

輸出（省略選項數值，保持簡單）：

```html
<select id="start_date_year" name="start_date[year]"> ... </select>
<select id="start_date_month" name="start_date[month]"> ... </select>
<select id="start_date_day" name="start_date[day]"> ... </select>
```

以上的輸入送出時會存在 `params[:start_date]`，以散列表的形式儲存，鍵有 `:year`、`:month` 以及 `day`。要獲得實際的 `Time` 或 `Date` 物件，可以將時間各個單位取出來，傳給適當的建構子，參考下例：

```ruby
Date.civil(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
```

上例的 `:prefix` 選項為 `:start_date`，是時間單位存在 `params` 的鍵名。沒給的話預設值是 `date`。

### 給 Model 物件用的方法

`select_date` 與 Active Record 配合的不好，因為 Active Record 期望每個 `params` 的元素，都對應到一個屬性。而 Model 物件的日期與時間輔助方法，會採用特殊的名稱來送出參數。Active Record 看到這些特殊名稱的參數時，便知道要將這些參數結合起來，傳給欄位類型的建構子。譬如：

```erb
<%= date_select :person, :birth_date %>
```

輸出（省略選項數值，保持簡單）：

```html
<select id="person_birth_date_1i" name="person[birth_date(1i)]"> ... </select>
<select id="person_birth_date_2i" name="person[birth_date(2i)]"> ... </select>
<select id="person_birth_date_3i" name="person[birth_date(3i)]"> ... </select>
```

產生出來的 `params` ：

```ruby
{'person' => {'birth_date(1i)' => '2008', 'birth_date(2i)' => '11', 'birth_date(3i)' => '22'}}
```

`params` 傳給 `Person.new` 或 `Person.update` 時，Active Record 會注意到這些參數名稱，要一起傳進來，來產生 `birth_date` 屬性，並根據字尾的資訊（`ni`），來決定傳給 `Date.civil` 的順序。

### 通用選項

這兩個家族的輔助方法，內部使用同一組核心功能，來產生 `select` 標籤，因此接受的選項大致相同。特別要提 Rails 預設會產生前後五年的年份。若這個範圍不夠用，`:start_year` 以及 `:end_year` 選項可以修改。可用選項更詳細的清單，請參考 [API 文件](http://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html)。

經驗法則表示，處理 Model 物件使用 `date_select`、其它情況用 `select_date`，像是用來過濾日期的搜尋表單。

NOTE: 內建的日期選單不太好用，無法幫助使用者處理日期與星期幾這個問題。

### 單一時間單位

有時只需顯示日期的某個部分，像年或月。Rails 提供一系列的輔助方法：`select_year`、`select_month`、`select_day`、`select_hour`、`select_minute` 以及 `select_second`。這些輔助方法的使用方式非常直觀，產生出來的 `input`，`name` 屬性預設會產生以時間單位命名的（譬如 `select_year` 產生出來的 `select`，`name` 為 `year`，以此類推）。這可以透過 `:field_name` 選項修改。`:prefix` 選項和 `select_date` 與 `select_time` 裡的用途相同，預設值也相同。


這些輔助方法的第一個參數指定要選中的數值，可以是 `Date`、`Time` 或 `DateTime` 的實體，或是數值也可以，對應的時間單位會被選中，譬如：

```erb
<%= select_year(2009) %>
<%= select_year(Time.now) %>
```

若今年是 2009 年，上面兩種用法的輸出相同，使用者選的數值可以在 `params[:date][:year]` 取出。

檔案上傳
--------

常見的任務是上傳檔案，舉凡使用者的圖片或需要處理的 CSV。檔案上傳最重要要記住的一點是，表單的編碼必須是 `"multipart/form-data"`。若使用 `form_for`，已經自動設定好了。若使用 `form_tag`，則必須自己設定，以下是表單上傳檔案的兩個例子：

```erb
<%= form_tag({action: :upload}, multipart: true) do %>
  <%= file_field_tag 'picture' %>
<% end %>

<%= form_for @person do |f| %>
  <%= f.file_field :picture %>
<% end %>
```

Rails 提供成對的輔助方法：準方法 `file_field_tag` 以及供 Model 物件使用的 `file_field`。這兩個輔助方法與其它表單輔助方法的差別在於無法設定預設值，因為預設值在這沒有意義。第一個例子，使用 `file_field_tag` 上傳的檔案會存在 `params[:picture]`，而 `file_field` 上傳的檔案則放在 `params[:person][:picture]`。

### 究竟上傳了什麼

`params` Hash 裡的物件，是 `IO` 子類別的實體。取決於上傳的檔案大小，會是 `StringIO` 或存在臨時檔案的 `File` 實體。兩種都會有 `original_filename` 屬性，記錄使用者電腦裡的檔案名稱；以及 `content_type` 屬性，記錄了上傳檔案的 `MIME` 類型。以下程式碼片段將上傳的內容存在 `#{Rails.root}/public/uploads`，使用原始上傳的檔名存放（假設使用前例 `form_for` 的表單來上傳）。

```ruby
def upload
  uploaded_io = params[:person][:picture]
  File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
    file.write(uploaded_io.read)
  end
end
```

一旦檔案上傳成功，有許多事情可以做。譬如把檔案存到別的地方（硬碟、Amazon S3 等）；或把檔案與 Model 關聯起來；縮放圖片檔案、產生縮圖等。這些事情超出了本文的範疇，但有許多專門設計的函式庫來協助完成這些任務。其中兩個不錯也比較多人知道的是 [CarrierWave](https://github.com/jnicklas/carrierwave) 以及 [Paperclip](https://github.com/thoughtbot/paperclip)。

NOTE: 若使用者沒有選擇檔案，對應的參數會是空字串。

### 處理 Ajax

要非同步的上傳檔案，不像其它的方法那麼簡單，像 `form_for` 只要加個 `remote: true` 即可。Ajax 表單的序列化由跑在瀏覽器的 JavaScript 處理，由於 JavaScript 無法從硬碟讀取檔案，檔案則無法上傳。最常見的解法是使用隱藏的 iframe，作為表單送出的目的地。

客製化表單構造器
--------------

如前所述，由 `form_for` 與 `fields_for` 給出的物件，是 `FormBuilder` （或子類）的實體。表單構造器封裝了單一物件的顯示。當然可以如往常一樣使用輔助方法，也可以繼承 `FormBuilder`，再往裡面新增輔助方法。譬如：

```erb
<%= form_for @person do |f| %>
  <%= text_field_with_label f, :first_name %>
<% end %>
```

可以替換成

```erb
<%= form_for @person, builder: LabellingFormBuilder do |f| %>
  <%= f.text_field :first_name %>
<% end %>
```

藉由定義 `LabellingFormBuilder` 類別：

```ruby
class LabellingFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options={})
    label(attribute) + super
  end
end
```

若很常需要使用這個功能，可以定義一個 `labeled_form_for` 輔助方法，來自動代入 `builder: LabellingFormBuilder` 選項：

```ruby
def labeled_form_for(record, options = {}, &block)
  options.merge! builder: LabellingFormBuilder
  form_for record, options, &block
end
```

表單構造器也決定了下面這行程式碼的行為：

```erb
<%= render partial: f %>
```

若 `f` 是 `FormBuilder` 的實體，則會算繪（render）`form` 這個部分頁面（partial），並把傳入的 `f` 設定成表單構造器。若表單構造器是 `LabellingFormBuilder` 的實體，則會算繪 `labelling_form` 這個部分頁面。

理解參數命名慣例
--------------

如前一節所見，表單的數值可以在 `params` 的第一層，或是嵌套在 Hash 裡。舉例來說，`Person` Model 對應的 Controller `create` 動作裡，`params[:person]` 這個 Hash，會存放建立 `person` 所需的屬性。`params` Hash 也可以包含陣列、陣列裡有 Hash 等都可以。

HTML 表單基本上不知道資料的結構，只是產生出純字串組成的 name-value 對。應用程式裡的陣列與 Hash，是透過 Rails 參數的命名慣例所產生。

TIP: 可能會發現在 Console 裡試試這些例子，可以瞭解得比較快。直接像下例這樣呼叫 Rack 的參數即可：

```ruby
Rack::Utils.parse_query "name=fred&phone=0123456789"
# => {"name"=>"fred", "phone"=>"0123456789"}
```

### 基本結構

兩個基本結構是陣列與 Hash。Hash 取值的方法和 `params` 相同。假設表單的內容為：

```html
<input id="person_name" name="person[name]" type="text" value="Henry"/>
```

則 `params` 的內容為：

```erb
{'person' => {'name' => 'Henry'}}
```

在 Controller 可以用 `params[:person][:name]` 來取出表單送出的數值。

Hash 可以多層嵌套，如：

```html
<input id="person_address_city" name="person[address][city]" type="text" value="New York"/>
```

產生的 `params` Hash：

```ruby
{'person' => {'address' => {'city' => 'New York'}}}
```

通常 Rails 會忽略重複的參數。若參數名稱有中括號，則會被放在陣列裡。若想使用者能夠輸入多組電話號碼，可以使用下面這個表單：

```html
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
<input name="person[phone_number][]" type="text"/>
```

則 `params[:person][:phone_number]` 會是個陣列。

### 結合起來

陣列與 Hash 可以混合使用。舉個例子，Hash 的一個元素可能像前面的例子一樣，是個陣列；或是可以有一個陣列，裡面存 Hash。下例是用來新建多筆地址的表單：

```html
<input name="addresses[][line1]" type="text"/>
<input name="addresses[][line2]" type="text"/>
<input name="addresses[][city]" type="text"/>
```

則 `params[:addresses]` 會是裡面有 Hash 的陣列，每個 Hash 的鍵有 `line1`, `line2` 以及 `city`。Rails 在目前的 Hash 發現有同樣的輸入時，會新建 Hash 來存放。

但有個限制，Hash 可以隨意嵌套，但陣列只能嵌套一次。陣列通常可以用 Hash 取代，譬如可以用 Hash 組成的 Model 物件來取代陣列組成的 Model 物件，Hash 的鍵是 `id`、陣列的索引、以及其它的參數。

WARNING: 陣列參數與 `check_box` 輔助方法配合的不好。根據 HTML 規範，沒選中的多選方框不會送出值。但多選方框總是送出值會比較方便。`check_box` 透過建立一個同名的隱藏輸入來處理。若多選方框沒有被勾選，則只會送出隱藏輸入；若勾選了多選方框，則會將隱藏輸入與勾選的值一起送出，但勾選的值優先權比較高。處理陣列參數時，重複的送出會使 Rails 困惑，因為 Rails 見到重複的輸入，就會建立一個新的陣列。使用 `check_box_tag` 或用 Hash 取代陣列是推薦的做法。

### 使用表單輔助方法

前一節完全沒用到 Rails 的表單輔助方法。自己手寫 `input` 再直接傳給 `text_field_tag` 沒有問題。但 Rails 提供了更抽象的方法。這裡介紹 `form_for` 與 `fields_for`，以及 `:index` 選項。

可能會想要有地址表單，裡面有一組可編輯的欄位，分別編輯地址的各個部分。

```erb
<%= form_for @person do |person_form| %>
  <%= person_form.text_field :name %>
  <% @person.addresses.each do |address| %>
    <%= person_form.fields_for address, index: address.id do |address_form|%>
      <%= address_form.text_field :city %>
    <% end %>
  <% end %>
<% end %>
```

假設 `person` 有兩個地址（`id` 分別是 23 與 `45`），輸出會像是：

```html
<form accept-charset="UTF-8" action="/people/1" class="edit_person" id="edit_person_1" method="post">
  <input id="person_name" name="person[name]" type="text" />
  <input id="person_address_23_city" name="person[address][23][city]" type="text" />
  <input id="person_address_45_city" name="person[address][45][city]" type="text" />
</form>
```

產生出的 `params`：

```ruby
{'person' => {'name' => 'Bob', 'address' => {'23' => {'city' => 'Paris'}, '45' => {'city' => 'London'}}}}
```

Rails 知道所有的 `input` 皆屬於 `person` Hash，因為對 `person_form` 呼叫了 `fields_for`。透過指定 `:index` 選項 `index: address.id`，可以告訴 Rails，`input` 的 `name` 不要命名為 `person[address][city]`，而是在 `address` 與 `city` 之間插入索引值（放在中括號內）。通常這很有用，因為可以簡單的找出要修改的地址記錄是那個。`:index` 的值可以是其它有意義的屬性，字串，甚至是 `nil` 也可以（`nil` 會建立一個陣列參數出來）。

要產生更複雜的嵌套，可以明確指定 `input` `name` 的第一個部分（`person[address]`）：

```erb
<%= fields_for 'person[address][primary]', address, index: address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

建立出來的輸入：

```html
<input id="person_address_primary_1_city" name="person[address][primary][1][city]" type="text" value="bologna" />
```

一個通用的規則是，最後的 `input` `name` 是傳給 `fields_for` 或 `form_for` 的名字，加上索引值，再加上屬性名稱。也可以直接將 `:index` 選項傳給像是 `text_field` 的輔助方法，但這樣比較繁瑣，在表單構造器一起指定來減少重複。

忽略 `:index` 選項的簡寫是，在傳給 `form_for` 或 `fields_for` 的名稱後面加上一個中括號。這與指定 `index: address` 的效果相同：

```erb
<%= fields_for 'person[address][primary][]', address do |address_form| %>
  <%= address_form.text_field :city %>
<% end %>
```

會產生與前例相同的輸出。

送出至外部資源的表單
---------------------------

Rails 的表單輔助方法，也可以用來打造送出資料到外部資源的表單。但需要給資源指定一個 `authenticity_token`，可以使用 `:authenticity_token` 選項來指定：

```erb
<%= form_tag 'http://farfar.away/form', authenticity_token: 'external_token' do %>
  Form contents
<% end %>
```

某些時候在送出資料到外部資源時，像是付款閘到。可以使用的欄位受外部 API 限制，還有可能不需要 `authenticity_token`，此時將 `:authenticity_token` 設為 `false` 即可：

```erb
<%= form_tag 'http://farfar.away/form', authenticity_token: false do %>
  Form contents
<% end %>
```

同樣的技術 `form_for` 也適用：

```erb
<%= form_for @invoice, url: external_url, authenticity_token: 'external_token' do |f| %>
  Form contents
<% end %>
```

不需要 `authenticity_token` 的情況：

```erb
<%= form_for @invoice, url: external_url, authenticity_token: false do |f| %>
  Form contents
<% end %>
```

打造複雜表單
-----------

許多應用程式表單不僅是編輯單一物件這麼簡單。例如建立 `person` 時，可能想讓使用者（在同一個表單）建立出多筆地址記錄（住家地址、工作地址等）。之後在編輯 `person` 時，使用者應該要能夠新增、刪除或修改地址。

### Model 部分

Active Record 在 Model 層級提供這樣的支援，請用 `accepts_nested_attributes_for` 方法：

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  accepts_nested_attributes_for :addresses
end

class Address < ActiveRecord::Base
  belongs_to :person
end
```

會建出一個 `Person#addresses_attributes=` 方法，用來新建、更新與刪除地址。

### 嵌套表單

下面的表單允許使用者用 `Person` 的實體來建立地址。

```html+erb
<%= form_for @person do |f| %>
  Addresses:
  <ul>
    <%= f.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>

        <%= addresses_form.label :street %>
        <%= addresses_form.text_field :street %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

當關聯接受嵌套屬性時，`fields_for` 會對關聯的每個元素，執行 `fields_for` 的區塊。若 `person` 沒有地址，便不執行 `fields_for` 區塊。常見的做法是在 Controller 建一個或多個空的子元素，這樣只少有一組欄位會顯示給使用者。下例會在新建 `person` 的表單產生兩組地址欄位，

```ruby
def new
  @person = Person.new
  2.times { @person.addresses.build}
end
```

`fields_for` 給出一個表單構造器。參數的名稱要與 `accepts_nested_attributes_for` 指定的相同。舉個例子，建立有兩組地址的使用者，送出的參數看起來會像是：

```ruby
{
  'person' => {
    'name' => 'John Doe',
    'addresses_attributes' => {
      '0' => {
        'kind' => 'Home',
        'street' => '221b Baker Street'
      },
      '1' => {
        'kind' => 'Office',
        'street' => '31 Spooner Street'
      }
    }
  }
}
```

`:addresses_attributes` Hash 的鍵不重要，每個地址的鍵不要重複就好。

若關聯物件已經儲存了，`fields_for` 會自動產生一個隱藏輸入，`id` 是該記錄的 `id`。可以傳入 `include_id: false` 給 `fields_for` 來禁用這個行為。可能會想要禁止產生隱藏輸入，因為自動產生的輸入擺放的位置不對，導致 HTML 不合法；或者是使用的 ORM，子物件沒有 `id`。

### Controller 部分

通常需要在傳給 Model 之前，先在 Controller [過濾參數](action_controller_overview.html#strong-parameters)：

```ruby
def create
  @person = Person.new(person_params)
  # ...
end

private
  def person_params
    params.require(:person).permit(:name, addresses_attributes: [:id, :kind, :street])
  end
```

### 移除物件

可以透過傳入 `allow_destroy: true` 給 `accepts_nested_attributes_for`，來允許使用者刪除關聯物件。

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  accepts_nested_attributes_for :addresses, allow_destroy: true
end
```

若屬性組成的 Hash 的鍵有 `_destroy`，值是 `1` 或 `true`，則物件會被刪除。下面這個表單允許使用者刪除地址：

```erb
<%= form_for @person do |f| %>
  Addresses:
  <ul>
    <%= f.fields_for :addresses do |addresses_form| %>
      <li>
        <%= addresses_form.check_box :_destroy%>
        <%= addresses_form.label :kind %>
        <%= addresses_form.text_field :kind %>
        ...
      </li>
    <% end %>
  </ul>
<% end %>
```

不要忘記更新 Controller 過濾參數的名單，要把 `_destroy` 加進來：

```ruby
def person_params
  params.require(:person).
    permit(:name, addresses_attributes: [:id, :kind, :street, :_destroy])
end
```

### 避免空的紀錄

忽略使用者沒有填的欄位通常很有用。可以透過傳給 `accepts_nested_attributes_for` 一個 `:reject_if` `proc` 來辦到。這個 `proc` 會在每個屬性送出時呼叫。若 `proc` 回傳 `flase`，則 Active Record 不會為這組 Hash 建立關聯物件。下面這個例子只有在有給出 `kind` 屬性時，才會建立地址：

```ruby
class Person < ActiveRecord::Base
  has_many :addresses
  accepts_nested_attributes_for :addresses, reject_if: lambda {|attributes| attributes['kind'].blank?}
end
```

有一個方便的符號可以用：`:all_blank`，會建立一個 `proc`，會拒絕為有任何屬性為空（ `_destroy` 屬性除外）的 Hash 建立物件。

### 動態添加欄位

與其一開始就算繪多組地址，不如加入一個按鈕 `Add new address`，讓使用者自己決定什麼時候要新增一組地址。但 Rails 不支援這個功能。建立一組新的欄位時，要確保關聯陣列的鍵是獨一無二的。在 JavaScript 使用目前的日期是常見的做法。
