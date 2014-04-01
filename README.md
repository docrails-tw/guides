# Rails 4 Official Guide: Traditional Chinese

[![Build Status](https://travis-ci.org/docrails-tw/guides.svg?branch=master)](https://travis-ci.org/docrails-tw/guides)

Translation is based on the master branch of [rails/rails](https://github.com/rails/rails).

## Setup

Add environment variable to your shell startup file.

```bash
GUIDES_LANGUAGE='zh-TW'
```

Otherwise you will have to pass in every time. Or make an alias.

Specify 3 repo's local path.

1. [rails/rails][rails]

For pulling latest English guides.

2. [docrails-tw/guides](https://github.com/docrails-tw/guides)

For working on translation.

3. [docrails-tw/docrails-tw.github.io](https://github.com/docrails-tw/docrails-tw.github.io)

For deploying.

By default they are under a `BASE_PATH = ~/doc/rails-guides-translation/`:

* `~/doc/rails-guides-translation/rails`

* `~/doc/rails-guides-translation/guides`

* `~/doc/rails-guides-translation/docrails-tw.github.io`, respectively.

```sh
mkdir ~/doc/rails-guides-translation
cd ~/doc/rails-guides-translation
git clone git@github.com:rails/rails.git
git clone git@github.com:docrails-tw/guides.git
git clone https://github.com/docrails-tw/docrails-tw.github.io
```

If you trust me, use this script:

curl:

```sh
ruby <(curl -L https://raw.githubusercontent.com/docrails-tw/guides/master/install.rb)
```

wget:

```sh
ruby <(wget --no-check-certificate https://raw.githubusercontent.com/docrails-tw/guides/master/install.rb)
```

If you use a different base location, you will need to change `BASE_PATH`'s location in `Rakefile`.

## Generate HTML

`rake guides:generate`

By default it will lazy generate, only generates what changes. pass `ALL=1` to make it generate everything. pass `GUIDES_LANGUAGE=zh-TW` to generate guides of `zh-TW` locale.

## Preview

```sh
open output/zh-TW/index.html
```

## Workflow

English guides live in `source/`.

Traditional Chinese guides live in `source/zh-TW`.

### 1. Start from scratch

**UPDATE BOTH** English and Traditional Chinese guides first. Then start to translate.

`rake guides:update_guide [name_of_the_guide]`

or you could update all guides at once:

`rake guides:update_guide` but **DO NOT** checks out the guides that you're not editing in version control.

### 2. Fix bugs in translation

**DO NOT** update the guide in English, just fix the translation error in `source/zh-TW`.

### 3. Update an obsolete translation

**UPDATE** the english guide first, see the English diff, adds up missing translation or updates.

## Before you make a Pull Request

Make sure Travis-CI is passing. Chinese text and English text has space between each other.

## Deploy

`rake guides:deploy`

## Something went wrong after deploy?

Do not worry. Just fix it and deploy again. Deploy often, deploy early.

## Contribute

Always fork and makes a topic branch!

## License

![CC-BY-SA](CC-BY-SA.png)

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 License](http://creativecommons.org/licenses/by-sa/3.0/).

The code are under [MIT license](http://opensource.org/licenses/MIT), copied with minor modifications from [rails/rails][rails].

[rails]: https://github.com/rails/rails