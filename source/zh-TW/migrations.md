Active Record 遷移
========================

Migration，遷移。Active Record 眾多功能之一，可與時俱進的[管理資料庫綱要](http://en.wikipedia.org/wiki/Schema_migration)。最棒的是遷移提供了簡潔的 Ruby DSL，無需寫純 SQL，便能變更資料表。

讀完本篇，您將了解：

* 使用產生遷移的產生器。
* Active Record 提供用來操作資料庫的方法。
* 撰寫 Rake 任務來管理資料庫綱要與遷移檔案。
* 遷移與 `db/schema.rb` 的關係。


--------------------------------------------------------------------------------

綜覽
--------------------

遷移是一種簡單、一致、方便[與時俱進管理資料庫綱要](http://en.wikipedia.org/wiki/Schema_migration)的方法。遷移使用 Ruby DSL，而不用手寫 SQL，適用於所有資料庫。

每筆遷移都可想成是資料庫的新版本。資料庫綱要一開始什麼也沒有，每筆遷移慢慢得往資料庫裡增刪資料表、欄位、記錄等。Active Record 知道如何依時間順序更新資料庫綱要，從資料庫歷史的何處開始都可以，都能前往最新版本。此外，Active Record 也會更新 `db/schema.rb` 檔案，與最新的資料庫結構保持同步。

來看個範例遷移檔案：

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

建立遷移
--------------------

### 新建獨立的遷移

遷移檔案存在 `db/migrate` 目錄，一個檔案對應一筆遷移。檔名以 `YYYYMMDDHHMMSS_create_products.rb` 形式命名：

`YYYYMMDDHHMMSS_migration_name.rb`，前面的 `YYYYMMDDHHMMSS` 是 UTC 格式的時間戳章，接著是底線，底線後面是該筆遷移的名稱。遷移類別以駝峰形式命名，會對應到 `_migration_name`。舉例來說 `20140916204300_create_products.rb` 會定義出 `CreateProducts` 這樣的類別名稱。而 `20121027111111_add_details_to_products.rb` 則會定義出 `AddDetailsToProducts` 這樣的類別名稱。Rails 根據時間戳章決定執行的先後順序。若是從別的應用程式複製過來的遷移檔案，或是自己產生的遷移，要注意執行的順序。

當然了，計算時間戳章很難，所以 Active Record 提供了產生器，幫您處理好時間戳的問題：

```bash
$ rails generate migration AddPartNumberToProducts
```

會產生出空的遷移檔案，遷移的類別名稱已經取好了：

```ruby
class AddPartNumberToProducts < ActiveRecord::Migration
  def change
  end
end
```

在命令行輸入的遷移名稱若是 `AddXXXToYYY` 或 `RemoveXXXFromYYY`，之後接一系列的欄位名稱與類型。則會自動產生 `add_column` 或 `remove_column`：


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

剛剛已經看過兩種常見的遷移命名形式：`AddXXXToYYY`、`RemoveXXXFromYYY`，還有 `CreateXXX` 這種，後面接欄位名與類型：

```bash
$ rails generate migration CreateProducts name:string part_number:string
```

則會新建 table 及欄位：

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

Rails 產生的遷移檔案不過是個開始，可以透過編輯 `db/migrate/YYYYMMDDHHMMSS_add_details_to_products.rb` 檔案，根據需求修改。

還有一種欄位類型叫做 `references`（＝ `belongs_to`）：

```bash
$ rails generate migration AddUserRefToProducts user:references
# 等同於
$ rails generate migration AddUserRefToProducts user:belongs_to
```

會產生

```ruby
class AddUserRefToProducts < ActiveRecord::Migration
  def change
    add_reference :products, :user, index: true
  end
end
```

會給 Product 資料表，產生一個 `user_id` 欄位並加上索引。

若傳給產生器的遷移名稱，名稱部分包含 `JoinTable`，則會建出連接表：

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

Model 與鷹架產生器新建 Model 時，也會建立遷移。這個遷移檔案會包含建立相關資料表的步驟。若進一步告訴 Rails 所需的欄位，欄位也會加入至遷移檔案裡。舉例來說，執行：

```bash
$ rails generate model Product name:string description:text
```

會產生如下的遷移檔案：

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

可以接著給產生出來的遷移檔案新增欄位。

### 支援的類型修飾符

類型後面還可加修飾符（modifiers），放在大括號裡。可以使用以下修飾符：

|修飾符         |說明                                           |
|:-------------|:---------------------------------------------|
|`:limit`      | 設定 `string/text/binary/integer` 欄位的最大值。|
|`:precision`  | 定義 `decimal` 欄位的精度，含小數點可以有幾個數字。|
|`:scale`      | 定義 `decimal` 欄位的位數，小數點可以有幾位。|
|`:polymorphic`| 給 `belongs_to` association 加上 `type` 欄位。|
|`:null`       | 欄位允不允許 `NULL` 值。|

舉例來說，執行：

```bash
$ rails generate migration AddDetailsToProducts 'price:decimal{5,2}' supplier:references{polymorphic}
```

會產生如下的遷移檔案：

```ruby
class AddDetailsToProducts < ActiveRecord::Migration
  def change
    add_column :products, :price, :decimal, precision: 5, scale: 2
    add_reference :products, :supplier, polymorphic: true, index: true
  end
end
```

撰寫遷移
------------------

使用產生器建立出遷移檔案之後，開工的時候到了！

### 建立資料表

`create_table` 是最基礎的方法之一，通常 `rails generate model` 或 `rails generate scaffold` 便會自動產生出來。常見用途：

```ruby
create_table :products do |t|
  t.string :name
end
```

會建立一張 `products` 資料表，有著 `name` 欄位（以及看不見的主鍵 `id`）。

`create_table` 預設會產生主鍵（`id`），可以用 `:primary_key` 選項來修改主鍵的名字（記得更新對應的 Model）。或者是完全不要主鍵，可以傳入 `id: false` 選項。資料庫特定的選項，可以傳給 `:options`

```ruby
create_table :products, options: "ENGINE=BLACKHOLE" do |t|
  t.string :name, null: false
end
```

會在用來建立資料表的 SQL 語句，附上 `ENGINE=BLACKHOLE`（使用 MySQL 預設是 `ENGINE=InnoDB`）。

更多細節可查閱 [create_table](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table) API。

### 建立連接資料表

`create_join_table` 會建立一張 HABTM (`has_and_belongs_to_many`)連接表。常見的應用場景：

```ruby
create_join_table :products, :categories
```

會建立一張 `categories_products` 資料表，有著 `category_id` 與 `product_id` 欄位。這些欄位的預設選項是 `null: false`，可以在 `:column_options` 修改預設值：

```ruby
create_join_table :products, :categories, column_options: {null: true}
```

會建立 `product_id` 與 `category_id` 欄位，配上 `null: true` 選項。

若要修改連接資料表的名字，使用 `table_name:` 選項：

```ruby
create_join_table :products, :categories, table_name: :categorization
```

便會產生出 `categorization` 資料表，一樣有 `category_id` 與 `product_id`。

`create_join_table` 也接受區塊，可以用來加索引（預設不會加）、或用來新增更多欄位：

```ruby
create_join_table :products, :categories do |t|
  t.index :product_id
  t.index :category_id
end
```

### 修改資料表

`change_table` 用來修改已存在的資料表。使用方式與 `create_table` 雷同，但傳入區塊的物件有更多方法可用。

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

Active Record 提供的 Helper 不夠用的時候，可以使用 `execute` 方法來執行任何 SQL 語句：

```ruby
Product.connection.execute('UPDATE `products` SET `price`=`free` WHERE 1')
```

關於每個方法的更多細節與範例，請查閱 API 文件，特別是：

[`ActiveRecord::ConnectionAdapters::SchemaStatements`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html)
（在 `change`, `up` and `down` 裡可用的方法有那些）

[`ActiveRecord::ConnectionAdapters::TableDefinition`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html)
（傳入 `create_table` 區塊物件可用的方法有那些）

[`ActiveRecord::ConnectionAdapters::Table`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Table.html)
（傳入 `change_table` 區塊物件可用的方法有那些）

### 使用 `change` 方法

撰寫遷移檔案主要用 `change` 方法，適用於大多數情況，多數 Active Record 知道如何執行逆操作的情況。以下是目前 `change` 方法裡所支援的方法：

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

如果想使用其它的方法，可以使用 `reversible` 或是撰寫 `up`、`down` 方法，而不是使用 `change`。

### 使用 `reversible`

需要處理 Active Record 不知道怎麼變回來的複雜遷移時，可以使用 `reversible` 方法來指定遷移時要做什麼（`up`），回滾時要做什麼（`down`），比如：

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
end
```

使用 `reversible` 會確保執行順序的正確性。上例的遷移取消時（回滾），`down` 區塊會在 `home_page_url` 欄位移除前，以及 `products` 資料表刪除前，執行 `down` 區塊裡的內容。


有時候遷移做了怎麼樣都不可逆的操作，比如，可能是刪除資料。這種情況下，Active Record 會在試著取消遷移時，拋出一個 `ActiveRecord::IrreversibleMigration`，表示無法恢復先前的操作。

### 使用 `up`、`down` 方法

可以不用 `change` 來撰寫遷移，而使用經典的 `up`、`down` 寫法。

`up` 撰寫對資料庫綱要的變化（遷移）、`down` 撰寫取消 `up` 操作的操作（回滾）。兩個操作要可以互相抵消。舉例來說，`up` 建了一張資料表，則 `down` 便要 `drop` 該張資料表。取消遷移時最好依照遷移時的反序執行。上例使用 `reversible` 可以用 `up`＋`down` 改寫：

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

如果遷移是不可逆的操作，要在 `down` 拋出一個 `ActiveRecord::IrreversibleMigration`。這樣子別的開發者試圖要取消遷移時，便會顯示這個遷移無法取消的錯誤訊息。

### 取消之前的遷移

Active Record 提供了回滾遷移的方法：`revert`

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

`revert` 方法也接受區塊，具體取消的操作寫在區塊裡，這在只取消部份的遷移的場景下很有用。舉個例子，假設 `ExampleMigration` 已經遷移了，之後覺得還是序列化產品清單（下例的 `product_list`）好了，於是要取消遷移，可以這麼寫：

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

同樣的遷移也可以不用 `revert` 處理，但會需要多做幾個步驟。把 `create_table` 與 `reversible` 順序對換，`create_table` 換成 `drop_table`，最後對換 `up` `down` 裡的程式碼。其實這就是 `revert` 做的事。

## 執行遷移

Rails 提供了一組 Rake 任務，用來執行特定的遷移。

第一個相關會用到的 Rake 任務是 `rake db:migrate`。`rake db:migrate` 任務最簡單的形式，不過是尚未執行的遷移裡面的 `change` 或 `up` 方法。若所有的遷移都執行完畢了便離開，否則按照時間戳的順序進行遷移。

有點要注意的是，執行 `db:migrate` 也會執行 `db:schema:dump`，會更新 `db/schema.rb` 來反映出當下的資料庫結構。

如果指定了目標版本，Active Record 會執行目標版本之前所有的遷移。目標版本的名稱是遷移名前綴的 UTC 時間戳章，比如 `20080906120000`：


```bash
$ rake db:migrate VERSION=20080906120000
```

若版本 `20080906120000` 大於目前版本，則會執行 `change`（或 `up`）方法，遷移到 `20080906120000`（包含）。若版本 `20080906120000` 小於目前版本，則會對版本小於 `20080906120000` （不包含）的遷移執行 `down` 方法。

### 回滾

最常見的任務便是回滾前次遷移。假設你犯了個錯誤，並想修正。與其找出前次的版本再執行，可以直接：

```bash
$ rake db:rollback
```

會取消上次的 `change` 操作，或是執行 `down` 方法，來回滾上一次遷移。可以指定要回滾幾步，使用 `STEP` 參數

```bash
$ rake db:rollback STEP=3
```

會回滾前 3 次遷移。

`db:migrate:redo` 用來回滾、接著再遷移一次。同樣接受 `STEP` 參數，比如往前回滾 3 次，再遷移：

```bash
$ rake db:migrate:redo STEP=3
```

這些操作用 `db:migrate` 都辦得到，只是方便你使用而已，因為不用特別指定要遷移或是回滾的版本號。

### 設定資料庫

The `rake db:setup` 會新建資料庫、載入資料庫綱要、並用種子資料來初始化資料庫。

### 重置資料庫

`rake db:reset` 會將資料庫移除，再重新建立。等同於 `rake db:drop db:setup`。

NOTE: 這與執行所有的遷移不一樣。這只會用 `schema.rb` 裡的內容來操作。如果遷移不能回滾，`rake db:reset` 也是派不上用場的。了解更多請參考[導出資料庫綱要](#導出資料庫綱要)。

### 執行特定的遷移

如想執行特定的遷移，可以用 `db:migrate:up` 或 `db:migrate:down`。只需要指定特定的版本，就會根據版本去呼叫 `change`、`up` 或 `down` 方法，比如：

```bash
$ rake db:migrate:up VERSION=20080906120000
```

會執行版本大於 `20080906120000` 的遷移裡面的 `change`、`up` 方法。若已經遷移過了，則 Active Record 不會執行。

### 在不同環境下執行遷移

默認 `rake db:migrate` 會在 `development` 環境下執行。可以通過指定 `RAILS_ENV` 來指定執行的環境，比如要在 `test` 環境下執行：

```bash
$ rake db:migrate RAILS_ENV=test
```

### 修改遷移執行中的輸出

遷移通常會回報它做了什麼，花了多長時間。建立資料表及加上索引的輸出可能會像是：

```bash
==  CreateProducts: migrating =================================================
-- create_table(:products)
   -> 0.0028s
==  CreateProducts: migrated (0.0028s) ========================================
```

遷移提供了幾個方法來控制輸出訊息：

| 方法                  | 目的
| :-------------------- | :-------
| suppress_messages    | 接受區塊作為參數，區塊內指名的代碼不會產生輸出。
| say                  | 接受一個訊息字串，並輸出該字串。第二個參數可以用來指定要不要縮排。
| say_with_time        | 同上，但會附上區塊的執行時間。若區塊返回整數，會假定該整數是受影響列的數量。

舉例來說，這個遷移：

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

如果想 Active Record 完全不要輸出訊息，則執行 `rake db:migrate VERBOSE=false` 即可，會消音所有訊息。

## 修改現有的遷移

有時候遷移可能會寫錯。已經執行過的遷移，不能修改遷移再執行一次：Rails 會認為這次遷移已經執行過了，修改已執行的遷移不會生效。要先執行 `rake db:rollback`，編輯遷移檔案，接著再次執行 `rake db:migrate`。

通常不太推薦修改現有的遷移，因為會增加同事更多工作量。尤其是遷移已經上線了（production），應該要寫個新的遷移，執行需要的修改，來達成想完成的事情。修改新建的遷移（尚未提交至版本管理）是相對無害的。

`revert` 方法用來寫新的遷移，取消先前的遷移的場景很有用。參考[取消之前的遷移](#取消前次遷移)小節。

導出資料庫綱要
----------------

### 資料庫綱要檔案有什麼用

遷移是會變的，不會反映出當下的資料庫結構。要確定資料庫的結構，還是看資料庫綱要檔案： `db/schema.rb` 最可靠，或是由 Active Record 導生的 SQL 檔案。`db/schema.rb` 與 SQL 是用來表示資料庫目前的狀態，兩個檔案不可以修改。

依靠重新執行所有的遷移，來部署新的應用程式，不可靠又容易出錯。最簡單的辦法是把資料庫的結構檔案，加載到資料庫裡。

舉例來說，這便是測試資料庫如何產生的過程：導出目前的開發資料庫（導出成 `db/schema.rb` 或 `db/structure.sql`），接著載入至測試資料庫。

若想了解 Active Record object 有什麼屬性。Model 裡沒有寫，屬性散佈在多個遷移檔案裡，但所有的屬性都總結在資料庫綱要檔案了。如果想要在 Model 裡看到所有的屬性資訊，有一個 [annotate_models](https://github.com/ctran/annotate_models) RubyGem，自動在 Model 檔案最上方加註解，使用資料庫綱要檔案，來記錄每個 Model 有的屬性。

### 導出資料庫綱要的種類

有兩種方式可以導出資料庫綱要。可以在 `config/application.rb` 檔案裡，使用 `config.active_record.schema_format` 來設定，值可以是 `:sql` 或 `:ruby`。

如果選擇用 `:ruby`，則資料庫綱要檔案會儲存在 `db/schema.rb`。打開這個檔案，會發現這像是一個很大的遷移檔案：

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

多數情況下，這便是資料庫裡有的東西。這個檔案是檢查資料庫之後，用 `create_table`、`add_index` 這些 helper 來表示資料庫的結構。這與使用何種資料庫無關，可以加載到任何 Active Record 所支援的資料庫。如果應用程式要發佈到多種資料庫的時候，這個檔案非常有用。

但魚與熊掌不可兼得：`db/schema.rb` 不能表達資料庫特有的功能，像是外鍵約束、觸發器（triggers）、或是儲存過程（stored procedure）。但是在遷移裡可以執行任何自訂的 SQL 語句，但資料庫綱要的程式，無法從資料庫重建出這些 SQL 語句。如果要執行自訂的 SQL，記得將資料庫綱要的導出格式設定為 `:sql`。

與其使用 Active Record 提供的資料庫綱要導出程式，可以用特定資料庫的導出工具（透過 `db:structure:dump` 任務來導出 `db/structure.sql`）。舉例來說，PostgreSQL 使用 `pg_dump` 這個工具來導出 SQL。而 MySQL 呢，資料庫綱要只不過是多張資料表的 `SHOW CREATE TABLE` 的結果。

載入這些 `:sql` 格式的綱要檔案，不過是執行裡面的 SQL 語句而已。定義上來說，會建立一份資料庫結構的完美複本。但使用 `:sql` 綱要格式的話，便不能從一種 RDBMS 資料庫，切換到另一種 RDBMS 資料庫了。

### 導出資料庫綱要與版本管理

因為導出的資料庫綱要檔案，是資料庫結構最權威的來源，強烈建議將資料庫綱要檔案加到版本管理裡。

Active Record 與參照完整性
----------------------------

Active Record 認為事情要在 model 裡處理好，而不是在資料庫。也是因為這個原因，像是觸發器或外鍵約束，這種需要在資料庫實作的功能，不常使用。

像 `validates :foreign_key, uniqueness: true` 這樣的驗證，是加強資料整合性的方法之一。`:dependet` 選項讓 Model 可以自動刪除關聯的資料。某些人認為像是這種操作，以及所有在應用程式層級執行的操作，無法保證參照的完整性，要跟外鍵約束一樣，放在資料庫解決才是。

雖然 Active Record 沒有直接提供任何工具來解決這件事，但可以用 `execute` 方法來執行任何的 SQL 語句，也可以使用像是 [foreigner](https://github.com/matthuhiggins/foreigner) 這種 RubyGem。Foreigner 給 Active Record 加入外鍵的支援（支援導出外鍵到 `db/schema.rb`）。

遷移與種子資料
----------------------------

有些人使用遷移來給資料庫新增資料：

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

但 Rails 有 “seeds” 這個功能，應該這麼用這個來給資料庫新增初始資料才對。用起來非常簡單，在 `db/seeds.rb` 寫些 Ruby，執行 `rake db:seed` 即可：

```ruby
5.times do |i|
  Product.create(name: "Product ##{i}", description: "A product.")
end
```

這樣比用遷移來設定新應用程式的資料庫簡潔許多。
