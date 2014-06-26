Rails 算繪與版型
===============

本篇介紹 Action Controller 與 Action View 關於版型的基本功能

讀完本篇，您將了解：

* 如何使用 Rails 內建的算繪方法。
* 如何建立有多個內容區域的版型（Layout）。
* 如何使用部分頁面（Partial）來避免重複。
* 如何使用嵌套版型（子模版）。

--------------------------------------------------------------------------------

綜覽：MVC 協同合作
-------------------------------------

本篇著重介紹 MVC 鐵三角中，Controller 與 View 之間的互動關係。Controller 負責策劃處理請求（Request）的整個過程，但通常會把複雜的事情交給 Model 處理；要把響應（Response）回給使用者時，Controller 把事情交給 View 處理。Controller 如何將工作派給別人便是本篇要介紹的主題。

更完整的說，這個過程包含了，響應要傳送什麼內容，要呼叫那些方法來建立響應。如果響應是完整的 View，Rails 會做些額外工作，譬如會把 View 放到版型裡，或是把某個部分頁面加進來。本篇之後會完整介紹這整個過程。

建立響應
------------------

從 Controller 的觀點來看，有三種方法可以建立 HTTP 響應：

* 呼叫 `render` 方法，建立完整響應給瀏覽器。
* 呼叫 `redirect_to` 方法，來寄送 HTTP 轉址狀態給瀏覽器。
* 呼叫 `head` 方法，來建立只有 HTTP 標頭的響應給瀏覽器。

### 預設算繪：慣例勝於設定的實踐

你可能聽說過，Rails 遵行“慣例勝於設定”的原則。Rails 預設的算繪功能便是一個很好的例子。Controller 預設會算繪與路由同名的 View。舉例來說，若 `BooksController` 有如下程式：

```ruby
class BooksController < ApplicationController
end
```

而路由檔案裡有：

```ruby
resources :books
```

並有 View `app/views/books/index.html.erb`：

```html+erb
<h1>Books are coming soon!</h1>
```

則當你瀏覽 `/books` 時，Rails 會自動算繪 `app/views/books/index.html.erb` 這一頁。你會看到網頁裡顯示了 `"Books are coming soon!`。

然而只顯示 coming soon 的頁面沒有太大用處，很快的便會建立 `Book` Model，並給 `BooksController` 加入 `index` 動作：

```ruby
class BooksController < ApplicationController
  def index
    @books = Book.all
  end
end
```

注意到，基於“慣例勝於設定”原則，在 `index` 動作結尾並沒有明確執行“算繪”這個動作。這裡的慣例是，即便沒有在 Controller 動作結尾明確指定要“算繪”的頁面，Rails 也會自動在 Controller 的 View 路徑尋找 `action_name.html.erb` 模版，並算繪之。所以這個情況裡，Rails 會自動算繪 `app/views/books/index.html.erb`。

若想在 View 裡顯示所有書本的資訊，ERB 可以這麼寫：

```html+erb
<h1>Listing Books</h1>

<table>
  <tr>
    <th>Title</th>
    <th>Summary</th>
    <th></th>
    <th></th>
    <th></th>
  </tr>

<% @books.each do |book| %>
  <tr>
    <td><%= book.title %></td>
    <td><%= book.content %></td>
    <td><%= link_to "Show", book %></td>
    <td><%= link_to "Edit", edit_book_path(book) %></td>
    <td><%= link_to "Remove", book, method: :delete, data: { confirm: "Are you sure?" } %></td>
  </tr>
<% end %>
</table>

<br>

<%= link_to "New book", new_book_path %>
```

NOTE: 實際的算繪工作是由 `ActionView::TemplateHandlers` 的子類完成。本篇不深入探討整個過程，但有一點很重要，就是 View 的副檔名，決定了使用的模版處理器。從 Rails 2 起，Rails 標準的模版處理器是 ERB，副檔名是 `.erb`；另一個是 Builder（XML 產生器），副檔名是 `.builder` 。

### 使用 `render`

在多數情況下，`ActionController::Base#render` 方法，負責把應用程式要傳給瀏覽器的內容算繪好。`render` 的行為有多種方法可以客製化。可以給 Rails 的模版算繪預設的 View，或是算繪某個特定的模版，檔案，甚至是一段程式碼，或者什麼都不算繪，都可以。可以算繪純文字內容、JSON 或 XML。也可以指定 Content Type、HTTP 狀態碼等。

TIP: 若想不在瀏覽器，來看 `render` 方法的算繪結果，可以呼叫 `render_to_string`。這個方法接受的參數和 `render` 一樣，但回傳的是字串，而不是一般要回給瀏覽器的響應。

#### 什麼都不算繪

也許最簡單的 `render` 便是什麼也不算繪：

```ruby
render nothing: true
```

若使用 cURL 來檢視響應，會看到如下輸出：

```bash
$ curl -i 127.0.0.1:3000/books
HTTP/1.1 200 OK
Connection: close
Date: Sun, 24 Jan 2010 09:25:18 GMT
Transfer-Encoding: chunked
Content-Type: */*; charset=utf-8
X-Runtime: 0.014297
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache

$
```

