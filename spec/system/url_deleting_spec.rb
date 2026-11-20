# frozen_string_literal: true

require "rails_helper"

# Deleting a link from a long list keeps the page where it is.
# rubocop:disable Metrics/BlockLength
RSpec.describe "Deleting a link", type: :system do
  let(:user) { create(:user) }

  before do
    # Long enough to scroll in the 1400px high test browser.
    60.times { |index| create(:url, user: user, shortened: format("link-%02d", index)) }
    sign_in(user)
  end

  def scroll_position
    page.evaluate_script("window.scrollY")
  end

  def delete_link(code)
    within("#my_urls tr", text: code) do
      accept_confirm("Are you sure you want to delete this?") { click_link "Delete" }
    end
    expect(page).to have_no_link(code)
  end

  it "fades the row out before it goes" do
    visit urls_path(sort: "shortened", direction: "asc", per_page: 60)

    within("#my_urls tr", text: "link-10") do
      accept_confirm("Are you sure you want to delete this?") { click_link "Delete" }
    end

    expect(page).to have_css("tr.url-row--removing", text: "link-10")
    expect(page).to have_no_link("link-10")
    expect(page).to have_no_css("tr.url-row--removing")
  end

  it "leaves the row alone when the delete is cancelled" do
    visit urls_path(sort: "shortened", direction: "asc", per_page: 60)

    within("#my_urls tr", text: "link-10") do
      dismiss_confirm("Are you sure you want to delete this?") { click_link "Delete" }
    end

    expect(page).to have_link("link-10")
    expect(page).to have_no_css("tr.url-row--removing")
  end

  it "keeps the scroll position" do
    visit urls_path(sort: "shortened", direction: "asc", per_page: 60)
    page.execute_script("window.scrollTo(0, 700)")
    expect(scroll_position).to eq(700)

    delete_link("link-10")

    expect(page).to have_link("link-11")
    expect(scroll_position).to eq(700)
  end

  it "keeps the scroll position after paging, when the address has the list's anchor" do
    visit urls_path(sort: "shortened", direction: "asc", per_page: 50)
    within("#my_urls .top_pagination") { click_link "2" }
    expect(page).to have_current_path(/my_page=2/)
    expect(page).to have_link("link-55")
    within("#my_urls .top_pagination") { click_link "1" }
    expect(page).to have_current_path(/#my_urls/, url: true)
    expect(page).to have_link("link-00")
    page.execute_script("window.scrollTo(0, 600)")
    expect(scroll_position).to eq(600)

    delete_link("link-08")

    expect(page).to have_link("link-50")
    expect(scroll_position).to eq(600)
  end
end
# rubocop:enable Metrics/BlockLength
