Active Record 關聯
==========================

本篇介紹 Active Record 的關聯功能。

讀完本篇，您將學會

* 如何宣告 Active Record Model 之間的關聯。
* 如何理解 Active Record 的各種關聯。
* 如何使用關聯加入的方法。

--------------------------------------------------------------------------------

為什麼需要關聯？
-----------------

為什麼 Model 之間要有關聯？關聯簡化了常見的操作，程式碼撰寫起來更簡單。比如，一個簡單的 Rails 應用程式，有顧客與訂單 Model。每個顧客可有多筆訂單。若沒有關聯功能，則 Model 看起來會像是：

```ruby
class Customer < ActiveRecord::Base
end

class Order < ActiveRecord::Base
end
```

為顧客加一筆訂單：

```ruby
@order = Order.create(order_date: Time.now, customer_id: @customer.id)
```

刪除顧客以及顧客所有相關的訂單：

```ruby
@orders = Order.where(customer_id: @customer.id)
@orders.each do |order|
  order.destroy
end
@customer.destroy
```

有了 Active Record 關聯，可以透過告訴 Rails Model 之間的關聯，來精簡上例。以下是簡化後的程式碼：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, dependent: :destroy
end

class Order < ActiveRecord::Base
  belongs_to :customer
end
```

改寫成這樣後，給顧客建新訂單變得簡單許多：

```ruby
@order = @customer.orders.create(order_date: Time.now)
```

刪除顧客以及有關訂單更是簡單多了：

```ruby
@customer.destroy
```

了解各種關聯的用途，請閱讀本篇下一節。下一節介紹關聯種類、各種關聯的秘訣與小技巧，本篇最後是 Rails 關聯的選項與方法的完整參考手冊。

關聯種類
-------------------------

在 Rails 的世界裡，__關聯__連結了兩個 Active Record Model。關聯使用宏風格（macro-style）的語法來呼叫，以宣告的形式加入功能到 Model。舉例來說，透過宣告一個 Model 屬於另一個，來告訴 Rails 如何維護兩者之間的主外鍵，同時獲得許多實用的方法。Rails 支援以下六種關聯：

* `belongs_to`
* `has_one`
* `has_many`
* `has_many :through`
* `has_one :through`
* `has_and_belongs_to_many`

本篇之後細講各種關聯如何使用，首先介紹各種關聯的應用場景。

### `belongs_to` 關聯

`belongs_to` 關聯建立兩個 Model 之間的一對一關係。`belongs_to` 關聯宣告一個 Model 實例屬於另一個 Model 實例。舉例來說，應用程式有顧客與訂單兩個 Model，每筆訂單只屬於一位顧客，訂單 Model 便如此宣告：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

![belongs_to Association Diagram](images/belongs_to.png)

NOTE: `belongs_to` 宣告**必須**使用單數形式。上例若使用複數形式，會報 `"uninitialized constant Order::Customers"` 錯誤。這是因為 Rails 自動從關聯名稱推斷出類別名稱。關聯名稱錯用複數，推斷出來的類別名稱自然也錯了。

上例對應的遷移看起來會像是：

```ruby
class CreateOrders < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :name
      t.timestamps
    end

    create_table :orders do |t|
      t.belongs_to :customer
      t.datetime :order_date
      t.timestamps
    end
  end
end
```

### `has_one` 關聯

`has_one` 關聯建立兩個 Model 之間的一對一關係，但語義與結果不同。`has_one` 關聯宣告一個 Model 實例，含有（或持有）另一個 Model 實例。舉例來說，每個供應商在應用程式裡只有一個帳號，供應商 Model 便如此宣告：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end
```

![has_one Association Diagram](images/has_one.png)

上例對應的遷移看起來會像是：

```ruby
class CreateSuppliers < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end
  end
end
```

### `has_many` 關聯

`has_many` 關聯建立兩個 Model 之間的一對多關係。通常 `has_many` 另一邊對應的是 `belongs_to` 關聯。`has_many` 關聯宣告一個 Model 實例有零個或多個另一個 Model 實例。舉例來說，應用程式有顧客與訂單兩個 Model，顧客可有多筆訂單，訂單 Model 便如此宣告：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end
```

NOTE: 宣告 `has_many` 關聯名稱採__複數__。

![has_many Association Diagram](images/has_many.png)

上例對應的遷移看起來會像是：

```ruby
class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :name
      t.timestamps
    end

    create_table :orders do |t|
      t.belongs_to :customer
      t.datetime :order_date
      t.timestamps
    end
  end
end
```

### `has_many :through` 關聯

`has_many :through` 關聯通常用來建立兩個 Model 之間的多對多關係。`has_many :through` 關聯__透過（through）__第三個 Model，宣告一個 Model 實例可有零個或多個另一個 Model 實例。舉個醫療的例子，“病患”需要__透過__“預約”來見“物理治療師”。相對應的宣告如下：

```ruby
class Physician < ActiveRecord::Base
  has_many :appointments
  has_many :patients, through: :appointments
end

class Appointment < ActiveRecord::Base
  belongs_to :physician
  belongs_to :patient
end

class Patient < ActiveRecord::Base
  has_many :appointments
  has_many :physicians, through: :appointments
end
```

![has_many :through Association Diagram](images/has_many_through.png)

上例對應的遷移看起來會像是：

```ruby
class CreateAppointments < ActiveRecord::Migration
  def change
    create_table :physicians do |t|
      t.string :name
      t.timestamps
    end

    create_table :patients do |t|
      t.string :name
      t.timestamps
    end

    create_table :appointments do |t|
      t.belongs_to :physician
      t.belongs_to :patient
      t.datetime :appointment_date
      t.timestamps
    end
  end
end
```

連接 Model（Join Model）的集合可以用 API 關聯。比如：

```ruby
physician.patients = patients
```

會為新建立的關聯物件建立 Join Model，如果刪除了其中一個物件，也會刪除對應的資料庫記錄。

WARNING: 自動刪除連接 Model 會直接執行，不會觸發任何 destroy 回呼。

`has_many :through` 關聯在簡化巢狀的 `has_many` 關聯很有用。比如文件有多個章節、段落。想要簡單地從文件取得所有段落，可以這麼寫：

```ruby
class Document < ActiveRecord::Base
  has_many :sections
  has_many :paragraphs, through: :sections
end

class Section < ActiveRecord::Base
  belongs_to :document
  has_many :paragraphs
end

class Paragraph < ActiveRecord::Base
  belongs_to :section
end
```

指定了 `has_many :paragraphs, through: :sections` 之後，Rails 便懂得如何透過章節，從文件中取得段落：

```ruby
@document.paragraphs
```

### `has_one :through` 關聯

`has_one :through` 關聯建立兩個 Model 之間的一對一關係。`has_one :through` 關聯__透過（through）__第三個 Model，宣告一個 Model 實例可有另一個 Model 實例。舉例來說，供應商有一個帳號，每個帳號有帳號歷史，則供應商 Model 看起來像是：

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
  has_one :account_history, through: :account
end

class Account < ActiveRecord::Base
  belongs_to :supplier
  has_one :account_history
end

class AccountHistory < ActiveRecord::Base
  belongs_to :account
end
```

![has_one :through Association Diagram](images/has_one_through.png)

上例對應的遷移看起來會像是：

```ruby
class CreateAccountHistories < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.belongs_to :supplier
      t.string :account_number
      t.timestamps
    end

    create_table :account_histories do |t|
      t.belongs_to :account
      t.integer :credit_rating
      t.timestamps
    end
  end
end
```

### `has_and_belongs_to_many` 關聯

