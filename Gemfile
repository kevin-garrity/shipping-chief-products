source 'https://rubygems.org'
gem 'rails', '~> 3.2.11'
group :assets do
    gem 'sass-rails',   '~> 3.2.3'
      gem 'coffee-rails', '~> 3.2.1'
        gem 'uglifier', '>= 1.0.3'
end
gem 'jquery-rails'
gem "rails_apps_composer", :git => "git://github.com/lastobelus/rails_apps_composer.git", :branch => "devcloudcoder"
gem "thin", ">= 1.5.0"
gem "haml", ">= 3.1.7"
gem "email_spec", ">= 1.2.1", :group => :test
gem "cucumber-rails", ">= 1.3.0", :group => :test, :require => false
gem "database_cleaner", ">= 0.9.1", :group => :test
gem "launchy", ">= 2.1.2", :group => :test
gem "capybara", ">= 1.1.2", :group => :test
gem "compass-rails", ">= 1.0.3", :group => :assets
gem "zurb-foundation", ">= 3.2.5", :group => :assets
gem "simple_form", ">= 2.0.4"
gem "shopify_app"
gem "nokogiri"
gem "log4r"
gem "kaminari"
gem "pg"
gem "config_spartan"
gem "active_shipping"

# aus_controller_development branch added these
gem "activerecord-postgresql-adapter"
gem "httparty"
gem "rack-cors", :require => 'rack/cors'


# gem 'rufus-decision', git: 'https://github.com/lastobelus/rufus-decision.git', branch: 'short_circuit_matchers'
gem 'rufus-decision', :git => 'https://github.com/jmettraux/rufus-decision.git'
gem 'rudelo'

gem 'memcachier'
gem 'kgio' # improves performance of dalli
gem 'dalli' # memcached client

gem 'oj' # fast json parser, but mainly to make multi_json stfu

group :development do
  gem 'shopifydev', :git => "git://github.com/variousauthors/shopifydev.git", :branch => "GLI_commandline_suite"
  gem "css_canon", :git => "git://github.com/lastobelus/css_canon"
  gem "hpricot", ">= 0.8.6"
  gem "ruby_parser", ">= 2.3.1"
  gem "rspec-rails", ">= 2.11.0"
  gem "factory_girl_rails", ">= 4.1.0"
  gem "quiet_assets", ">= 1.0.1"
  gem 'pry-rails'
  gem 'haml-rails'
  gem 'guard'
  gem 'guard-rspec'
  gem 'zeus', ">= 0.13.4.pre2"
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
end

group :test do
  gem "rspec-rails", ">= 2.11.0"
  gem "factory_girl_rails", ">= 4.1.0"
  gem 'simplecov', require: false
end
