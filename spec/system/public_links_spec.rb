# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Following a short link", type: :system do
  it "redirects a visitor to the destination and counts the click" do
    destination = "#{page.server.base_url}#{new_user_session_path}"
    url = create(:url, to: destination)

    visit shortened_path(url.shortened)

    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_button("Log in")
    expect(url.reload.clicks).to eq(1)
  end

  it "shows a not-found page for an unknown short link" do
    visit shortened_path("unknown-browser-link")

    expect(page).to have_text("Not found")
    expect(page).to have_text("we couldn't find that shortened URL")
  end
end