可以看到一個空的響應（`Cache-Control` 之後沒有資料），但請求本身是成功的，因為 Rails 將響應的狀態設為 `200 OK`。可以透過 `render` 的 `:status` 選項來更改響應的狀態碼。“什麼都不算繪”對於 Ajax 的請求很有用，因為只是要跟瀏覽器確認請求已完成。

TIP: 應該要使用 `header` 方法，而不是 `render :nothing`，本篇稍後會介紹。`head` 的靈活性更高，明確的指定只需要產生 HTTP 標頭。

#### 算繪動作的 View

若想在 Controller 算繪不同的模版，可以使用 `render`，指定模版的名稱：

```ruby
def update
  @book = Book.find(params[:id])
  if @book.update(book_params)
    redirect_to(@book)
  else
    render "edit"
  end
end
```

若 `update` 動作失敗，則 Controller 會 `render` Controller 的 `edit.html.erb` 模版。

可以使用符號來明確指定要算繪的動作，字串是用來指定模版。

```ruby
def update
  @book = Book.find(params[:id])
  if @book.update(book_params)
    redirect_to(@book)
  else
    render :edit
  end
end
```

#### 從別的 Controller 算繪模版

要是想從別的 Controller 算繪別的 Controller 的模版怎麼辦？也可以使用 `render` 來達成，傳入要算繪模版的（相對於 `app/views`）路徑即可。舉例來說，`AdminProductsController` 放在 `app/controllers/admin`，想在 `AdminProductsController` 算繪 `app/views/products` 的模版可以這麼做：

```ruby
render "products/show"
```

Rails 會發現這個 View 屬於不同的 Controller，因為字串裡有斜線 `/`。若想更明確，可以用 `:template` 選項（Rails 2.2 之後）：

```ruby
render template: "products/show"
```

#### 算繪任何檔案

`render` 方法也接受在應用程式外的 View（也許是兩個 Rails 應用程式之間共享的 View）：

```ruby
render "/u/apps/warehouse_app/current/app/views/products/show"
```

Rails 知道這要算繪的是檔案，因為字串開頭有一個斜線。更明確一點可以用 `:file` 選項指定（Rails 2.2 之後）：

```ruby
render file: "/u/apps/warehouse_app/current/app/views/products/show"
```

`:file` 選項接受系統的絕對路徑，要算繪的檔案必須要有權限才行。

NOTE: 算繪檔案預設不會使用版型。若想 Rails 將算繪的檔案內容放入版型裡，需要加上 `layout: true` 選項。

TIP: 若想在 Microsoft Windows 執行 Rails，要算繪檔案必須要使用 `:file` 選項，因為 Windows 的檔名跟 Unix 的檔名格式不同。

#### 總結

上述三種算繪方法（算繪模版、算繪別的 Controller 的模版、算繪檔案）實際上都是同種動作的不同表現方式。

實際上，在 `BooksController` 類別裡，在 `update` 動作裡，書本更新失敗時，我們想算繪 `edit` 模版。以下的呼叫都會算繪 `app/views/books` 目錄下的 `edit.html.erb`：

```ruby
render :edit
render action: :edit
render "edit"
render "edit.html.erb"
render action: "edit"
render action: "edit.html.erb"
render "books/edit"
render "books/edit.html.erb"
render template: "books/edit"
render template: "books/edit.html.erb"
render "/path/to/rails/app/views/books/edit"
render "/path/to/rails/app/views/books/edit.html.erb"
render file: "/path/to/rails/app/views/books/edit"
render file: "/path/to/rails/app/views/books/edit.html.erb"
```

用那一種完全取決於風格與慣例，但最佳實踐表示，用最能反映出程式實際情況的最簡形式最好。

#### 使用 `render` 的 `:inline` 選項

`render` 方法完全可以不使用 View 模版。使用 `:inline` 選項（“內聯算繪”），提供一段 ERB 程式碼即可。以下是完全合法的呼叫：

```ruby
render inline: "<% products.each do |p| %><p><%= p.name %></p><% end %>"
```

WARNING: 這個選項很少有用它的好理由。把 ERB 混入 Controller 違反了 Rails 的 MVC 原則，這也讓一起開發的開發者，更難理解專案的邏輯。把要算繪的內容放到另一個 ERB 模版比較好。

預設的“內聯算繪”使用 ERB 作為模版。可以使用 `:type` 來指定別的模版處理器，譬如使用 Builder：

```ruby
render inline: "xml.p {'Horrid coding practice!'}", type: :builder
```

#### 算繪純文字

要給瀏覽器發純文字，不含標記語言。使用 `render` 的 `:plain` 選項：

```ruby
render plain: "OK"
```

TIP: 算繪純文字最主要的用途是回應 Ajax ，或只需要回純文字的 Web Service。

NOTE: 若使用了 `:plain` 選項，文字算繪時不會使用版型。若想 Rails 將算繪的純文字放入版型，需要加上 `layout: true` 選項。

#### 算繪 HTML

給瀏覽器發 HTML，使用 `render` 的 `:html` 選項：

