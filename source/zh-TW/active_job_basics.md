Active Job 基礎
===============

本篇提供所有建立任務、將任務加入排程，執行背景任務的所有知識。

讀完本篇，您將了解：

* 如何新建任務。
* 如何把任務加入排程。
* 如何在背景執行任務。
* 如何異步發送信件。

--------------------------------------------------------------------------------

簡介
----

Active Job 是用來宣告任務，並把任務放到多種佇列後台執行的框架。這些任務可以是平常的系統定時清理、收費方式改變通知、或是定時寄送郵件等任務。任何可以細分的工作與同步執行的事情都可以用 Active Job 來做。

Active Job 存在目的
-------------------

主要確保 Rails 應用程式有個一致的背景任務框架，不做背景任務，要即時執行也可以。接著便可以有基於 Active Job 打造的功能、Gem 誕生，而無需擔心各種佇列後台，像是 Delayed Job 和 Resque 之間的 API 差異。選擇佇列後台變成一種運維方面的考量，而切換後台也無需修改任務本身的實作。

新建任務
-------

本節提供建立任務，將任務加入排程的詳細教學。

### 建立任務

Active Job 提供了 Rails 產生器來建立任務。以下會在 `app/jobs` 建立一件新任務：

```bash
$ bin/rails generate job guests_cleanup
create  app/jobs/guests_cleanup_job.rb
```

也可以建立跑在特定佇列上的任務：

```bash
$ bin/rails generate job guests_cleanup --queue urgent
create  app/jobs/guests_cleanup_job.rb
```

可以看出來，建立任務就和使用其他的 Rails 產生器一樣簡單。

若不想使用產生器，也可以自己在 `app/jobs` 下建立檔案，只要確保任務是繼承自 `ActiveJob::Base` 的類別即可。

以下是任務的程式範例：

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :default

  def perform(*args)
    # Do something later
  end
end
```

### 任務排程

將任務加入排程：

```ruby
MyJob.perform_later record  # Enqueue a job to be performed as soon the queueing system is free.
```

```ruby
MyJob.set(wait_until: Date.tomorrow.noon).perform_later(record)  # Enqueue a job to be performed tomorrow at noon.
```

```ruby
MyJob.set(wait: 1.week).perform_later(record) # Enqueue a job to be performed 1 week from now.
```

就這麼簡單！

執行任務
-------------

若無設定連接器，任務會即刻執行。

### 後台

Active Job 針對提供以下佇列後台的連接器：

* [Backburner](https://github.com/nesquena/backburner)
* [Delayed Job](https://github.com/collectiveidea/delayed_job)
* [Qu](https://github.com/bkeepers/qu)
* [Que](https://github.com/chanks/que)
* [QueueClassic 2.x](https://github.com/ryandotsmith/queue_classic/tree/v2.2.3)
* [Resque 1.x](https://github.com/resque/resque/tree/1-x-stable)
* [Sidekiq](https://github.com/mperham/sidekiq)
* [Sneakers](https://github.com/jondot/sneakers)
* [Sucker Punch](https://github.com/brandonhilkert/sucker_punch)

#### 各後台功能特色

|                       | Async | Queues | Delayed   | Priorities | Timeout | Retries |
|-----------------------|-------|--------|-----------|------------|---------|---------|
| **Backburner**        | Yes   | Yes    | Yes       | Yes        | Job     | Global  |
| **Delayed Job**       | Yes   | Yes    | Yes       | Job        | Global  | Global  |
| **Que**               | Yes   | Yes    | Yes       | Job        | No      | Job     |
| **Queue Classic**     | Yes   | Yes    | No*       | No         | No      | No      |
| **Resque**            | Yes   | Yes    | Yes (Gem) | Queue      | Global  | Yes     |
| **Sidekiq**           | Yes   | Yes    | Yes       | Queue      | No      | Job     |
| **Sneakers**          | Yes   | Yes    | No        | Queue      | Queue   | No      |
| **Sucker Punch**      | Yes   | Yes    | No        | No         | No      | No      |
| **Active Job Inline** | No    | Yes    | N/A       | N/A        | N/A     | N/A     |
| **Active Job**        | Yes   | Yes    | Yes       | No         | No      | No      |

NOTE:
* Queue Classic 不支援任務排程。但可以自己用 queue_classic-later Gem 來實作，詳細請參考 `ActiveJob::QueueAdapters::QueueClassicAdapter` 的文件。

### 切換後台

切換後台的連接器非常簡單：

```ruby
# be sure to have the adapter gem in your Gemfile and follow the adapter specific
# installation and deployment instructions
YourApp::Application.config.active_job.queue_adapter = :sidekiq
```

佇列
------

多數的連接器都支持多種佇列。用 Active Job 可以將任務放到特定的佇列裡執行：

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :low_priority
  #....
end
```

