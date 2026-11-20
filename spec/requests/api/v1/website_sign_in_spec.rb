# frozen_string_literal: true

require "rails_helper"

# The API has its own tokens. These specs check it stays separate from how
# people sign in to the website, and that the website's token pages keep the
# website's protection.
# rubocop:disable Metrics/BlockLength
RSpec.describe "API next to the website sign-in", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:secret) { ApiToken.generate_secret }
  let!(:token) { create(:api_token, user: user, secret: secret) }

  def with_forgery_protection
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  context "with header authentication" do
    around do |example|
      original_auth_type = Rails.application.config.devise_auth_type
      Rails.application.config.devise_auth_type = "headers"
      example.run
    ensure
      Rails.application.config.devise_auth_type = original_auth_type
    end

    let(:proxy_headers) { {"X-Auth-Email" => "someone@example.org", "X-Auth-Name" => "Someone"} }

    it "doesn't log in to the API with the proxy headers" do
      expect { get api_v1_me_path, headers: proxy_headers }.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]["code"]).to eq("missing_token")
    end

    it "uses the token's account even when the proxy names somebody else" do
      get api_v1_me_path, headers: api_headers(secret).merge(proxy_headers)

      expect(response).to have_http_status(:ok)
      expect(json["user"]["email"]).to eq(user.email)
    end

    it "lets people signed in by the proxy manage their tokens" do
      expect do
        post api_tokens_path,
          params: {api_token: {name: "From the proxy", access_level: "read_only", lifetime_days: "30"}},
          headers: {"X-Auth-Email" => user.email, "X-Auth-Name" => user.username}
      end.to change(user.api_tokens, :count).by(1)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "CSRF" do
    it "needs the form token to create a token on the settings page" do
      sign_in(user)

      with_forgery_protection do
        expect do
          post api_tokens_path, params: {api_token: {name: "Forged", access_level: "read_write", lifetime_days: "30"}}
        end.not_to change(ApiToken, :count)
      end

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "needs the form token to collect a token from a claim link" do
      api_token = ApiToken.new(user: create(:user, api_only: true), name: "Partner", lifetime_days: 30)
      claim_token = api_token.issue_claim

      with_forgery_protection { post api_token_claim_path, params: {token: claim_token} }

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_token.reload).to be_claimable
    end
  end

  describe "account changes" do
    # Locking is against password guessing on the website. If it stopped
    # tokens, anybody could break someone's scripts with wrong passwords.
    it "keeps tokens working when the website account is locked" do
      user.lock_access!(send_instructions: false)

      get api_v1_me_path, headers: api_headers(secret)

      expect(response).to have_http_status(:ok)
    end

    it "stops tokens when the account is deleted" do
      user.destroy!

      get api_v1_me_path, headers: api_headers(secret)

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]["code"]).to eq("invalid_token")
    end

    it "only takes bearer tokens, not other Authorization schemes" do
      basic = ActionController::HttpAuthentication::Basic.encode_credentials(user.email, user.password)

      get api_v1_me_path, headers: {"Authorization" => basic}

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]["code"]).to eq("missing_token")
    end
  end
end
# rubocop:enable Metrics/BlockLength
