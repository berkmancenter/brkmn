# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Password authentication", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }

  def log_in(password)
    post user_session_path, params: {user: {email: user.email, password: password}}
  end

  it "requires passwords of at least 12 characters" do
    expect(build(:user, password: "short-pass1", password_confirmation: "short-pass1")).not_to be_valid
    expect(build(:user, password: "long-enough-1", password_confirmation: "long-enough-1")).to be_valid
  end

  it "locks the account after too many wrong passwords" do
    Devise.maximum_attempts.times { log_in("wrong-password") }

    expect(user.reload).to be_access_locked

    log_in(user.password)
    get urls_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "does not tell whether an email has an account when resetting a password" do
    post user_password_path, params: {user: {email: "nobody@example.com"}}
    unknown_email_notice = flash[:notice]

    post user_password_path, params: {user: {email: user.email}}

    expect(unknown_email_notice).to be_present
    expect(flash[:notice]).to eq(unknown_email_notice)
  end

  it "shows the password reset form on the forgot password page" do
    get new_user_password_path

    expect(response.body).to include("Forgot your password?")
    expect(response.body).to include(%(action="#{user_password_path}"))
    expect(response.body).not_to include("Resend confirmation instructions</button>")
  end

  it "sends reset password instructions" do
    expect do
      post user_password_path, params: {user: {email: user.email}}
    end.to change { ActionMailer::Base.deliveries.size }.by(1)

    expect(ActionMailer::Base.deliveries.last.subject).to eq("Reset password instructions")
  end

  it "rate limits log in attempts" do
    store = ApplicationController.cache_store
    allow(store).to receive(:increment).and_return(ApplicationController::AUTH_RATE_LIMIT + 1)

    log_in(user.password)

    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to include("Too many attempts")
    get urls_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "sends a content security policy with a script nonce" do
    get new_user_session_path

    policy = response.headers["Content-Security-Policy"]
    nonce = policy[/'nonce-([^']+)'/, 1]
    expect(policy).to include("script-src 'self' 'nonce-")
    expect(policy).to include("object-src 'none'")
    expect(response.body).to match(/<script type="importmap"[^>]*nonce="#{Regexp.escape(nonce)}"/)
  end
end
# rubocop:enable Metrics/BlockLength
