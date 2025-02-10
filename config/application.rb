# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Brkmn
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[puma/plugin templates assets tasks])

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.hosts ||= []
    config.hosts += ENV['ALLOWED_HOSTS'].split(',') if ENV['ALLOWED_HOSTS'].present?

    # Mailer settings
    config.default_sender = ENV['DEFAULT_SENDER'] || 'no-reply@example.com'
    config.return_path = ENV['RETURN_PATH'] || 'user@example.com'

    # Devise authentication type
    config.devise_auth_type = ENV['DEVISE_AUTH_TYPE'] || 'db'

    # devise_cas_authenticatable configuration
    if config.devise_auth_type == 'cas'
      require 'devise_cas_authenticatable'
      config.rack_cas.server_url = ENV['DEVISE_CAS_AUTH_URL'] || 'https://cas.example.com'
      config.rack_cas.service = ENV['DEVISE_CAS_AUTH_SERVICE_PATH'] || '/users/service'
    end
  end
end
