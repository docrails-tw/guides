Active Model Basics
====================

本篇教你如何開始使用 Model。 Active Model 允許 Action Pack 輔助方法與不是 Active Record 的 Model 類別來做互動。Active Model 也允許在 Rails 框架之外自己造 ORM。

讀完本篇，您將了解：

* `AttributeMethods` 模組
* `Callbacks` 模組
* `Conversion` 模組
* `Dirty` 模組
* `Validations` 模組

--------------------------------------------------------------------------------

Active Model 簡介
---------------------

Active Model 是一個函式庫，由許多用來與 Action Pack 互動的模組組成。以下簡單介紹幾個 Active Model 的模組。

### AttributeMethods

用來給方法加上前綴或後綴。

```ruby
class Person
  include ActiveModel::AttributeMethods

  attribute_method_prefix 'reset_'
  attribute_method_suffix '_highest?'
  define_attribute_methods 'age'

  attr_accessor :age

  private
    def reset_attribute(attribute)
      send("#{attribute}=", 0)
    end

    def attribute_highest?(attribute)
      send(attribute) > 100
    end
end

person = Person.new
person.age = 110
person.age_highest?  # true
person.reset_age     # 0
person.age_highest?  # false
```

### 回呼

Active Record 風格的回呼。讓我們可以在運行期定義回呼。定義回呼後便有 `before_*`、`after_*` 與 `around_*` 方法可用。

```ruby
class Person
  extend ActiveModel::Callbacks

  define_model_callbacks :update

  before_update :reset_me

  def update
    run_callbacks(:update) do
      # This method is called when update is called on an object.
    end
  end

  def reset_me
    # This method is called when update is called on an object as a before_update callback is defined.
  end
end
```

### Conversion

如果一個類別有定義 `persisted?` 與 `id` 方法，則你可引入 `Conversion` 模組，並對此類別的物件呼叫 Rails 的 conversion 方法（`to_model`、`to_key`、`to_param`）。

```ruby
class Person
  include ActiveModel::Conversion

  def persisted?
    false
  end

  def id
    nil
  end
end

person = Person.new
person.to_model == person  # => true
person.to_key              # => nil
person.to_param            # => nil
```

### Dirty

物件有一個或多個改動，卻未儲存，則稱物件變“dirty”了。這讓我們可以檢查物件是否有變動。以下是 `Person` 類別，有 `first_name` 與 `last_name` 這兩個屬性：

```ruby
require 'active_model'

class Person
  include ActiveModel::Dirty
  define_attribute_methods :first_name, :last_name

  def first_name
    @first_name
  end

  def first_name=(value)
    first_name_will_change!
    @first_name = value
  end

  def last_name
    @last_name
  end

  def last_name=(value)
    last_name_will_change!
    @last_name = value
  end

  def save
    # do save work...
    changes_applied
  end
end
```

#### 查詢物件修改過屬性的列表

```ruby
person = Person.new
person.changed? # => false

person.first_name = "First Name"
person.first_name # => "First Name"

# returns if any attribute has changed.
person.changed? # => true

# returns a list of attributes that have changed before saving.
person.changed # => ["first_name"]

# returns a hash of the attributes that have changed with their original values.
person.changed_attributes # => {"first_name"=>nil}

# returns a hash of changes, with the attribute names as the keys, and the values will be an array of the old and new value for that field.
person.changes # => {"first_name"=>[nil, "First Name"]}
```

#### Attribute based accessor methods

檢查 `first_name` 這個屬性是否有變動，`first_name_changed?`：

Track whether the particular attribute has been changed or not.

```ruby
# attr_name_changed?
person.first_name # => "First Name"
person.first_name_changed? # => true
```

檢查屬性上一次的數值：
Track what was the previous value of the attribute.

```ruby
# attr_name_was accessor
person.first_name_was # => "First Name"
```

檢查屬性上次與當前的值，有變化回傳 Array，沒變化回傳 `nil`：

```ruby
# attr_name_change
person.first_name_change # => [nil, "First Name"]
person.last_name_change # => nil
```

### 驗證

給類別加入 Active Record 風格的驗證功能：

```ruby
class Person
  include ActiveModel::Validations

  attr_accessor :name, :email, :token

  validates :name, presence: true
  validates_format_of :email, with: /\A([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})\z/i
  validates! :token, presence: true
end

person = Person.new(token: "2b1f325")
person.valid?                        # => false
person.name = 'vishnu'
person.email = 'me'
person.valid?                        # => false
person.email = 'me@vishnuatrai.com'
person.valid?                        # => true
person.token = nil
person.valid?                        # => raises ActiveModel::StrictValidationFailed
```

### ActiveModel::Naming

`Naming` 模組加入幾個幫助管理命名和路由的模組。這個模組定義了 `model_name` 類別方法，這個方法用 `ActiveSupport::Inflector` 定義了許多存取器（accessor）方法。

```ruby
class Person
  extend ActiveModel::Naming
end

Person.model_name.name                # => "Person"
Person.model_name.singular            # => "person"
Person.model_name.plural              # => "people"
Person.model_name.element             # => "person"
Person.model_name.human               # => "Person"
Person.model_name.collection          # => "people"
Person.model_name.param_key           # => "person"
Person.model_name.i18n_key            # => :person
Person.model_name.route_key           # => "people"
Person.model_name.singular_route_key  # => "person"
```
