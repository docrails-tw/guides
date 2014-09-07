Action Mailer 基礎
===================

本篇提供收發信所需要了解的所有知識，包含 Action Mailer 內部工作原理以及如何測試 Mailer。

讀完本篇，您將了解：

* 如何在 Rails 裡寄信收信。
* 如何產生、編輯 Action Mailer 的類別與 View。
* 如何針對環境設定 Action Mailer。
* 如何測試 Action Mailer。

--------------------------------------------------------------------------------

簡介
----

Action Mailer 允許在應用程式裡使用 Mailer 類別與 View 來寄信。Mailer 的工作原理和 Controller 類似。Action Mailer 繼承自 `ActionMailer::Base`，檔案放在 `app/mailers`，與信件有關的 View 一樣放在 `app/views`。

寄信
----

本節逐步介紹如何建立 Mailer，以及相關的 View。

### 產生 Mailer 的步驟

#### 新建 Mailer

```bash
$ bin/rails generate mailer UserMailer
create  app/mailers/user_mailer.rb
invoke  erb
create    app/views/user_mailer
invoke  test_unit
create    test/mailers/user_mailer_test.rb
```

如上所見，可以使用產生器來產生 Mailer。Mailer 概念上類似於 Controller，產生的檔案也差不多：有 Mailer、放信件內容的目錄（View），以及測試 Mailer 的檔案。

若不想使用產生器，可以自己在 `app/mailers` 建立檔案，記得要繼承 `ActionMailer::Base`：

```ruby
class MyMailer < ActionMailer::Base
end
```

#### 編輯 Mailer

Mailer 和 Controller 非常類似。方法都叫做“動作”，用 View 來組織信件內容。但 Controller 是產生 HTML，回給客戶端；然而 Mailer 則是建立訊息，透過信件寄出。

看看剛剛產生出來的 `UserMailer`（`app/mailers/user_mailer.rb`）：

```ruby
class UserMailer < ActionMailer::Base
  default from: 'from@example.com'
end
```

新增一個方法，稱之為 `welcome_email`，會寄信給使用者註冊的信箱：

```ruby
class UserMailer < ActionMailer::Base
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email, subject: 'Welcome to My Awesome Site')
  end
end
```

