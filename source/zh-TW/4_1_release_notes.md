Ruby on Rails 4.1 發佈記
========================

Rails 4.1 精華摘要：

* 採用 Spring 來預載應用程式
* `config/secrets.yml`
* Action Pack Variants
* Action Mailer Preview

本篇僅記錄主要的變化。要了解關於已修復的 Bug、功能變更等，請參考 [Rails GitHub 主頁][rails]上各個 Gem 的 CHANGELOG 或是 [Rails 的提交歷史](https://github.com/rails/rails/commits/master)。

--------------------------------------------------------------------------------

升級至 Rails 4.1
------------------

如果您正試著升級現有的應用程式，最好有廣的測試覆蓋度。首先應先升級至 4.0，確保應用程式仍正常工作，接著再升上 4.1。升級需要注意的事項在 [Ruby on Rails 升級指南](upgrading_ruby_on_rails.html#upgrading-from-rails-4-0-to-rails-4-1)可以找到。

主要新功能
------------

### 應用程式預加載器：Spring

Spring 會預加載你的 Rails 應用程式。保持應用程式在背景執行，如此一來在執行 Rails 命令時：如跑測試、`rake`、`migrate` 時，不用每次都重啟 Rails 應用程式，加速你的開發流程。

新版 Rails 4.1 應用程式出廠內建 “Spring 化” 的 binstubs（aka，執行檔，如 `rails`、`rake`）。這表示 `bin/rails`、`bin/rake` 會自動採用 Spring 預載的那一份 Rails。

**執行 rake task：**

```
bin/rake test:models
```

**執行 console：**

```
bin/rails console
```

**查看 Spring**

```
$ bin/spring status
Spring is running:

 1182 spring server | my_app | started 29 mins ago
 3656 spring app    | my_app | started 23 secs ago | test mode
 3746 spring app    | my_app | started 10 secs ago | development mode
```

請查閱 [Spring README](https://github.com/rails/spring/blob/master/README.md) 了解所有功能。

參考 [Ruby on Rails 升級指南](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html)來了解如何在現有專案裡導入 Spring。

### `config/secrets.yml`

Rails 4.1 採用新的 `secrets.yml`，產生在 `config/` 目錄。這個檔案預設存有應用程式的 `secret_key_base`，也可以用來存放其它 secrets，比如存放外部 API 需要用的 access keys。例子：

`secrets.yml`:

```yaml
development:
  secret_key_base: "3b7cd727ee24e8444053437c36cc66c3"
  some_api_key: "b2c299a4a7b2fe41b6b7ddf517604a1c34"
```

如何讀：

```ruby
> Rails.application.secrets
=> "3b7cd727ee24e8444053437c36cc66c3"
> Rails.application.secrets.some_api_key
=> "SOMEKEY"
```

參考 [Ruby on Rails 升級指南](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html)來了解如何在現有專案裡導入此功能。

### Action Pack Variants

針對手機、平板、桌上型電腦及瀏覽器，常需要 `render` 不同格式的模版：`html`、`json`、`xml`。

__Variant 簡化了這件事。__

Request variant 是一種特殊的 request 格式，像是 `:tablet`、`:phone` 或 `:desktop`。

可在 `before_action` 裡設定 Variant：

```ruby
request.variant = :tablet if request.user_agent =~ /iPad/
```

在 Controller `action` 裡，`respond_to` 特殊格式跟一般格式方法相同：

```ruby
respond_to do |format|
  format.html do |html|
    html.tablet # 會 render app/views/projects/show.html+tablet.erb
    html.phone { extra_setup; render ... }
  end
end
```

再給每個特殊格式提供對應的模版：

```
app/views/projects/show.html.erb
app/views/projects/show.html+tablet.erb
app/views/projects/show.html+phone.erb
```

Variant 定義也可用 inline 寫法來簡化：

```ruby
respond_to do |format|
  format.js         { render "trash" }
  format.html.phone { redirect_to progress_path }
  format.html.none  { render "trash" }
end
```

### Action Mailer 預覽

Action Mailer Preview 提供你訪問特定 URL，來預覽 Email 信件。假設你有個 `Notifier` Mailer，則需要實現 `Notifier` 的 Preview Class，實作方法來返回信件內容：

```ruby
class NotifierPreview < ActionMailer::Preview
  def welcome
    Notifier.welcome(User.first)
  end
end
```

如此一來便可以訪問 http://localhost:3000/rails/mailers/notifier/welcome 來預覽 Email。

所有可預覽的 Email 可在此找到：http://localhost:3000/rails/mailers。

預設這些 preview class 產生在 `test/mailers/previews`、可以透過 `preview_path` 選項來調整存放的位置。

參見 [Action Mailer 的文件](http://api.rubyonrails.org/v4.1.0/classes/ActionMailer/Base.html)來了解更多細節。

### Active Record enums

宣告一個 `enum` 屬性，將屬性映射到資料庫的整數，並可透過名字查詢出來：

```ruby
class Conversation < ActiveRecord::Base
  enum status: [ :active, :archived ]
end

conversation.archived!
conversation.active? # => false
conversation.status  # => "archived"

Conversation.archived # => Relation for all archived Conversations
```

參見 [active_record/enum.rb](http://api.rubyonrails.org/v4.1.0/classes/ActiveRecord/Enum.html) 來了解更多細節。

### Message Verifier 訊息驗證器

訊息驗證器用來產生與驗證訊息，可以用來保護敏感資料（如 `remember_me` 的 token）傳輸的安全性。

```ruby
signed_token = Rails.application.message_verifier(:remember_me).generate(token)
Rails.application.message_verifier(:remember_me).verify(signed_token) # => token

Rails.application.message_verifier(:remember_me).verify(tampered_token)
# 拋出異常 ActiveSupport::MessageVerifier::InvalidSignature
```

### Module#concerning

一種自然、輕量級的方式來拆分 Class 內的職責。

```ruby
class Todo < ActiveRecord::Base
  concerning :EventTracking do
    included do
      has_many :events
    end

    def latest_event
      ...
    end

    private
      def some_internal_method
        ...
      end
  end
end
```

等同於以前要定義 `EventTracking` Module，`extend ActiveSupport::Concern`，再混入 (mixin) `Todo` Class。

參見 [Module#concerning](http://api.rubyonrails.org/v4.1.0/classes/Module/Concerning.html) 來了解更多細節。

### CSRF 機制新增遠端 `<script>` 防護。

Rails 的跨站偽造請求（CSRF）防護機制現在也會保護從第三方 JavaScript 來的 GET 請求了！這預防第三方網站引用你的 JavaScript，試圖竊取敏感資料。

這意味著任何訪問 `.js` URL 的測試會失敗（因為受 CSRF 保護），必須明確指定使用 `xhr` （`XmlHttpRequests`）。

```ruby
post :create, format: :js
```

改寫為

```ruby
xhr :post, :create, format: :js
```

Railties
------------

請參考 [CHANGELOG][Railties-CHANGELOG] 來了解更多細節。

### 移除

* 移除了 `update:application_controller` rake task。

* 移除了 `Rails.application.railties.engines`。

* Rails 移除了 `config.threadsafe!` 設定。

* 移除了 `ActiveRecord::Generators::ActiveModel#update_attributes`，
    請改用 `ActiveRecord::Generators::ActiveModel#update`。

* 移除了 `config.whiny_nils` 設定。

* 移除了用來跑測試的兩個 task：`rake test:uncommitted` 與 `rake test:recent`。

### 值得一提的變化

* [Spring](https://github.com/rails/spring) 納入 Rails 4.1 應用程式的預設 Gem，列在 `Gemfile`
  的 `group :development` 裡，production 環境不會安裝。[PR#12958](https://github.com/rails/rails/pull/12958)

* `BACKTRACE` 環境變數可看測試的完整 backtrace （沒有過濾敏感資料）。[Commit](https://github.com/rails/rails/commit/84eac5dab8b0fe9ee20b51250e52ad7bfea36553)

* 環境設定檔可設定 `MiddlewareStack#unshift`。 [PR#12749](https://github.com/rails/rails/pull/12749)

* 新增 `Application#message_verifier` 方法來回傳訊息驗證器。[PR#12995](https://github.com/rails/rails/pull/12995)

* 預設產生的 `test_helper.rb` 會 `require` `test_help.rb`，幫你把測試的資料庫與 `db/schema.rb` （或 `db/structure.sql`）同步。但發現尚未執行的 migration 與 schema 不一致時會拋出錯誤。錯誤拋出與否則是由這個設定決定：`config.active_record.maintain_test_schema = false`，參見此 [PR#13528](https://github.com/rails/rails/pull/13528)。

* 引入一個方便的方法： `Rails.gem_version`，來回傳 `Gem::Version.new(Rails.version)` 的值，一個更加可靠的方式來做版本比對。 [PR#14103](https://github.com/rails/rails/pull/14103)

Action Pack
--------------

請參考 [CHANGELOG][AP-CHANGELOG] 來了解更多細節。

### 移除

* 移除了 Rails 針對整合測試的補救方案（fallback），請設定 `ActionDispatch.test_app`。

* 移除了 `config.page_cache_extension` 設定。

* 移除了 `ActionController::RecordIdentifier`，請改用 `ActionView::RecordIdentifier`。

* 更改 Action Controller 下列常數的名稱：

    | 移除                                | 繼任                             |
    |:-----------------------------------|:--------------------------------|
    | ActionController::AbstractRequest  | ActionDispatch::Request         |
    | ActionController::Request          | ActionDispatch::Request         |
    | ActionController::AbstractResponse | ActionDispatch::Response        |
    | ActionController::Response         | ActionDispatch::Response        |
    | ActionController::Routing          | ActionDispatch::Routing         |
    | ActionController::Integration      | ActionDispatch::Integration     |
    | ActionController::IntegrationTest  | ActionDispatch::IntegrationTest |

### 值得一提的變化

* `protect_from_forgery` 現在也會預防跨站的 `<script>`。請更新測試，使用 `xhr :get, :foo, format: :js` 來取代 `get :foo, format: :js`。[PR#13345](https://github.com/rails/rails/pull/13345)

* `#url_for` 接受額外的 options，可將選項打包成 hash，放在陣列傳入。[PR#9599](https://github.com/rails/rails/pull/9599)

* 新增 `session#fetch` 方法，行為與 [Hash#fetch](http://www.ruby-doc.org/core-2.0.0/Hash.html#method-i-fetch) 類似，差別在回傳值永遠會存回 session。 [PR#12692](https://github.com/rails/rails/pull/12692)

* 將 Action View 從 Action Pack 裡整個抽離出來。 [PR#11032](https://github.com/rails/rails/pull/11032)

* 記錄受 deep munge 影響的 key。 [PR#13813](https://github.com/rails/rails/pull/13813)

* 新設定： `config.action_dispatch.perform_deep_munge`。用來決定是不是要開啟 "deep munging" （deep munge 用來處理安全風險 CVE-2013-0155）。 [PR#13188](https://github.com/rails/rails/pull/13188)

* 新設定：`config.action_dispatch.cookies_serializer`。用來指定加密與簽署 cookie jars 的 serializer。 [PR#13692](https://github.com/rails/rails/pull/13692) & [PR#13945](https://github.com/rails/rails/pull/13945) & [更多資訊](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#cookies-serializer)

* 新增 `render :plain`、`render :html` 以及 `render
  :body`。 [PR#14062](https://github.com/rails/rails/pull/14062) & [更多資訊](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#rendering-content-from-string)

Action Mailer
------------------

請參考 [CHANGELOG](https://github.com/rails/rails/blob/4-1-stable/actionmailer/CHANGELOG.md) 來了解更多細節。

### 值得一提的變化

* 新增 Mailer 預覽信件功能（基於 37 Signals 公司所開發的 mail_view Gem。）[Commit](https://github.com/rails/rails/commit/d6dec7fcb6b8fddf8c170182d4fe64ecfc7b2261)

*  Action Mailer 產生 mail 的時間會寫到 log 裡。 [PR#12556](https://github.com/rails/rails/pull/12556)

Active Record
------------------

請參考 [CHANGELOG][AR-CHANGELOG] 來了解更多細節。

### 移除

* 移除了傳入 `nil` 至右列 `SchemaCache` 的方法：`primary_keys`、`tables`、`columns` 及 `columns_hash`。

* 從 `ActiveRecord::Migrator#migrate` 移除了 block filter。

* 從 `ActiveRecord::Migrator` 移除了 String constructor。

* 移除了 scope 沒傳 callable object 的用法。

* 移除了 `transaction_joinable=`，請改用 `begin_transaction` 搭配 `:joinable` 選項的組合。

* 移除了 `decrement_open_transactions`。

* 移除了 `increment_open_transactions`。

* 移除了 `PostgreSQLAdapter#outside_transaction?`，可用 `#transaction_open?` 來取代。

* 移除了 `ActiveRecord::Fixtures.find_table_name` 請改用 `ActiveRecord::Fixtures.default_fixture_model_name`。

* 從 `SchemaStatements` 移除了 `columns_for_remove`。

* 移除了 `SchemaStatements#distinct`。

* 將棄用的 `ActiveRecord::TestCase` 移到 Rails test 裡。

* 移除有 `:dependent` 選項的關聯傳入 `:restrict` 選項。

* 移除了 association 這幾個選項 `:delete_sql`、`:insert_sql`、`:finder_sql` 及 `:counter_sql`。

* 從 Column 移除了 `type_cast_code` 方法。

* 移除了 `ActiveRecord::Base#connection` 實體方法，請透過 Class 來使用。

* 移除了 `auto_explain_threshold_in_seconds` 的警告。

* 移除了 `Relation#count` 的 `:distinct` 選項。

* 移除了 `partial_updates`、`partial_updates?` 與 `partial_updates=`。

* 移除了 `scoped`。

* 移除了 `default_scopes?`。

* 移除了隱式的 join references。

* 移掉 `activerecord-deprecated_finders` gem 的相依性，請參考[該 Gem 的 README](https://github.com/rails/activerecord-deprecated_finders#active-record-deprecated-finders) 來了解更多資訊。

* 移除了 `implicit_readonly`。請改用 `readonly` 方法，並將 record 明確標明為 `readonly`。 [PR#10769](https://github.com/rails/rails/pull/10769)

### 棄用

* 棄用了任何地方都沒用到的 `quoted_locking_column` 方法。

* Rails 內部棄用了 `ConnectionAdapters::SchemaStatements#distinct`。 [PR#10556](https://github.com/rails/rails/pull/10556)

* 棄用 `rake db:test:*` 系列的 task，因為現在會自動設定好測試資料庫。參見 Railties 的發佈記。[PR#13528](https://github.com/rails/rails/pull/13528)

* 棄用了無用的 `ActiveRecord::Base.symbolized_base_class` 與 `ActiveRecord::Base.symbolized_sti_name`，且沒有替代方案。[Commit](https://github.com/rails/rails/commit/97e7ca48c139ea5cce2fa9b4be631946252a1ebd)

### 值得一提的變化

* 預設 scope 不會再被一連串的條件語句給覆蓋掉。

  之前的行為：若在 Model 有定義 `default_scope`，則會被一連串的條件語句給覆蓋掉。現在會像其它 Scope 一樣合併。[更多細節](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#changes-on-default-scopes)

* 新增 `ActiveRecord::Base.to_param` 來顯示漂亮的 URL。 [PR#12891](https://github.com/rails/rails/pull/12891)

* 新增 `ActiveRecord::Base.no_touching`，可允許忽略對 Model 的 touch。 [PR#12772](https://github.com/rails/rails/pull/12772)

* 統一了 `MysqlAdapter` 與 `Mysql2Adapter` 的布林轉換，`true` 會返回 `1`，`false` 返回 `0`。 [PR#12425](https://github.com/rails/rails/pull/12425)

* `unscope` 現在移除了 `default_scope` 規範的 conditions。[Commit](https://github.com/rails/rails/commit/94924dc32baf78f13e289172534c2e71c9c8cade)

* 新增 `ActiveRecord::QueryMethods#rewhere`，會覆寫已存在的 where 條件。[Commit](https://github.com/rails/rails/commit/f950b2699f97749ef706c6939a84dfc85f0b05f2)

* 擴充了 `ActiveRecord::Base#cache_key`，可接受多個 timestamp，會使用數值最大的 timestamp。[Commit](https://github.com/rails/rails/commit/e94e97ca796c0759d8fcb8f946a3bbc60252d329)

* 新增 `ActiveRecord::Base#enum`，用來枚舉 attributes。將 attributes 映射到資料庫的整數，並可透過名字查詢出來。[Commit](https://github.com/rails/rails/commit/db41eb8a6ea88b854bf5cd11070ea4245e1639c5)

* 寫入資料庫時，JSON 會做類型轉換。這樣子讀寫才會一致。 [PR#12643](https://github.com/rails/rails/pull/12643)

* 寫入資料庫時，hstore 會做類型轉換，這樣子讀寫才會一致。[Commit](https://github.com/rails/rails/commit/5ac2341fab689344991b2a4817bd2bc8b3edac9d)

* `next_migration_number` 可供第三方函式庫存取。 [PR#12407](https://github.com/rails/rails/pull/12407)

* 若是呼叫 `update_attributes` 的參數有 `nil`，則會拋出 `ArgumentError`。更精準的說，傳進來的參數，沒有回應(`respond_to`) `stringify_keys` 的話，會拋出錯誤。[PR#9860](https://github.com/rails/rails/pull/9860)

* `CollectionAssociation#first`/`#last` (`has_many`) ，Query 會使用 `LIMIT` 來限制提取的數量，而不是將整個 collection 載入出來。 [PR#12137](https://github.com/rails/rails/pull/12137)

* 對 Active Record Model 的類別做 `inspect` 不會去連資料庫。這樣當資料庫不存在時，`inspect` 才不會噴錯誤。[PR#11014](https://github.com/rails/rails/pull/11014)

* 移除了 `count` 的欄位限制，SQL 不正確時，讓資料庫自己丟出錯誤。 [PR#10710](https://github.com/rails/rails/pull/10710)

* Rails 現在會自動偵測 inverse associations。如果 association 沒有設定 `:inverse_of`，則 Active Record 會自己猜出對應的 associaiton。[PR#10886](https://github.com/rails/rails/pull/10886)

* `ActiveRecord::Relation` 會處理有別名的 attributes。當使用符號作為 key 時，Active Record 現在也會一起翻譯別名的屬性了，將其轉成資料庫內所使用的欄位名。[PR#7839](https://github.com/rails/rails/pull/7839)

* Fixtures 檔案中的 ERB 不在 main 物件上下文裡執行了，多個 fixtures 使用的 Helper ，需要定義在被 `ActiveRecord::FixtureSet.context_class` 包含的 Module 裡。 [PR#13022](https://github.com/rails/rails/pull/13022)

* 若明確指定了 `RAILS_ENV`，則不要建立或刪除資料庫。 [PR#13629](https://github.com/rails/rails/pull/13629)

* `Relation` 不再有像是 `#map!` 以及 `#delete_if` 的 mutator 方法。要使用這些方法之前，先呼叫 `#to_a`。 [PR#13314](https://github.com/rails/rails/pull/13314)

* `find_in_batches`、`find_each`、`Result#each` 以及 `Enumerable#index_by`，現在會回傳 `Enumerator`，可以用來計算 `size`。[PR#13938](https://github.com/rails/rails/pull/13938)

* `scope`、`enum` 以及 Associations 現在對“危險的”名稱會拋出警告。 [PR#13450](https://github.com/rails/rails/pull/13450) & [PR#13896](https://github.com/rails/rails/pull/13896)

* 確保 `second` 致 `fifth` 的 Finder 方法與 `first` 行為一致。 [PR#13757](https://github.com/rails/rails/pull/13757)

* `touch` 方法會觸發 `after_commit` 與 `after_rollback` Callbacks. [PR#12031](https://github.com/rails/rails/pull/12031)

* `sqlite >= 3.8.0` 啟用 partial indexes。 [PR#13350](https://github.com/rails/rails/pull/13350)

* 讓 `change_column_null` 是可逆操作。[Commit](https://github.com/rails/rails/commit/724509a9d5322ff502aefa90dd282ba33a281a96)

* 加入一個 flag 來禁止資料庫遷移後的 schema dump。Production 環境預設為 `false`。 [PR#13948](https://github.com/rails/rails/pull/13948)

Active Model
--------------

請參考 [CHANGELOG][AM-CHANGELOG] 來了解更多細節。

### 棄用

* 棄用了 `Validator#setup`。現在要手動在 Validator 的 constructor 裡處理。[Commit](https://github.com/rails/rails/commit/7d84c3a2f7ede0e8d04540e9c0640de7378e9b3a)

### 值得一提的變化

* `ActiveModel::Dirty` 加入新的 API：`reset_changes` 與 `changes_applied`，來控制改變的狀態。

* 定義 validation 可以指定多個 context。 [PR#13754](https://github.com/rails/rails/pull/13754)

* `attribute_changed?` 現在可以接受 hash，來檢查 attribute 是否從 `:from` 變到 `:to`。 [PR#13131](https://github.com/rails/rails/pull/13131)

Active Support
------------------

請參考 [CHANGELOG](https://github.com/rails/rails/blob/4-1-stable/activesupport/CHANGELOG.md) 來了解更多細節。

### 移除

* 移除對 `MultiJSON` Gem 的依賴。也就是說 `ActiveSupport::JSON.decode` 不再接受給 `MultiJSON` 的 hash 參數。[PR#10576](https://github.com/rails/rails/pull/10576)

* 移除了 `encode_json` hook，本來可以用來把 object 轉成 JSON。這個功能被抽成了 [activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) Gem，請參考 [PR#12183](https://github.com/rails/rails/pull/12183) 與[這裡](upgrading_ruby_on_rails.html#changes-in-json-handling)。

* 移除了 `ActiveSupport::JSON::Variable`。

* 移除了 `String#encoding_aware?`（`core_ext/string/encoding.rb`）。

* 移除了 `Module#local_constant_names` 請改用 `Module#local_constants`。

* 移除了 `DateTime.local_offset` 請改用 `DateTime.civil_from_format`。

* 移除了 `Logger` （`core_ext/logger.rb`）。

* 移除了 `Time#time_with_datetime_fallback`、`Time#utc_time` 與
  `Time#local_time`，請改用 `Time#utc` 與 `Time#local`。

* 移除了 `Hash#diff`。

* 移除了 `Date#to_time_in_current_zone` 請改用 `Date#in_time_zone`。

* 移除了 `Proc#bind`。

* 移除了 `Array#uniq_by` 與 `Array#uniq_by!` 請改用 Ruby 原生的
  `Array#uniq` 與 `Array#uniq!`。

* 移除了 `ActiveSupport::BasicObject` 請改用 `ActiveSupport::ProxyObject`。

* 移除了 `BufferedLogger`, 請改用 `ActiveSupport::Logger`。

* 移除了 `assert_present` 與 `assert_blank`，請改用 `assert
  object.blank?` 與 `assert object.present?`。

* Remove deprecated `#filter` method for filter objects, use the corresponding
  method instead (e.g. `#before` for a before filter).

* Removed 'cow' => 'kine' irregular inflection from default
  inflections. ([Commit](https://github.com/rails/rails/commit/c300dca9963bda78b8f358dbcb59cabcdc5e1dc9))

### 棄用

* 棄用了 `Numeric#{ago,until,since,from_now}`，要明確的將數值轉成 `AS::Duration`。比如 `5.ago` 請改成 `5.seconds.ago`。 [PR#12389](https://github.com/rails/rails/pull/12389)

* 引用路徑裡棄用了 `active_support/core_ext/object/to_json`。請改用`active_support/core_ext/object/json` 來取代。 [PR#12203](https://github.com/rails/rails/pull/12203)

* 棄用了 `ActiveSupport::JSON::Encoding::CircularReferenceError`。這個功能被抽成了[activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) Gem，請參考 [PR#12183](https://github.com/rails/rails/pull/ 12183) 與[這裡](upgrading_ruby_on_rails.html#changes-in-json-handling)。

* 棄用了 `ActiveSupport.encode_big_decimal_as_string` 選項。這個功能被抽成了[activesupport-json_encoder](https://github.com/rails/activesupport-json_encoder) Gem，請參考 [PR#12183](https://github.com/rails/rails/pull/ 12183) 與[這裡](upgrading_ruby_on_rails.html#changes-in-json-handling)。

* 棄用自訂的 `BigDecimal`
  serialization。 [PR#13911](https://github.com/rails/rails/pull/13911)

### 值得一提的變化

* 使用 JSON gem 重寫 ActiveSupport 的 JSON Encoding 部分，提升了純 Ruby 編碼的效率。參考 [PR#12183](https://github.com/rails/rails/pull/12183) 與[這裡](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#changes-in-json-handling)。

* 提升 JSON gem 相容性。 [PR#12862](https://github.com/rails/rails/pull/12862) 與[這裡](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#changes-in-json-handling)

* 新增 `ActiveSupport::Testing::TimeHelpers#travel` 與 `#travel_to`。這些方法透過 stubbing `Time.now` 與 `Date.today`，可設定任何時間，坐時光旅行。

* 新增 `ActiveSupport::Testing::TimeHelpers#travel_back`。這個方法將當下時間回到原本的狀態。透過移除 `travel` 與 `travel_to` 加入的 stubs 辦到。 [PR#13884](https://github.com/rails/rails/pull/13884)

* 新增 `Numeric#in_milliseconds`，像是 1 小時有幾毫秒：`1.hour.in_milliseconds`。可以將時間轉成毫秒，再餵給 JavaScript 的 `getTime()` 函數。[Commit](https://github.com/rails/rails/commit/423249504a2b468d7a273cbe6accf4f21cb0e643)

* 新增了 `Date#middle_of_day`、`DateTime#middle_of_day` 與 `Time#middle_of_day`
  方法。同時添加了 `midday`、`noon`、`at_midday`、`at_noon`、`at_middle_of_day` 作為別名。[PR#10879](https://github.com/rails/rails/pull/10879)

* 新增 `Date#all_week/month/quarter/year` 用來產生一組日期範圍。  [PR#9685](https://github.com/rails/rails/pull/9685)

* 新增 `Time.zone.yesterday` 以及
  `Time.zone.tomorrow`。 [PR#12822](https://github.com/rails/rails/pull/12822)

* `String#gsub(pattern,'')` 可簡寫為 `String#remove(pattern)`。[Commit](https://github.com/rails/rails/commit/5da23a3f921f0a4a3139495d2779ab0d3bd4cb5f)

* 新增 `Hash#compact` 與 `Hash#compact!` 來移除 hash 中的 nil。 [PR#13632](https://github.com/rails/rails/pull/13632)

* `blank?` and `present?` 會返回 singleton。 ([Commit](https://github.com/rails/rails/commit/126dc47665c65cd129967cbd8a5926dddd0aa514))

* 新的設定： `I18n.enforce_available_locales` 預設是 `true`。代表 `I18n` 會確保所有傳入的 locale 都預先在 `available_locales` 裡宣告。 [PR#13341](https://github.com/rails/rails/pull/13341)

* 引入 `Module#concerning`：一種自然、輕量級的方式來拆分 Class 內的職責。[Commit](https://github.com/rails/rails/commit/1eee0ca6de975b42524105a59e0521d18b38ab81)

* 新增 `Object#presence_in` 來簡化對數值做白名單。[Commit](https://github.com/rails/rails/commit/4edca106daacc5a159289eae255207d160f22396)

致謝
----

許多人花了寶貴的時間貢獻至 Rails 專案，使 Rails 成為更穩定、更強韌的網路框架，參考[完整的 Rails 貢獻者清單](http://contributors.rubyonrails.org/)，感謝所有的貢獻者！

[rails]: https://github.com/rails/rails
[Railties-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/railties/CHANGELOG.md
[AR-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/activerecord/CHANGELOG.md
[AP-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/actionpack/CHANGELOG.md
[AM-CHANGELOG]: https://github.com/rails/rails/blob/4-1-stable/activemodel/CHANGELOG.md
[variants]: https://github.com/rails/rails/commit/2d3a6a0cb8df0360dd588a4d2fb260dd07cc9bcf
[spring]: https://github.com/jonleighton/rails/commit/df50e3064abc3099adc524f381ffced0dab84869
