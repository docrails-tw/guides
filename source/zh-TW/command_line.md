Rails 命令列
===========

讀完本篇，您將了解：

* 如何新建 Rails 應用程式。
* 如何產生 models、controllers、資料庫 migrations、單元測試。
* 如何啟動開發伺服器。
* 如何用互動的 Shell 來實驗物件。
* 如何測量應用程式的瓶頸。

--------------------------------------------------------------------------------

NOTE: 本文假設你已閱讀[Rails 起步走](getting_started.html)並有基礎的 Rails 知識。

命令列基礎
-------------------

Rails 開發有幾個每天都會用到的命令。以下按照通常的使用順序排列：

* `rails console`
* `rails server`
* `rake`
* `rails generate`
* `rails dbconsole`
* `rails new app_name`

每個命令都可以傳入 ```-h or --help``` 來列出更多資訊。

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

`rails server` 命令會啟動一個小型的網路伺服器，叫做 WEBrick，是 Ruby 內建的伺服器。想要在瀏覽器存取應用程式，就要使用 `rails server` 來啟動伺服器。

`rails server` 會啟動剛剛新產生出來的 Rails 應用程式：

```bash
$ cd commandsapp
$ bin/rails server
=> Booting WEBrick
=> Rails 4.1.2 application starting in development on http://0.0.0.0:3000
=> Run `rails server -h` for more startup options
=> Notice: server is listening on all interfaces (0.0.0.0). Consider using 127.0.0.1 (--binding option)
=> Ctrl-C to shutdown server
[2014-06-14 06:51:39] INFO  WEBrick 1.3.1
[2014-06-14 06:51:39] INFO  ruby 2.1.2 (2014-05-08) [x86_64-darwin13.0]
[2014-06-14 06:51:39] INFO  WEBrick::HTTPServer#start: pid=60314 port=3000
```

