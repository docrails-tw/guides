**DO NOT READ THIS FILE IN GITHUB, GUIDES ARE PUBLISHED IN http://rails.ruby.tw.**

Rails 算繪與版型
===============

本篇介紹 Action Controller 與 Action View 關於版型的基本功能

讀完本篇，您將了解：

* 如何使用 Rails 內建的算繪方法。
* 如何建立有多個內容區域的版型（Layout）。
* 如何使用局部頁面（Partial）來避免重複。
* 如何使用嵌套版型（子模版）。

--------------------------------------------------------------------------------

綜覽：MVC 協同合作
-------------------------------------

本篇著重介紹 MVC 架構中，Controller 與 View 之間的互動關係。Controller 負責策劃處理請求（Request）的整個過程，但通常會把複雜的事情交給 Model 處理；要把響應（Response）回給使用者時，Controller 把事情交給 View 處理。Controller 如何將工作派給別人便是本篇要介紹的主題。

更完整的說，這個過程包含了，響應要傳送什麼內容，要呼叫那些方法來建立響應。如果響應是完整的 View，Rails 會做些額外工作，譬如會把 View 放到版型裡，或是把某個局部頁面加進來。本篇之後會完整介紹這整個過程。

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

NOTE: 檔案預設使用當下的模版進行算繪。

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

可以使用 `render` 的 `:body` 選項，把未經處理的內容發給瀏覽器，而無需設定 Content-Type：

```ruby
render body: "raw"
```

TIP: 這個選項應該在不在意響應的 Content-Type 時使用。使用 `:plain` 或 `:html` 在多數情況下更合理。

NOTE: 使用 `:body` 選項，響應的內容類型會是 `text/html`，這是 Action Dispatch 響應預設的 Content-Type。

#### `render` 接受的選項

`render` 方法一般接受下列四個選項：

* `:content_type`
* `:layout`
* `:location`
* `:status`

##### `:content_type` 選項

Rails 算繪操作預設的 MIME Content-Type 為 `text/html`（若用了 `:json` 選項，則為 `application/json`；`:xml` 選項為 `application/xml`）。有時候會想要修改 Content-Type，可以使用 `:content_type` 選項來設定：

```ruby
render file: filename, content_type: "application/rss"
```

##### `:layout` 選項

`render` 方法多數的選項，都會把內容顯示到目前的版型裡。後面會更詳細介紹版型、版型如何使用。

用 `:layout` 選項指定動作要使用的版型：

```ruby
render layout: "special_layout"
```

也可以停用版型：

```ruby
render layout: false
```

##### `:location` 選項

可以使用 `:location` 選項設定 HTTP 標頭的 `Location`：

```ruby
render xml: photo, location: photo_url(photo)
```

##### `:status` 選項

Rails 會自動給響應產生正確的 HTTP 狀態碼（多數情況是 `200 OK`），可以用 `:status` 選項來修改：

```ruby
render status: 500
render status: :forbidden
```

可以用數字或是符號指定 HTTP 狀態碼：

