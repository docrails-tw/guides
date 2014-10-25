Active Record 驗證
=========================

本篇教您如何使用 Active Record 的驗證功能，在資料存入資料庫前，驗證物件的狀態。

讀完本篇，您將了解：

* 如何使用 Active Record 內建的驗證輔助方法。
* 如何新建自己的驗證方法。
* 如何處理驗證時所產生的錯誤訊息。

--------------------------------------------------------------------------------

驗證綜覽
--------------------

以下是一個簡單的例子：

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

如您所見，透過驗證，我們知道 `Person` 必須要有 `name` 屬性才算有效。上例第二個建立的 `Person`，因為缺少了 `name`，則不會存至資料庫。

在深入了解之前，先談談驗證在應用程式裡所扮演的角色。

### 為什麼要驗證？

驗證用來確保只有有效的資料才能存入資料庫。譬如每個使用者需要填寫有效的 E-mail 與郵寄地址。在 Model 層級驗證資料是最好的，只有通過驗證的資料方可存入資料庫。因為在 Model 層面驗證，不需要考慮資料庫的種類、無法在用戶端（瀏覽器）跳過驗證、且更容易測試與維護。Rails 使得資料驗證用起來非常簡單，提供了各種內建輔助方法，來滿足常見的需求，也可以新建自定的驗證方法。

在存入資料庫前有好幾種驗證方法，包含了原生的資料庫約束（constraint）、用戶端驗證、Controller 層級驗證。以下是各種方法的優缺點：

* 資料庫約束和 stored procedure 驗證機制只適用單一資料庫，不好測試，也更難維護。但若是其它應用程式也使用您的資料庫，加上資料庫層級的約束可能比較好。除此之外，資料庫層級的驗證可以安全地處理某些問題（像是在使用頻繁的資料表裡檢查唯一性），這倘若不在資料庫層級做，其它層級做起來可能很困難。
* 用戶端驗證很有用，但單獨使用時可靠性不高。若是用 JavaScript 實作，關掉 JavaScript 便可跳過驗證。但結合其它種驗證方式，用戶端驗證可提供使用者即時的反饋。
* Controller 層級驗證聽起來很誘人，但用起來很笨重，也很難測試與維護。不管怎麼說，盡量保持 Controller 輕巧短小，長遠下來看，應用程式會更好維護。

根據不同場合選擇不同驗證方式。Rails 團隊的觀點是 Model 層級的驗證，最符合多數應用場景。

### 驗證何時發生？

Active Record 物件有兩種：一種對應到資料庫的列、另一種沒有。當新建一個新的物件時，比如使用 `new` 方法，物件此時並不屬於資料庫。一旦對物件呼叫 `save`，則物件會存入對應的資料表裡。Active Record 使用 `new_record?` 這個實體方法來決定物件是否已存在資料庫。看看下面這個簡單的 Active Record 類別：

```ruby
class Person < ActiveRecord::Base
end
```

可以在 `rails console` 下試試這是怎麼工作的：

```ruby
$ bin/rails console
>> p = Person.new(name: "John Doe")
=> #<Person id: nil, name: "John Doe", created_at: nil, updated_at: nil>
>> p.new_record?
=> true
>> p.save
=> true
>> p.new_record?
=> false
```

新建與儲存新紀錄（record），會對資料庫做 SQL 的 `INSERT` 操作。更新已存在的記錄則會做 `UPDATE`。驗證通常在這些 SQL 執行之前就發生了。如果驗證失敗，則物件會被標示為無效的，Active Record 便不會執行 `INSERT` 或是 `UPDATE`。這避免了存入無效的物件到資料庫。您可以指定在物件建立時、儲存時、更新時，各個階段要做何種資料驗證。

CAUTION: 有許多種方法可以改變資料庫裡物件的狀態。某些方法會觸發驗證、某些不會。這表示有可能會不小心將無效的物件存入資料庫。

以下方法會觸發驗證，只會在物件有效時，把物件存入資料庫：

* `create`
* `create!`
* `save`
* `save!`
* `update`
* `update!`

