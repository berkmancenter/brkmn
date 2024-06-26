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

class IntegrationTest < Minitest::Spec
  include Capybara::DSL
  include DatabaseCleanerSupport
  include Rails.application.routes.url_helpers
  include Warden::Test::Helpers

  ActiveRecord::FixtureSet.create_fixtures('test/fixtures', %w[urls users])

  USERNAME = 'username'

  after do
    Warden.test_reset!
  end
end

Capybara.register_driver :no_redirects do |app|
  Capybara::RackTest::Driver.new app,
    redirect_limit: 0,
    follow_redirects: false,
    respect_data_method: true
end
