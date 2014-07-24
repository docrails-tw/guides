除錯 Rails 應用程式
=================

本篇介紹 Rails 應用程式除錯技巧。

讀完本篇，您將了解：

* 除錯的目的。
* 如何追蹤測試沒有找出的問題。
* 各種除錯方法。
* 如何分析 Stack Trace。

--------------------------------------------------------------------------------

除錯用的 View 輔助方法
--------------------

除錯常見任務之一是查看變數的內容。在 Rails 可以用三種方法：

* `debug`
* `to_yaml`
* `inspect`

### `debug`

`debug` 輔助方法會對物件以 YAML 格式算繪，把結果包在 `<pre>` 標籤內回傳。譬如，View 有如下程式：

```html+erb
<%= debug @article %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

輸出則像是：

```yaml
--- !ruby/object Article
attributes:
  updated_at: 2008-09-05 22:55:47
  body: It's a very helpful guide for debugging your Rails app.
  title: Rails debugging guide
  published: t
  id: "1"
  created_at: 2008-09-05 22:55:47
attributes_cache: {}


Title: Rails debugging guide
```

### `to_yaml`

以 YAML 格式顯示實體變數、物件、方法。用法：

```html+erb
<%= simple_format @article.to_yaml %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

`to_yaml` 方法把物件轉成可讀性比較高的 YAML 格式，接著 `simple_format` 會使用和終端同樣的方法來算繪物件。`debug` 方法其實就是結合了這兩者：

上例輸出結果：

```yaml
--- !ruby/object Article
attributes:
updated_at: 2008-09-05 22:55:47
body: It's a very helpful guide for debugging your Rails app.
title: Rails debugging guide
published: t
id: "1"
created_at: 2008-09-05 22:55:47
attributes_cache: {}

Title: Rails debugging guide
```

### `inspect`

另一個顯示物件數值的有用方法是 `inspect`，對陣列或 Hash 尤其有用。會把物件的數值以字串形式印出，譬如：

```html+erb
<%= [1, 2, 3, 4, 5].inspect %>
<p>
  <b>Title:</b>
  <%= @article.title %>
</p>
```

算繪出來為：

```
[1, 2, 3, 4, 5]

Title: Rails debugging guide
```

Logger
------

程式執行時，寫入資訊到記錄檔很有用。而 Rails 替每個環境都準備了一個記錄檔。

### 什麼是 Logger？

Rails 使用 `ActiveSupport::Logger` 來寫入記錄資訊。也可以換用別的 Logger，譬如 `Log4r`。

可以在 `environment.rb` 指定其它的 Logger，或在其它環境檔案內指定也可以。

```ruby
Rails.logger = Logger.new(STDOUT)
Rails.logger = Log4r::Logger.new("Application Log")
```

或在 `Initializer` 加入下面任一行：

```ruby
config.logger = Logger.new(STDOUT)
config.logger = Log4r::Logger.new("Application Log")
```

TIP: 記錄檔預設存在 `Rails.root/log/` 目錄下，記錄檔以應用程式正執行的環境命名。

### Log 層級

當產生的 Log 訊息層級高過設定的 Log 層級時，就會把 Log 記錄到對應的記錄檔裡。若想知道當前的 Log 層級，可以呼叫 `Rails.logger.level` 方法。

可用 Log 層級有：`:debug`、`:info`、`:warn`、`:error`、`:fatal` 以及 `:unknown`，分別對應到數字 `0` 到 `5`。修改預設 Log 層級：

```ruby
config.log_level = :warn # In any environment initializer, or
Rails.logger.level = 0 # at any time
```

這在開發和準上線環境（Staging）下很有用，也能避免上線環境寫入大量不必要的資訊。

TIP: Rails 預設上線環境的 Log 層級是 `info`，開發與測試環境是 `debug`。

### 寫入訊息

要寫入訊息到目前的記錄檔裡，在 Controller、Model 或 Mailer 裡使用 `logger.(debug|info|warn|error|fatal)`：

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
logger.info "Processing the request..."
logger.fatal "Terminating application, raised unrecoverable error!!!"
```

以下是有額外記錄資訊的方法：

```ruby
class ArticlesController < ApplicationController
  # ...

  def create
    @article = Article.new(params[:article])
    logger.debug "New article: #{@article.attributes.inspect}"
    logger.debug "Article should be valid: #{@article.valid?}"

    if @article.save
      flash[:notice] =  'Article was successfully created.'
      logger.debug "The article was saved and now the user is going to be redirected..."
      redirect_to(@article)
    else
      render action: "new"
    end
  end

  # ...
