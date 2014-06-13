Ruby on Rails 4.2 發佈記
========================

Rails 4.2 精華摘要：

本篇僅記錄主要的變化。要了解關於已修復的 Bug、功能變更等，請參考 [Rails GitHub 主頁][rails]上各個 Gem 的 CHANGELOG 或是 [Rails 的提交歷史](https://github.com/rails/rails/commits/master)。

--------------------------------------------------------------------------------

升級至 Rails 4.2
----------------------

如果您正試著升級現有的應用程式，最好有廣的測試覆蓋度。首先應先升級至 4.1，確保應用程式仍正常工作，接著再升上 4.2。升級需要注意的事項在 [Ruby on Rails 升級指南](upgrading_ruby_on_rails.html#upgrading-from-rails-4-1-to-rails-4-2)可以找到。

主要的新功能
--------------

Railties
--------

請參考 [CHANGELOG][Railties-CHANGELOG] 來了解更多細節。

### 移除

* 移除了 `rails application` 命令。
  ([Pull Request](https://github.com/rails/rails/pull/11616))

### 值得一提的變化

* 導入 `bin/setup` 腳本來啟動應用程式。
  ([Pull Request](https://github.com/rails/rails/pull/15189))

* `config.assets.digest` 在開發模式的預設值改為 `true`。
  ([Pull Request](https://github.com/rails/rails/pull/15155))

* 導入給 `rake notes` 註冊新擴充功能的 API。
  ([Pull Request](https://github.com/rails/rails/pull/14379))

* 導入 `Rails.gem_version` 作為回傳 `Gem::Version.new(Rails.version)` 的便捷方法。
  ([Pull Request](https://github.com/rails/rails/pull/14101))

Action Pack
-----------

請參考 [CHANGELOG][AP-CHANGELOG] 來了解更多細節。

### 棄用

* Deprecated support for setting the `to:` option of a router to a symbol or a
  string that does not contain a `#` character:

      get '/posts', to: MyRackApp    => (No change necessary)
      get '/posts', to: 'post#index' => (No change necessary)
      get '/posts', to: 'posts'      => get '/posts', controller: :posts
      get '/posts', to: :index       => get '/posts', action: :index

  ([Commit](https://github.com/rails/rails/commit/cc26b6b7bccf0eea2e2c1a9ebdcc9d30ca7390d9))

### 值得一提的變化

* `*_filter` 方法已經從文件中移除，已經不鼓勵使用。偏好使用 `*_action` 方法：

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

Action Mailer
-------------

請參考 [CHANGELOG](https://github.com/rails/rails/blob/4-1-stable/actionmailer/CHANGELOG.md) 來了解更多細節。

### 值得一提的變化

Active Record
-------------

請參考 [CHANGELOG][AR-CHANGELOG] 來了解更多細節。

### 棄用

* 依賴實體狀態（有定義接受參數的作用域）的關聯現在不能使用 `.joins`、`.preload` 以及 `.eager_load` 了。
  ([Commit](https://github.com/rails/rails/commit/ed56e596a0467390011bc9d56d462539776adac1))

* 棄用 `.find` 或 `.exists?` 可傳入 Active Record 物件。請先對物件呼叫 `#id`。
  (Commit [1](https://github.com/rails/rails/commit/d92ae6ccca3bcfd73546d612efaea011270bd270),
  [2](https://github.com/rails/rails/commit/d35f0033c7dec2b8d8b52058fb8db495d49596f7))

* 棄用半支持的 PostgreSQL 範圍數值（不包含起始值）。目前我們把 PostgreSQL 的範圍對應到 Ruby 的範圍。但由於 Ruby 的範圍不支援不包含起始值，所以無法完全轉換。

  目前的解決方法是將起始數遞增，這是不對的，已經棄用了。關於不知如何遞增的子類型（比如沒有定義 `#succ`）會對不包含起始值的拋出 `ArgumentError`。

  ([Commit](https://github.com/rails/rails/commit/91949e48cf41af9f3e4ffba3e5eecf9b0a08bfc3))

### 值得一提的變化

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

* 新增 PostgreSQL 連接器的使用自建的範圍類型支持。
  ([Commit](https://github.com/rails/rails/commit/4cb47167e747e8f9dc12b0ddaf82bdb68c03e032))

Active Model
------------

請參考 [CHANGELOG][AM-CHANGELOG] 來了解更多細節。

### 值得一提的變化

* 引入 `#validate` 作為 `#valid?` 的別名。
  ([Pull Request](https://github.com/rails/rails/pull/14456))

Active Support
--------------

請參考 [CHANGELOG](https://github.com/rails/rails/blob/4-1-stable/activesupport/CHANGELOG.md) 來了解更多細節。

### 移除

* 移除棄用的 `Numeric#ago`、`Numeric#until`、`Numeric#since` 以及
  `Numeric#from_now`. ([Commit](https://github.com/rails/rails/commit/f1eddea1e3f6faf93581c43651348f48b2b7d8bb))

* 移除棄用 `ActiveSupport::Callbacks` 基於字串的終止符。
  ([Pull Request](https://github.com/rails/rails/pull/15100))

### 棄用

* 棄用 `Class#superclass_delegating_accessor`，請改用 `Class#class_attribute`。
  ([Pull Request](https://github.com/rails/rails/pull/14271))

* 棄用 `ActiveSupport::SafeBuffer#prepend!` 請改用 `ActiveSupport::SafeBuffer#prepend`（兩者功能相同）。
  ([Pull Request](https://github.com/rails/rails/pull/14529))

### 值得一提的變化

* `humanize` 現在會去掉前面的底線。
  ([Commit](https://github.com/rails/rails/commit/daaa21bc7d20f2e4ff451637423a25ff2d5e75c7))

* 新增 `SecureRandom::uuid_v3` 和 `SecureRandom::uuid_v5` 方法。
  ([Pull Request](https://github.com/rails/rails/pull/12016))

* 導入 `Concern#class_methods` 來取代 `module ClassMethods` 以及 `Kernel#concern`，
  來避免使用 `module Foo; extend ActiveSupport::Concern; end` 這樣的樣板。
  ([Commit](https://github.com/rails/rails/commit/b16c36e688970df2f96f793a759365b248b582ad))

致謝
----

許多人花了寶貴的時間貢獻至 Rails 專案，使 Rails 成為更穩定、更強韌的網路框架，參考[完整的 Rails 貢獻者清單](http://contributors.rubyonrails.org/)，感謝所有的貢獻者！

[rails]: https://github.com/rails/rails
[Railties-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/railties/CHANGELOG.md
[AR-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/activerecord/CHANGELOG.md
[AP-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/actionpack/CHANGELOG.md
[AM-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/activemodel/CHANGELOG.md
