# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Header menu", type: :system do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context "on a phone" do
    before do
      page.current_window.resize_to(375, 800)
    end

    # The browser is shared between specs, the others expect the wide screen from spec/support/system.rb
    after do
      page.current_window.resize_to(1400, 1400)
    end

    it "keeps the menu items behind the Menu button" do
      visit urls_path

      expect(page).to have_css(".header-items-item-search > a", text: "Search")
      expect(page).to have_css("button[aria-expanded='false']", text: "Menu")
      expect(page).to have_no_link("Settings")
      expect(page).to have_no_link("Sign out")

      click_button "Menu"

      expect(page).to have_css("button[aria-expanded='true']", text: "Menu")
      expect(page).to have_text(user.email)
      expect(page).to have_link("Settings")

      find("body").send_keys(:escape)
      expect(page).to have_no_link("Settings")
    end

    it "signs out from the menu" do
      visit urls_path
      click_button "Menu"
      click_link "Sign out"

      expect(page).to have_current_path(new_user_session_path)
    end

    it "opens the search form below the header" do
      visit urls_path
      find(".header-items-item-search > a", text: "Search").click

      expect(page).to have_field("search")
      expect(page).to have_button("search_button")
    end
  end

  context "on a wide screen" do
    it "shows every item without the Menu button" do
      visit urls_path

      expect(page).to have_no_button("Menu")
      expect(page).to have_link("Settings")
      expect(page).to have_link("Sign out")
      expect(page).to have_text(user.email)
    end
  end
end