end
```

動作執行的紀錄檔：

```
Processing ArticlesController#create (for 127.0.0.1 at 2008-09-08 11:52:54) [POST]
  Session ID: BAh7BzoMY3NyZl9pZCIlMDY5MWU1M2I1ZDRjODBlMzkyMWI1OTg2NWQyNzViZjYiCmZsYXNoSUM6J0FjdGl
vbkNvbnRyb2xsZXI6OkZsYXNoOjpGbGFzaEhhc2h7AAY6CkB1c2VkewA=--b18cd92fba90eacf8137e5f6b3b06c4d724596a4
  Parameters: {"commit"=>"Create", "article"=>{"title"=>"Debugging Rails",
 "body"=>"I'm learning how to print in logs!!!", "published"=>"0"},
 "authenticity_token"=>"2059c1286e93402e389127b1153204e0d1e275dd", "action"=>"create", "controller"=>"articles"}
New article: {"updated_at"=>nil, "title"=>"Debugging Rails", "body"=>"I'm learning how to print in logs!!!",
 "published"=>false, "created_at"=>nil}
Article should be valid: true
  Article Create (0.000443)   INSERT INTO "articles" ("updated_at", "title", "body", "published",
 "created_at") VALUES('2008-09-08 14:52:54', 'Debugging Rails',
 'I''m learning how to print in logs!!!', 'f', '2008-09-08 14:52:54')
The article was saved and now the user is going to be redirected...
Redirected to # Article:0x20af760>
Completed in 0.01224 (81 reqs/sec) | DB: 0.00044 (3%) | 302 Found [http://localhost/articles]
```

增加額外的記錄可以更容易在記錄檔裡找到異常行為。若需要記錄更多資訊，記得設定合理的 Log 等級，避免在上線環境的紀錄檔裡寫入不必要的訊息。

### 給記錄打標籤

執行多使用者、多帳號的應用程式時，可以使用自訂規則來過濾記錄檔很有用。Active Support 的 `TaggedLogging` 便為此而生。可以在記錄裡加入像是子域名、請求 ID 等，其它有助於除錯的訊息。

```ruby
logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
logger.tagged("BCX") { logger.info "Stuff" }                            # Logs "[BCX] Stuff"
logger.tagged("BCX", "Jason") { logger.info "Stuff" }                   # Logs "[BCX] [Jason] Stuff"
logger.tagged("BCX") { logger.tagged("Jason") { logger.info "Stuff" } } # Logs "[BCX] [Jason] Stuff"
```

### 記錄對效能的影響

記錄肯定會對效能產生影響，特別是將記錄存到硬碟裡。有幾個潛在的問題：

使用 `:debug` 層級對效能的影響最大（與 `:fatal` 相比）。因為 `:debug` 與 `:fatal` 相比起來，需要處理的字串多很多，還得再寫入到磁碟。

另一個潛在的陷阱是，若是這樣使用 `Logger`：

```ruby
logger.debug "Person attributes hash: #{@person.attributes.inspect}"
```

在上例裡，即便 Logger 層級不包含 `:debug` 也會影響效能。因為 Ruby 需要對這些字串做求值，求值便需要實體化這些字串，再處理字串插值，這些都需要時間。

因此使用 `logger` 方法時，傳入區塊會比較好。區塊只在 Logger 層級相符時才會求值（即惰性加載）。上例可改寫為：

```ruby
logger.debug {"Person attributes hash: #{@person.attributes.inspect}"}
```

區塊的內容只在 `:debug` 層級的紀錄啟用時才會求值。省下的效能只在記錄大量資料時會體現出來，但這是可以遵循的良好實踐。

使用 `byebug` Gem 來除錯
-----------------------

當程式不按預期執行時，可以試著印出 Log 或在終端裡查看來找出問題。不幸的是，有時這些方法無法有效的找出問題所在。當需要逐步追蹤程式碼如何執行，除錯器是你的最佳夥伴。

除錯器也可以幫助你了解 Rails 的原始碼。若不知道從何下手，從任何一個請求切入，再運用下面教你的方法，一步一步深入 Rails 原始碼。

### 設定

使用 `byebug` gem 來下斷點，即可在正在執行的程式裡逐步執行。首先要安裝 `byebug`：

```bash
$ gem install byebug
```

在 Rails 應用程式裡的任何地方，可以使用 `byebug` 方法來呼叫除錯器。

範例：

```ruby
class PeopleController < ApplicationController
  def new
    byebug
    @person = Person.new
  end
end
```

### Shell

只要呼叫了 `byebug` 方法，除錯器便會啟動。啟動伺服器時，會在終端機裡開一個 Shell 起來，會停在呼叫 `byebug` 的地方。即將執行的程式碼左邊會有 `=>` 提示符號：

```
[1, 10] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug)
```

若是從瀏覽器觸發，瀏覽器分頁會停住，直到除錯器與請求結束。

比如說：

```bash
=> Booting WEBrick
=> Rails 4.2.0 application starting in development on http://0.0.0.0:3000
=> Run `rails server -h` for more startup options
=> Notice: server is listening on all interfaces (0.0.0.0). Consider using 127.0.0.1 (--binding option)
=> Ctrl-C to shutdown server
[2014-04-11 13:11:47] INFO  WEBrick 1.3.1
[2014-04-11 13:11:47] INFO  ruby 2.1.1 (2014-02-24) [i686-linux]
[2014-04-11 13:11:47] INFO  WEBrick::HTTPServer#start: pid=6370 port=3000


