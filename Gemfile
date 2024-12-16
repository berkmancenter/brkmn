# frozen_string_literal: true

source 'https://rubygems.org'

gem 'bootsnap', require: false
gem 'cancancan'
gem 'cssbundling-rails'
gem 'devise'
gem 'dotenv', '>= 3.0'
gem 'good_migrations'
gem 'importmap-rails'
gem 'jbuilder'
gem 'pg', '~> 1.1'
gem 'puma', '>= 5.0'
gem 'rack-canonical-host'
gem 'rails', '~> 7.2.1', '>= 7.2.1.1'
gem 'rqrcode'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]
gem 'will_paginate'

group :development, :test do
  gem 'brakeman', require: false
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'factory_bot_rails'
  gem 'sassc'
  gem 'rspec-rails'
end

group :development do
  gem 'annotate'
  gem 'bundler-audit', require: false
  gem 'erb_lint', require: false
  gem 'rack-mini-profiler'
  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', '>= 2.22.0', require: false
  gem 'tomo', '~> 1.18', require: false
  gem 'web-console'
end

group :test do
  gem 'capybara', require: false
  gem 'capybara-lockstep', require: false
  gem 'capybara-selenium'
  gem 'database_cleaner'
  gem 'faker'
  gem 'selenium-webdriver', require: false
  gem 'shoulda-matchers'
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock'
end

group :production do
  gem 'sidekiq', '~> 7.0'
end
