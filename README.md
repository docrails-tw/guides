# Edge Rails Guide Translation: Traditional Chinese [READ ONLINE](http://docrails-tw.github.io)

[![Build Status](https://travis-ci.org/docrails-tw/guides.svg?branch=master)](https://travis-ci.org/docrails-tw/guides)

Translation is based on the master branch of [rails/rails](https://github.com/rails/rails).

## Install

**DO THIS** If you want to work on Rails Guides Translation. If you just want to fix translation error. See [Fix Bugs in Translation](#fix-bugs-in-translation).

curl:

```sh
ruby -e "$(curl -sSL https://rawgithub.com/docrails-tw/guides/master/install.rb)"
```

wget:

```sh
ruby <(wget --no-check-certificate https://rawgithub.com/docrails-tw/guides/master/install.rb -O -)
```

What does above script do?

Clone 3 repos under a same folder (it will gently ask you where you would like to put these repos).

* 1 - [rails/rails][rails]

  For pulling latest English guides.

* 2 - [docrails-tw/guides](https://github.com/docrails-tw/guides)

  For working on translation.

* 3 - [docrails-tw/docrails-tw.github.io](https://github.com/docrails-tw/docrails-tw.github.io)

  For deploying.

```sh
mkdir ~/docs/rails-guides-translations
cd ~/docs/rails-guides-translations
git clone git@github.com:rails/rails.git
git clone git@github.com:docrails-tw/guides.git
git clone https://github.com/docrails-tw/docrails-tw.github.io
cd guides
cp BASE_PATH.example BASE_PATH
```

If you use a different base location, you will need to change the location in `BASE_PATH` file. Defaults to `~/docs/rails-guides-translations`

### Fix bugs in translation

Clone this repo, use a topic branch. Fix the translation error in `source/zh-TW`, then send a Pull Request. Or open an issue then someone may fix it.

If the error is not a translation error and latest guide: http://edgeguides.rubyonrails.org haven't fixed it. Then you could clone the `rails/rails` repo. Fix it then send a Pull Request to `rails/rails`. Make sure you've read the [Contributing to the Rails Documentation](http://edgeguides.rubyonrails.org/contributing_to_ruby_on_rails.html#contributing-to-the-rails-documentation) first. TL;DR. Word wrap to 80 chars and add `[ci skip]` in commit message for documentation changes.

## Workflow for Translator

**YOU NEED TO RUN THE INSTALL SCRIPT FIRST**.

After installation, now you have `rails`, `guides`, `docrails-tw.github.io` repos. `rails` is to get the latest source documents. `docrails-tw.github.io` is for hosting static html & css. `guides` is where you work on translation.

English guides live in `guides/source/`.

Traditional Chinese guides live in `guides/source/zh-TW`.

### 1. Start a new Translation

**UPDATE BOTH** English and Traditional Chinese guides first. Then start to translate.

`rake guides:update_guide [name_of_the_guide]`

or you could update all guides at once:

`rake guides:update_guides` but **DO NOT** check out the guides that you're not editing in version control.

When your translation is finished, generate, preview locally then send a Pull Request.

### 2. Update an obsolete translation

**UPDATE** the english guide first, see the English diff, adds up missing translation or updates.

`rake guides:update_guide [name_of_the_guide]`

or you could update all guides at once:

`rake guides:update_guides` but **DO NOT** checks out the guides that you're not editing in version control.

When your translation is finished, generate, preview locally then send a Pull Request.

## Generate HTML

`rake guides:generate`

By default it will lazy generate, only generates what changes. pass `ALL=1` to make it generate everything. Pass `GUIDES_LANGUAGE=zh-TW` to generate guides of `zh-TW` locale. Pass `RAILS_VERSION` to specify latest commit sha-1 (defaults to `local`).

## Preview

After generation, just open it:

```sh
open output/zh-TW/index.html
```

## Aliases

Put in your startup file (`.bash_profile` or ...):

```bash
alias deploy_to_pages="rake guides:deploy"
alias gen="rake guides:generate GUIDES_LANGUAGE=zh-TW"
alias genall="rake guides:generate ALL=1 GUIDES_LANGUAGE=zh-TW"
alias update_guide="rake guides:update_guide"
alias update_all_guides="rake guides:update_guides"
```

## Before you make a Pull Request

Generate and preview on local. Make sure everything is okay. Chinese text and English text MUST has a space between each other.

### Travis-CI

Travis-CI will run this command:

```
GUIDES_LANGUAGE=zh-TW rake
```

Make sure no errors occur before you open a Pull Request :D.

## Deploy

When your Pull Request got merged on master. It's time to deploy!

`rake guides:deploy`

## Contribute

Always fork and makes a topic branch!

## License

![CC-BY-SA](CC-BY-SA.png)

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 License](http://creativecommons.org/licenses/by-sa/3.0/).

The code are under [MIT license](http://opensource.org/licenses/MIT), copied with minor modifications from [rails/rails][rails].

[rails]: https://github.com/rails/rails