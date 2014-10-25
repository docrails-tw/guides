Action Controller 概覽
==========================

本篇介紹 Controller 的工作原理、Controller 如何與應用程式的請求（Request）週期結合在一起。

讀完本篇，您將了解：

* 如何透過 Controller 了解請求流程。
* 如何限制傳入 Controller 的參數。
* 資料存在 Session 或 Cookie 裡的應用場景。
* 如何在處理請求時，使用 Filters 來執行程式。
* 如何使用 Action Controller 內建的 HTTP 認證機制。
* 如何用串流方式將資料直接傳給使用者。
* 如何過濾應用程式 Log 裡的敏感資料。
* 如何在 Request 生命週期裡，處理可能拋出的異常。

----------------------------------------------------------------

Controller 的工作
--------------------------

Action Controller 是 MVC 的 C，Controller。一個請求進來，路由決定是那個 Controller 的工作後，便把工作指派給 Controller，Controller 負責處理該請求，給出適當的回應。幸運的是，Action Controller 把大部分的苦差事都辦好了，只需遵循一些簡單的規範來寫程式，事情便豁然開朗。

對多數按照 [REST](http://en.wikipedia.org/wiki/Representational_state_transfer) 規範來編寫的應用程式來說，Controller 的工作便是接收請求（開發者看不到），去 Model 讀或寫資料，再使用 View 來產生出 HTML。若 Controller 要處理別的事情，沒有問題，上面不過是 Controller 的主要功能。

Controller 因此可以想成是 Model 與 View 的中間人。負責替 Model 將資料傳給 View，讓 View 可以顯示資料給使用者。Controller 也將使用者更新或儲存的資料，存回 Model。

路由的詳細過程可以查閱 [Rails 路由：由表入裡](/routing.html)。

Controller 命名慣例
----------------------------

Rails Controller 的命名慣例是**最後一個單字以複數形式結尾**，但是也有例外，比如 `ApplicationController`。舉例來說：偏好 `ClientsController` 勝過 `ClientController`。偏好 `SiteAdminsController` 勝過 `SitesAdminsController` 等。

遵循慣例便可享受內建 Rails Router 的功能，如：`resources`、`resource` 路由等，而無需特地傳入 `:path`、`:controller` 選項，便可保持 URL 與路徑輔助方法的一致性。詳細內容請參考 [Rails 算繪與版型](/layouts_and_rendering.html)一篇。

NOTE: Controller 的命名慣例與 Model 的命名慣例不同，Model 命名慣例是**單數形式**。

動作即方法
-------------------

Controller 是從 `ApplicationController` 繼承而來的類別，但 Controller 其實和 Ruby 的類別相同，擁有許多動作（即 Ruby 的方法）。當應用程式收到請求時，Rails 的 Router 會決定這要交給那個 Controller 的那個 Action 來處理，接著 Rails 新建該 Controller 的實體，呼叫與動作同名的方法。

```ruby
class ClientsController < ApplicationController
  def new
  end
end
```

舉個例子，假設應用程式的使用者到 `/clients/new`，想要新建一位 `client`，Rails 會新建 `ClientsController` 的實體，並呼叫 `new` 來處理。注意 `new` 雖沒有內容，但 Rails 的預設行為會算繪（render） `new.html.erb`，除非 `new` 動作裡指定要做別的事。`new` 動作可透過 `Client.new`，為 View 提供實體變數 `@client`：

```ruby
def new
  @client = Client.new
end
```

詳情請參考 [Rails 算繪與版型](/layouts_and_rendering.html)一篇。

`ApplicationController` 繼承自 `ActionController::Base`，`ActionController::Base` 定義了許多有用的方法。本篇會提到一些，若是好奇到底有什麼方法可用，請參考 [ActionController::Base 的 API 文件](http://edgeapi.rubyonrails.org/classes/ActionController/Base.html)，或是閱讀 [ActionController::Base 的原始碼](https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/base.rb)。

只有公有方法，才可以被外部作為“動作”呼叫。所以輔助方法、濾動方法（Filter Methods），最好用 `protected` 或 `private` 隱藏起來。

參數
----------------

通常會想在 Controller 裡取得使用者傳入的資料，或是其他的參數。Web 應用程式有兩種參數。第一種是由 URL 的部份組成，這種叫做 “Query String 參數”。Query String 是 URL `?` 號後面的任何字串，通常是透過 HTTP `GET` 傳遞。第二種參數是 “POST 資料”。通常來自使用者在表單所填寫的資料。叫做 POST 資料的原因是，這種參數只能作為 HTTP POST 請求的一部分來傳遞。Rails 並不區分 Query String 參數或 POST 參數，兩者皆可在 Controller 裡取用，而它們都存在 `params` Hash：

```ruby
class ClientsController < ApplicationController
  # 使用了 Query String 參數，因為 Request 用的是
  # HTTP GET。URL 看起來會像是: /clients?status=activated
  def index
    if params[:status] == "activated"
      @clients = Client.activated
    else
      @clients = Client.inactivated
    end
  end

  # 使用了 POST 參數，參數很可能是從使用者送出的表單而來。
  # URL 看起來會像是: "/clients" (遵循 RESTful 慣例）。
  # 資料會放在請求的 Body 裡再送過來。
  def create
    @client = Client.new(params[:client])
    if @client.save
      redirect_to @client
    else
      # 覆寫預設的 `render` 行為，預設是 `render "create"`。
      render "new"
    end
  end
end
```

### Hash 與陣列參數

`params` Hash 不侷限於一維的 Hash，可以是嵌套結構，裡面可存陣列或嵌套的 Hash。

若想以陣列形式來傳遞參數，在鍵的名稱後方附加 `[]` 即可，如下所示：

```
GET /clients?ids[]=1&ids[]=2&ids[]=3
```

注意：上例 URL 會編碼為 `"/clients?ids%5B%5D=1&ids%5B%5D=2&ids%5B%5D=3"`，因為 `[]` 對 URL 來說是非法字元。多數情況下，瀏覽器會檢查字元是否合法，會自動對非法字元做編碼。Rails 收到時再自己解碼。但若是要手動發請求給伺服器時，要記得自己處理好這件事。

`params[:ids]` 現在會是 `["1", "2", "3"]`。注意！參數的值永遠是字串類型。Rails 不會試著去臆測或轉換類型。

NOTE: `params` 裡像是 `[]`、`[nil]` 或是 `[nil, nil, ...]` 基於安全考量，會自動替換成 `nil`。詳情請參考 [Rails 安全指南：產生不安全的查詢](/security.html#unsafe-query-generation)一節。

要送出 Hash 形式的參數，在中括號裡指定鍵的名稱：

```html
<form accept-charset="UTF-8" action="/clients" method="post">
  <input type="text" name="client[name]" value="Acme" />
  <input type="text" name="client[phone]" value="12345" />
  <input type="text" name="client[address][postcode]" value="12345" />
  <input type="text" name="client[address][city]" value="Carrot City" />
</form>
```

這個表單送出時，`params[:client]` 的值為:

```ruby
{
  "name" => "Acme",
  "phone" => "12345",
  "address" => {
    "postcode" => "12345", "city" => "Carrot City"
  }
}`
```

注意 `params[:client][:address]` 是嵌套的 Hash 結構。

`params` Hash 其實是 `ActiveSupport::HashWithIndifferentAccess` 的實體。`ActiveSupport::HashWithIndifferentAccess` 與一般 Hash 類似，不同之處是取出 Hash 的值時，鍵可以用字串與符號，即 `params[:foo]` 等同於 `params["foo"]`。

### JSON 參數

在寫 Web 服務的應用程式時，處理 JSON 格式的參數比其他種類的參數更好。若請求的 `"Content-Type"` 標頭檔（header）是 `"application/json"`，Rails 會自動將收到的 JSON 參數轉換好（將 JSON 轉成 Ruby 的 Hash），存至 `params` 裡。用起來與一般 Hash 相同。

舉個例子，若傳送的 JSON 參數如下：

```json
{ "company": { "name": "acme", "address": "123 Carrot Street" } }
```

則獲得的參數會是：

```ruby
params[:company] => { "name" => "acme", "address" => "123 Carrot Street" }
```

除此之外，如果開啟了 `config.wrap_parameters` 選項，或是在 Controller 呼叫了 `wrap_parameters`，則可忽略 JSON 參數的根元素。Rails 會以 Contorller 的名稱另起新鍵，將 JSON 內容轉換好存在這個鍵下面。所以上面的 JSON 參數可以這樣寫就好：


```json
{ "name": "acme", "address": "123 Carrot Street" }
```

傳給 `CompaniesController` 時，轉換好的參數會存在 `params[:company]`：

```ruby
{ name: "acme", address: "123 Carrot Street", company: { name: "acme", address: "123 Carrot Street" } }
```

關於如何鍵名稱的客製化，或針對某些特殊的參數執行 `wrap_parameters`，請查閱 [ActionController::ParamsWrapper 的 API 文件](http://edgeapi.rubyonrails.org/classes/ActionController/ParamsWrapper.html)。

NOTE: XML 的功能現已抽成 [actionpack-xml_parser](https://github.com/rails/actionpack-xml_parser) 這個 RubyGem。

### 路由參數

`params` Hash 永遠會有兩個鍵：`:controller` 與 `:action`，分別是當下呼叫的 Controller，與動作的名稱。但若想知道當下的 Controller 與動作名稱時，請使用 `controller_name` 與 `action_name`，不要直接從 `params` 裡取：

```ruby
controller.controller_name %>
controller.action_name %>
```

路由裡定義的參數也會放在 `params` 裡，像是 `:id`。

假設有一張 `Client` 的清單，`Client` 有兩種狀態，分別為啟用與停用兩種狀態。我們可以加入一條路由，來捕捉 `Client` 的狀態：

```ruby
get '/clients/:status' => 'clients#index', foo: 'bar'
```

這個情況裡，當使用者打開 `/clients/active` 這一頁，`params[:status]` 便會被設成 `"active"`，`params[:foo]` 也會被設成 `"bar"`，就像是我們原本透過 Query String 傳進去那樣。同樣的，`params[:action]` 也會被設成 `index`。

### `default_url_options`

可以設定預設用來產生 URL 的參數。首先在 Controller 定義一個叫做 `default_url_options` 的方法。這個方法必須回傳一個 Hash。鍵必須是 `Symbol` 類型，值為需要的內容：

```ruby
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

產生 URL 時會採用 `default_options` 所定義的選項，作為預設值。不過還是可以用 `url_for` 覆寫掉。

如果在 `ApplicationController` 定義 `default_url_options`，如上例。則產生所有 URL 的時候，都會傳入 `default_url_options` 內所定義的參數。`default_url_options` 也可以在特定的 Controller 裡定義，如此一來便只會影響該 Controller 所產生的 URL。

### Strong Parameters

原先大量賦值是由 Active Model 來處理，透過白名單來過濾不可賦值的參數。也就是得明確指定那些屬性可以賦值，避免掉不該被賦值的屬性被賦值了。有了 Strong Parameter 之後，這件工作交給 Action Controller 負責。

除此之外，還可以限制必須傳入那些參數。若是沒給入這些必要參數時，Rails 預先定義好的 `raise`/`rescue` 會處理好，回傳 400 Bad Request。

```ruby
class PeopleController < ActionController::Base
  # 會拋出 ActiveModel::ForbiddenAttributes 異常。
  # 因為做了大量覆值卻沒有明確的說明允許賦值的參數有那些。
  def create
    Person.create(params[:person])
  end

  # 若沒有傳入 :id，會拋出 ActionController::ParameterMissing 異常。
  # 這個異常會被 ActionController::Base 捕捉，並轉換成 400 Bad Request。
  def update
    person = current_account.people.find(params[:id])
    person.update!(person_params)
    redirect_to person
  end

  private
    # 使用 private 方法來封裝允許大量賦值的參數
    # 這麼做的好處是這個方法可以在 create 與 update 重複使用。
    # 同時可以這個方法也很容易擴展。
    def person_params
      params.require(:person).permit(:name, :age)
    end
end
```

#### 允許使用的純量值

給定：

```ruby
params.permit(:id)
```

若 `params` 有 `:id`，並且 `:id` 有允許使用的純量值。便可以通過白名單檢查，否則 `:id` 就會被過濾掉。這也是為什麼陣列、Hash 或任何其他的物件無法被注入。

允許的純量類型有：

`String`、`Symbol`、`NilClass`、`Numeric`、`TrueClass`、`FalseClass`、`Date`、`Time`、`DateTime`、`StringIO`、`IO`、`ActionDispatch::Http::UploadedFile` 以及
`Rack::Test::UploadedFile`。

`params` 裡需要允許賦值的參數是陣列形式怎麼辦？

```ruby
params.permit(id: [])
```

允許整個 Hash 裡的參數可以賦值，使用 `permit!`：

```ruby
params.require(:log_entry).permit!
```

`params` 裡的 `:log_entry` hash 以及裡面所有的子 Hash 此時都允許做大量賦值。**使用 `permit!` 要非常小心**，因為這允許了 Model 所有的屬性，都可以做大量賦值，要是之後 Model 新增了 `admin` 屬性而沒注意到 `permit!`，可能就會出問題了。

#### 嵌套參數

要允許嵌套參數做大量賦值，比如：

```ruby
params.permit(:name, { emails: [] },
              friends: [ :name,
                         { family: [ :name ], hobbies: [] }])
```

上面的宣告允許：`name`、`emails` 以及 `friends` 屬性。且 `emails` 會是陣列形式、`friends` 會是由 resource 組成的陣列，需要有 `name`、`hobbies` （必須是陣列形式）、以及 `family` （只允許有 `name`）。

#### 更多例子

可能也想在 `new` 動作裡使用允許的屬性。但這帶出了一個問題，無法對根元素使用 `require`。因為呼叫 `new` 的時候，資料根本還不存在，這時可以用 `fetch`：

```ruby
# 使用 `fetch` 你可以設定預設值，並使用
# Strong Parameters 的 API 來取出
params.fetch(:blog, {}).permit(:title, :author)
```

`accepts_nested_attributes_for` 允許基於 `id` 與 `_destroy` 參數，來 `update` 與 `destroy` 相關的記錄：

```ruby
# 允許 :id 與 :_destroy
params.require(:author).permit(:name, books_attributes: [:title, :id, :_destroy])
```

當 Hash 的鍵是整數時，處理的方式不大一樣。可以宣告屬性是子 Hash。在 `has_many` 的關聯裡使用 `accepts_nested_attributes_for` 時會得到以下類型的參數：

```ruby
# 白名單過濾下列資料
# {"book" => {"title" => "Some Book",
#             "chapters_attributes" => { "1" => {"title" => "First Chapter"},
#                                        "2" => {"title" => "Second Chapter"}}}}

params.require(:book).permit(:title, chapters_attributes: [:title])
```

#### Strong Parameters 處理不了的問題

Strong Parameter API 不是銀彈，無法處理所有關於白名單的問題。但可以簡單地將 Strong Parameter API 與你的程式混合使用，來對付不同的需求。

假想看看，想要給某個屬性加上白名單，該屬性可以包含一個 Hash，裡面可能有任何鍵。使用 Strong Parameter 無法允許有任何 key 的 Hash，但可以這麼做：

```ruby
def product_params
  params.require(:product).permit(:name, data: params[:product][:data].try(:keys))
end
```

Session
----------

應用程式為每位使用者都準備了一個 Session，可以儲存小量的資料，資料在請求之間都會保存下來。Session 僅在 Controller 與 View 裡面可以使用，Session 儲存機制如下：

* `ActionDispatch::Session::CookieStore` ─ 所有資料都存在用戶端。
* `ActionDispatch::Session::CacheStore` ─ 資料存在 Rails 的 Cache。
* `ActionDispatch::Session::ActiveRecordStore` ─ 資料使用 Active Record 存在資料庫（需要 `activerecord-session_store` RubyGem）。
* `ActionDispatch::Session::MemCacheStore` ─ 資料存在 memcached（這是遠古時代的實作方式，考慮改用 CacheStore 吧）。

所有的 Session 儲存機制都會使用一個 Cookie。在 Cookie 裡為每個 Session 存一個獨立的 Session ID。Session ID 必須要存在 Cookie 裡，因為 Rails 不允許在 URL 傳遞 Session ID（不安全）。

多數的儲存機制使用 Session ID 到伺服器上查詢 Session 資料，譬如到資料庫裡查詢。但有個例外，會把 Session 資料全部存在 Cookie，即 CookieStore 的儲存方式。優點是非常輕量，完全不用設定。存在 Cookie 的資料經過加密簽署，防止有心人士竄改。即便是擁有 Session 資料存取權的人，也無法讀取內容（內容經過加密）。如果 Cookie 的資料遭到修改，Rails 也不會使用這個資料。

CookieStore 大約可以存 4KB 的資料，其他儲存機制可以存更多，但通常 4KB 已經夠用了。不管用的是那種儲存機制，不建議在 Session 裡存大量資料。特別要避免將複雜的物件儲存在 Session 裡（除了 Ruby 基本物件之外的東西都不要存，比如 Model 的實體）。因為伺服器可能沒辦法在請求之間重新將物件還原，便會導致錯誤發生。

若使用者的 Session 沒有儲存重要的資料，或存的是短期的資料（比如只是用來顯示提示訊息）。可以考慮使用 `ActionDispatch::Session::CacheStore`。這會將 Session 存在應用程式所設定的快取裡。優點是利用現有的快取架構來儲存，不用額外管理，或是設定 Session 的儲存機制。缺點是生命週期短、隨時可能會消失。

關於如何安全地儲存 Session，請閱讀 [Rails 安全指南：Session](/security.html#session) 一節。

如需不同的 Session 儲存機制，可以在 `config/initializers/session_store.rb` 裡設定：

```ruby
# 使用資料庫來存 Session，而不是使用預設的 Cookie 來存。
# 注意，不要存任何高度敏感的資料在 Session。
# （建立 Session 資料表："rails g active_record:session_migration"）
# Rails.application.config.session_store :active_record_store
```

簽署 Session 資料時，Rails 設了一個 Session 鍵（為 Cookie 的名字），這個名字可在 `config/initializers/session_store.rb` 裡修改：

```ruby
# 修改此文件時記得重新啟動 Server
Rails.application.config.session_store :cookie_store, key: '_your_app_session'
```

也可以傳入 `:domain` key，來指定 cookie 的 domain name：

```ruby
# 修改此文件時記得重新啟動 Server
Rails.application.config.session_store :cookie_store, key: '_your_app_session', domain: ".example.com"
```

Rails 替 CookieStore 設了一個 secret key，用來簽署加密 Session 資料。這個 key 可以在 `config/secrets.yml` 裡修改。

```ruby
# 修改此文件時記得重新啟動 Server

# Secret Key 用來簽署與認證 Cookie。
# Key 變了先前的 cookie 都會失效！

# 確保 Secret 至少有 30 個隨機字元，沒有一般的單字（防禦字典查表攻擊）。
# 可以使用 `rake secret` 來產生一個安全的 Secret Key.

# 如果要將程式碼公開，
# 不要公開這個檔案裡的 Secret。

development:
  secret_key_base: a75d...

test:
  secret_key_base: 492f...

# Repository 裡不要放 Production 的 Secret。
# 應該把 Secret 放在環境變數裡讀進來。
production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```

NOTE: 更改 `secret_key_base` 之後，先前簽署的 Session 都會失效。

### 存取 Session

在 Controller 可以透過 `session` 這個實體方法來存取 Session。

**注意：Session 是惰性加載的。若動作沒用到 Session，便不會載入 Session。若是不想用 Session，無需關掉 Session，不要用就好了。

Session 以類似於 Hash 的方式儲存（鍵值對）：

```ruby
class ApplicationController < ActionController::Base

  private

  # 用存在 Session 的 :current_user_id 來找到 User。
  # 這是 Rails 常見處理使用者登入的手法；
  # 登入時將使用者的 ID 存在 Session，登出時再清掉。
  def current_user
    @_current_user ||= session[:current_user_id] &&
      User.find_by(id: session[:current_user_id])
  end
end
```

要在 Session 裡存值，給 Hash 的鍵賦值即可：

```ruby
class LoginsController < ApplicationController
  # 建立“登入”，也就是“登入使用者”
  def create
    if user = User.authenticate(params[:username], params[:password])
      # 將使用者的 ID 存在 Session，供之後的 Request 使用。
      session[:current_user_id] = user.id
      redirect_to root_url
    end
  end
end
```

要從 Session 裡移掉數值，給想移除的鍵賦 `nil` 值即可：

```ruby
class LoginsController < ApplicationController
  def destroy
    # 將 user id 從 session 裡移除
    @_current_user = session[:current_user_id] = nil
    redirect_to root_url
  end
end
```

要將整個 session 清掉，使用 `reset_session` 方法。

### 提示訊息

提示訊息（Flash Message）是 Session 特殊的一部分，可以從一個請求傳遞（錯誤、提示）訊息到下個請求，下個請求結束後，便會自動清除提示訊息。

`flash` 的使用方式與 `session` 雷同，和操作一般的 Hash 一樣（實際上 `flash` 是 [FlashHash](http://edgeapi.rubyonrails.org/classes/ActionDispatch/Flash/FlashHash.html) 的實體）。

用登出作為例子，Controller 可以傳一個訊息，用來給下個請求顯示：

```ruby
class LoginsController < ApplicationController
  def destroy
    session[:current_user_id] = nil
    flash[:notice] = "成功登出了"
    redirect_to root_url
  end
end
```

注意也可以直接在 `redirect_to` 設定提示訊息：

```ruby
redirect_to root_url, notice: "You have successfully logged out."
redirect_to root_url, alert: "You're stuck here!"
redirect_to root_url, flash: { referral_code: 1234 }
```

上面的 `destroy` 動作會導向到應用程式的 `root_url`，導回到 `root_url` 後會顯示`"成功登出了"`的訊息。注意到提示訊息永遠在上個動作裡設定。


通常都會用 Flash 來顯示錯誤、提示訊息等，通常會在應用程式的版型檔案 `app/views/layout/application.html.erb`，加入提示訊息所需的 View：

```erb
<html>
  <!-- <head/> -->
  <body>
    <% flash.each do |name, msg| -%>
      <%= content_tag :div, msg, class: name %>
    <% end -%>

    <!-- more content -->
  </body>
</html>
```

如此一來，若動作有設定 `:notice` 或 `:alert` 訊息，View 便會自動顯示。

提示訊息的種類不侷限於 `:notice`、`:alert` 或 `:flash`，可以自己定義：

```erb
<% if flash[:just_signed_up] %>
  <p class="welcome">Welcome to our site!</p>
<% end %>
```

若想要提示訊息在請求之間保留下來，使用 `keep` 方法：

```ruby
class MainController < ApplicationController
  # 假設這個動作會回應 root_url
  # 但想要所有的請求都導到 UsersController#index
  # 若在此設定了提示訊息，接著 redirect，則無法保存提示訊息。
  # 可以用 flash.keep 將 flash 的值保存下來，供別的請求使用。
  def index
    # 保留整個 flash
    flash.keep

    # 也可以只保留提示訊息的 :notice 部分
    # flash.keep(:notice)
    redirect_to users_url
  end
end
```

#### `flash.now`

預設情況下，加入值至 `flash`，只能在下次請求可以取用，但有時會想在同個請求裡使用這些訊息。舉例來說，如果 `create` 動作無法儲存，想要直接 `render` `new`，這不會發另一個請求，但仍需要顯示訊息，這時候便可以使用 `flash.now`：

```ruby
class ClientsController < ApplicationController
  def create
    @client = Client.new(params[:client])
    if @client.save
      # ...
    else
      flash.now[:error] = "無法儲存 Client"
      render action: "new"
    end
  end
end
```

Cookies
----------

應用程式可以在客戶端儲存小量的資料，這種資料稱為 Cookie。Cookie 在請求之間是不會消失，可以用來存 Session。Rails 裡存取 Cookies 的非常簡單，`cookies`，用起來跟 `session` 類似，和 Hash 用法相同：

```ruby
class CommentsController < ApplicationController
  def new
    # 若是 Cookie 裡有存留言者的名字，自動填入。
    @comment = Comment.new(author: cookies[:commenter_name])
  end

  def create
    @comment = Comment.new(params[:comment])
    if @comment.save
      flash[:notice] = "感謝您的意見！"
      if params[:remember_name]
        # 選擇記住名字，則記下留言者的名稱。
        cookies[:commenter_name] = @comment.author
      else
        # 選擇不記住名字，刪掉 Cookie 裡留言者的名稱。
        cookies.delete(:commenter_name)
      end
      redirect_to @comment.article
    else
      render action: "new"
    end
  end
end
```

**注意 Session 是用賦 `nil` 值來清空某個鍵的值；Cookie 則要使用 `cookies.delete(:key)` 刪掉。**

Rails 也提供簽署 Cookie 與加密 Cookie，用來儲存敏感資料。簽署 Cookie 裡的數值會附上加密過的簽名，確保值沒有被竄改。加密 Cookie 不僅會在值附加簽名的基礎上再次加密，讓用戶端使用者無法讀取。詳細資料請閱讀 [Action Dispatch 的 API 文件](http://api.rubyonrails.org/classes/ActionDispatch/Cookies.html)

這兩種特殊的 Cookie 使用一個 Serializer，將數值序列化成字串，讀取時再反序列化回來。

指定使用的 Serializer：

```ruby
Rails.application.config.action_dispatch.cookies_serializer = :json
```

Rails 新版的預設 Serializer 是 `:json`。但為了與舊版應用程式裡的 Cookie 相容，沒特別指定 Serializer 時，會使用 `:marshal`。

也可以設成 `:hybrid`。讀到以 `Marshal` 序列化的 Cookie 時，會用 `:marshal` 來反序列化。並重新使用 `JSON` 格式寫回去。這在將現有應用程式的 Serializer 升級到 `:json` 時很有用。

使用自訂的 Serializer 也可以（必須要實作 `load` 與 `dump`）：

```ruby
Rails.application.config.action_dispatch.cookies_serializer = MyCustomSerializer
```

在使用 `:json` 或 `hybrid` Serializer 時，應該要注意到，不是所有的 Ruby 物件，都可以轉成 JSON。舉個例子，`Date` 與 `Time` 物件會被序列化成字串，Hash 的鍵也會被序列化成字串。

```ruby
class CookiesController < ApplicationController
  def set_cookie
    cookies.encrypted[:expiration_date] = Date.tomorrow # => Thu, 20 Mar 2014
    redirect_to action: 'read_cookie'
  end

  def read_cookie
    cookies.encrypted[:expiration_date] # => "2014-03-20"
  end
end
```

建議 Cookie 裡只存放簡單的資料（像是數字與字串）。

若必須存放複雜的物件，需要自己在接下來的請求裡手動轉換。

如果 Session 採用的是 CookieStore 儲存機制，則上面的規則， `session` 與 `flash` 同樣適用。

算繪 XML 與 JSON 資料
------------------------------

在 `ActionController` 裡算繪 `XML` 或是 `JSON` 真是再簡單不過了，看看下面這個用鷹架所產生出來的 Controller：

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @users}
      format.json { render json: @users}
    end
  end
end
```

注意這裡 `render` XML 的時候是寫 `render xml: @users`，而不是 `render xml: @users.to_xml`。如果 `render` 的物件不是字串的話，Rails 會自動呼叫 `to_xml`。

濾動器
----------

濾動器（Filter）是可在 Controller 動作執行前、後、之間所執行的方法。

濾動器可被 Controller 繼承，也就是在 `ApplicationController` 定義的濾動器，在整個應用程式裡都會執行該濾動器。

前置濾動器（Before Filter）可能會終止請求週期。常見的前置濾動器，像是執行某個動作需要使用者登入。則可以這麼定義濾動器方法：

```ruby
class ApplicationController < ActionController::Base
  before_action :require_login, only: [:admin]

  def admin
    # 管理員才可使用的...
  end

  private

  def require_login
    unless logged_in?
      flash[:error] = "這個區塊必須登入才能存取"
      redirect_to new_login_url # 終止請求週期
    end
  end
end
```

這個方法非常簡單，當使用者沒有登入時，將錯誤訊息存在 `flash` 裡，並轉向到登入頁。若前置濾動器執行了 `render` 或是 `redirect_to`，便不會執行 `admin` 動作。要是 before 濾動器之間互相有依賴，一個取消了，另一個也會跟著取消。

剛剛的例子裡，濾動器加入至 `ApplicationController`，所以在應用程式裡，只要是繼承 `ApplicationController` 的所有動作，都會需要登入才能使用。但使用者還沒註冊之前，怎麼登入？所以一定有方法可以跳過濾動器，`skip_before_action`：

```ruby
class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
end
```

現在 `LoginsController` 的 `new` 與 `create` 動作如先前一般工作，無需使用者登入。`:only` 選項用來決定這個濾動器只需要檢查那幾個動作，而 `:except` 選項則是決定這個濾動器不需要檢查那幾個動作。

### 後續濾動器與前後濾動器

除了有前置濾動器，也可以在動作結束後執行（後置濾動器，after filter），或者是動作前後之間執行（前後濾動器，around filter）。

後置濾動器與前置濾動器類似，但因為 `action` 已經執行完畢，所以後置濾動器可以存取即將要回給使用者的響應（Response）。後置濾動器無法終止請求週期，因為動作已經執行完畢，無法終止。不像前置濾動可以透過 `render` 或是 `redirect_to`，來終止動作的執行。

前後濾動器主要透過 `yield` 來負責執行相關的動作，跟 Rack 中間件的工作原理類似。

舉例來說，要給某個網站提交改動時，必須先獲得管理員同意，改動才會生效。管理員會需要某種類似預覽功能的操作，將此操作包在交易即可：

```ruby
class ChangesController < ApplicationController
  around_action :wrap_in_transaction, only: :show

  private

  def wrap_in_transaction
    ActiveRecord::Base.transaction do
      begin
        yield
      ensure
        raise ActiveRecord::Rollback
      end
    end
  end
end
```

注意前後濾動器包含了 `render`。需要特別說明的是，假設 View 會從資料庫讀取資料來顯示，在交易裡也會這麼做，如此一來便可達到預覽的效果。

響應也可以自己生，不需要用 `yield`。若是沒使用 `yield`，則 `show` 動作便不會被執行。

### 濾動器的其它使用方式

濾動器一般的使用方式是，先建立一個 `private` 方法，在使用 `*_action` 來針對是要在特定 `action` 前、後、之間執行該 `private` 方法。除了寫個方法，還有兩種方式可以達到濾動器的效果。

第一種是直接對 `*_action` 使用區塊。區塊接受 `controller` 作為參數，上面的 `require_login` 例子可以改寫為：

```ruby
class ApplicationController < ActionController::Base
  before_action do |controller|
    unless controller.send(:logged_in?)
      flash[:error] = flash[:error] = "這個區塊必須登入才能存取"
      redirect_to new_login_url
    end
  end
end
```

注意到這裡使用了 `send`，因為 `logged_in?` 方法是 `private`，濾動器不在 Controller 的作用域下執行。這種實作濾動器的方式不推薦使用，但在非常簡單的情況下可能有用。

第二種方式是使用類別，實際上使用任何物件都可以，只要物件有回應對的方法即可。用類別實作的好處是提高可讀性、重用性。舉個例子，上例可以改寫為：

```ruby
class ApplicationController < ActionController::Base
  before_action LoginFilter
end

class LoginFilter
  def self.before(controller)
    unless controller.send(:logged_in?)
      controller.flash[:error] = "這個區塊必須登入才能存取"
      controller.redirect_to controller.new_login_url
    end
  end
end
```

同樣這不是這種濾動器的好例子，因為不在 Controller 的作用域下執行，需要傳入 Controller 作為參數。濾動器類別必須實作與濾動器同名的方法，所以 `before_filter` 便需要實作 `before` 方法，以此類推。`around` 方法則必須 `yield`，來執行該動作。

Request 偽造保護
--------------------

跨站偽造請求（CSRF, Cross-site request forgery）是利用 A 站的使用者，給 B 站發送請求的一種攻擊手法，比如利用 A 站的梁山伯，去新增、修改、刪除 B 站祝英台的資料。

防範的第一動是確保所有破壞性的動作，如：`create`、`update` 與 `destroy` 只可以透過 **非 GET** 請求來操作。若遵循 RESTful 的慣例，則這已經解決了。但惡意站點仍可發送非 GET 請求至你的網站，這時便是請求偽造防護（Request Forgery Protection）派上用場的時刻了，請求偽造防護如其名：偽造請求防禦。

防護的手法是每次請求時，加上一個猜不到的 token。如此一來，沒有正確 token 的請求便會被拒絕存取。.

假設有下列表單：

```erb
<%= form_for @user do |f| %>
  <%= f.text_field :username %>
  <%= f.text_field :password %>
<% end %>
```

token 如何加到隱藏欄位：

```html
<form accept-charset="UTF-8" action="/users/1" method="post">
<input type="hidden"
       value="67250ab105eb5ad10851c00a5621854a23af5489"
       name="authenticity_token"/>
<!-- username & password fields -->
</form>
```

Rails 自動給所有使用了[表單輔助方法](/form-helpers.html) 的表單加上這個 token，所以不用擔心怎麼處理。若是手寫表單可以透過 `form_authenticity_token` 方法來加上 token。

[`form_authenticity_token`](http://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection.html#method-i-form_authenticity_token) 產生一個有效的驗證 token。這在 Rails 沒有自動加上 token 的場景下很有用，像是自定的 Ajax 請求，`form_authenticity_token` 很簡單，就是設定了 Session 的 `_csrf_token`：

```ruby
def form_authenticity_token
  session[:_csrf_token] ||= SecureRandom.base64(32)
end
```

參閱 [Rails 安全指南](/security.html)來了解此議題，以及開發 Web 應用程式所需要了解的安全性問題。

請求與響應
------------------------------

請求生命週期裡，每個 Controller 都有兩個存取器方法，`request` 與 `response`。`request` 方法包含了 `AbstractRequest` 的實體。`response` 方法則是即將回給客戶端的 `response` 物件。

### `request` 物件

`request` 物件帶有許多從客戶端而來的有用資訊。關於所有可用的方法，請查閱 [ActionDispatch::Request API 文件](http://api.rubyonrails.org/classes/ActionDispatch/Request.html)。而所有可存取的特性有：

| `request` 的 property                     | 用途                                                        |
| ----------------------------------------- | ---------------------------------------------------------- |
| host                                      | 請求所使用的 hostname。|
| domain(n=2)                               | 主機名稱的前 `n` 個區段，從 TLD 右邊開始算起。|
| format                                    | 請求所使用的 content type。|
| method                                    | 請求所使用的 HTTP 動詞。|
| get?, post?, patch?, put?, delete?, head? | HTTP 動詞為右列其一時，返回真。 GET/POST/PATCH/PUT/DELETE/HEAD。|
| headers                                   | 返回請求的標頭檔（Hash）。|
| port                                      | 請求使用的埠號。|
| protocol                                  | 返回包含 `"://"` 的字串，如 `"http://"`。|
| query_string                              | URL 的 Query String 部分。也就是 "?" 之後的字串。|
| remote_ip                                 | 客戶端的 IP 位址。|
| url                                       | 請求所使用的完整 URL 位址。|

#### `path_parameters`、`query_parameters` 以及 `request_parameters`

Rails 將所有與請求一起送來的參數，不管是 Query String 還是 POST body 而來的參數，都蒐集在 `params` Hash 裡。

`request` 物件有三個存取器，可以取出這些參數，分別是 `query_parameters`、`request_parameters` 以及 `path_parameters`，它們都是 Hash。

* `query_parameters`： Query String 參數（via GET）。

* `request_parameters`： POST 而來的參數。

* `path_parameters`： Controller 與動作名稱：

  ```ruby
  { 'action' => 'my_action', 'controller' => 'my_controller' }
  ```

### `response` 物件

`response` 物件通常不會直接使用，會在執行動作時，與算繪即將送回給使用者的資料時，建立出 `response` 物件。需要先處理響應，處理完再回給 User 的場景下有用，比如在後置濾動器處理這件事。此時便可以存取到 `response`，甚至可透過 Setters 來改變 `response` 部分的值。

| `response` 的 property  | 用途                                               |
| ---------------------- | ---------------------------------------------------|
| body                   | 傳回給客戶端的字串，通常是 HTML。|
| status                 | 響應的狀態碼，比如成功回 200，找不到回 404。|
| location               | 轉址的 URL（如果有的話）。|
| content_type           | 響應的 Content-Type。|
| charset                | 響應使用的編碼集，預設是 "UTF-8"。|
| headers                | 響應使用的標頭檔。|

#### 自訂標頭檔

若是想給響應自定標頭檔，修改 `response.headers`。`headers` 是一個 Hash，將響應標頭檔的名稱與值關連起來，某些值 Rails 已經設定好了。假設 API 需要回一個特殊的 Header，`X-TOP-SECRET-HEADER`，在 Controller 便可以這麼寫：

```ruby
response.headers["X-TOP-SECRET-HEADER"] = '123456789'
```

若是要設定每個響應預設的標頭檔，可在 `config/application.rb` 裡設定，詳情參考 [Rails 設定應用程式 - 3.8 設定 Action Dispatch](/configuring.html#configuring-action-dispatch) 一節。

HTTP 認證
--------------------

Rails 內建了兩種 HTTP 認證方法：

* Basic Authentication（基礎認證）
* Digest Authentication（摘要認證）

### HTTP 基礎認證

「HTTP 基礎認證」是一種主流瀏覽器與 HTTP 客戶端皆支援的認證方式。舉個例子，假設有一段管理員才能瀏覽的區塊，必須在瀏覽器的 HTTP 基本會話視窗輸入 `username` 與 `password`，確保身分是管理員才可瀏覽。

在 Rails 裡只要使用一個方法：`http_basic_authenticate_with` 即可。

```ruby
class AdminsController < ApplicationController
  http_basic_authenticate_with name: "humbaba", password: "5baa61e4"
end
```

有了這行程式碼之後，可以從 `AdminsController` 切出命名空間，讓要管控的 Controller 繼承 `AdminsController`。

### HTTP 摘要認證

HTTP 摘要認證比 HTTP 基礎認證高級一些，不需要使用者透過網路傳送未加密的密碼（但採用 HTTPS 的情況下，HTTP 基礎認證是安全的）。使用摘要認證也只需要一個方法：`authenticate_or_request_with_http_digest`。

```ruby
class AdminsController < ApplicationController
  USERS = { "lifo" => "world" }

  before_action :authenticate

  private

    def authenticate
      authenticate_or_request_with_http_digest do |username|
        USERS[username]
      end
    end
end
```

從上例可以看出來，`authenticate_or_request_with_http_digest` 接受一個參數，`username`。區塊內返回密碼：

```ruby
authenticate_or_request_with_http_digest do |username|
  USERS[username]
end
```

最後 `authenticate` 返回 `true` 或 `false`，決定認證是否成功。

串流與檔案下載
--------------------

有時候想給使用者傳檔案，而不是算繪出 HTML 頁面。Rails 所有的 Controller 都有 `send_data` 與 `send_file` 方法，可以用來串流資料。`send_file` 是個簡單傳檔案的方法，只要輸入檔案名稱，便可串流該檔案的內容。

要串流資料給客戶端，使用 `send_data` 即可：

```ruby
require "prawn"
class ClientsController < ApplicationController
  # 用客戶端的資訊產生並返回 PDF 檔案。
  # 使用者會像是下載檔案一樣獲得 PDF。
  def download_pdf
    client = Client.find(params[:id])
    send_data generate_pdf(client),
              filename: "#{client.name}.pdf",
              type: "application/pdf"
  end

  private

    def generate_pdf(client)
      Prawn::Document.new do
        text client.name, align: :center
        text "Address: #{client.address}"
        text "Email: #{client.email}"
      end.render
    end
end
```

上例的 `download_pdf` 會呼叫產生 PDF 檔案的 `private` 方法，並返回一個字串。這個字串會串流給使用者，讓使用者可以依照推薦的檔案名稱來下載檔案。有時候串流檔案給使用者時，可能不希望檔案被下載。舉圖片的例子來說，圖片可以嵌入在 HTML，但不要下載。要想跟瀏覽器說，某種檔案不是用來下載的，可以設定 `:disposition` 選項為 `"inline"`。預設值是 `"attachment"`。

### 傳送檔案

若想傳送硬碟上的檔案，使用 `send_file`：

```ruby
class ClientsController < ApplicationController
  # 串流已存在硬碟上的檔案
  def download_pdf
    client = Client.find(params[:id])
    send_file("#{Rails.root}/files/clients/#{client.id}.pdf",
              filename: "#{client.name}.pdf",
              type: "application/pdf")
  end
end
```

這會讀檔案的 4KB 到記憶體，避免載入整個檔案。串流可以透過 `:stream` 選項關掉，或是調整預讀取的大小：`:buffer_size`。

若是沒有指定 `:type`，會使用 `:filename` 的副檔名。若該副檔名的 Content-Type 沒有註冊過，會使用 `application/octet-stream`。

WARNING: 小心使用從客戶端來的資料來指定檔案位址（params、cookies 等），因為這變相的讓某人獲得存取不該存取檔案的權限。

TIP: 不推薦透過 Rails 來串流靜態檔案。可以將檔案存在 public 目錄，讓使用者透過 Nginx 或其他伺服器來下載會比較有效率，串流檔案避免讓請求走過整個 Rails stack。

### RESTful 風格的下載

`send_data` 可以用，但打造 RESTful 應用程式時，不需要將檔案下載切成不同的動作。在 REST 的世界裡，上例的 PDF 檔案可以想成另一種客戶端資源的表現方式。Rails 提供簡單有序的方式來實作 “RESTful 風格的下載”。以下是如何重寫上例，讓 PDF 下載成為 `show` 動作的一部分，而無需使用任何串流：

```ruby
class ClientsController < ApplicationController
  # 使用者可發 Request 來決定要獲取資源的 HTML 格式，還是 PDF 格式。
  def show
    @client = Client.find(params[:id])

    respond_to do |format|
      format.html
      format.pdf { render pdf: generate_pdf(@client) }
    end
  end
end
```

為了使上例可以動，必須要加入 PDF 的 MIME 類型到 Rails。在 `config/initializers/mime_types.rb`：

```ruby
Mime::Type.register "application/pdf", :pdf
```

NOTE: 設定檔不會在每個請求之間重新載入，所以必須要重新啟動伺服器，更改才能生效。

現在使用者可以發請求到 URL `/clients/1.pdf` 來獲得自己的 PDF。

```bash
GET /clients/1.pdf
```

### 即時串流任何資料

Rails 允許串流檔案之外的資料。實際上，可以透過 `response` 物件來串流任何資料。`ActionController::Live` 模組允許你與瀏覽器之間建立持久的連結。使用此模組，能夠在任何時間送任何資料給瀏覽器。

#### 導入即時串流

在 Controller 類別內部 `include ActionController::Live` 讓 Controller 內部所有的 action 皆可串流資料：

```ruby
class MyController < ActionController::Base
  include ActionController::Live

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    100.times {
      response.stream.write "hello world\n"
      sleep 1
    }
  ensure
    response.stream.close
  end
end
```

上面的程式碼會在瀏覽器打開一個持久性的連結，傳送 100 次 `"hello world\n"`，每次間隔 1 秒。

上例有幾件事情要注意。需要確保響應串流使用完之後要關閉。忘記關掉響應串流會導致 socket 永遠打開。另一件事是，在寫出響應串流前，要將 Content-Type 設為 `text/event-stream`。這是因為標頭檔無法在送出響應之後（`response.committed` 為 `true` 時）更改，比如上面的 `response.stream.write "hello world\n"`。

#### 應用場景

假設正在做一部卡拉 OK 機器，而使用者想要獲得特定歌曲的歌詞。每首 `Song` 的歌詞都有特定的行數，而每一行所花費的時間是 `num_beats`。

若我們想以常見的卡拉 OK 形式返回歌詞（在上一句唱完之後，傳送下句歌詞），則我們可使用 `ActionController::Live`：

```ruby
class LyricsController < ActionController::Base
  include ActionController::Live

  def show
    response.headers['Content-Type'] = 'text/event-stream'
    song = Song.find(params[:id])

    song.each do |line|
      response.stream.write line.lyrics
      sleep line.num_beats
    end
  ensure
    response.stream.close
  end
end
```

上面的程式碼僅在歌手唱完上一句，才會發送下句歌詞。

#### 串流需要考量的事情

串流任意資料是個非常強大的工具。像上個例子，可以選擇何時、與傳送何種資料。但有幾件事情需要注意：

* 每個響應串流會建立新的線程，並從原本的線程複製區域變數出來線程 有太多區域變數會大大影響效能，有太多線程也是。
* 忘記關掉響應串流會使 socket 一直開著。記得使用完響應串流要 `close` 掉。
* WEBrick 伺服器會自動將所有的響應放入緩衝區，所以 `include ActionController::Live` 不會起作用。必須使用不會自動將響應放入緩衝區的伺服器。

過濾 Log
--------------------

Rails 為每個環境都存有 Log 檔案，放在 `log` 目錄下。這些 Log 檔案拿來 debug 非常有用，可以瞭解應用程式當下究竟在幹嘛。但正式上線的應用程式，可能不想要記錄所有的資訊。

### 過濾參數

可以從 Log 檔案過濾掉特定的請求參數，在 `config/application.rb` 裡的 `config.filter_parameters` 設定。

```ruby
config.filter_parameters << :password
```

設定過的參數在 Log 裡會被改成 `[FILTERED]`，確保 Log 外洩時，輸入的密碼不會跟著外洩。

### 過濾轉址

有時候會想要從 Log 檔案過濾某些應用程式 `redirect_to` 的地方。可以透過設定 `config.filter_redirect` 來達成：

```ruby
config.filter_redirect << 's3.amazonaws.com'
```

也可以用字串、正規表達式，或用陣列存字串、正規表達式：

```ruby
config.filter_redirect.concat ['s3.amazonaws.com', /private_path/]
```

匹配的 URL 會被標記成 `[FILTERED]`。

拯救異常
--------------------

每個應用程式都可能有 bugs，或是拋出異常，這些都需要處理。舉例來說，使用者點了一個連結，該連結的 resource 已經不在資料庫了，Active Record 會拋出 `ActiveRecord::RecordNotFound` 異常。

Rails 預設處理異常的方式是 `"500 Internal Server Error"`。若 Request 是從 local 端發出，會有 backtrace 資訊，用來來查找錯誤究竟在那裡。若請求是從遠端而來，則 Rails 僅顯示 `"500 Internal Server Error"`。若是使用者試圖存取不存在的路徑，Rails 則會回 `"404 Not Found"`。有時會想自定這些錯誤的處理及顯示方式。接著讓我們看看在 Rails 當中，處理錯誤與異常的幾個層級：

### 內建的 500、404 與 422 模版

跑在 production 環境的應用程式，預設會算繪 404、500 或 422 錯誤訊息，分別在 `public` 目錄下面的靜態檔案： `404.html`、`500.html` 與 `422.html`。可以修改 `404.html` 或是 `500.html` 或 `422.html`。可以客製化這些檔案，加入額外的資訊或調整版型等。但記得這些是靜態檔案，也就是無法嵌入任何 Ruby，只能使用純 HTML。

### `rescue_from`

若想要對捕捉錯誤做些更複雜的事情，可以使用 `rescue_from`。`rescue_from` 在整個 Controller 與 Controller 的子類別下，處理特定類型的異常（或多種類型的異常）。

當異常發生，被 `rescue_from` 捕捉時，異常物件會傳給 Handler。Handler 可以是有著 `:with` 選項的 `Proc` 物件，也可以直接使用區塊。

以下是使用 `rescue_from` 來攔截所有 `ActiveRecord::RecordNotFound` 的示範：

```ruby
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

    def record_not_found
      render plain: "404 沒有找到", status: 404
    end
end
```

上例跟預設的處理方式沒什麼兩樣，只是示範如何捕捉異常，捕捉到之後，想做任何事都可以。舉例來說，可以建立一個自定義的異常類別，在使用者沒有權限存取應用程式的某一部分時拋出：

```ruby
class ApplicationController < ActionController::Base
  rescue_from User::NotAuthorized, with: :user_not_authorized

  private

    def user_not_authorized
      flash[:error] = "無權存取此部份"
      redirect_to :back
    end
end

class ClientsController < ApplicationController
  # 檢查使用者是否有正確的權限可以存取。
  before_action :check_authorization

  # 注意到動作不需要處理授權問題，因為已經在 before_action 裡處理了。
  def edit
    @client = Client.find(params[:id])
  end

  private

    # 若使用者沒有授權，拋出異常。
    def check_authorization
      raise User::NotAuthorized unless current_user.admin?
    end
end
```

WARNING: 不要做 `rescue_from Exception` 或 `rescue_from StandardError`，除非有很好的理由。因為這會帶來嚴重的副作用（譬如無法得知異常的細節、無法在開發時追蹤 Backtrace）。若想要動態產生錯誤頁面請參考[自訂錯誤頁面](#自訂錯誤頁面)。

NOTE: 特定的異常只有在 `ApplicationController` 裡面可以捕捉的到，因為他們在 Controller 被實體化出來之前，或動作執行之前便發生了。參考 Pratik Naik 的[文章](http://m.onkey.org/2008/7/20/rescue-from-dispatching)來了解更多關於這個問題的細節。

### 自訂錯誤頁面

可以使用 Controller 與 View 來自己客製化錯誤處理的版面。首先定義顯示錯誤頁面的路由。

* `config/application.rb`

  ```ruby
  config.exceptions_app = self.routes
  ```

* `config/routes.rb`

  ```ruby
  match '/404', via: :all, to: 'errors#not_found'
  match '/422', via: :all, to: 'errors#unprocessable_entity'
  match '/500', via: :all, to: 'errors#server_error'
  ```

建立 Controller 與 View。

* `app/controllers/errors_controller.rb`

  ```ruby
  class ErrorsController < ActionController::Base
    layout 'error'

    def not_found
      render status: :not_found
    end

    def unprocessable_entity
      render status: :unprocessable_entity
    end

    def server_error
      render status: :server_error
    end
  end
  ```

* `app/views`

  ```
  errors/
    not_found.html.erb
    unprocessable_entity.html.erb
    server_error.html.erb
  layouts/
    error.html.erb
  ```


別忘記在 Controller 設定正確的錯誤碼（如上所示）。

WARNING: 錯誤頁面要避免對資料庫進行操作，或是進行任何複雜的操作。因為使用者已經到了錯誤頁面這裡，在錯誤頁面產生另外的錯誤會造成不必要的問題。

強制使用 HTTPS 協定
------------------------------

有時候出於安全性考量，可能想讓特定的 Controller 只可以透過 HTTPS 來存取。可以在 Controller 使用 `force_ssl` 方法：

```ruby
class DinnerController
  force_ssl
end
```

和 `filter` 的用法相同，可以傳入 `:only` 與 `except` 選項來決定那幾個動作要用 HTTPS：

```ruby
class DinnerController
  force_ssl only: :cheeseburger
  # or
  force_ssl except: :cheeseburger
end
```

請注意，若發現許多 Controller 都要加上 `force_ssl`，可以在環境設定檔開啟 `config.force_ssl` 選項。
