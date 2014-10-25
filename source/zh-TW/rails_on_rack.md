Rails on Rack
================

本篇介紹 Rails 與 Rack 的整合、如何與其他 Rack 組件互動。

讀完本篇，您將了解：

* 如何在 Rails 裡使用 Rack Middleware。
* ActionPack  Middleware 的內部工作原理。
* 如何自定 Middleware。

--------------------------------------------------------------------------------

WARNING: 本篇需要先了解 Rack 協定，以及 Rack 的相關概念，譬如：什麼是 Middleware、什麼是 URL 映射以及 `Rack::Builder` 等知識。

Rack 簡介
--------------------

Rack 給使用 Ruby 開發的網路應用程式，提供了精簡、模組化、容易介接的介面。Rack 將 HTTP 請求與響應，盡可能包裝成最簡單的形式，給網路框架、伺服器以及框架與伺服器之間的軟體（Middleware）提供了一個統一的 API 接口，`call` 方法。

更多內容請參考：[Rack API 文件](http://rack.github.io/)。

深入解釋 Rack 超出本篇的範疇。若不熟悉 Rack 的基礎知識，請閱讀[參考資料](#參考資料)一節。

Rails on Rack
----------------

### Rails 應用程式的 Rack 物件

`ApplicationName::Application` 是 Rails 應用程式主要的 Rack 物件。任何與 Rack 相容的 Web 伺服器，都應該使用 `ApplicationName::Application` 物件來執行 Rails 應用程式。`Rails.application` 是 `ApplicationName::Application` 物件 的引用。

### `rails server`

`rails server` 建立 `Rack::Server` 物件並啟動伺服器。

以下是 `rails server` 如何建立 `Rack::Server` 的實體。

```ruby
Rails::Server.new.tap do |server|
  require APP_PATH
  Dir.chdir(Rails.application.root)
  server.start
end
```

`Rails::Server` 繼承自 `Rack::Server`，並呼叫 `Rack::Server#start` 方法：

```ruby
class Server < ::Rack::Server
  def start
    ...
    super
  end
end
```

以下是如何載入 Middlewares：

```ruby
def middleware
  middlewares = []
  middlewares << [Rails::Rack::Debugger] if options[:debugger]
  middlewares << [::Rack::ContentLength]
  Hash.new(middlewares)
end
```

`Rails::Rack::Debugger` 主要只在開發模式下有用。下表解釋了加載的 Middleware 的用途：

| Middleware | 用途 |
| :--------- | :------ |
| Rails::Rack::Debugger | 啟動 Debugger
| Rack::ContentLength   | 計算響應有幾個 byte，並設定 HTTP Content-Length 標頭|

### `rackup`

若想用 `rackup` 來取代 `rails server`，可以修改 Rails 應用程式根目錄下的 `config.ru`：

```ruby
# Rails.root/config.ru
require ::File.expand_path('../config/environment', __FILE__)

use Rack::Debugger
use Rack::ContentLength
run Rails.application
```

啟動伺服器：

```bash
$ rackup config.ru
```

了解 `rackup` 接受的其他選項：

```bash
$ rackup --help
```

### 開發自動重載

Middlewares 只會載入一次，察覺不到新的修改。有關 Middleware 的修改需要重新啟動伺服器才行。

Action Dispatcher Middleware Stack
-------------------------------------

許多 Action Dispatcher 的內部組件都是以 Rack Middleware 的方式所實作。`Rails::Application` 使用了 `ActionDispatch::MiddlewareStack`，將內部與外部的 Middleware 結合起來，形成完整的 Rails Rack 應用程式。


NOTE: Rails 的 `ActionDispatch::MiddlewareStack` 等同於 `Rack::Builder`，但靈活性更高、更多功能，專門為了滿足 Rails 需求所打造。

### 檢視 Middleware Stack

Rails 有一個好用的 Rake 任務，可檢視使用中的 Middleware stack：

```bash
$ bin/rake middleware
```

新建出來的 Rails 應用程式，輸出結果會像是：

```ruby
use Rack::Sendfile
use ActionDispatch::Static
use Rack::Lock
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x000000029a0838>
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use Rails::Rack::Logger
use ActionDispatch::ShowExceptions
use ActionDispatch::DebugExceptions
use ActionDispatch::RemoteIp
use ActionDispatch::Reloader
use ActionDispatch::Callbacks
use ActiveRecord::Migration::CheckPending
use ActiveRecord::ConnectionAdapters::ConnectionManagement
use ActiveRecord::QueryCache
use ActionDispatch::Cookies
use ActionDispatch::Session::CookieStore
use ActionDispatch::Flash
use ActionDispatch::ParamsParser
use Rack::Head
use Rack::ConditionalGet
use Rack::ETag
run Rails.application.routes
```

上列 Middlewares 在[內部 Middlewares](#內部-middleware-stack) 一節分別介紹。

### 設定 Middleware Stack

Rails 提供了簡單的設定接口：`config.middleware`，用來新增、刪除、修改 Middleware Stack 裡的 Middleware。可以在 `application.rb` 或是特定環境的設定檔：`environments/<environment>.rb` 來使用這個設定。

#### 新增 Middleware

使用下面任一方法來新增 Middleware 到 Middleware Stack：

**`config.middleware.use(new_middleware, args)`**

* 新增 Middleware 到 Middleware Stack 的底部

**`config.middleware.insert_before(existing_middleware, new_middleware, args)`**

* 新增 Middleware 在某個現有的 Middleware 之前。

**`config.middleware.insert_after(existing_middleware, new_middleware, args)`**

* 新增 Middleware 在某個現有的 Middleware 之後。

```ruby
# config/application.rb

# Push Rack::BounceFavicon at the bottom
config.middleware.use Rack::BounceFavicon

# Add Lifo::Cache after ActiveRecord::QueryCache.
# Pass { page_cache: false } argument to Lifo::Cache.
config.middleware.insert_after ActiveRecord::QueryCache, Lifo::Cache, page_cache: false
```

#### 交換 Middleware 順序

使用 `config.middleware.swap` 來交換現有 Middleware Stack 中，Middleware 的順序。

```ruby
# config/application.rb

# Replace ActionDispatch::ShowExceptions with Lifo::ShowExceptions
config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions
```

#### 刪除 Middleware

加入下行程式碼到應用程式設定檔，來刪除 Middleware：

```ruby
# config/application.rb
config.middleware.delete "Rack::Lock"
```

現在檢視 Middleware Stack，會發現 `Rack::Lock` 已經被刪除了。

```bash
$ bin/rake middleware
use Rack::Sendfile
use ActionDispatch::Static
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x000000029a0838>
use Rack::Runtime
...
run Rails.application.routes
```

若想移除與 Session 有關的 Middleware：

```ruby
# config/application.rb
config.middleware.delete "ActionDispatch::Cookies"
config.middleware.delete "ActionDispatch::Session::CookieStore"
config.middleware.delete "ActionDispatch::Flash"
```

或移除與瀏覽器相關的 Middleware：

```ruby
# config/application.rb
config.middleware.delete "Rack::MethodOverride"
```

### 內部 Middleware Stack

Action Controller 大多數的功能皆以 Middleware 的方式實作，以下解釋每個 Middleware 的用途：

**`Rack::Sendfile`**

* 設定伺服器的 `X-Sendfile` 標頭（header）。使用 `config.action_dispatch.x_sendfile_header` 來設定。

**`ActionDispatch::Static`**

* 用來決定是否由 Rails 提供靜態 assets。使用 `config.serve_static_assets` 選項來啟用或禁用（`true` 啟用）。

**`Rack::Lock`**

* 將 `env["rack.multithread"]` 設為 `false` ，則可將應用程式包在 Mutex 裡。

**`ActiveSupport::Cache::Strategy::LocalCache::Middleware`**

* 用來做 memory cache。注意，此 cache 不是線程安全的。

**`Rack::Runtime`**

* 設定 X-Runtime 標頭，並記錄請求的執行時間（秒為單位）。

**`Rack::MethodOverride`**

* 如有設定 `params[:_method]`，則允許可以重寫方法。這個 Middleware 實作了 HTTP `PUT` 與 `DELETE` 方法。

**`ActionDispatch::RequestId`**

* 在響應中產生獨立的 `X-Request-Id` 標頭，並啟用 `ActionDispatch::Request#uuid` 方法。

**`Rails::Rack::Logger`**

* 請求開始時通知 Log，請求結束寫入 Log。

**`ActionDispatch::ShowExceptions`**

* Rescue 任何由應用程式拋出的異常，並呼叫處理異常的程式，將異常以適合的格式顯示給使用者。

**`ActionDispatch::DebugExceptions`**

* 負責記錄異常，並在請求來自本機時，顯示除錯頁面。

**`ActionDispatch::RemoteIp`**

* 檢查 IP 欺騙攻擊。

**`ActionDispatch::Reloader`**

* 準備與清除回呼。主要在開發模式下用來重新加載程式碼。

**`ActionDispatch::Callbacks`**

* 處理請求前，先執行預備好的回呼。

**`ActiveRecord::Migration::CheckPending`**

* 檢查是否有未執行的遷移檔案，有的話拋出 `PendingMigrationError` 錯誤。

**`ActiveRecord::ConnectionAdapters::ConnectionManagement`**

* 每個請求結束後，若 `rack.test` 不為真，則將作用中的連線清除。

**`ActiveRecord::QueryCache`**

* 啟用 Active Record 的查詢快取。

**`ActionDispatch::Cookies`**

* 幫請求設定 Cookie。

**`ActionDispatch::Session::CookieStore`**

* 負責把 Session 存到 Cookie。

**`ActionDispatch::Flash`**

`config.action_controller.session_store` 設定為真時，設定[提示訊息](action_controller_overview.html#提示訊息)的鍵。

**`ActionDispatch::ParamsParser`**

* 解析請求的參數放到 `params` Hash 裡。

**`ActionDispatch::Head`**

* 將 HTTP `HEAD` 請求轉換成 `GET` 請求處理。

**`Rack::ConditionalGet`**

* 給伺服器加入 HTTP 的 Conditional `GET` 支持，頁面沒有變化，就不會回傳響應。

**`Rack::ETag`**

* 為所有字串 Body 加上 ETag 標頭，用來驗證快取。

TIP: 以上所有的 Middleware 都可以在自定的 Rack Stack 使用。

參考資料
---------

### 學習 Rack

* [Rack 官方網站](http://rack.github.io)
* [介紹 Rack](http://chneukirchen.org/blog/archive/2007/02/introducing-rack.html)
* [Ruby on Rack #1 - Hello Rack!](http://m.onkey.org/ruby-on-rack-1-hello-rack)
* [Ruby on Rack #2 - The Builder](http://m.onkey.org/ruby-on-rack-2-the-builder)
* [#317 Rack App from Scratch (pro) - RailsCasts](http://railscasts.com/episodes/317-rack-app-from-scratch)
* [#222 Rack in Rails 3 - RailsCasts](http://railscasts.com/episodes/222-rack-in-rails-3)

### 理解 Middlewares

* [List of Rack Middlewares](https://github.com/rack/rack/wiki/List-of-Middleware)
* [Railscast on Rack Middlewares](http://railscasts.com/episodes/151-rack-middleware)
