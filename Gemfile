# frozen_string_literal: true

source 'https://rubygems.org'

gem 'annotate'
gem 'bootsnap'
gem 'cancancan'
gem 'devise'
gem 'dotenv-rails'
gem 'haml'
gem 'jquery-rails'
gem 'net-ldap'
gem 'pg', '~> 0.12'
gem 'rails', '~> 6.0.0'
gem 'rack-mini-profiler', require: ['enable_rails_patches', 'rack-mini-profiler']
gem 'webpacker'
gem 'will_paginate'

group :assets do
  gem 'coffee-rails'
  gem 'sass-rails'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'
  gem 'uglifier'
end

group :development do
  gem 'listen'
  gem 'web-console'
end

group :development, :test do
  gem 'byebug'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'capybara'
  gem 'database_cleaner-active_record'
  gem 'minitest-around'
  gem 'minitest-rails'
  gem 'minitest-spec-context'
  gem 'simplecov', require: false
  gem 'webmock'
end
