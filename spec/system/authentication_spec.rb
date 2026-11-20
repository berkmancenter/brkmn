# frozen_string_literal: true

require "rails_helper"

# rubocop:disable-next Metrics/BlockLength
RSpec.describe "Account access", type: :system do
  it "signs in through the login form and signs out from the dashboard" do
    user = create(:user, confirmed_at: Time.current)

    visit urls_path
    expect(page).to have_current_path(new_user_session_path)
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Log in"

    expect(page).to have_current_path(urls_path)
    expect(page).to have_text("My URLs")

    click_link "Sign out"
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_button("Log in")
  end

  it "registers an account and confirms it using the emailed link" do
    email = "new-user@example.org"

    visit new_user_session_path
    click_link "Sign up"
    fill_in "Email", with: email
    fill_in "Password", with: "correct-horse-battery", exact: true
    fill_in "Password confirmation", with: "correct-horse-battery"
    click_button "Sign up"

    expect(page).to have_current_path(new_user_session_path)
    message = ActionMailer::Base.deliveries.last
    expect(message.to).to eq([email])
    confirmation_link = Nokogiri::HTML(message.body.decoded).at_css("a")["href"]
    visit URI.parse(confirmation_link).request_uri

    expect(page).to have_text("Your email address has been successfully confirmed.")
    expect(User.find_by!(email: email)).to be_confirmed
  end
end