| 響應類別              | HTTP 狀態碼      | 符號                                |
| ------------------- | ---------------- | ---------------------------------- |
| **資訊**             | 100              | `:continue`                        |
|                     | 101              | `:switching_protocols`             |
|                     | 102              | `:processing`                      |
| **成功**             | 200              | `:ok`                              |
|                     | 201              | `:created`                         |
|                     | 202              | `:accepted`                        |
|                     | 203              | `:non_authoritative_information`   |
|                     | 204              | `:no_content`                      |
|                     | 205              | `:reset_content`                   |
|                     | 206              | `:partial_content`                 |
|                     | 207              | `:multi_status`                    |
|                     | 208              | `:already_reported`                |
|                     | 226              | `:im_used`                         |
| **重新導向**         | 300              | `:multiple_choices`                |
|                     | 301              | `:moved_permanently`               |
|                     | 302              | `:found`                           |
|                     | 303              | `:see_other`                       |
|                     | 304              | `:not_modified`                    |
|                     | 305              | `:use_proxy`                       |
|                     | 306              | `:reserved`                        |
|                     | 307              | `:temporary_redirect`              |
|                     | 308              | `:permanent_redirect`              |
| **用戶端錯誤**        | 400              | `:bad_request`                     |
|                     | 401              | `:unauthorized`                    |
|                     | 402              | `:payment_required`                |
|                     | 403              | `:forbidden`                       |
|                     | 404              | `:not_found`                       |
|                     | 405              | `:method_not_allowed`              |
|                     | 406              | `:not_acceptable`                  |
|                     | 407              | `:proxy_authentication_required`   |
|                     | 408              | `:request_timeout`                 |
|                     | 409              | `:conflict`                        |
|                     | 410              | `:gone`                            |
|                     | 411              | `:length_required`                 |
|                     | 412              | `:precondition_failed`             |
|                     | 413              | `:request_entity_too_large`        |
|                     | 414              | `:request_uri_too_long`            |
|                     | 415              | `:unsupported_media_type`          |
|                     | 416              | `:requested_range_not_satisfiable` |
|                     | 417              | `:expectation_failed`              |
|                     | 422              | `:unprocessable_entity`            |
|                     | 423              | `:locked`                          |
|                     | 424              | `:failed_dependency`               |
|                     | 426              | `:upgrade_required`                |
|                     | 428              | `:precondition_required`           |
|                     | 429              | `:too_many_requests`               |
|                     | 431              | `:request_header_fields_too_large` |
| **伺服器錯誤**        | 500              | `:internal_server_error`           |
|                     | 501              | `:not_implemented`                 |
|                     | 502              | `:bad_gateway`                     |
|                     | 503              | `:service_unavailable`             |
|                     | 504              | `:gateway_timeout`                 |
|                     | 505              | `:http_version_not_supported`      |
|                     | 506              | `:variant_also_negotiates`         |
|                     | 507              | `:insufficient_storage`            |
|                     | 508              | `:loop_detected`                   |
|                     | 510              | `:not_extended`                    |
|                     | 511              | `:network_authentication_required` |

#### 尋找版型

Rails 在 `app/views/layouts` 下尋找與 Controller 同名的檔案作為目前的版型。舉例來說，`PhotosController` 會使用 `app/views/layouts/photos.html.erb`（或是 `app/views/layouts/photos.builder`）。若找不到與 Controller 同名的版型，會使用 `app/views/layouts/application.html.erb` 或是 `app/views/layouts/application.builder` 作為版型。若 `.erb` 版型不存在，Rails 會使用 `.builder` 版型（如果有的話）。Rails 也提供數種方式用來給 Controller 與動作設定版型。

##### 給 Controller 指定版型

在 Controller 使用 `layout` 宣告來覆寫預設的版型：

```ruby
class ProductsController < ApplicationController
  layout "inventory"
  #...
end
```

加上這行宣告以後，`ProductsController` 會使用 `app/views/layouts/inventory.html.erb` 作為版型。

要給整個應用程式指定版型，在 `ApplicationController` 使用 `layout` 來指定：

```ruby
class ApplicationController < ActionController::Base
  layout "main"
  #...
end
```

加上這行宣告以後，應用程式全都使用 `app/views/layouts/main.html.erb` 作為版型。

##### 動態指定版型

可以使用符號來推遲版型的選擇，版型會在處理請求時選擇：

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

若目前的使用者是一個特殊的使用者，會使用特殊的版型。

甚至可以使用一個“內聯方法”，比如 `Proc` 來指定版型。舉例來說，若傳入 `Proc` 物件，這個 `Proc` 會傳給 Controller 的實體，版型則可以在當下的請求裡指定：

```ruby
class ProductsController < ApplicationController
  layout Proc.new { |controller| controller.request.xhr? ? "popup" : "application" }
end
```

##### 條件式版型

在 Controller 裡指定版型還接受 `:only` 與 `:except` 選項。這些選項接受方法名稱、方法名稱組成的陣列。這些名稱對應到 Controller 裡的方法。

```ruby
class ProductsController < ApplicationController
  layout "product", except: [:index, :rss]
end
```

加了上面這條宣告後，`index` 與 `rss` 會使用 `product` 版型。

##### 版型繼承

版型宣告可以“串接”，會採用最具體的版型指定。舉例來說：

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

在這個應用程式裡：

* View 通常會在 `main` 版型裡算繪。
* `ArticlesController#index` 會使用 `main` 版型。
* `SpecialArticlesController#index` 會使用 `special` 版型。
* `OldArticlesController#show` 不會使用任何版型。
* `OldArticlesController#index` 會使用 `old` 版型。

#### 避免雙重算繪錯誤