```ruby
render html: "<strong>Not Found</strong>".html_safe
```

TIP: 要算繪一小段 HTML 可能有用。稍微複雜點可能就考慮放到單獨的檔案裡比較好。

NOTE: 若字串不是 HTML 安全的，會自動對 HTML 進行跳脫字元處理。

#### 算繪 JSON

JSON 是一種許多 Ajax 函式庫採用的 JavaScript 資料格式。Rails 原生支援物件到 JSON 的轉換，並將 JSON 算繪完回給瀏覽器：

```ruby
render json: @product
```

TIP: 不需要對要算繪的物件呼叫 `to_json`。使用了 `:json` 選項自動會對物件呼叫 `to_json`。

#### 算繪 XML

Rails 也內建轉換物件到 XML、XML 回給呼叫者的支援：

```ruby
render xml: @product
```

TIP: 不需要對要算繪的物件呼叫 `to_xml`。使用了 `:json` 選項自動會對物件呼叫 `to_xml`。

#### 算繪純 JavaScript

Rails 可以算繪純 JavaScript：

```ruby
render js: "alert('Hello Rails');"
```

這會把 MIME 類型設定為 `text/javascript`，再將字串傳給瀏覽器，

#### 算繪未經處理的內容

可以把未經處理的內容發給瀏覽器，而無需設定 Content-Type，使用 `render` 的 `:body` 選項：

```ruby
render body: "raw"
```

TIP: 這個選項應該在不在意響應的 Content-Type 時使用。使用 `:plain` 或 `:html` 在多數情況下更合理。

NOTE: 使用 `:body` 選項，響應的內容類型會是 `text/html`，這是 Action Dispatch 響應預設的 Content-Type。

#### `render` 接受的選項

`render` 方法通常接受如下選項：

* `:content_type`
* `:layout`
* `:location`
* `:status`

##### `:content_type` 選項

By default, Rails will serve the results of a rendering operation with the MIME content-type of `text/html` (or `application/json` if you use the `:json` option, or `application/xml` for the `:xml` option.). There are times when you might like to change this, and you can do so by setting the `:content_type` option:

```ruby
render file: filename, content_type: "application/rss"
```

##### `:layout` 選項

With most of the options to `render`, the rendered content is displayed as part of the current layout. You'll learn more about layouts and how to use them later in this guide.

You can use the `:layout` option to tell Rails to use a specific file as the layout for the current action:

```ruby
render layout: "special_layout"
```

You can also tell Rails to render with no layout at all:

```ruby
render layout: false
```

##### `:location` 選項

You can use the `:location` option to set the HTTP `Location` header:

```ruby
render xml: photo, location: photo_url(photo)
```

##### `:status` 選項

Rails will automatically generate a response with the correct HTTP status code (in most cases, this is `200 OK`). You can use the `:status` option to change this:

```ruby
render status: 500
render status: :forbidden
```

Rails understands both numeric status codes and the corresponding symbols shown below.

| 響應類別              | HTTP 狀態碼       | 對應符號                           |
| ------------------- | ---------------- | -------------------------------- |
| **Informational**   | 100              | :continue                        |
|                     | 101              | :switching_protocols             |
|                     | 102              | :processing                      |
| **Success**         | 200              | :ok                              |
|                     | 201              | :created                         |
|                     | 202              | :accepted                        |
|                     | 203              | :non_authoritative_information   |
|                     | 204              | :no_content                      |
|                     | 205              | :reset_content                   |
|                     | 206              | :partial_content                 |
|                     | 207              | :multi_status                    |
|                     | 208              | :already_reported                |
|                     | 226              | :im_used                         |
| **Redirection**     | 300              | :multiple_choices                |
|                     | 301              | :moved_permanently               |
|                     | 302              | :found                           |
|                     | 303              | :see_other                       |
|                     | 304              | :not_modified                    |
|                     | 305              | :use_proxy                       |
|                     | 306              | :reserved                        |
|                     | 307              | :temporary_redirect              |
|                     | 308              | :permanent_redirect              |
| **Client Error**    | 400              | :bad_request                     |
|                     | 401              | :unauthorized                    |
|                     | 402              | :payment_required                |
|                     | 403              | :forbidden                       |
|                     | 404              | :not_found                       |
|                     | 405              | :method_not_allowed              |
|                     | 406              | :not_acceptable                  |
|                     | 407              | :proxy_authentication_required   |
|                     | 408              | :request_timeout                 |
|                     | 409              | :conflict                        |
|                     | 410              | :gone                            |
|                     | 411              | :length_required                 |
|                     | 412              | :precondition_failed             |
|                     | 413              | :request_entity_too_large        |
|                     | 414              | :request_uri_too_long            |
|                     | 415              | :unsupported_media_type          |
|                     | 416              | :requested_range_not_satisfiable |
|                     | 417              | :expectation_failed              |
|                     | 422              | :unprocessable_entity            |
|                     | 423              | :locked                          |
|                     | 424              | :failed_dependency               |
|                     | 426              | :upgrade_required                |
|                     | 428              | :precondition_required           |
|                     | 429              | :too_many_requests               |
|                     | 431              | :request_header_fields_too_large |
| **Server Error**    | 500              | :internal_server_error           |
|                     | 501              | :not_implemented                 |
|                     | 502              | :bad_gateway                     |
|                     | 503              | :service_unavailable             |
|                     | 504              | :gateway_timeout                 |
|                     | 505              | :http_version_not_supported      |
|                     | 506              | :variant_also_negotiates         |
|                     | 507              | :insufficient_storage            |
|                     | 508              | :loop_detected                   |
|                     | 510              | :not_extended                    |
|                     | 511              | :network_authentication_required |

