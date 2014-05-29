Rails 路由：深入淺出
=================================

本篇介紹與使用者息息相關的路由功能。

讀完本篇，您將了解：

* 如何解讀 `routes.rb` 裡的程式碼。
* 如何使用推薦的資源式寫法或使用 `match` 方法來撰寫路由。
* Controller 動作可接受的參數有那些。
* 如何使用路由輔助方法來自動建立路徑與 URL。
* 路由約束條件與 Rack Endpoint 等進階技巧。

--------------------------------------------------------------------------------

Rails 路由器的目的
-------------------------------

Rails 路由器（router）識別 URL，分配給對應的 Controller 動作處理。Rails 路由器同時也可用來產生路徑與 URL，避免在 View 裡面把路徑寫死。

### URL 工作分派

當 Rails 收到如下請求時：

```
GET /patients/17
```

會詢問路由器，匹配的 Controller 動作是那個。若第一個匹配的路由為：

```ruby
get '/patients/:id', to: 'patients#show'
```

則請求會分派給 `PatientsController` 的 `show` 動作處理，且 `params` 裡有 `{ id: '17' }` 參數。

### 產生路徑與 URL

Rails 路由器也可以產生路徑與 URL。若上例的路由改寫為：

```ruby
get '/patients/:id', to: 'patients#show', as: 'patient'
```

且應用程式 Controller 裡有以下程式碼：

```ruby
@patient = Patient.find(17)
```

並有對應的 View：

```erb
<%= link_to 'Patient Record', patient_path(@patient) %>
```

則路由器便會給 `patient_path(@patient)` 產生路徑 `/patients/17`。這使得程式碼更容易了解。注意，使用路由輔助方法（`patient_path`）時，無需指定 ID。

資源式路由：Rails 的預設路由
-----------------------------------

資源式路由允許替給定的資源式 Controller，快速宣告出所有常見的路由。與其替每個動作（ `index`、`show`、`new`、`edit`、`create`、`update` 以及 `destroy`）個別宣告路由，資源式路由宣告只需要一行即可。

### Web 世界裡的資源

瀏覽器向 Rails 請求頁面時，透過使用具體的 HTTP 動詞，如 `GET`、`POST`、`PATCH`、`PUT` 以及 `DELETE`，往 URL 發出請求。每個動詞都是對資源的一種操作。資源式路由將相關的請求，對應到 Controller 的不同動作。

當 Rails 應用程式收到下面這個請求時：

```
DELETE /photos/17
```

會詢問路由器，該交給那個 Controller 的那個動作處理。若第一個匹配的路由為：

```ruby
resources :photos
```

Rails 會將請求分派給 `PhotosController` 的 `destroy` 方法，且 `params` 裡有 `{ id: '17' }` 參數。

### CRUD、HTTP 動詞以及動作

在 Rails 裡，資源式路由提供 HTTP 動詞、URL、Controller 動作，這三者的對應關係。按照慣例，每個動作會對應到資料庫特定的 CRUD 操作。假設路由檔案裡有一條路由宣告為：

```ruby
resources :photos
```

會在應用程式建立出七筆不同的路由，皆對應到 `PhotosController`：

| HTTP 動詞 | 路徑             | Controller#動作 | 用途                                     |
| --------- | --------------- | -------------- | --------------------------------------- |
| GET       | /photos          | photos#index      | 顯示所有圖片                 |
| GET       | /photos/new      | photos#new        | 回傳建立新圖片的表單 |
| POST      | /photos          | photos#create     | 建立新圖片                           |
| GET       | /photos/:id      | photos#show       | 顯示特定圖片                     |
| GET       | /photos/:id/edit | photos#edit       | 回傳編輯圖片的表單     |
| PATCH/PUT | /photos/:id      | photos#update     | 更新特定圖片                     |
| DELETE    | /photos/:id      | photos#destroy    | 刪除特定圖片                      |

NOTE: 因為路由器使用 HTTP 動詞與 URL ，來匹配進來的請求，所以可以將四個 URL 對應到七種不同的動作。

NOTE: Rails 路由依據宣告的順序來匹配。若在 `get 'photos/poll'` 之前宣告了 `resources :photos`，則 `show` 動作會先匹配到 `resources :photos`。若想將 `get 'photos/poll'` 的匹配順序提前，提到 `resources :photos` 之前即可。

### 路徑與 URL 的輔助方法

新建一筆資源式的路由，同時會給 Controller 加入一些輔助方法。以 `resources :photos` 為例，可用的輔助方法有：

| 輔助方法 | 用途 |
| ------- | ----- |
| `photos_path` | 回傳 `/photos` |
| `new_photo_path` | 回傳 `/photos/new` |
| `edit_photo_path(:id)` | 回傳 `/photos/:id/edit` (例如 `edit_photo_path(10)` 會回傳 `/photos/10/edit`) |
| `photo_path(:id)` | 回傳 `/photos/:id` (例如 `photo_path(10)` 回傳 `/photos/10`) |

這些輔助方法有對應的 `*_url` 形式（像是 `photos_url`），`*_url` 會回傳完整的路徑，包含了主機、埠口以及路徑。

### 同時定義多筆資源

如需要給多個資源建立路由時，可以用一行 `resources` 宣告完成，節省一些打字的時間：

```ruby
resources :photos, :books, :videos
```

等同於：

```ruby
resources :photos
resources :books
resources :videos
```