多數的 Rails 開發者遲早會看過這個錯誤訊息："Can only render or redirect once per action"。這個提示雖然很討厭，但也很容易修正。通常的發生原因是不了解 `render` 的工作原理。

舉例來說，以下是會觸發此錯誤的程式：

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
  render action: "regular_show"
end
```

若 `@book.special?` 求值為 `true`，Rails 會把 `@book` 變數放到 `special_show` View 裡算繪。但之後的程式碼還是會執行，會繼續算繪 `regular_show`，進而造成錯誤。解決方法很簡單，確保程式只會執行一次 `render` 或是 `redirect`。或是加上 `and return`，以下是上面程式的修正版本：

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show" and return
  end
  render action: "regular_show"
end
```

記得要使用 `and return` 而不是 `&& return`，因為 Ruby 運算子優先權的關係，`&& return` 不會有任何作用。

注意 `ActionController` 默認會執行 `render`，但會先檢查 `render` 是否有呼叫過，所以下面這段程式不會有錯誤：

```ruby
def show
  @book = Book.find(params[:id])
  if @book.special?
    render action: "special_show"
  end
end
```

特殊的書會算繪 `special_view` 模版，而一般的書則會算繪預設的 `show` 模版。

### 使用 `redirect_to`

另一種回傳響應給 HTTP 請求的方式是使用 `redirect_to`。`render` 告訴 Rails 要用那個 View （或是其他 Asset）來打造響應。而 `redirect_to` 方法則完全不同，告訴瀏覽器對不同的 URL 發一個新請求。舉例來說，可以在程式碼任何一個地方做轉址，比如轉到 `photos` 的 `index`：

```ruby
redirect_to photos_url
```

可以對 `redirect_to` 使用任何 `link_to` 或 `url_for` 也接受的參數。有一個特殊的轉址，會回到使用者到這頁的“前一頁”：

```ruby
redirect_to :back
```

#### 獲得不同的狀態碼

當呼叫 `redirect_to` 時，Rails 使用 HTTP 狀態碼 302，即暫時轉址（temporary redirect）。若想使用不同的狀態碼，譬如 301，永久轉址，可以使用 `:status` 選項：

```ruby
redirect_to photos_path, status: 301
```

和 `render` 方法的 `:status` 選項一樣，`redirect_to` 的 `:status` 接受數字與符號來指定狀態碼。

#### `render` 和 `redirect_to` 的差異

有時候經驗不足的開發者會認為 `redirect_to` 是某種 `goto` 命令，在 Rails 程式裡從一處跳至另一處。**這是不正確的**。`redirect_to` 方法會讓程式停止執行，等待瀏覽器發起新請求。你需要用 HTTP 302 狀態碼，告訴瀏覽器下個請求是什麼才是。

考量下面這幾個動作來看出差異：

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

在上面的程式裡，若 `@book` 的值為 `nil`，則會有問題。`render :action` 不會執行 `:action` 裡的任何程式，因此不會執行 `index` 裡的 `@books = Book.all`。解決辦法是使用 `redirect_to`：

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

程式改成這樣後，瀏覽器會對 `index` 頁面發一個新的請求，這麼一來便會執行 `index` 方法裡的程式，一切正常。

這段程式的唯一缺點是，無法直接跳到 `index`，需要經過瀏覽器：瀏覽器起初對 `show` 動作發起 `/books/1`，Controller 發現找不到該本書（`@book.nil?`），Controller 傳送 `302 redirect response` 給瀏覽器，告訴瀏覽器到 `/books/`，瀏覽器按照要求，對 Controller 對 `index` 動作發一個新的請求，Controller 從資料庫將所有的書拿來，算繪 `index` 模版，發回給瀏覽器，最終顯示在螢幕上。

小的應用程式裡，這加了一些延遲時間（latency），可能沒什麼問題。但如果響應時間很重要，就需要考慮這個問題。以下用一個假設的例子來示範如何處理這個問題：

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

找不到該本書時，會將所有的書取出來，放到 `@books`，在直接算繪 `index.html.erb`，把算繪結果加上一條提示訊息回給瀏覽器，告訴使用者究竟發生了什麼事。

### 使用 `head` 來建立只含標頭的響應

