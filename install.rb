require 'fileutils'
require 'pathname'
require 'thor'

has_guides_repo  = false
base_path_change = false

def clone_all!
  clone_rails!
  clone_guides!
  clone_rails_guides_github_pages!
end

def clone_rails!
  return if File.exist?((BASE_PATH + 'rails').expand_path)
  `git clone git@github.com:rails/rails.git`
end

def clone_guides!
  if File.exist?((BASE_PATH + 'guides').expand_path)
    has_guides_repo = true
  else
    `git clone git@github.com:docrails-tw/guides.git`
  end
end

def clone_rails_guides_github_pages!
  return if File.exist?((BASE_PATH + 'docrails-tw.github.io').expand_path)
  `git clone https://github.com/docrails-tw/docrails-tw.github.io`
end

def clone_by_option!(option)
  option_map = {
    '1' => 'rails/rails',
    '2' => 'docrails-tw/guides',
    '3' => 'docrails-tw/docrails-tw.github.io',
    '4' => 'all'
  }

  case option_map[option]
  when 'rails/rails' then clone_rails!
  when 'docrails-tw/guides' then clone_guides!
  when 'docrails-tw/docrails-tw.github.io' then clone_rails_guides_github_pages!
  when 'all' then clone_all!
  else clone_all!
  end
end

# ========================================

basic_thor_shell = Thor::Shell::Basic.new

if basic_thor_shell.yes? 'Do you want to change default base path? (~/doc/rails-guides-translation) (y/N)'
  basic_thor_shell.say 'this is the location to clone rails/rails, docrails-tw/guides, docrails-tw/docrails-tw.github.io'
  new_base_path = basic_thor_shell.ask("Where would you like to store those repositories?\n", path: true)
  if new_base_path.empty?
    BASE_PATH = Pathname('./')
  else
    BASE_PATH = Pathname(new_base_path)
  end
  base_path_change = true
else
  BASE_PATH = Pathname('~/doc/rails-guides-translation')
end

unless File.exist? BASE_PATH
  basic_thor_shell.say "Create directories #{BASE_PATH}"
  FileUtils.mkdir_p(BASE_PATH.expand_path)
end

clone_option = basic_thor_shell.ask(<<CLONE_MSG)
  1. rails/rails
  2. docrails-tw/guides
  3. docrails-tw/docrails-tw.github.io
  4. ALL
  or you could use 1+2, 1+3...etc.
CLONE_MSG

print "Parsing Cloning options...\r"
$stdout.flush
sleep 0.5
print "Parsing Cloning options......\r"
$stdout.flush
sleep 0.5
print "Parsing Cloning options.........OK!\n"
FileUtils.cd(BASE_PATH.expand_path) do
  parsed_option = clone_option.scan(/\d+/)
  if parsed_option.empty?
    clone_by_option!(clone_option)
  else # 1+2 or 1,2 or ...
    parsed_option.each do |opt|
      clone_by_option!(opt)
    end
  end
end

# Replace Rakefile BASE_PATH
if base_path_change && has_guides_repo
  rakefile_path = (BASE_PATH + 'guides' + 'Rakefile').expand_path
  IO.write(rakefile_path, File.open(rakefile_path) do |f|
      f.read.gsub!("BASE_PATH = '~/doc/rails-guides-translations'", "BASE_PATH = #{BASE_PATH}")
    end
  )
end

basic_thor_shell.say "You need to clone the docrails-tw/guides under #{BASE_PATH}, then change the BASE_PATH in /guides/Rakefile" if base_path_change && !has_guides_repo

puts 'Installation Complete!'