Action Mailer 基礎
===================

本篇提供收寄信所需要了解的所有知識，Action Mailer 內部工作原理以及如何測試 Mailer。

讀完本篇，您將了解：

* 如何在 Rails 裡寄信收信。
* 如何產生、編輯 Action Mailer 的類別與 View。
* 如何針對環境設定 Action Mailer。
* 如何測試 Action Mailer。

--------------------------------------------------------------------------------

簡介
----

Action Mailer 允許在應用程式裡使用 Mailer 類別與 View 來寄信。Mailer 的動作原理類似於 Controller。Action Mailer 繼承自 `ActionMailer::Base`，檔案放在 `app/mailers`，與信件有關的 View 一樣放在 `app/views`。

寄信
----

本節一步一步介紹如何建立 Mailer，以及相關的 View。

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

如上所見，可以使用產生器來產生 Mailer。Mailer 概念上類似於 Controller，產生的檔案也類似：有 Mailer、放信件 View 的目錄，以及測試。

若不想使用產生器，可以自己在 `app/mailers` 建立檔案，記得繼承自 `ActionMailer::Base`：

```ruby
class MyMailer < ActionMailer::Base
end
```

#### 編輯 Mailer

Mailer 和 Controller 非常類似。方法都叫做“動作”，用 View 來組織信件內容。但 Controller 是產生 HTML，回給客戶端；Mailer 則是建立訊息，透過信件寄出。

剛剛產生出來的 `app/mailers/user_mailer.rb` 檔案裡，有空的 Mailer：

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

以下是 `welcome_email` 的快速說明。所有可用的選項請參考[〈Action Mailer user-settable attributes〉]()一節。

* `default` ── 任何使用這個 Mailer 送出的信件的預設值都存在這個 Hash 裡。上例設定了 `:from` 標頭為 `'notifications@example.com'`。所有發出去的信件都會採用這個預設值，但可以在動作裡覆蓋。
* `mail` ── 寄信的方法。上例傳入了 `:to` 與 `:subject` 這兩個標頭。

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

呼叫 `mail` 方法時，Action Mailer 會偵測出有兩個模版（純文字與 HTML），會自動產生 `multipart/alternative` 的信件。

#### 呼叫 Mailer

Mailer 其實只是另一種算繪 View 的方式，只是算繪的 View 不透過 HTTP 協定送出，而是透過 Email 協定送出。也是因為這個原因，使用者成功建立之後，應該用 Controller 呼叫 mailer 來寄信。

設定起來非常非常簡單。

首先，建立一個簡單的 `User` 鷹架：

```bash
$ bin/rails generate scaffold user name email login
$ bin/rake db:migrate
```

現在有了可以實驗的 `User` Model，打開 `app/controllers/users_controller.rb`，修改 `create` 動作，在成功新建使用者之後，讓 Controller 呼叫 `UserMailer` 寄信出去。將 `UserMailer.welcome_email` 這一行放到使用者成功儲存之後：