Started GET "/" for 127.0.0.1 at 2014-04-11 13:11:48 +0200
  ActiveRecord::SchemaMigration Load (0.2ms)  SELECT "schema_migrations".* FROM "schema_migrations"
Processing by ArticlesController#index as HTML

[3, 12] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug)
```

現在是時候深入程式一探究竟了。先看看有什麼命令可以用，輸入 `help`：

```
(byebug) help

byebug 2.7.0

Type 'help <command-name>' for help on a specific command

Available commands:
backtrace  delete   enable  help       list    pry next  restart  source     up
break      disable  eval    info       method  ps        save     step       var
catch      display  exit    interrupt  next    putl      set      thread
condition  down     finish  irb        p       quit      show     trace
continue   edit     frame   kill       pp      reload    skip     undisplay
```

TIP: 要查看任何命令的說明文件，請使用 `help <command-name>`，譬如 `help list`。也可以使用縮寫（輸入足夠與其他命令區別的字元即可），比如 `list` 可用 `l` 即可，例如：

要列出前十行程式，可以使用 `list-` 或 `l-`：

```
(byebug) l-

[1, 10] in /PathTo/project/app/controllers/articles_controller.rb
   1  class ArticlesController < ApplicationController
   2    before_action :set_article, only: [:show, :edit, :update, :destroy]
   3
   4    # GET /articles
   5    # GET /articles.json
   6    def index
   7      byebug
   8      @articles = Article.find_recent
   9
   10      respond_to do |format|

```

這樣便可看 `byebug` 上面與下面的程式碼。最後，要回到 `byebug` 停下來的地方，輸入 `list=`：

```
(byebug) list=

[3, 12] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug)
```

### 上下文

開始除錯應用程式時，會在不同的上下文裡跳轉。

除錯器停在某個地方（或觸發事件時），會建立一個上下文，上下文有當下暫停程式的資訊，讓除錯器可以檢查 Frame Stack、以當下程式的角度對變數求值，並擁有程式暫停的位置資訊。

任何時候都可以使用 `backtrace`（別名 `where`）來印出應用程式的 Backtrace。這可以知道程式是怎麼跑到這裡來。若困惑程式是如何執行到這裡，執行 `backtrace` 便可找到答案。

```
(byebug) where
--> #0  ArticlesController.index
      at /PathTo/project/test_app/app/controllers/articles_controller.rb:8
    #1  ActionController::ImplicitRender.send_action(method#String, *args#Array)
      at /PathToGems/actionpack-4.2.0/lib/action_controller/metal/implicit_render.rb:4
    #2  AbstractController::Base.process_action(action#NilClass, *args#Array)
      at /PathToGems/actionpack-4.2.0/lib/abstract_controller/base.rb:189
    #3  ActionController::Rendering.process_action(action#NilClass, *args#NilClass)
      at /PathToGems/actionpack-4.2.0/lib/action_controller/metal/rendering.rb:10
...
```

當下的 Frame 會以 `-->` 註記。可以使用 `frame n` 命令移動到 Frame 的任何地方，`n` 是 Frame 的編號。移動時，`byebug` 會同時顯示新的上下文。

```
(byebug) frame 2