也可給所有任務加上佇列名前綴，加入 `config.active_job.queue_name_prefix` 設定到 `application.rb` 即可：

```ruby
# config/application.rb
module YourApp
  class Application < Rails::Application
    config.active_job.queue_name_prefix = Rails.env
  end
end

# app/jobs/guests_cleanup.rb
class GuestsCleanupJob < ActiveJob::Base
  queue_as :low_priority
  #....
end

# Now your job will run on queue production_low_priority on your
# production environment and on beta_low_priority on your beta
# environment
```

若需要更細緻的控制任務的執行，可以傳 `:queue` 給 `#set` 方法。

```ruby
MyJob.set(queue: :another_queue).perform_later(record)
```

要在任務層級控制佇列，可以傳一個區塊給 `queue_as`。區塊會在任務的上下文裡執行（也就是拿的到 `self.arguments），記得要回傳佇列的名稱：

```ruby
class ProcessVideoJob < ActiveJob::Base
  queue_as do
    video = self.arguments.first
    if video.owner.premium?
      :premium_videojobs
    else
      :videojobs
    end
  end

  def perform(video)
    # do process video
  end
end

ProcessVideoJob.perform_later(Video.last)
```

NOTE: 確保後台程式知道佇列的名稱是什麼。某些後台可能需要明確指定佇列。

回呼
---------

Active Job 在任務生命週期裡的每個階段都有提供 hooks。回呼允許在任務生命週期裡觸發事件來執行程式邏輯。

### 可用的回呼

* `before_enqueue`
* `around_enqueue`
* `after_enqueue`
* `before_perform`
* `around_perform`
* `after_perform`

### 用法

```ruby
class GuestsCleanupJob < ActiveJob::Base
  queue_as :default

  before_enqueue do |job|
    # do something with the job instance
  end

  around_perform do |job, block|
    # do something before perform
    block.call
    # do something after perform
  end

  def perform
    # Do something later
  end
end
```

ActionMailer
------------

現代網路應用最常見的任務之一是在請求響應週期之外發送 Email，減去使用者等待的時間。Active Job
已與 Action Mailer 整合，異步寄送信件只需使用 `deliver_later` 即可：

```ruby
# If you want to send the email now use #deliver_now
UserMailer.welcome(@user).deliver_now

# If you want to send the email through Active Job use #deliver_later
UserMailer.welcome(@user).deliver_later
```

GlobalID
--------

Active Job 支持使用 GlobalID 作為參數。這使得任務可以傳入 Active Record 物件，而不只是需要額外處理的類別名稱或 ID。使用類別和 ID 的任務看起來會像是：

```ruby
class TrashableCleanupJob
  def perform(trashable_class, trashable_id, depth)
    trashable = trashable_class.constantize.find(trashable_id)
    trashable.cleanup(depth)
  end
end
```

可以傳入 Active Record 物件來簡化：

```ruby
class TrashableCleanupJob
  def perform(trashable, depth)
    trashable.cleanup(depth)
  end
end
```

以上對任何混入 `ActiveModel::GlobalIdentification` 的類都有效，Active Model 的類別預設皆有混入 `ActiveModel::GlobalIdentification`。

Exceptions
----------

Active Job 提供捕捉任務執行期間發生異常的方法：

```ruby

class GuestsCleanupJob < ActiveJob::Base
  queue_as :default

  rescue_from(ActiveRecord::RecordNotFound) do |exception|
   # do something with the exception
  end

  def perform
    # Do something later
  end
end
```