```ruby
class UsersController < ApplicationController
  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        # Tell the UserMailer to send a welcome email after save
        UserMailer.welcome_email(@user).deliver

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

`welcome_email` 會回傳 `Mail::Message` 物件，對這個物件呼叫 `deliver` 便會送出信件。

### 自動對標頭編碼

Action Mailer 會自動對標頭與信件主體裡的多位元組字元編碼。

定義其它字元組、自編碼純文字等更複雜的範例，請參考 [Mail](https://github.com/mikel/mail) 函式庫。

### Action Mailer 方法清單

任何信件有三個方法最為重要：

* `headers` ── 指定信件的標頭。可以用 Hash 傳入欄位名與數值，或是呼叫 `headers[:field_name] = 'value'`。
* `attachments` ── 加入附件到信件。例如，`attachments['file-name.jpg'] = File.read('file-name.jpg')`。
* `mail` ── 寄出實際信件。可以將標頭作為 Hash 傳給 `mail` 作為參數。`mail` 會新建一封信，純文字或是多種格式（multipart），取決於定義的模版是那種。

#### 新增附件

Action Mailer 把新增附件變得非常簡單。


* Pass the file name and content and Action Mailer and the
  [Mail gem](https://github.com/mikel/mail) will automatically guess the
  mime_type, set the encoding and create the attachment.

    ```ruby
    attachments['filename.jpg'] = File.read('/path/to/filename.jpg')
    ```

  When the `mail` method will be triggered, it will send a multipart email with
  an attachment, properly nested with the top level being `multipart/mixed` and
  the first part being a `multipart/alternative` containing the plain text and
  HTML email messages.

NOTE: Mail will automatically Base64 encode an attachment. If you want something
different, encode your content and pass in the encoded content and encoding in a
`Hash` to the `attachments` method.

* Pass the file name and specify headers and content and Action Mailer and Mail
  will use the settings you pass in.

    ```ruby
    encoded_content = SpecialEncode(File.read('/path/to/filename.jpg'))
    attachments['filename.jpg'] = {mime_type: 'application/x-gzip',
                                   encoding: 'SpecialEncoding',
                                   content: encoded_content }
    ```

NOTE: If you specify an encoding, Mail will assume that your content is already
encoded and not try to Base64 encode it.

#### Making Inline Attachments

Action Mailer 3.0 makes inline attachments, which involved a lot of hacking in pre 3.0 versions, much simpler and trivial as they should be.

* First, to tell Mail to turn an attachment into an inline attachment, you just call `#inline` on the attachments method within your Mailer:

    ```ruby
    def welcome
      attachments.inline['image.jpg'] = File.read('/path/to/image.jpg')
    end
    ```

* Then in your view, you can just reference `attachments` as a hash and specify
  which attachment you want to show, calling `url` on it and then passing the
  result into the `image_tag` method:

    ```html+erb
    <p>Hello there, this is our image</p>

    <%= image_tag attachments['image.jpg'].url %>
    ```

* As this is a standard call to `image_tag` you can pass in an options hash
  after the attachment URL as you could for any other image:

    ```html+erb
    <p>Hello there, this is our image</p>

    <%= image_tag attachments['image.jpg'].url, alt: 'My Photo',
                                                class: 'photos' %>
    ```

#### Sending Email To Multiple Recipients

It is possible to send email to one or more recipients in one email (e.g.,
informing all admins of a new signup) by setting the list of emails to the `:to`
key. The list of emails can be an array of email addresses or a single string
with the addresses separated by commas.

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

The same format can be used to set carbon copy (Cc:) and blind carbon copy
(Bcc:) recipients, by using the `:cc` and `:bcc` keys respectively.

#### Sending Email With Name

Sometimes you wish to show the name of the person instead of just their email
address when they receive the email. The trick to doing that is to format the
email address in the format `"Full Name <email>"`.

```ruby
def welcome_email(user)
  @user = user
  email_with_name = "#{@user.name} <#{@user.email}>"
  mail(to: email_with_name, subject: 'Welcome to My Awesome Site')
end
```

### Mailer Views

Mailer views are located in the `app/views/name_of_mailer_class` directory. The
specific mailer view is known to the class because its name is the same as the
mailer method. In our example from above, our mailer view for the
`welcome_email` method will be in `app/views/user_mailer/welcome_email.html.erb`
for the HTML version and `welcome_email.text.erb` for the plain text version.

To change the default mailer view for your action you do something like:

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

In this case it will look for templates at `app/views/notifications` with name
`another`.  You can also specify an array of paths for `template_path`, and they
will be searched in order.

If you want more flexibility you can also pass a block and render specific
templates or even render inline or text without using a template file:

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

This will render the template 'another_template.html.erb' for the HTML part and
use the rendered text for the text part. The render command is the same one used
inside of Action Controller, so you can use all the same options, such as
`:text`, `:inline` etc.

### Action Mailer Layouts

Just like controller views, you can also have mailer layouts. The layout name
needs to be the same as your mailer, such as `user_mailer.html.erb` and
`user_mailer.text.erb` to be automatically recognized by your mailer as a
layout.

