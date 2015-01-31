**DO NOT READ THIS FILE ON GITHUB, GUIDES ARE PUBLISHED ON http://rails.ruby.tw.**

Rails 應用程式模版
=================

應用程式模版其實就是 Ruby 檔案，內含新增 Gems、Initializers 等的 DSL，用來建立、更新 Rails 專案。

讀完本篇，您將了解：

* 如何使用模版來產生、客製化 Rails 應用程式。
* 如何使用 Rails 的模版 API 撰寫出可複用的應用程式模版。

--------------------------------------------------------------------------------

用途
-----

要套用模版，首先需要提供 Rails 產生器並用 `-m` 選項附上模版的位置。位置可以是個檔案或是 URL。

```bash
$ rails new blog -m ~/template.rb
$ rails new blog -m http://example.com/template.rb
```

可以使用 `rake rails:template` 來套用模版到現有的 Rails 應用程式。模版的位置需要使用 `LOCATION` 這個環境變數傳入。再強調一次，模版的位置可以是檔案或 URL。

```bash
$ bin/rake rails:template LOCATION=~/template.rb
$ bin/rake rails:template LOCATION=http://example.com/template.rb
```

模版 API
------------

Rails 模版 API 很容易理解。看下面這個 Rails 模版的典型例子：

```ruby
# template.rb
generate(:scaffold, "person name:string")
route "root to: 'people#index'"
rake("db:migrate")

after_bundle do
  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
```

下節概述模版 API 主要提供的方法：

### gem(*args)

新增 `gem` 到應用程式的 `Gemfile`。

舉個例子，加入 `bj` 與 `nokogiri` 到 `Gemfile`：

```ruby
gem "bj"
gem "nokogiri"
```

請注意這不會安裝，要執行 `bundle install` 才會安裝：

```bash
bundle install
```

### gem_group(*names, &block)

將 Gem 分組。

譬如只想要在開發與測試環境下載入 `rspec-rails`：

```ruby
gem_group :development, :test do
  gem "rspec-rails"
end
```

### add_source(source, options = {})

新增 RubyGems 來源網站到 `Gemfile`。

```ruby
add_source "http://code.whytheluckystiff.net"
```

### environment/application(data=nil, options={}, &block)

新增程式到 `config/application.rb`。

若有指定環境 `options[:env]`，則程式會加到 `config/environments` 下對應的環境設定檔裡。

```ruby
environment 'config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}', env: 'production'
```

`data` 參數可以是區塊。

### vendor/lib/file/initializer(filename, data = nil, &block)

新增 initializer 到 `config/initializers` 目錄下。

假設想使用 `Object#not_nil?` 與 `Object#not_blank?`：

```ruby
initializer 'bloatlol.rb', <<-CODE
  class Object
    def not_nil?
      !nil?
    end

    def not_blank?
      !blank?
    end
  end
CODE
```

`lib()` 則是在 `lib/` 目錄下建立檔案、`vender()` 在 `vender/` 目錄下建立檔案。

還有一個 `file()` 方法，可在 `Rails.root` 的相對路徑下同時建立目錄與檔案。

```ruby
file 'app/components/foo.rb', <<-CODE
  class Foo
  end
CODE
```

這會建立出 `app/components` 目錄，並新增 `foo.rb`。

### rakefile(filename, data = nil, &block)

在 `lib/tasks` 建立 Rake 檔案：

```ruby
rakefile("bootstrap.rake") do
  <<-TASK
    namespace :boot do
      task :strap do
        puts "i like boots!"
      end
    end
  TASK
end
```

### generate(what, *args)

使用給入的參數執行 Rails 的產生器：

```ruby
generate(:scaffold, "person", "name:string", "address:text", "age:number")
```

### run(command)

執行任何命令，即反引號（`` ` ``）。譬如想移除 `README.rdoc` 檔案：

```ruby
run "rm README.rdoc"
```

### rake(command, options = {})

執行指定的 Rake 任務。

```ruby
rake "db:migrate"
```

也可以針對環境執行：

```ruby
rake "db:migrate", env: 'production'
```

### route(routing_code)

新增一筆路由到 `config/routes.rb`。譬如加一筆 `root` 路由：

```ruby
route "root to: 'person#index'"
```

### inside(dir)

在特定目錄下執行命令：

```ruby
inside('vendor') do
  run "ln -s ~/commit-rails/rails rails"
end
```

### ask(question)

`ask()` 可以詢問使用者問題，並獲得使用者的輸入。比如詢問即將新增的函式庫名稱：

```ruby
lib_name = ask("What do you want to call the shiny library ?")
lib_name << ".rb" unless lib_name.index(".rb")

lib lib_name, <<-CODE
  class Shiny
  end
CODE
```

### yes?(question) or no?(question)

這兩個方法可以問問題，根據使用者的答案來決定執行流程。譬如根據使用者的回答，決定是否執行 `bundle package`：

```ruby
system("bundle package") if yes?("Package all gems?")
# no?(question) acts just the opposite.
```

### git(:command)

Rails 模版可執行任何 git 命令：

```ruby
git :init
git add: "."
git commit: "-a -m 'Initial commit'"
```

進階用途
--------

應用程式模版在 `Rails::Generators::AppGenerator` 實體的上下文裡求值。使用了由 [Thor](https://github.com/erikhuda/thor/blob/master/lib/thor/actions.rb#L209) 所提供的 `apply` 方法。這表示可以自己擴展、修改這個實體，以符所需。

舉個複寫 `source_paths` 方法的例子，讓 `source_path` 包含模版的位置。現在像是 `copy_file` 的方法會接受相對於模版的位置了。

```ruby
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end
```