`has_and_belongs_to_many` 關聯建立兩個 Model 之間__直接的__多對多關係。舉例來說，應用程式有組件（Assembly），組件下有部件（Part），可以如此宣告：

```ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

![has_and_belongs_to_many Association Diagram](images/habtm.png)

上例對應的遷移看起來會像是：

```ruby
class CreateAssembliesAndParts < ActiveRecord::Migration
  def change
    create_table :assemblies do |t|
      t.string :name
      t.timestamps
    end

    create_table :parts do |t|
      t.string :part_number
      t.timestamps
    end

    create_table :assemblies_parts, id: false do |t|
      t.belongs_to :assembly
      t.belongs_to :part
    end
  end
end
```

### `belongs_to` 與 `has_one` 的應用場景

如果想建立兩個 Model 之間的一對一關係，一邊宣告 `belongs_to`，另一邊宣告 `has_one`。怎麼知道那個要寫那個？

差異在於外鍵放在那個 Model（__外鍵放在宣告 `belongs_to` 的關聯的資料表__）。但應該要考慮實際的語義。比如 `has_one` 關聯表示某物屬於你，也就是供應商有一個帳號，比帳號擁有供應商合理。所以正確的關聯應這麼宣告：

```ruby
class Supplier < ActiveRecord::Base
end

class Account < ActiveRecord::Base
  belongs_to :supplier
end
```

上例對應的遷移看起來會像是：

```ruby
class CreateSuppliers < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string  :name
      t.timestamps
    end

    create_table :accounts do |t|
      t.integer :supplier_id
      t.string  :account_number
      t.timestamps
    end
  end
end
```

NOTE: 使用 `t.integer :supplier_id` 讓外鍵看起來更明確。這種寫法可以使用 `t.references :supplier` 抽象掉實作細節。

### `has_many :through` 與 `has_and_belongs_to_many` 的應用場景

Rails 提供兩種方式來宣告多對多關係。簡單的方法是使用 `has_and_belongs_to_many` 來直接建立多對多關聯：

```ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

第二種建立多對多關係的方式是使用 `has_many :through`。這透過連接的 Model，間接建立出多對多關聯：

```ruby
class Assembly < ActiveRecord::Base
  has_many :manifests
  has_many :parts, through: :manifests
end

class Manifest < ActiveRecord::Base
  belongs_to :assembly
  belongs_to :part
end

class Part < ActiveRecord::Base
  has_many :manifests
  has_many :assemblies, through: :manifests
end
```

最簡單的經驗法則表示，當多對多關係中間的 Model 要獨立使用時，使用 `has_many :through`；不需要對多對多關係中間的 Model 做任何事時，保持簡單使用 `has_and_belongs_to_many`（但要記得在資料庫建立連接的資料表）。

若是連接的資料表需要驗證、回呼或其他屬性時，使用 `has_many :through`。

### 多型關聯

一種更進階的關聯用法是__多型關聯__。使用多型關聯，單個關聯裡，Model 可屬於多個 Model。舉例來說，圖片 Model 可屬於員工或產品 Model。以下是如何宣告：

```ruby
class Picture < ActiveRecord::Base
  belongs_to :imageable, polymorphic: true
end

class Employee < ActiveRecord::Base
  has_many :pictures, as: :imageable
end

class Product < ActiveRecord::Base
  has_many :pictures, as: :imageable
end
```

可以把多型的 `belongs_to` 宣告想成是一個介面，任何 Model 皆可使用的介面。在 `Employee` Model，可以透過 `@employee.pictures` 來取出所有圖片。同樣的，在 `Product` Model 亦然：`@product.pictures`。

如果有一個 `Picture` Model 的實例，可以使用 `@picture.imageable` 看擁有這張圖片的是誰（父物件）。但首先需要先在遷移裡宣告外鍵（`*_id`）與類型（`*_type`）欄位，`*_type` 宣告此 Model 擁有多型介面：

```ruby
class CreatePictures < ActiveRecord::Migration
  def change
    create_table :pictures do |t|
      t.string  :name
      t.integer :imageable_id
      t.string  :imageable_type
      t.timestamps
    end
  end
end
```

上例遷移可用 `t.references` 形式簡化：

```ruby
class CreatePictures < ActiveRecord::Migration
  def change
    create_table :pictures do |t|
      t.string :name
      t.references :imageable, polymorphic: true
      t.timestamps
    end
  end
end
```

![Polymorphic Association Diagram](images/polymorphic.png)

### 自連接

在設計資料 Model 時會發現，有的 Model 自己與自己有關係。舉例來說，可能會想把員工資料通通存在一張資料表，但又要能夠追蹤像是經理或下屬之間的關係。這種情況可以使用自連接（Self join）關聯：

```ruby
class Employee < ActiveRecord::Base
  has_many :subordinates, class_name: "Employee",
                          foreign_key: "manager_id"

  belongs_to :manager, class_name: "Employee"
end
```

這麼設定好後，可以使用 `@employee.subordinates` 與 `@employee.manager` 來取出經理與下屬。

在遷移裡則是需要加入參照自己的欄位：

```ruby
class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.references :manager
      t.timestamps
    end
  end
end
```

秘訣、技巧與注意事項
--------------------------

以下是在 Rails 裡有效使用 Active Record 關聯所需要知道的二三事：

* 控制快取
* 避免命名衝突
* 更新資料庫綱要
* 控制關聯作用域
* 雙向關聯

### 控制快取

所有關聯新增的方法皆圍繞著快取打轉。這些方法會保留最近的查詢結果，供之後的查詢使用。快取甚至可在方法之間共享，比如：

```ruby
customer.orders        # 從資料庫取出訂單，快取之。
customer.orders.size   # 使用快取的訂單查詢數量
customer.orders.empty? # 使用快取的訂單檢查是否為空
```

但要是應用程式某部分更新了資料，想重載快取呢？呼叫關聯方法時傳入 `true` 即可：

```ruby
customer.orders              # 從資料庫取出訂單，快取。
customer.orders.size         # 使用快取的訂單查詢數量
customer.orders(true).empty? # 捨棄快取的訂單，重新去資料庫取出訂單，檢查是否為空。
```

### 避免命名衝突

關聯名稱不可隨意使用。因為在建立關聯時，會新增與關聯名稱相同的方法。若是關聯名稱與 `ActiveRecord::Base` 的實例方法相同時，關聯新增的方法會覆蓋掉 `ActiveRecord::Base` 的實例方法。比如 `attributes` 或 `connection` 是不好的關聯名稱。

### 更新資料庫綱要

關聯非常非常有用，但沒什麼神奇的。為關聯維護對應的資料庫綱要是您的責任。不同關聯需要做的事不同。對於 `belongs_to` 關聯來說，需要建立外鍵；對於 `has_and_belongs_to_many` 則需要建立適當的連接資料表。

#### 為 `belongs_to` 關聯建立外鍵

當宣告了 `belongs_to` 關聯時，需要建立外鍵。看看下面這個 Model：

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

這個宣告需要在訂單資料表建立適當的外鍵才有效：

```ruby
class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.datetime :order_date
      t.string   :order_number
      t.integer  :customer_id
    end
  end
end
```

若在建立 Model 之後才宣告關聯，記得使用 `add_column` 遷移來提供所需的外鍵。

#### 為 `has_and_belongs_to_many` 關聯建立連接資料表

如果建立了 `has_and_belongs_to_many` 關聯，需要明確的建一張連接表。除非資料表已在 `:join_table` 選項中指定，否則 Active Record 會以關聯的類別名稱，依照辭典順序先後來命名這張連接資料表。假設 `Customer` 與 `Order` Model 預設的連接表名稱是 `customers_orders`，因為在詞法序當中，`c` 的地位高於 `o`。

