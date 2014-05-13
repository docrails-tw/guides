客製與新增 Rails 產生器與模版
=====================================================

如有計劃要改善工作流程，Rails 產生器（Generator）是基本工具。本篇教如何建立產生器以及如何客製化 Rails 內建的產生器。

讀完本篇，您將了解：

* 如何看應用程式裡有那些產生器可用。
* 如何用模版建立產生器。
* Rails 如何找到產生器並呼叫它們。
* 如何用新的產生器來客製化鷹架。
* 如何變更產生器模版來客製化鷹架。
* 如何用替代方案避免覆寫一大組產生器。
* 如何新建應用程式模版。

--------------------------------------------------------------------------------

初次接觸
-------------

使用 `rails` 指令時，其實就使用了 Rails 產生器。要查看 Rails 完整的產生器清單，輸入 `rails generate`：

```bash
$ rails new myapp
$ cd myapp
$ rails generate
```

需要特定產生器的詳細說明，可以傳入 `--help`，比如要瀏覽輔助方法產生器的說明：

```bash
$ rails generate helper --help
```

建立第一個產生器
-----------------------------

自 Rails 3.0 起，產生器用 [Thor](https://github.com/erikhuda/thor)
重寫了。Thor 負責解析命令行參數、具有強大的檔案處理 API。輕輕鬆鬆便能打造一個 Generator，如何寫個能在 `config/initializers` 目錄下產生 `initializer` 檔案（`initializer.rb`）的 Generator 呢？

首先新建 `lib/generators/initializer_generator.rb` 檔案，填入如下內容：

```ruby
class InitializerGenerator < Rails::Generators::Base
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

NOTE: `create_file` 是 `Thor::Actions` 提供的方法。`create_file` 及其它 Thor 提供的方法請查閱 [Thor 的 API 文件](http://rdoc.info/github/wycats/thor/master/Thor/Actions.html)。

新的產生器非常簡單：從 `Rails::Generators::Base` 繼承而來，內有一個方法。呼叫產生器時，所有產生器的公有方法會依定義的順序執行。最後，呼叫 `create_file` 方法會在指定的路徑產生出檔案，檔案裡有給定的內容。如熟悉 Rails 應用程式模版的 API，便會感到這兩個 API 其實大同小異。

要呼叫新的產生器，只需要：

```bash
$ rails generate initializer
```

在繼續解說之前，看看剛剛建立出來的產生器的說明文件：

```bash
$ rails generate initializer --help
```
如果產生器放在適當的命名空間，譬如 `ActiveRecord::Generators::ModelGenerator`，Rails 通常可以產生出不錯的指令說明。但這個情況不適用。這個問題有兩個解決辦法，一是使用 `desc` 自己寫說明：

```ruby
class InitializerGenerator < Rails::Generators::Base
  desc "This generator creates an initializer file at config/initializers"
  def create_initializer_file
    create_file "config/initializers/initializer.rb", "# Add initialization content here"
  end
end
```

現在可以使用 `--help` 看到新的說明。第二種新增說明的方法是，在產生器所在的目錄裡面，建立一個叫做 `USAGE` 的檔案。

用現有產生器建立新產生器
-----------------------------------

產生器本身也可以用產生器來產生：

```bash
$ rails generate generator initializer
      create  lib/generators/initializer
      create  lib/generators/initializer/initializer_generator.rb
      create  lib/generators/initializer/USAGE
      create  lib/generators/initializer/templates
```

這是剛建立的產生器：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)
end
```

首先，注意到是繼承自 `Rails::Generators::NamedBase`，而不是 `Rails::Generators::Base`。這表示產生器至少接受一個參數，也就是 `initializer` 的名稱，會存在程式碼的 `name` 變數裡。

可以透過呼叫新的產生器的說明看看（記得先刪除舊的產生器檔案）：

```bash
$ rails generate initializer --help
Usage:
  rails generate initializer NAME [options]
```

新的產生器有一個類別方法：`source_root`。這個方法指向產生器模版的位置，預設是指向 `lib/generators/initializer/templates`。

為了要了解產生器模版是做什麼的，先建立 `lib/generators/initializer/templates/initializer.rb`，並填入以下內容：

```ruby
# Add initialization content here
```

接著修改產生器，使產生器呼叫時，複製這個模版：

```ruby
class InitializerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
  end
end
```

接著執行：

```bash
$ rails generate initializer core_extensions
```

現在可以看到一個 `initializer`，叫做 `core_extensions` 被建立出來了，位置是：`config/initializers/core_extensions.rb`，內容是模版所填之內容。`copy_file` 在 `source_root` 複製檔案到指定的目標路徑。當繼承自 `Rails::Generators::NamedBase` 時，會自動建立 `file_name` 這個方法。

產生器可用的方法在[最後一節](#產生器方法參考手冊)說明。

產生器的查找順序
----------------------

執行 `rails generate initializer core_extensions` 時，Rails 依序 `require` 這些檔案直到找到為止：

```bash
rails/generators/initializer/initializer_generator.rb
generators/initializer/initializer_generator.rb
rails/generators/initializer_generator.rb
generators/initializer_generator.rb
```

若都沒有找到則會回錯誤訊息。

INFO: 上例將檔案放在應用程式的 `lib` 目錄下，因為該目錄屬於 `$LOAD_PATH`。

客製化工作流程
-------------------------

Rails 內建的產生器已經足夠靈活，可以用來客製化鷹架。可以在 `config/application.rb` 裡設定，以下是某些設定的預設值：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: true
end
```

在客製化工作流程之前，先看看預設的鷹架輸出是什麼：

```bash
$ rails generate scaffold User name:string
      invoke  active_record
      create    db/migrate/20140513182748_create_users.rb
      create    app/models/user.rb
      invoke    test_unit
      create      test/models/user_test.rb
      create      test/fixtures/users.yml
      invoke  resource_route
       route    resources :users
      invoke  scaffold_controller
      create    app/controllers/users_controller.rb
      invoke    erb
      create      app/views/users
      create      app/views/users/index.html.erb
      create      app/views/users/edit.html.erb
      create      app/views/users/show.html.erb
      create      app/views/users/new.html.erb
      create      app/views/users/_form.html.erb
      invoke    test_unit
      create      test/controllers/users_controller_test.rb
      invoke    helper
      create      app/helpers/users_helper.rb
      invoke      test_unit
      create        test/helpers/users_helper_test.rb
      invoke    jbuilder
      create      app/views/users/index.json.jbuilder
      create      app/views/users/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/users.js.coffee
      invoke    scss
      create      app/assets/stylesheets/users.css.scss
      invoke  scss
      create    app/assets/stylesheets/scaffolds.css.scss
```

看輸出便很容易可以了解，Rails 的產生器是如何工作的。鷹架產生器實際上沒有產生任何東西，只是去呼叫其它的產生器。我們便可以新增、更換、移除任何產生器的呼叫。譬如，鷹架產生器呼叫 `scaffold_controller`，`scaffold_controller` 在呼叫 `erb`、`test_unit`、`helper` 以及 `jbuilder`。每個產生器各司其職，很輕鬆便可以重複使用，減少重複的程式碼。

對工作流程的第一個客製化，便是讓鷹架停止產生 CSS、JavaScript 以及測試用的假資料。可以透過修改設定檔：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

若使用產生器再產生一次，可以看到沒有建立出 CSS、JavaScripts 以及假資料。若想進一步客製化，譬如使用 DataMapper 與 RSpec 來取代 Active Record 與 TestUnit，只需要將 Gem 加到 Gemfile，並設定產生器即可。

接著來客製化輔助方法產生器，先建立新的輔助方法產生器，這個產生器會幫輔助方法裡的實體變數自動加上 `attr_reader`。首先在 Rails 的命名空間下建立產生器，這樣 Rails 才能找到。

```bash
$ rails generate generator rails/my_helper
      create  lib/generators/rails/my_helper
      create  lib/generators/rails/my_helper/my_helper_generator.rb
      create  lib/generators/rails/my_helper/USAGE
      create  lib/generators/rails/my_helper/templates
```

接著刪掉不會使用到的 `templates` 資料夾，以及產生器的 `source_root` 這行。加入以下方法之後，產生器看起來會像是：

```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
end
    FILE
  end
end
```

可以建立輔助方法，來試試看新的產生器：

```bash
$ rails generate my_helper products
      create  app/helpers/products_helper.rb
```

會在 `app/helpers` 產生出這個輔助方法：

```ruby
module ProductsHelper
  attr_reader :products, :product
end
```

與預期相符，現在可以讓鷹架使用新的輔助方法產生器了。編輯 `config/application.rb`：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
  g.helper          :my_helper
end
```

再產生看看是否用了新加的輔助方法產生器：

```bash
$ rails generate scaffold Post body:text
      [...]
      invoke    my_helper
      create      app/helpers/posts_helper.rb
```

可以看到這裡用了新寫的輔助方法產生器，而不是 Rails 內建的。但還少了一樣東西，產生測試的產生器。使用舊的產生器來修改。

從 Rails 3.0 開始，因為引入了 `hook`，修改測試產生器變得非常簡單。不用綁在一個測試框架上，可以透過 hook，測試框架只需要實作 hook，就可以與 Rails 相容。

將產生器修改為：

```ruby
# lib/generators/rails/my_helper/my_helper_generator.rb
class Rails::MyHelperGenerator < Rails::Generators::NamedBase
  def create_helper_file
    create_file "app/helpers/#{file_name}_helper.rb", <<-FILE
module #{class_name}Helper
  attr_reader :#{plural_name}, :#{plural_name.singularize}
end
    FILE
  end

  hook_for :test_framework
end
```

現在當輔助方法產生器被呼叫時，TestUnit 會被設定成測試框架，會試著執行 `Rails::TestUnitGenerator` 與 `TestUnit::MyHelperGenerator`。由於這兩者都沒有定義，可以跟產生器說，使用 Rails 內建的 `TestUnit::Generators::HelperGenerator` 來取代。將剛剛的 `hook_for` 新增一個 `:as` 選項即可：

```ruby
# Search for :helper instead of :my_helper
hook_for :test_framework, as: :helper
```

現在重新執行鷹架，現在也會產生測試了！

修改產生器模版來客製化工作流程
----------------------------------------------------------

上例我們不過想讓輔助方法產生出的輔助方法多一行程式碼，沒加別的功能。其實還有更簡單的方法可以辦到，換掉 Rails 內建的輔助方法產生器（`Rails::Generators::HelperGenerator`）原生的模版。

Rails 3.0 之後，產生器不僅會在模版的 `source_root` 路徑下尋找，也會在其它路徑下，找看看有沒有模版存在，譬如：`lib/templates`。由於想客製的是 `Rails::Generators::HelperGenerator`，可以透過在 `lib/templates/rails/helper` 目錄下建立 `helper.rb`，填入以下內容：

```erb
module <%= class_name %>Helper
  attr_reader :<%= plural_name %>, :<%= plural_name.singularize %>
end
```

將 `config/application.rb` 上次的修改還原（刪除下面這段）：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :test_unit, fixture: false
  g.stylesheets     false
  g.javascripts     false
end
```

產生新的資源看看，可以看到相同的結果！若想要客製化鷹架模版，譬如想要客製化鷹架建立出來的 `index.html.erb` 與 `edit.html.erb`，在 `lib/templates/erb/scaffold/`，新建 `index.html.erb` 與 `edit.html.erb`，填入想產生的內容即可。

新增產生器的替代方案
---------------------------

產生器最後要加入的功能是替代方案。舉個例子，假設想在 `TestUnit` 加入像是 [shoulda](https://github.com/thoughtbot/shoulda) 的功能。由於 TestUnit 已實作所有 Rails 產生器所需要的方法，而 Shoulda 不過是覆寫某部分功能，不需要為了 Shoulda 重新實作這些產生器，可以告訴 Rails 在 `Shoulda` 命名空間下沒找到產生器時，可以用 `TestUnit` 來代替。

看看怎麼實作，首先打開 `config/application.rb`，修改如下：

```ruby
config.generators do |g|
  g.orm             :active_record
  g.template_engine :erb
  g.test_framework  :shoulda, fixture: false
  g.stylesheets     false
  g.javascripts     false

  # Add a fallback!
  g.fallbacks[:shoulda] = :test_unit
end
```

現在用鷹架新建 `Comment`資源，會看到輸出裡呼叫了 `shoulda` 產生器，最下方替代方案使用了 TestUnit 產生器：

```bash
$ rails generate scaffold Comment body:text
      invoke  active_record
      create    db/migrate/20130924143118_create_comments.rb
      create    app/models/comment.rb
      invoke    shoulda
      create      test/models/comment_test.rb
      create      test/fixtures/comments.yml
      invoke  resource_route
       route    resources :comments
      invoke  scaffold_controller
      create    app/controllers/comments_controller.rb
      invoke    erb
      create      app/views/comments
      create      app/views/comments/index.html.erb
      create      app/views/comments/edit.html.erb
      create      app/views/comments/show.html.erb
      create      app/views/comments/new.html.erb
      create      app/views/comments/_form.html.erb
      invoke    shoulda
      create      test/controllers/comments_controller_test.rb
      invoke    my_helper
      create      app/helpers/comments_helper.rb
      invoke      shoulda
      create        test/helpers/comments_helper_test.rb
      invoke    jbuilder
      create      app/views/comments/index.json.jbuilder
      create      app/views/comments/show.json.jbuilder
      invoke  assets
      invoke    coffee
      create      app/assets/javascripts/comments.js.coffee
      invoke    scss
```

替代方案讓每個產生器各司其職、提高程式碼重用性、減少重複的程式碼。

應用程式模版
---------------------

已經見過如何在應用程式裡使用產生器，這些方法也可以用來產生應用程式。這種產生器叫做“模版”。以下是模版 API 的綜覽。更詳細的文件請參考 [Rails 應用程式模版指南](rails_application_templates.html)。

```ruby
gem "rspec-rails",    group: "test"
gem "cucumber-rails", group: "test"

if yes?("Would you like to install Devise?")
  gem "devise"
  generate "devise:install"
  model_name = ask("What would you like the user model to be called? [user]")
  model_name = "user" if model_name.blank?
  generate "devise", model_name
end
```

上例中我們為產生的 Rails 應用程式新增了兩個 gem（`rspec-rails`、`cucumber-rails`），放在 `test` 群組，會自動加到 `Gemfile`。接著問使用者是否要安裝 Devise？若使用者回答 `y` 或 `yes`，則會把 `gem "devise"` 加到 `Gemfile`，並執行 `devise:install` 產生器，並詢問預設的使用者 Model 名稱為？並產生出該 Model。

現在將上面的程式碼，存成 `template.rb`，便可在 `rails new` 輸入 `-m` 選項來使用這個 Template：

```bash
$ rails new thud -m template.rb
```

這個命令會使用 `template.rb` 來產生 `Thud` 應用程式。

模版不需要存在本機，`-m` 選項也支援線上模版：

```bash
$ rails new thud -m https://gist.github.com/radar/722911/raw/
```

本文最後一節不會介紹如何產生最厲害的模版，而是會走一遍可用的方法有那些，了解之後便可以自己寫出模版。這些方法適用於產生器。

產生器方法參考手冊
-------------------

以下是 Rails 產生器與模版內可用的方法（[原始碼](https://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb)）

NOTE: 本文沒有介紹 Thor 所提供的方法，關於 Thor 提供的方法請查閱 [Thor 的 API 文件](http://rdoc.info/github/wycats/thor/master/Thor/Actions.html)。

### `gem`

指定應用程式依賴的 Gem。

```ruby
gem "rspec", group: "test", version: "2.1.0"
gem "devise", "1.1.5"
```

可用選項有：

* `:group` - The group in the `Gemfile` where this gem should go.
* `:version` - The version string of the gem you want to use. Can also be specified as the second argument to the method.
* `:git` - The URL to the git repository for this gem.

此方法任何其它可能傳入的選項，請放在行尾：

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

以上程式碼會將下行寫入 `Gemfile`:

```ruby
gem "devise", git: "git://github.com/plataformatec/devise", branch: "master"
```

### `gem_group`

把 Gem 放入群組裡：

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### `add_source`

指定 `Gemfile` 使用的來源：

```ruby
add_source "http://gems.github.com"
```

### `inject_into_file`

注入一塊程式碼到檔案指定位置：

```ruby
inject_into_file 'name_of_file.rb', after: "#The code goes below this line. Don't forget the Line break at the end\n" do <<-'RUBY'
  puts "Hello World"
RUBY
end
```

### `gsub_file`

替換檔案裡的文字。

```ruby
gsub_file 'name_of_file.rb', 'method.to_be_replaced', 'method.the_replacing_code'
```

用正規表達式更簡潔。亦可用 `append_file` 及 `prepend_file` 來附加、插入程式碼到檔案裡。

### `application`

在 `config/application.rb` 應用程式類別定義後面，新增一行程式碼。

```ruby
application "config.asset_host = 'http://example.com'"
```

方法也可改寫成區塊形式：

```ruby
application do
  "config.asset_host = 'http://example.com'"
end
```

可用選項有：

* `:env` - 指定這個設定應用的環境。若要使用此選項，推薦使用區塊語法：

```ruby
application(nil, env: "development") do
  "config.asset_host = 'http://localhost:3000'"
end
```

### `git`

執行特定的 `git` 命令：

```ruby
git :init
git add: "."
git commit: "-m First commit!"
git add: "onefile.rb", rm: "badfile.cxx"
```

Hash 的值便是傳給 `git` 命令的值。一次可使用多條 git 命令，__但不保證執行的順序與指定的順序相同__。

### `vendor`

將含有特定程式碼的檔案，放入 `vendor` 目錄。

```ruby
vendor "sekrit.rb", '#top secret stuff'
```

此方法接受區塊參數：

```ruby
vendor "seeds.rb" do
  "puts 'in your app, seeding your database'"
end
```

### `lib`

將含有特定程式碼的檔案，放入 `lib` 目錄。

```ruby
lib "special.rb", "p Rails.root"
```

此方法接受區塊參數：

```ruby
lib "super_special.rb" do
  puts "Super special!"
end
```

### `rakefile`

在應用程式的 `lib/tasks` 新建一個 Rake 檔案：

```ruby
rakefile "test.rake", "hello there"
```

此方法接受區塊參數

```ruby
rakefile "test.rake" do
  %Q{
    task rock: :environment do
      puts "Rockin'"
    end
  }
end
```

### `initializer`

在應用程式的 `config/initializers` 新建一個 `initializer`：

```ruby
initializer "begin.rb", "puts 'this is the beginning'"
```

此方法也接受區塊，並預期回傳字串：

```ruby
initializer "begin.rb" do
  "puts 'this is the beginning'"
end
```

### `generate`

執行特定的產生器，第一個參數為產生器的名字，其餘參數直接傳給產生器。

```ruby
generate "scaffold", "forums title:string description:text"
```

### `rake`

執行特定的 Rake 任務。

```ruby
rake "db:migrate"
```

可用選項有：

* `:env` - 指定執行此 Rake 任務的環境。
* `:sudo` - 是否用 `sudo` 執行此任務，默認是 `false`。

### `capify!`

在應用程式根目錄執行 Capistrano 的 `capify` 指令，會產生出 Capistrano 的設定檔。

```ruby
capify!
```

### `route`

新增一條路由至 `config/routes.rb`：

```ruby
route "resources :people"
```

### `readme`

輸出模版 `source_path` 檔案的內容，通常是 `README`。

```ruby
readme "README"
```