### 單數資源

有些資源不需要 ID 便能查詢。舉個例子，希望 `/profile` 顯示目前登入使用者的個人檔案。這個情況下可以使用單數資源（Singular resource），把 `/profile`（而不是 `/profile/:id`）對應到 `show` 動作：

```ruby
get 'profile', to: 'users#show'
```

`:to` 選項傳入字串要使用 `controller#action` 的形式，傳入符號會直接對應到動作名稱。

```ruby
get 'profile', to: :show
```

以下這筆單數資源式路由：

```ruby
resource :geocoder
```

會建立出六筆不同的路由，皆對應到 `GeocodersController`：

| HTTP 動詞 | 路徑           | Controller#動作 | 用途                                      |
| --------- | ------------- | --------------- | ---------------------------------------- |
| GET       | /geocoder/new  | geocoders#new     | 回傳建立 `geocoder` 的表單 |
| POST      | /geocoder      | geocoders#create  | 建立新 `geocoder`                       |
| GET       | /geocoder      | geocoders#show    | 顯示唯一的 `geocoder` 資源    |
| GET       | /geocoder/edit | geocoders#edit    | 回傳編輯 `geocoder` 的表單 |
| PATCH/PUT | /geocoder      | geocoders#update  | 更新唯一的 `geocoder` 資源    |
| DELETE    | /geocoder      | geocoders#destroy | 刪除 `geocoder` 資源                  |

NOTE: 有時單數（`/account`）與複數路由（`/accounts/45`）想交給同樣的 Controller 處理，或是把單數資源對應到複數 Controller 上。舉個例子，`resource :photo` 與 `resources :photos` 同時建立出單數與複數的路由，皆對應到 `PhotosController`。

單數的資源式路由會產生以下輔助方法：

| 輔助方法 | 用途 |
| ------- | ----- |
| `new_geocoder_path` | 回傳 `/geocoder/new` |
| `edit_geocoder_path` | 回傳 `/geocoder/edit` |
| `geocoder_path` | 回傳 `/geocoder` |

和複數資源的路由相同，皆有對應的 `*_url` 形式，會回傳完整的路徑，包含了主機、埠口以及路徑。