#### Finding Layouts

To find the current layout, Rails first looks for a file in `app/views/layouts` with the same base name as the controller. For example, rendering actions from the `PhotosController` class will use `app/views/layouts/photos.html.erb` (or `app/views/layouts/photos.builder`). If there is no such controller-specific layout, Rails will use `app/views/layouts/application.html.erb` or `app/views/layouts/application.builder`. If there is no `.erb` layout, Rails will use a `.builder` layout if one exists. Rails also provides several ways to more precisely assign specific layouts to individual controllers and actions.

##### Specifying Layouts for Controllers

You can override the default layout conventions in your controllers by using the `layout` declaration. For example:

```ruby
class ProductsController < ApplicationController
  layout "inventory"
  #...
end
```

With this declaration, all of the views rendered by the `ProductsController` will use `app/views/layouts/inventory.html.erb` as their layout.

To assign a specific layout for the entire application, use a `layout` declaration in your `ApplicationController` class:

```ruby
class ApplicationController < ActionController::Base
  layout "main"
  #...
end
```

With this declaration, all of the views in the entire application will use `app/views/layouts/main.html.erb` for their layout.

##### Choosing Layouts at Runtime

You can use a symbol to defer the choice of layout until a request is processed:

```ruby
class ProductsController < ApplicationController
  layout :products_layout

  def show
    @product = Product.find(params[:id])
  end

  private
    def products_layout
      @current_user.special? ? "special" : "products"
    end

end
```

Now, if the current user is a special user, they'll get a special layout when viewing a product.

You can even use an inline method, such as a Proc, to determine the layout. For example, if you pass a Proc object, the block you give the Proc will be given the `controller` instance, so the layout can be determined based on the current request:

```ruby
class ProductsController < ApplicationController
  layout Proc.new { |controller| controller.request.xhr? ? "popup" : "application" }
end
```

##### Conditional Layouts

Layouts specified at the controller level support the `:only` and `:except` options. These options take either a method name, or an array of method names, corresponding to method names within the controller:

```ruby
class ProductsController < ApplicationController
  layout "product", except: [:index, :rss]
end
```

With this declaration, the `product` layout would be used for everything but the `rss` and `index` methods.

##### Layout Inheritance

Layout declarations cascade downward in the hierarchy, and more specific layout declarations always override more general ones. For example:

* `application_controller.rb`

    ```ruby
    class ApplicationController < ActionController::Base
      layout "main"
    end
    ```

* `articles_controller.rb`

    ```ruby
    class ArticlesController < ApplicationController
    end
    ```

* `special_articles_controller.rb`

    ```ruby
    class SpecialArticlesController < ArticlesController
      layout "special"
    end
    ```

* `old_articles_controller.rb`

    ```ruby
    class OldArticlesController < SpecialArticlesController
      layout false

      def show
        @article = Article.find(params[:id])
      end

      def index
        @old_articles = Article.older
        render layout: "old"
      end
      # ...
    end
    ```

In this application:

* In general, views will be rendered in the `main` layout
* `ArticlesController#index` will use the `main` layout
* `SpecialArticlesController#index` will use the `special` layout
* `OldArticlesController#show` will use no layout at all
* `OldArticlesController#index` will use the `old` layout

#### Avoiding Double Render Errors

Sooner or later, most Rails developers will see the error message "Can only render or redirect once per action". While this is annoying, it's relatively easy to fix. Usually it happens because of a fundamental misunderstanding of the way that `render` works.

For example, here's some code that will trigger this error:

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
  render action: "regular_show"
end
```

If `@book.special?` evaluates to `true`, Rails will start the rendering process to dump the `@book` variable into the `special_show` view. But this will _not_ stop the rest of the code in the `show` action from running, and when Rails hits the end of the action, it will start to render the `regular_show` view - and throw an error. The solution is simple: make sure that you have only one call to `render` or `redirect` in a single code path. One thing that can help is `and return`. Here's a patched version of the method:

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show" and return
  end
  render action: "regular_show"
end
```

Make sure to use `and return` instead of `&& return` because `&& return` will not work due to the operator precedence in the Ruby Language.

