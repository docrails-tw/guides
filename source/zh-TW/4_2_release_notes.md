Ruby on Rails 4.2 發佈記
========================

Rails 4.2 精華摘要：

* ...
* ...

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

* 棄用 `*_filter` 的方法，偏好 `*_action` 的方法。

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

  若應用程式依賴這些 `*_filter` 方法，應該使用 `*_action` 方法替換。
  ([Commit](https://github.com/rails/rails/commit/6c5f43bab8206747a8591435b2aa0ff7051ad3de))

### 值得一提的變化

* 從 RFC-4791 新增 HTTP 方法 `MKCALENDAR`。
  ([Pull Request](https://github.com/rails/rails/pull/15121))

* `*_fragment.action_controller` 通知訊息的 Payload 現在包含 Controller 與動作名稱。
  ([Pull Request](https://github.com/rails/rails/pull/14137))

* 傳入 URL 輔助方法的片段現在會自動 Escaped。
  ([Commit](https://github.com/rails/rails/commit/5460591f0226a9d248b7b4f89186bd5553e7768f))

* 改善路由錯誤頁面，搜索路由支持模糊搜尋。
  ([Pull Request](https://github.com/rails/rails/pull/14619))

* 新增關掉 CSRF 失敗記錄的選項。
  ([Pull Request](https://github.com/rails/rails/pull/14280))


Action Mailer
-------------

請參考 [CHANGELOG](https://github.com/rails/rails/blob/4-1-stable/actionmailer/CHANGELOG.md) 來了解更多細節。

### 值得一提的變化

* ...
* ...


Active Record
-------------

請參考 [CHANGELOG][AR-CHANGELOG] 來了解更多細節。

### 值得一提的變化

* ...
* ...


Active Model
------------

請參考 [CHANGELOG][AM-CHANGELOG] 來了解更多細節。

### 值得一提的變化

* ...
* ...


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
