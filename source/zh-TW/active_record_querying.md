Active Record 查詢
=============================

本篇詳細介紹各種用 Active Record 多種從資料庫取出資料的方法。

讀完本篇，您將學到：

* 如何使用各種方法與條件來取出資料庫記錄（record）。
* 如何排序、取出某幾個屬性、分組、其它用來找出資料庫記錄的特性。
* 如何使用 Eager load 來減少資料庫查詢的次數。
* 如何使用 Active Record 動態的 Finder 方法。
* 如何檢查特定的資料庫記錄是否存在。
* 如何在 Active Record Model 裡做各式計算。
* 如何對 Active Record Relation 使用 `EXPLAIN`。

--------------------------------------------------------------------------------

如果習慣寫純 SQL 來查詢資料庫，則會發現在 Rails 裡有更好的方式可以執行同樣的操作。Active Record 適用於大多數場景，需要寫 SQL 的場景會變得非常少。

本篇之後的例子都會用下列的 Model 來講解：

TIP: 除非特別說明，否則下列 Model 都用 `id` 作為主鍵。

```ruby
class Client < ActiveRecord::Base
  has_one  :address
  has_many :orders
  has_and_belongs_to_many :roles
end
```

```ruby
class Address < ActiveRecord::Base
  belongs_to :client
end
```

```ruby
class Order < ActiveRecord::Base
  belongs_to :client, counter_cache: true
end
```

```ruby
class Role < ActiveRecord::Base
  has_and_belongs_to_many :clients
end
```

Active Record 幫你對資料庫做查詢，相容多數資料庫（MySQL、PostgreSQL 以及 SQLite 等）。不管用的是何種資料庫，Active Record 方法格式保持一致。

取出資料
----------

Active Record 提供了多種 Finder 方法，用來從資料庫裡取出物件。每個 Finder 方法允許傳參數，來對資料庫執行不同的查詢，而無需直接寫純 SQL。

Finder 方法有：

* `bind`
* `create_with`
* `distinct`
* `eager_load`
* `extending`
* `from`
* `group`
* `having`
* `includes`
* `joins`
* `limit`
* `lock`
* `none`
* `offset`
* `order`
* `preload`
* `readonly`
* `references`
* `reorder`
* `reverse_order`
* `select`
* `uniq`
* `where`

以上方法皆會回傳一個 `ActiveRecord::Relation` 實例。

`Model.find(options)` 的主要操作可以總結如下：

* 將傳入的參數轉換成對應的 SQL 語句。
* 執行 SQL 語句，去資料庫取回對應的結果。
* 將每個查詢結果，根據適當的 Model 實例化出 Ruby 物件。
* 有 `after_find` 回呼的話，執行它們。

### 取出單一物件

Active Record 提供數種方式來取出一個物件。

#### 透過主鍵

使用 `Model.find(primary_key)` 來取出給定主鍵的物件，比如：

```ruby
# Find the client with primary key (id) 10.
client = Client.find(10)
# => #<Client id: 10, first_name: "Ryan">
```

對應的 SQL：

```sql
SELECT * FROM clients WHERE (clients.id = 10) LIMIT 1
```

如果 `Model.find(primary_key)` 沒找到符合條件的記錄，則會拋出 `ActiveRecord::RecordNotFound` 異常。

#### `take`

`Model.take` 從資料庫取出一筆記錄，不考慮順序，比如：

```ruby
client = Client.take
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients LIMIT 1
```

如果沒找到記錄，`Model.take` 會回傳 `nil`，不會拋出異常。

TIP: 取得的記錄根據使用的資料庫引擎會有不同結果。

#### `first`

`Model.first` 按主鍵排序，取出第一筆資料，比如：

```ruby
client = Client.first
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

如果沒找到記錄，`Model.first` 會回傳 `nil`，不會拋出異常。

#### `last`

`Model.last` 按主鍵排序，取出最後一筆資料，比如：

```ruby
client = Client.last
# => #<Client id: 221, first_name: "Russel">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

如果沒找到記錄，`Model.last` 會回傳 `nil`，不會拋出異常。

#### `find_by`

`Model.find_by` 找第一筆符合條件的記錄：

```ruby
Client.find_by first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by first_name: 'Jon'
# => nil
```

等同於：

```ruby
Client.where(first_name: 'Lifo').take
```

#### `take!`

`Model.take!` 從資料庫取出一筆記錄，不考慮任何順序，比如：

```ruby
client = Client.take!
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients LIMIT 1
```

如果沒找到記錄，`Model.take!` 會拋出 `ActiveRecord::RecordNotFound`。

#### `first!`

`Model.first!` 按主鍵排序，取出第一筆資料，比如：

```ruby
client = Client.first!
# => #<Client id: 1, first_name: "Lifo">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

如果沒找到記錄，`Model.first!` 會拋出 `ActiveRecord::RecordNotFound` 異常。

#### `last!`

`Model.last!` 按主鍵排序，取出最後一筆資料，比如：

```ruby
client = Client.last!
# => #<Client id: 221, first_name: "Russel">
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

如果沒找到記錄，`Model.last!` 會拋出 `ActiveRecord::RecordNotFound` 異常。

#### `find_by!`

`Model.find_by!` 找第一筆符合條件的紀錄。

```ruby
Client.find_by! first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by! first_name: 'Jon'
# => ActiveRecord::RecordNotFound
```

等同於：

```ruby
Client.where(first_name: 'Lifo').take!
```

如果沒找到符合條件的記錄，`Model.find_by!` 會拋出 `ActiveRecord::RecordNotFound` 異常。

### 取出多個物件

#### 使用多個主鍵

`Model.find(array_of_primary_key)` 接受以主鍵組成的陣列，並以陣列形式返回所有匹配的結果，比如：

```ruby
# Find the clients with primary keys 1 and 10.
client = Client.find([1, 10]) # Or even Client.find(1, 10)
# => [#<Client id: 1, first_name: "Lifo">, #<Client id: 10, first_name: "Ryan">]
```

對應的 SQL：

```sql
SELECT * FROM clients WHERE (clients.id IN (1,10))
```