這些方法對應的 BANG 版本（比如 `save!`），會對無效的記錄拋出異常。非 BANG 方法則不會，`save` 與 `update` 僅回傳 `false`，`create` 僅回傳物件本身。

### 略過驗證

以下這些方法會略過驗證，將物件存入資料庫時不會考慮資料的有效性。應謹慎使用。

* `decrement!`
* `decrement_counter`
* `increment!`
* `increment_counter`
* `toggle!`
* `touch`
* `update_all`
* `update_attribute`
* `update_column`
* `update_columns`
* `update_counters`

注意 `save` 也能夠略過驗證，傳入 `validate: false` 作為參數即可。這個技巧要小心使用。

* `save(validate: false)`

### `valid?` 與 `invalid?`

檢查物件是否有效，Rails 使用的是 `valid?` 方法。可以直接呼叫此方法來觸發驗證。物件若沒有錯誤會回傳 `true`，反之回傳 `false`。前面已經見過了：

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

Person.create(name: "John Doe").valid? # => true
Person.create(name: nil).valid? # => false
```

Active Record 做完驗證後，所有找到的錯誤都可透過 `errors.messages` 這個實體方法來存取，會回傳錯誤集合。就定義來說，物件做完驗證後，錯誤集合為空才是有效的。

注意到用 `new` 實體化出來的物件，即便有錯誤也不會說，因為 `new` 不會觸發任何驗證。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

>> p = Person.new
# => #<Person id: nil, name: nil>
>> p.errors.messages
# => {}

>> p.valid?
# => false
>> p.errors.messages
# => {name:["can't be blank"]}

>> p = Person.create
# => #<Person id: nil, name: nil>
>> p.errors.messages
# => {name:["can't be blank"]}

>> p.save
# => false

>> p.save!
# => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank

>> Person.create!
# => ActiveRecord::RecordInvalid: Validation failed: Name can't be blank
```

`invalid?` 是 `valid?` 的反相。物件找到任何錯誤回傳 `true`，反之回傳 `false`。

### `errors[]`

要檢查物件的特定屬性是否有效，可以使用 `errors[:attribute]`，會以陣列形式返回該屬性的所有錯誤，沒有錯誤則返回空陣列。

這個方法只有在驗證後呼叫才有用，因為它只是檢查 `errors` 集合，而不會觸發驗證。`errors[:attribute]` 與 `ActiveRecord::Base#invalid?` 方法不同，因為它不是檢查整個物件的有效性，只是檢查物件單一屬性是否有錯誤。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true
end

>> Person.new.errors[:name].any? # => false
>> Person.create.errors[:name].any? # => true
```

在 [7 處理驗證錯誤](#)一節會更深入講解驗證錯誤。現在讓我們看看 Rails 內建的驗證輔助方法有那些。

驗證輔助方法
-----------

Active Record 預先定義了許多驗證用的輔助方法，供您直接在類別定義中使用。這些輔助方法提供了常見的驗證規則。每當驗證失敗時，驗證訊息會新增到物件的 `errors` 集合，這個訊息與出錯的屬性是相關聯的。


每個輔助方法皆接受任意數量的屬性名稱，所以一行程式碼，便可給多個屬性加入同樣的驗證。

所有的輔助方法皆接受 `:on` 與 `:message` 選項，分別用來指定何時做驗證、出錯時的錯誤訊息。每個驗證輔助方法都有預設的錯誤訊息。這些訊息在沒有指定 `:message` 選項時很有用。讓我們看看每一個可用的輔助方法。

### `acceptance`

這個方法在表單送出時，檢查 UI 的 checkbox 是否有打勾。這對於使用者需要接受服務條款、隱私權政策等相關的場景下很有用。這個驗證僅針對網頁應用程式，且不需要存入資料庫（如果沒有為 `acceptance` 開一個欄位，輔助方法自己會使用一個虛擬屬性）。

```ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: true
end
```

這個輔助方法預設的錯誤訊息是 _"must be accepted"_。

這個方法接受一個 `:accept` 選項，用來決定什麼值代表“接受”。預設是 “1”，改成別的也很簡單。

```ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: { accept: 'yes' }
end
```

### `validates_associated`

當 Model 與其它 Model 有關聯，且與之關聯的 Model 也需要驗證時，用這個方法來處理。在儲存物件時，會對相關聯的物件呼叫 `valid?`。

```ruby
class Library < ActiveRecord::Base
  has_many :books
  validates_associated :books
