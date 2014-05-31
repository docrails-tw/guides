Ruby on Rails 4.2 Release Notes
===============================

Highlights in Rails 4.2:

* ...
* ...

These release notes cover only the major changes. To know about various bug
fixes and changes, please refer to the change logs or check out the
[list of commits](https://github.com/rails/rails/commits/master) in the main
Rails repository on GitHub.

--------------------------------------------------------------------------------

Upgrading to Rails 4.2
----------------------

If you're upgrading an existing application, it's a great idea to have good test
coverage before going in. You should also first upgrade to Rails 4.1 in case you
haven't and make sure your application still runs as expected before attempting
an update to Rails 4.2. A list of things to watch out for when upgrading is
available in the
[Upgrading Ruby on Rails](upgrading_ruby_on_rails.html#upgrading-from-rails-4-1-to-rails-4-2)
guide.


Major Features
--------------



Railties
--------

Please refer to the
[Changelog](https://github.com/rails/rails/blob/4-2-stable/railties/CHANGELOG.md)
for detailed changes.

### Removals

* The `rails application` command has been removed without replacement.
  ([Pull Request](https://github.com/rails/rails/pull/11616))

### Notable changes

* Introduced `bin/setup` script to bootstrap an application.
  ([Pull Request](https://github.com/rails/rails/pull/15189))

* Changed default value for `config.assets.digest` to `true` in development.
  ([Pull Request](https://github.com/rails/rails/pull/15155))

* Introduced an API to register new extensions for `rake notes`.
  ([Pull Request](https://github.com/rails/rails/pull/14379))

* Introduced `Rails.gem_version` as a convenience method to return `Gem::Version.new(Rails.version)`.
  ([Pull Request](https://github.com/rails/rails/pull/14101))


Action Pack
-----------

Please refer to the
[Changelog](https://github.com/rails/rails/blob/4-2-stable/actionpack/CHANGELOG.md)
for detailed changes.

### Deprecations

* "Soft deprecated" the `*_filter` family methods in favor of the `*_action`
  family methods:

      after_filter          => after_action
      append_after_filter   => append_after_action
      append_around_filter  => append_around_action
      append_before_filter  => append_before_action
      around_filter         => around_action
      before_filter         => before_action
      prepend_after_filter  => prepend_after_action
      prepend_around_filter => prepend_around_action
      prepend_before_filter => prepend_before_action
      skip_after_filter     => skip_after_action
      skip_around_filter    => skip_around_action
      skip_before_filter    => skip_before_action
      skip_filter           => skip_action_callback

  If your application is depending on these methods, you should use the
  replacement `*_action` methods instead.
  ([Commit](https://github.com/rails/rails/commit/6c5f43bab8206747a8591435b2aa0ff7051ad3de))

### Notable changes

* Added HTTP method `MKCALENDAR` from RFC-4791
  ([Pull Request](https://github.com/rails/rails/pull/15121))

* `*_fragment.action_controller` notifications now include the controller and action name
  in the payload.
  ([Pull Request](https://github.com/rails/rails/pull/14137))

* Segments that are passed into URL helpers are now automatically escaped.
  ([Commit](https://github.com/rails/rails/commit/5460591f0226a9d248b7b4f89186bd5553e7768f))

* Improved Routing Error page with fuzzy matching for route search.
  ([Pull Request](https://github.com/rails/rails/pull/14619))

* Added option to disable logging of CSRF failures.
  ([Pull Request](https://github.com/rails/rails/pull/14280))


Action Mailer
-------------

Please refer to the
[Changelog](https://github.com/rails/rails/blob/4-2-stable/actionmailer/CHANGELOG.md)
for detailed changes.

### Notable changes

* ...
* ...


Active Record
-------------

Please refer to the
[Changelog](https://github.com/rails/rails/blob/4-2-stable/activerecord/CHANGELOG.md)
for detailed changes.

### Notable changes

* ...
* ...


Active Model
------------

Please refer to the
[Changelog](https://github.com/rails/rails/blob/4-2-stable/activemodel/CHANGELOG.md)
for detailed changes.

### Notable changes

* ...
* ...


Active Support
--------------

Please refer to the
[Changelog](https://github.com/rails/rails/blob/4-2-stable/activesupport/CHANGELOG.md)
for detailed changes.

### Removals

* Removed deprecated `Numeric#ago`, `Numeric#until`, `Numeric#since`,
  `Numeric#from_now`. ([Commit](https://github.com/rails/rails/commit/f1eddea1e3f6faf93581c43651348f48b2b7d8bb))

* Removed deprecated string based terminators for `ActiveSupport::Callbacks`.
  ([Pull Request](https://github.com/rails/rails/pull/15100))

### Deprecations

* Deprecated `Class#superclass_delegating_accessor`, use `Class#class_attribute`
  instead. ([Pull Request](https://github.com/rails/rails/pull/14271))

* Deprecated `ActiveSupport::SafeBuffer#prepend!` as `ActiveSupport::SafeBuffer#prepend`
  now performs the same function. ([Pull Request](https://github.com/rails/rails/pull/14529))

### Notable changes

* The `humanize` inflector helper now strips any leading underscores.
  ([Commit](https://github.com/rails/rails/commit/daaa21bc7d20f2e4ff451637423a25ff2d5e75c7))

* Added `SecureRandom::uuid_v3` and `SecureRandom::uuid_v5`.
  ([Pull Request](https://github.com/rails/rails/pull/12016))

* Introduce `Concern#class_methods` as an alternative to `module ClassMethods`,
  as well as `Kernel#concern` to avoid the `module Foo; extend ActiveSupport::Concern; end`
  boilerplate. ([Commit](https://github.com/rails/rails/commit/b16c36e688970df2f96f793a759365b248b582ad))

Credits
-------

See the
[full list of contributors to Rails](http://contributors.rubyonrails.org/) for
the many people who spent many hours making Rails, the stable and robust
framework it is. Kudos to all of them.