Note that the implicit render done by ActionController detects if `render` has been called, so the following will work without errors:

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
end
```

This will render a book with `special?` set with the `special_show` template, while other books will render with the default `show` template.

### Using `redirect_to`

Another way to handle returning responses to an HTTP request is with `redirect_to`. As you've seen, `render` tells Rails which view (or other asset) to use in constructing a response. The `redirect_to` method does something completely different: it tells the browser to send a new request for a different URL. For example, you could redirect from wherever you are in your code to the index of photos in your application with this call:

```ruby
redirect_to photos_url
```

You can use `redirect_to` with any arguments that you could use with `link_to` or `url_for`. There's also a special redirect that sends the user back to the page they just came from:

```ruby
redirect_to :back
```

#### Getting a Different Redirect Status Code

Rails uses HTTP status code 302, a temporary redirect, when you call `redirect_to`. If you'd like to use a different status code, perhaps 301, a permanent redirect, you can use the `:status` option:

```ruby
redirect_to photos_path, status: 301
```

Just like the `:status` option for `render`, `:status` for `redirect_to` accepts both numeric and symbolic header designations.

#### The Difference Between `render` and `redirect_to`

Sometimes inexperienced developers think of `redirect_to` as a sort of `goto` command, moving execution from one place to another in your Rails code. This is _not_ correct. Your code stops running and waits for a new request for the browser. It just happens that you've told the browser what request it should make next, by sending back an HTTP 302 status code.

Consider these actions to see the difference:

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    render action: "index"
  end
end
```

With the code in this form, there will likely be a problem if the `@book` variable is `nil`. Remember, a `render :action` doesn't run any code in the target action, so nothing will set up the `@books` variable that the `index` view will probably require. One way to fix this is to redirect instead of rendering:

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    redirect_to action: :index
  end
end
```

With this code, the browser will make a fresh request for the index page, the code in the `index` method will run, and all will be well.

The only downside to this code is that it requires a round trip to the browser: the browser requested the show action with `/books/1` and the controller finds that there are no books, so the controller sends out a 302 redirect response to the browser telling it to go to `/books/`, the browser complies and sends a new request back to the controller asking now for the `index` action, the controller then gets all the books in the database and renders the index template, sending it back down to the browser which then shows it on your screen.

While in a small application, this added latency might not be a problem, it is something to think about if response time is a concern. We can demonstrate one way to handle this with a contrived example:

```ruby
def index
  @books = Book.all
end

def show
  @book = Book.find_by(id: params[:id])
  if @book.nil?
    @books = Book.all
    flash.now[:alert] = "Your book was not found"
    render "index"
  end
end
```

This would detect that there are no books with the specified ID, populate the `@books` instance variable with all the books in the model, and then directly render the `index.html.erb` template, returning it to the browser with a flash alert message to tell the user what happened.

### Using `head` To Build Header-Only Responses

The `head` method can be used to send responses with only headers to the browser. It provides a more obvious alternative to calling `render :nothing`. The `head` method accepts a number or symbol (see [reference table](#the-status-option)) representing a HTTP status code. The options argument is interpreted as a hash of header names and values. For example, you can return only an error header:

```ruby
head :bad_request
```

This would produce the following header:

```
HTTP/1.1 400 Bad Request
Connection: close
Date: Sun, 24 Jan 2010 12:15:53 GMT
Transfer-Encoding: chunked
Content-Type: text/html; charset=utf-8
X-Runtime: 0.013483
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache
```

Or you can use other HTTP headers to convey other information:

```ruby
head :created, location: photo_path(@photo)
```

Which would produce:

```
HTTP/1.1 201 Created
Connection: close
Date: Sun, 24 Jan 2010 12:16:44 GMT
Transfer-Encoding: chunked
Location: /photos/1
Content-Type: text/html; charset=utf-8
X-Runtime: 0.083496
Set-Cookie: _blog_session=...snip...; path=/; HttpOnly
Cache-Control: no-cache
```

Structuring Layouts
-------------------

When Rails renders a view as a response, it does so by combining the view with the current layout, using the rules for finding the current layout that were covered earlier in this guide. Within a layout, you have access to three tools for combining different bits of output to form the overall response:

* Asset tags
* `yield` and `content_for`
* Partials

### Asset Tag Helpers

Asset tag helpers provide methods for generating HTML that link views to feeds, JavaScript, stylesheets, images, videos and audios. There are six asset tag helpers available in Rails:

* `auto_discovery_link_tag`
* `javascript_include_tag`
* `stylesheet_link_tag`
* `image_tag`
* `video_tag`
* `audio_tag`

You can use these tags in layouts or other views, although the `auto_discovery_link_tag`, `javascript_include_tag`, and `stylesheet_link_tag`, are most commonly used in the `<head>` section of a layout.

WARNING: The asset tag helpers do _not_ verify the existence of the assets at the specified locations; they simply assume that you know what you're doing and generate the link.

#### Linking to Feeds with the `auto_discovery_link_tag`

The `auto_discovery_link_tag` helper builds HTML that most browsers and feed readers can use to detect the presence of RSS or Atom feeds. It takes the type of the link (`:rss` or `:atom`), a hash of options that are passed through to url_for, and a hash of options for the tag:

```erb
<%= auto_discovery_link_tag(:rss, {action: "feed"},
  {title: "RSS Feed"}) %>