WARNING: Model 名稱的優先順序使用 `String` 的 `<` 來計算。若字串不一樣長，比較最短長度時，兩個字串是相等的。但長字串詞法地位高於短字串。舉例來說，你可能認為 `paper_boxes` 與 `papers` 這兩個資料表產生的連接表名稱是 `papers_paper_boxes`，因為 `paper_boxes` 比 `papers` 長。但實際上是 `paper_boxes_papers`，因為在常見的編碼裡，`_` 的詞法地位高於 `s`。

不論名稱為何，必須要在適當的遷移中，手動產生連接表。考慮下面的關聯範例：

```ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

關聯要有效，還需寫一個遷移來建立 `assemblies_parts` 資料表。並且此表無主鍵：

```ruby
class CreateAssembliesPartsJoinTable < ActiveRecord::Migration
  def change
    create_table :assemblies_parts, id: false do |t|
      t.integer :assembly_id
      t.integer :part_id
    end
  end
end
```

`create_table` 傳入 `id: false` 因為資料表無需表示一個 Model。這張資料表只是為了讓關聯可以正常工作。如果你發現 `has_and_belongs_to_many` 關聯出現任何奇怪的行為，像是 ID 錯位、ID 衝突，很可能就是因為忘記去掉主鍵。

### 控制關聯作用域

預設關聯只會在目前模組的作用域裡尋找物件。這在模組裡宣告 Active Record Model 時很重要，比如：

```ruby
module MyApplication
  module Business
    class Supplier < ActiveRecord::Base
       has_one :account
    end

    class Account < ActiveRecord::Base
       belongs_to :supplier
    end
  end
end
```

這沒什麼問題，因為 `Supplier` 與 `Account` 在相同的作用域裡定義。但以下不會正常工作，因為 `Supplier` 與 `Account` 定義在不同的作用域裡。


```ruby
module MyApplication
  module Business
    class Supplier < ActiveRecord::Base
       has_one :account
    end
  end

  module Billing
    class Account < ActiveRecord::Base
       belongs_to :supplier
    end
  end
end
```

要將不同命名空間下的 Model 關聯起來，可以在宣告關聯時指定完整的類別名稱：

```ruby
module MyApplication
  module Business
    class Supplier < ActiveRecord::Base
       has_one :account,
        class_name: "MyApplication::Billing::Account"
    end
  end

  module Billing
    class Account < ActiveRecord::Base
       belongs_to :supplier,
        class_name: "MyApplication::Business::Supplier"
    end
  end
end
```

### 雙向關聯

關聯兩邊都可以工作是很常見的需求，這需要在兩邊都宣告：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end

class Order < ActiveRecord::Base
  belongs_to :customer
end
```

Active Record 預設不知道這些關聯的連結關係。這可能會導致複製一個物件的不同步：

```ruby
c = Customer.first
o = c.orders.first
c.first_name == o.customer.first_name # => true
c.first_name = 'Manny'
c.first_name == o.customer.first_name # => false
```

只所以會這樣的原因是，`c` 與 `o.customer` 在記憶體裡是表示相同資料的兩種表示，改了一個不會自動改另一個。Active Record 提供了 `inverse_of` 選項，用來通知 Rails 關聯之間的關係：

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, inverse_of: :customer
end

class Order < ActiveRecord::Base
  belongs_to :customer, inverse_of: :orders
end
```

加上了 `inverse_of` 後，Active Record 只會載入一個顧客物件，避免資料的不一致，並提高應用程式的效率：

```ruby
c = Customer.first
o = c.orders.first
c.first_name == o.customer.first_name # => true
c.first_name = 'Manny'
c.first_name == o.customer.first_name # => true
```

`inverse_of` 有幾點限制：

* 不能與 `:through` 關聯同時使用。
* 不能與 `:polymorphic` 關聯同時使用。
* 不能與 `:as` 選項同時使用。
* 對 `belongs_to` 關聯，會忽略 `has_many` 所設定的 `inverse_of`。

每種關聯皆會試著自動找到對應的關聯，並根據關聯名稱來合理地設定 `:inverse_of` 選項。多數使用標準名稱的關聯都會自動設定。但使用了以下選項的關聯，則無法自動設定：

* `:conditions`
* `:through`
* `:polymorphic`
* `:foreign_key`

關聯完整參考手冊
------------------------------

The following sections give the details of each type of association, including the methods that they add and the options that you can use when declaring an association.

### `belongs_to` Association Reference

The `belongs_to` association creates a one-to-one match with another model. In database terms, this association says that this class contains the foreign key. If the other class contains the foreign key, then you should use `has_one` instead.

#### Methods Added by `belongs_to`

When you declare a `belongs_to` association, the declaring class automatically gains five methods related to the association:

* `association(force_reload = false)`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`

In all of these methods, `association` is replaced with the symbol passed as the first argument to `belongs_to`. For example, given the declaration:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

Each instance of the order model will have these methods:

```ruby
customer
customer=
build_customer
create_customer
create_customer!
```

NOTE: When initializing a new `has_one` or `belongs_to` association you must use the `build_` prefix to build the association, rather than the `association.build` method that would be used for `has_many` or `has_and_belongs_to_many` associations. To create one, use the `create_` prefix.

##### `association(force_reload = false)`

The `association` method returns the associated object, if any. If no associated object is found, it returns `nil`.

```ruby
@customer = @order.customer
```

If the associated object has already been retrieved from the database for this object, the cached version will be returned. To override this behavior (and force a database read), pass `true` as the `force_reload` argument.

##### `association=(associate)`

The `association=` method assigns an associated object to this object. Behind the scenes, this means extracting the primary key from the associate object and setting this object's foreign key to the same value.

```ruby
@order.customer = @customer
```

##### `build_association(attributes = {})`

The `build_association` method returns a new object of the associated type. This object will be instantiated from the passed attributes, and the link through this object's foreign key will be set, but the associated object will _not_ yet be saved.

```ruby
@customer = @order.build_customer(customer_number: 123,
                                  customer_name: "John Doe")
```

##### `create_association(attributes = {})`

The `create_association` method returns a new object of the associated type. This object will be instantiated from the passed attributes, the link through this object's foreign key will be set, and, once it passes all of the validations specified on the associated model, the associated object _will_ be saved.

```ruby
@customer = @order.create_customer(customer_number: 123,
                                   customer_name: "John Doe")
```

##### `create_association!(attributes = {})`

Does the same as `create_association` above, but raises `ActiveRecord::RecordInvalid` if the record is invalid.


#### Options for `belongs_to`

While Rails uses intelligent defaults that will work well in most situations, there may be times when you want to customize the behavior of the `belongs_to` association reference. Such customizations can easily be accomplished by passing options and scope blocks when you create the association. For example, this association uses two such options:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, dependent: :destroy,
    counter_cache: true
end
```

The `belongs_to` association supports these options:

* `:autosave`
* `:class_name`
* `:counter_cache`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:polymorphic`
* `:touch`
* `:validate`

##### `:autosave`

If you set the `:autosave` option to `true`, Rails will save any loaded members and destroy members that are marked for destruction whenever you save the parent object.

##### `:class_name`

If the name of the other model cannot be derived from the association name, you can use the `:class_name` option to supply the model name. For example, if an order belongs to a customer, but the actual name of the model containing customers is `Patron`, you'd set things up this way:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, class_name: "Patron"
end
```

##### `:counter_cache`

The `:counter_cache` option can be used to make finding the number of belonging objects more efficient. Consider these models:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
class Customer < ActiveRecord::Base
  has_many :orders
end
```

