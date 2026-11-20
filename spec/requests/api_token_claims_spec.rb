# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Collecting an external API token", type: :request do
  let(:external_user) { create(:user, email: "partner@example.org", api_only: true) }
  let(:api_token) { ApiToken.new(user: external_user, name: "Newsletter", lifetime_days: 30) }
  let!(:claim_token) { api_token.issue_claim }

  describe "GET /api/token_claim" do
    it "shows a button without using up the link" do
      get api_token_claim_path(token: claim_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Show my token", "partner@example.org", "Newsletter")
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
      expect(api_token.reload).to be_claimable
      expect(secrets_in(response.body)).to be_empty
    end

    it "explains an expired link" do
      api_token.update!(claim_expires_at: 1.minute.ago)

      get api_token_claim_path(token: claim_token)

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("This link expired")
    end

    it "explains an unknown link" do
      get api_token_claim_path(token: "nope")

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("invalid or has already been used")
    end

    it "keeps links sent with the old path working" do
      get legacy_api_token_claim_path(token: claim_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Show my token")
    end
  end

  describe "POST /api/token_claim" do
    it "shows the token once and then the link stops working" do
      post api_token_claim_path, params: {token: claim_token}

      secret = secrets_in(response.body).first
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(ApiToken.find_for_secret(secret)).to eq(api_token)
      expect(api_token.reload).to be_usable
      expect(api_token.expires_at).to be_within(5.seconds).of(30.days.from_now)

      post api_token_claim_path, params: {token: claim_token}
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("invalid or has already been used")
      expect(secrets_in(response.body)).to be_empty
    end

    it "answers Turbo form submissions with a stream" do
      post api_token_claim_path,
        params: {token: claim_token},
        headers: {"Accept" => "text/vnd.turbo-stream.html, text/html"}

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('target="api_token_claim"')
      expect(secrets_in(response.body).size).to eq(1)
    end

    it "gives a token that works with the API" do
      post api_token_claim_path, params: {token: claim_token}
      secret = secrets_in(response.body).first

      get api_v1_me_path, headers: api_headers(secret)

      expect(response).to have_http_status(:ok)
      expect(json["user"]["email"]).to eq("partner@example.org")
    end

    it "refuses an expired link" do
      api_token.update!(claim_expires_at: 1.minute.ago)

      post api_token_claim_path, params: {token: claim_token}

      expect(response).to have_http_status(:unprocessable_content)
      expect(api_token.reload).to be_pending
    end
  end

  describe "signing in to the website" do
    it "is refused for API-only accounts" do
      user = create(:user, api_only: true, password: "correct-horse-battery", confirmed_at: Time.current)

      post user_session_path, params: {user: {email: user.email, password: "correct-horse-battery"}}
      follow_redirect!

      expect(response.body).to include("This account can only use the API")
      get urls_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
# rubocop:enable Metrics/BlockLength
