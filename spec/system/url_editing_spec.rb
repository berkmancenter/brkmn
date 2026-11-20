# frozen_string_literal: true

require "rails_helper"

# Editing a link's destination happens in a dialog on the list, like sharing.
# rubocop:disable Metrics/BlockLength
RSpec.describe "Editing a link in a dialog", type: :system do
  let(:user) { create(:user) }
  let!(:url) { create(:url, user: user, shortened: "edit-me", to: "https://example.org/original") }

  before do
    sign_in(user)
  end

  def open_edit_dialog
    within("#row_url_#{url.id}") { click_link "Edit" }
    expect(page).to have_css("dialog.link_edit[open]")
  end

  it "saves the destination and updates the row without leaving the page" do
    visit urls_path
    open_edit_dialog

    within("dialog.link_edit") do
      expect(page).to have_text('Edit "edit-me"')
      expect(page).to have_field("Full URL", with: "https://example.org/original")
      fill_in "Full URL", with: "https://example.org/changed"
      click_button "Save"
    end

    expect(page).to have_no_css("dialog.link_edit")
    within("#row_url_#{url.id}") { expect(page).to have_link("https://example.org/changed") }
    expect(page).to have_current_path(urls_path)
    expect(url.reload.to).to eq("https://example.org/changed")
  end

  it "focuses the destination with the cursor at the end" do
    cursor = lambda do
      page.evaluate_script(<<~JS)
        (() => {
          const field = document.activeElement
          return [field.id, field.selectionStart, field.selectionEnd, field.value.length]
        })()
      JS
    end

    visit urls_path
    open_edit_dialog
    expect(cursor.call).to eq(["edit_url_to_#{url.id}", 28, 28, 28])

    within("dialog.link_edit") do
      fill_in "Full URL", with: "https://"
      click_button "Save"
      expect(page).to have_css("[role='alert']")
    end
    expect(cursor.call).to eq(["edit_url_to_#{url.id}", 8, 8, 8])
  end

  it "shows errors in the dialog and keeps it open" do
    visit urls_path
    open_edit_dialog

    within("dialog.link_edit") do
      fill_in "Full URL", with: "https://ex ample.org"
      click_button "Save"

      expect(page).to have_css("[role='alert']", text: "must be a valid url")
      expect(page).to have_field("Full URL", with: "https://ex ample.org")
    end
    expect(url.reload.to).to eq("https://example.org/original")
  end

  it "closes with Cancel or Escape without saving" do
    visit urls_path

    open_edit_dialog
    within("dialog.link_edit") do
      fill_in "Full URL", with: "https://example.org/not-saved"
      click_button "Cancel"
    end
    expect(page).to have_no_css("dialog.link_edit")

    open_edit_dialog
    expect(page).to have_field("Full URL", with: "https://example.org/original")
    find("dialog.link_edit").send_keys(:escape)
    expect(page).to have_no_css("dialog.link_edit")

    expect(url.reload.to).to eq("https://example.org/original")
  end

  it "keeps both lists on their pages after saving" do
    create(:url, user: user, shortened: "aaa-first")
    3.times { |index| create(:url, user: create(:user), shortened: "theirs-#{index}") }

    visit urls_path(per_page: 1, my_page: 2, others_page: 2, sort: "shortened", direction: "asc")
    open_edit_dialog
    within("dialog.link_edit") do
      fill_in "Full URL", with: "https://example.org/on-page-two"
      click_button "Save"
    end

    within("#row_url_#{url.id}") { expect(page).to have_link("https://example.org/on-page-two") }
    within("#not_my_urls") { expect(page).to have_link("theirs-1") }
    expect(page).to have_current_path(/my_page=2/)
    expect(page).to have_current_path(/others_page=2/)
  end
end
# rubocop:enable Metrics/BlockLength
