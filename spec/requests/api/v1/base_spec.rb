# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "API authentication, limits, and errors", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:secret) { ApiToken.generate_secret }
  let!(:token) { create(:api_token, :read_only, user: user, secret: secret, name: "CI") }

  describe "GET /api/v1/me" do
    it "returns the token's user and token details" do
      get api_v1_me_path, headers: api_headers(secret)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
      expect(json["user"]).to include("id" => user.id, "email" => user.email, "superadmin" => false)
      expect(json["token"]).to include(
        "id" => token.id, "name" => "CI", "prefix" => token.token_prefix, "access_level" => "read_only"
      )
      expect(response.body).not_to include(secret)
    end

    it "accepts the `Token token=` scheme as well" do
      get api_v1_me_path, headers: {"Authorization" => %(Token token="#{secret}")}

      expect(response).to have_http_status(:ok)
    end

    it "records when the token was last used" do
      expect do
        get api_v1_me_path, headers: api_headers(secret)
      end.to change { token.reload.last_used_at }.from(nil)
    end
  end

  describe "authentication failures" do
    it "asks for a bearer token when none is sent" do
      get api_v1_me_path

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to eq('Bearer realm="brkmn"')
      expect(json["error"]).to include("code" => "missing_token")
    end

    it "rejects an unknown token" do
      get api_v1_me_path, headers: api_headers(ApiToken.generate_secret)

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to include('error="invalid_token"')
      expect(json["error"]["code"]).to eq("invalid_token")
    end

    it "rejects a revoked token" do
      token.revoke!(by: user)

      get api_v1_me_path, headers: api_headers(secret)

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]["message"]).to eq("Invalid or revoked access token.")
    end

    it "rejects an expired token and says when it expired" do
      token.update!(expires_at: 1.minute.ago)

      get api_v1_me_path, headers: api_headers(secret)

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]["message"]).to include("expired")
    end

    it "doesn't accept tokens in the query string" do
      get api_v1_me_path(access_token: secret)

      expect(response).to have_http_status(:unauthorized)
    end

    it "ignores the website's session cookie" do
      sign_in(user)

      get api_v1_me_path

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "requests from scripts and old browsers" do
    let(:old_chrome) do
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) " \
        "Chrome/90.0.4430.93 Safari/537.36"
    end

    it "skips the website's modern-browser check" do
      sign_in(user)
      get urls_path, headers: {"User-Agent" => old_chrome}
      expect(response).to have_http_status(:not_acceptable)

      get api_v1_me_path, headers: api_headers(secret).merge("User-Agent" => old_chrome)
      expect(response).to have_http_status(:ok)
    end

    it "accepts curl" do
      get api_v1_me_path, headers: api_headers(secret).merge("User-Agent" => "curl/8.5.0")

      expect(response).to have_http_status(:ok)
    end

    it "doesn't require a CSRF token for writes" do
      token.update!(access_level: :read_write)
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true

      post api_v1_urls_path, params: {url: {to: "https://example.org/csrf"}}, headers: api_headers(secret), as: :json

      expect(response).to have_http_status(:created)
    ensure
      ActionController::Base.allow_forgery_protection = original
    end
  end

  describe "rate limiting" do
    around do |example|
      api_config = Rails.application.config.x.api
      original = [api_config.rate_limit, api_config.rate_limit_period]
      api_config.rate_limit = 2
      api_config.rate_limit_period = 60
      Api::V1::BaseController.rate_limit_store = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      api_config.rate_limit, api_config.rate_limit_period = original
      Api::V1::BaseController.rate_limit_store = nil
    end

    it "limits each token across all endpoints" do
      get api_v1_me_path, headers: api_headers(secret)
      expect(response.headers["X-RateLimit-Limit"]).to eq("2")
      expect(response.headers["X-RateLimit-Remaining"]).to eq("1")

      get api_v1_urls_path, headers: api_headers(secret)
      expect(response).to have_http_status(:ok)
      expect(response.headers["X-RateLimit-Remaining"]).to eq("0")

      get api_v1_me_path, headers: api_headers(secret)
      expect(response).to have_http_status(:too_many_requests)
      expect(json["error"]["code"]).to eq("rate_limited")
      expect(response.headers["Retry-After"].to_i).to be_between(1, 60)
      expect(response.headers["X-RateLimit-Reset"].to_i).to be > Time.current.to_i
    end

    it "counts tokens separately" do
      other_secret = ApiToken.generate_secret
      create(:api_token, user: user, secret: other_secret)
      3.times { get api_v1_me_path, headers: api_headers(secret) }

      get api_v1_me_path, headers: api_headers(other_secret)

      expect(response).to have_http_status(:ok)
    end

    it "starts a fresh window after the period" do
      3.times { get api_v1_me_path, headers: api_headers(secret) }

      travel(61.seconds) do
        get api_v1_me_path, headers: api_headers(secret)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "CORS" do
    it "answers preflight requests for the API" do
      options api_v1_urls_path,
        headers: {
          "Origin" => "https://app.example.net",
          "Access-Control-Request-Method" => "POST",
          "Access-Control-Request-Headers" => "authorization, content-type"
        }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
      expect(response.headers["Access-Control-Allow-Methods"]).to include("POST")
      expect(response.headers["Access-Control-Allow-Headers"].downcase).to include("authorization")
      expect(response.headers["Access-Control-Allow-Credentials"]).to be_nil
    end

    it "exposes the rate limit headers to browser clients" do
      get api_v1_me_path, headers: api_headers(secret).merge("Origin" => "https://app.example.net")

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
      expect(response.headers["Access-Control-Expose-Headers"]).to include("X-RateLimit-Remaining")
    end

    it "doesn't add CORS headers to the website" do
      get new_user_session_path, headers: {"Origin" => "https://app.example.net"}

      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    end
  end

  describe "errors" do
    it "returns JSON for unknown endpoints" do
      get "/api/v1/nothing-here", headers: api_headers(secret)

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to include("code" => "not_found")
    end

    it "returns JSON for unknown endpoints even without a token" do
      delete "/api/v2/urls/1"

      expect(response).to have_http_status(:not_found)
      expect(json["error"]["code"]).to eq("not_found")
    end

    it "returns JSON for the API root" do
      get "/api"

      expect(response).to have_http_status(:not_found)
      expect(response.media_type).to eq("application/json")
      expect(json["error"]["code"]).to eq("not_found")
    end

    it "rejects a malformed JSON body" do
      token.update!(access_level: :read_write)

      post api_v1_urls_path,
        params: "{not json",
        headers: api_headers(secret).merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]["message"]).to include("not valid JSON")
    end
  end
end
# rubocop:enable Metrics/BlockLength