With these declarations, asking for the value of `@customer.orders.size` requires making a call to the database to perform a `COUNT(*)` query. To avoid this call, you can add a counter cache to the _belonging_ model:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, counter_cache: true
end
class Customer < ActiveRecord::Base
  has_many :orders
end
```

With this declaration, Rails will keep the cache value up to date, and then return that value in response to the `size` method.

Although the `:counter_cache` option is specified on the model that includes the `belongs_to` declaration, the actual column must be added to the _associated_ model. In the case above, you would need to add a column named `orders_count` to the `Customer` model. You can override the default column name if you need to:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, counter_cache: :count_of_orders
end
class Customer < ActiveRecord::Base
  has_many :orders
end
```

Counter cache columns are added to the containing model's list of read-only attributes through `attr_readonly`.

##### `:dependent`
If you set the `:dependent` option to:

* `:destroy`, when the object is destroyed, `destroy` will be called on its
associated objects.
* `:delete`, when the object is destroyed, all its associated objects will be
deleted directly from the database without calling their `destroy` method.

WARNING: You should not specify this option on a `belongs_to` association that is connected with a `has_many` association on the other class. Doing so can lead to orphaned records in your database.

##### `:foreign_key`

By convention, Rails assumes that the column used to hold the foreign key on this model is the name of the association with the suffix `_id` added. The `:foreign_key` option lets you set the name of the foreign key directly:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, class_name: "Patron",
                        foreign_key: "patron_id"
end
```

TIP: In any case, Rails will not create foreign key columns for you. You need to explicitly define them as part of your migrations.

##### `:inverse_of`

The `:inverse_of` option specifies the name of the `has_many` or `has_one` association that is the inverse of this association. Does not work in combination with the `:polymorphic` options.

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, inverse_of: :customer
end

class Order < ActiveRecord::Base
  belongs_to :customer, inverse_of: :orders
end
```

##### `:polymorphic`

Passing `true` to the `:polymorphic` option indicates that this is a polymorphic association. Polymorphic associations were discussed in detail <a href="#polymorphic-associations">earlier in this guide</a>.

##### `:touch`

If you set the `:touch` option to `:true`, then the `updated_at` or `updated_on` timestamp on the associated object will be set to the current time whenever this object is saved or destroyed:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, touch: true
end

class Customer < ActiveRecord::Base
  has_many :orders
end
```

In this case, saving or destroying an order will update the timestamp on the associated customer. You can also specify a particular timestamp attribute to update:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, touch: :orders_updated_at
end
```

##### `:validate`

If you set the `:validate` option to `true`, then associated objects will be validated whenever you save this object. By default, this is `false`: associated objects will not be validated when this object is saved.

#### Scopes for `belongs_to`

There may be times when you wish to customize the query used by `belongs_to`. Such customizations can be achieved via a scope block. For example:

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, -> { where active: true },
                        dependent: :destroy
end
```

You can use any of the standard [querying methods](active_record_querying.html) inside the scope block. The following ones are discussed below:

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

The `where` method lets you specify the conditions that the associated object must meet.

```ruby
class Order < ActiveRecord::Base
  belongs_to :customer, -> { where active: true }
end
```

##### `includes`

You can use the `includes` method to specify second-order associations that should be eager-loaded when this association is used. For example, consider these models:

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class Customer < ActiveRecord::Base
  has_many :orders
end
```

If you frequently retrieve customers directly from line items (`@line_item.order.customer`), then you can make your code somewhat more efficient by including customers in the association from line items to orders:

```ruby
class LineItem < ActiveRecord::Base
  belongs_to :order, -> { includes :customer }
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class Customer < ActiveRecord::Base
  has_many :orders
end
```

NOTE: There's no need to use `includes` for immediate associations - that is, if you have `Order belongs_to :customer`, then the customer is eager-loaded automatically when it's needed.

##### `readonly`

If you use `readonly`, then the associated object will be read-only when retrieved via the association.

##### `select`

The `select` method lets you override the SQL `SELECT` clause that is used to retrieve data about the associated object. By default, Rails retrieves all columns.

TIP: If you use the `select` method on a `belongs_to` association, you should also set the `:foreign_key` option to guarantee the correct results.

#### Do Any Associated Objects Exist?

You can see if any associated objects exist by using the `association.nil?` method:

```ruby
if @order.customer.nil?
  @msg = "No customer found for this order"
end
```

#### When are Objects Saved?

Assigning an object to a `belongs_to` association does _not_ automatically save the object. It does not save the associated object either.

### `has_one` Association Reference

The `has_one` association creates a one-to-one match with another model. In database terms, this association says that the other class contains the foreign key. If this class contains the foreign key, then you should use `belongs_to` instead.

#### Methods Added by `has_one`

When you declare a `has_one` association, the declaring class automatically gains five methods related to the association:

* `association(force_reload = false)`
* `association=(associate)`
* `build_association(attributes = {})`
* `create_association(attributes = {})`
* `create_association!(attributes = {})`

In all of these methods, `association` is replaced with the symbol passed as the first argument to `has_one`. For example, given the declaration:

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end
```

Each instance of the `Supplier` model will have these methods:

```ruby
account
account=
build_account
create_account
create_account!
```

NOTE: When initializing a new `has_one` or `belongs_to` association you must use the `build_` prefix to build the association, rather than the `association.build` method that would be used for `has_many` or `has_and_belongs_to_many` associations. To create one, use the `create_` prefix.

##### `association(force_reload = false)`

The `association` method returns the associated object, if any. If no associated object is found, it returns `nil`.

```ruby
@account = @supplier.account
```

If the associated object has already been retrieved from the database for this object, the cached version will be returned. To override this behavior (and force a database read), pass `true` as the `force_reload` argument.

##### `association=(associate)`

The `association=` method assigns an associated object to this object. Behind the scenes, this means extracting the primary key from this object and setting the associate object's foreign key to the same value.

```ruby
@supplier.account = @account
```

##### `build_association(attributes = {})`

The `build_association` method returns a new object of the associated type. This object will be instantiated from the passed attributes, and the link through its foreign key will be set, but the associated object will _not_ yet be saved.

```ruby
@account = @supplier.build_account(terms: "Net 30")
```

##### `create_association(attributes = {})`

The `create_association` method returns a new object of the associated type. This object will be instantiated from the passed attributes, the link through its foreign key will be set, and, once it passes all of the validations specified on the associated model, the associated object _will_ be saved.

```ruby
@account = @supplier.create_account(terms: "Net 30")
```

##### `create_association!(attributes = {})`

Does the same as `create_association` above, but raises `ActiveRecord::RecordInvalid` if the record is invalid.

#### Options for `has_one`

While Rails uses intelligent defaults that will work well in most situations, there may be times when you want to customize the behavior of the `has_one` association reference. Such customizations can easily be accomplished by passing options when you create the association. For example, this association uses two such options:

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, class_name: "Billing", dependent: :nullify
end
```

The `has_one` association supports these options:

* `:as`
* `:autosave`
* `:class_name`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:primary_key`
* `:source`
* `:source_type`
* `:through`
* `:validate`

##### `:as`

Setting the `:as` option indicates that this is a polymorphic association. Polymorphic associations were discussed in detail <a href="#polymorphic-associations">earlier in this guide</a>.

##### `:autosave`

If you set the `:autosave` option to `true`, Rails will save any loaded members and destroy members that are marked for destruction whenever you save the parent object.

##### `:class_name`

If the name of the other model cannot be derived from the association name, you can use the `:class_name` option to supply the model name. For example, if a supplier has an account, but the actual name of the model containing accounts is `Billing`, you'd set things up this way:

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, class_name: "Billing"
end
```

