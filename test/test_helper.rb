require 'simplecov'
SimpleCov.start

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'capybara/rails'
require 'database_cleaner'
require 'support/database_cleaner'
require 'minitest/rails' # must go after rails/test_help or fixtures won't load
require 'webmock'

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  include DatabaseCleanerSupport
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in
  # alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in
  # integration tests -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class IntegrationTest < MiniTest::Spec
  include ActiveSupport::Testing::SetupAndTeardown
  include Capybara::DSL
  include DatabaseCleanerSupport
  include Rails.application.routes.url_helpers

  def authorize
    visit '/'
    page.driver.browser.authorize('username', 'password')
  end
end