```

There are three tag options available for the `auto_discovery_link_tag`:

* `:rel` specifies the `rel` value in the link. The default value is "alternate".
* `:type` specifies an explicit MIME type. Rails will generate an appropriate MIME type automatically.
* `:title` specifies the title of the link. The default value is the uppercase `:type` value, for example, "ATOM" or "RSS".

#### Linking to JavaScript Files with the `javascript_include_tag`

The `javascript_include_tag` helper returns an HTML `script` tag for each source provided.

If you are using Rails with the [Asset Pipeline](asset_pipeline.html) enabled, this helper will generate a link to `/assets/javascripts/` rather than `public/javascripts` which was used in earlier versions of Rails. This link is then served by the asset pipeline.

A JavaScript file within a Rails application or Rails engine goes in one of three locations: `app/assets`, `lib/assets` or `vendor/assets`. These locations are explained in detail in the [Asset Organization section in the Asset Pipeline Guide](asset_pipeline.html#asset-organization)

You can specify a full path relative to the document root, or a URL, if you prefer. For example, to link to a JavaScript file that is inside a directory called `javascripts` inside of one of `app/assets`, `lib/assets` or `vendor/assets`, you would do this:

```erb
<%= javascript_include_tag "main" %>
```

Rails will then output a `script` tag such as this:

```html
<script src='/assets/main.js'></script>
```

The request to this asset is then served by the Sprockets gem.

To include multiple files such as `app/assets/javascripts/main.js` and `app/assets/javascripts/columns.js` at the same time:

```erb
<%= javascript_include_tag "main", "columns" %>
```

To include `app/assets/javascripts/main.js` and `app/assets/javascripts/photos/columns.js`:

```erb
<%= javascript_include_tag "main", "/photos/columns" %>
```

To include `http://example.com/main.js`:

```erb
<%= javascript_include_tag "http://example.com/main.js" %>
```

#### Linking to CSS Files with the `stylesheet_link_tag`

The `stylesheet_link_tag` helper returns an HTML `<link>` tag for each source provided.

If you are using Rails with the "Asset Pipeline" enabled, this helper will generate a link to `/assets/stylesheets/`. This link is then processed by the Sprockets gem. A stylesheet file can be stored in one of three locations: `app/assets`, `lib/assets` or `vendor/assets`.

You can specify a full path relative to the document root, or a URL. For example, to link to a stylesheet file that is inside a directory called `stylesheets` inside of one of `app/assets`, `lib/assets` or `vendor/assets`, you would do this:

```erb
<%= stylesheet_link_tag "main" %>
```

To include `app/assets/stylesheets/main.css` and `app/assets/stylesheets/columns.css`:

```erb
<%= stylesheet_link_tag "main", "columns" %>
```

To include `app/assets/stylesheets/main.css` and `app/assets/stylesheets/photos/columns.css`:

```erb
<%= stylesheet_link_tag "main", "photos/columns" %>
```

To include `http://example.com/main.css`:

```erb
<%= stylesheet_link_tag "http://example.com/main.css" %>
```

By default, the `stylesheet_link_tag` creates links with `media="screen" rel="stylesheet"`. You can override any of these defaults by specifying an appropriate option (`:media`, `:rel`):

```erb
<%= stylesheet_link_tag "main_print", media: "print" %>
```

#### Linking to Images with the `image_tag`

The `image_tag` helper builds an HTML `<img />` tag to the specified file. By default, files are loaded from `public/images`.

WARNING: Note that you must specify the extension of the image.

```erb
<%= image_tag "header.png" %>
```

You can supply a path to the image if you like:

```erb
<%= image_tag "icons/delete.gif" %>
```

You can supply a hash of additional HTML options:

```erb
<%= image_tag "icons/delete.gif", {height: 45} %>
```

You can supply alternate text for the image which will be used if the user has images turned off in their browser. If you do not specify an alt text explicitly, it defaults to the file name of the file, capitalized and with no extension. For example, these two image tags would return the same code:

```erb
<%= image_tag "home.gif" %>
<%= image_tag "home.gif", alt: "Home" %>
```

You can also specify a special size tag, in the format "{width}x{height}":

```erb
<%= image_tag "home.gif", size: "50x20" %>
```

In addition to the above special tags, you can supply a final hash of standard HTML options, such as `:class`, `:id` or `:name`:

```erb
<%= image_tag "home.gif", alt: "Go Home",
                          id: "HomeImage",
                          class: "nav_bar" %>
```

#### Linking to Videos with the `video_tag`

The `video_tag` helper builds an HTML 5 `<video>` tag to the specified file. By default, files are loaded from `public/videos`.

```erb
<%= video_tag "movie.ogg" %>
```

Produces

```erb
<video src="/videos/movie.ogg" />
```

Like an `image_tag` you can supply a path, either absolute, or relative to the `public/videos` directory. Additionally you can specify the `size: "#{width}x#{height}"` option just like an `image_tag`. Video tags can also have any of the HTML options specified at the end (`id`, `class` et al).

The video tag also supports all of the `<video>` HTML options through the HTML options hash, including:

* `poster: "image_name.png"`, provides an image to put in place of the video before it starts playing.
* `autoplay: true`, starts playing the video on page load.
* `loop: true`, loops the video once it gets to the end.
* `controls: true`, provides browser supplied controls for the user to interact with the video.
* `autobuffer: true`, the video will pre load the file for the user on page load.

