**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://rails.ruby.tw.**

Active Record 回呼
=============================

本篇講解如何掛載事件到 Active Record 物件的生命週期。

讀完本篇，您將了解：

* Active Record 物件的生命週期。
* 如何建立回呼方法回應生命週期裡的事件。
* 如何封裝回呼常見的行為到特殊的類別裡。

--------------------------------------------------------------------------------

物件的生命週期
---------------------

Rails 應用程式常見的操作裡，物件可以被新建、更新與刪除。Active Record 提供了掛載機制，可以掛載事件到物件的生命週期裡，用來控制應用程式與資料。

回呼允許你在物件狀態前後，觸發特定的邏輯。

回呼綜覽
---------------------

回呼是在物件生命週期特定時間點所呼叫的方法。有了回呼便可以在 Active Record 物件，__新建、儲存、更新、刪除、驗證、或從資料庫讀出__前後，執行想要的邏輯。

### 註冊回呼

需要先註冊方可使用回呼。註冊回呼可以使用一般的方法或是宏風格的方法：

```ruby
class User < ActiveRecord::Base
  validates :login, :email, presence: true

  before_validation :ensure_login_has_a_value

  protected
    def ensure_login_has_a_value
      if login.nil?
        self.login = email unless email.blank?
      end
    end
end
```

宏風格的類別方法也接受區塊。如果回呼邏輯很短只有一行，可以考慮使用區塊形式：

```ruby
class User < ActiveRecord::Base
  validates :login, :email, presence: true

  before_create do
    self.name = login.capitalize if name.blank?
  end
end
```

回呼也可只針對 Active Record 物件生命週期裡特定的事件觸發：

```ruby
class User < ActiveRecord::Base
  before_validation :normalize_name, on: :create

  # :on takes an array as well
  after_validation :set_location, on: [ :create, :update ]

  protected
    def normalize_name
      self.name = self.name.downcase.titleize
    end

    def set_location
      self.location = LocationService.query(self)
    end
end
```

通常會把回呼方法宣告為 `protected` 或 `private` 方法。若是 `public` 方法，有可能會在 Model 外被呼叫，則違反了物件封裝的精神。

可用的回呼
-------------------

以下是 Active Record 可用的回呼，__依照執行順序排序__：

### 新建物件

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_create`
* `around_create`
* `after_create`
* `after_save`
* `after_commit/after_rollback`

### 更新物件

* `before_validation`
* `after_validation`
* `before_save`
* `around_save`
* `before_update`
* `around_update`
* `after_update`
* `after_save`
* `after_commit/after_rollback`

### 刪除物件

* `before_destroy`
* `around_destroy`
* `after_destroy`
* `after_commit/after_rollback`

WARNING: `after_save` 在 `create` 與 `update` 都會執行。但不論回呼註冊的順序為何，`after_save` 總是在更為具體的 `after_create` 與 `after_update` 之後執行。

### `after_initialize` 與 `after_find`

不管是實體化 Active Record 物件，還是從資料庫裡讀出記錄時，都會呼叫 `after_initialize`。使用 `after_initialize` 比覆蓋 Active Record 的 `initialize` 方法好多了。

無論何時從資料庫取出 Active Record 物件時，如果同時使用了 `after_find` 與 `after_initialize`，會先呼叫 `after_find`。

`after_initialize` 與 `after_find` 沒有對應的 `before_*`。`after_initialize` 與 `after_find` 註冊的方法與一般回呼相同。

```ruby
class User < ActiveRecord::Base
  after_initialize do |user|
    puts "You have initialized an object!"
  end

  after_find do |user|
    puts "You have found an object!"
  end
end

>> User.new
You have initialized an object!
=> #<User id: nil>

>> User.first
You have found an object!
You have initialized an object!
=> #<User id: 1>
```

### `after_touch`

`after_touch` 回呼會在 Active Record 執行完 `touch` 之後呼叫。

```ruby
class User < ActiveRecord::Base
  after_touch do |user|
    puts "You have touched an object"
  end
end

>> u = User.create(name: 'Kuldeep')
=> #<User id: 1, name: "Kuldeep", created_at: "2013-11-25 12:17:49", updated_at: "2013-11-25 12:17:49">

