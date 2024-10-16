# frozen_string_literal: true

Rails.application.config.generators do |g|
  # Generate "users_factory.rb" instead of "users.rb"
  g.factory_bot suffix: "factory"
  # Disable generators we don't need.
  g.javascripts false
  g.stylesheets false
  g.routing_specs false
  g.view_specs false
end
