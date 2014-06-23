Rails 命令列
===========

讀完本篇，您將了解：

* 如何新建 Rails 應用程式。
* 如何產生 Models、Controllers、資料庫遷移以及單元測試。
* 如何啟動開發伺服器。
* 如何用互動的 Shell 來實驗物件。
* 如何測量應用程式的瓶頸。

--------------------------------------------------------------------------------

NOTE: 本文假設你已閱讀 [Rails 起步走](getting_started.html)並有基礎的 Rails 知識。

命令列基礎
-------------------

有幾個開發 Rails 每天都會用到的命令。以下按常見的使用順序排列：

* `rails console`
* `rails server`
* `rake`
* `rails generate`
* `rails dbconsole`
* `rails new app_name`

每個命令都可以傳入 `-h` 或 `--help` 來列出更多資訊。

首先建立一個簡單的 Rails 應用程式，用來講解這些命令。

### `rails new`

通常安裝 Rails 之後，第一個會用到的命令是 `rails new`，用來新建 Rails 應用程式。

INFO: 可以使用 `gem install rails` 來安裝 Rails。

```bash
$ rails new commandsapp
     create
     create  README.rdoc
     create  Rakefile
     create  config.ru
     create  .gitignore
     create  Gemfile
     create  app
     ...
     create  tmp/cache
     ...
        run  bundle install
```

才一個命令，Rails 就建立了這麼多東西！有了這些產生出來的東西之後，就可以試著把伺服器跑起來了。

### `rails server`

`rails server` 命令會啟動一個小型的網路伺服器，叫做 WEBrick，是 Ruby 內建的伺服器。想要在瀏覽器存取 Rails 應用程式，使用 `rails server` 來啟動伺服器。

`rails server` 會啟動剛剛新產生出來的 Rails 應用程式：

```bash
$ cd commandsapp
$ bin/rails server
=> Booting WEBrick
=> Rails 4.2.0 application starting in development on http://0.0.0.0:3000
=> Run `rails server -h` for more startup options
=> Notice: server is listening on all interfaces (0.0.0.0). Consider using 127.0.0.1 (--binding option)
=> Ctrl-C to shutdown server
[2014-06-14 06:51:39] INFO  WEBrick 1.3.1
[2014-06-14 06:51:39] INFO  ruby 2.1.2 (2014-05-08) [x86_64-darwin13.0]
[2014-06-14 06:51:39] INFO  WEBrick::HTTPServer#start: pid=60314 port=3000
```

