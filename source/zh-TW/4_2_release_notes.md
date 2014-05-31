Ruby on Rails 4.2 Release Notes
===============================

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

* The `rails application` command has been removed without replacement.
  ([Pull Request](https://github.com/rails/rails/pull/11616))

### 值得一提的變化

* Introduced `bin/setup` script to bootstrap an application.
  ([Pull Request](https://github.com/rails/rails/pull/15189))

* Changed default value for `config.assets.digest` to `true` in development.
  ([Pull Request](https://github.com/rails/rails/pull/15155))

* Introduced an API to register new extensions for `rake notes`.
  ([Pull Request](https://github.com/rails/rails/pull/14379))

* Introduced `Rails.gem_version` as a convenience method to return `Gem::Version.new(Rails.version)`.
  ([Pull Request](https://github.com/rails/rails/pull/14101))


Action Pack
-----------

請參考 [CHANGELOG][AP-CHANGELOG] 來了解更多細節。

### 棄用

* "Soft deprecated" the `*_filter` family methods in favor of the `*_action`
  family methods:

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

  If your application is depending on these methods, you should use the
  replacement `*_action` methods instead.
  ([Commit](https://github.com/rails/rails/commit/6c5f43bab8206747a8591435b2aa0ff7051ad3de))

### 值得一提的變化

* Added HTTP method `MKCALENDAR` from RFC-4791
  ([Pull Request](https://github.com/rails/rails/pull/15121))

* `*_fragment.action_controller` notifications now include the controller and action name
  in the payload.
  ([Pull Request](https://github.com/rails/rails/pull/14137))

* Segments that are passed into URL helpers are now automatically escaped.
  ([Commit](https://github.com/rails/rails/commit/5460591f0226a9d248b7b4f89186bd5553e7768f))

* Improved Routing Error page with fuzzy matching for route search.
  ([Pull Request](https://github.com/rails/rails/pull/14619))

* Added option to disable logging of CSRF failures.
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

* Removed deprecated `Numeric#ago`, `Numeric#until`, `Numeric#since`,
  `Numeric#from_now`. ([Commit](https://github.com/rails/rails/commit/f1eddea1e3f6faf93581c43651348f48b2b7d8bb))

* Removed deprecated string based terminators for `ActiveSupport::Callbacks`.
  ([Pull Request](https://github.com/rails/rails/pull/15100))

### 棄用

* Deprecated `Class#superclass_delegating_accessor`, use `Class#class_attribute`
  instead. ([Pull Request](https://github.com/rails/rails/pull/14271))

* Deprecated `ActiveSupport::SafeBuffer#prepend!` as `ActiveSupport::SafeBuffer#prepend`
  now performs the same function. ([Pull Request](https://github.com/rails/rails/pull/14529))

### 值得一提的變化

* The `humanize` inflector helper now strips any leading underscores.
  ([Commit](https://github.com/rails/rails/commit/daaa21bc7d20f2e4ff451637423a25ff2d5e75c7))

* Added `SecureRandom::uuid_v3` and `SecureRandom::uuid_v5`.
  ([Pull Request](https://github.com/rails/rails/pull/12016))

* Introduce `Concern#class_methods` as an alternative to `module ClassMethods`,
  as well as `Kernel#concern` to avoid the `module Foo; extend ActiveSupport::Concern; end`
  boilerplate. ([Commit](https://github.com/rails/rails/commit/b16c36e688970df2f96f793a759365b248b582ad))

致謝
----

許多人花了寶貴的時間貢獻至 Rails 專案，使 Rails 成為更穩定、更強韌的網路框架，參考[完整的 Rails 貢獻者清單](http://contributors.rubyonrails.org/)，感謝所有的貢獻者！

[rails]: https://github.com/rails/rails
[Railties-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/railties/CHANGELOG.md
[AR-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/activerecord/CHANGELOG.md
[AP-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/actionpack/CHANGELOG.md
[AM-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/activemodel/CHANGELOG.md