In order to use a different file, call `layout` in your mailer:

```ruby
class UserMailer < ActionMailer::Base
  layout 'awesome' # use awesome.(html|text).erb as the layout
end
```

Just like with controller views, use `yield` to render the view inside the
layout.

You can also pass in a `layout: 'layout_name'` option to the render call inside
the format block to specify different layouts for different formats:

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

Will render the HTML part using the `my_layout.html.erb` file and the text part
with the usual `user_mailer.text.erb` file if it exists.

### Generating URLs in Action Mailer Views

Unlike controllers, the mailer instance doesn't have any context about the
incoming request so you'll need to provide the `:host` parameter yourself.

As the `:host` usually is consistent across the application you can configure it
globally in `config/application.rb`:

```ruby
config.action_mailer.default_url_options = { host: 'example.com' }
```

#### generating URLs with `url_for`

You need to pass the `only_path: false` option when using `url_for`. This will
ensure that absolute URLs are generated because the `url_for` view helper will,
by default, generate relative URLs when a `:host` option isn't explicitly
provided.

```erb
<%= url_for(controller: 'welcome',
            action: 'greeting',
            only_path: false) %>
```

If you did not configure the `:host` option globally make sure to pass it to
`url_for`.


```erb
<%= url_for(host: 'example.com',
            controller: 'welcome',
            action: 'greeting') %>
```

NOTE: When you explicitly pass the `:host` Rails will always generate absolute
URLs, so there is no need to pass `only_path: false`.

#### generating URLs with named routes

Email clients have no web context and so paths have no base URL to form complete
web addresses. Thus, you should always use the "_url" variant of named route
helpers.

If you did not configure the `:host` option globally make sure to pass it to the
url helper.

```erb
<%= user_url(@user, host: 'example.com') %>
```

### Sending Multipart Emails

Action Mailer will automatically send multipart emails if you have different
templates for the same action. So, for our UserMailer example, if you have
`welcome_email.text.erb` and `welcome_email.html.erb` in
`app/views/user_mailer`, Action Mailer will automatically send a multipart email
with the HTML and text versions setup as different parts.

The order of the parts getting inserted is determined by the `:parts_order`
inside of the `ActionMailer::Base.default` method.

### Sending Emails with Dynamic Delivery Options

If you wish to override the default delivery options (e.g. SMTP credentials)
while delivering emails, you can do this using `delivery_method_options` in the
mailer action.

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

### Sending Emails without Template Rendering

There may be cases in which you want to skip the template rendering step and
supply the email body as a string. You can achieve this using the `:body`
option. In such cases don't forget to add the `:content_type` option. Rails
will default to `text/plain` otherwise.

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

Receiving Emails
----------------

Receiving and parsing emails with Action Mailer can be a rather complex
endeavor. Before your email reaches your Rails app, you would have had to
configure your system to somehow forward emails to your app, which needs to be
listening for that. So, to receive emails in your Rails app you'll need to:

* Implement a `receive` method in your mailer.

* Configure your email server to forward emails from the address(es) you would
  like your app to receive to `/path/to/app/bin/rails runner
  'UserMailer.receive(STDIN.read)'`.

Once a method called `receive` is defined in any mailer, Action Mailer will
parse the raw incoming email into an email object, decode it, instantiate a new
mailer, and pass the email object to the mailer `receive` instance
method. Here's an example:

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

Action Mailer Callbacks
---------------------------

Action Mailer allows for you to specify a `before_action`, `after_action` and
`around_action`.

* Filters can be specified with a block or a symbol to a method in the mailer
  class similar to controllers.

* You could use a `before_action` to populate the mail object with defaults,
  delivery_method_options or insert default headers and attachments.

* You could use an `after_action` to do similar setup as a `before_action` but
  using instance variables set in your mailer action.

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

* Mailer Filters abort further processing if body is set to a non-nil value.

Using Action Mailer Helpers
---------------------------

Action Mailer now just inherits from `AbstractController`, so you have access to
the same generic helpers as you do in Action Controller.

