require 'fileutils'
require 'pathname'

# ========== Helpers ==========

def base_path_change?
  BASE_PATH == '~/docs/rails-guides-translation' ? false : true
end

def has_guides_repo?(base_path)
  File.directory?((BASE_PATH + 'guides').expand_path)
end

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
  return if File.exist?((BASE_PATH + 'guides').expand_path)
  `git clone git@github.com:docrails-tw/guides.git`
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

def yes? msg
  puts msg
  response = gets.chomp
  /yes|y/i.match(response).nil? ? false : true
end

def ask msg
  puts msg
  gets.chomp
end

# ========== End of Helpers ==========

if yes? 'Do you want to change default base path? (~/docs/rails-guides-translation) (y/N)'
  puts 'this is the location to clone rails/rails, docrails-tw/guides, docrails-tw/docrails-tw.github.io'
  new_base_path = ask("Where would you like to store those repositories?")
  if new_base_path.empty?
    BASE_PATH = Pathname('./')
  else
    BASE_PATH = Pathname(new_base_path)
  end
else
  BASE_PATH = Pathname('~/docs/rails-guides-translation')
end

unless File.exist? BASE_PATH
  puts "Create directories #{BASE_PATH}"
  FileUtils.mkdir_p(BASE_PATH.expand_path)
end

clone_option = ask(<<CLONE_MSG)
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
  multiple_options = clone_option.scan(/\d+/)
  if multiple_options.empty?
    clone_by_option!(clone_option)
  else # 1+2 or 1,2 or ...
    multiple_options.each do |opt|
      clone_by_option!(opt)
    end
  end

  if base_path_change? && has_guides_repo?(BASE_PATH)
    puts 'cp guides/BASE_PATH.example guides/BASE_PATH'
    `cp guides/BASE_PATH.example guides/BASE_PATH`

    puts 'Writing new base path.....'
    IO.write((BASE_PATH + 'guides' + 'BASE_PATH').expand_path, BASE_PATH.to_s)
  end
end

puts 'Installation Complete!'
puts "Your repos are at #{BASE_PATH} ^_^..."