>> u.touch
You have touched an object
=> true
```

可與 `belongs_to` 搭配使用:

```ruby
class Employee < ActiveRecord::Base
  belongs_to :company, touch: true
  after_touch do
    puts 'An Employee was touched'
  end
end

class Company < ActiveRecord::Base
  has_many :employees
  after_touch :log_when_employees_or_company_touched

  private
  def log_when_employees_or_company_touched
    puts 'Employee/Company was touched'
  end
end

>> @employee = Employee.last
=> #<Employee id: 1, company_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

# triggers @employee.company.touch
>> @employee.touch
Employee/Company was touched
An Employee was touched
=> true
```

執行回呼
----------------

以下方法會觸發回呼：

* `create`
* `create!`
* `decrement!`
* `destroy`
* `destroy!`
* `destroy_all`
* `increment!`
* `save`
* `save!`
* `save(validate: false)`
* `toggle!`
* `touch`
* `update_attribute`
* `update`
* `update!`
* `valid?`

另外 `after_find` 由下列查詢方法觸發：

* `all`
* `first`
* `find`
* `find_by`
* `find_by_*`
* `find_by_*!`
* `find_by_sql`
* `last`

`after_initialize` 在每次 Active Record 物件實體化時觸發。

NOTE: 這些查詢方法是 Active Record 給每個屬性動態產生的，參見[動態查詢方法](/active_record_querying.html#動態查詢方法) 一節。

## 略過回呼

驗證可以略過，回呼同樣也可以。使用下列方法來略過回呼：

* `decrement`
* `decrement_counter`
* `delete`
* `delete_all`
* `increment`
* `increment_counter`
* `toggle`
* `update_column`
* `update_columns`
* `update_all`
* `update_counters`

小心使用這些方法，因為回呼裡可能有重要的業務邏輯。沒弄懂回呼的用途，便直接跳過可能會導致存入不合法的資料。

終止執行
--------------

為 Model 註冊新的回呼時，回呼便會加入佇列裡等待執行。這個佇列包含了所有需要執行的驗證、回呼以及資料庫操作。

整條回呼鏈（Callback Chain）被包在一筆交易（Transaction）裡。如果有任何的 `before_*` 回呼方法回傳 `false` 或拋出異常，則執行鏈會被終止，並回滾取消此次交易。而 `after_*` 回呼則需要拋出異常才可取消交易。

WARNING: 即便回呼鏈已終止，任何非 `ActiveRecord::Rollback` 的異常會在回呼鏈終止時被 Rails 重複拋出。拋出非 `ActiveRecord::Rollback` 可能會導致不期望收到異常的方法像是 `save` 與 `update` 執行異常（通常會回傳 `true` 或 `false`）。

關聯回呼
--------------------------

回呼也可穿透 Model 之間的關係，甚至可以透過關聯來定義。舉個例子，假設使用者有許多文章，使用者的文章應在刪除使用者時一併刪除。可以在與 `User` Model 相關聯的 `Article` Model 裡加入 `after_destroy` 回呼：

```ruby
class User < ActiveRecord::Base
  has_many :articles, dependent: :destroy
end

class Article < ActiveRecord::Base
  after_destroy :log_destroy_action

  def log_destroy_action
    puts 'Article also destroyed'
  end
end

>> user = User.first
=> #<User id: 1>
>> user.posts.create!
=> #<Article id: 1, user_id: 1>
>> user.destroy
Article destroyed
=> #<User id: 1>
```

條件式回呼
----------------------

回呼和驗證一樣，也可以在滿足給定條件時才執行。條件透過 `:if`、`:unless` 選項指定，接受 `Symbol`、`String`、`Proc` 或 `Array`。當回呼滿足某條件則執行時，請用 `:if`；回呼不滿足某條件則執行時，請用 `:unless`。

###  使用符號指定 `:if` 與 `:unless`

`:if` 與 `:unless` 選項傳入符號（Symbol）時，符號代表執行回呼前，所要呼叫的謂詞方法名稱。當使用 `:if` 選項時，若謂詞方法回傳 `false`，則不會執行回呼；當使用 `:unless` 選項時，則是 `true` 不會執行回呼。使用符號是最常見。這種註冊回呼的方式，還可以使用多個謂詞方法來決定是否要執行回呼。

```ruby
class Order < ActiveRecord::Base
  before_save :normalize_card_number, if: :paid_with_card?