WARNING: 有一個[存在已久的 Bug](https://github.com/rails/rails/issues/1769) 導致 `form_for` 無法自動處理好單數資源。解決辦法是給表單明確指定 URL：

```ruby
form_for @geocoder, url: geocoder_path do |f|
```

### Controller 命名空間與路由

有時可能想把一堆 Controllers 放在同個命名空間下管理。最常見的場景是需要把管理用的 Controller 放在 `Admin::` 命名空間下。首先將這些 Controllers 搬到 `app/controllers/admin` 資料夾底下，接著在路由裡宣告：

```ruby
namespace :admin do
  resources :articles, :comments
end
```

會給 `Articles` 與 `Comments` Controllers 在 `Admin::` 命名空間下建出路由。比如 `Admin::ArticlesController`，Rails 會產生以下路由：

| HTTP 動詞  | 路徑                      | Controller#動作        | 輔助方法                      |
| --------- | ------------------------ | ---------------------- | ---------------------------- |
| GET       | /admin/articles          | admin/articles#index   | admin_articles_path          |
| GET       | /admin/articles/new      | admin/articles#new     | new_admin_article_path       |
| POST      | /admin/articles          | admin/articles#create  | admin_articles_path          |
| GET       | /admin/articles/:id      | admin/articles#show    | admin_article_path(:id)      |
| GET       | /admin/articles/:id/edit | admin/articles#edit    | edit_admin_article_path(:id) |
| PATCH/PUT | /admin/articles/:id      | admin/articles#update  | admin_article_path(:id)      |
| DELETE    | /admin/articles/:id      | admin/articles#destroy | admin_article_path(:id)      |

若想把路徑拿掉 `/admin` 前綴，則可以這麼宣告：

```ruby
scope module: 'admin' do
  resources :articles, :comments
end
```

如只有一筆資源，則可簡寫為：

```ruby
resources :articles, module: 'admin'
```

若路由希望是 `/admin/articles`，但想拿掉 `Admin::` 的前綴，可以這麼宣告：

```ruby
scope '/admin' do
  resources :articles, :comments
end
```

如只有一筆資源，則可簡寫為：

```ruby
resources :articles, path: '/admin/articles'
```

以上這些例子，若沒有使用 `scope`，則輔助方法保持不變。看看上面最後一個使用 `scope` 的例子（與前個表格對比看看那裡不一樣），Rails 會產生以下路由：

| HTTP 動詞  | 路徑                      | Controller#動作      | 輔助方法                |
| --------- | ------------------------ | -------------------- | ---------------------- |
| GET       | /admin/articles          | articles#index       | articles_path          |
| GET       | /admin/articles/new      | articles#new         | new_article_path       |
| POST      | /admin/articles          | articles#create      | articles_path          |
| GET       | /admin/articles/:id      | articles#show        | article_path(:id)      |
| GET       | /admin/articles/:id/edit | articles#edit        | edit_article_path(:id) |
| PATCH/PUT | /admin/articles/:id      | articles#update      | article_path(:id)      |
| DELETE    | /admin/articles/:id      | articles#destroy     | article_path(:id)      |

TIP: 若需要在 `namespace` 區塊裡，使用不同的命名空間。可以指定 Controller 的絕對路徑：`get '/foo' => '/foo#index'`。

### 嵌套資源

資源是其它資源的子資源是很常見的情況。舉例來說，假設應用程式有雜誌與廣告兩個 Model：

```ruby
class Magazine < ActiveRecord::Base
  has_many :ads
end

class Ad < ActiveRecord::Base
  belongs_to :magazine
end
```

這種關係可以用嵌套路由來描述。在這個情況裡，可以這麼宣告路由：

```ruby
resources :magazines do
  resources :ads
end
```

上面會建立 `MagazinesController` 的路由，也會給 `AdsController` 建立路由。`Ad` 的路徑裡會需要引用 `Magazine` 資源：

| HTTP 動詞 | 路徑                                 | Controller#動作 | 用途                                                                   |
| --------- | ----------------------------------- | ---------------- | -------------------------------------------------------------------------- |
| GET       | /magazines/:magazine_id/ads          | ads#index         | 顯示特定雜誌的所有廣告                          |
| GET       | /magazines/:magazine_id/ads/new      | ads#new           | 回傳給特定雜誌新建廣告的表單 |
| POST      | /magazines/:magazine_id/ads          | ads#create        | 建立屬於特定雜誌的廣告                           |
| GET       | /magazines/:magazine_id/ads/:id      | ads#show          | 顯示屬於特定雜誌的廣告                     |
| GET       | /magazines/:magazine_id/ads/:id/edit | ads#edit          | 回傳編輯屬於特定雜誌廣告的表單     |
| PATCH/PUT | /magazines/:magazine_id/ads/:id      | ads#update        | 更新屬於特定雜誌的廣告                      |
| DELETE    | /magazines/:magazine_id/ads/:id      | ads#destroy       | 刪除屬於特定雜誌的廣告                     |

同時這也會建立像是 `magazine_ads_url` 以及 `edit_magazine_ad_path` 的路由輔助方法。這些方法可接受 `Magazine` 的實體作為第一個參數：`magazine_ads_url(@magazine)`。

#### 嵌套的限制

嵌套資源也可以放在其它的嵌套資源裡，譬如：

```ruby
resources :publishers do
  resources :magazines do
    resources :photos
  end
end
```

多層嵌套很快的變得很難處理。在這個情況裡，應用程式需要識別像是下面的路由：

```
/publishers/1/magazines/2/photos/3
```

對應的路由輔助方法則變成： `publisher_magazine_photo_url`，需要指定三層的物件。這個情況已經足夠令人困惑，使得 Jamis Buck 寫出一篇流行的[文章](http://weblog.jamisbuck.org/2007/2/5/nesting-resources)，文章總結了好的 Rails 的設計經驗準則：

TIP: 嵌套資源永遠不要超過 1 層。

#### 淺層嵌套

避免多層嵌套的方法之一，是將 Controller 的集合動作放在父資源的作用域底下，這樣可以有階層的概念，但不需要嵌套的成員動作。也就是說，只用最少的資源資訊來表示路由，像是：

```ruby
resources :articles do
  resources :comments, only: [:index, :new, :create]
end
resources :comments, only: [:show, :edit, :update, :destroy]
```

這種做法在有意義的描述路由與深層嵌套之間取得平衡。上例還可以使用 `:shallow` 選項來簡寫：

```ruby
resources :articles do
  resources :comments, shallow: true
end
```

這種寫法產生的路由與上例相同。也可以對父資源指定 `:shallow` 選項，則父資源底下的資源都會是淺層嵌套：

```ruby
resources :articles, shallow: true do
  resources :comments
  resources :quotes
  resources :drafts
end
```

另有一個 `shallow` 方法，建立一個作用域區塊，其中的路由皆是淺層嵌套。以下範例會產生與前例相同的路由：

```ruby
shallow do
  resources :articles do
    resources :comments
    resources :quotes
    resources :drafts
  end
end
```

`scope` 方法有兩個選項，可以用來客製化淺層路由。`:shallow_path` 可以在 member path 前加上指定的前綴：

```ruby
scope shallow_path: "sekret" do
  resources :articles do
    resources :comments, shallow: true
  end
end
```

comments 資源會有下列路由：

| HTTP Verb | Path                                         | Controller#Action | Named Helper          |
| --------- | -------------------------------------------- | ----------------- | --------------------- |
| GET       | /articles/:article_id/comments(.:format)     | comments#index    | article_comments_path    |
| POST      | /articles/:article_id/comments(.:format)     | comments#create   | article_comments_path    |
| GET       | /articles/:article_id/comments/new(.:format) | comments#new      | new_article_comment_path |
| GET       | /sekret/comments/:id/edit(.:format)          | comments#edit     | edit_comment_path     |
| GET       | /sekret/comments/:id(.:format)               | comments#show     | comment_path          |
| PATCH/PUT | /sekret/comments/:id(.:format)               | comments#update   | comment_path          |
| DELETE    | /sekret/comments/:id(.:format)               | comments#destroy  | comment_path          |

`:shallow_prefix` 選項則是給 named helpers 加上前綴:

```ruby
scope shallow_prefix: "sekret" do
  resources :articles do
    resources :comments, shallow: true
  end
end
```

comments 資源會有下列路由：

| HTTP Verb | Path                                         | Controller#Action | Named Helper             |
| --------- | -------------------------------------------- | ----------------- | ------------------------ |
| GET       | /articles/:article_id/comments(.:format)     | comments#index    | article_comments_path       |
| POST      | /articles/:article_id/comments(.:format)     | comments#create   | article_comments_path       |
| GET       | /articles/:article_id/comments/new(.:format) | comments#new      | new_article_comment_path    |
| GET       | /comments/:id/edit(.:format)                 | comments#edit     | edit_sekret_comment_path |
| GET       | /comments/:id(.:format)                      | comments#show     | sekret_comment_path      |
| PATCH/PUT | /comments/:id(.:format)                      | comments#update   | sekret_comment_path      |
| DELETE    | /comments/:id(.:format)                      | comments#destroy  | sekret_comment_path      |

### Routing Concerns

Routing Concerns 允許將常見的路由宣告為可重用的，可在其他資源與路由裡使用。定義一個 Routing Concerns：

```ruby
concern :commentable do
  resources :comments
end

concern :image_attachable do
  resources :images, only: :index
end
```

這些 Concerns 可以在資源裡使用，來避免寫重複的程式碼，以及讓路由之間可以共享行為：

```ruby
resources :messages, concerns: :commentable

resources :articles, concerns: [:commentable, :image_attachable]
```

上例等價於：

```ruby
resources :messages do
  resources :comments
end

resources :articles do
  resources :comments
  resources :images, only: :index
end
```

Concerns 可以在任何地方使用，譬如在作用域，或是命名空間呼叫裡使用：

```ruby
namespace :articles do
  concerns :commentable
end
```

### 從物件建立路徑與 URL

除了使用路由輔助方法之外，Rails 也可以從一組參數，建出路徑與 URL。舉例來說，假設有以下路由：

```ruby
resources :magazines do
  resources :ads
end
```

在使用 `magazine_ad_path` 時，可以傳入 `Magazine` 與 `Ad` 的實體，而不需要傳入 ID：

```erb
<%= link_to 'Ad details', magazine_ad_path(@magazine, @ad) %>
```

也可以使用 `url_for`，搭配一組物件，則 Rails 會自動決定要用那個路由：

```erb
<%= link_to 'Ad details', url_for([@magazine, @ad]) %>
```

這個情況裡，Rails 看到 `@magazine` 與 `@ad`，會使用 `magazine_ad_path` 輔助方法。在像是 `link_to` 的輔助方法，可以直接指定物件，省略 `url_for`：

```erb
<%= link_to 'Ad details', [@magazine, @ad] %>
```

若想要只連到雜誌：

```erb
<%= link_to 'Magazine details', @magazine %>
```

要連到不同的動作，在參數陣列的第一個元素，指定動作名稱即可：
```erb
<%= link_to 'Edit Ad', [:edit, @magazine, @ad] %>
```

這種用法可以將 Model 的實體當做 URL 看待，是使用資源式路由的主要優勢之一。

### 新增更多資源式路由

不受限於七個預設產生的資源式路由。還可以新增更多集合路由、成員路由。

#### 新增成員路由

要新增成員路由，只需要在 `resources` 區塊裡加入 `member` 區塊：

```ruby
resources :photos do
  member do
    get 'preview'
  end
end
```

這會識別出 `/photos/1/preview` 的 GET 請求，交給 `PhotosController` 的 `preview` 動作處理，相片的 ID 會存在 `params[:id]`。也會新增 `preview_photo_path` 與 `preview_photo_url` 輔助方法。

在成員路由的區塊裡，可以指定使用特定的 HTTP 動詞。可用的有：`get`、`patch`、`put`、`post` 或 `delete`。若成員路由只有一筆，可以使用 `:on`，便不需要以區塊形式宣告：

```ruby
resources :photos do
  get 'preview', on: :member
end
```

也可以不使用 `:on` 選項，會得到相同的成員路由，只是 ID 會存在 `params[:photo_id]`，而不是 `params[:id]`。

#### 新增集合路由

新增一筆集合路由：

```ruby
resources :photos do
  collection do
    get 'search'
  end
end
```

這會使 Rails 識別出發送到 `/photos/search` 的 GET 請求，交給 `PhotosController` 的 `search` 動作處理。也會新增 `search_photos_path` 與 `search_photos_url` 輔助方法。

和成員路由相同，可以傳入 `:on` 選項：

```ruby
resources :photos do
  get 'search', on: :collection
end
```

#### 給額外的新動作新增路由

要新增額外的 `new` 動作，可以使用 `:on` 選項：

```ruby
resources :comments do
  get 'preview', on: :new
end
```

這會使 Rails 識別出發送到 `/comments/new/preview` 的 GET 請求，交給 `CommentsController` 的 `preview` 動作處理。也會新增 `preview_new_comment_path` 與 `preview_new_comment_url` 輔助方法。

TIP: 若發現給資源新增了許多額外的動作，停下來想想是不是要拆成另一個資源。

非資源式路由
----------------------

除了資源式路由之外，將隨意的 URL 對應到動作，Rails 提供了強大的支持。這一節不像資源式路由，會獲得一組自動產生的路由。反而是自己在應用程式裡設定每一條路由。

雖然通常應該要使用資源式路由，但仍有許多簡單的路由更合適的場景。也不用整個應用程式都得用資源式風格的路由才行，選擇最合適的解決方案。

簡單的路由使得把傳統的 URL 對應到 Rails 動作變得特別簡單。

### 綁定參數

設定一般的路由時，提供一系列的符號給 Rails，Rails 會根據這些符號來對進來的 HTTP 請求做匹配。有兩個特殊符號：`:controller` 會對應到應用程式裡的 Controller 名稱，而 `:action` 則是對應到該 Controller 的動作。舉例來說，看下面這條路由：

```ruby
get ':controller(/:action(/:id))'
```
若發送到 `/photos/show/1` 的請求由這條路由處理（路由檔案裡沒有其它匹配的路由），則會呼叫 `PhotosController` 的 `show` 動作，並將 `params{:id]` 設為 `"1"`。這條路由也會處理發送到 `/photos` 的請求，將請求交給 `PhotosController#index` 處理。因為 `:action`、`:id` 放在括號裡代表是可選參數。

### 動態片段

一般的路由裡可以設定多個動態片段。路由裡任何不是 `:controller`、`:action` 的選項，都會變成 `params` 的一部分。若有以下路由：

```ruby
get ':controller/:action/:id/:user_id'
```

任何至 `/photos/show/1/2` 的請求會被分配給 `PhotosController` 的 `show` 動作處理，`params[:id]` 則會設為 `"1"`，而 `params[:user_id]` 則是 `"2"`。

NOTE: 路徑片段有 `:controller` 時，無法與 `:namespace`、`:module` 一起使用。若需要這麼做的話，對 `:controller` 使用約束條件，明確指定要匹配的命名空間，譬如：

```ruby
get ':controller(/:action(/:id))', controller: /admin\/[^\/]+/
```

TIP: 動態片段預設不接受 `.` ── 這是因為 `.` 是格式化路由的分隔符。如需要在動態片段裡使用 `.`，用約束條件來處理 ── 例如，`id: /[^\/]+/` 允許斜線以外的所有字元。

### 靜態片段

建立路由時，可以指定靜態片段，片段前不加冒號即可：

```ruby
get ':controller/:action/:id/with_user/:user_id'
```

這條路由會回應發送到 `/photos/show/1/with_user/2` 的請求，`params` 的內容則為 `{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`。

### 查詢字串

`params` 也會存放查詢字串的參數。舉個例子，看看以下這條路由：

```ruby
get ':controller/:action/:id'
```

從 `/photos/show/1?user_id=2` 進來的請求會分配給 `PhotosController` 的 `show` 動作處理，`params` 的內容為 `{ controller: 'photos', action: 'show', id: '1', user_id: '2' }`。

### 定義預設值

路由裡不需要明確使用 `:controller` 與 `:action`。可以指定預設值：

```ruby
get 'photos/:id', to: 'photos#show'
```

有了這條路由之後，Rails 會分配 `/photos/12` 給 `PhotosController` 的 `show` 動作。

也可以傳 Hash 給 `:defaults` 選項，來給路由新增預設值。這對於沒有寫動態片段的路由也適用。舉例來說：

```ruby
get 'photos/:id', to: 'photos#show', defaults: { format: 'jpg' }
```

Rails 會匹配 `photos/12` to the `show` action of `PhotosController`, and set `params[:format]` to `"jpg"`.

### 命名路由

可以使用 `:as` 選項給任何路由取名字：

```ruby
get 'exit', to: 'sessions#destroy', as: :logout
```

會建立出 `logout_path` 與 `logout_url` 這兩個具名輔助方法。呼叫 `logout_path` 會回傳 `/exit`。

也可以使用 `:as` 來覆寫 `resources` 預設定義的方法：

```ruby
get ':username', to: 'users#show', as: :user
```

會定義 `user_path` 方法，在 Controller、輔助方法、以及 View 裡都可用，會回傳像是 `/bob` 的路徑。在 `UsersController` 的 `show` 動作裡，`params[:username]` 會有使用者的 `username`，如不喜歡參數名稱取名為 `:username` 可以修改這個值。

### HTTP 動詞約束條件

通常應該使用 `get`、`post`、`put`、`patch` 以及 `delete` 方法來限制路由只處理特定的動詞。`match` 方法與 `:via` 選項可以一直匹配多個動詞：

```ruby
match 'photos', to: 'photos#show', via: [:get, :post]
```

路由要匹配所有的動詞也可以，`via: :all`：

```ruby
match 'photos', to: 'photos#show', via: :all
```

NOTE: 將 `GET` 與 `POST` 請求路由到單一的動作有安全隱憂。除非有很好的理由，通常應該要避免將所有 HTTP 動詞對應到一個動作上。

### 片段約束

使用 `:constraints` 選項限制動態片段的格式：

```ruby
get 'photos/:id', to: 'photos#show', constraints: { id: /[A-Z]\d{5}/ }
```

這條路由會匹配像是 `/photos/A12345`，但不會匹配 `/photos/893`。可以進一步簡化為：

```ruby
get 'photos/:id', to: 'photos#show', id: /[A-Z]\d{5}/
```

`:constraints` 雖然接受正規表示法，但不能使用錨點（anchors）。比如以下路由不會正常工作：

```ruby
get '/:id', to: 'articles#show', constraints: {id: /^\d/}
```

但其實不需要使用錨點，因為所有的路由皆從頭開始匹配。

舉個例子，下面的路由，若 `articles` 呼叫 `to_param` 的值像是 `1-hello-world`，以數字開頭，就會把請求交給 `ArticlesController` 的 `show` 動作處理；而 `to_param` 的值不以數字開頭，像是 `david`，則會交給 `UsersController` 的 `show` 動作處理。

```ruby
get '/:id', to: 'articles#show', constraints: { id: /\d.+/ }
get '/:username', to: 'users#show'
```

### 基於請求的約束條件

也可以使用 [`request` 物件](action_controller_overview.html#request-物件)裡，任何會回傳字串的方法，來宣告路由的約束條件。

基於 `request` 物件的約束條件的宣告方式與片段約束條件相同：

```ruby
get 'photos', constraints: {subdomain: 'admin'}
```

約束條件也可以使用區塊形式：

```ruby
namespace :admin do
  constraints subdomain: 'admin' do
    resources :photos
  end
end
```

### 進階約束條件

如有更進階的約束條件，可以傳入一個回應 `matches?` 的物件。假設需要將所有黑名單的使用者交給 `BlackListController` 處理，可以這麼做：

```ruby
class BlacklistConstraint
  def initialize
    @ips = Blacklist.retrieve_ips
  end

  def matches?(request)
    @ips.include?(request.remote_ip)
  end
end

TwitterClone::Application.routes.draw do
  get '*path', to: 'blacklist#index',
    constraints: BlacklistConstraint.new
end
```

約束條件也可用 lambda 宣告：

```ruby
TwitterClone::Application.routes.draw do
  get '*path', to: 'blacklist#index',
    constraints: lambda { |request| Blacklist.retrieve_ips.include?(request.remote_ip) }
end
```

`matches?` 方法與 lambda 都接受 `request` 物件作為參數。

### 路由通配片段

路由通配是指定匹配參數的方法，比如：

```ruby
get 'photos/*other', to: 'photos#unknown'
```

這筆路由會匹配 `photos/12` 或 `/photos/long/path/to/12`，並將 `params[:other]` 設為 `"12"` 或 `"long/path/to/12"`。有星號前綴的片段稱之為“通配片段”。

通配片段可在路由的任何位置出現，譬如：

```ruby
get 'books/*section/:title', to: 'books#show'
```

會匹配 `books/some/section/last-words-a-memoir`，`params[:section]` 會設為 `"some/section"`，而 `params[:title]` 則是 `"last-words-a-memoir"`。

技術上來說，路由可有多個通配片段。匹配器會以直觀的方式來將參數賦值給片段，比如：

```ruby
get '*a/foo/*b', to: 'test#index'
```

會匹配 `zoo/woo/foo/bar/baz`，`params[:a]` 會設為 `'zoo/woo'`，而 `params[:b]` 則是 `'bar/baz'`。

NOTE: 若想請求 `"/foo/bar.json"`，`params[:pages]` 會設為 `"foo/bar"`，請求格式為 JSON。若想使用 3.0.x 的行為，可以傳一個 `format: false`：

```ruby
get '*pages', to: 'pages#show', format: false
```

NOTE: 若想要設定格式為必要參數，則可以傳 `format: true`：

```ruby
get '*pages', to: 'pages#show', format: true
```

### 轉址

可以使用 `redirect` 輔助方法將甲路徑轉到乙路徑：

```ruby
get '/stories', to: redirect('/articles')
```

轉址也可以重複使用匹配路由的動態片段：

```ruby
get '/stories/:name', to: redirect('/articles/%{name}')
```

`redirect` 也可以以區塊形式定義，接受 `path` 參數與 `request` 物件：

```ruby
get '/stories/:name', to: redirect { |path_params, req| "/articles/#{path_params[:name].pluralize}" }
get '/stories', to: redirect { |path_params, req| "/articles/#{req.subdomain}" }
```

Note: 轉址是 301 "Moved Permanently" 轉址。某些瀏覽器或代理伺服器會快取 301 轉址，導致舊的頁面無法存取。

以上所有的情況裡，若沒有提供主機（`http://www.example.com`），Rails 會從當下的請求裡取得。

### 路由到 Rack 應用程式

除了使用像是 `"articles#index"` 的字串（會交給 `ArticlesController` 的 `index` 動作處理），還可以指定任何 [Rack 應用程式](/rails_on_rack.html) 作為 Endpoint：

```ruby
match '/application.js', to: Sprockets, via: :all
```

只要 `Sprockets` 有回應 `call`，並回傳 `[status, headers, body]`，則路由器便不管這是一個 Rack 應用程式，還是單純一個動作。這是個應用 `via: :all` 的適當場景，因為希望 Rack 應用程式自己處理所有的 HTTP 動詞。

NOTE: 針對比較好奇的朋友，`"articles#index` 其實會展開成 `ArticlesController.action(:index)`，會回傳一個合法的 Rack 應用程式。

### 使用 `root`

可以用 `root` 指定 Rails 要把 `"/"` 路由到那裡：

```ruby
root to: 'pages#main'
root 'pages#main' # 上例的縮寫
```

`root` 路由應放在 `config/routes.rb` 的最上方，因為這是最重要的路由，應該第一個匹配。

NOTE: `root` 路由只處理對應動作的 `GET` 請求。

`root` 也可以在命名空間或是作用域裡使用：

```ruby
namespace :admin do
  root to: "admin#index"
end

root to: "home#index"
```

### Unicode 字元的路由

路由中可以直接指定 Unicode 字元：

```ruby
get 'こんにちは', to: 'welcome#index'
```

客製化資源式路由
------------------------------

`resources :articles` 產生的預設路由與輔助方法通常可以滿足多數需求，但有時可能想在某種程度上進行客製化。Rails 允許資源式輔助方法的通用部分做客製化。

### 指定使用的 Controller

`:controller` 選項可明確指定資源要使用的 Controller：

```ruby
resources :photos, controller: 'images'
```

會識別出以 `/photos` 開頭的請求，交給 `Images` Controller 處理：

| HTTP Verb | Path             | Controller#Action | Named Helper         |
| --------- | ---------------- | ----------------- | -------------------- |
| GET       | /photos          | images#index      | photos_path          |
| GET       | /photos/new      | images#new        | new_photo_path       |
| POST      | /photos          | images#create     | photos_path          |
| GET       | /photos/:id      | images#show       | photo_path(:id)      |
| GET       | /photos/:id/edit | images#edit       | edit_photo_path(:id) |
| PATCH/PUT | /photos/:id      | images#update     | photo_path(:id)      |
| DELETE    | /photos/:id      | images#destroy    | photo_path(:id)      |

NOTE: 產生路徑的輔助方法保持不變 `photos_path`、`new_photo_path`。

具有命名空間的 Controller，指定時使用和目錄一樣的表示法即可：

```ruby
resources :user_permissions, controller: 'admin/user_permissions'
```

會把路由交給 `Admin::UserPermissions` 處理。

NOTE: 只支援目錄表示法。使用 Ruby 的常數表示法（如：`controller: "Admin::UserPermissions"`）會導致路由問題，並觸發警告。

### 指定約束條件

可用 `:constraints` 選項來對 `id` 指定格式，譬如：

```ruby
resources :photos, constraints: { id: /[A-Z][A-Z][0-9]+/ }
```

這條宣告限制 `:id` 參數需符合指定的正規表示法。故這個情況裡，路由器不會匹配 `/photos/1`，而是會匹配 `/photos/RR27`。

可以將約束條件應用至多條路由，使用以下的區塊形式：

```ruby
constraints(id: /[A-Z][A-Z][0-9]+/) do
  resources :photos
  resources :accounts
end
```

NOTE: 當然這裡也可以使用非資源式路由的進階約束條件。

TIP: `:id` 預設不接受 `.` ── 這是因為 `.` 是格式化路由的分隔符。如需要在 `:id` 裡使用 `.`，用約束條件來處理 ── 例如，`id: /[^\/]+/` 允許斜線以外的所有字元。

### 覆寫具名輔助方法

`:as` 選項可以覆寫具名輔助方法的名稱。比如：

```ruby
resources :photos, as: 'images'
```

will recognize incoming paths beginning with `/photos` and route the requests to `PhotosController`, but use the value of the :as option to name the helpers.

| HTTP Verb | Path             | Controller#Action | Named Helper         |
| --------- | ---------------- | ----------------- | -------------------- |
| GET       | /photos          | photos#index      | images_path          |
| GET       | /photos/new      | photos#new        | new_image_path       |
| POST      | /photos          | photos#create     | images_path          |
| GET       | /photos/:id      | photos#show       | image_path(:id)      |
| GET       | /photos/:id/edit | photos#edit       | edit_image_path(:id) |
| PATCH/PUT | /photos/:id      | photos#update     | image_path(:id)      |
| DELETE    | /photos/:id      | photos#destroy    | image_path(:id)      |

### 覆寫 `new` 與 `edit` 片段

`:path_names` 選項可以覆寫自動在路徑裡產生的 `new` 與 `edit` 片段：

```ruby
resources :photos, path_names: { new: 'make', edit: 'change' }
```

路由路徑變更為：

```
/photos/make
/photos/1/change
```

NOTE: 實際的動作名稱並沒有改變。這兩個路徑仍路由到 `new` and `edit` 動作。

TIP: 若發現一直使用 `:path_names` 的話，考慮使用 `scope`。

```ruby
scope path_names: { new: 'make' } do
  # rest of your routes
end
```

### 給具名輔助方法加前綴

`:as` 選項可以給具名輔助方法加上前綴。使用此選項用來避免路由之間的命名衝突，例如：

```ruby
scope 'admin' do
  resources :photos, as: 'admin_photos'
end

resources :photos
```

會產生像是 `admin_photos_path`、`new_admin_photo_path` 等路由輔助方法。

要前綴一組路由輔助方法，使用 `scope` 與 `:as` 選項：

```ruby
scope 'admin', as: 'admin' do
  resources :photos, :accounts
end

resources :photos, :accounts
```

這會產生像是 `admin_photos_path` 以及 `admin_accounts_path` 輔助方法，分別對應到 `/admin/photos` 以及 `/admin/accounts`。

NOTE: `namespace` 作用域會自動新增 `:as`、`:module` 以及 `:path` 前綴。

也可以使用具名參數給路由加上前綴：

```ruby
scope ':username' do
  resources :articles
end
```

這會產生像是 `/bob/articles/1` 的路由，並允許在 Controller、View 以及輔助方法使用 `params[:username]` 來存取路徑傳入的 `username`。

### 限制建立出來的路由

Rails 預設會為以資源式風格宣告的路由的七個動作（index、show、new、create、edit、update 以及 destroy）建立路由。可用 `:only` 以及 `:except` 選項來調整這個行為。`:only` 選項告訴 Rails 只需要產生那些路由就好：

```ruby
resources :photos, only: [:index, :show]
```

`/photos` 收到 GET 請求會正常工作，但 POST 請求（通常會路由到 `:create` 動作）則會失敗。

The `:except` 選項指定不要建立的路由：

```ruby
resources :photos, except: :destroy
```

這個情況 Rails 會建立出除了 `:destory` （發送 `DELETE` 請求到 `/photos/:id`）之外所有的路由。

TIP: 如應用程式有許多 RESTful 風格的路由，使用 `:only` 與 `:except` 選項來產生需要的路由。這樣可以減少記憶體的使用量，並加速路由過程。

### 翻譯路徑

使用 `scope`，可以修改由 `resources` 產生的路徑名稱：

```ruby
scope(path_names: { new: 'neu', edit: 'bearbeiten' }) do
  resources :categories, path: 'kategorien'
end
```

產生的路由：

| HTTP Verb | Path                       | Controller#Action  | Named Helper            |
| --------- | -------------------------- | ------------------ | ----------------------- |
| GET       | /kategorien                | categories#index   | categories_path         |
| GET       | /kategorien/neu            | categories#new     | new_category_path       |
| POST      | /kategorien                | categories#create  | categories_path         |
| GET       | /kategorien/:id            | categories#show    | category_path(:id)      |
| GET       | /kategorien/:id/bearbeiten | categories#edit    | edit_category_path(:id) |
| PATCH/PUT | /kategorien/:id            | categories#update  | category_path(:id)      |
| DELETE    | /kategorien/:id            | categories#destroy | category_path(:id)      |

### 覆寫單數形式

若想定義某個資源的單數形式，給 `Inflector` 新增額外的規則：

```ruby
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'tooth', 'teeth'
end
```

### 在嵌套資源中使用 `:as` 選項

`:as` 選項覆寫在嵌套資源裡，自動產生的路由輔助方法，例如：

```ruby
resources :magazines do
  resources :ads, as: 'periodical_ads'
end
```

這會產生出像是：`edit_magazine_periodical_ad_path` 與 `magazine_periodical_ads_url` 等輔助方法。

### 覆寫具名路由參數

`:param` 選項可以覆寫辨識資源的變數，預設是 `:id`（[動態片段](#動態片段)的名稱）。這個變數是用來產生路由的。可以在 Controller 使用 `params[<:param>]` 傳入片段變數。

```ruby
resources :videos, param: :identifier
```

```
     videos GET  /videos(.:format)                  videos#index
            POST /videos(.:format)                  videos#create
 new_videos GET  /videos/new(.:format)              videos#new
edit_videos GET  /videos/:identifier/edit(.:format) videos#edit
```

```ruby
Video.find_by(identifier: params[:identifier])
```

檢查與測試路由
-----------------------------

Rails 有提供用來檢查與測試路由的工具。

### 列出現有的路由

要獲得應用程式完整可用的路由列表，在開發環境下啟動伺服器，瀏覽 `http://localhost:3000/rails/info/routes`。也可以在終端機裡執行 `rake routes` 命令。

以上兩種方法都會列出所有的路由，順序與 `config/routes.rb` 裡定義的一樣，每條路由的內容會有：

* 路由名稱（有的話）
* 使用的 HTTP 動詞（若不是回應所有動詞的路由）
* 匹配的 URL 模式。
* 路由的參數。

舉個例子，以下是某個 RESTful 路由的 `rake routes` 輸出的一小部分：

```
    users GET    /users(.:format)          users#index
          POST   /users(.:format)          users#create
 new_user GET    /users/new(.:format)      users#new
edit_user GET    /users/:id/edit(.:format) users#edit
```

可以使用環境變數 `CONTROLLER`，來限制僅列出特定 Controller 的路由：

```bash
$ CONTROLLER=users rake routes
```

TIP: 若將終端機視窗拉寬到無斷行，會發現 `rake routes` 輸出的可讀性更高。

### 測試路由

路由和其它部分的程式一樣，也需要測試。Rails 提供三個[內建的斷言方法](http://api.rubyonrails.org/classes/ActionDispatch/Assertions/RoutingAssertions.html)，專門為簡化路由測試而設計：

* `assert_generates`
* `assert_recognizes`
* `assert_routing`

#### `assert_generates` 斷言

`assert_generates` 檢測給定選項產生出來的預設路由或自訂路由是否正確：

```ruby
assert_generates '/photos/1', { controller: 'photos', action: 'show', id: '1' }
assert_generates '/about', controller: 'pages', action: 'about'
```

#### `assert_recognizes` 斷言

`assert_recognizes` 與 `assert_generates` 相反。檢測給定的路徑是否能識別出來，並路由到正確的位置。比如：

```ruby
assert_recognizes({ controller: 'photos', action: 'show', id: '1' }, '/photos/1')
```

可用 `:method` 參數來指定 HTTP 動詞：

```ruby
assert_recognizes({ controller: 'photos', action: 'create' }, { path: 'photos', method: :post })
```

#### `assert_routing` 斷言

`assert_routing` 斷言雙向檢查路由：測試路徑產生的選項對不對，以及選項產生出來的路徑是否正確。因此，結合了 `assert_generates` 與 `assert_recognizes` 的功能：

```ruby
assert_routing({ path: 'photos', method: :post }, { controller: 'photos', action: 'create' })
```