僅使用了三個命令，便能把 Rails 在埠口 3000 跑起來了。開啟瀏覽器並瀏覽 [http://localhost:3000](http://localhost:3000)，會看到 Rails 正在執行。

INFO: 也可以使用縮寫 `s` 來啟動伺服器：`rails s`。

伺服器可以跑在不同的埠口，使用 `-p` 選項。而預設的開發環境可以使用 `-e` 更改。

```bash
$ bin/rails server -e production -p 4000
```

`-b` 選項可把 Rails 綁定到特定的 IP，預設是 `0.0.0.0`。`-d` 選項可以把伺服器放在背景裡執行（daemon）。

### `rails generate`

`rails generate` 命令使用模版來產生一大堆東西。執行 `rails generate` 可以看到所有可用的產生器。

INFO: 也可以使用縮寫 `g` 來使用產生器命令：`rails g`。

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

INFO: 和所有的 *nix 工具一樣，所有的 Rails 子命令都有說明文件。可以在命令最後加上 `--help` 或 `-h` 試試看，譬如 `rails server --help`。

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

從上可知 Controller 產生器預期參數形式為 `generate controller ControllerName action1 action2`。讓我們建立一個 `Greetings` Controller，內有 `hello` 動作，會說些好聽的話。

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

這些是怎麼產生的？建了許多資料夾，建了 Controller、View、功能性測試、View 的輔助方法、JavaScript 以及樣式表。

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

INFO: Rails 應用程式 URL 通常會遵循這個模式 `http://(host)/(controller)/(action)`，而 URL 像是 `http://(host)/(controller)` 會觸發該 Controller 的 `index` 動作。

Rails 也有產生 Model 的產生器。

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

但與其直接產生 Model，讓我們來設定一個鷹架。Rails 的鷹架是用來產生一組完整的 Model、遷移、Controller、View 以及測試。

產生一個簡單的資源叫做 “HighScore”，用來追蹤玩過的電玩遊戲的最高分。

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


The generator checks that there exist the directories for models, controllers, helpers, layouts, functional and unit tests, stylesheets, creates the views, controller, model and database migration for HighScore (creating the `high_scores` table and fields), takes care of the route for the **resource**, and new tests for everything.

The migration requires that we **migrate**, that is, run some Ruby code (living in that `20130717151933_create_high_scores.rb`) to modify the schema of our database. Which database? The SQLite3 database that Rails will create for you when we run the `rake db:migrate` command. We'll talk more about Rake in-depth in a little while.

```bash
$ bin/rake db:migrate
==  CreateHighScores: migrating ===============================================
-- create_table(:high_scores)
   -> 0.0017s
==  CreateHighScores: migrated (0.0019s) ======================================
```

INFO: Let's talk about unit tests. Unit tests are code that tests and makes assertions about code. In unit testing, we take a little part of code, say a method of a model, and test its inputs and outputs. Unit tests are your friend. The sooner you make peace with the fact that your quality of life will drastically increase when you unit test your code, the better. Seriously. We'll make one in a moment.

Let's see the interface Rails created for us.

```bash
$ bin/rails server
```

Go to your browser and open [http://localhost:3000/high_scores](http://localhost:3000/high_scores), now we can create new high scores (55,160 on Space Invaders!)

### `rails console`

The `console` command lets you interact with your Rails application from the command line. On the underside, `rails console` uses IRB, so if you've ever used it, you'll be right at home. This is useful for testing out quick ideas with code and changing data server-side without touching the website.

INFO: You can also use the alias "c" to invoke the console: `rails c`.

You can specify the environment in which the `console` command should operate.

```bash
$ bin/rails console staging
```

If you wish to test out some code without changing any data, you can do that by invoking `rails console --sandbox`.

```bash
$ bin/rails console --sandbox
Loading development environment in sandbox (Rails 4.0.0)
Any modifications you make will be rolled back on exit
irb(main):001:0>
```

### `rails dbconsole`

`rails dbconsole` figures out which database you're using and drops you into whichever command line interface you would use with it (and figures out the command line parameters to give to it, too!). It supports MySQL, PostgreSQL, SQLite and SQLite3.

INFO: You can also use the alias "db" to invoke the dbconsole: `rails db`.

### `rails runner`

`runner` runs Ruby code in the context of Rails non-interactively. For instance:

```bash
$ bin/rails runner "Model.long_running_method"
```

INFO: You can also use the alias "r" to invoke the runner: `rails r`.

You can specify the environment in which the `runner` command should operate using the `-e` switch.

```bash
$ bin/rails runner -e staging "Model.long_running_method"
```

### `rails destroy`

Think of `destroy` as the opposite of `generate`. It'll figure out what generate did, and undo it.

INFO: You can also use the alias "d" to invoke the destroy command: `rails d`.

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

Rake is Ruby Make, a standalone Ruby utility that replaces the Unix utility 'make', and uses a 'Rakefile' and `.rake` files to build up a list of tasks. In Rails, Rake is used for common administration tasks, especially sophisticated ones that build off of each other.

You can get a list of Rake tasks available to you, which will often depend on your current directory, by typing `rake --tasks`. Each task has a description, and should help you find the thing you need.

To get the full backtrace for running rake task you can pass the option
```--trace``` to command line, for example ```rake db:create --trace```.

```bash
$ bin/rake --tasks
rake about              # List versions of all Rails frameworks and the environment
rake assets:clean       # Remove old compiled assets
rake assets:clobber     # Remove compiled assets
rake assets:precompile  # Compile all the assets named in config.assets.precompile
rake db:create          # Create the database from config/database.yml for the current Rails.env
...
rake log:clear          # Truncates all *.log files in log/ to zero bytes (specify which logs with LOGS=test,development)
rake middleware         # Prints out your Rack middleware stack
...
rake tmp:clear          # Clear session, cache, and socket files from tmp/ (narrow w/ tmp:sessions:clear, tmp:cache:clear, tmp:sockets:clear)
rake tmp:create         # Creates tmp directories for sessions, cache, sockets, and pids
```
INFO: You can also use ```rake -T```  to get the list of tasks.

### `about`

`rake about` gives information about version numbers for Ruby, RubyGems, Rails, the Rails subcomponents, your application's folder, the current Rails environment name, your app's database adapter, and schema version. It is useful when you need to ask for help, check if a security patch might affect you, or when you need some stats for an existing Rails installation.

```bash
$ bin/rake about
About your application's environment
Ruby version              1.9.3 (x86_64-linux)
RubyGems version          1.3.6
Rack version              1.3
Rails version             4.1.1
JavaScript Runtime        Node.js (V8)
Active Record version     4.1.1
Action Pack version       4.1.1
Action View version       4.1.1
Action Mailer version     4.1.1
Active Support version    4.1.1
Middleware                Rack::Sendfile, ActionDispatch::Static, Rack::Lock, #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x007ffd131a7c88>, Rack::Runtime, Rack::MethodOverride, ActionDispatch::RequestId, Rails::Rack::Logger, ActionDispatch::ShowExceptions, ActionDispatch::DebugExceptions, ActionDispatch::RemoteIp, ActionDispatch::Reloader, ActionDispatch::Callbacks, ActiveRecord::Migration::CheckPending, ActiveRecord::ConnectionAdapters::ConnectionManagement, ActiveRecord::QueryCache, ActionDispatch::Cookies, ActionDispatch::Session::CookieStore, ActionDispatch::Flash, ActionDispatch::ParamsParser, Rack::Head, Rack::ConditionalGet, Rack::ETag
Application root          /home/foobar/commandsapp
Environment               development
Database adapter          sqlite3
Database schema version   20110805173523
```

### `assets`

You can precompile the assets in `app/assets` using `rake assets:precompile`,
and remove older compiled assets using `rake assets:clean`. The `assets:clean`
task allows for rolling deploys that may still be linking to an old asset while
the new assets are being built.

If you want to clear `public/assets` completely, you can use `rake assets:clobber`.

### `db`

The most common tasks of the `db:` Rake namespace are `migrate` and `create`, and it will pay off to try out all of the migration rake tasks (`up`, `down`, `redo`, `reset`). `rake db:version` is useful when troubleshooting, telling you the current version of the database.

More information about migrations can be found in the [Migrations](migrations.html) guide.

### `doc`

The `doc:` namespace has the tools to generate documentation for your app, API documentation, guides. Documentation can also be stripped which is mainly useful for slimming your codebase, like if you're writing a Rails application for an embedded platform.

* `rake doc:app` generates documentation for your application in `doc/app`.
* `rake doc:guides` generates Rails guides in `doc/guides`.
* `rake doc:rails` generates API documentation for Rails in `doc/api`.

### `notes`

`rake notes` will search through your code for comments beginning with FIXME, OPTIMIZE or TODO. The search is done in files with extension `.builder`, `.rb`, `.rake`, `.yml`, `.yaml`, `.ruby`, `.css`, `.js` and `.erb` for both default and custom annotations.

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

You can add support for new file extensions using `config.annotations.register_extensions` option, which receives a list of the extensions with its corresponding regex to match it up.

```ruby
config.annotations.register_extensions("scss", "sass", "less") { |annotation| /\/\/\s*(#{annotation}):?\s*(.*)$/ }
```

If you are looking for a specific annotation, say FIXME, you can use `rake notes:fixme`. Note that you have to lower case the annotation's name.

```bash
$ bin/rake notes:fixme
(in /home/foobar/commandsapp)
app/controllers/admin/users_controller.rb:
  * [132] high priority for next deploy

app/models/school.rb:
  * [ 17]
```

You can also use custom annotations in your code and list them using `rake notes:custom` by specifying the annotation using an environment variable `ANNOTATION`.

```bash
$ bin/rake notes:custom ANNOTATION=BUG
(in /home/foobar/commandsapp)
app/models/article.rb:
  * [ 23] Have to fix this one before pushing!
```

NOTE. When using specific annotations and custom annotations, the annotation name (FIXME, BUG etc) is not displayed in the output lines.

By default, `rake notes` will look in the `app`, `config`, `lib`, `bin` and `test` directories. If you would like to search other directories, you can provide them as a comma separated list in an environment variable `SOURCE_ANNOTATION_DIRECTORIES`.

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

`rake routes` will list all of your defined routes, which is useful for tracking down routing problems in your app, or giving you a good overview of the URLs in an app you're trying to get familiar with.

### `test`

INFO: A good description of unit testing in Rails is given in [A Guide to Testing Rails Applications](testing.html)

Rails comes with a test suite called Minitest. Rails owes its stability to the use of tests. The tasks available in the `test:` namespace helps in running the different tests you will hopefully write.

### `tmp`

The `Rails.root/tmp` directory is, like the *nix /tmp directory, the holding place for temporary files like sessions (if you're using a file store for files), process id files, and cached actions.

The `tmp:` namespaced tasks will help you clear and create the `Rails.root/tmp` directory:

* `rake tmp:cache:clear` clears `tmp/cache`.
* `rake tmp:sessions:clear` clears `tmp/sessions`.
* `rake tmp:sockets:clear` clears `tmp/sockets`.
* `rake tmp:clear` clears all the three: cache, sessions and sockets.
* `rake tmp:create` creates tmp directories for sessions, cache, sockets, and pids.

### Miscellaneous

* `rake stats` is great for looking at statistics on your code, displaying things like KLOCs (thousands of lines of code) and your code to test ratio.
* `rake secret` will give you a pseudo-random key to use for your session secret.
* `rake time:zones:all` lists all the timezones Rails knows about.

### Custom Rake Tasks

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

To pass arguments to your custom rake task:

```ruby
task :task_name, [:arg_1] => [:pre_1, :pre_2] do |t, args|
  # You can use args from here
end
```

You can group tasks by placing them in namespaces:

```ruby
namespace :db do
  desc "This task does nothing"
  task :nothing do
    # Seriously, nothing
  end
end
```

Invocation of the tasks will look like:

```bash
$ bin/rake task_name
$ bin/rake "task_name[value 1]" # entire argument string should be quoted
$ bin/rake db:nothing
```

NOTE: If your need to interact with your application models, perform database queries and so on, your task should depend on the `environment` task, which will load your application code.

The Rails Advanced Command Line
-------------------------------

More advanced use of the command line is focused around finding useful (even surprising at times) options in the utilities, and fitting those to your needs and specific work flow. Listed here are some tricks up Rails' sleeve.

### Rails with Databases and SCM

When creating a new Rails application, you have the option to specify what kind of database and what kind of source code management system your application is going to use. This will save you a few minutes, and certainly many keystrokes.

Let's see what a `--git` option and a `--database=postgresql` option will do for us:

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

We had to create the **gitapp** directory and initialize an empty git repository before Rails would add files it created to our repository. Let's see what it put in our database configuration:

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
development:
  adapter: postgresql
  encoding: unicode
  database: gitapp_development
  pool: 5
  username: gitapp
  password:
...
...
```

It also generated some lines in our database.yml configuration corresponding to our choice of PostgreSQL for database.

NOTE. The only catch with using the SCM options is that you have to make your application's directory first, then initialize your SCM, then you can run the `rails new` command to generate the basis of your app.