end
```

### 使用字串指定 `:if` 與 `:unless`

傳入的字串將會使用 `eval` 求值，所以字串必須是合法的 Ruby 程式碼。應該只在條件夠簡短的情況下再使用字串：

```ruby
class Order < ActiveRecord::Base
  before_save :normalize_card_number, if: "paid_with_card?"
end
```

### 使用 `Proc` 指定 `:if` 與 `:unless`

最後，也可以使用 `Proc` 物件來指定 `:if` 與 `:unless`，適合撰寫簡短驗證方法的場景下使用，通常是單行：

```ruby
class Order < ActiveRecord::Base
  before_save :normalize_card_number,
    if: Proc.new { |order| order.paid_with_card? }
end
```

### 多重條件回呼

撰寫條件式回呼時，`:if` 與 `:unless` 也可混用在同個回呼裡：

```ruby
class Comment < ActiveRecord::Base
  after_create :send_email_to_author, if: :author_wants_emails?,
    unless: Proc.new { |comment| comment.article.ignore_comments? }
end
```

回呼類別
------------------

若某個回呼別的 Model 也可重複使用，此時便可把回呼封裝成類別。Active Record 使封裝回呼方法到類別裡格外簡單，重用便更容易了。

以下是個範例。我們建立一個 `PictureFile` Model，並註冊一個 `after_destroy` 回呼：

```ruby
class PictureFileCallbacks
  def after_destroy(picture_file)
    if File.exists?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
```

回呼在類別裡宣告時（如上），回呼方法會收到 Model 實體（`picture_file`）作為參數。回呼類別在 Model 裡的使用方式如下：

```ruby
class PictureFile < ActiveRecord::Base
  after_destroy PictureFileCallbacks.new
end
```

注意我們需要建立一個新的 `PictureFileCallbacks` 實體，因為回呼寫在 `PictureFileCallbacks` 類裡是實體方法。這在回呼使用到了實體變數的場景下特別有用。但通常回呼宣告成類別方法更合理：

```ruby
class PictureFileCallbacks
  def self.after_destroy(picture_file)
    if File.exists?(picture_file.filepath)
      File.delete(picture_file.filepath)
    end
  end
end
```

若回呼方法如此定義，則使用時便不用實體化 `PictureFileCallbacks` 了：

```ruby
class PictureFile < ActiveRecord::Base
  after_destroy PictureFileCallbacks
end
```

回呼類別裡可宣告任意數量個回呼方法。

交易回呼
--------------------

完成資料庫交易操作時會觸發兩個條件式回呼：`after_commit` 與 `after_rollback`。它們與 `after_save` 回呼非常類似，不同點在於 `after_commit` 是提交到資料庫後才執行，而 `after_rollback` 則是在資料庫回滾後執行。當 Active Record Model 需要與資料庫交易之外的外部系統互動時，這兩個回呼非常有用。

舉個例子，上例 `PictureFile` Model 需要在某個特定記錄刪除後，刪除一個檔案。若 `after_destroy` 拋出任何異常，則交易取消。但檔案卻被刪除了，Model 會處於一種不一致的狀態。舉例來說，假設下例的 `picture_file_2` 不是合法的檔案，`save!` 會拋出一個錯誤。

```ruby
PictureFile.transaction do
  picture_file_1.destroy
  picture_file_2.save!
end
```

使用 `after_commit` 回呼便可以解決這個問題。

```ruby
class PictureFile < ActiveRecord::Base
  after_commit :delete_picture_file_from_disk, on: [:destroy]

  def delete_picture_file_from_disk
    if File.exist?(filepath)
      File.delete(filepath)
    end
  end
end
```

NOTE: `:on` 選項指定何時觸發這個回呼。沒指定時對所有方法都會觸發。

WARNING: `after_commit` 與 `after_rollback` 在新建、更新、刪除 Model 時一定會執行。如果 `after_commit` 或 `after_rollback` 回呼其中一個拋出異常時，異常會被忽略，來確保彼此不會互相干擾。也是因為如此，如果回呼會拋出異常，記得自己 `rescue` 回來，並在回呼做適當的處理。