##### `:dependent`

Controls what happens to the associated object when its owner is destroyed:

* `:destroy` causes the associated object to also be destroyed
* `:delete` causes the associated object to be deleted directly from the database (so callbacks will not execute)
* `:nullify` causes the foreign key to be set to `NULL`. Callbacks are not executed.
* `:restrict_with_exception` causes an exception to be raised if there is an associated record
* `:restrict_with_error` causes an error to be added to the owner if there is an associated object

It's necessary not to set or leave `:nullify` option for those associations
that have `NOT NULL` database constraints. If you don't set `dependent` to
destroy such associations you won't be able to change the associated object
because initial associated object foreign key will be set to unallowed `NULL`
value.

##### `:foreign_key`

By convention, Rails assumes that the column used to hold the foreign key on the other model is the name of this model with the suffix `_id` added. The `:foreign_key` option lets you set the name of the foreign key directly:

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, foreign_key: "supp_id"
end
```

TIP: In any case, Rails will not create foreign key columns for you. You need to explicitly define them as part of your migrations.

##### `:inverse_of`

The `:inverse_of` option specifies the name of the `belongs_to` association that is the inverse of this association. Does not work in combination with the `:through` or `:as` options.

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, inverse_of: :supplier
end

class Account < ActiveRecord::Base
  belongs_to :supplier, inverse_of: :account
end
```

##### `:primary_key`

By convention, Rails assumes that the column used to hold the primary key of this model is `id`. You can override this and explicitly specify the primary key with the `:primary_key` option.

##### `:source`

The `:source` option specifies the source association name for a `has_one :through` association.

##### `:source_type`

The `:source_type` option specifies the source association type for a `has_one :through` association that proceeds through a polymorphic association.

##### `:through`

The `:through` option specifies a join model through which to perform the query. `has_one :through` associations were discussed in detail <a href="#the-has-one-through-association">earlier in this guide</a>.

##### `:validate`

If you set the `:validate` option to `true`, then associated objects will be validated whenever you save this object. By default, this is `false`: associated objects will not be validated when this object is saved.

#### Scopes for `has_one`

There may be times when you wish to customize the query used by `has_one`. Such customizations can be achieved via a scope block. For example:

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, -> { where active: true }
end
```

You can use any of the standard [querying methods](active_record_querying.html) inside the scope block. The following ones are discussed below:

* `where`
* `includes`
* `readonly`
* `select`

##### `where`

The `where` method lets you specify the conditions that the associated object must meet.

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, -> { where "confirmed = 1" }
end
```

##### `includes`

You can use the `includes` method to specify second-order associations that should be eager-loaded when this association is used. For example, consider these models:

```ruby
class Supplier < ActiveRecord::Base
  has_one :account
end

class Account < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ActiveRecord::Base
  has_many :accounts
end
```

If you frequently retrieve representatives directly from suppliers (`@supplier.account.representative`), then you can make your code somewhat more efficient by including representatives in the association from suppliers to accounts:

```ruby
class Supplier < ActiveRecord::Base
  has_one :account, -> { includes :representative }
end

class Account < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :representative
end

class Representative < ActiveRecord::Base
  has_many :accounts
end
```

##### `readonly`

If you use the `readonly` method, then the associated object will be read-only when retrieved via the association.

##### `select`

The `select` method lets you override the SQL `SELECT` clause that is used to retrieve data about the associated object. By default, Rails retrieves all columns.

#### Do Any Associated Objects Exist?

You can see if any associated objects exist by using the `association.nil?` method:

```ruby
if @supplier.account.nil?
  @msg = "No account found for this supplier"
end
```

#### When are Objects Saved?

When you assign an object to a `has_one` association, that object is automatically saved (in order to update its foreign key). In addition, any object being replaced is also automatically saved, because its foreign key will change too.

If either of these saves fails due to validation errors, then the assignment statement returns `false` and the assignment itself is cancelled.

If the parent object (the one declaring the `has_one` association) is unsaved (that is, `new_record?` returns `true`) then the child objects are not saved. They will automatically when the parent object is saved.

If you want to assign an object to a `has_one` association without saving the object, use the `association.build` method.

### `has_many` Association Reference

The `has_many` association creates a one-to-many relationship with another model. In database terms, this association says that the other class will have a foreign key that refers to instances of this class.

#### Methods Added by `has_many`

When you declare a `has_many` association, the declaring class automatically gains 16 methods related to the association:

* `collection(force_reload = false)`
* `collection<<(object, ...)`
* `collection.delete(object, ...)`
* `collection.destroy(object, ...)`
* `collection=objects`
* `collection_singular_ids`
* `collection_singular_ids=ids`
* `collection.clear`
* `collection.empty?`
* `collection.size`
* `collection.find(...)`
* `collection.where(...)`
* `collection.exists?(...)`
* `collection.build(attributes = {}, ...)`
* `collection.create(attributes = {})`
* `collection.create!(attributes = {})`

In all of these methods, `collection` is replaced with the symbol passed as the first argument to `has_many`, and `collection_singular` is replaced with the singularized version of that symbol. For example, given the declaration:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end
```

Each instance of the customer model will have these methods:

```ruby
orders(force_reload = false)
orders<<(object, ...)
orders.delete(object, ...)
orders.destroy(object, ...)
orders=objects
order_ids
order_ids=ids
orders.clear
orders.empty?
orders.size
orders.find(...)
orders.where(...)
orders.exists?(...)
orders.build(attributes = {}, ...)
orders.create(attributes = {})
orders.create!(attributes = {})
```

##### `collection(force_reload = false)`

The `collection` method returns an array of all of the associated objects. If there are no associated objects, it returns an empty array.

```ruby
@orders = @customer.orders
```

##### `collection<<(object, ...)`

The `collection<<` method adds one or more objects to the collection by setting their foreign keys to the primary key of the calling model.

```ruby
@customer.orders << @order1
```

##### `collection.delete(object, ...)`

The `collection.delete` method removes one or more objects from the collection by setting their foreign keys to `NULL`.

```ruby
@customer.orders.delete(@order1)
```

WARNING: Additionally, objects will be destroyed if they're associated with `dependent: :destroy`, and deleted if they're associated with `dependent: :delete_all`.

##### `collection.destroy(object, ...)`

The `collection.destroy` method removes one or more objects from the collection by running `destroy` on each object.

```ruby
@customer.orders.destroy(@order1)
```

WARNING: Objects will _always_ be removed from the database, ignoring the `:dependent` option.

##### `collection=objects`

The `collection=` method makes the collection contain only the supplied objects, by adding and deleting as appropriate.

##### `collection_singular_ids`

The `collection_singular_ids` method returns an array of the ids of the objects in the collection.

```ruby
@order_ids = @customer.order_ids
```

##### `collection_singular_ids=ids`

The `collection_singular_ids=` method makes the collection contain only the objects identified by the supplied primary key values, by adding and deleting as appropriate.

##### `collection.clear`

The `collection.clear` method removes every object from the collection. This destroys the associated objects if they are associated with `dependent: :destroy`, deletes them directly from the database if `dependent: :delete_all`, and otherwise sets their foreign keys to `NULL`.

##### `collection.empty?`

The `collection.empty?` method returns `true` if the collection does not contain any associated objects.

```erb
<% if @customer.orders.empty? %>
  No Orders Found
