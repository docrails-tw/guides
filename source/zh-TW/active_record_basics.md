**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://rails.ruby.tw.**

Active Record 基礎
====================

本篇介紹 Active Record。

讀完本篇，您將了解：

* 物件關係映射（Object Relational Mapping）與 Active Record 是什麼，以及如何在 Rails 使用它們。
* Active Record 如何融入 MVC 範式。
* 如何使用 Active Record Model 來處理存在關聯式資料庫的資料。
* Active Record 資料庫綱要的命名慣例。
* 資料庫遷移、驗證與回呼的概念。

--------------------------------------------------------------------------------

Active Record 是什麼？
-----------------------

Active Record 是 [MVC](getting_started.html#the-mvc-architecture) 的 M（Model），表現商業邏輯與資料的層級。Active Record 負責新增與操作需要持久存在資料庫裡的資料。Active Record 本身是物件關聯映射（Object Relational Mapping）系統的描述，以 Active Record 模式實作。

### Active Record 模式

Active Record 模式出自 Martin Fowler 在其書：《Patterns of Enterprise Application Architecture》中[所描述的 Active Record](http://www.martinfowler.com/eaaCatalog/activeRecord.html)。在 Active Record 模式裡，物件擁有持久化的資料與行為，Active Record 確保存取資料的邏輯是物件的一部分，進而教導使用者如何將物件寫入於讀出資料庫。

### 物件關聯映射

物件關聯映射，通常縮寫為 ORM。是一種技巧，將應用程式中複雜的物件，對應到關聯式資料庫管理系統中的資料表。使用 ORM，可以輕鬆儲存物件的特性與關係，取出來的時候也不需要撰寫 SQL 語句，總體上減少了與資料庫存取有關的程式碼。

### Active Record 作為 ORM 框架

Active Record 賦予我們許多功能，最重要幾個是：

* 表示 Model 與資料。
* 表示 Model 之間的關係。
* 表示相關 Model 之間的繼承關係。
* 持久化資料存入資料庫的驗證。
* 以物件導向的風格操作資料庫。

Active Record 中的慣例勝於設定
----------------------------------------------

使用其它程式語言撰寫應用程式時，可能會需要寫許多與設定有關的程式碼。大多數的 ORM 框架都是這樣。然而如果依循 Rails 的慣例，新建 Active Record Model 便只需要非常少的設定（某些情況甚至無需設定）。背後的概念是，如果多數時候大家都這麼設定應用程式，那這應該是預設的設定方式。因此，再無法遵循標準慣例的情況下，才需要額外設定。

### 命名慣例

Active Record 預設使用某種命名慣例來找出 Model 與資料表的對應關係。Rails 會將類別名稱轉成複數來找到對應的資料表。所以 `Book` 類對應的資料表便叫做 `books`。Rails 單複數轉換機制非常強大，能從單數轉複數、複數轉單數，單字的單複數形的不規則轉換，都能正確處理。類別名稱由兩個以上的單字組成時，Model 名稱應要遵循 Ruby 的命名慣例，採用駝峰式命名，而資料表名稱必須採用底線分隔。例子：

* 資料表 - 複數形，由底線分隔多個單字。
* Model 類別 - 單數形，第一個字母大寫。

    | Model / Class | Table / Schema |
    | ------------- | -------------- |
    | `Article`     | `articles`     |
    | `LineItem`    | `line_items`   |
    | `Deer`        | `deers`        |
    | `Mouse`       | `mice`         |
    | `Person`      | `people`       |


### 資料庫綱要慣例

Active Record 資料表欄位的命名慣例，取決於欄位的用途

* **外鍵** - 應用資料表的單數形加上 `_id` 來命名，比如 `item_id`, `order_id`。Active Record 會在你建立 Model 之間的關聯時，尋找這種形式的欄位 `singularized_table_name_id`。

* **主鍵** -  Active Record 預設會使用一個叫做 `id` 的整數欄位，作為資料表的主鍵。採用 [Active Record
  遷移](migrations.html) 來建立資料表時，這個欄位會自動產生。

以下是某些選擇性的欄位名稱，會加入更多功能到 Active Record 實體：

* `created_at` - 記錄首次建立時自動設定此欄位為當下的日期與時間。
* `updated_at` - 無論何時更新記錄時，會自動設定此欄位為當下的日期與時間。
* `lock_version` - 加入 [optimistic
  locking](http://api.rubyonrails.org/classes/ActiveRecord/Locking.html) 功能至 Model。
* `type` - 表示 Model 開啟了[單表繼承](http://api.rubyonrails.org/classes/ActiveRecord/Base.html#class-ActiveRecord::Base-label-Single+table+inheritance)功能。
* `(association_name)_type` - 儲存
  [多態關聯](association_basics.html#polymorphic-associations) 所需的類型資料。
* `(table_name)_count` - 用來快取關聯物件的數量。舉例來說，`Article` Model 的 `comments_count` 便會為每篇文章快取評論的數量。

NOTE: 雖然這些欄位名稱是選擇性的，但實際上是 Active Record 的保留字。如果要使用這些額外的功能，不要將這些保留字作為他用。比如，`type` 是用來設計單表繼承的資料表。如果沒有使用 STI 功能，試試用個類似的名稱如，“context” 來描述您在建模的資料。

新增 Active Record Models
-----------------------------

新增 Active Record Model 非常簡單。只需要建立一個 `ActiveRecord::Base` 的子類別即可：

```ruby
class Product < ActiveRecord::Base
end
```

便會新增一個 `Product` Model，對應到資料庫的 `products` 表。資料表當中的每一列，皆會對應到 Model 實體的屬性。假設 `products` 以下面的 SQL 語句新建而成：

```sql
CREATE TABLE products (
   id int(11) NOT NULL auto_increment,
   name varchar(255),
   PRIMARY KEY  (id)
);
```

按照上述的資料表綱要，可以寫出如下程式碼：

```ruby
p = Product.new
p.name = "Some Book"
puts p.name # "Some Book"
```

覆寫命名慣例
---------------------------------

那要是需要不同於 Active Record 所提供的命名慣例怎麼辦？或者是 Rails 應用程式使用的資料來自老舊的資料庫？沒問題，覆寫預設的慣例非常簡單。

可以使用 `ActiveRecord::Base.table_name=` 方法來指定對應的資料表名稱：

```ruby
class Product < ActiveRecord::Base
  self.table_name = "PRODUCT"
end
```

如果修改了資料表的名稱，在測試裡會需要使用 `set_fixture_class` 來手動定義 fixture 的類別名稱。

```ruby
class FunnyJoke < ActiveSupport::TestCase
  set_fixture_class funny_jokes: Joke
  fixtures :funny_jokes
  ...
end
```

覆寫資料表中的欄位也是有可能的，比如使用 `ActiveRecord::Base.primary_key=` 方法將修改主鍵的名稱

```ruby
class Product < ActiveRecord::Base
  self.primary_key = "product_id"
end
```

CRUD：讀寫資料
------------------------------

CRUD 是四種資料操作的簡稱：**C**reate,
**R**ead, **U**pdate and **D**elete，分別是新增、讀取、更新與刪除。Active Record 自動為應用程式新增處理資料表所需要的方法。

### 新增 Create

Active Record 物件可以從 Hash、區塊（blcok）中建立出來，或者是建立後再設定也可以。`new` 方法回傳一個新的物件，而 `create` 會會傳新物件並存入資料庫。

舉個例子，`User` Model 有 `name` 與 `occupation` 屬性，以下是用 `create` 方法在資料庫新增一筆記錄的例子：

```ruby
user = User.create(name: "David", occupation: "Code Artist")
```

使用 `new` 方法，物件會實體化出來，但不會儲存：

```ruby
user = User.new
user.name = "David"
user.occupation = "Code Artist"
```

呼叫 `user.save` 會將該筆記錄存入資料庫。

最後，使用區塊的例子，會將 User.new 實體化出來的物件放入區塊裡，對個別屬性作設定：

```ruby
user = User.new do |u|
  u.name = "David"
  u.occupation = "Code Artist"
end
```

### 讀取 Read

Active Record 提供了豐富的 API 來存取資料庫裡的資料。下面是 Active Record 所提供的幾個資料存取方法用例：

```ruby
# return a collection with all users
users = User.all
```

```ruby
# return the first user
user = User.first
```

```ruby
# return the first user named David
david = User.find_by(name: 'David')
```

```ruby
# find all users named David who are Code Artists and sort by created_at in reverse chronological order
users = User.where(name: 'David', occupation: 'Code Artist').order('created_at DESC')
```

關於對 Active Record Model 做查詢的內容，請參考 [Active Record
Query Interface](active_record_querying.html)。

### 更新 Update

一旦 Active Record 物件被取出來了，就可以對屬性修改，再存回資料庫。

```ruby
user = User.find_by(name: 'David')
user.name = 'Dave'
user.save
```

修改屬性再儲存有簡寫方式，使用 Hash 來對應要修改的屬性，如下所示：

```ruby
user = User.find_by(name: 'David')
user.update(name: 'Dave')
```

一次更新多個屬性時用這招最有效。若是要批量更新多筆記錄，可以使用類別方法：`update_all`：

```ruby
User.update_all "max_login_attempts = 3, must_change_password = 'true'"
```

### 刪除 Delete

既然可以取出 Active Record 物件做更新，同樣也可以將其從資料庫移除。

```ruby
user = User.find_by(name: 'David')
user.destroy
```

驗證
-----------

Active Record 允許您在資料被存入資料庫之前，驗證資料的狀態。驗證有許多方法，比如可以檢查屬性的值是不是空的、是不是唯一的、資料庫裡是不是已經有一份？每種檢查方法有特定的書寫格式。

驗證是在把持久化資料存入資料庫前，需要審慎思量的問題。跟資料存入資料庫有關的二種方法 `save` 以及 `update`，在呼叫時會進行驗證。當這三個方法回傳值為 `false` 時，驗證失敗，將不會對資料庫進行任何操作。上述三個方法皆有對應的 BANG 方法：`save!` 以及 `update!`，這比原本的方法更嚴格些，一旦失敗會直接拋出 `ActiveRecord::RecordInvalid` 的異常。用個簡單例子來說明：

```ruby
class User < ActiveRecord::Base
  validates :name, presence: true
end

user = User.new
user.save  # => false
user.save! # => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

了解更多關於驗證的內容，請參考：[Active Record Validations
guide](active_record_validations.html)。

回呼（Callbacks）
-------------------

Active Record 回呼允許您在 Model 生命週期裡對特定事件附加程式碼。這使您可以在特定事件發生時，執行特定的程式碼。比如向資料庫新增、更新、刪除某筆記錄等。了解更多關於回呼的內容，請參考：[Active Record Callbacks](active_record_callbacks.html)

遷移
----------

Rails 提供了用來處理資料庫綱要的 DSL，稱為“遷移”。遷移存在檔案裡，可以對 Active Record 支持的任何資料庫，透過 `rake` 執行。以下是如何新建一張資料表：

```ruby
class CreatePublications < ActiveRecord::Migration
  def change
    create_table :publications do |t|
      t.string :title
      t.text :description
      t.references :publication_type
      t.integer :publisher_id
      t.string :publisher_type
      t.boolean :single_issue

      t.timestamps null: false
    end
    add_index :publications, :publication_type_id
  end
end
```

Rails 持續追蹤提交到資料庫的檔案，並提供回滾功能。要真正的建立一張資料表，需要執行：`rake db:migrate`；要回滾則是執行：`rake db:rollback`。

注意以上的程式碼適用於任何資料庫，不管是 Oracle、PostgreSQL、MySQL 都可以。了解更多關於遷移的內容，請參考 [Active Record Migrations](migrations.html)。