以下是 `welcome_email` 的快速說明。關於 Action Mailer 所有可用的選項請參考[〈Action Mailer 設定〉](#action-mailer-設定)一節。

* `default` ─ 任何使用這個 Mailer 送出的信件，預設值都存在這個 Hash 裡。上例設定了 `:from` 設為 `'notifications@example.com'`。所有發出去的信都會採用這個預設值，但可以在動作裡覆蓋。
* `mail` ─ 寄信的方法。上例傳入了 `:to` 與 `:subject` 這兩個標頭（Header）。

和 Controller 一樣，動作裡定義的實體變數，在 View 裡都可以取用。

#### 建立 Mailer 的 View

在 `app/views/user_mailer/` 新建叫做 `welcome_email.html.erb` 檔案。這個檔案會是信件的模版，採用 HTML 格式：

```html+erb
<!DOCTYPE html>
<html>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
  </head>
  <body>
    <h1>Welcome to example.com, <%= @user.name %></h1>
    <p>
      You have successfully signed up to example.com,
      your username is: <%= @user.login %>.<br>
    </p>
    <p>
      To login to the site, just follow this link: <%= @url %>.
    </p>
    <p>Thanks for joining and have a great day!</p>
  </body>
</html>
```

再給信件建立一個純文字檔案。因為不是所有客戶端都可以顯示 HTML 格式的信件，兩種格式都寄是最佳實踐。在 `app/views/user_mailer/` 建立 `welcome_email.text.erb`：

```erb
Welcome to example.com, <%= @user.name %>
===============================================

You have successfully signed up to example.com,
your username is: <%= @user.login %>.

To login to the site, just follow this link: <%= @url %>.

Thanks for joining and have a great day!
```

呼叫 `mail` 方法時，Action Mailer 會偵測出有兩個模版（純文字與 HTML），會自動產生類型為 `multipart/alternative` 的信件。

#### 呼叫 Mailer

Mailer 其實只是另一種算繪（render） View 的方式，只是算繪的 View 不透過 HTTP 協定送出，而是透過 Email 協定送出。也是因為這個原因，成功建立使用者之後，應該用 Controller 呼叫 mailer 來寄信。

設定起來非常非常簡單。

首先，用鷹架建立簡單的 `User` ：

```bash
$ bin/rails generate scaffold user name email login
$ bin/rake db:migrate
```

現在有了可以實驗的 `User` Model，打開 `app/controllers/users_controller.rb`，修改 `create` 動作，在成功新建使用者之後，讓 Controller 呼叫 `UserMailer` 寄信出去。將 `UserMailer.welcome_email` 這一行，放到成功儲存使用者之後。

Action Mailer 最近與 Active Job 整併，現在可以在請求響應週期之外寄送信件（背景執行），而無需使用者等候。

```ruby
class UsersController < ApplicationController
  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        # Tell the UserMailer to send a welcome email after save
        UserMailer.welcome_email(@user).deliver_later

        format.html { redirect_to(@user, notice: 'User was successfully created.') }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
end
```

NOTE: Active Job 的預設行為是即刻（`:inline`）執行任務，要馬上寄出信件現在用 `deliver_later` 即可。之後要改成背景執行也很簡單，給 Active Job 設定一個佇列後台即可（比如 Sidekiq、Resque 等）。

若想馬上寄出信件（比如在定時任務裡），只要呼叫 `deliver_now` 即可：

```ruby
class SendWeeklySummary
  def run
    User.find_each do |user|
      UserMailer.weekly_summary(user).deliver_now
    end
  end
end
```

`welcome_email` 會回傳 `Mail::Message` 物件，對這個物件呼叫 `deliver_now` 或 `deliver_later` 便會將信件發送出去。`ActionMailer::MessageDelivery` 物件不過是 `Mail::Message` 物件的封裝。若想查看、修改 `Mail::Message` 物件，可以對 `ActionMailer::MessageDelivery` 呼叫 `message` 方法，來獲得 `Mail::Message` 物件。

### 自動對標頭編碼

Action Mailer 會自動對標頭（header）與信件主體（body）裡的多位元組字元進行編碼。

定義其它字元組、自編碼純文字等更複雜的範例，請參考 [Mail](https://github.com/mikel/mail) 函式庫的說明文件。

### Action Mailer 方法清單

有三個方法最為重要：

* `headers` ─ 指定信件的標頭。可以用 Hash 傳入欄位名與數值，或是使用 `headers[:field_name] = 'value'` 進行設定。
* `attachments` ─ 加入附件到信件。例如，`attachments['file-name.jpg'] = File.read('file-name.jpg')`。
* `mail` ─ 寄出實際信件。可以將標頭作為 Hash 傳給 `mail` 作為參數。`mail` 會新建一封信，純文字或是多種格式（multipart），取決於定義的模版是那種。

#### 新增附件

Action Mailer 把新增附件變得非常簡單。

* 傳入檔名與內容，Action Mailer 與 [Mail gem](https://github.com/mikel/mail) 會自動推論出 `mime_type`，設定編碼、建立附件。

    ```ruby
    attachments['filename.jpg'] = File.read('/path/to/filename.jpg')
    ```

  觸發 `mail` 方法之後，會寄出由多個部分組成的 Email，附件會嵌套在 `multipart/mixed` 類型裡，`multipart/mixed` 第一個部分是 `multipart/alternative`，包含 HTML 與純文字格式的信件，接著是附件。

NOTE: Mail 會自動使用 Base64 來對附件做編碼。若想用不同的編碼，先自行編碼，再使用 Hash 傳給 `attachments` 方法。

* 傳入檔名、指定標頭與內容，Action Mailer 與 Mail 會使用傳入的設定來新增附件。

    ```ruby
    encoded_content = SpecialEncode(File.read('/path/to/filename.jpg'))
    attachments['filename.jpg'] = {
      mime_type: 'application/x-gzip',
      encoding: 'SpecialEncoding',
      content: encoded_content
    }
    ```

NOTE: 如有指定編碼，Mail 會假設信件內容已經經過編碼了，不會再對附件做 Base64 編碼。

#### 製作行內附件

Action Mailer 3.0 起可製作行內附件（inline attachments）。3.0 以前需要很多 Hacking 才辦的到，3.0 之後，行內附件使用起來變得非常簡單直觀。

* 首先，告訴 Mail 將附件轉成行內附件。只要對 `attachments` 方法呼叫 `#inline` 即可：

    ```ruby
    def welcome
      attachments.inline['image.jpg'] = File.read('/path/to/image.jpg')
    end
    ```

* 接著在 View 裡，可以把 `attachments` 當成 Hash，指定要顯示的附件，對附件呼叫 `url`，接著傳給 `image_tag`：

    ```html+erb
    <p>Hello there, this is our image</p>

    <%= image_tag attachments['image.jpg'].url %>
    ```

* 這不過是 `image_tag` 的標準呼叫方式，附件 URL 之後還可以傳別的選項：

    ```html+erb
    <p>Hello there, this is our image</p>

    <%= image_tag attachments['image.jpg'].url, alt: 'My Photo',
                                                class: 'photos' %>
    ```

#### 寄信給多個收件者

可能會需要將信一次寄給多個人（譬如有人註冊通知所有的管理員），透過將 `:to` 設定成一組 Email 即可。一組 Email 可以用陣列表示，或是由逗號分開的 Email 字串。

```ruby
class AdminMailer < ActionMailer::Base
  default to: Proc.new { Admin.pluck(:email) },
          from: 'notification@example.com'

  def new_registration(user)
    @user = user
    mail(subject: "New User Signup: #{@user.email}")
  end
end
```

同樣的格式也可以用來設定副本與密件副本，分別設定 `:cc` 與 `:bcc` 即可。

#### 使用名稱寄信

有時希望收件者可看到寄件者的名稱，而不是寄件者的 Email。秘訣是以 `"Full Name <email>"` 格式書寫 Email 地址。

```ruby
def welcome_email(user)
  @user = user
  email_with_name = %("#{@user.name}" <#{@user.email}>)
  mail(to: email_with_name, subject: 'Welcome to My Awesome Site')
end
```

### Mailer Views

Mailer views 檔案在 `app/views/name_of_mailer_class` 目錄下。Mailer 之所以知道要使用那個 View，是因為 View 的名稱和 Mailer 的方法同名。上面的例子裡，`welcome_email` 方法的 View 的 HTML 格式會存在 `app/views/user_mailer/welcome_email.html.erb`；純文字格式則是 `app/views/user_mailer/welcome_email.text.erb`。

要修改 Mailer 動作預設使用的 View，可以這麼做：

```ruby
class UserMailer < ActionMailer::Base
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: 'Welcome to My Awesome Site',
         template_path: 'notifications',
         template_name: 'another')
  end
end
```

這個例子 `UserMailer` 會去 `app/views/notifications` 尋找 `another` 這個 View。`template_path` 也可以是一組路徑（陣列形式），會依序在路徑下搜索 View。

若想更靈活的話，也可以傳入區塊，在區塊內明確算繪要用的模版，或是不使用模版，直接傳入字串也可以：

```ruby
class UserMailer < ActionMailer::Base
  default from: 'notifications@example.com'

  def welcome_email(user)
    @user = user
    @url  = 'http://example.com/login'
    mail(to: @user.email,
         subject: 'Welcome to My Awesome Site') do |format|
      format.html { render 'another_template' }
      format.text { render text: 'Render text' }
    end
  end
end
```

上例程式會使用 `another_template.html.erb` 來算繪出 HTML 格式的信件，使用 `'Render text'` 來算繪純文字格式。`render` 方法與 Action Controller 內的 `render` 相同，接受同樣選項，像是 `:text`、`:inline` 等。

### Action Mailer 版型

和 Controller 的 View 類似，可以有 Mailer 版型（layout）。版型名稱必須與 Mailer 名稱相同，譬如 `user_mailer.html.erb` 或 `user_mailer.text.erb`，才可以自動視為是 Mailer 所使用的版型。

為了要使用不同的版型，在 Mailer 裡呼叫 `layout` 方法：

```ruby
class UserMailer < ActionMailer::Base
  layout 'awesome' # use awesome.(html|text).erb as the layout
end
```

和 Controller View 一樣，在版型裡使用 `yield` 來算繪 View。

也可以在算繪呼叫裡，傳入 `layout: 'layout_name'` 選項來指定版型：

```ruby
class UserMailer < ActionMailer::Base
  def welcome_email(user)
    mail(to: user.email) do |format|
      format.html { render layout: 'my_layout' }
      format.text
    end
  end
end
```

HTML 部分會使用 `my_layout.html.erb`，而純文字部分則會使用一般的 `user_mailer.text.erb` （如果存在的話）。

### 在 Action Mailer Views 產生 URL

跟 Controllers 不一樣，Mailer 實體不知道與請求有關的上下文，所以要自行提供 `:host` 參數。

通常應用程式裡的 `:host` 都是相同的，可以在 `config/application.rb` 一併設定：

```ruby
config.action_mailer.default_url_options = { host: 'example.com' }
```

因為這個設定的關係，Email 裡不可以使用任何的 `*_path` 輔助方法，要用 `*_url`。譬如之前是：

```
<%= link_to 'welcome', welcome_path %>
```

會需要改為：

```
<%= link_to 'welcome', welcome_url %>
```

使用完整的 URL，Email 裡的連結才會正常工作。

#### 使用 `url_for` 產生 URL

使用 `url_for` 時，需要傳入 `only_path: false` 選項。確保產生的是絕對 URL，因為 `url_for` 輔助方法預設會產生相對 URL。

```erb
<%= url_for(controller: 'welcome',
            action: 'greeting',
            only_path: false) %>
```

若沒有全域設定 `:host`，記得在用 `url_for` 時要傳進來。

```erb
<%= url_for(host: 'example.com',
            controller: 'welcome',
            action: 'greeting') %>
```

NOTE: 當明確傳入 `:host` 時，Rails 會產生絕對 URL，所以不需要再指定 `only_path: false`。

#### 使用具名路由產生 URL

Email 客戶端對 Web 一無所知，無法根據某個基礎 URL 來產生完整的 URL。因此，具名路由應該要永遠使用 `*_url`。


若沒有全域設定 `:host`，記得要傳進來。

```erb
<%= user_url(@user, host: 'example.com') %>
```

### 寄送多種格式的 Email

如果 Action Mailer 的動作有多個模版，Action Mailer 會自動寄出多種格式的 Email。在 `UserMailer` 例子裡，若 `app/views/user_mailer` 有 `welcome_email.text.erb` 以及 `welcome_email.html.erb`，則 Action Mailer 會自動寄出多種格式的 Email。

Email 格式收到的順序由 `ActionMailer::Base.default` 方法裡的 `:parts_order` 決定。

### 使用動態發送選項來寄信

若想送信時覆蓋預設的發送選項（譬如 SMTP credential），可以在 Mailer 的動作裡使用 `delivery_method_options`。

```ruby
class UserMailer < ActionMailer::Base
  def welcome_email(user, company)
    @user = user
    @url  = user_url(@user)
    delivery_options = { user_name: company.smtp_user,
                         password: company.smtp_password,
                         address: company.smtp_host }
    mail(to: @user.email,
         subject: "Please see the Terms and Conditions attached",
         delivery_method_options: delivery_options)
  end
end
```

### 寄信但不使用模版

有些情況可能不想要使用模版，需要直接將信件主體（Email Body）作為字串送出。可以使用 `:body` 選項。同時記得要加上 `:content_type` 選項（Rails 預設是 `text/plain`）。

```ruby
class UserMailer < ActionMailer::Base
  def welcome_email(user, email_body)
    mail(to: user.email,
         body: email_body,
         content_type: "text/html",
         subject: "Already rendered!")
  end
end
```

收信
----------------

在 Action Mailer 接受與解析信件相對複雜許多。在信件送到 Rails 應用程式之前，需要設定作業系統轉發信件到 Rails，所以作業系統會需要監聽進來的信。總結在 Rails 裡收信會需要：

* 在 Mailer 實作 `receive` 方法。

* 設定郵件伺服器轉發信件到 `/path/to/app/bin/rails runner
  'UserMailer.receive(STDIN.read)'`。

一旦在任何 Mailer 裡定義了 `receive`，Action Mailer 會將進來的信件解析成 Email 物件、解碼、實體化新的 Mailer，接著將 Email 物件傳給 Mailer 的 `receive`。以下是範例：

```ruby
class UserMailer < ActionMailer::Base
  def receive(email)
    page = Page.find_by(address: email.to.first)
    page.emails.create(
      subject: email.subject,
      body: email.body
    )

    if email.has_attachments?
      email.attachments.each do |attachment|
        page.attachments.create({
          file: attachment,
          description: email.subject
        })
      end
    end
  end
end
```

Action Mailer 回呼
------------------

Action Mailer 允許指定 `before_action`、`after_action` 以及 `around_action` 回呼。

* 濾動器（filters）可用方法名稱（符號）指定，也可用區塊，和 Controller 指定方法類似。

* 可以使用 `before_action` 在寄信前對 Mailer 物件做處理，或是用 `delivery_method_options` 來設定預設值，插入預設的標頭、附件等。

* 可以使用 `after_action` 做和 `before_action` 類似的事情，但動作裡可以使用實體變數。

```ruby
class UserMailer < ActionMailer::Base
  after_action :set_delivery_options,
               :prevent_delivery_to_guests,
               :set_business_headers

  def feedback_message(business, user)
    @business = business
    @user = user
    mail
  end

  def campaign_message(business, user)
    @business = business
    @user = user
  end

  private

    def set_delivery_options
      # You have access to the mail instance,
      # @business and @user instance variables here
      if @business && @business.has_smtp_settings?
        mail.delivery_method.settings.merge!(@business.smtp_settings)
      end
    end

    def prevent_delivery_to_guests
      if @user && @user.guest?
        mail.perform_deliveries = false
      end
    end

    def set_business_headers
      if @business
        headers["X-SMTPAPI-CATEGORY"] = @business.code
      end
    end
end
```

* 若信件的 body 不是 `nil`，Mailer 的濾動器會終止處理。

使用 Action Mailer 的輔助方法
---------------------------

Action Mailer 只是繼承自 `AbstractController`，所以 Action Controller 有的通用輔助方法，Action Mailer 裡也有。

Action Mailer 設定
---------------------------

以下設定選項最好在跟環境相關的檔案裡設定（environment.rb, production.rb 等）。

| Configuration | Description |
|---------------|-------------|
|`logger`| 產生 Mailer 執行時的記錄檔。設為 `nil` 則不記錄。可以使用 Ruby 的 `Logger` 與 `log4r`。|
|`smtp_settings`| 用來設定 `:smtp` 發送方法：<ul><li>`:address` ─ 允許使用遠端郵件伺服器。預設是 `"localhost"`。</li><li>`:port` ─ 若郵件伺服器不是使用埠口 25，這個選項可以改。</li><li>`:domain` ─ 指定 HELO 網域。</li><li>`:user_name` ─ 如果郵件伺服器需要驗證身分，這個選項可以設定使用者名稱。</li><li>`:password` ─ 如果郵件伺服器需要驗證身分，這個選項可以設定密碼。</li><li>`:authentication` ─ 如果郵件伺服器需要驗證身分，這個選項可以設定驗證類型，可用的值有（符號）：`:plain`、`:login`、`:cram_md5`。</li><li>`:enable_starttls_auto` ─ 如果無法解析郵件伺服器的證書，把這個設定設為 `false`。</li></ul>|
|`sendmail_settings`| 設定 `:sendmail` 發送方法的選項。<ul><li>`:location` ─ `sendmail` 執行檔案的位置。預設是 `/usr/sbin/sendmail`。</li><li>`:arguments` ─ 傳給 `sendmail` 參數的命令列參數，預設是 `-i -t`。</li></ul>|
|`raise_delivery_errors`| 信件寄送失敗時是否要拋出錯誤。只在外部郵件伺服器設為立即送出時有效。|
|`delivery_method`| 定義送信的方法。可用的數值有：<ul><li>`:smtp`（預設值），可以透過 `config.action_mailer.smtp_settings` 來設定。</li><li>`:sendmail`，可以透過 `config.action_mailer.sendmail_settings` 來設定。</li><li>`:file`：把信件存成檔案。可以透過 `config.action_mailer.file_settings` 來設定。</li><li>`:test`：把信件存到 `ActionMailer::Base.deliveries` 陣列裡。</li></ul>參考 [API 文件](http://api.rubyonrails.org/classes/ActionMailer/Base.html)來了解更多資訊。|
|`perform_deliveries`| 決定 `deliver` 方法是否真的要送出信件。預設是會，但可以在做功能性測試時關掉。|
|`deliveries`| 由 Action Mailer 使用 `:test` 方法送出的信件保存到陣列裡。主要用來做功能性與單元測試。|
|`default_options`| 設定 `mail` 方法的預設值（如 `:from`、`:reply_to` 等）。|

完整設定選項請參考[《Rails 應用程式設定》文中的〈Action Mailer〉一節](configuring.html#configuring-action-mailer)。

### Action Mailer 設定範例

`config/environments/$RAILS_ENV.rb` 檔案關於 Mailer 的設定範例：

```ruby
config.action_mailer.delivery_method = :sendmail
# Defaults to:
# config.action_mailer.sendmail_settings = {
#   location: '/usr/sbin/sendmail',
#   arguments: '-i -t'
# }
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_options = {from: 'no-reply@example.com'}
```

### Action Mailer Gmail 設定範例

由於 Action Mailer 現在使用 [Mail gem](https://github.com/mikel/mail) 了，Gmail 的設定非常簡單，將下面的程式碼加到 `config/environments/$RAILS_ENV.rb` 檔案即可：

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:              'smtp.gmail.com',
  port:                 587,
  domain:               'example.com',
  user_name:            '<username>',
  password:             '<password>',
  authentication:       'plain',
  enable_starttls_auto: true  }
```

測試 Mailer
--------------

如何測試 Mailer 的詳細教學可以參考[測試指南](testing.html#testing-your-mailers)。

攔截 Email
-------------------

有時候需要在信件寄出前做些修改。Action Mailer 提供攔截 Email 的 hook。可以註冊一個攔截器，在信件內容交給發送服務前對信件做修改。

```ruby
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['sandbox@example.com']
  end
end
```

攔截器執行任務之前，需要先給 Action Mailer 打聲招呼。建立一個 initializer 檔案，`config/initializers/sandbox_email_interceptor.rb`：

```ruby
ActionMailer::Base.register_interceptor(SandboxEmailInterceptor) if Rails.env.staging?
```

NOTE: 上例使用了自訂的環境，叫做 “staging”，跟 production 環境類似，做測試之用。自訂 Rails 環境的更多資訊，請閱讀[建立 Rails 環境](configuring.html#creating-rails-environments)。
