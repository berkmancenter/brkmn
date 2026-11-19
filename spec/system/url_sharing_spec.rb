# frozen_string_literal: true

require "rails_helper"

# rubocop:disable-next Metrics/BlockLength
RSpec.describe "Link sharing", type: :system do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:url) { create(:url, user: owner) }

  it "shows sharing errors, then grants and revokes access in the open dialog" do
    sign_in(owner)
    visit urls_path
    open_details

    within "dialog[open]" do
      fill_in "Email address", with: "missing@example.org"
      click_button "Share"
      expect(page).to have_css("[role='alert']", text: "No user was found with that email address.")
      expect(page).to have_field("Email address", with: "missing@example.org")

      fill_in "Email address", with: other_user.email
      click_button "Share"
      expect(page).to have_css("[role='status']", text: "#{other_user.email} can now edit this link.")
      expect(page).to have_field("Email address", with: "")

      accept_confirm("Remove this user's edit access?") do
        click_button "Remove edit access for #{other_user.email}"
      end
      expect(page).to have_css("[role='status']", text: "Edit access was removed from #{other_user.email}.")
      expect(page).to have_no_button("Remove edit access for #{other_user.email}")

      click_button "Close link details"
    end

    expect(page).to have_no_css("dialog[open]")
    open_details
    expect(page).to have_no_css("dialog[open] [role='status']")
  end

  it "refreshes an owner's existing page with a new access request and approves it" do
    sign_in(owner)
    visit urls_path

    using_session(:requester) do
      sign_in(other_user)
      visit urls_path
      open_details

      within "dialog[open]" do
        click_button "Request edit access"
        expect(page).to have_text("Edit access requested")
      end
    end

    open_details
    within "dialog[open]" do
      expect(page).to have_text("Access requests")
      expect(page).to have_text(other_user.email)
      click_button "Approve"
      expect(page).to have_no_button("Approve")
      expect(page).to have_button("Remove edit access for #{other_user.email}")
    end

    using_session(:requester) do
      visit urls_path
      within "#my_urls" do
        expect(page).to have_link("Edit", href: edit_url_path(url))
      end
    end
  end

  it "denies an access request and removes it from the open dialog" do
    UrlAccessRequest.create!(url: url, user: other_user)
    sign_in(owner)
    visit urls_path
    open_details

    within "dialog[open]" do
      click_button "Deny"
      expect(page).to have_css("[role='status']", text: "The edit access request was denied.")
      expect(page).to have_no_button("Deny")
      expect(page).to have_no_button("Remove edit access for #{other_user.email}")
    end
  end

  def open_details
    click_button "View sharing and link details for #{url.shortened}"
    expect(page).to have_css("dialog[open]")
  end
end
