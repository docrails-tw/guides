Ruby on Rails 4.2 發佈記
========================

Rails 4.2 精華摘要：

* Active Job、Action Mailer #deliver_later
* Adequate Record
* Web Console
* 外鍵支援

本篇僅記錄主要的變化。要了解關於已修復的 Bug、功能變更等，請參考 [Rails GitHub 主頁](https://github.com/rails/rails)上各個 Gem 的 CHANGELOG 或是 [Rails 的提交歷史](https://github.com/rails/rails/commits/master)。

--------------------------------------------------------------------------------

升級至 Rails 4.2
----------------------

如果您正試著升級現有的應用程式，應用程式最好要有足夠的測試。第一步先升級至 4.1，確保應用程式仍正常工作，接著再升上 4.2。升級需要注意的事項在 [Ruby on Rails 升級指南](upgrading_ruby_on_rails.html#upgrading-from-rails-4-1-to-rails-4-2)可以找到。

主要的新功能
----------

### Active Job、Action Mailer #deliver_later

Active Job 是 Rails 4.2 新搭載的框架。是連結佇列系統（Queuing systems）的連接層（adapter layer），用來連接像是 [Resque](https://github.com/resque/resque)、[Delayed
Job](https://github.com/collectiveidea/delayed_job)、[Sidekiq](https://github.com/mperham/sidekiq) 等佇列系統。

採用 Active Job 的 API 來撰寫背景任務程式（Background jobs），程式便可跑在任何支援的佇列系統之上（預設會即時執行任務），而無需做任何修正。

有了 Active Job 做基礎，Action Mailer 新增了 `#deliver_later` 方法，把要寄出的信作為任務，加到佇列裡，不會拖慢 Controller 或 Model 的執行。

新加入的 GlobalID 函式庫，透過把 Active Record 物件序列化（serialize）為通用的形式，Active Record 物件現在要傳給任務變得簡單了。不再需要傳入 ID，自己對 ID 做處理，只要傳給任務 Active Record 物件，任務會自己用 Global ID 做序列化，執行時再自動進行反序列化。

### Adequate Record

Adequate Record 是對 Active Record `find` 和 `find_by` 方法以及其它的關聯查詢方法所進行的一系列重構，查詢速度最高提昇到了兩倍之多。

工作原理是在執行 Active Record 呼叫時，把 SQL 查詢語句快取起來。有了查詢語句的快取之後，同樣的 SQL 查詢就不需要再次把呼叫轉換成 SQL 語句。更多細節請參考 [Aaron Patterson 的文章](http://tenderlovemaking.com/2014/02/19/adequaterecord-pro-like-activerecord.html)。

Adequate Record 已經合併到 Rails 裡，所以不需要特別啟用這個功能。多數的 `find` 和 `find_by` 呼叫和關聯查詢會自動使用 Adequate Record，比如：

```ruby
Post.find 1  # caches query pattern
Post.find 2  # uses the cached pattern

Post.find_by_title 'first post'  # caches query pattern
Post.find_by_title 'second post' # uses the cached pattern

post.comments        # caches query pattern
post.comments(true)  # uses cached pattern
```

下列場景則不會使用快取：

- 當 model 有預設作用域時
- 當 model 使用了單表繼承時
- 當 `find` 查詢一組 ID 時：

  ```ruby
  Post.find(1,2,3)
  OR
  Post.find [1,2]
  ```

- 以 SQL 片段執行 `find_by`：

  ```ruby
  Post.find_by "published_at < ?", 2.weeks.ago
  ```

### Web Console

用 Rails 4.2 新產生的應用程式，預設搭載了 Web Console。

Web Console 是一組專門為 Rails 應用程式打造的除錯工具，在錯誤頁面加入了互動式的終端，`console` View 輔助方法，以及一個相容 VT100 的終端機。

錯誤頁面的互動式的終端，讓你可以在異常發生的地方執行程式碼。用來檢查異常發生的狀態格外有用。

插入 `console` View 輔助方法到任何頁面，便可以在頁面的上下文裡，啟動一個互動式的終端。

最後，可以執行 `rails console` 來啟動一個 VT100 終端。若需要建立或修改測試資料，可以直接從瀏覽器裡執行。

### 外鍵支援

遷移 DSL 現在支援新增、移除外鍵，也會導出到 `schema.rb`。目前只有 `mysql`、`mysql2` 以及 `postgresql` 的連接器支援外鍵。

```ruby
# add a foreign key to `articles.author_id` referencing `authors.id`
add_foreign_key :articles, :authors

# add a foreign key to `articles.author_id` referencing `users.lng_id`
add_foreign_key :articles, :users, column: :author_id, primary_key: "lng_id"

# remove the foreign key on `accounts.branch_id`
remove_foreign_key :accounts, :branches

# remove the foreign key on `accounts.owner_id`
remove_foreign_key :accounts, column: :owner_id
```

完整說明請參考 API 文件：[add_foreign_key](http://api.rubyonrails.org/v4.2.0/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_foreign_key) 和 [remove_foreign_key](http://api.rubyonrails.org/v4.2.0/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-remove_foreign_key)。


Rails 4.2 向下不相容的部份
------------------------

前版棄用的功能已全部移除。請參考文後下列各 Rails 元件來了解 Rails 4.2 新棄用的功能有那些。

以下是升級至 Rails 4.2 所需要立即採取的行動。

### `render` 字串參數

4.2 以前在 Controller 動作呼叫 `render "foo/bar"` 時，效果等同於：`render file: "foo/bar"`；Rails 4.2 被改為 `render template: "foo/bar"`。如需 `render` 檔案，請將程式碼改為 `render file: "foo/bar"`。

### `respond_with` / class-level `respond_to`

`respond_with` 以及對應的**類別層級** `respond_to` 被移到了 `responders` gem。要使用這個功能，把 `gem 'responders', '~> 2.0'` 加入到 Gemfile：

```ruby
# app/controllers/users_controller.rb

class UsersController < ApplicationController
  respond_to :html, :json

  def show
    @user = User.find(params[:id])
    respond_with @user
  end
end
```

而實體層級的 `respond_to` 則不受影響：

```ruby
# app/controllers/users_controller.rb

class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end
end
```

### `rails server` 的預設主機（host）變更

由於 [Rack 的一項修正](https://github.com/rack/rack/commit/28b014484a8ac0bbb388e7eaeeef159598ec64fc)，`rails server` 現在預設會監聽 `localhost` 而不是 `0.0.0.0`。http://127.0.0.1:3000 和 http://localhost:3000 仍可以像以前一樣使用。

但這項變更禁止了從其它機器訪問 Rails 伺服器（譬如開發環境位於虛擬環境裡，而想要從宿主機器上訪問），會需要用 `rails server -b 0.0.0.0` 來啟動才能像之前一樣使用。

若是使用了 `0.0.0.0`，記得要把防火牆設定好，改成只有信任的機器才可以存取你的開發伺服器。

### Production logging

`production` 環境預設的 log 層級改為 `:debug`。和其它環境保持一致，確保足夠的資訊輸出到 Log，供診斷問題之用。

要改回先前的 `:info` 層級 ，在環境設定檔裡加入：

```ruby
# config/environments/production.rb

# Decrease the log volume.
config.log_level = :info
```

### HTML Sanitizer

HTML sanitizer 換成一個新的、更加安全的實作，基於 Loofah 和 Nokogiri。新的 Sanitizer 更安全，而 sanitization 更加完善與靈活。

有了新的 sanitization 演算法之後，某些 pathological 的輸入的輸出會和之前不一樣。

若真的需要使用舊的 sanitizer，可以把 `rails-deprecated_sanitizer` 加到 Gemfile，便會用舊的 sanitizer 取代掉新的。因為這是自己選擇性加入的 gem，所以並不會拋出棄用警告。

Rails 4.2 仍會維護 `rails-deprecated_sanitizer`，但 Rails 5.0 之後便不會再進行維護。

參考[這篇文章](http://blog.plataformatec.com.br/2014/07/the-new-html-sanitizer-in-rails-4-2/)來了解更多關於新的 sanitizer 的變更內容細節。

### `assert_select`

`assert_select` 測試方法現在用 Nokogiri 改寫。

不再支援某些先前可用的選擇器。若應用程式使用了以下的選擇器，則會需要進行更新：

*   屬性選擇器的數值需要用雙引號包起來。

    ```
    a[href=/]      =>     a[href="/"]
    a[href$=/]     =>     a[href$="/"]
    ```

*   含有錯誤嵌套的 HTML 所建出來的 DOM 可能會不一樣

    譬如：

    ``` ruby
    # content: <div><i><p></i></div>

    # before:
    assert_select('div > i')  # => true
    assert_select('div > p')  # => false
    assert_select('i > p')    # => true

    # now:
    assert_select('div > i')  # => true
    assert_select('div > p')  # => true
    assert_select('i > p')    # => false
    ```

*   之前要比較含有 HTML entities 的元素要寫未經轉譯的 HTML，現在寫轉譯後的即可

    ``` ruby
    # content: <p>AT&amp;T</p>

    # before:
    assert_select('p', 'AT&amp;T')  # => true
    assert_select('p', 'AT&T')      # => false

    # now:
    assert_select('p', 'AT&T')      # => true
    assert_select('p', 'AT&amp;T')  # => false
    ```


Railties
--------

請參考 [CHANGELOG][railties] 來了解更多細節。

### 移除

*   `--skip-action-view` 選項從產生器移除了。([Pull Request](https://github.com/rails/rails/pull/17042))

*   移除 `rails application` 命令。([Pull Request](https://github.com/rails/rails/pull/11616))

### 棄用

*   棄用 `Rails::Rack::LogTailer`，沒有替代方案。([Commit](https://github.com/rails/rails/commit/84a13e019e93efaa8994b3f8303d635a7702dbce))

### 值得一提的變化

*   `web-console` 導入為內建的 Gem。
    ([Pull Request](https://github.com/rails/rails/pull/11667))

*   Model 用來產生關聯的產生器新增 `required` 選項。
    ([Pull Request](https://github.com/rails/rails/pull/16062))

*   導入 `after_bundle` 回呼到 Rails 模版。
  ([Pull Request](https://github.com/rails/rails/pull/16359))

*   導入 `x` 命名空間，用來自訂設定選項：

    ```ruby
    # config/environments/production.rb
    config.x.payment_processing.schedule = :daily
    config.x.payment_processing.retries  = 3
    config.x.super_debugger              = true
    ```

    這些選項都可以從設定物件裡獲取：

    ```ruby
    Rails.configuration.x.payment_processing.schedule # => :daily
    Rails.configuration.x.payment_processing.retries  # => 3
    Rails.configuration.x.super_debugger              # => true
    ```

    ([Commit](https://github.com/rails/rails/commit/611849772dd66c2e4d005dcfe153f7ce79a8a7db))

*   導入 `Rails::Application.config_for`，用來給當前的環境載入設定

    ```ruby
    # config/exception_notification.yml:
    production:
      url: http://127.0.0.1:8080
      namespace: my_app_production
    development:
      url: http://localhost:3001
      namespace: my_app_development

    # config/production.rb
    Rails.application.configure do
      config.middleware.use ExceptionNotifier, config_for(:exception_notification)
    end
    ```

    ([Pull Request](https://github.com/rails/rails/pull/16129))

*   產生器新增 `--skip-turbolinks` 選項，新建應用程式便不會內建 turbolink。
    ([Commit](https://github.com/rails/rails/commit/bf17c8a531bc8059d50ad731398002a3e7162a7d))

*   導入 `bin/setup` 腳本來啟動應用程式。
  ([Pull Request](https://github.com/rails/rails/pull/15189))

*   `config.assets.digest` 在開發模式的預設值改為 `true`。
  ([Pull Request](https://github.com/rails/rails/pull/15155))

*   導入給 `rake notes` 註冊新擴充功能的 API。
  ([Pull Request](https://github.com/rails/rails/pull/14379))

*   導入 `Rails.gem_version` 作為回傳 `Gem::Version.new(Rails.version)` 的便捷方法。
  ([Pull Request](https://github.com/rails/rails/pull/14101))


Action Pack
-----------

請參考 [CHANGELOG][action-pack] 來了解更多細節。

### 移除

*   將 `respond_with` 以及類別層級的 `respond_to` 從 Rails 移除，移到 `responders` gem（版本 2.0）。要繼續使用這個功能，請在 Gemfile 加入：`gem 'responders', '~> 2.0'`。([Pull Request](https://github.com/rails/rails/pull/16526))

*   移除棄用的 `AbstractController::Helpers::ClassMethods::MissingHelperError`，
    改用 `AbstractController::Helpers::MissingHelperError` 取代。
    ([Commit](https://github.com/rails/rails/commit/a1ddde15ae0d612ff2973de9cf768ed701b594e8))

### 棄用

*   棄用 `*_path` 輔助方法的 `only_path` 選項。
    ([Commit](https://github.com/rails/rails/commit/aa1fadd48fb40dd9396a383696134a259aa59db9))

*   棄用 `assert_tag`、`assert_no_tag`、`find_tag` 以及 `find_all_tag`，請改用 `assert_select`。
    ([Commit](https://github.com/rails/rails-dom-testing/commit/b12850bc5ff23ba4b599bf2770874dd4f11bf750))

* 棄用路由的 `:to` 選項裡，`:to` 可以指向符號或不含井號的字串這兩個功能。

    ```ruby
    get '/posts', to: MyRackApp    => (No change necessary)
    get '/posts', to: 'post#index' => (No change necessary)
    get '/posts', to: 'posts'      => get '/posts', controller: :posts
    get '/posts', to: :index       => get '/posts', action: :index
    ```

    ([Commit](https://github.com/rails/rails/commit/cc26b6b7bccf0eea2e2c1a9ebdcc9d30ca7390d9))

### 值得一提的變化

*   Rails 現在會自動把模版的 digest 加入到 ETag。
    ([Pull Request](https://github.com/rails/rails/pull/16527))

*   `render nothing: true` 或算繪 `nil` 不再加入一個空白到響應主體。
  ([Pull Request](https://github.com/rails/rails/pull/14883))

*   導入 `always_permitted_parameters` 選項，用來設定全局允許賦值的參數。
  預設值是 `['controller', 'action']`。
  ([Pull Request](https://github.com/rails/rails/pull/15933))

*   `*_filter` 方法已經從文件中移除，已經不鼓勵使用。偏好使用 `*_action` 方法：

    ```ruby
    after_filter          => after_action
    append_after_filter   => append_after_action
    append_around_filter  => append_around_action
    append_before_filter  => append_before_action
    around_filter         => around_action
    before_filter         => before_action
    prepend_after_filter  => prepend_after_action
    prepend_around_filter => prepend_around_action
    prepend_before_filter => prepend_before_action
    skip_after_filter     => skip_after_action
    skip_around_filter    => skip_around_action
    skip_before_filter    => skip_before_action
    skip_filter           => skip_action_callback
    ```

    若應用程式依賴這些 `*_filter` 方法，應該使用 `*_action` 方法替換。
    因為 `*_filter` 方法最終會從 Rails 裡拿掉。
    (Commit [1](https://github.com/rails/rails/commit/6c5f43bab8206747a8591435b2aa0ff7051ad3de),
    [2](https://github.com/rails/rails/commit/489a8f2a44dc9cea09154ee1ee2557d1f037c7d4))

* 從 RFC-4791 新增 HTTP 方法 `MKCALENDAR`。
  ([Pull Request](https://github.com/rails/rails/pull/15121))

* `*_fragment.action_controller` 通知訊息的 Payload 現在包含 Controller 與動作名稱。
  ([Pull Request](https://github.com/rails/rails/pull/14137))

* 傳入 URL 輔助方法的片段現在會自動 Escaped。
  ([Commit](https://github.com/rails/rails/commit/5460591f0226a9d248b7b4f89186bd5553e7768f))

* 改善路由錯誤頁面，搜索路由支持模糊搜尋。
  ([Pull Request](https://github.com/rails/rails/pull/14619))

* 新增關掉記錄 CSRF 失敗的選項。
  ([Pull Request](https://github.com/rails/rails/pull/14280))

*   當 Rails 伺服器設為提供靜態資源時，若客戶端支援 gzip，則會自動傳送預先產生好的 gzip 靜態資源。Asset Pipeline 預設會給所有可壓縮的靜態資源產生 `.gz` 檔。傳送 gzip 可將所需傳輸的資料量降到最小，並加速靜態資源請求的存取。當然若要在 Rails 線上環境提供靜態資源，最好還是使用 [CDN](http://guides.rubyonrails.org/asset_pipeline.html#cdns)。([Pull Request](https://github.com/rails/rails/pull/16466))

*   `assert_select` 的工作方式變更了，解讀 CSS 選擇器若用了多個不同的函式庫，會建一個過渡的 DOM 供選擇器選擇取出資料。譬如：
    *  屬性選擇器的值為非字母字元時，需要用雙引號包起來。
    *  由含有嵌套錯誤元素的 HTML 建出來的 DOM 和先前不同。
    *  先前要比較未轉譯的元素時，需傳入未轉譯的元素（比如 `AT&amp;T`）給選擇器，現在只要傳轉譯後的元素（`AT&T`）即可。


Action View
-------------

請參考 [CHANGELOG][action-view] 來了解更多細節。

### 棄用

*   棄用 `AbstractController::Base.parent_prefixes`。想修改尋找 View 的位置，
  請覆寫 `AbstractController::Base.local_prefixes`。
  ([Pull Request](https://github.com/rails/rails/pull/15026))

*   棄用 `ActionView::Digestor#digest(name, format, finder, options = {})`，
  現在參數改用 Hash 傳入。
  ([Pull Request](https://github.com/rails/rails/pull/14243))

### 值得一提的變化

*   `render "foo/bar"` 現在展開為 `render template: "foo/bar"` 而不是 `render file: "foo/bar"`。([Pull Request](https://github.com/rails/rails/pull/16888))

*   導入一個特別的 `#{partial_name}_iteration` 區域變數，給在 collection 裡算繪的局部頁面（Partial）使用。這個變數可以透過 `#index`、`#size`、`first?` 以及 `last?` 等方法來存取目前迭代的狀態。([Pull Request](https://github.com/rails/rails/pull/7698))

*   隱藏欄位的表單輔助方法不再產生含有行內樣式表的 `<div>` 元素。
  ([Pull Request](https://github.com/rails/rails/pull/14738))

*   Placeholder I18n follows the same convention as `label` I18n.
    ([Pull Request](https://github.com/rails/rails/pull/16438))

Action Mailer
-------------

請參考 [CHANGELOG][action-mailer] 來了解更多細節。

### 棄用

*   Mailer 全部棄用 `*_path` 輔助方法。請全面改用 `*_url`。
    ([Pull Request](https://github.com/rails/rails/pull/15840))

*   棄用 `deliver` 與 `deliver!`，請改用 `deliver_now` 或 `deliver_now!`。
    ([Pull Request](https://github.com/rails/rails/pull/16582))

### 值得一提的變化

*   導入 `deliver_later` 方法，將要寄的信加到應用程式的佇列裡，用來異步發送信件。
    ([Pull Request](https://github.com/rails/rails/pull/16485))

*   新增 `show_previews` 選項，用來在開發環境之外啟用郵件預覽功能。
  ([Pull Request](https://github.com/rails/rails/pull/15970))

Active Record
-------------

請參考 [CHANGELOG][active-record] 來了解更多細節。

### 移除

*   移除 `cache_attributes` 以及其它相關的方法。現在所有屬性都有快取。
  ([Pull Request](https://github.com/rails/rails/pull/15429))

*   移除已棄用的方法 `ActiveRecord::Base.quoted_locking_column`.
  ([Pull Request](https://github.com/rails/rails/pull/15612))

*   移除已棄用的方法 `ActiveRecord::Migrator.proper_table_name`。
  請改用 `ActiveRecord::Migration` 的實體方法：`proper_table_name`。
  ([Pull Request](https://github.com/rails/rails/pull/15512))

*   移除了未使用的 `:timestamp` 類型。把所有 `timestamp` 類型都改為 `:datetime` 的別名。
  修正在 `ActiveRecord` 之外，欄位類型不一致的問題，譬如 XML 序列化。
  ([Pull Request](https://github.com/rails/rails/pull/15184))

### 棄用

*   棄用 `sanitize_sql_hash_for_conditions`，沒有替代方案。使用
    `Relation` 物件來進行查詢與更新是偏好的使用方式。
    ([Commit](https://github.com/rails/rails/commit/d5902c9e))

*   棄用 `after_commit` 和 `after_rollback` 將錯誤吃掉的行為。
    ([Pull Request](https://github.com/rails/rails/pull/16537))

*   棄用未連接資料庫便呼叫 `DatabaseTasks.load_schema`，請改用 `DatabaseTasks.load_schema_current`。
    ([Commit](https://github.com/rails/rails/commit/f15cef67f75e4b52fd45655d7c6ab6b35623c608))

*   棄用 `Reflection#source_macro`，沒有替代方案。因為 Active Record 不再需要這個方法。
    ([Pull Request](https://github.com/rails/rails/pull/16373))

*   棄用對 `has_many :through` 自動偵測 counter cache 的支持。要自己對 `has_many` 與
  `belongs_to` 關聯，給 `through` 的紀錄手動設定。
  ([Pull Request](https://github.com/rails/rails/pull/15754))

*   棄用了 `serialized_attributes`，沒有替代方案。
  ([Pull Request](https://github.com/rails/rails/pull/15704))

*   棄用了當欄位不存在時，還會從 `column_for_attribute` 回傳 `nil` 的情況。
  Rails 5.0 將會回傳 Null Object。
  ([Pull Request](https://github.com/rails/rails/pull/15878))

*   依賴實體狀態（有定義接受參數的作用域）的關聯現在不能使用 `.joins`、`.preload` 以及 `.eager_load` 了。
  ([Commit](https://github.com/rails/rails/commit/ed56e596a0467390011bc9d56d462539776adac1))

*   棄用 `.find` 或 `.exists?` 可傳入 Active Record 物件。請先對物件呼叫 `#id`。
  (Commit [1](https://github.com/rails/rails/commit/d92ae6ccca3bcfd73546d612efaea011270bd270),
  [2](https://github.com/rails/rails/commit/d35f0033c7dec2b8d8b52058fb8db495d49596f7))

*   棄用僅支持一半的 PostgreSQL 範圍數值（不包含起始值）。目前我們把 PostgreSQL 的範圍對應到 Ruby 的範圍。但由於 Ruby 的範圍不支援不包含起始值，所以無法完全轉換。

    目前的解決方法是將起始數遞增，這是不對的，已經棄用了。關於不知如何遞增的子類型（比如沒有定義 `#succ`）會對不包含起始值的拋出 `ArgumentError`。

    ([Commit](https://github.com/rails/rails/commit/91949e48cf41af9f3e4ffba3e5eecf9b0a08bfc3))

### 值得一提的變化

*   PostgreSQL 連接器現在支持 PostgreSQL 9.4 的 `JSONB` 資料類型。
    ([Pull Request](https://github.com/rails/rails/pull/16220))

*   遷移的 `#references` 方法現在可以指定類型，`type` 選項，可用來指定外鍵的類型（比如 `:uuid`）。
    ([Pull Request](https://github.com/rails/rails/pull/16231))

*   單數關聯增加 `:required` 選項，用來定義關聯的存在性驗證。
  ([Pull Request](https://github.com/rails/rails/pull/16056))

*   導入 `ActiveRecord::Base#validate!`，會在記錄不合法時拋出 `RecordInvalid` 異常。
  ([Pull Request](https://github.com/rails/rails/pull/8639))

*   `ActiveRecord::Base#reload` 行為同 `m = Model.find(m.id)`，代表自訂的 `select` 不再保有額外的屬性。
  meaning that it no longer retains the extra attributes from custom `select`s.
  ([Pull Request](https://github.com/rails/rails/pull/15866))

*   導入 `bin/rake db:purge` 任務，用來清空當前環境的資料庫。
  ([Commit](https://github.com/rails/rails/commit/e2f232aba15937a4b9d14bd91e0392c6d55be58d))

*   `ActiveRecord::Dirty` 現在會偵測可變數值的改變。序列化過的屬性有變更才會儲存。
  修復了像是 PostgreSQL 不會偵測到變更的字串欄位、JSON 欄位。
  (Pull Requests [1](https://github.com/rails/rails/pull/15674),
  [2](https://github.com/rails/rails/pull/15786),
  [3](https://github.com/rails/rails/pull/15788))

* 新增 `ActiveRecord::Base` 物件的 `#pretty_print` 方法。
  ([Pull Request](https://github.com/rails/rails/pull/15172))

* PostgreSQL 與 SQLite 連接器不再預設限制字串只能 255 字元。
  ([Pull Request](https://github.com/rails/rails/pull/14579))

* `sqlite3:///some/path` 現在可以解析系統的絕對路徑 `/some/path`。
  相對路徑請使用 `sqlite3:some/path`。(先前是 `sqlite3:///some/path`
  會解析成 `some/path`。這個行為已在 Rails 4.1 被棄用了。  Rails 4.1.)
  ([Pull Request](https://github.com/rails/rails/pull/14569))

* 引入 `#validate` 作為 `#valid?` 的別名。
  ([Pull Request](https://github.com/rails/rails/pull/14456))

* `#touch` 現在可一次對多屬性操作。
  ([Pull Request](https://github.com/rails/rails/pull/14423))

* 新增 MySQL 5.6 以上版本的 fractional seconds 支持。
  (Pull Request [1](https://github.com/rails/rails/pull/8240), [2](https://github.com/rails/rails/pull/14359))

* 新增 PostgreSQL 連接器的 `citext` 支持。
  ([Pull Request](https://github.com/rails/rails/pull/12523))

* 新增 PostgreSQL 連接器的使用者自訂的範圍類型支持。
  ([Commit](https://github.com/rails/rails/commit/4cb47167e747e8f9dc12b0ddaf82bdb68c03e032))

Active Model
------------

請參考 [CHANGELOG][active-model] 來了解更多細節。

### 移除

*   移除了 `Validator#setup`，沒有替代方案。
  ([Pull Request](https://github.com/rails/rails/pull/15617))

### 棄用

*   棄用 `reset_#{attribute}`，請改用 `restore_#{attribute}`。
    ([Pull Request](https://github.com/rails/rails/pull/16180))

*   棄用 `ActiveModel::Dirty#reset_changes`，請改用 `#clear_changes_information`。
    ([Pull Request](https://github.com/rails/rails/pull/16180))

### 值得一提的變化

*   `ActiveModel::Dirty` 導入 `restore_attributes` 方法，用來回復更改的屬性到先前的數值。
    (Pull Request [1](https://github.com/rails/rails/pull/14861),
    [2](https://github.com/rails/rails/pull/16180))

*   `has_secure_password` 現在預設允許空密碼（只含空白的密碼也算空密碼）。
    ([Pull Request](https://github.com/rails/rails/pull/16412))

*    驗證啟用時，`has_secure_password` 現在會檢查密碼是否少於 72 個字元。
  ([Pull Request](https://github.com/rails/rails/pull/15708))

*    引入 `#validate` 作為 `#valid?` 的別名。
  ([Pull Request](https://github.com/rails/rails/pull/14456))

Active Support
--------------

請參考 [CHANGELOG][active-support] 來了解更多細節。

### 移除

*   移除棄用的 `Numeric#ago`、`Numeric#until`、`Numeric#since` 以及
  `Numeric#from_now`. ([Commit](https://github.com/rails/rails/commit/f1eddea1e3f6faf93581c43651348f48b2b7d8bb))

*   移除棄用 `ActiveSupport::Callbacks` 基於字串的終止符。
  ([Pull Request](https://github.com/rails/rails/pull/15100))

### 棄用

*   棄用 `Kernel#silence_stderr`、`Kernel#capture` 以及 `Kernel#quietly` 方法，沒有替代方案。([Pull Request](https://github.com/rails/rails/pull/13392))

* 棄用 `Class#superclass_delegating_accessor`，請改用 `Class#class_attribute`。
  ([Pull Request](https://github.com/rails/rails/pull/14271))

* 棄用 `ActiveSupport::SafeBuffer#prepend!` 請改用 `ActiveSupport::SafeBuffer#prepend`（兩者功能相同）。
  ([Pull Request](https://github.com/rails/rails/pull/14529))

### 值得一提的變化

*   導入新的設定選項： `active_support.test_order`，用來指定測試執行的順序，預設是 `:sorted`，在 Rails 5.0 將會改成 `:random`。([Commit](https://github.com/rails/rails/commit/53e877f7d9291b2bf0b8c425f9e32ef35829f35b))

*   `Object#try` 和 `Object#try!` 方法現在無需有訊息接收者也可以使用。
    ([Commit](https://github.com/rails/rails/commit/5e51bdda59c9ba8e5faf86294e3e431bd45f1830),
    [Pull Request](https://github.com/rails/rails/pull/17361))

*   `travel_to` 測試輔助方法現在會把 `usec` 部分截斷為 0。
    ([Commit](https://github.com/rails/rails/commit/9f6e82ee4783e491c20f5244a613fdeb4024beb5))

*   導入 `Object#itself` 作為 identity 函數（返回自身的函數）。(Commit [1](https://github.com/rails/rails/commit/702ad710b57bef45b081ebf42e6fa70820fdd810) 和 [2](https://github.com/rails/rails/commit/64d91122222c11ad3918cc8e2e3ebc4b0a03448a))

*   `Object#with_options` 方法現在無需有訊息接收者也可以使用。
    ([Pull Request](https://github.com/rails/rails/pull/16339))

*   導入 `String#truncate_words` 方法，可指定要單字截斷至幾個單字。
    ([Pull Request](https://github.com/rails/rails/pull/16190))

* 新增 `Hash#transform_values` 與 `Hash#transform_values!` 方法，來簡化 Hash
  值需要更新、但鍵保留不變這樣的常見模式。
  ([Pull Request](https://github.com/rails/rails/pull/15819))

* `humanize` 現在會去掉前面的底線。
  ([Commit](https://github.com/rails/rails/commit/daaa21bc7d20f2e4ff451637423a25ff2d5e75c7))

* 導入 `Concern#class_methods` 來取代 `module ClassMethods` 以及 `Kernel#concern`，
  來避免使用 `module Foo; extend ActiveSupport::Concern; end` 這樣的樣板。
  ([Commit](https://github.com/rails/rails/commit/b16c36e688970df2f96f793a759365b248b582ad))

致謝
----

許多人花費寶貴的時間貢獻至 Rails 專案，使 Rails 成為更穩定、更強韌的網路框架，參考[完整的 Rails 貢獻者清單](http://contributors.rubyonrails.org/)，感謝所有的貢獻者！

[railties]:       https://github.com/rails/rails/blob/4-2-stable/railties/CHANGELOG.md
[action-pack]:    https://github.com/rails/rails/blob/4-2-stable/actionpack/CHANGELOG.md
[action-view]:    https://github.com/rails/rails/blob/4-2-stable/actionview/CHANGELOG.md
[action-mailer]:  https://github.com/rails/rails/blob/4-2-stable/actionmailer/CHANGELOG.md
[active-record]:  https://github.com/rails/rails/blob/4-2-stable/activerecord/CHANGELOG.md
[active-model]:   https://github.com/rails/rails/blob/4-2-stable/activemodel/CHANGELOG.md
[active-support]: https://github.com/rails/rails/blob/4-2-stable/activesupport/CHANGELOG.md
