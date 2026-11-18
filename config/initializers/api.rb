# frozen_string_literal: true

# Settings for the JSON API under /api/v1.
Rails.application.configure do
  # Requests allowed per token in each window of API_RATE_LIMIT_PERIOD seconds.
  # The counters live in Rails.cache, so use a cache store shared by all app
  # processes (for example memcached or Redis) when running more than one host.
  config.x.api.rate_limit = Integer(ENV.fetch("API_RATE_LIMIT", 300))
  config.x.api.rate_limit_period = Integer(ENV.fetch("API_RATE_LIMIT_PERIOD", 300))

  # Comma-separated origins allowed to call the API from browser JavaScript.
  # The API authenticates with bearer tokens only (no cookies), so allowing any
  # origin can't be used to act on behalf of a signed-in user.
  config.x.api.cors_origins = ENV.fetch("API_CORS_ORIGINS", "*").split(",").map(&:strip).compact_blank
end

if Rails.application.config.x.api.cors_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*Rails.application.config.x.api.cors_origins)
      resource "/api/*",
        headers: %w[Authorization Content-Type Accept],
        methods: %i[get post put patch delete options head],
        expose: %w[Location Retry-After X-RateLimit-Limit X-RateLimit-Remaining X-RateLimit-Reset],
        credentials: false,
        max_age: 600
    end
  end
end