[184, 193] in /PathToGems/actionpack-4.2.0/lib/abstract_controller/base.rb
   184:       # is the intended way to override action dispatching.
   185:       #
   186:       # Notice that the first argument is the method to be dispatched
   187:       # which is *not* necessarily the same as the action name.
   188:       def process_action(method_name, *args)
=> 189:         send_action(method_name, *args)
   190:       end
   191:
   192:       # Actually call the method associated with the action. Override
   193:       # this method if you wish to change how action methods are called,

(byebug)
```

也可以使用 `up [n]` 或 `down [n]` 來往上或下幾個 Frame。`n` 預設是 `1`。往上會往編號較高的 Frame 走；而下是往編號較低的 Frame 去。

### 線程

除錯器可以列出線程（Thread）、停止線程、繼續線程、切換線程：`thread` 命令（或縮寫 `th`）。有以下選項可用：

* `thread`：顯示當前的線程。
* `thread list`：用來列出所有線程及線程的狀態。線程數字前有 `+` 號表示為當前的線程。
* `thread stop n`：停止線程 `n`。
* `thread resume n`：繼續線程 `n`。
* `thread switch n`：切換當前的線程到線程 `n`。

這條命令在需要除錯當前線程時很有用，比如可以檢查線程是否有競態條件。

### 查看變數

當前的上下文裡可以執行任何表達式。要對表達式做求值，輸入表達式即可！

下例示範如何在當下的上下文裡印出實體變數：

```
[3, 12] in /PathTo/project/app/controllers/articles_controller.rb
    3:
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     byebug
=>  8:     @articles = Article.find_recent
    9:
   10:     respond_to do |format|
   11:       format.html # index.html.erb
   12:       format.json { render json: @articles }

(byebug) instance_variables
[:@_action_has_layout, :@_routes, :@_headers, :@_status, :@_request,
 :@_response, :@_env, :@_prefixes, :@_lookup_context, :@_action_name,
 :@_response_body, :@marked_for_same_origin_verification, :@_config]
```

你可能看出來了，所有 Controller 可以存取的變數都印出來了。這個變數清單會隨程式執行而變。譬如使用 `next` 可跳到下一行：

```
(byebug) next
[5, 14] in /PathTo/project/app/controllers/articles_controller.rb
   5     # GET /articles.json
   6     def index
   7       byebug
   8       @articles = Article.find_recent
   9
=> 10       respond_to do |format|
   11         format.html # index.html.erb
   12        format.json { render json: @articles }
   13      end
   14    end
   15
(byebug)
```

接著再使用 `instance_variables`:

```
(byebug) instance_variables.include? "@articles"
true
```

現在 `@articles` 被加到實體變數清單裡了，因為定義 `@articles` 的那一行已經被執行了。

TIP: 也可以切換到 `irb` 模式，使用 `irb` 命令即可。會在當下的上下文裡，起一個新的 irb 起來，但這個功能還在實驗階段。

`var` 是用來顯示變數的方法，說明文件如下：

```
(byebug) help var
v[ar] cl[ass]                   show class variables of self
v[ar] const <object>            show constants of object
v[ar] g[lobal]                  show global variables
v[ar] i[nstance] <object>       show instance variables of object
v[ar] l[ocal]                   show local variables
```

這是用來檢視當前上下文變數的好方法。舉個例子，看有沒有定義任何區域變數：

```
(byebug) var local
(byebug)
```

檢視物件的實體變數：

```
(byebug) var instance Article.new
@_start_transaction_state = {}
@aggregation_cache = {}
@association_cache = {}
@attributes = {"id"=>nil, "created_at"=>nil, "updated_at"=>nil}
@attributes_cache = {}
@changed_attributes = nil
...
```

TIP: `p`（print）和 `pp`（pretty print）可以用來對 Ruby 表達式求值、顯示變數的值到終端。

也可用 `display` 來“關注”變數。這是程式執行時，用來追蹤變數值的好方法。

```
(byebug) display @articles
1: @articles = nil
```

在 `display` 關注清單的變數，會在上下文切換時印出來。要停止關注變數，`undisplay n`，`n` 是變數前的編號（上例 `1`）。

### 逐步執行

現在應該了解如何知道自己在執行程式的位置，並能印出變數。接著看程式如何執行。

使用 `step`（縮寫 `s`）來繼續執行程式直到下個斷點，控制權會轉移回除錯器。

也可以使用 `next`，跟 `step` 類似，但會略過行內的程式執行。

TIP: 可以用 `step n` 或 `next n` 來一次往前 `n` 步。

`next` 與 `step` 的差別是 `step` 會跳到下一行程式碼“裡”；而 `next` 則會移到“下一行”程式，不會執行行內的程式碼。

看看下面這個例子：

```ruby
Started GET "/" for 127.0.0.1 at 2014-04-11 13:39:23 +0200
Processing by ArticlesController#index as HTML