end
```

所有的關聯類型皆適用此方法。

CAUTION: 不要在關聯的兩邊都使用 `validates_associated`。它們會互相呼叫陷入無窮迴圈。

`validates_associated` 預設錯誤訊息是 _"is invalid"_。注意到每個關聯的物件會有自己的 `errors` 集合。錯誤不會集中到呼叫該方法的 Model。

### `confirmation`

當有兩個 text field 內容需要完全相同時，使用這個方法。比如可能想要確認 E-mail 或密碼兩次輸入是否相同。這個驗證會新建一個虛擬屬性，名字是該欄位（field）的名稱，後面加上 `_confirmation`。

```ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
end
```

在 View 模版（template）裡，可以這麼用：

```erb
<%= text_field :person, :email %>
<%= text_field :person, :email_confirmation %>
```

只有 `email_confirmation` 不為 `nil` 時，才會做驗證。需要確認的話，記得要給 `email_confirmation` 屬性加上存在性（presence）驗證（稍後介紹 `presence`）：

```ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
end
```

`confirmation` 預設錯誤訊息是  _"doesn't match confirmation"_。

### `exclusion`

這個方法驗證屬性是否“不屬於”某個給定的集合。集合可以是任何 `Enumerable` 的物件。

```ruby
class Account < ActiveRecord::Base
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value} is reserved." }
end
```

`exclusion` 有 `:in` 選項，接受一組數值，決定屬性“不可接受”的值。`:in` 別名為 `:within`。上例使用了 `:message` 選項來示範如何在錯誤訊息裡印出屬性的值。

`exclusion` 預設錯誤訊息是  _"is reserved"_。

### `format`

這個方法驗證屬性的值是否匹配一個透過 `:with` 給定的正規表達式。

```ruby
class Product < ActiveRecord::Base
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "only allows letters" }
end
```

也可以使用 `:without` 來指定沒有匹配的屬性。

`format` 預設錯誤訊息是  _"is invalid"_。

### `inclusion`

這個方法驗證屬性是否“屬於”某個給定的集合。集合可以是任何 `Enumerable` 的物件。

```ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }
end
```

`inclusion` 有 `:in` 選項，接受一組數值，決定屬性“可接受”的值。`:in` 的別名為 `:within`。上例使用了 `:message` 選項來示範如何在錯誤訊息裡印出屬性的值。

`inclusion` 預設錯誤訊息是 _"is not included in the list"_。

### `length`

這個方法驗證屬性值的長度。有多種選項來限制長度（如下所示）：

```ruby
class Person < ActiveRecord::Base
  validates :name, length: { minimum: 2 }
  validates :bio, length: { maximum: 500 }
  validates :password, length: { in: 6..20 }
  validates :registration_number, length: { is: 6 }
end
```

長度限制選項有：

* `:minimum` - 屬性值的長度的最小值。
* `:maximum` - 屬性值的長度的最大值。
* `:in` (or `:within`) - 屬性值的長度所屬的區間。這個選項的值必須是一個範圍。
* `:is` - T屬性值的長度必須等於。

預設錯誤訊息取決於用的是那種長度驗證方法。可以使用 `:wrong_length`、`too_long`、`too_short` 選項，以及 `%{count}` 來客製化訊息。使用 `:message` 也是可以的。

```ruby
class Person < ActiveRecord::Base
  validates :bio, length: { maximum: 1000,
    too_long: "%{count} characters is the maximum allowed" }
end
```

這個方法計算長度的預設單位是字元。但可以用 `:tokenizer` 選項來修改，比如取一個字為最小單位：

```ruby
class Essay < ActiveRecord::Base
  validates :content, length: {
    minimum: 300,
    maximum: 400,
    tokenizer: lambda { |str| str.scan(/\w+/) },
    too_short: "must have at least %{count} words",
    too_long: "must have at most %{count} words"
  }
