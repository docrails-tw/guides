Active Record PostgreSQL
============================

本篇介紹 Active Record PostgreSQL 的具體用法。

讀完本篇，您將了解：

* 如何使用 PostgreSQL 的資料類型。
* 如何使用 UUID 主鍵。
* 如何在 PostgreSQL 實作全文搜索。

--------------------------------------------------------------------------------

PostgreSQL 的最低版本要求為 8.2。舊版不支援。

開始使用 PostgreSQL 之前，請先看看[如何為 Active Record 設定 PostgreSQL 資料庫](configuring.html#configuring-a-postgresql-database)。

資料類型
---------

PostgreSQL 提供許多具體的資料類型。以下是 PostgreSQL 連接器所支援的類型列表。

### Bytea 類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/datatype-binary.html)
* [函數與運算元](http://www.postgresql.org/docs/9.3/static/functions-binarystring.html)

```ruby
# db/migrate/20140207133952_create_documents.rb
create_table :documents do |t|
  t.binary 'payload'
end

# app/models/document.rb
class Document < ActiveRecord::Base
end

# 用途
data = File.read(Rails.root + "tmp/output.pdf")
Document.create payload: data
```

### 陣列類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/arrays.html)
* [函數與運算元](http://www.postgresql.org/docs/9.3/static/functions-array.html)

```ruby
# db/migrate/20140207133952_create_books.rb
create_table :books do |t|
  t.string 'title'
  t.string 'tags', array: true
  t.integer 'ratings', array: true
end

add_index :books, :tags, using: 'gin'
add_index :books, :ratings, using: 'gin'

# app/models/book.rb
class Book < ActiveRecord::Base
end

# 用途
Book.create title: "Brave New World",
            tags: ["fantasy", "fiction"],
            ratings: [4, 5]

## Books for a single tag
Book.where("'fantasy' = ANY (tags)")

## Books for multiple tags
Book.where("tags @> ARRAY[?]::varchar[]", ["fantasy", "fiction"])

## Books with 3 or more ratings
Book.where("array_length(ratings, 1) >= 3")
```

### Hstore 類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/hstore.html)

```ruby
# db/migrate/20131009135255_create_profiles.rb
ActiveRecord::Schema.define do
  create_table :profiles do |t|
    t.hstore 'settings'
  end
end

# app/models/profile.rb
class Profile < ActiveRecord::Base
end

# 用途
Profile.create(settings: { "color" => "blue", "resolution" => "800x600" })

profile = Profile.first
profile.settings # => {"color"=>"blue", "resolution"=>"800x600"}

profile.settings = {"color" => "yellow", "resolution" => "1280x1024"}
profile.save!

## you need to call _will_change! if you are editing the store in place
profile.settings["color"] = "green"
profile.settings_will_change!
profile.save!
```

### JSON 類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/datatype-json.html)
* [函數與運算元](http://www.postgresql.org/docs/9.3/static/functions-json.html)

```ruby
# db/migrate/20131220144913_create_events.rb
create_table :events do |t|
  t.json 'payload'
end

# app/models/event.rb
class Event < ActiveRecord::Base
end

# 用途
Event.create(payload: { kind: "user_renamed", change: ["jack", "john"]})

event = Event.first
event.payload # => {"kind"=>"user_renamed", "change"=>["jack", "john"]}

## 基於 JSON 文件的查詢
Event.where("payload->'kind' = ?", "user_renamed")
```

### Range 類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/rangetypes.html)
* [函數與運算元](http://www.postgresql.org/docs/9.3/static/functions-range.html)

此類型映射到 Ruby 的 [`Range`](http://www.ruby-doc.org/core-2.1.1/Range.html) 物件

```ruby
# db/migrate/20130923065404_create_events.rb
create_table :events do |t|
  t.daterange 'duration'
end

# app/models/event.rb
class Event < ActiveRecord::Base
end

# 用途
Event.create(duration: Date.new(2014, 2, 11)..Date.new(2014, 2, 12))

event = Event.first
event.duration # => Tue, 11 Feb 2014...Thu, 13 Feb 2014

## 找出特定日期的所有活動
Event.where("duration @> ?::date", Date.new(2014, 2, 12))

## 使用 range bounds
event = Event.
  select("lower(duration) AS starts_at").
  select("upper(duration) AS ends_at").first

event.starts_at # => Tue, 11 Feb 2014
event.ends_at # => Thu, 13 Feb 2014
```

### 複合類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/rowtypes.html)

複合類型映射到一般的 `text` 欄位。

```sql
CREATE TYPE full_address AS
(
  city VARCHAR(90),
  street VARCHAR(90)
);
```

```ruby
# db/migrate/20140207133952_create_contacts.rb
execute <<-SQL
 CREATE TYPE full_address AS
 (
   city VARCHAR(90),
   street VARCHAR(90)
 );
SQL
create_table :contacts do |t|
  t.column :address, :full_address
end

# app/models/contact.rb
class Contact < ActiveRecord::Base
end

# 用途
Contact.create address: "(Paris,Champs-Élysées)"
contact = Contact.first
contact.address # => "(Paris,Champs-Élysées)"
contact.address = "(Paris,Rue Basse)"
contact.save!
```

### 枚舉類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/datatype-enum.html)

枚舉類型映射到一般的 `text` 欄位。

```ruby
# db/migrate/20131220144913_create_events.rb
execute <<-SQL
  CREATE TYPE article_status AS ENUM ('draft', 'published');
SQL
create_table :articles do |t|
  t.column :status, :article_status
end

# app/models/article.rb
class Article < ActiveRecord::Base
end

# 用途
Article.create status: "draft"
article = Article.first
article.status # => "draft"

article.status = "published"
article.save!
```

### UUID 類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/datatype-uuid.html)
* [產生器函數](http://www.postgresql.org/docs/9.3/static/uuid-ossp.html)

```ruby
# db/migrate/20131220144913_create_revisions.rb
create_table :revisions do |t|
  t.column :identifier, :uuid
end

# app/models/revision.rb
class Revision < ActiveRecord::Base
end

# 用途
Revision.create identifier: "A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11"

revision = Revision.first
revision.identifier # => "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
```

### 位元字串類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/datatype-bit.html)
* [函數與運算元](http://www.postgresql.org/docs/9.3/static/functions-bitstring.html)

```ruby
# db/migrate/20131220144913_create_users.rb
create_table :users, force: true do |t|
  t.column :settings, "bit(8)"
end

# app/models/device.rb
class User < ActiveRecord::Base
end

# 用途
User.create settings: "01010011"
user = User.first
user.settings # => "(Paris,Champs-Élysées)"
user.settings = "0xAF"
user.settings # => 10101111
user.save!
```

### 網路位址類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/datatype-net-types.html)

`inet` 與 `cidr` 類型映射到 Ruby 的 [`IPAddr`](http://www.ruby-doc.org/stdlib-2.1.1/libdoc/ipaddr/rdoc/IPAddr.html) 物件。`macaddr` 類型映射到一般的 `text` 欄位。

```ruby
# db/migrate/20140508144913_create_devices.rb
create_table(:devices, force: true) do |t|
  t.inet 'ip'
  t.cidr 'network'
  t.macaddr 'address'
end

# app/models/device.rb
class Device < ActiveRecord::Base
end

# Usage
macbook = Device.create(ip: "192.168.1.12",
                        network: "192.168.2.0/24",
                        address: "32:01:16:6d:05:ef")

macbook.ip
# => #<IPAddr: IPv4:192.168.1.12/255.255.255.255>

macbook.network
# => #<IPAddr: IPv4:192.168.2.0/255.255.255.0>

macbook.address
# => "32:01:16:6d:05:ef"
```

### 幾何類型

* [類型定義](http://www.postgresql.org/docs/9.3/static/datatype-geometric.html)

幾何類型映射到一般的 `text` 欄位。

UUID 主鍵
-----------------

NOTE: 需要啟用 `uuid-ossp` 擴充功能才可以產生 UUID。

```ruby
# db/migrate/20131220144913_create_devices.rb
enable_extension 'uuid-ossp' unless extension_enabled?('uuid-ossp')
create_table :devices, id: :uuid, default: 'uuid_generate_v4()' do |t|
  t.string :kind
end

# app/models/device.rb
class Device < ActiveRecord::Base
end

# 用途
device = Device.create
device.id # => "814865cd-5a1d-4771-9306-4268f188fe9e"
```

全文搜索
----------------

```ruby
# db/migrate/20131220144913_create_documents.rb
create_table :documents do |t|
  t.string 'title'
  t.string 'body'
end

execute "CREATE INDEX documents_idx ON documents USING gin(to_tsvector('english', title || ' ' || body));"

# app/models/document.rb
class Document < ActiveRecord::Base
end

# 用途
Document.create(title: "Cats and Dogs", body: "are nice!")

## 所有匹配 `cat & dog` 的文件
Document.where("to_tsvector('english', title || ' ' || body) @@ to_tsquery(?)",
                 "cat & dog")
```

Views
-----


* [建立 View](http://www.postgresql.org/docs/9.3/static/sql-createview.html)

假設需要處理老舊的資料庫，資料表如下：

```
rails_pg_guide=# \d "TBL_ART"
                                        Table "public.TBL_ART"
   Column   |            Type             |                         Modifiers
------------+-----------------------------+------------------------------------------------------------
 INT_ID     | integer                     | not null default nextval('"TBL_ART_INT_ID_seq"'::regclass)
 STR_TITLE  | character varying           |
 STR_STAT   | character varying           | default 'draft'::character varying
 DT_PUBL_AT | timestamp without time zone |
 BL_ARCH    | boolean                     | default false
Indexes:
    "TBL_ART_pkey" PRIMARY KEY, btree ("INT_ID")
```

這張資料表完全沒有遵循 Rails 的慣例。
因為簡單的 PostgreSQL View 預設便可以更新了，可以像下面這樣包起來：

```ruby
# db/migrate/20131220144913_create_articles_view.rb
execute <<-SQL
CREATE VIEW articles AS
  SELECT "INT_ID" AS id,
         "STR_TITLE" AS title,
         "STR_STAT" AS status,
         "DT_PUBL_AT" AS published_at,
         "BL_ARCH" AS archived
  FROM "TBL_ART"
  WHERE "BL_ARCH" = 'f'
  SQL

# app/models/article.rb
class Article < ActiveRecord::Base
  self.primary_key = "id"
  def archive!
    update_attribute :archived, true
  end
end

# Usage
first = Article.create! title: "Winter is coming",
                        status: "published",
                        published_at: 1.year.ago
second = Article.create! title: "Brace yourself",
                         status: "draft",
                         published_at: 1.month.ago

Article.count # => 1
first.archive!
p Article.count # => 2
```

NOTE: 這個應用程式只專注在尚未歸檔的 `Articles`。View 也允許使用條件式，所以我們可以直接排除掉已歸檔的 `Articles`。