Action Mailer Configuration
---------------------------

The following configuration options are best made in one of the environment
files (environment.rb, production.rb, etc...)

| Configuration | Description |
|---------------|-------------|
|`logger`|Generates information on the mailing run if available. Can be set to `nil` for no logging. Compatible with both Ruby's own `Logger` and `Log4r` loggers.|
|`smtp_settings`|Allows detailed configuration for `:smtp` delivery method:<ul><li>`:address` - Allows you to use a remote mail server. Just change it from its default "localhost" setting.</li><li>`:port` - On the off chance that your mail server doesn't run on port 25, you can change it.</li><li>`:domain` - If you need to specify a HELO domain, you can do it here.</li><li>`:user_name` - If your mail server requires authentication, set the username in this setting.</li><li>`:password` - If your mail server requires authentication, set the password in this setting.</li><li>`:authentication` - If your mail server requires authentication, you need to specify the authentication type here. This is a symbol and one of `:plain`, `:login`, `:cram_md5`.</li><li>`:enable_starttls_auto` - Set this to `false` if there is a problem with your server certificate that you cannot resolve.</li></ul>|
|`sendmail_settings`|Allows you to override options for the `:sendmail` delivery method.<ul><li>`:location` - The location of the sendmail executable. Defaults to `/usr/sbin/sendmail`.</li><li>`:arguments` - The command line arguments to be passed to sendmail. Defaults to `-i -t`.</li></ul>|
|`raise_delivery_errors`|Whether or not errors should be raised if the email fails to be delivered. This only works if the external email server is configured for immediate delivery.|
|`delivery_method`|Defines a delivery method. Possible values are:<ul><li>`:smtp` (default), can be configured by using `config.action_mailer.smtp_settings`.</li><li>`:sendmail`, can be configured by using `config.action_mailer.sendmail_settings`.</li><li>`:file`: save emails to files; can be configured by using `config.action_mailer.file_settings`.</li><li>`:test`: save emails to `ActionMailer::Base.deliveries` array.</li></ul>See [API docs](http://api.rubyonrails.org/classes/ActionMailer/Base.html) for more info.|
|`perform_deliveries`|Determines whether deliveries are actually carried out when the `deliver` method is invoked on the Mail message. By default they are, but this can be turned off to help functional testing.|
|`deliveries`|Keeps an array of all the emails sent out through the Action Mailer with delivery_method :test. Most useful for unit and functional testing.|
|`default_options`|Allows you to set default values for the `mail` method options (`:from`, `:reply_to`, etc.).|

For a complete writeup of possible configurations see the
[Action Mailer section](configuring.html#configuring-action-mailer) in
our Configuring Rails Applications guide.

### Example Action Mailer Configuration

An example would be adding the following to your appropriate
`config/environments/$RAILS_ENV.rb` file:

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

### Action Mailer Configuration for Gmail

As Action Mailer now uses the [Mail gem](https://github.com/mikel/mail), this
becomes as simple as adding to your `config/environments/$RAILS_ENV.rb` file:

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

Mailer Testing
--------------

You can find detailed instructions on how to test your mailers in the
[testing guide](testing.html#testing-your-mailers).

Intercepting Emails
-------------------
There are situations where you need to edit an email before it's
delivered. Fortunately Action Mailer provides hooks to intercept every
email. You can register an interceptor to make modifications to mail messages
right before they are handed to the delivery agents.

```ruby
class SandboxEmailInterceptor
  def self.delivering_email(message)
    message.to = ['sandbox@example.com']
  end
end
```

Before the interceptor can do its job you need to register it with the Action
Mailer framework. You can do this in an initializer file
`config/initializers/sandbox_email_interceptor.rb`

```ruby
ActionMailer::Base.register_interceptor(SandboxEmailInterceptor) if Rails.env.staging?
```

NOTE: The example above uses a custom environment called "staging" for a
production like server but for testing purposes. You can read
[Creating Rails environments](./configuring.html#creating-rails-environments)
for more information about custom Rails environments.
