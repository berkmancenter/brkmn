# frozen_string_literal: true

module ApiSpecHelpers
  def api_headers(secret)
    {"Authorization" => "Bearer #{secret}", "Accept" => "application/json"}
  end

  def json
    JSON.parse(response.body)
  end

  # Plaintext tokens shown on a page.
  def secrets_in(body)
    body.scan(/#{ApiToken::SECRET_PREFIX}[1-9A-HJ-NP-Za-km-z]{#{ApiToken::SECRET_LENGTH}}/o).uniq
  end
end

RSpec.configure do |config|
  config.include ApiSpecHelpers, type: :request
end