end
```

注意到預設的錯誤訊息是複數。（例如，"is too short (minimum
is %{count} characters)"）。故當 `:minimum` 為 1 時，要提供一個自訂的訊息，或者是使用 `presence: true` 取代。當 `:in` 或 `:within` 下限小於 1 時，應該要提供一個自訂的訊息，或者是在驗證 `length` 之前，先驗證 `presence`。

### `numericality`

這個方法驗證屬性是不是純數字。預設會匹配帶有正負號（可選）的整數或浮點數。只允許整數可以透過將 `:only_integer` 為 `true`。

`:only_integer` 為 `true`，會使用下面的正規表達式來檢查屬性的值：

```ruby
/\A[+-]?\d+\Z/
```

否則會嘗試使用 `Float` 將值轉為數字。

WARNING. 注意上面的正規表達式允許最後有新行字元。

```ruby
class Player < ActiveRecord::Base
  validates :points, numericality: true
  validates :games_played, numericality: { only_integer: true }
end
```

除了 `only_integer` 之外，這個方法也接受下列選項，用來限制允許的數值：

* `:greater_than` - 屬性的值必須大於指定的值。預設錯誤訊息是 _"must be greater than %{count}"_。
* `:greater_than_or_equal_to` - 屬性的值必須大於等於指定的值。預設錯誤訊息是 _"must be greater than or equal to %{count}"_。
* `:equal_to` - 屬性的值必須等於指定的值。預設錯誤訊息是 _"must be equal to %{count}"_。
* `:less_than` - 屬性的值必須小於指定的值。預設錯誤訊息是 _"must be less than %{count}"_。
* `:less_than_or_equal_to` - 屬性的值必須小於等於指定的值。預設錯誤訊息是 _"must be less than or equal to %{count}"_。
* `:odd` - 若 `:odd` 設為 `true`，則屬性的值必須是奇數。預設錯誤訊息是 _"must be odd"_。
* `:even` - 若 `:even` 設為 `true`，則屬性的值必須是偶數。預設錯誤訊息是 _"must be even"_。

`numericality` 預設錯誤訊息是 _"is not a number"_。

### `presence`

這個方法驗證指定的屬性是否“存在”。使用 `blank?` 來檢查數值是否為 `nil` 或空字串（僅有空白的字串也是空字串）。

```ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, presence: true
end
```

想確保關聯物件是否存在，需要檢查關聯物件本身，而不是檢查對應的外鍵。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
  validates :order, presence: true
end
```

而在 `Order` 這一邊，要用 `inverse_of` 來檢查關聯的物件是否存在。

```ruby
class Order < ActiveRecord::Base
  has_many :line_items, inverse_of: :order
end
```

如透過 `has_one` 或 `has_many` 關係來驗證關聯的物件是否存在，則會對該物件呼叫 `blank?` 與 `marked_for_destruction?`，來確定存在性。

由於 `false.blank?` 為 `true`，如果想驗證布林欄位的存在性，應該要使用下列的驗證方法：

```ruby
validates :boolean_field_name, presence: true
validates :boolean_field_name, inclusion: { in: [true, false] }
validates :boolean_field_name, exclusion: { in: [nil] }
```

預設錯誤訊息是 _"can't be blank"_。

### `absence`

這個方法驗證是否“不存在”。使用 `present?` 來檢查數值是否為非 `nil` 或非空字串（僅有空白的字串也是空字串）。


```ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, absence: true
end
```

想確保關聯物件是否“不存在”，需要檢查關聯物件本身，而不是檢查對應的外鍵。

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
  validates :order, absence: true
end
```

而在 `Order` 這一邊，要用 `inverse_of` 來檢查關聯的物件是否不存在。

```ruby
class Order < ActiveRecord::Base
  has_many :line_items, inverse_of: :order