[1, 8] in /home/davidr/Proyectos/test_app/app/models/article.rb
   1: class Article < ActiveRecord::Base
   2:
   3:   def self.find_recent(limit = 10)
   4:     byebug
=> 5:     where('created_at > ?', 1.week.ago).limit(limit)
   6:   end
   7:
   8: end

(byebug)
```

若使用 `next`，`next` 不會深入 `where(...)`，而是跳到下一行。上例剛好到了 `end`，則會跳到下一個 Frame。

```
(byebug) next
Next went up a frame because previous frame finished

[4, 13] in /PathTo/project/test_app/app/controllers/articles_controller.rb
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     @articles = Article.find_recent
    8:
=>  9:     respond_to do |format|
   10:       format.html # index.html.erb
   11:       format.json { render json: @articles }
   12:     end
   13:   end

(byebug)
```

反之若使用的是 `step`，則會到“下一行”，這個例子會跳到 Active Support 的 `week` 方法。

```
(byebug) step

[50, 59] in /PathToGems/activesupport-4.2.0/lib/active_support/core_ext/numeric/time.rb
   50:     ActiveSupport::Duration.new(self * 24.hours, [[:days, self]])
   51:   end
   52:   alias :day :days
   53:
   54:   def weeks
=> 55:     ActiveSupport::Duration.new(self * 7.days, [[:days, self * 7]])
   56:   end
   57:   alias :week :weeks
   58:
   59:   def fortnights

