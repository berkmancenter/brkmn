# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Header authentication", type: :request do
  around do |example|
    original_auth_type = Rails.application.config.devise_auth_type
    Rails.application.config.devise_auth_type = "headers"
    example.run
  ensure
    Rails.application.config.devise_auth_type = original_auth_type
  end

  let(:headers) do
    {
      "X-Auth-Email" => "Person@Example.com",
      "X-Auth-Name" => "proxy-user",
    }
  end

  it "creates a user from the trusted headers and authenticates the request" do
    expect do
      get urls_path, headers: headers
    end.to change(User, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(User.last).to have_attributes(
      email: "person@example.com",
      username: "proxy-user"
    )
  end

  it "updates the existing user matched by email" do
    user = create(:user, email: "person@example.com", username: "old-name", confirmed_at: Time.current)

    expect do
      get urls_path, headers: headers
    end.not_to change(User, :count)

    expect(response).to have_http_status(:ok)
    expect(user.reload.username).to eq("proxy-user")
  end

  it "requires the email header" do
    expect do
      get urls_path, headers: headers.except("X-Auth-Email")
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unauthorized)
  end

  it "requires the name header" do
    expect do
      get urls_path, headers: headers.except("X-Auth-Name")
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unauthorized)
  end

  it "ignores the headers when the request does not come from a trusted proxy" do
    expect do
      get urls_path, headers: headers, env: {"REMOTE_ADDR" => "203.0.113.9"}
    end.not_to change(User, :count)

    expect(response).to have_http_status(:unauthorized)
  end

  it "accepts the headers from a configured proxy range" do
    original_proxies = Rails.application.config.auth_headers_trusted_proxies
    Rails.application.config.auth_headers_trusted_proxies = [IPAddr.new("10.0.0.0/8")]

    get urls_path, headers: headers, env: {"REMOTE_ADDR" => "10.1.2.3"}
    expect(response).to have_http_status(:ok)

    get urls_path, headers: headers, env: {"REMOTE_ADDR" => "127.0.0.1"}
    expect(response).to have_http_status(:unauthorized)
  ensure
    Rails.application.config.auth_headers_trusted_proxies = original_proxies
  end

  it "lets two people with the same display name log in" do
    create(:user, email: "first@example.com", username: "Pat Smith")

    get urls_path, headers: {"X-Auth-Email" => "second@example.com", "X-Auth-Name" => "Pat Smith"}

    expect(response).to have_http_status(:ok)
    expect(User.find_by!(email: "second@example.com").username).to eq("second@example.com")
  end

  it "does not write the user again when nothing changed" do
    get urls_path, headers: headers
    user = User.find_by!(email: "person@example.com")

    expect do
      get urls_path, headers: headers
    end.not_to(change { user.reload.updated_at })
  end

  it "rejects a forged form post even though the proxy sends the headers" do
    ActionController::Base.allow_forgery_protection = true

    expect do
      post urls_path, params: {url: {to: "https://evil.example.org"}}, headers: headers
    end.not_to change(Url, :count)

    expect(response).to have_http_status(:unprocessable_content)
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  it "does not reuse the header-authenticated user without headers" do
    get urls_path, headers: headers
    expect(response).to have_http_status(:ok)

    get urls_path

    expect(response).to have_http_status(:unauthorized)
  end
end
# rubocop:enable Metrics/BlockLength