<% end %>
```

##### `collection.size`

The `collection.size` method returns the number of objects in the collection.

```ruby
@order_count = @customer.orders.size
```

##### `collection.find(...)`

The `collection.find` method finds objects within the collection. It uses the same syntax and options as `ActiveRecord::Base.find`.

```ruby
@open_orders = @customer.orders.find(1)
```

##### `collection.where(...)`

The `collection.where` method finds objects within the collection based on the conditions supplied but the objects are loaded lazily meaning that the database is queried only when the object(s) are accessed.

```ruby
@open_orders = @customer.orders.where(open: true) # No query yet
@open_order = @open_orders.first # Now the database will be queried
```

##### `collection.exists?(...)`

The `collection.exists?` method checks whether an object meeting the supplied conditions exists in the collection. It uses the same syntax and options as `ActiveRecord::Base.exists?`.

##### `collection.build(attributes = {}, ...)`

The `collection.build` method returns one or more new objects of the associated type. These objects will be instantiated from the passed attributes, and the link through their foreign key will be created, but the associated objects will _not_ yet be saved.

```ruby
@order = @customer.orders.build(order_date: Time.now,
                                order_number: "A12345")
```

##### `collection.create(attributes = {})`

The `collection.create` method returns a new object of the associated type. This object will be instantiated from the passed attributes, the link through its foreign key will be created, and, once it passes all of the validations specified on the associated model, the associated object _will_ be saved.

```ruby
@order = @customer.orders.create(order_date: Time.now,
                                 order_number: "A12345")
```

##### `collection.create!(attributes = {})`

Does the same as `collection.create` above, but raises `ActiveRecord::RecordInvalid` if the record is invalid.

#### Options for `has_many`

While Rails uses intelligent defaults that will work well in most situations, there may be times when you want to customize the behavior of the `has_many` association reference. Such customizations can easily be accomplished by passing options when you create the association. For example, this association uses two such options:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, dependent: :delete_all, validate: :false
end
```

The `has_many` association supports these options:

* `:as`
* `:autosave`
* `:class_name`
* `:dependent`
* `:foreign_key`
* `:inverse_of`
* `:primary_key`
* `:source`
* `:source_type`
* `:through`
* `:validate`

##### `:as`

Setting the `:as` option indicates that this is a polymorphic association, as discussed <a href="#polymorphic-associations">earlier in this guide</a>.

##### `:autosave`

If you set the `:autosave` option to `true`, Rails will save any loaded members and destroy members that are marked for destruction whenever you save the parent object.

##### `:class_name`

If the name of the other model cannot be derived from the association name, you can use the `:class_name` option to supply the model name. For example, if a customer has many orders, but the actual name of the model containing orders is `Transaction`, you'd set things up this way:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, class_name: "Transaction"
end
```

##### `:dependent`

Controls what happens to the associated objects when their owner is destroyed:

* `:destroy` causes all the associated objects to also be destroyed
* `:delete_all` causes all the associated objects to be deleted directly from the database (so callbacks will not execute)
* `:nullify` causes the foreign keys to be set to `NULL`. Callbacks are not executed.
* `:restrict_with_exception` causes an exception to be raised if there are any associated records
* `:restrict_with_error` causes an error to be added to the owner if there are any associated objects

NOTE: This option is ignored when you use the `:through` option on the association.

##### `:foreign_key`

By convention, Rails assumes that the column used to hold the foreign key on the other model is the name of this model with the suffix `_id` added. The `:foreign_key` option lets you set the name of the foreign key directly:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, foreign_key: "cust_id"
end
```

TIP: In any case, Rails will not create foreign key columns for you. You need to explicitly define them as part of your migrations.

##### `:inverse_of`

The `:inverse_of` option specifies the name of the `belongs_to` association that is the inverse of this association. Does not work in combination with the `:through` or `:as` options.

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, inverse_of: :customer
end

class Order < ActiveRecord::Base
  belongs_to :customer, inverse_of: :orders
end
```

##### `:primary_key`

By convention, Rails assumes that the column used to hold the primary key of the association is `id`. You can override this and explicitly specify the primary key with the `:primary_key` option.

Let's say that `users` table has `id` as the primary_key but it also has
`guid` column. And the requirement is that `todos` table should hold
`guid` column value and not `id` value. This can be achieved like this

```ruby
class User < ActiveRecord::Base
  has_many :todos, primary_key: :guid
end
```

Now if we execute `@user.todos.create` then `@todo` record will have
`user_id` value as the `guid` value of `@user`.


##### `:source`

The `:source` option specifies the source association name for a `has_many :through` association. You only need to use this option if the name of the source association cannot be automatically inferred from the association name.

##### `:source_type`

The `:source_type` option specifies the source association type for a `has_many :through` association that proceeds through a polymorphic association.

##### `:through`

The `:through` option specifies a join model through which to perform the query. `has_many :through` associations provide a way to implement many-to-many relationships, as discussed <a href="#the-has-many-through-association">earlier in this guide</a>.

##### `:validate`

If you set the `:validate` option to `false`, then associated objects will not be validated whenever you save this object. By default, this is `true`: associated objects will be validated when this object is saved.

#### Scopes for `has_many`

There may be times when you wish to customize the query used by `has_many`. Such customizations can be achieved via a scope block. For example:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, -> { where processed: true }
end
```

You can use any of the standard [querying methods](active_record_querying.html) inside the scope block. The following ones are discussed below:

* `where`
* `extending`
* `group`
* `includes`
* `limit`
* `offset`
* `order`
* `readonly`
* `select`
* `uniq`

##### `where`

The `where` method lets you specify the conditions that the associated object must meet.

```ruby
class Customer < ActiveRecord::Base
  has_many :confirmed_orders, -> { where "confirmed = 1" },
    class_name: "Order"
end
```

You can also set conditions via a hash:

```ruby
class Customer < ActiveRecord::Base
  has_many :confirmed_orders, -> { where confirmed: true },
                              class_name: "Order"
end
```

If you use a hash-style `where` option, then record creation via this association will be automatically scoped using the hash. In this case, using `@customer.confirmed_orders.create` or `@customer.confirmed_orders.build` will create orders where the confirmed column has the value `true`.

##### `extending`

The `extending` method specifies a named module to extend the association proxy. Association extensions are discussed in detail <a href="#association-extensions">later in this guide</a>.

##### `group`

The `group` method supplies an attribute name to group the result set by, using a `GROUP BY` clause in the finder SQL.

```ruby
class Customer < ActiveRecord::Base
  has_many :line_items, -> { group 'orders.id' },
                        through: :orders
end
```

##### `includes`

You can use the `includes` method to specify second-order associations that should be eager-loaded when this association is used. For example, consider these models:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class LineItem < ActiveRecord::Base
  belongs_to :order
end
```

If you frequently retrieve line items directly from customers (`@customer.orders.line_items`), then you can make your code somewhat more efficient by including line items in the association from customers to orders:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, -> { includes :line_items }
end

class Order < ActiveRecord::Base
  belongs_to :customer
  has_many :line_items
end

class LineItem < ActiveRecord::Base
  belongs_to :order
end
```

##### `limit`

The `limit` method lets you restrict the total number of objects that will be fetched through an association.

```ruby
class Customer < ActiveRecord::Base
  has_many :recent_orders,
    -> { order('order_date desc').limit(100) },
    class_name: "Order",
end
```

##### `offset`

The `offset` method lets you specify the starting offset for fetching objects via an association. For example, `-> { offset(11) }` will skip the first 11 records.

##### `order`