WARNING: 只要有一個主鍵沒找到對應的紀錄，`Model.find(array_of_primary_key)` 會拋出 ActiveRecord::RecordNotFound` 異常。

#### `take`

`Model.take(limit)` 取出 `limit` 筆記錄，不考慮順序：

```ruby
Client.take(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

對應的 SQL：

```sql
SELECT * FROM clients LIMIT 2
```

#### `first`

`Model.first(limit)` 按主鍵排序，取出 `limit` 筆記錄：

```ruby
Client.first(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY id ASC LIMIT 2
```

#### `last`

`Model.last(limit)` 按主鍵排序，從後取出 `limit` 筆記錄：

```ruby
Client.last(2)
# => [#<Client id: 10, first_name: "Ryan">,
      #<Client id: 9, first_name: "John">]
```

對應的 SQL：

```sql
SELECT * FROM clients ORDER BY id DESC LIMIT 2
```

### 批次取出多筆記錄

處理多筆記錄是常見的需求，比如寄信給使用者，轉出資料。

直覺可能會這麼做：

```ruby
# 如果有數千個使用者，效率非常差。
User.all.each do |user|
  NewsLetter.weekly_deliver(user)
end
```

但在資料表很大的時候，這個方法便不實用了。由於 `User.all.each` 告訴 Active Record 一次去把整張表抓出來，再為表的每一列建出物件，最後將所有的物件放到記憶體裡。如果資料庫裡存了非常多筆記錄，可能會把記憶體用光。

Rails 提供了兩個方法來解決這個問題，將記錄針對記憶體來說有效率的大小，分批處理。第一個方法是 `find_each`，取出一批記錄，並將每筆記錄傳入至區塊裡，可取單一筆記錄。第二個方法是 `find_in_batches`，一次取一批記錄，整批放至區塊裡，整批記錄以陣列形式取用。

TIP: `find_each` 與 `find_in_batches` 方法專門用來解決大量記錄，處理無法一次放至記憶體的大量記錄。如果只是一千筆資料，使用平常的查詢方法便足夠了。

#### `find_each`

`find_each` 方法取出一批記錄，將每筆記錄傳入區塊裡。下面的例子，將以 `find_each` 來取出 1000 筆記錄（`find_each` 與 `find_in_batches` 的預設值），並傳至區塊。一次處理 1000 筆，直至記錄通通處理完畢為止：

```ruby
User.find_each do |user|
  NewsLetter.weekly_deliver(user)
end
```

##### `find_each` 選項

`find_each` 方法接受多數 `find` 所允許的選項，除了 `:order` 與 `:limit`，這兩個選項保留供 `find_each` 內部使用。

此外有兩個額外的選項，`:batch_size` 與 `:start`。

**`:batch_size`**

`:batch_size` 選項允許你在將各筆記錄傳進區塊前，指定一批要取多少筆記錄。比如一次取 5000 筆：

```ruby
User.find_each(batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

**`:start`**

預設記錄按主鍵升序取出，主鍵類型必須是整數。批次預設從最小的 ID 開始，可用 `:start` 選項可以設定批次的起始 ID。在前次被中斷的批量處理重新開始的場景下很有用。

舉例來說，本週總共有 5000 封信要發。1-1999 已經發過了，便可以使用此選項從 2000 開始發信：

```ruby
User.find_each(start: 2000, batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

另個例子是想要多個 worker 處理同個佇列時。可以使用 `:start` 讓每個 worker 分別處理 10000 筆記錄。

#### `find_in_batches`

`find_in_batches` 方法與 `find_each` 類似，皆用來取出記錄。差別在於 `find_in_batchs` 取出記錄放入陣列傳至區塊，而 `find_each` 是一筆一筆放入區塊。下例會一次將 1000 張發票拿到區塊裡處理：

```ruby
# Give add_invoices an array of 1000 invoices at a time
Invoice.find_in_batches(include: :invoice_lines) do |invoices|
  export.add_invoices(invoices)
end
```

NOTE: `:include` 選項可以指定需要跟 Model 一起載入的關聯。

##### `find_in_batches` 接受的選項

`find_in_batches` 方法接受和 `find_each` 一樣的選項： `:batch_size` 與 `:start`，以及多數 `find` 接受的參數，除了 `:order` 與 `:limit` 之外。

`find_in_batches` 方法接受和 `find_each` 一樣的選項： `:batch_size` 與 `:start`，以及多數 `find` 接受的參數，除了 `:order` 與 `:limit` 之外。這兩個選項保留供 `find_in_batches` 內部使用。

條件
----------

`where` 方法允許取出符合條件的記錄，`where` 即代表了 SQL 語句的 `WHERE` 部分。

條件可以是字串、陣列、或是 Hash。

### 字串條件

直接將要使用的條件，以字串形式傳入 `where` 即可。如 `Client.where("orders_count = '2'")` 會回傳所有 `orders_count` 是 2 的 clients。

WARNING: 條件是純字串可能有 SQL injection 的風險。舉例來說，`Client.where("first_name LIKE '%#{params[:first_name]}%'")` 是不安全的，參考下節如何將字串條件改用陣列來處理。

### 陣列條件

如果我們要找的 `orders_count`，不一定固定是 2，可能是不定的數字：

```ruby
Client.where("orders_count = ?", params[:orders])
```

Active Record 會將 `?` 換成 `params[:orders]` 做查詢。也可聲明多個條件，條件式後的元素，對應到條件裡的每個 `?`。

```ruby
Client.where("orders_count = ? AND locked = ?", params[:orders], false)
```

上例第一個 `?` 會換成 `params[:orders]`，第二個則會換成 SQL 裡的 `false` （根據不同的 adapter 而異）。

這麼寫

```ruby
Client.where("orders_count = ?", params[:orders])
```

比下面這種寫法好多了

```ruby
Client.where("orders_count = #{params[:orders]}")
```

因為前者比較安全。直接將變數插入條件字串裡，不論變數是什麼，都會直接存到資料庫裡。這表示從惡意使用者傳來的變數，會直接存到資料庫。這麼做是把資料庫放在風險裡不管啊！一旦有人知道，可以隨意將任何字串插入資料庫裡，就可以做任何想做的事。__絕對不要直接將變數插入條件字串裡。__

TIP: 關於更多 SQL injection 的資料，請參考 [Ruby on Rails 安全指南](edgeguides.rubyonrails.org/security.html#sql-injection)。

#### 佔位符

替換除了可以使用 `?` 之外，用符號也可以。以 Hash 的鍵值對方式，傳入陣列條件：

```ruby
Client.where("created_at >= :start_date AND created_at <= :end_date", {start_date: params[:start_date], end_date: params[:end_date]})
```

若條件中有許多參數，這種寫法不僅提高了可讀性，傳遞起來也更方便。

### Hash

Active Record 同時允許你傳入 Hash 形式的條件，以提高條件式的可讀性。使用 Hash 條件時，鍵是要查詢的欄位、值為期望值。

NOTE: 只有 Equality、Range、subset 可用這種形式來寫條件。

#### Equality

```ruby
Client.where(locked: true)
```

欄位名稱也可以是字串：

```ruby
Client.where('locked' => true)
```

`belongs_to` 關係裡，關聯名稱也可以用來做查詢，`polymorphic` 關係也可以。

```ruby
Address.where(client: client)
Address.joins(:clients).where(clients: {address: address})
```

Note: 條件的值不能用符號。比如這樣是不允許的 `Client.where(status: :active)`。

#### Range

```ruby
Client.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

會使用 SQL 的 `BETWEEN` 找出所有在昨天建立的客戶。

```sql
SELECT * FROM clients WHERE (clients.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

這種寫法展示了如何簡化[陣列條件](#)。

#### Subset

如果要使用 SQL 的 `IN` 來查詢，可以在條件 Hash 裡傳入陣列：

```ruby
Client.where(orders_count: [1,3,5])
```

上例會產生像是如下的 SQL：

```sql
SELECT * FROM clients WHERE (clients.orders_count IN (1,3,5))
```

### NOT

SQL 的 `NOT` 可以使用 `where.not`。

```ruby
Post.where.not(author: author)
```

換句話說，先不傳參數呼叫 `where`，再使用 `not` 傳入 `where` 條件。

排序
--------

要按照特定順序來取出記錄，可以使用 `order` 方法。

比如有一組記錄，想要按照 `created_at` 升序排列：

```ruby
Client.order(:created_at)
# OR
Client.order("created_at")
```

升序 `ASC`；降序 `DESC`：

```ruby
Client.order(created_at: :desc)
# OR
Client.order(created_at: :asc)
# OR
Client.order("created_at DESC")
# OR
Client.order("created_at ASC")
```

排序多個欄位：

```ruby
Client.order(orders_count: :asc, created_at: :desc)
# OR
Client.order(:orders_count, created_at: :desc)
# OR
Client.order("orders_count ASC, created_at DESC")
# OR
Client.order("orders_count ASC", "created_at DESC")
```

如果想在不同的語境裡連鎖使用 `order`，SQL 的 ORDER BY 順序與呼叫順序相同：

```ruby
Client.order("orders_count ASC").order("created_at DESC")
# SELECT * FROM clients ORDER BY orders_count ASC, created_at DESC
```

選出特定欄位
-------------------------

`Model.find` 預設會使用 `select *` 取出所有的欄位。

只要取某些欄位的話，可以透過 `select` 方法來聲明。

比如，只要 `viewable_by` 與 `locked` 欄位：

```ruby
Client.select("viewable_by, locked")
```

會產生出像是下面的 SQL 語句：

```sql
SELECT viewable_by, locked FROM clients
```

要小心使用 `select`。因為實例化出來的物件僅有所選欄位。如果試圖存取不存在的欄位，會得到 `ActiveModel::MissingAttributeError` 異常：

```bash
ActiveModel::MissingAttributeError: missing attribute: <attribute>
```

上面的 `<attribute>` 會是試圖存取的欄位。`id` 方法不會拋出 `ActiveModel::MissingAttributeError`，所以在關聯裡使用要格外注意，因為關聯要有 `id` 才能正常工作。

如果想找出特定欄位所有不同的數值，使用 `distinct`：

```ruby
Client.select(:name).distinct
```

會產生如下 SQL：

```sql
SELECT DISTINCT name FROM clients
```

也可以之後移掉唯一性的限制：

```ruby
query = Client.select(:name).distinct
# => Returns unique names

query.distinct(false)
# => Returns all names, even if there are duplicates
```

Limit 與 Offset
----------------

要在 `Model.find` 裡使用 SQL 的 `LIMIT`，可以對 Active Record Relation 使用 `limit` 與 `offset` 方法 可以指定從第幾個記錄開始查詢。比如：

```ruby
Client.limit(5)
```

最多會回傳 5 位客戶。因為沒指定 `offset`，會回傳資料比如的前 5 筆。產生的 SQL 會像是：

```sql
SELECT * FROM clients LIMIT 5
```

上例加上 `offset`：

```ruby
Client.limit(5).offset(30)
```

會從資料庫裡的第 31 筆開始，最多回傳 5 位客戶的紀錄，產生的 SQL 像是：

```sql
SELECT * FROM clients LIMIT 5 OFFSET 30
```

Group
----------


要在 `Model.find` 裡使用 SQL 的 `LIMIT`，可以對 Active Record Relation 使用 `group` 方法。

比如想找出某日的訂單：

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").group("date(created_at)")
```

會依照存在資料庫裡的順序，按日期回傳單筆訂單物件。

產生的 SQL 會像是：

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
```

Having
------

在 SQL 裡，可以使用 `HAVING` 子句來對 `GROUP BY` 欄位下條件。`Model.find` 加入 `:having` 選項。

比如：

```ruby
Order.select("date(created_at) as ordered_date, sum(price) as total_price").
  group("date(created_at)").having("sum(price) > ?", 100)
```

產生的 SQL 會像是：

```sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
HAVING sum(price) > 100
```

這會回傳每天總價大於 `100` 的訂單。

覆蓋條件
---------------------

### `except`

用 `except` 來去掉特定條件，如：

```ruby
Post.where('id > 10').limit(20).order('id asc').except(:order)
```

執行的 SQL 語句：

```sql
SELECT * FROM posts WHERE id > 10 LIMIT 20

# Original query without `except`
SELECT * FROM posts WHERE id > 10 ORDER BY id asc LIMIT 20

```

### `unscope`

`except` 在 Relation 合併時無效，比如：

```ruby
Post.comments.except(:order)
```

如果 `.order(...)` 從預設 scope 而來，則不會消去。為了要移掉所有 `.order(...)`，使用 `unscope`：

```ruby
Post.order('id DESC').limit(20).unscope(:order) = Post.limit(20)
Post.order('id DESC').limit(20).unscope(:order, :limit) = Post.all
```

`unscope` 特定的 `where` 子句也可以：

```ruby
Post.where(id: 10).limit(1).unscope({ where: :id }, :limit).order('id DESC') = Post.order('id DESC')
```

### `only`

`only` 可以留下特定條件，比如：

```ruby
Post.where('id > 10').limit(20).order('id desc').only(:order, :where)
```

執行的 SQL 語句：

```sql
SELECT * FROM posts WHERE id > 10 ORDER BY id DESC

# Original query without `only`
SELECT "posts".* FROM "posts" WHERE (id > 10) ORDER BY id desc LIMIT 20

```

### `reorder`

`reorder` 可以覆蓋掉預設 scope 的 `order` 條件：

```ruby
class Post < ActiveRecord::Base
  ..
  ..
  has_many :comments, -> { order('posted_at DESC') }
end

Post.find(10).comments.reorder('name')
```

執行的 SQL 語句：

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY name
```

原本會執行的 SQL 語句（沒用 `reorder`）：

```sql
SELECT * FROM posts WHERE id = 10 ORDER BY posted_at DESC
```

### `reverse_order`

`reverse_order` 方法反轉 `order` 條件。

```ruby
Client.where("orders_count > 10").order(:name).reverse_order
```

執行的 SQL 語句（`ASC` 反轉為 `DESC`）：

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY name DESC
```

如果查詢裡沒有 `order` 條件，預設 `reverse_order` 會對主鍵做反轉。

```ruby
Client.where("orders_count > 10").reverse_order
```

執行的 SQL 語句：

```sql
SELECT * FROM clients WHERE orders_count > 10 ORDER BY clients.id DESC
```

`reverse_order` **不接受參數**。

空 Relation
-------------

`none` 方法回傳一個不包含任何記錄、可連鎖使用的 Relation。`none` 回傳的 Relation 上做查詢，仍會回傳空的 Relation。應用場景是回傳的 Relation 可能沒有記錄，但需要可以連鎖使用。

```ruby
Post.none # returns an empty Relation and fires no queries.
```

回傳空的 Relation，不會對資料庫下查詢。

```ruby
# The visible_posts method below is expected to return a Relation.
@posts = current_user.visible_posts.where(name: params[:name])

def visible_posts
  case role
  when 'Country Manager'
    Post.where(country: country)
  when 'Reviewer'
    Post.published
  when 'Bad User'
    Post.none # => returning [] or nil breaks the caller code in this case
  end
end
```

上例 `visible_posts` 可能沒有可見的 `posts`，但之後還有 `where` 子句，此時沒有 `posts` 的情況可以使用 `Post.none`。


唯讀物件
----------------

Active Record 提供 `readonly` 方法，用來禁止修改回傳的物件。試圖要修改 `readonly` 物件徒勞無功，並會拋出 `ActiveRecord::ReadOnlyRecord` 異常。

```ruby
client = Client.readonly.first
client.visits += 1
client.save
```

`client` 明確設定為唯讀物件，上面的程式碼在執行到 `client.save` 時會拋出 `ActiveRecord::ReadOnlyRecord` 異常，因為 `visits` 的數值改變了。

更新時鎖定記錄
--------------------------

鎖定可以避免更新可能發生的 race condition，確保更新是原子性的操作。


Active Record 提供兩種鎖定機制：

* 樂觀鎖定（Optimistic Locking）
* 悲觀鎖定（Pessimistic Locking）

### 樂觀鎖定

樂觀鎖定允許多個使用者編輯相同的紀錄，並假設資料衝突發生衝突的可能性最小。透過檢查該記錄從資料庫取出後，是否有另個進程修改此記錄。如果有其他進程同時修改記錄時，會拋出 `ActiveRecord::StaleObjectError` 異常。

**樂觀鎖定欄位**

要使用樂觀鎖定，資料表需要加一個叫做 `lock_version` 的整數欄位。記錄更新時，Active Record 會遞增 `lock_version`。如果正在更新的記錄的 `lock_version` 比資料庫裡的 `lock_version` 值小時，會拋出 `ActiveRecord::StaleObjectError`，比如：

```ruby
c1 = Client.find(1)
c2 = Client.find(1)

c1.first_name = "Michael"
c1.save

c2.name = "should fail"
c2.save # Raises an ActiveRecord::StaleObjectError
```

拋出異常後您要負責處理，將異常救回來。看是要回滾、合併或是根據商業邏輯來處理衝突。

這個行為可以透過設定 `ActiveRecord::Base.lock_optimistically = false` 來關掉。

`lock_version` 欄位名可以透過 `ActiveRecord::Base` 提供的類別屬性 `locking_column` 來覆蓋：

```ruby
class Client < ActiveRecord::Base
  self.locking_column = :lock_client_column
end
```

### 悲觀鎖定

悲觀鎖定使用資料庫提供的鎖定機制。在建立 Relation 時，使用 `lock` 可以對選擇的列獲得一個互斥鎖。通常使用 `lock` 的 Relation 會包在 transaction 裡，避免死鎖的情況發生。

比如：

```ruby
Item.transaction do
  i = Item.lock.first
  i.name = 'Jones'
  i.save
end
```

上面的程式碼在 MySQL 會產生如下 SQL：

```sql
SQL (0.2ms)   BEGIN
Item Load (0.3ms)   SELECT * FROM `items` LIMIT 1 FOR UPDATE
Item Update (0.4ms)   UPDATE `items` SET `updated_at` = '2009-02-07 18:05:56', `name` = 'Jones' WHERE `id` = 1
SQL (0.8ms)   COMMIT
```

`lock` 方法可以傳純 SQL，來使用不同種類的鎖。比如 MySQL 有 `LOCK IN SHARE MODE`，鎖定記錄同時允許查詢讀取。直接傳入 `lock` 即可使用：

```ruby
Item.transaction do
  i = Item.lock("LOCK IN SHARE MODE").find(1)
  i.increment!(:views)
end
```

如果已經有 Model 的實例，使用以下寫法，可以將操作包在 transaction 裡，並同時獲得鎖：

```ruby
item = Item.first
item.with_lock do
  # This block is called within a transaction,
  # item is already locked.
  item.increment!(:views)
end
```

連接資料表
--------------

Active Record 提供一個 Finder 方法，`joins`。用來對 SQL 指定 `JOIN` 子句。`joins` 有多種使用方式。

### 使用字串形式的 SQL 片段

在 `joins` 裡寫純 SQL 來指定 `JOIN`：

```ruby
Client.joins('LEFT OUTER JOIN addresses ON addresses.client_id = clients.id')
```

會產生下面的 SQL：

```sql
SELECT clients.* FROM clients LEFT OUTER JOIN addresses ON addresses.client_id = clients.id
```

### 使用關聯名稱的陣列或 Hash 形式

WARNING: 此法僅對 `INNER JOIN` 有效。

Active Record 允許在使用 `joins` 方法時，使用關聯名稱來指定 `JOIN` 子句。

舉個例子，以下有 `Category`、`Post`、`Comment`、`Guest` 以及 `Tag` Models：

```ruby
class Category < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :category
  has_many :comments
  has_many :tags
end

class Comment < ActiveRecord::Base
  belongs_to :post
  has_one :guest
end

class Guest < ActiveRecord::Base
  belongs_to :comment
end

class Tag < ActiveRecord::Base
  belongs_to :post
end
```

接下來，以下的方法都會使用 `INNER JOIN` 來產生出連接查詢（join queries）：

#### 連接單個關聯

```ruby
Category.joins(:posts)
```

會產生：

```sql
SELECT categories.* FROM categories
  INNER JOIN posts ON posts.category_id = categories.id
```

用白話解釋是：“依文章分類來回傳分類物件”。注意到如果有 `post` 是相同類別，會看到重複的分類物件。若要去掉重複結果，可以使用 `Category.joins(:posts).uniq`。

#### 連接多個關聯

```ruby
Post.joins(:category, :comments)
```

會產生：

```sql
SELECT posts.* FROM posts
  INNER JOIN categories ON posts.category_id = categories.id
  INNER JOIN comments ON comments.post_id = posts.id
```

用白話解釋是：“依分類來回傳文章物件，且文章至少有一則評論”。有多則評論的文章將會出現很多次。

#### 連接一層巢狀關聯

```ruby
Post.joins(comments: :guest)
```

會產生：

```sql
SELECT posts.* FROM posts
  INNER JOIN comments ON comments.post_id = posts.id
  INNER JOIN guests ON guests.comment_id = comments.id
```

用白話解釋是：“回傳所有有訪客評論的文章”。

#### 連接多層巢狀關聯

```ruby
Category.joins(posts: [{comments: :guest}, :tags])
```

會產生：

```sql
SELECT categories.* FROM categories
  INNER JOIN posts ON posts.category_id = categories.id
  INNER JOIN comments ON comments.post_id = posts.id
  INNER JOIN guests ON guests.comment_id = comments.id
  INNER JOIN tags ON tags.post_id = posts.id
```

### 對連接的資料表指定條件

可以對連接的資料表使用一般的[陣列](#)與[字串](#)條件。[Hash]條件則是有提供特殊的語法來下條件：

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where('orders.created_at' => time_range)
```

另一種更簡潔的寫法是使用巢狀 Hash：

```ruby
time_range = (Time.now.midnight - 1.day)..Time.now.midnight
Client.joins(:orders).where(orders: {created_at: time_range})
```

會用 `BETWEEN` 找到所有昨天下訂單的客戶。

Eager Loading 關聯
--------------------------


Eager loading 是載入由 `Model.find` 回傳的物件關聯記錄的機制，將查詢數降到最低。

**N + 1 查詢問題**

考慮以下程式碼。找出 10 個客戶，並印出郵遞區號：

```ruby
clients = Client.limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

程式碼一眼看起來沒什麼問題。但問題是總共執行了幾次查詢。上例程式碼總共會執行 **11** 次查詢，1 次用來取得 10 位客戶、10 次用來取得客戶地址的郵遞區號。

**N + 1 查詢的解法**

Active Record 可預先指定所有會載入的關聯。透過使用 `Model.find` 搭配 `includes` 方法。有了 `includes`，Active Record 確保所有指定的關聯用最少次的查詢來加載。

用 Eager Loading 重寫上例：

```ruby
clients = Client.includes(:address).limit(10)

clients.each do |client|
  puts client.address.postcode
end
```

上面的程式碼只會執行 **2** 次查詢。

```sql
SELECT * FROM clients LIMIT 10
SELECT addresses.* FROM addresses
  WHERE (addresses.client_id IN (1,2,3,4,5,6,7,8,9,10))
```

### Eager Loading 多個關聯

使用 `Model.find` 與 `includes` 方法，Active Record 可以 Eager Load 任意數量的關聯。關聯可以以陣列、Hash 或是巢狀 Hash（內有陣列、Hash）形式指定。

#### 陣列有多個關聯

```ruby
Post.includes(:category, :comments)
```

會加載所有文章，以及每篇文章的類別與評論。

#### 巢狀關聯 Hash

```ruby
Category.includes(posts: [{comments: :guest}, :tags]).find(1)
```

會找到 `category` `id` 為 1 的類別，並加載與類別相關聯的文章。以及文章的標籤與評論跟評論的 `guest` 關聯。

### 對 Eager Loaded 關聯下條件

雖然 Active Record 允許您像 `joins` 那樣對 eager loaded 關聯下條件，但推薦的做法是使用[連接資料表](#)。

但若非要這麼做，可以像平常那樣使用 `where`：

```ruby
Post.includes(:comments).where("comments.visible" => true)
```

產生的查詢語句會有 `LEFT OUTER JOIN`，而 `joins` 產生的是 `INNER JOIN`。

```ruby
SELECT "posts"."id" AS t0_r0, ... "comments"."updated_at" AS t1_r5 FROM "posts" LEFT OUTER JOIN "comments" ON "comments"."post_id" = "posts"."id" WHERE (comments.visible = 1)
```

如果沒有下 `where` 條件，則會像平常那樣產生兩條查詢。

上例若文章都沒有評論，仍會載入所有文章。然而使用 `joins` （`INNER JOIN`）**必須**要滿足連接條件，不然不會回傳任何記錄。

作用域
------

作用域（Scopes）允許將常用查詢定義成關聯物件或 Model 的方法。作用域可以使用前面介紹過的 `where`、`joins`、`includes` 等方法。所有作用域方法會回傳一個 `ActiveRecord::Relation` 物件，允許之後的方法（像是作用域）來繼續呼叫。

要定義一個簡單的作用域，在類別裡使用 `scope` 方法，傳入呼叫此作用域時想執行的查詢即可：

```ruby
class Post < ActiveRecord::Base
  scope :published, -> { where(published: true) }
end
```

這與定義一個類別方法完全相同，用那個完全是個人喜好：

```ruby
class Post < ActiveRecord::Base
  def self.published
    where(published: true)
  end
end
```

作用域可以與其它作用域連鎖使用：

```ruby
class Post < ActiveRecord::Base
  scope :published,               -> { where(published: true) }
  scope :published_and_commented, -> { published.where("comments_count > 0") }
end
```

要呼叫 `published` 作用域，可以在類上呼叫：

```ruby
Post.published # => [published posts]
```

或是對由 `Post` 物件組成的關聯使用：

```ruby
category = Category.first
category.posts.published # => [published posts belonging to this category]
```

### 傳入參數

作用域可接受參數：

```ruby
class Post < ActiveRecord::Base
  scope :created_before, ->(time) { where("created_at < ?", time) }
end
```

像呼叫類別方法那般使用作用域

```ruby
Post.created_before(Time.zone.now)
```

這只是重複類別方法可提供的功能。

```ruby
class Post < ActiveRecord::Base
  def self.created_before(time)
    where("created_at < ?", time)
  end
end
```

作用域需要接受參數偏好使用類別方法。接受參數的類別方法仍可在關聯物件上使用：

```ruby
category.posts.created_before(time)
```

### 合併作用域

和 `where` 條件類似，作用域使用 SQL 的 `AND` 來合併。

```ruby
class User < ActiveRecord::Base
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.active.inactive
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'inactive'
```

`scope` 作用域與 `where` 條件可以混用，最終的 SQL 會用 `AND` 把所有條件連結起來。

```ruby
User.active.where(state: 'finished')
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'active' AND "users"."state" = 'finished'
```

如果想讓最後一個 `where` 條件覆蓋先前的，可以使用 `Relation#merge`。

```ruby
User.active.merge(User.inactive)
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

一個重要的提醒是 `default_scope` 會被 `scope` 作用域與 `where` 條件覆蓋掉。

```ruby
class User < ActiveRecord::Base
  default_scope { where state: 'pending' }
  scope :active, -> { where state: 'active' }
  scope :inactive, -> { where state: 'inactive' }
end

User.all
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'pending'

User.active
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'active'

User.where(state: 'inactive')
# => SELECT "users".* FROM "users" WHERE "users"."state" = 'inactive'
```

如上所見，`default_scope` 被 `scope` 與 `where` 覆蓋掉了。

### 使用預設作用域

若想要所有的查詢皆使用某個預設的作用域，可以使用 `default_scope`。

```ruby
class Client < ActiveRecord::Base
  default_scope { where("removed_at IS NULL") }
end
```

當這個 Model 執行查詢時，執行的 SQL 會像是：

```sql
SELECT * FROM clients WHERE removed_at IS NULL
```

如果預設作用域需要做更複雜的事，可以用類別方法來取代：

```ruby
class Client < ActiveRecord::Base
  def self.default_scope
    # Should return an ActiveRecord::Relation.
  end
end
```

### 移除所有作用域

如果想移除作用域，可以使用 `unscoped` 方法。這在特定查詢不需要使用 `default_scope` 時特別有用。

```ruby
Client.unscoped.load
```

`unscoped` 會移除所有的作用域，回到原本正常的資料表查詢。

注意把 `unscoped` 與 `scope` 連起來用是無效的。這種情況下推薦使用 `unscoped` 的區塊形式：

```ruby
Client.unscoped {
  Client.created_before(Time.zone.now)
}
```

動態查詢方法
------------------

NOTE: Rails 4.0 已棄用動態查詢方法，並在 4.1 移除這些方法。最佳實踐是使用 Active Record 的 scope 來取代。可以在 [activerecord-deprecated_finders](https://github.com/rails/activerecord-deprecated_finders。
) Gem 找到這些棄用的方法。

每個資料表裡定義的欄位（又稱屬性），Active Record 都提供一個 Finder 方法。假設 `Client` Model 有 `first_name`，則 Active Record 便會有 `find_by_first_name` 方法可用。若 `Client` Model 有 `locked`，則 Active Record 便會有 `find_by_locked` 方法可用。

在動態查詢方法名稱最後加上驚嘆號（`!`），可以獲得對應的 BANG 版本，即未找到符合的記錄時，會拋出 `ActiveRecord::RecordNotFound` 異常，像是 `Client.find_by_name!("Ryan")`。

如果同時想找多個欄位，可以在方法名中間使用 `and` 連起來，比如：`Client.find_by_first_name_and_locked("Ryan", true)`。

尋找或新建物件
--------------------------

在找不到記錄情況，新建一個物件是很常見的需求。可以透過 `find_or_create_by`、`find_or_create_by!` 來實作。

### `find_or_create_by`

`find_or_create_by` 方法檢查指定屬性的記錄是否存在。不存在便呼叫 `create`，看個例子。

假設想找到名稱是 `'Andy'` 的客戶，沒找到便新建。可以這麼做：

```ruby
Client.find_or_create_by(first_name: 'Andy')
# => #<Client id: 1, first_name: "Andy", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">
```

這個方法產生的 SQL 看起來像是：

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Andy') LIMIT 1
BEGIN
INSERT INTO clients (created_at, first_name, locked, orders_count, updated_at) VALUES ('2011-08-30 05:22:57', 'Andy', 1, NULL, '2011-08-30 05:22:57')
COMMIT
```

`find_or_create_by` 會回傳已存在的紀錄，或是新建一筆記錄。在上面的例子裡，沒有找到 Andy 這個客戶，便新建一筆再回傳。

新記錄可能沒有存至資料庫；這取決於驗證是否通過（就像 `create` 一樣）。

假設我們想新建客戶時把 `locked` 屬性設為 `false`，但不想要包含在查詢裡。也就是沒找到叫 Andy 的客戶時，新建一位未鎖定的 Andy 客戶。有兩種方法可以做到，第一種是使用 `create_with`：

```ruby
Client.create_with(locked: false).find_or_create_by(first_name: 'Andy')
```

第二種是使用區塊：

```ruby
Client.find_or_create_by(first_name: 'Andy') do |c|
  c.locked = false
end
```

區塊只在新建客戶時執行，已有客戶便會忽略掉區塊。

### `find_or_create_by!`

也可以使用 `find_or_create_by!` 在建立的新紀錄為無效記錄時拋出異常。本文未涵蓋有關驗證的內容，但假設你不小心把這行加到了 `Client` Model：

```ruby
validates :orders_count, presence: true
```

若沒有傳入 `orders_count` 而要建立新客戶時，則會拋出 `ActiveRecord::RecordInvalid` 異常：

```ruby
Client.find_or_create_by!(first_name: 'Andy')
# => ActiveRecord::RecordInvalid: Validation failed: Orders count can't be blank
```

### `find_or_initialize_by`

`find_or_initialize_by` 方法的工作原理與 `find_or_create_by` 相同，但沒找到時會用 `new` 而不是 `create`。這表示新紀錄會放在記憶體，不會存到資料庫。沿用 `find_or_create_by` 例子 ，假設我們現在想找叫做 Nick 的客戶：

```ruby
nick = Client.find_or_initialize_by(first_name: 'Nick')
# => <Client id: nil, first_name: "Nick", orders_count: 0, locked: true, created_at: "2011-08-30 06:09:27", updated_at: "2011-08-30 06:09:27">

nick.persisted?
# => false

nick.new_record?
# => true
```

由於這個物件還沒存到資料庫，產生出來的 SQL 像是：

```sql
SELECT * FROM clients WHERE (clients.first_name = 'Nick') LIMIT 1
```

當想存到資料庫時，呼叫 `save` 即可：

```ruby
nick.save
# => true
```

用 SQL 查詢
--------------

如果想用 SQL 在資料表裡找記錄可以使用：`find_by_sql`。`find_by_sql` 方法會將查詢到的物件放在陣列裡回傳，即便只有一條記錄符合。比如可以執行以下查詢：

```ruby
Client.find_by_sql("SELECT * FROM clients
  INNER JOIN orders ON clients.id = orders.client_id
  ORDER clients.created_at desc")
```

`find_by_sql` 提供自定查詢的簡單方式，並會將取出的物件實例化。

### `select_all`

`find_by_sql` 有個類似的方法：`connection#select_all`。 `select_all` 會使用自定的 SQL 語句從資料庫取出物件，但不會實例化物件。會回傳一個 `ActiveRecord::Result` 物件，可以使用 `to_ary` 或 `to_hash` 將 `ActiveRecord::Result` 轉成陣列，每筆記錄皆是陣列裡的一個 Hash。

```ruby
Client.connection.select_all("SELECT * FROM clients WHERE id = '1'")
```

### `pluck`

`pluck` 可以用來查詢資料表的一個或多個欄位。接受欄位名稱作為參數，並回傳由指定欄位值所組成的陣列。

```ruby
Client.where(active: true).pluck(:id)
# SELECT id FROM clients WHERE active = 1
# => [1, 2, 3]

Client.distinct.pluck(:role)
# SELECT DISTINCT role FROM clients
# => ['admin', 'member', 'guest']

Client.pluck(:id, :name)
# SELECT clients.id, clients.name FROM clients
# => [[1, 'David'], [2, 'Jeremy'], [3, 'Jose']]
```

以下程式碼：

```ruby
Client.select(:id).map { |c| c.id }
# or
Client.select(:id).map(&:id)
# or
Client.select(:id, :name).map { |c| [c.id, c.name] }
```

可以用 `pluck` 取代：

```ruby
Client.pluck(:id)
# or
Client.pluck(:id, :name)
```

與 `select` 不同，`pluck` 直接將從資料庫查詢的結果，轉成 Ruby 的 `Array`，而沒有建出 `ActiveRecord` 物件。可大幅提昇常用、大量查詢的執行效能。但任何 Model 可用的方法便無法使用了，如：

```ruby
class Client < ActiveRecord::Base
  def name
    "I am #{super}"
  end
end

Client.select(:name).map &:name
# => ["I am David", "I am Jeremy", "I am Jose"]

Client.pluck(:name)
# => ["David", "Jeremy", "Jose"]
```

此外，`pluck` 不像 `select` 與其他 `Relation` 作用域，`pluck` 會直接觸發查詢，無法供之後的作用域連鎖使用，但可以與已經建立的作用域連鎖使用：

```ruby
Client.pluck(:name).limit(1)
# => NoMethodError: undefined method `limit' for #<Array:0x007ff34d3ad6d8>

Client.limit(1).pluck(:name)
# => ["David"]
```

### `ids`

`ids` 可以用來 `pluck` 所有 ID（取得資料表所有的主鍵）：

```ruby
Person.ids
# SELECT id FROM people
```

```ruby
class Person < ActiveRecord::Base
  self.primary_key = "person_id"
end

Person.ids
# SELECT person_id FROM people
```

物件存在性
--------------------

想檢查物件是否存在，可以使用 `exists?`。`exists` 會使用與 `find` 相同的 SQL 語句查詢資料庫，但不會回傳物件集合，而是回傳 `true` 或 `false`。

```ruby
Client.exists?(1)
```

`exists` 方法可接受多個數值，但只要有一個記錄存在，便會回傳 `true`。

```ruby
Client.exists?(id: [1,2,3])
# or
Client.exists?(name: ['John', 'Sergei'])
```

`exists?` 不傳任何參數也可以。

```ruby
Client.where(first_name: 'Ryan').exists?
```

如果至少有一位客戶名稱是 `'Ryan'` 則回傳 `true`，否則回傳 `false`。

```ruby
Client.exists?
```

`clients` 資料表為空時回傳 `false`，反之 `true`。

`any?` 與 `many?` 也可以用來檢查 Model 或 Relation 的存在性。

```ruby
# via a model
Post.any?
Post.many?

# via a named scope
Post.recent.any?
Post.recent.many?

# via a relation
Post.where(published: true).any?
Post.where(published: true).many?

# via an association
Post.first.categories.any?
Post.first.categories.many?
```

計算
------------

本節以 `count` 為例，`count` 適用的選項所有子章節亦適用。

所有計算方法都可直接在 Model 上呼叫：

```ruby
Client.count
# SELECT count(*) AS count_all FROM clients
```

或在 Active Record Relation 呼叫：

```ruby
Client.where(first_name: 'Ryan').count
# SELECT count(*) AS count_all FROM clients WHERE (first_name = 'Ryan')
```

也可以對 Active Record Relation 使用不同的查詢方法，來做複雜的計算：

```ruby
Client.includes("orders").where(first_name: 'Ryan', orders: {status: 'received'}).count
```

會執行下面的 SQL：

```sql
SELECT count(DISTINCT clients.id) AS count_all FROM clients
  LEFT OUTER JOIN orders ON orders.client_id = client.id WHERE
  (clients.first_name = 'Ryan' AND orders.status = 'received')
```

### 計數

想知道 Model 資料表裡有多少筆記錄，呼叫 `Client.count` 即可。也可以查詢特定欄位有幾筆記錄：`Client.count(:age)`。

可用選項請參考[計算](#計算)一節。

### 平均

如果想找出資料表特定欄位的平均值，使用 `average` 方法：

```ruby
Client.average("orders_count")
Client.average(:orders_count)
```

會回傳指定欄位的平均值，可能是浮點數（比如 3.14159265）。

可用選項請參考[計算](#計算)一節。

### 最小值

如果想找出資料表特定欄位的最小值，使用 `min` 方法：

```ruby
Client.minimum("age")
Client.minimum(:age)
```

可用選項請參考[計算](#計算)一節。

### 最大值

如果想找出資料表特定欄位的最大值，使用 `max` 方法：

```ruby
Client.maximum("age")
Client.maximum(:age)
```

可用選項請參考[計算](#計算)一節。

### 和

如果想找出資料表裡某欄位所有記錄的和，使用 `sum` 方法：

```ruby
Client.sum("orders_count")
Client.sum(:orders_count)
```

可用選項請參考[計算](#計算)一節。

執行 EXPLAIN
---------------

可以對 Active Record Relation 使用 `explain`，比如：

```ruby
User.where(id: 1).joins(:posts).explain
```

可能輸出如下（MySQL）：

```
EXPLAIN for: SELECT `users`.* FROM `users` INNER JOIN `posts` ON `posts`.`user_id` = `users`.`id` WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
| id | select_type | table | type  | possible_keys | key     | key_len | ref   | rows | Extra       |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
|  1 | SIMPLE      | users | const | PRIMARY       | PRIMARY | 4       | const |    1 |             |
|  1 | SIMPLE      | posts | ALL   | NULL          | NULL    | NULL    | NULL  |    1 | Using where |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------------+
2 rows in set (0.00 sec)
```

Active Record 會根據使用的資料庫不同，按照資料庫 Shell 的方式印出。在 PostgreSQL 可能會輸出：

```
EXPLAIN for: SELECT "users".* FROM "users" INNER JOIN "posts" ON "posts"."user_id" = "users"."id" WHERE "users"."id" = 1
                                  QUERY PLAN
------------------------------------------------------------------------------
 Nested Loop Left Join  (cost=0.00..37.24 rows=8 width=0)
   Join Filter: (posts.user_id = users.id)
   ->  Index Scan using users_pkey on users  (cost=0.00..8.27 rows=1 width=4)
         Index Cond: (id = 1)
   ->  Seq Scan on posts  (cost=0.00..28.88 rows=8 width=4)
         Filter: (posts.user_id = 1)
(6 rows)
```

Eager loading 可能會觸發多條查詢，某些查詢依賴先前查詢的結果。由於這個原因，`explain` 會實際執行該查詢，並詢問要查詢那一個，比如：

```ruby
User.where(id: 1).includes(:posts).explain
```

會輸出（MySQL）：

```
EXPLAIN for: SELECT `users`.* FROM `users`  WHERE `users`.`id` = 1
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
| id | select_type | table | type  | possible_keys | key     | key_len | ref   | rows | Extra |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
|  1 | SIMPLE      | users | const | PRIMARY       | PRIMARY | 4       | const |    1 |       |
+----+-------------+-------+-------+---------------+---------+---------+-------+------+-------+
1 row in set (0.00 sec)

EXPLAIN for: SELECT `posts`.* FROM `posts`  WHERE `posts`.`user_id` IN (1)
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
|  1 | SIMPLE      | posts | ALL  | NULL          | NULL | NULL    | NULL |    1 | Using where |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
1 row in set (0.00 sec)
```

### 解讀 EXPLAIN

解讀 EXPLAIN 的輸出超出本指南的範疇。下面列出幾篇可能有用的文章：

* SQLite3: [EXPLAIN QUERY PLAN](http://www.sqlite.org/eqp.html)

* MySQL: [EXPLAIN Output Format](http://dev.mysql.com/doc/refman/5.6/en/explain-output.html)

* PostgreSQL: [Using EXPLAIN](http://www.postgresql.org/docs/current/static/using-explain.html)
