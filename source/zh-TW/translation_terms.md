翻譯術語
===================

參考了業界先進張文鈿（ihower）先生 [Rails 實戰聖經的翻譯術語表](http://ihower.tw/rails3/translation.html) 以及[藍一婷](https://twitter.com/etblue)小姐的[翻譯詞彙表](https://docs.google.com/spreadsheet/ccc?key=0AkNsS2a-Qx8ZdDJzTUlNeVlvRy1BYnZDUnRjZUpWWGc&hl=en#gid=0)。

更好的譯法，請不吝指教，感謝。

歡迎加入新術語。

-------

保留原文不譯
------------

* Model

* View

* Controller

* Cookie

* Session

* Token

token 通常是由英數字組成的字串，做身分識別之用，如：

OAuth 的 Access Token。

* URL

通常是翻譯成網址。

* Web

翻譯術語
------------

A
------

* Accessor 存取器

* Action 動作

* Anchor 錨點

* Authentication 認證

* Auxiliary Methods 輔助方法

使用者認證。

* Adapter 連接器

用來連接資料庫的“連接器”，比如 Active Record 以相同的 API，分別實作了 SQLite、PostgreSQL、MySQL 等“連接器”，用來連接資料庫。

* Application 應用程式

* Association 關聯

* Association Proxy 關聯代理

* Attribute 屬性

Model 的屬性、HTML 的屬性。

B
------

* Bound Parameters 綁定參數

C
------

* Callback 回呼

* Cache 快取

* Class 類別

Ruby 的 `Class`

* CamelCase 駝峰形式

* Code 程式碼

* Collection Action 集合動作

* Collection Route 集合路由

* Column 欄位

資料庫的欄位。

* Commit 提交

版本管理世界的用詞。`git commit`。

* Conditional 條件式

* Compile 編譯

* Computer 計算機

亦作電腦。

* Copy 複本

* Constructor 建構子

D
------

* Database 資料庫

* Database Schema 資料庫綱要

通常指的是 Rails `db/schema.rb` 檔案。有時也有資料庫結構的意思。

* DDL Transaction DDL 交易

[Transactional DDL in PostgreSQL: A Competitive Analysis - PostgreSQL wiki](https://wiki.postgresql.org/wiki/Transactional_DDL_in_PostgreSQL:_A_Competitive_Analysis)

* Debug 除錯

* Drop 刪除

刪除整個資料庫、刪除整張資料表。

* Dynamic Segments 動態片段

E
------

* exception 異常

F
------

* Flash 提示訊息

* Flash Message 提示訊息

* Foreign Key 外鍵

* Foreign Key Constraint 外鍵約束

資料庫特有的功能之一。

* Form 表單

* Form Helpers 表單輔助方法

* Form Builder 表單構造器

* File 檔案

* Finder Methods 查詢方法

指得是 Active Record 所提供的查詢方法，如 `find`、`first、`find_by` 等。

* Filter 濾動器

    * Before Filter 前置濾動器
    * Around Filter 前後濾動器
    * After Filter 後置濾動器

* Filter Methods 濾動方法

通常電子學的世界裡，我們有濾波器，給定輸入（以波的形式），經濾波器處理，再輸出，得名濾波器。但在 Rails 的世界裡，`before_filter` 總是用來過濾“動作”，或是在動作前執行程式。所以我用“濾動”這個詞。

G
------

* Generator 產生器

* Globbing 通配符號

H
------

* Hash 散列

* Handler 處理函數

JavaScript 給元素綁定的函數。

* Header 標頭

* Helpers 輔助方法

* Host 主機

I
------

* Index 索引

給資料庫欄位加上索引，提高檢索時的效率。

* Instance 實體

* Instance variable 實體變數

* Instantiate 實體化

指 `Class.new`。

* Interface 介面、接口

UI => 介面

API => 接口

* Integrity 完整性

* Iterate 迭代

J
------

* Join 連接

* Join Table 連接表

* Join Table 連接資料表

K
------

* Key 鍵

Hash 的鍵。`{ "foo" => "bar" }` Hash 有一鍵為 `"foo"`，對應的值為 `"bar"`。

L
------

* Layout 版型

* Library 函式庫

M
------

* Macro 宏

宏通常指的是透過一行宣告，可以給目標動態新增許多新的程式碼。用宏表示這種“神奇的”程式設計手法似乎比較好。

* Macro-style 宏風格的

* Migration 遷移

* Modifier 修飾符

* Module 模組

* Middleware 中間件

* Member action 成員動作

* Member route 成員路由

N
------

* Namespace 命名空間

* Named Helpers 具名輔助方法

* Nesting 嵌套的

* Nested 嵌套的

O
------

* Object 物件

* Option 選項

方法所接受的選項。

P
------

* Package 套件

* Partial 部份頁面

* Path 路徑

* Port 埠口

* Predicate 謂詞

謂詞，回傳真或假的條件式，比如 `Array#empty?`。

* Program (n.) 程式

* Program (v.) 編程

編寫程式，取編寫的編，程式的程來代表。亦作寫程式。

* Protocol 協定

Q
------

* Query 查詢

* Query String 查詢字串

URL 的一部分。後面以 `?` 定義的變數。

`http://server/program/path/?query_string`

R
------

* Raise 拋出

拋出異常、拋出錯誤。

* Rake Task Rake 任務

* Record 記錄

資料庫裡的紀錄。

* Record Identification 記錄自動識別技術

指的是 `form_for @article` 能自動分辨出現在是 `edit`、還是 `new`。

* Redirection

轉址。

* Referential Integrity 參照完整性

* Repository 原碼庫。

Repository 在生活中有倉庫的意思，在版本控制的世界裡，通常我們將原始碼提交到 Repository，叫做原碼庫。

* Request 請求

為 HTTP 協定裡的專有名詞，HTTP Request。

* Resource routing 資源式路由

* Resource 資源

* Response 響應

為 HTTP 協定裡的專有名詞，HTTP Response。

* Rollback 回滾

資料庫恢復至以前的狀態。

* Router 路由器

指得是以 [Journey](https://github.com/rails/journey) 所實作的路由器。

S
------

* Scaffold 鷹架

蓋房子的搭的鷹架，這裡指的是 Rails 產生器的一個子命令： `rails generate scaffold`。

目前官方已經不推薦使用鷹架，自己建立文件才能更好的掌握 Rails（尤其是新手）。

* Scalar Value 純量值

* Scalar Types 純量類型

* Seed Data 種子資料

資料庫的初始資料，通常寫在 `db/seeds.rb` 檔案裡。

* Segment 片段

* Segment Constraints 片段約束

* Self-Join 自連接

* Serialize 序列化

* Serialization 序列化

* Shallow Nesting 淺層嵌套

* Singular resource 單數資源

* Static Segments 靜態片段

* Stored Procedure 儲存過程

在資料庫先寫好程式，供外部程式呼叫。

http://zh.wikipedia.org/wiki/%E5%AD%98%E5%82%A8%E7%A8%8B%E5%BA%8F

* Stream 串流

* Streaming 串流

* Strong Parameters 核可參數

T
------

* Table 資料表

* Task 任務

Rake 任務。

* Template 模版

* Transaction 交易

可逆的資料庫操作。

* Type 類型

* Trigger 觸發器

資料庫特有的功能之一。

U
------


V
------

* Vanilla JavaScript 純 JavaScript

W
------

* Web Service Web 服務

* Wildcard 通配符號

X
------


Y
------


Z
------