You can also specify multiple videos to play by passing an array of videos to the `video_tag`:

```erb
<%= video_tag ["trailer.ogg", "movie.ogg"] %>
```

This will produce:

```erb
<video><source src="trailer.ogg" /><source src="movie.ogg" /></video>
```

#### Linking to Audio Files with the `audio_tag`

The `audio_tag` helper builds an HTML 5 `<audio>` tag to the specified file. By default, files are loaded from `public/audios`.

```erb
<%= audio_tag "music.mp3" %>
```

You can supply a path to the audio file if you like:

```erb
<%= audio_tag "music/first_song.mp3" %>
```

You can also supply a hash of additional options, such as `:id`, `:class` etc.

Like the `video_tag`, the `audio_tag` has special options:

* `autoplay: true`, starts playing the audio on page load
* `controls: true`, provides browser supplied controls for the user to interact with the audio.
* `autobuffer: true`, the audio will pre load the file for the user on page load.

### Understanding `yield`

Within the context of a layout, `yield` identifies a section where content from the view should be inserted. The simplest way to use this is to have a single `yield`, into which the entire contents of the view currently being rendered is inserted:

```html+erb
<html>
  <head>
  </head>
  <body>
  <%= yield %>
  </body>
</html>
```

You can also create a layout with multiple yielding regions:

```html+erb
<html>
  <head>
  <%= yield :head %>
  </head>
  <body>
  <%= yield %>
  </body>
</html>
```

The main body of the view will always render into the unnamed `yield`. To render content into a named `yield`, you use the `content_for` method.

### Using the `content_for` Method

The `content_for` method allows you to insert content into a named `yield` block in your layout. For example, this view would work with the layout that you just saw:

```html+erb
<% content_for :head do %>
  <title>A simple page</title>
<% end %>

<p>Hello, Rails!</p>
```

The result of rendering this page into the supplied layout would be this HTML:

```html+erb
<html>
  <head>
  <title>A simple page</title>
  </head>
  <body>
  <p>Hello, Rails!</p>
  </body>
</html>
```

The `content_for` method is very helpful when your layout contains distinct regions such as sidebars and footers that should get their own blocks of content inserted. It's also useful for inserting tags that load page-specific JavaScript or css files into the header of an otherwise generic layout.

### Using Partials

Partial templates - usually just called "partials" - are another device for breaking the rendering process into more manageable chunks. With a partial, you can move the code for rendering a particular piece of a response to its own file.

#### Naming Partials

To render a partial as part of a view, you use the `render` method within the view:

```ruby
<%= render "menu" %>
```

This will render a file named `_menu.html.erb` at that point within the view being rendered. Note the leading underscore character: partials are named with a leading underscore to distinguish them from regular views, even though they are referred to without the underscore. This holds true even when you're pulling in a partial from another folder:

```ruby
<%= render "shared/menu" %>
```

That code will pull in the partial from `app/views/shared/_menu.html.erb`.

#### Using Partials to Simplify Views

One way to use partials is to treat them as the equivalent of subroutines: as a way to move details out of a view so that you can grasp what's going on more easily. For example, you might have a view that looked like this:

```erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
...

<%= render "shared/footer" %>
```

Here, the `_ad_banner.html.erb` and `_footer.html.erb` partials could contain content that is shared among many pages in your application. You don't need to see the details of these sections when you're concentrating on a particular page.

TIP: For content that is shared among all pages in your application, you can use partials directly from layouts.

#### Partial Layouts

A partial can use its own layout file, just as a view can use a layout. For example, you might call a partial like this:

```erb
<%= render partial: "link_area", layout: "graybar" %>
```

This would look for a partial named `_link_area.html.erb` and render it using the layout `_graybar.html.erb`. Note that layouts for partials follow the same leading-underscore naming as regular partials, and are placed in the same folder with the partial that they belong to (not in the master `layouts` folder).

Also note that explicitly specifying `:partial` is required when passing additional options such as `:layout`.

#### Passing Local Variables

You can also pass local variables into partials, making them even more powerful and flexible. For example, you can use this technique to reduce duplication between new and edit pages, while still keeping a bit of distinct content:

* `new.html.erb`

    ```html+erb
    <h1>New zone</h1>
    <%= render partial: "form", locals: {zone: @zone} %>
    ```

* `edit.html.erb`

    ```html+erb
    <h1>Editing zone</h1>
    <%= render partial: "form", locals: {zone: @zone} %>
    ```

* `_form.html.erb`

    ```html+erb
    <%= form_for(zone) do |f| %>
      <p>
        <b>Zone name</b><br>
        <%= f.text_field :name %>
      </p>
      <p>
        <%= f.submit %>
      </p>
    <% end %>
    ```

Although the same partial will be rendered into both views, Action View's submit helper will return "Create Zone" for the new action and "Update Zone" for the edit action.

Every partial also has a local variable with the same name as the partial (minus the underscore). You can pass an object in to this local variable via the `:object` option:

```erb
<%= render partial: "customer", object: @new_customer %>
```

