Active Record 遷移
========================

Migration，遷移。Active Record 眾多功能之一，可與時俱進的[管理資料庫綱要](http://en.wikipedia.org/wiki/Schema_migration)。最棒的是 Migration 提供了簡潔的 Ruby DSL，無需寫純 SQL，便能變更資料表。

讀完本篇，您將了解：

* 使用產生遷移的產生器。
* Active Record 提供用來操作資料庫的方法。
* 撰寫 Rake 任務來管理資料庫的 schema 與遷移檔案。
* 遷移與 schema.rb 的關係。

綜覽
--------------------

遷移是一種簡單、一致、方便[與時俱進管理資料庫綱要]()的方法。遷移使用 Ruby DSL，而不用手寫 SQL，適用於所有資料庫。

每筆遷移都可想成是資料庫的新版本。資料庫綱要一開始什麼也沒有，每筆遷移慢慢得往資料庫裡增刪資料表、欄位、記錄等。Active Record 知道如何依時間順序更新資料庫綱要，從資料庫歷史的何處開始都可以，都能前往最新版本。此外，Active Record 也會更新 `db/schema.rb` 檔案，與最新的資料庫結構保持同步。

來看個範例 Migration：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

`create_table :products do |t|` 新增了一張 `products` 的資料表，有 `name` （類型是字串）、`description`（類型是 text）的欄位。也會自動新增主鍵（`id`）（遷移裡看不到），所有 Active Record Model 的預設主鍵名稱都叫做 `id`。`timestamps` 宏新稱了兩個欄位， `created_at` 與 `updated_at`，Active Record 會負責處理特殊欄位（主鍵、時間戳章），無需自己處理。


Migration 是前進下一關，那回到上一關叫做什麼？ __Rollback，回滾。__

當我們回滾剛剛的 Migration，Active Record 會自動幫你移除這個 table。有些資料庫支援 transaction （事務），改變 Schema 的 Migration 會包在事務裡
。不支援事務的資料庫，無法 Rollback 到上一個版本，則你得自己手動 Rollback。

注意到我們定義了一個 `change` 方法，內容填入時間往前時期望的變動。在這筆遷移執行之前，資料庫裡還沒有資料表。遷移之後資料表便建出來了。Active Record 知道如何倒回這筆遷移：若我們回滾這筆遷移，Active Record 會把該資料表刪除。

在支援交易的資料庫裡，遷移會包在交易裡執行。若資料庫不支援交易功能，則遷移失敗時，已進行的操作不會回滾。會需要手動恢復已進行的操作。

NOTE: 某些查詢無法在交易裡執行。如果連接器支援 DDL 交易，可以用 `disable_ddl_transaction!` 在單次遷移裡停用交易功能。

若想在遷移裡做些 Active Record 不知道如何回滾的事，可以自己用 `reversible` 手動回滾：

```ruby
class ChangeProductsPrice < ActiveRecord::Migration
  def change
    reversible do |dir|
      change_table :products do |t|
        dir.up   { t.change :price, :string }
        dir.down { t.change :price, :integer }
      end
    end
  end
end
```

也可以用 `up`、`down` 來取代 `change`：

```ruby
class ChangeProductsPrice < ActiveRecord::Migration
  def up
    change_table :products do |t|
      t.change :price, :string
    end
  end

  def down
    change_table :products do |t|
      t.change :price, :integer
    end
  end
end
```

建立 Migration
--------------------

### 新增獨立的 Migration

__Migration 存在那裡？__

`db/migrate` 目錄下。

__Migration 檔名規則？__

`YYYYMMDDHHMMSS_migration_name.rb`，前面的 `YYYYMMDDHHMMSS` 是 UTC 格式的時間戳章，後面接的是該 Migration 的名稱（前例 `migration_name.rb`）。Migration 的類別是用駝峰形式（CamelCased）定義的，會對應到檔名。

舉個例子：

`20130916204300_create_products.rb` 會定義出 `CreateProducts` 這樣的類別名稱。

`20121027111111_add_details_to_products.rb` 會定義出 `AddDetailsToProducts` 這樣的類別名稱。

__Rails 根據時間戳章決定運行先後順序。__

__怎麼產生 Migration?__

```bash
$ rails generate migration AddPartNumberToProducts
```

會產生出空的 Migration：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
  end
end
```

Migration 名稱有兩個常見的形式：`AddXXXToYYY`、`RemoveXXXFromYYY`，之後接一系列的欄位名稱＋類型。則會自動幫你產生 `add_column`：

```bash
$ rails generate migration AddPartNumberToProducts part_number:string
```

會產生

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
  end
end
```

當你 rollback 的時候，Rails 會自動幫你 `remove_column`。

給欄位加上索引（index）也是很簡單的：

```bash
$ rails generate migration AddPartNumberToProducts part_number:string:index
```

會產生

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
    add_index :products, :part_number
  end
end
```

同樣也可以移除某個欄位：

```bash
$ rails generate migration RemovePartNumberFromProducts part_number:string
```

會產生：

```ruby
class RemovePartNumberFromProducts < ActiveRecord::Migration
  def change
    remove_column :products, :part_number, :string
  end
end
```

一次可產生多個欄位：

```bash
$ rails generate migration AddDetailsToProducts part_number:string price:decimal
```

會產生：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :part_number, :string
    add_column :products, :price, :decimal
  end
end
```

剛剛已經講過兩個常見的 Migration 命名形式：`AddXXXToYYY`、`RemoveXXXFromYYY`，還有 `CreateXXX` 這種：

```bash
$ rails generate migration CreateProducts name:string part_number:string
```

會新建 table 及欄位：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :part_number
    end
  end
end
```

不過 Rails 產生的 Migration 不是不能改的，可以按需更改。

欄位類型還有一種叫做 `references` （＝ `belongs_to`）：

```bash
$ rails generate migration AddUserRefToProducts user:references
```

會產生

```ruby
class AddUserRefToProducts < ActiveRecord::Migration
  def change
    add_reference :products, :user, index: true
  end
end
```

會針對 Product 表，產生一個 `user_id` 欄位並加上索引。

__產生 Join Table?__

```bash
rails g migration CreateJoinTableCustomerProduct customer product
```

會產生：

```ruby
class CreateJoinTableCustomerProduct < ActiveRecord::Migration
  def change
    create_join_table :customers, :products do |t|
      # t.index [:customer_id, :product_id]
      # t.index [:product_id, :customer_id]
    end
  end
end
```

### Model 產生器

看看 `rails generate model` 會產生出來的 Migration 例子，比如：

```bash
$ rails generate model Product name:string description:text
```

會產生如下的 Migration：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```


`rails generate model Product` 後面可接無限個欄位名及類型。

__Active Record 支援的欄位類型有哪些？__

> `:primary_key`, `:string`, `:text`, <br>
> `:integer`, `:float`, `:decimal`, <br>
> `:datetime`, `:timestamp`, `:time`, <br>
> `:date`, `:binary`, `:boolean`, `:references`

### 類型修飾符

類型後面還可加修飾符（modifiers），支持下列修飾符：

|修飾符         |說明                                           |
|:-------------|:---------------------------------------------|
|`:limit`      | 設定 `string/text/binary/integer` 欄位的最大值。|
|`:precision`  | 定義 `decimal` 欄位的精度，含小數點可以有幾個數字。|
|`:scale`      | 定義 `decimal` 欄位的位數，小數點可以有幾位。|
|`:polymorphic`| 給 `belongs_to` association 加上 `type` 欄位。|
|`:null`       | 欄位允不允許 `NULL` 值。|

舉例來說

```bash
$ rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

會產生如下的 Migration：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :price, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true, index: true
  end
end
```

撰寫 Migration
------------------

### 產生 Table

`create_table`，通常用 `rails generate model` 或是 `rails generate scaffold` 的時候會自動產生 Migration，裡面就帶有 `create_table`，比如 `rails g model product name:string`：

```ruby
create_table :products do |t|
  t.string :name
end
```

`create_table` 預設會產生主鍵（`id`），可以給主鍵換名字。用 `:primary_key`，或者是不要主鍵，可以傳入 `id: false`。要傳入資料庫相關的選項，可以用 `:options`

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

會在產生出來的 SQL 語句，加上 `ENGINE=BLACKHOLE`。

更多可查閱 [create_table](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table) API。


### 產生 Join Table

`create_join_table` 會產生 HABTM (HasAndBelongsToMany) join table。常見的應用場景：

```ruby
create_join_table :products, :categories
```

會產生一個 `categories_products` 表，有著 `category_id` 與 `product_id` 欄位。這些欄位的預設選項是 `null: false`，可以在 `:column_options` 裡改為 `true`：

```ruby
create_join_table :products, :categories, column_options: {null: true}
```

可以更改 join table 的名字，使用 `table_name:` 選項：

```ruby
create_join_table :products, :categories, table_name: :categorization
```

便會產生出 `categorization` 表，一樣有 `category_id` 與 `product_id`。

`create_join_table` 也接受區塊，可以用來加索引、或是新增更多欄位：

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

### 變更 Table

`change_table` 用來變更已存在的 table。

```ruby
change_table :products do |t|
  t.remove :description, :name
  t.string :part_number
  t.index :part_number
  t.rename :upccode, :upc_code
end
```

會移除 `description` 與 `name` 欄位。新增 `part_number` （字串）欄位，並打上索引。並將 `upccode` 欄位重新命名為 `upc_code`。

### Helpers 不夠用怎麼辦

Active Record 提供的 Helper 無法完成你想做的事情時，可以使用 `execute` 方法來執行任何 SQL 語句：

```ruby
Product.connection.execute('UPDATE `products` SET `price`=`free` WHERE 1')
```

每個方法的更多細節與範例，請查閱 API 文件，特別是：

[`ActiveRecord::ConnectionAdapters::SchemaStatements`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html)
(which provides the methods available in the `change`, `up` and `down` methods)

[`ActiveRecord::ConnectionAdapters::TableDefinition`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html)
(which provides the methods available on the object yielded by `create_table`)

[`ActiveRecord::ConnectionAdapters::Table`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html)
(which provides the methods available on the object yielded by `change_table`).

### 使用 `change` 方法

撰寫 Migration 主要用 `change`，大多數情況 Active Record 知道如何執行逆操作。下面是 Active Record 可以自動產生逆操作的方法：

* `add_column`
* `add_index`
* `add_reference`
* `add_timestamps`
* `create_table`
* `create_join_table`
* `drop_table` (must supply a block)
* `drop_join_table` (must supply a block)
* `remove_timestamps`
* `rename_column`
* `rename_index`
* `remove_reference`
* `rename_table`

`change_table` 也是可逆的，只要傳給 `change_table` 的區塊沒有呼叫 `change`、`change_default` 或是 `remove` 即可。

如果你想有更多的靈活性，可以使用 `reversible` 或是撰寫 `up`、`down` 方法。

### 使用 `reversible`

複雜的 Migration Active Record 可能不知道怎麼變回來。這時候可以使用 `reversible`：

```ruby
class ExampleMigration < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.references :category
    end

    reversible do |dir|
      dir.up do
        #add a foreign key
        execute <<-SQL
          ALTER TABLE products
            ADD CONSTRAINT fk_products_categories
            FOREIGN KEY (category_id)
            REFERENCES categories(id)
        SQL
      end
      dir.down do
        execute <<-SQL
          ALTER TABLE products
            DROP FOREIGN KEY fk_products_categories
        SQL
      end
    end

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end
```

使用 `reversible` 會確保執行順序的正確性。若你做了不可逆的操作，比如刪除資料。Active Record 會在執行 `down` 區塊時，raise 一個 `ActiveRecord::IrreversibleMigration`。


### 使用 `up`、`down` 方法

可以不用 `change` 撰寫 Migration，使用經典的 `up`、`down` 寫法。

`up` 撰寫 migrate、`down` 撰寫 rollback。兩個操作要可以互相抵消。舉例來說，`up` 建了一個 table，`down` 就要 `drop` 那個 table。

上面使用 `reversible` 可以用 `up`＋`down` 改寫：

```ruby
class ExampleMigration < ActiveRecord::Migration
  def up
    create_table :products do |t|
      t.references :category
    end

    # add a foreign key
    execute <<-SQL
      ALTER TABLE products
        ADD CONSTRAINT fk_products_categories
        FOREIGN KEY (category_id)
        REFERENCES categories(id)
    SQL

    add_column :users, :home_page_url, :string
    rename_column :users, :email, :email_address
  end

  def down
    rename_column :users, :email_address, :email
    remove_column :users, :home_page_url

    execute <<-SQL
      ALTER TABLE products
        DROP FOREIGN KEY fk_products_categories
    SQL

    drop_table :products
  end
end
```

如果 Migration 是不可逆的操作，要在 `down` raise 一個 `ActiveRecord::IrreversibleMigration`。

### 取消之前的 Migration

用 `revert` 來取消先前的 Migration：

```ruby
require_relative '2012121212_example_migration'

class FixupExampleMigration < ActiveRecord::Migration
  def change
    revert ExampleMigration

    create_table(:apples) do |t|
      t.string :variety
    end
  end
end
```

`revert` 方法也接受區塊，可以只取消部份的 Migration。看看這個例子（取消 `ExampleMigration`）：

```ruby
class SerializeProductListMigration < ActiveRecord::Migration
  def change
    add_column :categories, :product_list

    reversible do |dir|
      dir.up do
        # transfer data from Products to Category#product_list
      end
      dir.down do
        # create Products from Category#product_list
      end
    end

    revert do
      # copy-pasted code from ExampleMigration
      create_table :products do |t|
        t.references :category
      end

      reversible do |dir|
        dir.up do
          #add a foreign key
          execute <<-SQL
            ALTER TABLE products
              ADD CONSTRAINT fk_products_categories
              FOREIGN KEY (category_id)
              REFERENCES categories(id)
          SQL
        end
        dir.down do
          execute <<-SQL
            ALTER TABLE products
              DROP FOREIGN KEY fk_products_categories
          SQL
        end
      end

      # The rest of the migration was ok
    end
  end
end
```

上面這個 Migration 也可以不用 `revert` 寫成。

把 `create_table` 與 `reversible` 順序對換，`create_table` 換成 `drop_table`，最後對換 `up` `down`。

這其實就是 `revert` 做的事。

## 執行 Migrations

Rails 提供了許多 Rake 任務用來執行 Migration。

有點要注意的是，執行 `db:migrate` 也會執行 `db:schema:dump`，會幫你更新 `db/schema.rb` 來反映出當下的資料庫結構。

如果指定了 target 版本，Active Record 會執行版本之前所有的 Migration。target 名稱是 Migration 前面的 UTC 時間戳章（包含 20080906120000）：

```bash
$ rake db:migrate VERSION=20080906120000
```

```bash
$ rake db:rollback VERSION=20080906120000
```

會從最新的版本，執行 `down` 方法到 `20080906120000` 但不包含（`20080906120000`）

### 回滾

最常見的就是回滾上一個 task。假設你犯了個錯誤，並想修正。可以：

```bash
$ rake db:rollback
```

會回退一個 Migration。可以指定要回退幾步，使用 `STEP` 參數

```bash
$ rake db:rollback STEP=3
```

會取消前 3 次 migrations。

`db:migrate:redo` 用來回退、接著再一次 `rake db:migrate`，同樣接受 `STEP` 參數：

```bash
$ rake db:migrate:redo STEP=3
```

這些操作用 `db:migrate` 都辦得到，只是方便你使用而已。

### 設定資料庫

The `rake db:setup` 會新建資料庫、載入 schema、並用種子資料來初始化資料庫。

### 重置資料庫

`rake db:reset` 會將資料庫 drop 掉，並重新恢復。

`rake db:reset` ＝ `rake db:drop db:setup`。

__注意！__ 這跟執行所有的 Migration 不一樣。這只會用 `schema.rb` 裡的內容來操作。如果 Migration 不能回退， `rake db:reset` 也是派不上用場的！了解更多參考 [schema dumping and you](#7-schema-dumping-與你)。

### 執行特定的 Migration

用 `db:migrate:up` 或 `db:migrate:down` tasks，並指定版本：

```bash
$ rake db:migrate:up VERSION=20080906120000
```

會執行在 `20080906120000` 版本之前的 Migration 裡面的 `change`、`up` 方法。若已經遷移過了，則 Active Record 不會執行。

### 在不同環境下執行 Migration

默認 `rake db:migrate` 會在 `development` 環境下執行。可以通過指定 `RAILS_ENV` 來指定運行的環境，比如在 `test` 環境下：

```bash
$ rake db:migrate RAILS_ENV=test
```

### 修改執行中 Migration 的輸出

Migration 通常會告訴你他們幹了什麼，並花了多長時間。建立 table 及加 index 的輸出可能像是這樣：

```bash
==  CreateProducts: migrating =================================================
-- create_table(:products)
   -> 0.0028s
==  CreateProducts: migrated (0.0028s) ========================================
```

Migration 提供了幾個方法讓你控制輸出訊息：

| 方法                  | 目的
| :-------------------- | :-------
| suppress_messages    | 接受區塊作為參數，區塊內指名的代碼不會產生輸出。
| say                  | 接受一個訊息字串，並輸出該字串。第二個參數可以用來指定要不要縮排。
| say_with_time        | 同上，但會附上區塊的執行時間。若區塊返回整數，會假定該整數是受影響的 row 的數量。

舉例來說：

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    suppress_messages do
      create_table :products do |t|
        t.string :name
        t.text :description
        t.timestamps
      end
    end

    say "Created a table"

    suppress_messages {add_index :products, :name}
    say "and an index!", true

    say_with_time 'Waiting for a while' do
      sleep 10
      250
    end
  end
end
```

產生輸出如下：

```bash
==  CreateProducts: migrating =================================================
-- Created a table
   -> and an index!
-- Waiting for a while
   -> 10.0013s
   -> 250 rows
==  CreateProducts: migrated (10.0054s) =======================================
```

如果想 Active Record 完全不要輸出訊息，執行 `rake db:migrate VERBOSE=false`。

## 修改現有的 Migrations

有時候 Migration 可能會寫錯。修正過來之後，要先執行 `rake db:rollback`，再執行 `rake db:migrate`。

編輯現有的 Migration 不太好，因為會增加一起開發的人更多工作量。尤其是 Migration 已經上 production，應該要寫個新的 Migration，來達成你想完成的事情。

`revert` 方法用來寫新的 Migration 取消先前的 Migration 很有用。

## Schema Dumping 與你

### Schema 有什麼用

Migrations，是可以變化的，要確定資料庫的 schema，還是看 `db/schema.rb` 最可靠，或是由 Active Record 產生的 SQL 檔案。`db/schema.rb` 與 SQL 都是用來表示資料庫目前的狀態，不要修改這兩個檔案。

依靠 Migration 來佈署新的 app 是不可靠而且容易出錯的。最簡單的辦法是把 `db/schema.rb` 加載到資料庫裡。

舉例來說吧，這便是測試資料庫如何產生的過程：dump 目前的開發資料庫，dump 成 `db/schema.rb` 或是 `db/structure.sql`，並載入至測試資料庫。

若想了解 Active Record object 有什麼屬性，直接看 Schema 檔案是很有用的。因為屬性總是透過 Migration 添加，要追蹤這些 Migration 不容易，但最後的結果都總結在 schema 檔案裡。

[annotate_models](https://github.com/ctran/annotate_models) Gem 自動替你在每個 model 最上方，添加或更新註解，描述每個 model 屬性的註解。

### Schema Dump 的種類

兩種方式來 dump schema。可在 `config/application.rb` 來設定：

`config.active_record.schema_format`，可以是 `:sql` 或 `:ruby`。

如果選擇用 `:ruby`，則 schema 會儲存在 `db/schema.rb`。打開這個檔案，你會看到像是下面的 Migration：

```ruby
ActiveRecord::Schema.define(version: 20080906171750) do
  create_table "authors", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", force: true do |t|
    t.string   "name"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "part_number"
  end
end
```

許多情況下，這便是資料庫裡有的東西。這個檔案是檢查資料庫之後，用 `create_table`、`add_index` 這些 helper 來表示資料庫的結構。由於這獨立於資料庫，可以加載到任何 Active Record 所支援的資料庫。如果你的 app 要執行許多資料庫的時候，這點非常有用。

但有好有壞：`db/schema.rb` 不能表達資料庫特有的功能，像是 foreign key constraints、triggers、或是 stored procedures。在 Migration 可以執行任何 SQL 語句，但 schema dumper 不能從這些 SQL 語句裡重建出資料庫。如果要執行自訂的 SQL，記得將 schema 格式設定為 `:sql`。

與其使用 Active Record 提供的 schema dumper，可以用資料庫專門的工具。透過 `db:structure:dump` 任務來導出 `db/structure.sql`。舉例來說，PostgreSQL 使用 `pg_dump`。MySQL 只不過是多張表的 `SHOW CREATE TABLE` 的結果。

載入這些 schema ，不過是執行裡面的 SQL 語句。定義上來說，這可以完美拷貝一份資料庫的結構。但使用 `:sql` schema 格式，便不能從一種 RDBMS 資料庫，切換到另一種 RDBMS 資料庫了。

### Schema Dumps 與版本管理

因為 schema dumps 是資料庫 schema 最完整的來源，強烈建議你將 schema 用版本管理來追蹤。

## Active Record 與 Referential Integrity

Active Record 認為事情要在 model 裡處理好，不是在資料庫。也是因為這個原因，像是 trigger 或 foreign key constraints 這種牽涉到資料庫的事情不常使用

`validates :foreign_key, uniqueness: true` 是整合資料的一種方法。`:dependet` 選項讓 model 可以自動 destroy 與其關聯的資料。有人認為這種操作不能保證 referential integrity，要在資料庫解決才是。

雖然 Active Record 沒有直接提供任何工具來解決這件事，但你可以用 `execute` 方法來執行 SQL 語句，也可以使用像是 [foreigner](https://github.com/matthuhiggins/foreigner) 這種 Gem。Foreigner 給  Active Record 加入 foreign key 的支援（包含在 `db/schema.rb` dumping foreign key。）

Migrations 與 Seed Data
----------------------------

有些人使用 Migration 來加資料到資料庫：

```ruby
class AddInitialProducts < ActiveRecord::Migration
  def up
    5.times do |i|
      Product.create(name: "Product ##{i}", description: "A product.")
    end
  end

  def down
    Product.delete_all
  end
end
```

但 Rails 有 “seeds” 這個功能，應該這麼用才對。在 `db/seeds.rb` 填入 Ruby 代碼，執行 `rake db:seed` 即可：

```ruby
5.times do |i|
  Product.create(name: "Product ##{i}", description: "A product.")
end
```

這個辦法比用 Migration 來建立資料到空的資料庫好。
