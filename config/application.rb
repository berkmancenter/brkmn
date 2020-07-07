require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Brkmn
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths << File.join(Rails.root, 'lib')
    config.eager_load_paths << File.join(Rails.root, 'lib')

    config.filter_parameters += [:password]
    config.assets.enabled = true

    # See config/development.rb.
    config.use_fakeauth = false
    config.action_controller.per_form_csrf_tokens = true
  end
end