end
```

如透過 `has_one` 或 `has_many` 關係來驗證關聯的物件是否存在，則會對該物件呼叫 `present?` 與 `marked_for_destruction?`，來確定不存在性。

由於 `false.present?` 為 `false`，如果想驗證布林欄位的存在性，應該要使用 `validates :field_name, exclusion: { in: [true, false] }`。

預設錯誤訊息是 _"must be blank"_。

### `uniqueness`

這個方法在物件儲存前，驗證屬性值是否是唯一的。此方法只是在應用層面檢查，不對資料庫做約束。同時有兩個資料庫連接，便有可能建立出兩個相同的紀錄。要避免則是需要在資料庫加上 unique 索引，請參考 [MySQL 手冊](http://dev.mysql.com/doc/refman/5.6/en/multiple-column-indexes.html)來了解多欄索引該怎麼做。

```ruby
class Account < ActiveRecord::Base
  validates :email, uniqueness: true
end
```

這個驗證透過對 Model 的資料表執行一條 SQL 查詢語句，搜尋是否已經有同樣數值的紀錄存在。

`:scope` 選項可以用另一個屬性來限制唯一性：

```ruby
class Holiday < ActiveRecord::Base
  validates :name, uniqueness: { scope: :year,
    message: "should happen once per year" }
end
```

另有 `:case_sensitive` 選項可以用來定義是否要分大小寫。此選項預設開啟。

```ruby
class Person < ActiveRecord::Base
  validates :name, uniqueness: { case_sensitive: false }
end
```

WARNING: 注意某些資料庫預設搜尋是不分大小寫的。

預設錯誤訊息是 _"has already been taken"_。

### `validates_with`

這個方法將記錄傳入，另開一類別來驗證。

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if record.first_name == "Evil"
      record.errors[:base] << "This person is evil"
    end
  end
end

class Person < ActiveRecord::Base
  validates_with GoodnessValidator
end
```

NOTE: 注意錯誤會加到 `record.errors[:base]`。這個錯誤與整個物件有關，不單屬於某個屬性。

`validates_with` 方法接受一個類別，或一組類別。`validates_with` 沒有預設錯誤訊息。你必須要手動新增錯誤到記錄的 `errors` 集合。

實作 `validate` 方法時，參數必須要有 `record`，來表示要被驗證的那條記錄。

與所有的驗證類似，`validates_with` 接受 `:if`、`:unless`，以及 `:on` 選項。如果傳入其它的選項，預設會被放入 `options` Hash（參考下例）：

```ruby
class GoodnessValidator < ActiveModel::Validator
  def validate(record)
    if options[:fields].any? { |field| record.send(field) == "Evil" }
      record.errors[:base] << "This person is evil"
    end
  end
end

class Person < ActiveRecord::Base
  validates_with GoodnessValidator, fields: [:first_name, :last_name]
end
```

注意自己寫的這個驗證類別（上例為 `GoodnessValidator`），在應用程式生命週期內**只會實體化一次**，而不是每次驗證時就實體化一次。所以使用實體變數時要很小心。

如果驗證類別足夠複雜的話，需要用到實體變數，可以用純 Ruby 物件（Plain Old Ruby Object, PORO） 來取代：

```ruby
class Person < ActiveRecord::Base
  validate do |person|
    GoodnessValidator.new(person).validate
  end
end

class GoodnessValidator
  def initialize(person)
    @person = person
  end

  def validate
    if some_complex_condition_involving_ivars_and_private_methods?
      @person.errors[:base] << "This person is evil"
    end
  end

  # ...
end
```

`validates_with` 沒有預設錯誤訊息。

### `validates_each`

這個方法採用區塊（block）來驗證屬性。沒有預先定義的驗證功能。可以在程式碼區塊裡寫要驗證的行為，`validates_each` 指定的每個屬性，會傳入區塊做驗證。比如下例檢查名與姓是否以小寫字母開頭：

```ruby
class Person < ActiveRecord::Base
  validates_each :name, :surname do |record, attr, value|
    record.errors.add(attr, 'must start with upper case') if value =~ /\A[[:lower:]]/
  end
end
```

這個區塊接受記錄、屬性名稱、屬性值。在區塊裡可以寫任何驗證行為。驗證失敗時應給 Model 新增錯誤訊息，才能把記錄標記成非法的。

