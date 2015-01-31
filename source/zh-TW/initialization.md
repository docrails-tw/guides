**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://rails.ruby.tw.**

Rails 啟動過程
=================

本篇介紹 Rails 4 啟動過程的內部原理。非常深入的一篇指南，推薦進階的 Rails 開發者閱讀。

讀完本篇，您將了解：

* 如何使用 `rails server`。
* Rails 啟動過程的時間軸。
* 啟動時 `require` 了那些檔案。
* `Rails::Server` 介面是如何定義的，以及如何使用。

--------------------------------------------------------------------------------

本篇針對 Rails 4，走一遍啟動 Rails 所需的每個方法呼叫。過程中詳細解釋每個步驟的用途，特別針對從 `rails server`， 到應用程式啟動起來之間的過程做解說。

NOTE: 除非特別聲明，本篇提及的路徑都是相對於 [Rails 原始碼](https://github.com/rails/rails)的目錄，或相對於 Rails 應用程式的路徑。

TIP: 若想跟著瀏覽 Rails 的[原始碼](https://github.com/rails/rails)，推薦[使用 GitHub 提供的檔案搜索](https://github.com/blog/793-introducing-the-file-finder)功能，來快速找到檔案，在 GitHub Repository 頁面按 `t` 即可使用。

啟動！
----

從初始化（Initialize）與啟動（boot）應用程式開始。Rails 應用程式通常在執行 `rails server` 或 `rails console` 時會啟動。

### `railties/bin/rails`

[View Source](https://github.com/rails/rails/blob/master/railties/bin/rails)

`rails server` 命令裡的 `rails`，是放在載入路徑（load path）下的 Ruby 執行檔。這個執行檔的內容如下：

```ruby
version = ">= 0"
load Gem.bin_path('railties', 'rails', version)
```

若在 Rails Console 裡試這個命令，會看到這個命令載入了 [`railties/bin/rails`](https://github.com/rails/rails/blob/master/railties/bin/rails)。

`railties/bin/rails` 裡有這一行：

```ruby
require "rails/cli"
```

[`railties/lib/rails/cli`](https://github.com/rails/rails/blob/master/railties/lib/rails/cli.rb) 接著呼叫 `Rails::AppRailsLoader.exec_app_rails`。

### `railties/lib/rails/app_rails_loader.rb`

[View Source](https://github.com/rails/rails/blob/master/railties/lib/rails/app_rails_loader.rb)

`exec_app_rails` 的主要目的是執行應用程式的 `bin/rails`，若當前目錄沒有 `bin/rails`，會往上搜索，看找不找的到 `bin/rails`。這也是為什麼可以在 rails 應用程式裡的任何目錄下使用 `rails` 命令。

`rails server` 實際上等於下面這個命令：

```bash
$ exec ruby bin/rails server
```

### `bin/rails`

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application', __FILE__)
require_relative '../config/boot'
require 'rails/commands'
```

`APP_PATH` 常數之後會被 `rails/commands` 使用。這裡引用的 `config/boot` 檔案是指 `config/boot.rb`，負責載入與設定 Bundler。

### `config/boot.rb`

```ruby
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
```

標準的 Rails 應用程式裡，會有一個檔案，裡面記錄所有依賴的 RubyGems：`Gemfile`。`config/boot.rb` 將 `ENV['BUNDLE_GEMFILE']` 設為 `Gemfile` 的位置。若 `Gemfile` 存在，則需要 `require 'bundler/setup'`。這一行是 Bundler 用來設定 `Gemfile` 內所有相依 RubyGems 的載入路徑。

標準的 Rails 應用程式依賴以下 RubyGems：

* actionmailer
* actionpack
* actionview
* activemodel
* activerecord
* activesupport
* arel
* builder
* bundler
* erubis
* i18n
* mail
* mime-types
* rack
* rack-cache
* rack-mount
* rack-test
* rails
* railties
* rake
* sqlite3
* thor
* tzinfo

### `rails/commands.rb`

[View Source](https://github.com/rails/rails/blob/master/railties/lib/rails/commands.rb)

`config/boot.rb` 執行完畢後，下個 `require` 的檔案是 `rails/commands`，用來展開命令的別名（alias）。在 `rails server` 這個情況裡，`ARGV` 的內容是 `server`，無需展開：

```ruby
ARGV << '--help' if ARGV.empty?

aliases = {
  "g"  => "generate",
  "d"  => "destroy",
  "c"  => "console",
  "s"  => "server",
  "db" => "dbconsole",
  "r"  => "runner"
}

command = ARGV.shift
command = aliases[command] || command

require 'rails/commands/commands_tasks'

Rails::CommandsTasks.new(ARGV).run_command!(command)
```

TIP: 如上所見，`ARGV` 為空時，Rails 會印出幫助訊息。

若用了別名，如 `rails s`，便會用 `aliases` 展開成對應的命令：

### `rails/commands/command_tasks.rb`

[View Source](https://github.com/rails/rails/blob/master/railties/lib/rails/commands/commands_tasks.rb)

當輸入錯的 Rails 命令時，`run_command!` 負責拋出錯誤訊息。若命令是有效的，則會呼叫與命令同名的方法。

```ruby
COMMAND_WHITELIST = %(plugin generate destroy console server dbconsole application runner new version help)

def run_command!(command)
  command = parse_command(command)
  if COMMAND_WHITELIST.include?(command)
    send(command)
  else
    write_error_message(command)
  end
end
```

假設傳入的命令是 `server`，Rails 會執行以下的程式碼：

```ruby
def server
  set_application_directory!
  require_command!("server")

  Rails::Server.new.tap do |server|
    # We need to require application after the server sets environment,
    # otherwise the --environment option given to the server won't propagate.
    require APP_PATH
    Dir.chdir(Rails.application.root)
    server.start
  end
end

private

  def set_application_directory!
    Dir.chdir(File.expand_path('../../', APP_PATH)) unless File.exist?(File.expand_path("config.ru"))
  end

  def require_command!(command)
    require "rails/commands/#{command}"
  end
```

沒找到 `config.ru` 時，會切換到 Rails 的根目錄（從 `APP_PATH` 往上兩層，`APP_PATH` 指向 `config/application.rb` ）。接著 `require` `rails/commands/server`（[rails/commands/server.rb](rails/commands/server），會把 `Rails::Server` 類別設定好。

```ruby
require 'fileutils'
require 'optparse'
require 'action_dispatch'
require 'rails'

module Rails
  class Server < ::Rack::Server
```

`fileutils` 和 `optparse` 是 Ruby 的標準函式庫，用來處理檔案與解析命令行參數。

### `actionpack/lib/action_dispatch.rb`

[View Source](https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch.rb)

Action Dispatch 是 Rails 框架負責處理路由的元件。為 Rails 加入像是路由、Session 以及常見的 Middlewares。

### `rails/commands/server.rb`

[View Source](https://github.com/rails/rails/blob/master/railties/lib/rails/commands/server.rb)

`Rails::Server` 在這個檔案裡定義，繼承自 `Rack::Server`。呼叫 `Rails::Server.new` 時，會呼叫 [`rails/commands/server.rb`](https://github.com/rails/rails/blob/master/railties/lib/rails/commands/server.rb) 裡的 `initialize` 方法：

```ruby
def initialize(*)
  super
  set_environment
end
```

首先呼叫 `super`，`super` 會呼叫 `Rack::Server` 的 `initialize`。

### Rack: `lib/rack/server.rb`

[View Source](https://github.com/rack/rack/blob/master/lib/rack/server.rb)

`Rack::Server` 負責給所有基於 Rack 的應用程式，提供通用的伺服器接口（interface），Rails 也是基於 Rack 的應用程式。

`Rack::Server` 的 `initialize` 方法只是設定幾個變數而已：

```ruby
def initialize(options = nil)
  @options = options
  @app = options[:app] if options && options[:app]
end
```

這個情況裡，`options` 會是 `nil`，所以 `initialize` 什麼也沒做。

`super` 結束之後，回到 `rails/commands/server.rb`。接著在 `Rails::Server` 的上下文裡呼叫 `set_environment`，猛一看好像沒做什麼：

```ruby
def set_environment
  ENV["RAILS_ENV"] ||= options[:environment]
end
```

實際上 `options` 方法做了很多事情。這個方法在 `Rack::Server` 的定義是：

```ruby
def options
  @options ||= parse_options(ARGV)
end
```

`parse_options` 方法的內容：

```ruby
def parse_options(args)
  options = default_options

  # Don't evaluate CGI ISINDEX parameters.
  # http://www.meb.uni-bonn.de/docs/cgi/cl.html
  args.clear if ENV.include?("REQUEST_METHOD")

  options.merge! opt_parser.parse!(args)
  options[:config] = ::File.expand_path(options[:config])
  ENV["RACK_ENV"] = options[:environment]
  options
end
```

`default_options` 的內容：

```ruby
def default_options
  environment  = ENV['RACK_ENV'] || 'development'
  default_host = environment == 'development' ? 'localhost' : '0.0.0.0'

  {
    :environment => environment,
    :pid         => nil,
    :Port        => 9292,
    :Host        => default_host,
    :AccessLog   => [],
    :config      => "config.ru"
  }
end
```

接著看到，因為 `ENV` 裡沒有 `REQUEST_METHOD`，可以忽略 `args.clear`。下一行 `options.merge! opt_parser.parse!(args)`，把從命令行來的參數與 `opt_parser` 的選項合併，`opt_parser` 在 `Rack::Server` 裡定義：

```ruby
def opt_parser
  Options.new
end
```

雖然 [`parse!`](https://github.com/rack/rack/blob/master/lib/rack/server.rb#L6-L87) 是在 `Rack::Server` 裡定義，但在 `Rails::Server` [被覆寫了](https://github.com/rails/rails/blob/master/railties/lib/rails/commands/server.rb#L9-L47)，因為要收不同的參數。`Rails::Server` 定義的 `parse!` 方法開頭是：

```ruby
def parse!(args)
  args, options = args.dup, {}

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: rails server [mongrel, thin, etc] [options]"
    opts.on("-p", "--port=port", Integer,
            "Runs Rails on the specified port.", "Default: 3000") { |v| options[:Port] = v }
  ...
```

這個方法會設定好 `options` 所有的鍵，Rails 根據這些鍵，決定伺服器該怎麼執行。在 `initialize` 結束之後，回到 [`rails/commands/command_tasks.rb`](https://github.com/rails/rails/blob/master/railties/lib/rails/commands/commands_tasks.rb)，見 `# Back to here`：

```ruby
def server
  set_application_directory!
  require_command!("server")

  # Back to here

  Rails::Server.new.tap do |server|
    # We need to require application after the server sets environment,
    # otherwise the --environment option given to the server won't propagate.
    require APP_PATH
    Dir.chdir(Rails.application.root)
    server.start
  end
end
```

### `config/application.rb`

當 `require APP_PATH` 執行時，會載入 `config/application.rb`。回想一下，`APP_PATH` 在 Rails 應用程式下的 `bin/rails` 裡定義：

```ruby
APP_PATH = File.expand_path('../../config/application',  __FILE__)
```

`config/application.rb` 裡放的是任何要對應用程式修改的設定。

### `Rails::Server#start`

[View Source](https://github.com/rails/rails/blob/master/railties/lib/rails/commands/server.rb#L70-L81)

`config/application.rb` 載入完畢後，呼叫了 `server.start`。`#start` 方法的定義是：

```ruby
def start
  print_boot_information
  trap(:INT) { exit }
  create_tmp_directories
  log_to_stdout if options[:log_stdout]

  super
  ...
end

private

  def print_boot_information
    ...
    puts "=> Run `rails server -h` for more startup options"
    ...
    puts "=> Ctrl-C to shutdown server" unless options[:daemonize]
  end

  def create_tmp_directories
    %w(cache pids sessions sockets).each do |dir_to_make|
      FileUtils.mkdir_p(File.join(Rails.root, 'tmp', dir_to_make))
    end
  end

  def log_to_stdout
    wrapped_app # touch the app so the logger is set up

    console = ActiveSupport::Logger.new($stdout)
    console.formatter = Rails.logger.formatter
    console.level = Rails.logger.level

    Rails.logger.extend(ActiveSupport::Logger.broadcast(console))
  end
```

Rails 啟動過程“初次輸出訊息”的地方。這個方法會捕捉 `INT` 信號，所以當你按下 `CTRL-C` 時，才能從進程（process）裡離開。從這段程式碼可以看到，會建立出 `tmp/cache`、`tmp/pids`、`tmp/sessions` 以及 `tmp/sockets` 這四個目錄。接著呼叫 `wrapped_app`，這個方法負責在指定 `ActiveSupport::Logger` 之前，建立出 Rack 應用程式。

上面 `start` 方法裡的 `super` 方法會呼叫 [`Rack::Server.start`](https://github.com/rack/rack/blob/master/lib/rack/server.rb#L228-L265)，此方法定義如下：

```ruby
def start &blk
  if options[:warn]
    $-w = true
  end

  if includes = options[:include]
    $LOAD_PATH.unshift(*includes)
  end

  if library = options[:require]
    require library
  end

  if options[:debug]
    $DEBUG = true
    require 'pp'
    p options[:server]
    pp wrapped_app
    pp app
  end

  check_pid! if options[:pid]

  # Touch the wrapped app, so that the config.ru is loaded before
  # daemonization (i.e. before chdir, etc).
  wrapped_app

  daemonize_app if options[:daemonize]

  write_pid if options[:pid]

  trap(:INT) do
    if server.respond_to?(:shutdown)
      server.shutdown
    else
      exit
    end
  end

  server.run wrapped_app, options, &blk
end
```

Rails 應用程式感興趣的是最後一行，`server.run`。這裡又遇到 `wrapped_app` 方法了，是深入介紹的時候了。

`wrapped_app` 的定義：

```ruby
@wrapped_app ||= build_app app
```

`app` 方法的定義：

```ruby
def app
  @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
end

...

private
  def build_app_and_options_from_config
    if !::File.exist? options[:config]
      abort "configuration #{options[:config]} not found"
    end

    app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
    self.options.merge! options
    app
  end

  def build_app_from_string
    Rack::Builder.new_from_string(self.options[:builder])
  end
```

`options[:config]` 的預設值是 `config.ru`，而 `config.ru` 的內容：

```ruby
# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
run <%= app_const %>
```

[`Rack::Builder.parse_file`](https://github.com/rack/rack/blob/371cf6f3a8d390edfa901b6f963b78810270a387/lib/rack/builder.rb#L32-L46) 方法讀取 `config.ru` ，並進行解析：

```ruby
app = new_from_string cfgfile, config

...

def self.new_from_string(builder_script, file="(rackup)")
  eval "Rack::Builder.new {\n" + builder_script + "\n}.to_app",
    TOPLEVEL_BINDING, file, 0
end
```

`Rack::Builder` 的 [`initialize` 方法](https://github.com/rack/rack/blob/371cf6f3a8d390edfa901b6f963b78810270a387/lib/rack/builder.rb#L53-L56)接受區塊參數，會在 `Rack::Builder` 的實體裡執行這個區塊。Rails 啟動過程主要都在這裡發生。最先執行的是 `config.ru` 裡的這一行：

```ruby
require ::File.expand_path('../config/environment', __FILE__)
```

### `config/environment.rb`

這個檔案通常由 `config.ru`（即 `rails server`）與 Passenger `require` 進來。這也是兩種啟動伺服器方法首次相遇的地方。在這之前都只是在設定 Rack 與 Rails 而已。

這個檔案從 `require` `config/application.rb` 開始：

```ruby
# Load the Rails application.
require File.expand_path('../application', __FILE__)
```

### `config/application.rb`

這個檔案 `require` `config/boot.rb`:

```ruby
require File.expand_path('../boot', __FILE__)
```

但只在 `config/boot.rb` 沒有被 `require` 的前提下才會進行 `require`。如此一來 `rails server` 才不會重複 `require`，但 Passenger 每次都會重新 `require` `config/boot.rb`。

有趣的事情開始了！

載入 Rails
----------

`config/application.rb` 檔案的下一行是：

```ruby
require 'rails/all'
```

### `railties/lib/rails/all.rb`

[View Source](https://github.com/rails/rails/blob/master/railties/lib/rails/all.rb)

這個檔案負責 `require` Rails 框架的各個元件：

```ruby
require "rails"

%w(
  active_record
  action_controller
  action_view
  action_mailer
  rails/test_unit
  sprockets
).each do |framework|
  begin
    require "#{framework}/railtie"
  rescue LoadError
  end
end
```

這是整個 Rails 框架載入的地方，讓每個元件在應用程式裡都可以使用。每個部分怎麼載入的不深入探究，但有興趣可以自己深入研究。

現在只要記得，共用的功能像是 Rails 引擎、I18n 以及 Rails 所有的設定都是在這裡定義完成。

### 回到 `config/environment.rb`

`config/application.rb` 的其他部分定義了 `Rails::Application` 的設定，這些設定在應用程式啟動完畢時會全部載入進來。當 `config/application.rb` 載入 Rails 完畢時，以及應用程式命名空間定義完畢時，會回到應用程式初始化的地方，也就是 `config/environment.rb`。舉個例子，若應用程式叫做 `Blog`，則會找到 `Rails.application.initialize!`，這個方法在 `rails/application.rb` 裡定義。

### `railties/lib/rails/application.rb`

[View Source](https://github.com/rails/rails/blob/master/railties/lib/rails/application.rb)

`initialize!` 方法：

```ruby
def initialize!(group=:default) #:nodoc:
  raise "Application has been already initialized." if @initialized
  run_initializers(group, self)
  @initialized = true
  self
end
```

可以看到應用程式只會初始化一次。Initializers（`config/initializers` 目錄下的設定檔）透過 `run_initializers` 方法依序執行，`run_initializers` 方法在 [`railties/lib/rails/initializable.rb`](https://github.com/rails/rails/blob/master/railties/lib/rails/initializable.rb) 裡定義：

```ruby
def run_initializers(group=:default, *args)
  return if instance_variable_defined?(:@ran)
  initializers.tsort_each do |initializer|
    initializer.run(*args) if initializer.belongs_to?(group)
  end
  @ran = true
end
```

`run_initializers` 很巧妙。在這裡會遍歷所有類別的祖先，找出有回應 `initializers` 方法的類別。接著按名稱將這些類別排序，再執行它們。舉例來說，`Engine` 類別透過給每個 Engine 提供 `initializers` 方法，讓這些 Engine 都可以引用進來。

Rails::Application 類別（在 [`railties/lib/rails/application.rb`](https://github.com/rails/rails/blob/master/railties/lib/rails/application.rb) 裡定義）定義了 bootstrap、railtie、finisher 這三個 Initializers。第一個執行的 Initializer 是 bootstrap，bootstrap 將應用程式準備好（像是初始化 logger），而 finisher initializer 則是最後執行（像是把 Middleware 都建好）。而 railtie initializers 則是在 `Rails::Application` 裡定義，在 bootstrap 與 finisher 之間執行。

Initializers 都執行完畢後，回到 `Rack::Server`。

### Rack: lib/rack/server.rb

[View Source](https://github.com/rack/rack/blob/master/lib/rack/server.rb)

在 [1.9 小節](#%E5%95%9F%E5%8B%95%EF%BC%81-rack:-lib/rack/server.rb) ，我們看過 `app` 是如何被定義的：

```ruby
def app
  @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
end

...

private
  def build_app_and_options_from_config
    if !::File.exist? options[:config]
      abort "configuration #{options[:config]} not found"
    end

    app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
    self.options.merge! options
    app
  end

  def build_app_from_string
    Rack::Builder.new_from_string(self.options[:builder])
  end
```

到了這一步，`app` 便是 Rails 應用程式本身（Middleware），接下來 Rack 會呼叫所有的 Middlewares：

```ruby
def build_app(app)
  middleware[options[:environment]].reverse_each do |middleware|
    middleware = middleware.call(self) if middleware.respond_to?(:call)
    next unless middleware
    klass = middleware.shift
    app = klass.new(app, *middleware)
  end
  app
end
```

記得 `wrapped_app` 在 `Server#start` 呼叫了 `build_app` （最後一行）：

```ruby
server.run wrapped_app, options, &blk
```

到這裡 `server.run` 取決於所使用的伺服器實作是那一個。假設用的是 Puma，下面是 Puma 的 `run` 方法：

```ruby
...
DEFAULT_OPTIONS = {
  :Host => '0.0.0.0',
  :Port => 8080,
  :Threads => '0:16',
  :Verbose => false
}

def self.run(app, options = {})
  options  = DEFAULT_OPTIONS.merge(options)

  if options[:Verbose]
    app = Rack::CommonLogger.new(app, STDOUT)
  end

  if options[:environment]
    ENV['RACK_ENV'] = options[:environment].to_s
  end

  server   = ::Puma::Server.new(app)
  min, max = options[:Threads].split(':', 2)

  puts "Puma #{::Puma::Const::PUMA_VERSION} starting..."
  puts "* Min threads: #{min}, max threads: #{max}"
  puts "* Environment: #{ENV['RACK_ENV']}"
  puts "* Listening on tcp://#{options[:Host]}:#{options[:Port]}"

  server.add_tcp_listener options[:Host], options[:Port]
  server.min_threads = min
  server.max_threads = max
  yield server if block_given?

  begin
    server.run.join
  rescue Interrupt
    puts "* Gracefully stopping, waiting for requests to finish"
    server.stop(true)
    puts "* Goodbye!"
  end

end
```

伺服器本身的實作不深入探究，但這是 Rails 啟動過程整個旅程的最後一站。

希望這高度抽象的綜覽能幫助你更好的了解 Rails 程式是如何執行的，進而成為一個更好的 Rails 開發者。若想了解更多的話，那就閱讀 Rails 的原始碼吧！