The `order` method dictates the order in which associated objects will be received (in the syntax used by an SQL `ORDER BY` clause).

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, -> { order "date_confirmed DESC" }
end
```

##### `readonly`

If you use the `readonly` method, then the associated objects will be read-only when retrieved via the association.

##### `select`

The `select` method lets you override the SQL `SELECT` clause that is used to retrieve data about the associated objects. By default, Rails retrieves all columns.

WARNING: If you specify your own `select`, be sure to include the primary key and foreign key columns of the associated model. If you do not, Rails will throw an error.

##### `distinct`

Use the `distinct` method to keep the collection free of duplicates. This is
mostly useful together with the `:through` option.

```ruby
class Person < ActiveRecord::Base
  has_many :readings
  has_many :posts, through: :readings
end

person = Person.create(name: 'John')
post   = Post.create(name: 'a1')
person.posts << post
person.posts << post
person.posts.inspect # => [#<Post id: 5, name: "a1">, #<Post id: 5, name: "a1">]
Reading.all.inspect  # => [#<Reading id: 12, person_id: 5, post_id: 5>, #<Reading id: 13, person_id: 5, post_id: 5>]
```

In the above case there are two readings and `person.posts` brings out both of
them even though these records are pointing to the same post.

Now let's set `distinct`:

```ruby
class Person
  has_many :readings
  has_many :posts, -> { distinct }, through: :readings
end

person = Person.create(name: 'Honda')
post   = Post.create(name: 'a1')
person.posts << post
person.posts << post
person.posts.inspect # => [#<Post id: 7, name: "a1">]
Reading.all.inspect  # => [#<Reading id: 16, person_id: 7, post_id: 7>, #<Reading id: 17, person_id: 7, post_id: 7>]
```

In the above case there are still two readings. However `person.posts` shows
only one post because the collection loads only unique records.

If you want to make sure that, upon insertion, all of the records in the
persisted association are distinct (so that you can be sure that when you
inspect the association that you will never find duplicate records), you should
add a unique index on the table itself. For example, if you have a table named
`person_posts` and you want to make sure all the posts are unique, you could
add the following in a migration:

```ruby
add_index :person_posts, :post, unique: true
```

Note that checking for uniqueness using something like `include?` is subject
to race conditions. Do not attempt to use `include?` to enforce distinctness
in an association. For instance, using the post example from above, the
following code would be racy because multiple users could be attempting this
at the same time:

```ruby
person.posts << post unless person.posts.include?(post)
```

#### When are Objects Saved?

When you assign an object to a `has_many` association, that object is automatically saved (in order to update its foreign key). If you assign multiple objects in one statement, then they are all saved.

If any of these saves fails due to validation errors, then the assignment statement returns `false` and the assignment itself is cancelled.

If the parent object (the one declaring the `has_many` association) is unsaved (that is, `new_record?` returns `true`) then the child objects are not saved when they are added. All unsaved members of the association will automatically be saved when the parent is saved.

If you want to assign an object to a `has_many` association without saving the object, use the `collection.build` method.

### `has_and_belongs_to_many` Association Reference

The `has_and_belongs_to_many` association creates a many-to-many relationship with another model. In database terms, this associates two classes via an intermediate join table that includes foreign keys referring to each of the classes.

#### Methods Added by `has_and_belongs_to_many`

When you declare a `has_and_belongs_to_many` association, the declaring class automatically gains 16 methods related to the association:

* `collection(force_reload = false)`
* `collection<<(object, ...)`
* `collection.delete(object, ...)`
* `collection.destroy(object, ...)`
* `collection=objects`
* `collection_singular_ids`
* `collection_singular_ids=ids`
* `collection.clear`
* `collection.empty?`
* `collection.size`
* `collection.find(...)`
* `collection.where(...)`
* `collection.exists?(...)`
* `collection.build(attributes = {})`
* `collection.create(attributes = {})`
* `collection.create!(attributes = {})`

In all of these methods, `collection` is replaced with the symbol passed as the first argument to `has_and_belongs_to_many`, and `collection_singular` is replaced with the singularized version of that symbol. For example, given the declaration:

```ruby
class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

Each instance of the part model will have these methods:

```ruby
assemblies(force_reload = false)
assemblies<<(object, ...)
assemblies.delete(object, ...)
assemblies.destroy(object, ...)
assemblies=objects
assembly_ids
assembly_ids=ids
assemblies.clear
assemblies.empty?
assemblies.size
assemblies.find(...)
assemblies.where(...)
assemblies.exists?(...)
assemblies.build(attributes = {}, ...)
assemblies.create(attributes = {})
assemblies.create!(attributes = {})
```

##### Additional Column Methods

If the join table for a `has_and_belongs_to_many` association has additional columns beyond the two foreign keys, these columns will be added as attributes to records retrieved via that association. Records returned with additional attributes will always be read-only, because Rails cannot save changes to those attributes.

WARNING: The use of extra attributes on the join table in a `has_and_belongs_to_many` association is deprecated. If you require this sort of complex behavior on the table that joins two models in a many-to-many relationship, you should use a `has_many :through` association instead of `has_and_belongs_to_many`.


##### `collection(force_reload = false)`

The `collection` method returns an array of all of the associated objects. If there are no associated objects, it returns an empty array.

```ruby
@assemblies = @part.assemblies
```

##### `collection<<(object, ...)`

The `collection<<` method adds one or more objects to the collection by creating records in the join table.

```ruby
@part.assemblies << @assembly1
```

NOTE: This method is aliased as `collection.concat` and `collection.push`.

##### `collection.delete(object, ...)`

The `collection.delete` method removes one or more objects from the collection by deleting records in the join table. This does not destroy the objects.

```ruby
@part.assemblies.delete(@assembly1)
```

WARNING: This does not trigger callbacks on the join records.

##### `collection.destroy(object, ...)`

The `collection.destroy` method removes one or more objects from the collection by running `destroy` on each record in the join table, including running callbacks. This does not destroy the objects.

```ruby
@part.assemblies.destroy(@assembly1)
```

##### `collection=objects`

The `collection=` method makes the collection contain only the supplied objects, by adding and deleting as appropriate.

##### `collection_singular_ids`

The `collection_singular_ids` method returns an array of the ids of the objects in the collection.

```ruby
@assembly_ids = @part.assembly_ids
```

##### `collection_singular_ids=ids`

The `collection_singular_ids=` method makes the collection contain only the objects identified by the supplied primary key values, by adding and deleting as appropriate.

##### `collection.clear`

The `collection.clear` method removes every object from the collection by deleting the rows from the joining table. This does not destroy the associated objects.

##### `collection.empty?`

The `collection.empty?` method returns `true` if the collection does not contain any associated objects.

```ruby
<% if @part.assemblies.empty? %>
  This part is not used in any assemblies
<% end %>
```

##### `collection.size`

The `collection.size` method returns the number of objects in the collection.

```ruby
@assembly_count = @part.assemblies.size
```

##### `collection.find(...)`

The `collection.find` method finds objects within the collection. It uses the same syntax and options as `ActiveRecord::Base.find`. It also adds the additional condition that the object must be in the collection.

```ruby
@assembly = @part.assemblies.find(1)
```

##### `collection.where(...)`

The `collection.where` method finds objects within the collection based on the conditions supplied but the objects are loaded lazily meaning that the database is queried only when the object(s) are accessed. It also adds the additional condition that the object must be in the collection.

```ruby
@new_assemblies = @part.assemblies.where("created_at > ?", 2.days.ago)
```

##### `collection.exists?(...)`

The `collection.exists?` method checks whether an object meeting the supplied conditions exists in the collection. It uses the same syntax and options as `ActiveRecord::Base.exists?`.

##### `collection.build(attributes = {})`