(byebug)
```

這是找出 Bug 最好的方法之一，或者說這是在 Ruby on Rails 框架裡最好的除錯方法。

### 斷點

斷點可使程式在執行到某處時停下來，會在該處起一個 Shell。

可以動態加斷點，使用 `break` （或 `b` 就好）。有三種方式可以手動加斷點：

* `break line`：在目前的檔案裡對 `line` 行下斷點。
* `break file:line [if expression]`： 在 `file` 的 `line` 行下斷點。`if` 表達式求值為真時會啟動除錯器。
* `break class(.|\#)method [if expression]`： 在 _`class`_ 的類別方法或實體方法裡下斷點。同樣在 `if` 表達式求值為真時會啟動除錯器。

譬如在前例下斷點：

```
[4, 13] in /PathTo/project/app/controllers/articles_controller.rb
    4:   # GET /articles
    5:   # GET /articles.json
    6:   def index
    7:     @articles = Article.find_recent
    8:
=>  9:     respond_to do |format|
   10:       format.html # index.html.erb
   11:       format.json { render json: @articles }
   12:     end
   13:   end

(byebug) break 11
Created breakpoint 1 at /PathTo/project/app/controllers/articles_controller.rb:11

```

使用 `info breakpoints n` 或 `info break n` 來列出斷點。若有給 `n` 號碼，會只列出對應號碼的斷點，否則列出所有的斷點。

```
(byebug) info breakpoints
Num Enb What
1   y   at /PathTo/project/app/controllers/articles_controller.rb:11
```

要刪除斷點，使用 `delete n`，來移除 `n` 號斷點。若沒指定則會刪除所有使用中的斷點。

```
(byebug) delete 1
(byebug) info breakpoints
No breakpoints.
```

也可以啟用或停用某個斷點：

* `enable breakpoints`：接受一個斷點清單。沒給清單會啟用所有的斷點（預設）。
* `disable breakpoints`：指定的斷點不會對程式造成影響。

### 補捉異常

`catch exception-name`（或 `cat exception-name`）命令可用來攔截沒有預設處理程序的異常（異常的類型為 `exception-name`）。

列出所有的攔截點請用 `catch`。

### 繼續執行

除錯器暫停程式，有兩種恢復程式執行的方法：

* `continue [line-specification]`（或 `c`）：在上次停下來的地方繼續執行程式，該行的任何斷點會被忽略。接受一個選擇性參數 `line-specification`，允許指定行號。可以消掉指定行號的斷點。
* `finish [frame-number]`（或 `fin`）：執行 Frame 裡的所有程式。沒指定要執行那個 Frame 時，程式會執行到當下的 Frame 結束為止。若有指定 Frame，則會執行到該 Frame 結束為止。

### 編輯

兩個命令可以從除錯器裡開啟編輯器來編輯：

* `edit [file:line]`: 使用環境變數 `EDITOR` 指定的編輯器來編輯 _`file`_，可以選擇性指定要編輯的行號 `line`。

### 離開

要離開除錯器，使用 `quit` 命令（縮寫 `q`），別名：`exit`。

離開實際上會終止所有的線程。因此伺服器會被停止，需要自己重新啟動。

### 設定

`byebug` 有幾個可用的選項：

* `set autoreload`： 原始碼改變時自動重載（預設 `true`）。
* `set autolist`：每個斷點自動執行 `list` 命令（預設 `true`）。
* `set listsize _n_`： 設定要列出的行數（預設 `10`）。
* `set forcestep`：確保 `next` 和 `step` 命令總是移到下一行。

可以使用 `help set` 看完整的設定選項。使用 `help set subcommand` 來學習特定子命令的知識。

TIP: 可以將這些設定直存在家目錄下的 `.byebugrc` 檔案裡。除錯器在啟動時會讀取這些全域設定。譬如：

```bash
set forcestep
set listsize 25
```

找出記憶體洩漏
------------

Ruby 應用（不管是不是 Rails）都有可能會洩漏記憶體，可能是 Ruby 或是 C 程式洩漏記憶體。

本節介紹 Valgrind 工具，可以用來找出並修正記憶體洩漏的問題。

### Valgrind

[Valgrind](http://valgrind.org/) 只能在 Linux 上使用，用來找出 C 語言的記憶體洩漏或是競態條件。

有一些 Valgrind 工具可以自動偵測出記憶體洩漏、線程 Bugs 並可以對程式做詳細的分析。舉個例子，若有個用 C 寫的擴充程式，在直譯器呼叫了 `malloc()`，但沒有 `free()`，這些記憶體在應用程式結束時才會被釋放。

關於安裝 Valgrind 以及如何跟 Ruby 使用，請參考 Evan Weaver 所寫的文章：[Valgrind and Ruby](http://blog.evanweaver.com/articles/2008/02/05/valgrind-and-ruby/)。

除錯套件
-------

以下是幫助你找出錯誤與除錯程式的套件清單。

* [Footnotes](https://github.com/josevalim/rails-footnotes) 在每頁的頁腳印出請求的資訊、並連結到對應的程式碼（TextMate）。
* [Query Trace](https://github.com/ntalbott/query_trace/tree/master) 增加查詢記錄的源頭。
* [Query Reviewer](https://github.com/nesquena/query_reviewer) 這個 Rails 插件只會在開發模式的 `SELECT` 查詢前執行 `EXPLAIN`，並將分析過後的結果放在 `div` 裡，附在每一頁裡。
* [Exception Notifier](https://github.com/smartinez87/exception_notification/tree/master) 提供一個 Mailer 物件以及一組模版。當 Rails 程式出錯時，寄送一封郵件通知。
* [Better Errors](https://github.com/charliesome/better_errors) 替換 Rails 標準的錯誤頁面，用有更多上下文資訊的頁面（像是出錯的程式、變量等）來取代。
* [RailsPanel](https://github.com/dejan/rails_panel) Chrome 套件，在瀏覽器的開發工具顯示 `development.log` 的內容。提供像是資料庫查詢時間、算繪時間、總時間、參數列表、算繪的 View 等資訊。

參考資料
-------

* [ruby-debug Homepage](http://bashdb.sourceforge.net/ruby-debug/home-page.html)
* [debugger Homepage](https://github.com/cldwalker/debugger)
* [byebug Homepage](https://github.com/deivid-rodriguez/byebug)
* [Article: Debugging a Rails application with ruby-debug](http://www.sitepoint.com/debug-rails-app-ruby-debug/)
* [Ryan Bates' debugging ruby (revised) screencast](http://railscasts.com/episodes/54-debugging-ruby-revised)
* [Ryan Bates' stack trace screencast](http://railscasts.com/episodes/24-the-stack-trace)
* [Ryan Bates' logger screencast](http://railscasts.com/episodes/56-the-logger)
* [Debugging with ruby-debug](http://bashdb.sourceforge.net/ruby-debug.html)