`validates_each` 沒有預設錯誤訊息。

常見驗證選項
-------------------------

以下是常見的驗證選項：

### `:allow_nil`

`:allow_nil` 選項當驗證的值為 `nil` 時略過驗證。

```ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }, allow_nil: true
end
```

### `:allow_blank`

`:allow_nil` 選項當驗證的值為 `blank?` 時，即 `blank?` 回傳 `true` 時，略過驗證。

```ruby
class Topic < ActiveRecord::Base
  validates :title, length: { is: 5 }, allow_blank: true
end

Topic.create(title: "").valid?  # => true
Topic.create(title: nil).valid? # => true
```

### `:message`

如上已經介紹過，`message` 選項可在驗證失敗時，加上錯誤訊息至 `errors` 集合。沒給入此選項時，Active Record 會使用預設的錯誤訊息。

### `:on`

`:on` 選項可指定驗證發生時機。所有驗證方法預設在 `save` 時會觸發驗證（也就是新建與更新時）。也可以指定只在新建時做驗證 `on: :create`，或是只在更新時做驗證  `on: :update`。

```ruby
class Person < ActiveRecord::Base
  # it will be possible to update email with a duplicated value
  validates :email, uniqueness: true, on: :create

  # it will be possible to create the record with a non-numerical age
  validates :age, numericality: true, on: :update

  # the default (validates on both create and update)
  validates :name, presence: true
end
```

嚴格驗證
------------------

如傳入了 `strict: true`，當物件為無效時，會拋出 `ActiveModel::StrictValidationFailed`。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: { strict: true }
end

Person.new.valid?  # => ActiveModel::StrictValidationFailed: Name can't be blank
```

可自定要拋出的異常：

```ruby
class Person < ActiveRecord::Base
  validates :token, presence: true, uniqueness: true, strict: TokenGenerationException
end

Person.new.valid?  # => TokenGenerationException: Token can't be blank
```

條件式驗證
----------------------

某些時候只有在物件滿足了給定條件時，再進行驗證比較合理。可以透過 `:if` 與 `:unless` 選項來辦到此事。它們接受符號、字串、`Proc` 或 `Array`。`:if` 可以指定驗證發生時機，而 `:unless` 則是指定驗證略過時機。

### `:if` 與 `:unless`：使用 Symbol

`:if` 與 `:uinless` 接受符號，這個符號代表了驗證執行之前所需呼叫的方法。這是最常見的用途。

```ruby
class Order < ActiveRecord::Base
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

### `:if` 與 `:unless`：使用 String

`:if` 與 `:unless` 也接受字串，字串需要是有效的 Ruby 程式碼，會使用 `eval` 來對字串求值。極短的條件式可以使用字串：

```ruby
class Person < ActiveRecord::Base
  validates :surname, presence: true, if: "name.nil?"
end
```

### `:if` 與 `:unless`：使用 `Proc`

最後，`:if` 與 `:unless` 也可以接受 `Proc` 物件。使用 `Proc` 可以寫把一行的條件式寫在區塊裡，而不用另外寫在方法裡。一行的條件式最適合用 `Proc`：

```ruby
class Account < ActiveRecord::Base
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

### 組合條件式驗證

有時候多個驗證需要共用一個條件式，可以透過 `with_options` 來實作：

```ruby
class User < ActiveRecord::Base
  with_options if: :is_admin? do |admin|
    admin.validates :password, length: { minimum: 10 }
    admin.validates :email, presence: true
  end
end
```

所有在 `with_options` 區塊內的驗證都會傳入 `if: :is_admin?` 驗證。

### 結合驗證條件

另一方面來看，當驗證發生於否取決於多條條件時，可以使用 `Array`。此外，`:if` 與 `:unless` 也可以混用。以下是一個綜合的例子：

```ruby
class Computer < ActiveRecord::Base
  validates :mouse, presence: true,
                    if: ["market.retail?", :desktop?],
                    unless: Proc.new { |c| c.trackpad.present? }
