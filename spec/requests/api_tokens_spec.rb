# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "API tokens page", type: :request do
  let(:user) { create(:user) }
  let(:turbo_stream_headers) { {"Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"} }

  before { sign_in(user) }

  describe "GET /settings" do
    it "opens the API token settings" do
      get settings_path

      expect(response).to redirect_to(api_tokens_path)
    end
  end

  describe "GET /api_tokens" do
    it "lists only the user's own tokens, including revoked ones" do
      create(:api_token, user: user, name: "Mine")
      create(:api_token, :revoked, user: user, name: "Old one", revoked_by: user)
      create(:api_token, name: "Someone else's")

      get api_tokens_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mine", "Old one", "Revoked", "by #{user.username}")
      expect(response.body).not_to include("Someone else's")
      expect(response.body).to include(
        "https://github.com/berkmancenter/brkmn/blob/main/docs/api/README.md"
      )
      expect(response.body).to include("Settings", "API tokens", 'aria-current="page"')
      expect(response.body).not_to include(admin_api_tokens_path, new_admin_api_token_path)
    end

    it "requires sign-in" do
      sign_out

      get api_tokens_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /api_tokens" do
    let(:params) { {api_token: {name: "CI", access_level: "read_only", lifetime_days: "30"}} }

    it "creates a token and shows its secret exactly once" do
      expect { post api_tokens_path, params: params }.to change(user.api_tokens, :count).by(1)

      token = user.api_tokens.last
      secrets = secrets_in(response.body)
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(secrets.size).to eq(1)
      expect(ApiToken.find_for_secret(secrets.first)).to eq(token)
      expect(token).to have_attributes(name: "CI", access_level: "read_only", lifetime_days: 30, created_by: user)

      get api_tokens_path
      expect(secrets_in(response.body)).to be_empty
      expect(response.body).to include(token.token_prefix)
    end

    it "answers Turbo form submissions with a stream that replaces the page" do
      post api_tokens_path, params: params, headers: turbo_stream_headers

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('action="replace"', 'target="api_tokens_page"')
      expect(secrets_in(response.body).size).to eq(1)
    end

    it "creates a token that never expires" do
      post api_tokens_path, params: {api_token: {name: "Forever", access_level: "read_write", lifetime_days: ""}}

      expect(user.api_tokens.last).to have_attributes(lifetime_days: nil, expires_at: nil, access_level: "read_write")
    end

    it "shows validation errors" do
      expect do
        post api_tokens_path, params: {api_token: {name: "", access_level: "read_only"}}
      end.not_to change(ApiToken, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Name can&#39;t be blank")
    end

    it "ignores attempts to create a token for someone else" do
      other = create(:user)

      post api_tokens_path, params: {api_token: {name: "Sneaky", user_id: other.id}}

      expect(other.api_tokens).to be_empty
      expect(user.api_tokens.pluck(:name)).to eq(["Sneaky"])
    end
  end

  describe "POST /api_tokens/:id/regenerate" do
    it "replaces the secret and shows the new one once" do
      old_secret = ApiToken.generate_secret
      token = create(:api_token, user: user, secret: old_secret, lifetime_days: 7, expires_at: 1.day.from_now)

      post regenerate_api_token_path(token)

      new_secret = secrets_in(response.body).first
      expect(response).to have_http_status(:ok)
      expect(ApiToken.find_for_secret(old_secret)).to be_nil
      expect(ApiToken.find_for_secret(new_secret)).to eq(token)
      expect(token.reload.expires_at).to be_within(5.seconds).of(7.days.from_now)
    end

    it "refuses to regenerate a revoked token" do
      token = create(:api_token, :revoked, user: user)

      post regenerate_api_token_path(token)

      expect(response).to redirect_to(api_tokens_path)
      expect(flash[:alert]).to include("revoked")
    end

    it "can't touch another user's token" do
      token = create(:api_token)

      post regenerate_api_token_path(token)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api_tokens/:id/revoke" do
    it "revokes the token and keeps it in the list" do
      secret = ApiToken.generate_secret
      token = create(:api_token, user: user, secret: secret, name: "Zapier")

      patch revoke_api_token_path(token)

      expect(response).to redirect_to(api_tokens_path)
      expect(response).to have_http_status(:see_other)
      expect(token.reload).to have_attributes(revoked_by: user)
      expect(ApiToken.find_for_secret(secret)).not_to be_usable

      follow_redirect!
      expect(response.body).to include("Token “Zapier” was revoked.")
    end

    it "can't revoke another user's token" do
      token = create(:api_token)

      patch revoke_api_token_path(token)

      expect(response).to have_http_status(:not_found)
      expect(token.reload).not_to be_revoked
    end
  end

  describe "header links" do
    it "links regular users to settings" do
      get urls_path

      expect(response.body).to include(settings_path)
      expect(response.body).to include('class="header-items-item-settings"')
      expect(response.body).to match(/<img[^>]+src="[^"]*settings[^"]*\.svg"/)
      expect(response.body).not_to include(api_tokens_path, admin_api_tokens_path)
    end

    it "uses the same settings entry point for superadmins" do
      user.update!(superadmin: true)

      get urls_path

      expect(response.body).to include(settings_path)
      expect(response.body).not_to include(api_tokens_path, admin_api_tokens_path)
    end
  end
end
# rubocop:enable Metrics/BlockLength