`head` 方法可以用來建立只有標頭的響應，來傳給瀏覽器。使用 `head` 與 `render :nothing` 比起來，意圖更明確清晰。`head` 方法接受數字或符號（參考 [〈HTTP 狀態選項〉](#:status-選項)一節的表格）。選項參數是一個 Hash，指定標頭的名稱與數值。舉個例子，可以只回傳錯誤標頭：

```ruby
head :bad_request
```

會產生出以下的標頭：

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

或可以使用別的 HTTP 標頭來傳遞其他資訊：

```ruby
head :created, location: photo_path(@photo)
```

會產生：

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

組織版型
-------

當 Rails 算繪 View 作為響應時，首先使用前文所述的慣例找到版型，將 View 與版型結合起來。在版型裡，可以使用三種工具，將每個部分組合在一起，來產生完整的響應：

* Asset tags
* `yield` 與 `content_for`
* 局部頁面

### Asset Tag 輔助方法

Asset Tag 輔助方法提供用來產生連結，可以產生連結到 feeds、JavaScript、樣式表、圖片、影片和音訊的 HTML 程式碼。Rails 提供以下六個 Asset Tag 輔助方法：

* `auto_discovery_link_tag`
* `javascript_include_tag`
* `stylesheet_link_tag`
* `image_tag`
* `video_tag`
* `audio_tag`

這些方法可以在版型、或其他的 View 裡使用，雖然 `auto_discovery_link_tag`、`javascript_include_tag` 和 `stylesheet_link_tag` 這三個方法一般是在 HTML 裡的 `<head>` 裡使用。

WARNING: Asset Tag 輔助方法不會檢查 Assets 是否存在，這些方法是假設你知道自己在幹什麼，純粹幫你產生連結出來。

#### 用 `auto_discovery_link_tag` 來連結到 Feeds

`auto_discovery_link_tag` 輔助方法所產生的 HTML，多數瀏覽器與 Feed 閱讀器都會識別成 RSS 或是 Atom Feeds。這個方法接受的參數有：連結的類型（`:rss` 或 `:atom`），給 `url_for` 的選項（Hash）以及給 `auto_discovery_link_tag` 本身的選項（Hash）：

```erb
<%= auto_discovery_link_tag(:rss, {action: "feed"},
  {title: "RSS Feed"}) %>
```

`auto_discovery_link_tag` 可用的選項有三個：

* `:rel` 指定連結的 `rel`。預設值是 `"alternate"`。
* `:type` 指定 MIME 類型。Rails 會自動產生適當的 MIME 類型。
* `:title` 指定連結的 `title`。預設值是 `:type` 的值轉大寫，譬如 `"ATOM"` 或 `"RSS"`。

#### 使用 `javascript_include_tag` 來引入 JavaScript

`javascript_include_tag` 輔助方法根據提供的來源，回傳 HTML 的 `<script>` 標籤。

若有啟用 Rails 的 [Asset Pipeline](asset_pipeline.html)，連結會由 Asset Pipeline 來供應。這個方法產生的連結會連到 `/assets/javascripts`，而不是 `public/javascripts`（舊版 Rails，JavaScript 都放在這個目錄下）。

Rails 應用程式或 Rails Engine 裡的 JavaScript，通常放在三個地方：`app/assets`、`lib/assets` 或 `vendor/assets`。這些擺放的位置在《Asset Pipeline》一文的[〈組織 Asset〉](asset_pipeline.html#asset-organization) 一節裡有更深入的介紹。

可以指定相對於根目錄的完整路徑，或是 URL 也可以。舉例來說，要連結到放在 `javascripts` 目錄（`app/assets`、`lib/assets` 或是 `vendor/assets`）下的 JavaScript 檔案，可以這麼寫：

```erb
<%= javascript_include_tag "main" %>
```

Rails 則會輸出像是這樣的 `script` 標籤：

```html
<script src='/assets/main.js'></script>
```

Asset 的請求則是交給 Sprockets Gem 來處理。

要引入多個 JavaScript 檔案，像是一次引入 `app/assets/javascripts/main.js` 和 `app/assets/javascripts/columns.js`：

```erb
<%= javascript_include_tag "main", "columns" %>
```

要引入 `app/assets/javascripts/main.js` 和 `app/assets/javascripts/photos/columns.js`：

```erb
<%= javascript_include_tag "main", "/photos/columns" %>
```

要引入 `http://example.com/main.js`：

```erb
<%= javascript_include_tag "http://example.com/main.js" %>
```

#### 使用 `stylesheet_link_tag` 來引入樣式表檔案

`stylesheet_link_tag` 輔助方法根據提供的來源，回傳 HTML 的 `<link>` 標籤。

若有啟用 Rails 的 [Asset Pipeline](asset_pipeline.html)，這個輔助方法會產生指向 `assets/stylesheets` 的連結。接著交給 Sprockets Gem 來處理。樣式表檔案可以存在這三個地方：`app/assets`、`lib/assets` 或 `vendor/assets`。

可以指定相對於根目錄的完整路徑，或是 URL 也可以。舉例來說，要連結到放在 `stylesheets` 目錄（`app/assets`、`lib/assets` 或是 `vendor/assets`）下的樣式表檔案，可以這麼寫：

```erb
<%= stylesheet_link_tag "main" %>
```

要引入 `app/assets/stylesheets/main.css` 和 `app/assets/stylesheets/columns.css`：

```erb
<%= stylesheet_link_tag "main", "columns" %>
```

要引入 `app/assets/stylesheets/main.css` 和 `app/assets/stylesheets/photos/columns.css`：

```erb
<%= stylesheet_link_tag "main", "photos/columns" %>
```

要引入 `http://example.com/main.css`：

```erb
<%= stylesheet_link_tag "http://example.com/main.css" %>
```

`stylesheet_link_tag` 建立出 `<link>` 標籤，預設有 `media="screen" rel="stylesheet"` 屬性。可以覆寫這些預設值，使用 `:media`、`:rel` 選項來修改：

```erb
<%= stylesheet_link_tag "main_print", media: "print" %>
```

#### 使用 `image_tag` 來連結圖片

`image_tag` 輔助方法根據指定的檔案建立出 `<img />` 標籤。預設情況會載入 `public/images` 目錄下的檔案。

WARNING: 必須指定圖片的副檔名。

```erb
<%= image_tag "header.png" %>
```

可以指定圖片的路徑：

```erb
<%= image_tag "icons/delete.gif" %>
```

也可以提供其它的 HTML 選項：

```erb
<%= image_tag "icons/delete.gif", {height: 45} %>
```

可以提供當使用者把瀏覽器顯示圖片功能關掉所要顯示的文字。若沒特別指定 `alt` 文字，預設值是檔案名稱（轉成大寫、去掉副檔名）。舉例來說，以下兩個 image 標籤會回傳一樣的 HTML：

```erb
<%= image_tag "home.gif" %>
<%= image_tag "home.gif", alt: "Home" %>
```

也可以指定大小，格式為 `"{width}x{height}"`。

```erb
<%= image_tag "home.gif", size: "50x20" %>
```

除了上開選項之外，可以提供標準 HTML 所接受的選項，以 Hash 傳入，像是 `:class`、`:id`、`:name`：

```erb
<%= image_tag "home.gif", alt: "Go Home",
                          id: "HomeImage",
                          class: "nav_bar" %>
```

#### 使用 `video_tag` 連結到視訊檔案

`video_tag` 輔助方法根據指定的檔案建立 HTML 5 的 `<video>` 標籤。預設從 `public/videos` 載入檔案。

```erb
<%= video_tag "movie.ogg" %>
```

會產生：

```erb
<video src="/videos/movie.ogg" />
```

和 `image_tag` 一樣，可以提供路徑，絕對路徑或相對於 `public/videos` 的路徑。除此之外，可以指定大小：`size: "#{width}x#{height}"`。也接受標準 HTML 所接受的選項（`id`、`class` 等）。

`video_tag` 也支持所有 `<video>` 所支援的 HTML 選項：

* `poster: "image_name.png"`，提供一張播放前的預覽圖片。
* `autoplay: true`，頁面載入時自動播放影片。
* `loop: true`，播放結束時重新播放。
* `controls: true`，提供瀏覽器支持的控件給使用者，用來與影片做互動。
* `autobuffer: true`，頁面載入時，會先緩衝影片。

也可以一次指定多筆要播放的影片：

```erb
<%= video_tag ["trailer.ogg", "movie.ogg"] %>
```

會產生：

```erb
<video><source src="/videos/trailer.ogg" /><source src="/videos/trailer.flv" /></video>
```

#### 使用 `audio_tag` 連結到音訊檔案

`audio_tag` 輔助方法根據指定的檔案建立 HTML 5 的 `<audio>` 標籤。預設從 `public/audios` 載入檔案。

```erb
<%= audio_tag "music.mp3" %>
```

可以指定音訊檔案的路徑：

```erb
<%= audio_tag "music/first_song.mp3" %>
```
也可以提供標準 HTML 所接受的選項（`id`、`class` 等）。

和 `video_tag` 一樣，`audio_tag` 有特殊選項：

* `autoplay: true`，頁面載入時自動播放音訊。
* `controls: true`，提供瀏覽器支持的控件給使用者，用來與音訊檔案做互動。
* `autobuffer: true`，頁面載入時，會先緩衝音訊檔案。

### 理解 `yield`

在版型的上下文裡，`yield` 分出一塊區域，決定應該要插入什麼內容。最簡單就是使用單一個 `yield`，算繪的整個 View 都會插入到這個區域：

```html+erb
<html>
  <head>
  </head>
  <body>
  <%= yield %>
  </body>
</html>
```

可以建立多個 `yield` 區域：

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

View 的主要內容總是會插入到無名的 `yield`。要把算繪內容到具名的 `yield` 區域，可以使用 `content_for` 方法。

### 使用 `content_for` 方法

`content_for` 方法允許在版型裡插入內容到 `yield` 具名的區塊。舉例來說，上例有 `<%= yield :head %>` 的版型，要結合下面的 `content_for` 使用：

```html+erb
<% content_for :head do %>
  <title>A simple page</title>
<% end %>

<p>Hello, Rails!</p>
```

算繪此頁的結果為：

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

`content_for` 在版型分多個區域，各個區域內容不同時很有用，像是邊欄、頁尾。`content_for` 也可以用來針對特定頁面插入 JavaScript 或 CSS。

### 使用局部頁面

局部頁面模版，如其名“局部頁面”──是另個可以把算繪過程分成多個片段的工具。有了局部頁面，可以把某些特定內容的算繪移到單獨的檔案。

#### 局部頁面命名

在 View 算繪局部頁面：

```ruby
<%= render "menu" %>
```

會在呼叫的地方對 `_menu.html.erb` 進行算繪。注意名字開頭有“底線”（`_`）：局部頁面的命名規則是由底線開始，用來和一般的 View 區隔開來，但引入局部頁面時，無需寫底線：

```ruby
<%= render "shared/menu" %>
```

這段程式碼會從 `app/views/shared/_menu.html.erb` 引入局部頁面。

#### 使用局部頁面來簡化 View

使用局部頁面的一種方式是，把它想成是副程式：把細節抽離出去，以便更好理解 View 在做什麼。舉個例子，可能看過這樣寫的 View：

```erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
...

<%= render "shared/footer" %>
```

這裡的 `_ad_banner.html.erb` 和 `_footer.html.erb`，內容可以包含應用程式裡可以共用的內容。這麼一來在撰寫特定頁面時，引用這些局部頁面就好，而無需關注細節。

TIP: 對於應用程式裡都可以共用的內容，可以直接在版型裡使用局部頁面。

#### 局部頁面的版型

局部頁面可以使用自己的版型，就跟 View 可以使用版型一樣。舉例來說，可能會這麼呼叫局部頁面：

```erb
<%= render partial: "link_area", layout: "graybar" %>
```

會尋找 `_link_area.html.erb` 的局部頁面，使用 `_grabar.html.erb` 版型來算繪。注意局部頁面的版型，同樣遵循用底線開頭的命名規則。局部頁面的版型和局部頁面放在同一個資料夾裡（而不是放在應用程式的版型目錄裡 `app/views/layouts`）。

同樣注意到，傳入額外的選項，像是 `:layout` 時，需要明確指定 `:partial`。

#### 傳入區域變數

可以傳入區域變數到局部頁面裡，這麼一來局部頁面變得更強大靈活。舉個例子，用至這個方法來減少 `new` 與 `edit` 頁面重複的程式碼，但仍保有不同的內容：

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

雖然 `new` 與 `edit` 使用同樣的局部頁面，Action View 的 `submit` 輔助方法對 `new` 動作會回傳 `"Create Zone"`；而 `edit` 動作則會回傳 `"Update Zone"`。

每個局部頁面都有個與局部頁面同名的區域變數（沒有開頭的底線）。可以用 `:object` 選項把物件傳給這個區域變數：

```erb
<%= render partial: "customer", object: @new_customer %>
```

在 `customer` 局部頁面裡，`customer` 變數會對應到呼叫時的 `@new_customer`。

若有一個實體變數要傳入局部頁面，可以使用簡寫：

```erb
<%= render @customer %>
```

假設 `@customer` 實體變數是 `Customer` Model 的實體。上面的程式碼會用 `_customer.html.erb` 來算繪，區域變數 `customer` 的值是 `@customer`。

#### 算繪集合

局部頁面在算繪集合時非常有用。當使用 `:collection` 選項，會把集合的每個元素插入的局部頁面裡：

* `index.html.erb`

    ```html+erb
    <h1>Products</h1>
    <%= render partial: "product", collection: @products %>
    ```

* `_product.html.erb`

    ```html+erb
    <p>Product Name: <%= product.name %></p>
    ```

當局部頁面傳入複數形式的集合時，可以在局部頁面裡透過與局部頁面同名的變數來存取到集合的成員。上例裡，局部頁面是 `_product`，`product` 則是當下被算繪的實體。

算繪集合有簡寫形式。假設 `@products` 是 `product` 實體的集合，則在 `index.html.erb` 可以這麼寫：

```html+erb
<h1>Products</h1>
<%= render @products %>
```

Rails 根據集合各元素的 Model 名稱，來決定要使用的是那個局部頁面。實際上，集合內的元素可以來自不同的 Model，Rails 會給元素選擇正確的局部頁面進行算繪。

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

這個例子裡，Rails 會根據集合成員所屬的 Model，來選擇要使用的局部頁面。

若集合為空，則 `render` 方法會回傳 `nil`，所以最好提供集合為空時的替代文字。

```html+erb
<h1>Products</h1>
<%= render(@products) || "There are no products available." %>
```

#### 區域變數

要在局部頁面裡使用區域變數，在呼叫局部頁面時使用 `:as` 選項：

```erb
<%= render partial: "product", collection: @products, as: :item %>
```

這樣修改以後，可以在局部頁面裡，用 `item` 來存取到 `@products` 集合裡的成員。

也可以使用 `locals: {}` 選項，給任何的局部頁面，傳入隨意的區域變數。

```erb
<%= render partial: "product", collection: @products,
           as: :item, locals: {title: "Products Page"} %>
```

在這個情況裡，局部頁面裡可以存取到 `title` 區域變數，值是 `"Products Page"`。

TIP: Rails 也給傳入集合的局部頁面，提供了一個計數器變數。名稱是集合名加上 `_counter`。譬如在算繪 `@products` 時，可以在局部頁面裡使用 `product_counter`，來知道局部頁面被算繪了幾次。但不能和 `as: :value` 選項一起使用。

在主局部頁面渲染實體之間，可以使用 `:spacer_template` 選項指定第二個局部頁面。

#### Spacer 模版

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

Rails 會在算繪 `_product` 局部頁面時，在兩次算繪之間，算繪 `_product_ruler` 局部頁面（不傳入任何資料）。

#### 集合局部頁面的版型

當算繪集合時，也可以使用 `:layout` 選項。

```erb
<%= render partial: "product", collection: @products, layout: "special_layout" %>
```

在算繪集合各元素時，會同時算繪指定的版型。目前的物件和 `object_counter` 變數在版型裡也可以使用。

### Using Nested Layouts

可能會需要給特定的 Controller，使用和一般應用程式版型不太一樣的版型。與其重複主版型進行編輯，可以使用嵌套版型來完成（有時候也叫子模版）。以下是個範例。

假設 `ApplicationController` 的版型如下：

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

而由 `NewsController` 產生的頁面，想要把上面的選單隱藏起來，並且在右邊新增一個選單：

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

這樣就可以了。`NewsController` 會使用 `news.html.erb` 版型，隱藏上面的選單，在 `id` 是 `"content"` 的 `div` 右邊加一個選單。

有數種使用子模版的方式可以達到同樣的效果。但注意，嵌套層數沒有限制。也可以透過 `render template: 'layout/news'` 來使用 `ActionView::render` 方法，在 `news` 版型的基礎上使用新的版型。若確定 `news` 版型不會有子模版，則可以把 `content_for?(:news_content) ? yield(:news_content) : yield` 換成 `yield` 即可。