end
```

這條驗證只在滿足了所有 `:if` 的條件，以及 `:unless` 條件求值結果為 `true` 時才執行。

使用自定驗證
-----------------------------

當內建的驗證不夠用時，可以自己定義 validator 或驗證方法。

### 自定 Validators

自定 Validator 是擴展 `ActiveModel::Validator` 的類別，且必須實作 `validate` 方法，此方法接受 `record` 作為參數，驗證行為寫在這個方法裡。寫好 Validator，使用時則是用 `validates_with`。

```ruby
class MyValidator < ActiveModel::Validator
  def validate(record)
    unless record.name.starts_with? 'X'
      record.errors[:name] << 'Need a name starting with X please!'
    end
  end
end

class Person
  include ActiveModel::Validations
  validates_with MyValidator
end
```

加入自定 Validator 來驗證每一個屬性的最簡單方法是使用 `ActiveModel::EachValidator`。在這個例子裡，自定的 Validator 類別必須實作一個 `validate_each` 方法，接受三個參數，`record`、`attribute` 以及 `value`，分別對應到要驗證的紀錄、屬性、屬性值。

```ruby
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      record.errors[attribute] << (options[:message] || "is not an email")
    end
  end
end

class Person < ActiveRecord::Base
  validates :email, presence: true, email: true
end
```

如上例所示，也可以在自定的 Validator 裡結合標準的驗證方法。

### 自定方法

也可以寫方法來驗證 Model 的狀態，並在 Model 狀態無效的情況下將錯誤加入 `errors` 集合。必須使用 `validate` 這個類別方法來註冊。

這個類別方法接受多個符號，執行的順序按照註冊的順序。

```ruby
class Invoice < ActiveRecord::Base
  validate :expiration_date_cannot_be_in_the_past,
    :discount_cannot_be_greater_than_total_value

  def expiration_date_cannot_be_in_the_past
    if expiration_date.present? && expiration_date < Date.today
      errors.add(:expiration_date, "can't be in the past")
    end
  end

  def discount_cannot_be_greater_than_total_value
    if discount > total_value
      errors.add(:discount, "can't be greater than total value")
    end
  end
end
```

預設情況下，每當你呼叫 `valid?` 時，都會執行這些自定的驗證方法。也可以透過 `:on` 來決定何時觸發自定驗證方法，可指定 `:create` 或 `:update`。

```ruby
class Invoice < ActiveRecord::Base
  validate :active_customer, on: :create

  def active_customer
    errors.add(:customer_id, "is not active") unless customer.active?
  end
end
```

處理驗證錯誤
------------------------------

除了前面介紹過的 `valid?` 與 `invalid?` 之外，Rails 提供了許多方法來處理 `errors` 集合、查詢物件的有效性。

以下是最常使用的方法。請參考 `ActiveModel::Errors` 的文件來了解所有可用的方法。

### `errors`

此方法回傳 `ActiveModel::Errors` 類別的實體，包含了所有的錯誤。屬性名稱為鍵，值為由錯誤訊息字串組成的陣列，

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors.messages
 # => {:name=>["can't be blank", "is too short (minimum is 3 characters)"]}

person = Person.new(name: "John Doe")
person.valid? # => true
person.errors.messages # => {}
```

### `errors[]`

`errors[]` 用來檢查特定屬性的錯誤訊息。會回傳給定屬性的錯誤訊息字串陣列，每個字串都是一個錯誤訊息。如果該屬性沒有錯誤，則返回空陣列。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new(name: "John Doe")
person.valid? # => true
person.errors[:name] # => []

person = Person.new(name: "JD")
person.valid? # => false
person.errors[:name] # => ["is too short (minimum is 3 characters)"]

person = Person.new
person.valid? # => false
person.errors[:name]
 # => ["can't be blank", "is too short (minimum is 3 characters)"]