只用了三個命令，便能把 Rails 在埠口 3000 跑起來了。開啟瀏覽器並瀏覽 [http://localhost:3000](http://localhost:3000)，會看到簡單的 Rails 應用程式正在執行。

INFO: 也可以使用縮寫 `s` 來啟動伺服器：`rails s`。

伺服器可以跑在不同的埠口，使用 `-p` 選項。而環境可以使用 `-e` 更改。

```bash
$ bin/rails server -e production -p 4000
```

`-b` 選項可以把 Rails 綁定在特定的 IP，預設 IP 是 `0.0.0.0`。`-d` 選項可以把伺服器放在背景裡執行（daemon）。

### `rails generate`

`rails generate` 命令使用模版來產生很多東西。執行 `rails generate`，會看到所有可用的產生器。

INFO: 也可以使用別名 `g` 來使用產生器命令：`rails g`。

```bash
$ bin/rails generate
Usage: rails generate GENERATOR [args] [options]

General options:
  -h, [--help]     # Print generator's options and usage
  ...

Please choose a generator below.

Rails:
  assets
  controller
  generator
  ...
  ...
```

NOTE: 透過 Gems 還能安裝更多產生器、插件，甚至可以建立自己的產生器！

使用產生器會節省許多撰寫“樣板程式”的時間。

讓我們來自己建立產生 Controller 的產生器。該怎麼產生“產生器”？問問便知：

INFO: 和所有的 *nix 工具一樣，所有的 Rails 子命令都有說明文件。在命令最後加上 `--help` 或 `-h` 試試看，譬如 `rails server --help`。

```bash
$ bin/rails generate controller
Usage: rails generate controller NAME [action action] [options]

...
...

Description:
    ...

    To create a controller within a module, specify the controller name as a path like 'parent_module/controller_name'.

    ...

Example:
    `rails generate controller CreditCards open debit credit close`

    Credit card controller with URLs like /credit_cards/debit.
        Controller: app/controllers/credit_card_controller.rb
        Test:       test/controllers/credit_cards_controller_test.rb
        Views:      app/views/credit_cards/debit.html.erb [...]
        Helper:     app/helpers/credit_cards_helper.rb
```

從上可知 Controller 產生器預期參數形式為 `generate controller ControllerName action1 action2`。接著建立一個 `Greetings` Controller，內有一個會打招呼的 `hello` 動作。

```bash
$ bin/rails generate controller Greetings hello
     create  app/controllers/greetings_controller.rb
      route  get 'greetings/hello'
     invoke  erb
     create    app/views/greetings
     create    app/views/greetings/hello.html.erb
     invoke  test_unit
     create    test/controllers/greetings_controller_test.rb
     invoke  helper
     create    app/helpers/greetings_helper.rb
     invoke    test_unit
     create      test/helpers/greetings_helper_test.rb
     invoke  assets
     invoke    coffee
     create      app/assets/javascripts/greetings.js.coffee
     invoke    scss
     create      app/assets/stylesheets/greetings.css.scss
```

產生出來的這些檔案是什麼？在應用程式裡建了許多資料夾，建了 Controller、View、功能性測試、View 的輔助方法、JavaScript 以及樣式表。

打開 Controller 並稍微修改一下 (in `app/controllers/greetings_controller.rb`)：

```ruby
class GreetingsController < ApplicationController
  def hello
    @message = "Hello, how are you today?"
  end
end
```

接著修改 View，顯示訊息（`app/views/greetings/hello.html.erb`）：

```erb
<h1>A Greeting for You!</h1>
<p><%= @message %></p>
```

啟動伺服器 `rails server`：

```bash
$ bin/rails server
=> Booting WEBrick...
```

網址是 [http://localhost:3000/greetings/hello](http://localhost:3000/greetings/hello)。

INFO: Rails 應用程式的網址的模式是 `http://(host)/(controller)/(action)`，而像是 `http://(host)/(controller)` 的網址，會觸發 Controller 的 `index` 動作。

Rails 也有產生 Model 之用的產生器。

```bash
$ bin/rails generate model
Usage:
  rails generate model NAME [field[:type][:index] field[:type][:index]] [options]

...

Active Record options:
      [--migration]            # Indicates when to generate migration
                               # Default: true

...

Description:
    Create rails files for model generator.

...

Available field types:

...
```

NOTE: 所有可用的欄位類型，請參考 [API 文件](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html#method-i-column) `TableDefinition` 類別的 `column` 方法。

但與其直接產生 Model，先用鷹架試試。Rails 的鷹架是用來產生一組完整的 Model、遷移、Controller、View 以及測試。

產生一個簡單的資源叫做 “HighScore”，用來追蹤電玩遊戲的最高分。

```bash
$ bin/rails generate scaffold HighScore game:string score:integer
    invoke  active_record
    create    db/migrate/20140613231642_create_high_scores.rb
    create    app/models/high_score.rb
    invoke    test_unit
    create      test/models/high_score_test.rb
    create      test/fixtures/high_scores.yml
    invoke  resource_route
     route    resources :high_scores
    invoke  scaffold_controller
    create    app/controllers/high_scores_controller.rb
    invoke    erb
    create      app/views/high_scores
    create      app/views/high_scores/index.html.erb
    create      app/views/high_scores/edit.html.erb
    create      app/views/high_scores/show.html.erb
    create      app/views/high_scores/new.html.erb
    create      app/views/high_scores/_form.html.erb
    invoke    test_unit
    create      test/controllers/high_scores_controller_test.rb
    invoke    helper
    create      app/helpers/high_scores_helper.rb
    invoke      test_unit
    create        test/helpers/high_scores_helper_test.rb
    invoke    jbuilder
    create      app/views/high_scores/index.json.jbuilder
    create      app/views/high_scores/show.json.jbuilder
    invoke  assets
    invoke    coffee
    create      app/assets/javascripts/high_scores.js.coffee
    invoke    scss
    create      app/assets/stylesheets/high_scores.css.scss
    invoke  scss
    create    app/assets/stylesheets/scaffolds.css.scss
```

產生器會建立 HighScroe 資源所需的所有檔案，包含了 Controller、Model、Model 的遷移檔案、輔助方法、Assets（JavaScript、CSS）、設定路由，以及所有的測試檔案（Controller、Model、輔助方法的測試）。

遷移檔案產生出來之後，需要手動進行執行“遷移”，也就是執行 `20130717151933_create_high_scores.rb` 檔案裡的 Ruby 程式碼，用來修改資料庫的綱要檔案。修改那個資料庫？執行 `rake db:migrate` 命令，Rails 會建立一個 SQLite3 資料庫。稍後會再詳細介紹 Rake。

```bash
$ bin/rake db:migrate
==  CreateHighScores: migrating ===============================================
-- create_table(:high_scores)
   -> 0.0017s
==  CreateHighScores: migrated (0.0019s) ======================================
```

INFO: 介紹一下單元測試。單元測試是用來測試、檢查邏輯的程式。在單元測試裡，從小部分的程式下手，譬如 Model 的一個方法，測試輸入輸出。單元測試是你的好朋友。很快你就會發現到，當你有對程式做單元測試，生活的品質便會提高了許多。我說真的，稍後寫一個單元測試做示範。


首先看一下 Rails 建立的介面。

```bash
$ bin/rails server
```

到瀏覽器打開 [http://localhost:3000/high_scores](http://localhost:3000/high_scores)，現在可以建立新的高分了（太空侵略者的最高分是 55160 分）

### `rails console`

`console` 命令可以從命令列跟 Rails 應用程式互動。`rails console` 背後用的是 IRB，有用過 IRB 的話，一定會感到很熟悉。可以用來快速驗證想法、不到網站便可修改伺服器上的資料等。

INFO: 也可以使用別名 `c` 來啟動伺服器：`rails c`。

指定 `console` 命令要運行的環境。

```bash
$ bin/rails console staging
```

若想測試而不想修改到資料，可以使用 `rails console --sandbox`。

```bash
$ bin/rails console --sandbox
Loading development environment in sandbox (Rails 4.0.0)
Any modifications you make will be rolled back on exit
irb(main):001:0>
```

#### `app` 與 `helper` 物件

在 `rails console` 裡，有兩個實體可以存取：`app` 與 `helper`。

`app` 可以存取網址與路徑的輔助方法，也可以發送請求。

```bash
>> app.root_path
=> "/"

>> app.get _
Started GET "/" for 127.0.0.1 at 2014-06-19 10:41:57 -0300
...
```

而 `helper` 方法可以存取應用程式裡的輔助方法。

```bash
>> helper.time_ago_in_words 30.days.ago
=> "about 1 month"

>> helper.my_custom_helper
=> "my custom helper"
```

### `rails dbconsole`

`rails dbconsole` 知道正在使用的資料庫，打開每個資料庫的命令列介面（也能接受傳給命令列的參數哦！）支援 MySQL、PostgreSQL、SQLite 以及 SQLite3。

INFO: 別名 `db`，`rails db`。

### `rails runner`

`runner` 在 Rails 的上下文裡執行 Ruby 程式碼。譬如：

```bash
$ bin/rails runner "Model.long_running_method"
```

INFO: 別名 `r`，`rails r`。

可以使用 `-e` 指定命令執行的環境。

```bash
$ bin/rails runner -e staging "Model.long_running_method"
```

### `rails destroy`

可以把 `destroy` 想成是 `generate` 的反操作。`destroy` 會研究出 `generate` 做了什麼，並復原。

INFO: 別名 `d`，`rails d`。

```bash
$ bin/rails generate model Oops
      invoke  active_record
      create    db/migrate/20120528062523_create_oops.rb
      create    app/models/oops.rb
      invoke    test_unit
      create      test/models/oops_test.rb
      create      test/fixtures/oops.yml
```
```bash
$ bin/rails destroy model Oops
      invoke  active_record
      remove    db/migrate/20120528062523_create_oops.rb
      remove    app/models/oops.rb
      invoke    test_unit
      remove      test/models/oops_test.rb
      remove      test/fixtures/oops.yml
```

Rake
----

Rake 是 Ruby 的 “Make”，獨立的 Ruby 工具，用來取代 Unix 的 make。Rake 使用 `Rakefile` 與 `.rake` 檔案來撰寫一系列的任務。在 Rails，Rake 用來做一些管理的任務，特別是相互之間有關聯、又複雜的管理任務。

可以輸入 `rake --tasks` 來獲得這個 Rails 應用程式所有可用的任務清單，應該可以找到需要用的任務。

要獲得執行 Rake 任務完整的 Backtrace，可以傳入 `--trace` 選項，譬如：`rake db:create --trace`。

```bash
$ bin/rake --tasks
rake about              # 列出整個 Rails 框架與環境的版本
rake assets:clean       # 移除過時已編譯過的 Assets
rake assets:clobber     # 移除編譯過的 Assets
rake assets:precompile  # 編譯所有在 config.assets.precompile 所指定的 Assets
rake db:create          # 根據 config/database.yml 給目前的 Rails.env 環境建立資料庫
...
rake log:clear          # 刪掉 log/ 目錄下所有的 *.log 檔案（可以用 LOGS 選項指定要刪除那個環境的記錄檔，譬如 LOGS=test,development）。
rake middleware         # 印出所有的 Rack 中間件
...
rake tmp:clear          # 清空 tmp/ 目錄下的 Session、快取以及 Socket 檔案。（清除單一個請用 tmp:sessions:clear、tmp:cache:clear、tmp:sockets:clear）
rake tmp:create         # 建立 tmp/ 目錄，用來存放 Session、快取、Socket 以及 pid 等資料。
```

INFO: `rake --tasks` 縮寫為 `rake -T`。

### `about`

`rake about` 會輸出關於 Ruby、RubyGems、Rails、Rails 各個元件的版本、Middleware、應用程式根目錄、目前的 Rails 環境、資料庫連接器以及資料庫綱要的版本。在需要知道現有 Rails 的一些資料的情況下很有用，比如檢查某個安全性補丁有沒有影響到正在使用的版本。

```bash
$ bin/rake about
About your application's environment
Ruby version              2.1.2-p95 (x86_64-darwin13.0)
RubyGems version          2.3.0
Rack version              1.5
Rails version             4.2.0
JavaScript Runtime        Node.js (V8)
Active Record version     4.2.0
Action Pack version       4.2.0
Action View version       4.2.0
Action Mailer version     4.2.0
Active Support version    4.2.0
Active Model version      4.2.0
Middleware                Rack::Sendfile, ActionDispatch::Static, Rack::Lock, #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x007fe45ae964e8>, Rack::Runtime, Rack::MethodOverride, ActionDispatch::RequestId, Rails::Rack::Logger, ActionDispatch::ShowExceptions, ActionDispatch::DebugExceptions, ActionDispatch::RemoteIp, ActionDispatch::Reloader, ActionDispatch::Callbacks, ActiveRecord::Migration::CheckPending, ActiveRecord::ConnectionAdapters::ConnectionManagement, ActiveRecord::QueryCache, ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, ActionDispatch::Flash, ActionDispatch::ParamsParser, Rack::Head, Rack::ConditionalGet, Rack::ETag
Application root          /Users/Juan/play/gitapp
Environment               development
Database adapter          postgresql
Database schema version   0
```

### `assets`

使用 `rake assets:precompile` 來預編譯 `app/assets` 下的 Assets 檔案，`rake assets:clean` 會刪除編譯過的 Assets 檔案。`assets:clean` 任務允許在部署時編譯新的 Asset 時，仍使用先前編譯過的 Assets 檔案。

若想完整清空 `public/assets`，可以使用 `rake assets:clobber`。

### `db`

`db:` 命名空間下最常使用的任務是 `migrate` 與 `create`。這兩個任務會試著執行所有遷移相關的 Rake 任務（`up`、`down`、`redo`、`reset`）。`rake db:version` 在除錯時有用，會告訴你當前資料庫的版本號是多少。

更多遷移有關的資料，請閱讀 [Active Record 遷移](migrations.html)指南。

### `doc`

`doc:` 命名空間下有用來給應用程式產生文件的任務，API 文件、指南等。文件可以從應用程式裡拿掉，減少整個程式的大小，比如在嵌入式平台上撰寫 Rails 應用程式。

* `rake doc:app` 為應用程式產生文件，放在 `doc/app`。
* `rake doc:guides` 產生 Rails 指南，放在 `doc/guides`。
* `rake doc:rails` 產生 API 文件，放在 `doc/api`。

### `notes`

`rake notes` 會到程式碼裡尋找是否有以 `FIXME`、`OPTIMIZE` 或 `TODO` 開頭的註解。會搜索這些副檔名的檔案：`.builder`、`.rb`、`.rake`、`.yml`、`.yaml`、`.ruby`、`.css`、`.js` 以及 `.erb`。會同時搜索預設的註解，以及自訂的註解。

```bash
$ bin/rake notes
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [ 20] [TODO] any other way to do this?
  * [132] [FIXME] high priority for next deploy

app/models/school.rb:
  * [ 13] [OPTIMIZE] refactor this code to make it faster
  * [ 17] [FIXME]
```

可以使用 `config.annotations.register_extensions` 選項新增要搜尋的副檔名。選項接受一組副檔名，區塊內放實際搜尋的正則表達式。

```ruby
config.annotations.register_extensions("scss", "sass", "less") { |annotation| /\/\/\s*(#{annotation}):?\s*(.*)$/ }
```

若要搜尋特定的註解，譬如 `FIXME`，可以使用 `rake notes:fixme`。

```bash
$ bin/rake notes:fixme
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [132] high priority for next deploy

app/models/school.rb:
  * [ 17]
```

也可以在程式裡使用自訂的註解，並用 `rake notes:custom` 來搜尋，要搜尋的註解使用環境變數 `ANNOTATION` 來指定。

```bash
$ bin/rake notes:custom ANNOTATION=BUG
(in /home/foobar/commandsapp)
app/models/article.rb:
  * [ 23] Have to fix this one before pushing!
```

NOTE: 使用自訂註解時，搜尋結果不會顯示註解的名稱（例如 BUG、FIXME 等）。

`rake notes` 預設會在 `app`、`config`、`lib`、`bin` 以及 `test` 目錄下搜尋。若想搜尋其它目錄，可以使用 `SOURCE_ANNOTATION_DIRECTORIES` 來指定，目錄之間以逗號區隔。

```bash
$ export SOURCE_ANNOTATION_DIRECTORIES='spec,vendor'
$ bin/rake notes
(in /home/foobar/commandsapp)
app/models/user.rb:
  * [ 35] [FIXME] User should have a subscription at this point
spec/models/user_spec.rb:
  * [122] [TODO] Verify the user that has a subscription works
```

### `routes`

`rake routes` 會列出所有定義的路由，可以用來追蹤有關路由的問題，或是在需要熟習 Rails 時，綜覽一下整個 Rails 應用程式裡的路由。

### `test`

INFO: 關於單元測試，請閱讀 [Rails 測試指南](testing.html)。

Rails 內建了叫做 Minitest 的測試套裝。Rails 本身也是使用 Minitest 做測試。`test:` 命名空間下的任務可用來執行各種測試。

### `tmp`

`Rails.root/tmp` 目錄和 *nix 的 `/tmp` 目錄的作用相同，用來存放像是 Session 等的暫存檔案（如果 Session 是用檔案來存的話）、進程的 ID 檔案、快取檔案等。

`tmp:` 命名空間下的任務可以清理、新建 `Rails.root/tmp` 目錄：

* `rake tmp:cache:clear` 清空 `tmp/cache`。
* `rake tmp:sessions:clear` 清空 `tmp/sessions`。
* `rake tmp:sockets:clear` 清空 `tmp/sockets`。
* `rake tmp:clear` 完整清空這三個目錄：`cache`、`sessions` 以及 sockets。
* `rake tmp:create` 給 sessions、cache、sockets 以及 pids 新建臨時目錄。

### 其它

* `rake stats` is great for looking at statistics on your code, displaying things like KLOCs (thousands of lines of code) and your code to test ratio.
* `rake secret` will give you a pseudo-random key to use for your session secret.
* `rake time:zones:all` lists all the timezones Rails knows about.

### 自訂 Rake 任務

Custom rake tasks have a `.rake` extension and are placed in
`Rails.root/lib/tasks`. You can create these custom rake tasks with the
`bin/rails generate task` command.

```ruby
desc "I am short, but comprehensive description for my cool task"
task task_name: [:prerequisite_task, :another_task_we_depend_on] do
  # All your magic here
  # Any valid Ruby code is allowed
end
```

傳入參數給自訂的 Rake 任務：

```ruby
task :task_name, [:arg_1] => [:pre_1, :pre_2] do |t, args|
  # You can use args from here
end
```

把相同任務放在命名空間下管理：

```ruby
namespace :db do
  desc "This task does nothing"
  task :nothing do
    # Seriously, nothing
  end
end
```

使用命名空間下的任務：

```bash
$ bin/rake task_name
$ bin/rake "task_name[value 1]" # entire argument string should be quoted
$ bin/rake db:nothing
```

NOTE: 如需與應用程式的 Model 互動、進行資料庫查詢等操作，任務需要依賴於 `environment` 任務，`environment` 任務 會載入應用程式的程式進來。

進階命令列
---------

命令列更進階的用途主要在如何找到每個工具有用的選項，找到符合需求的選項，結合到工作流程裡。以下列出一些小撇步。

### Rails 與資料庫、原始碼管理系統

建立新的 Rails 應用程式時，可以指定要使用的資料庫與原始碼管理系統。可以省下一點打字的時間。

看看 `--git` 與 `--database=postgresql` 選項可以幹嘛：

```bash
$ mkdir gitapp
$ cd gitapp
$ git init
Initialized empty Git repository in .git/
$ rails new . --git --database=postgresql
      exists
      create  app/controllers
      create  app/helpers
...
...
      create  tmp/cache
      create  tmp/pids
      create  Rakefile
add 'Rakefile'
      create  README.rdoc
add 'README.rdoc'
      create  app/controllers/application_controller.rb
add 'app/controllers/application_controller.rb'
      create  app/helpers/application_helper.rb
...
      create  log/test.log
add 'log/test.log'
```

必須要在使用 `rails new . --git --database=postgresql` 命令之前先建立一個空的資料夾，並做 `git init`。看看資料庫設定檔的內容：

```bash
$ cat config/database.yml
# PostgreSQL. Versions 8.2 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On OS X with Homebrew:
#   gem install pg -- --with-pg-config=/usr/local/bin/pg_config
# On OS X with MacPorts:
#   gem install pg -- --with-pg-config=/opt/local/lib/postgresql84/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem 'pg'
#
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see rails configuration guide
  # http://guides.rubyonrails.org/configuring.html#database-pooling
  pool: 5

development:
  <<: *default
  database: gitapp_development
...
...
```

會根據 PostgreSQL 產生相關的設定到 `database.yml`。

NOTE: 指定原始碼管理系統要注意先建立資料夾、初始化，接著才執行 `rails new` 命令。
