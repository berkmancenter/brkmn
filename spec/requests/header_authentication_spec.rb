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

  it "does not reuse the header-authenticated user without headers" do
    get urls_path, headers: headers
    expect(response).to have_http_status(:ok)

    get urls_path

    expect(response).to have_http_status(:unauthorized)
  end
end
# rubocop:enable Metrics/BlockLength