```

### `errors.add`

`errors.add` 方法讓你手動加上特定屬性的錯誤訊息。可以使用 `errors.full_messages` 或是 `errors.to_a` 方法來檢視最終將呈現給使用者的錯誤訊息。這些特定的錯誤訊息前面會附上屬性名稱（大寫形式）。`errors.add` 接受的參數為：要加上錯誤訊息的屬性、錯誤訊息內容。

```ruby
class Person < ActiveRecord::Base
  def a_method_used_for_validation_purposes
    errors.add(:name, "cannot contain the characters !@#%*()_-+=")
  end
end

person = Person.create(name: "!@#")

person.errors[:name]
 # => ["cannot contain the characters !@#%*()_-+="]

person.errors.full_messages
 # => ["Name cannot contain the characters !@#%*()_-+="]
```

另一種方式是使用 `[]=` Setter。

```ruby
  class Person < ActiveRecord::Base
    def a_method_used_for_validation_purposes
      errors[:name] = "cannot contain the characters !@#%*()_-+="
    end
  end

  person = Person.create(name: "!@#")

  person.errors[:name]
   # => ["cannot contain the characters !@#%*()_-+="]

  person.errors.to_a
   # => ["Name cannot contain the characters !@#%*()_-+="]
```

### `errors[:base]`

可以針對整個物件本身新增錯誤訊息，而不是針對某個特定的屬性。不論是那個值所導致的錯誤，想要把物件標記為無效的時候，可以使用這個方法。由於 `errors[:base]` 是個陣列，可以加入字串進去，字串會被當成錯誤訊息使用。

```ruby
class Person < ActiveRecord::Base
  def a_method_used_for_validation_purposes
    errors[:base] << "This person is invalid because ..."
  end
end
```

### `errors.clear`

`errors.clear` 方法可以清除 `errors` 集合裡的所有錯誤。當然了，對無效物件呼叫 `errors.clear` 不會使其有效，只是清除了錯誤訊息。下次再呼叫 `valid?`，或是其它會呼叫 `save` 的方法時，驗證再次觸發，失敗的錯誤訊息仍會將錯誤填入 `errors` 集合。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors[:name]
 # => ["can't be blank", "is too short (minimum is 3 characters)"]

person.errors.clear
person.errors.empty? # => true

p.save # => false

p.errors[:name]
# => ["can't be blank", "is too short (minimum is 3 characters)"]
```

### `errors.size`

`size` 方法回傳物件錯誤訊息的總數。

```ruby
class Person < ActiveRecord::Base
  validates :name, presence: true, length: { minimum: 3 }
end

person = Person.new
person.valid? # => false
person.errors.size # => 2

person = Person.new(name: "Andrea", email: "andrea@example.com")
person.valid? # => true
person.errors.size # => 0
```

在 View 顯示驗證失敗訊息
-------------------------------------

一旦 Model 建好，也加入驗證。用表單新建模型時，可能會需要在驗證失敗的欄位顯示錯誤訊息。

因為每個應用程式處理錯誤的方式不同，Rails 沒有直接提供 View 層級的輔助方法，來直接產生這些錯誤訊息。

然而，Rails 大量豐富的驗證方法，自己寫一個顯示錯誤的輔助方法也不難。當使用 Scaffold 產生時，Rails 會在 `_form.html.erb` 加入一些 ERB，用來產生 Model 的完整錯誤清單。

假設我們有個 Model 存在實體變數 `@article` 裡，View 則可以這麼寫：

```ruby
<% if @article.errors.any? %>
  <div id="error_explanation">
    <h2><%= pluralize(@article.errors.count, "error") %> prohibited this article from being saved:</h2>

    <ul>
    <% @article.errors.full_messages.each do |msg| %>
      <li><%= msg %></li>
    <% end %>
    </ul>
  </div>
<% end %>
```

再者，如果使用 Rails 的表單輔助方法來產生表單時，當某個欄位驗證失敗時，Rails 會在該欄位包一個 `<div>`。

```
<div class="field_with_errors">
 <input id="article_title" name="article[title]" size="30" type="text" value="">
</div>
```

這個 div 可以加上任何樣式。Rails Scaffold 預設產生的 CSS 樣式為：

```css
.field_with_errors {
  padding: 2px;
  background-color: red;
  display: table;
}
```

任何有錯誤的欄位都會加上 2px 的紅框。