Within the `customer` partial, the `customer` variable will refer to `@new_customer` from the parent view.

If you have an instance of a model to render into a partial, you can use a shorthand syntax:

```erb
<%= render @customer %>
```

Assuming that the `@customer` instance variable contains an instance of the `Customer` model, this will use `_customer.html.erb` to render it and will pass the local variable `customer` into the partial which will refer to the `@customer` instance variable in the parent view.

#### Rendering Collections

Partials are very useful in rendering collections. When you pass a collection to a partial via the `:collection` option, the partial will be inserted once for each member in the collection:

* `index.html.erb`

    ```html+erb
    <h1>Products</h1>
    <%= render partial: "product", collection: @products %>
    ```

* `_product.html.erb`

    ```html+erb
    <p>Product Name: <%= product.name %></p>
    ```

When a partial is called with a pluralized collection, then the individual instances of the partial have access to the member of the collection being rendered via a variable named after the partial. In this case, the partial is `_product`, and within the `_product` partial, you can refer to `product` to get the instance that is being rendered.

There is also a shorthand for this. Assuming `@products` is a collection of `product` instances, you can simply write this in the `index.html.erb` to produce the same result:

```html+erb
<h1>Products</h1>
<%= render @products %>
```

Rails determines the name of the partial to use by looking at the model name in the collection. In fact, you can even create a heterogeneous collection and render it this way, and Rails will choose the proper partial for each member of the collection:

* `index.html.erb`

    ```html+erb
    <h1>Contacts</h1>
    <%= render [customer1, employee1, customer2, employee2] %>
    ```

* `customers/_customer.html.erb`

    ```html+erb
    <p>Customer: <%= customer.name %></p>
    ```

* `employees/_employee.html.erb`

    ```html+erb
    <p>Employee: <%= employee.name %></p>
    ```

In this case, Rails will use the customer or employee partials as appropriate for each member of the collection.

In the event that the collection is empty, `render` will return nil, so it should be fairly simple to provide alternative content.

```html+erb
<h1>Products</h1>
<%= render(@products) || "There are no products available." %>
```

#### Local Variables

To use a custom local variable name within the partial, specify the `:as` option in the call to the partial:

```erb
<%= render partial: "product", collection: @products, as: :item %>
```

With this change, you can access an instance of the `@products` collection as the `item` local variable within the partial.

You can also pass in arbitrary local variables to any partial you are rendering with the `locals: {}` option:

```erb
<%= render partial: "product", collection: @products,
           as: :item, locals: {title: "Products Page"} %>
```

In this case, the partial will have access to a local variable `title` with the value "Products Page".

TIP: Rails also makes a counter variable available within a partial called by the collection, named after the member of the collection followed by `_counter`. For example, if you're rendering `@products`, within the partial you can refer to `product_counter` to tell you how many times the partial has been rendered. This does not work in conjunction with the `as: :value` option.

You can also specify a second partial to be rendered between instances of the main partial by using the `:spacer_template` option:

#### Spacer Templates

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

Rails will render the `_product_ruler` partial (with no data passed in to it) between each pair of `_product` partials.

#### Collection Partial Layouts

When rendering collections it is also possible to use the `:layout` option:

```erb
<%= render partial: "product", collection: @products, layout: "special_layout" %>
```

The layout will be rendered together with the partial for each item in the collection. The current object and object_counter variables will be available in the layout as well, the same way they do within the partial.

### Using Nested Layouts

You may find that your application requires a layout that differs slightly from your regular application layout to support one particular controller. Rather than repeating the main layout and editing it, you can accomplish this by using nested layouts (sometimes called sub-templates). Here's an example:

Suppose you have the following `ApplicationController` layout:

* `app/views/layouts/application.html.erb`

    ```html+erb
    <html>
    <head>
      <title><%= @page_title or "Page Title" %></title>
      <%= stylesheet_link_tag "layout" %>
      <style><%= yield :stylesheets %></style>
    </head>
    <body>
      <div id="top_menu">Top menu items here</div>
      <div id="menu">Menu items here</div>
      <div id="content"><%= content_for?(:content) ? yield(:content) : yield %></div>
    </body>
    </html>
    ```

On pages generated by `NewsController`, you want to hide the top menu and add a right menu:

* `app/views/layouts/news.html.erb`

    ```html+erb
    <% content_for :stylesheets do %>
      #top_menu {display: none}
      #right_menu {float: right; background-color: yellow; color: black}
    <% end %>
    <% content_for :content do %>
      <div id="right_menu">Right menu items here</div>
      <%= content_for?(:news_content) ? yield(:news_content) : yield %>
    <% end %>
    <%= render template: "layouts/application" %>
    ```

That's it. The News views will use the new layout, hiding the top menu and adding a new right menu inside the "content" div.

There are several ways of getting similar results with different sub-templating schemes using this technique. Note that there is no limit in nesting levels. One can use the `ActionView::render` method via `render template: 'layouts/news'` to base a new layout on the News layout. If you are sure you will not subtemplate the `News` layout, you can replace the `content_for?(:news_content) ? yield(:news_content) : yield` with simply `yield`.
