# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

require 'capybara/rails'
require 'database_cleaner'
require 'minitest/rails' # must go after rails/test_help or fixtures won't load
require 'webmock/minitest'

Dir[Rails.root.join('test/support/**/*.rb')].sort.each { |f| require f }

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
  include Capybara::DSL
  include DatabaseCleanerSupport
  include Rails.application.routes.url_helpers
  include Warden::Test::Helpers

  ActiveRecord::FixtureSet.create_fixtures('test/fixtures', %w[urls users])

  USERNAME = 'username'

  after do
    Warden.test_reset!
  end

  def authorize
    visit '/'
    page.driver.browser.authorize(USERNAME, 'password')
  end

  def sign_in_as_user(options={}, &block)
    user = User.find_or_create_by(username: options[:username])

    visit new_user_session_path
    fill_in 'user_username', with: options[:username] || 'normal'
    fill_in 'user_password', with: options[:password] || '12345678'
    check 'user_remember me' if options[:remember_me] == true
    yield if block_given?
    click_on 'Log in'

    user
  end
end