The `collection.build` method returns a new object of the associated type. This object will be instantiated from the passed attributes, and the link through the join table will be created, but the associated object will _not_ yet be saved.

```ruby
@assembly = @part.assemblies.build({assembly_name: "Transmission housing"})
```

##### `collection.create(attributes = {})`

The `collection.create` method returns a new object of the associated type. This object will be instantiated from the passed attributes, the link through the join table will be created, and, once it passes all of the validations specified on the associated model, the associated object _will_ be saved.

```ruby
@assembly = @part.assemblies.create({assembly_name: "Transmission housing"})
```

##### `collection.create!(attributes = {})`

Does the same as `collection.create`, but raises `ActiveRecord::RecordInvalid` if the record is invalid.

#### Options for `has_and_belongs_to_many`

While Rails uses intelligent defaults that will work well in most situations, there may be times when you want to customize the behavior of the `has_and_belongs_to_many` association reference. Such customizations can easily be accomplished by passing options when you create the association. For example, this association uses two such options:

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, autosave: true,
                                       readonly: true
end
```

The `has_and_belongs_to_many` association supports these options:

* `:association_foreign_key`
* `:autosave`
* `:class_name`
* `:foreign_key`
* `:join_table`
* `:validate`
* `:readonly`

##### `:association_foreign_key`

By convention, Rails assumes that the column in the join table used to hold the foreign key pointing to the other model is the name of that model with the suffix `_id` added. The `:association_foreign_key` option lets you set the name of the foreign key directly:

TIP: The `:foreign_key` and `:association_foreign_key` options are useful when setting up a many-to-many self-join. For example:

```ruby
class User < ActiveRecord::Base
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:autosave`

If you set the `:autosave` option to `true`, Rails will save any loaded members and destroy members that are marked for destruction whenever you save the parent object.

##### `:class_name`

If the name of the other model cannot be derived from the association name, you can use the `:class_name` option to supply the model name. For example, if a part has many assemblies, but the actual name of the model containing assemblies is `Gadget`, you'd set things up this way:

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, class_name: "Gadget"
end
```

##### `:foreign_key`

By convention, Rails assumes that the column in the join table used to hold the foreign key pointing to this model is the name of this model with the suffix `_id` added. The `:foreign_key` option lets you set the name of the foreign key directly:

```ruby
class User < ActiveRecord::Base
  has_and_belongs_to_many :friends,
      class_name: "User",
      foreign_key: "this_user_id",
      association_foreign_key: "other_user_id"
end
```

##### `:join_table`

If the default name of the join table, based on lexical ordering, is not what you want, you can use the `:join_table` option to override the default.

##### `:validate`

If you set the `:validate` option to `false`, then associated objects will not be validated whenever you save this object. By default, this is `true`: associated objects will be validated when this object is saved.

#### Scopes for `has_and_belongs_to_many`

There may be times when you wish to customize the query used by `has_and_belongs_to_many`. Such customizations can be achieved via a scope block. For example:

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, -> { where active: true }
end
```

You can use any of the standard [querying methods](active_record_querying.html) inside the scope block. The following ones are discussed below:

* `where`
* `extending`
* `group`
* `includes`
* `limit`
* `offset`
* `order`
* `readonly`
* `select`
* `uniq`

##### `where`

The `where` method lets you specify the conditions that the associated object must meet.

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { where "factory = 'Seattle'" }
end
```

You can also set conditions via a hash:

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { where factory: 'Seattle' }
end
```

If you use a hash-style `where`, then record creation via this association will be automatically scoped using the hash. In this case, using `@parts.assemblies.create` or `@parts.assemblies.build` will create orders where the `factory` column has the value "Seattle".

##### `extending`

The `extending` method specifies a named module to extend the association proxy. Association extensions are discussed in detail <a href="#association-extensions">later in this guide</a>.

##### `group`

The `group` method supplies an attribute name to group the result set by, using a `GROUP BY` clause in the finder SQL.

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies, -> { group "factory" }
end
```

##### `includes`

You can use the `includes` method to specify second-order associations that should be eager-loaded when this association is used.

##### `limit`

The `limit` method lets you restrict the total number of objects that will be fetched through an association.

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { order("created_at DESC").limit(50) }
end
```

##### `offset`

The `offset` method lets you specify the starting offset for fetching objects via an association. For example, if you set `offset(11)`, it will skip the first 11 records.

##### `order`

The `order` method dictates the order in which associated objects will be received (in the syntax used by an SQL `ORDER BY` clause).

```ruby
class Parts < ActiveRecord::Base
  has_and_belongs_to_many :assemblies,
    -> { order "assembly_name ASC" }
end
```

##### `readonly`

If you use the `readonly` method, then the associated objects will be read-only when retrieved via the association.

##### `select`

The `select` method lets you override the SQL `SELECT` clause that is used to retrieve data about the associated objects. By default, Rails retrieves all columns.

##### `uniq`

Use the `uniq` method to remove duplicates from the collection.

#### When are Objects Saved?

When you assign an object to a `has_and_belongs_to_many` association, that object is automatically saved (in order to update the join table). If you assign multiple objects in one statement, then they are all saved.

If any of these saves fails due to validation errors, then the assignment statement returns `false` and the assignment itself is cancelled.

If the parent object (the one declaring the `has_and_belongs_to_many` association) is unsaved (that is, `new_record?` returns `true`) then the child objects are not saved when they are added. All unsaved members of the association will automatically be saved when the parent is saved.

If you want to assign an object to a `has_and_belongs_to_many` association without saving the object, use the `collection.build` method.

### Association Callbacks

Normal callbacks hook into the life cycle of Active Record objects, allowing you to work with those objects at various points. For example, you can use a `:before_save` callback to cause something to happen just before an object is saved.

Association callbacks are similar to normal callbacks, but they are triggered by events in the life cycle of a collection. There are four available association callbacks:

* `before_add`
* `after_add`
* `before_remove`
* `after_remove`

You define association callbacks by adding options to the association declaration. For example:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders, before_add: :check_credit_limit

  def check_credit_limit(order)
    ...
  end
end
```

Rails passes the object being added or removed to the callback.

You can stack callbacks on a single event by passing them as an array:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders,
    before_add: [:check_credit_limit, :calculate_shipping_charges]

  def check_credit_limit(order)
    ...
  end

  def calculate_shipping_charges(order)
    ...
  end
end
```

If a `before_add` callback throws an exception, the object does not get added to the collection. Similarly, if a `before_remove` callback throws an exception, the object does not get removed from the collection.

### Association Extensions

You're not limited to the functionality that Rails automatically builds into association proxy objects. You can also extend these objects through anonymous modules, adding new finders, creators, or other methods. For example:

```ruby
class Customer < ActiveRecord::Base
  has_many :orders do
    def find_by_order_prefix(order_number)
      find_by(region_id: order_number[0..2])
    end
  end
end
```

If you have an extension that should be shared by many associations, you can use a named extension module. For example:

```ruby
module FindRecentExtension
  def find_recent
    where("created_at > ?", 5.days.ago)
  end
end

class Customer < ActiveRecord::Base
  has_many :orders, -> { extending FindRecentExtension }
end

class Supplier < ActiveRecord::Base
  has_many :deliveries, -> { extending FindRecentExtension }
end
```

Extensions can refer to the internals of the association proxy using these three attributes of the `proxy_association` accessor:

* `proxy_association.owner` returns the object that the association is a part of.
* `proxy_association.reflection` returns the reflection object that describes the association.
* `proxy_association.target` returns the associated object for `belongs_to` or `has_one`, or the collection of associated objects for `has_many` or `has_and_belongs_to_many`.
