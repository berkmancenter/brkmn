# frozen_string_literal: true

require "rails_helper"

# "My URLs" and "All URLs" have their own pages (my_page, others_page). Paging
# through one list must not move the other one.
# rubocop:disable Metrics/BlockLength
RSpec.describe "Paging through the link lists", type: :system do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    3.times { |index| create(:url, user: user, shortened: "mine-#{index}") }
    3.times { |index| create(:url, user: other_user, shortened: "theirs-#{index}") }
    sign_in(user)
  end

  # Waits for the address too: Turbo adds the history entry right after the
  # list is drawn, a quick "back" could skip it otherwise.
  def go_to_page(number, list:)
    param = list == "my_urls" ? "my_page" : "others_page"
    within("##{list} .top_pagination") { click_link number.to_s }
    if number > 1
      expect(page).to have_current_path(/#{param}=#{number}/)
    else
      expect(page).to have_no_current_path(/#{param}=[2-9]/)
    end
  end

  def expect_list(list, shows:, hides:)
    within("##{list}") do
      expect(page).to have_link(shows)
      expect(page).to have_no_link(hides)
    end
  end

  def expect_mine_on_page2 = expect_list("my_urls", shows: "mine-2", hides: "mine-0")
  def expect_mine_on_page1 = expect_list("my_urls", shows: "mine-0", hides: "mine-2")
  def expect_theirs_on_page2 = expect_list("not_my_urls", shows: "theirs-2", hides: "theirs-0")
  def expect_theirs_on_page1 = expect_list("not_my_urls", shows: "theirs-0", hides: "theirs-2")

  it "keeps the page of the other list, also after a reload" do
    visit urls_path(per_page: 2, sort: "shortened", direction: "asc")

    go_to_page 2, list: "not_my_urls"
    expect_theirs_on_page2
    expect_mine_on_page1

    go_to_page 2, list: "my_urls"
    expect_mine_on_page2
    expect_theirs_on_page2
    expect(page).to have_current_path(/my_page=2/)
    expect(page).to have_current_path(/others_page=2/)

    refresh
    expect_mine_on_page2
    expect_theirs_on_page2

    go_to_page 1, list: "not_my_urls"
    expect_theirs_on_page1
    expect_mine_on_page2
  end

  it "goes back to the pages before with the back button" do
    visit urls_path(per_page: 2, sort: "shortened", direction: "asc")

    go_to_page 2, list: "my_urls"
    expect_mine_on_page2
    go_to_page 2, list: "not_my_urls"
    expect_theirs_on_page2

    page.go_back
    expect_theirs_on_page1
    expect_mine_on_page2
  end

  it "keeps the pages after deleting a link" do
    visit urls_path(per_page: 2, sort: "shortened", direction: "asc")
    go_to_page 2, list: "not_my_urls"
    expect_theirs_on_page2

    within("#my_urls tr", text: "mine-0") do
      accept_confirm("Are you sure you want to delete this?") { click_link "Delete" }
    end

    expect_list("my_urls", shows: "mine-2", hides: "mine-0")
    expect_theirs_on_page2
    expect(page).to have_current_path(/others_page=2/)
  end

  it "sorts both lists, the sort is the same for both" do
    visit urls_path(per_page: 2, sort: "shortened", direction: "asc")

    within("#my_urls") { click_link "Shortened URL" }

    expect_list("my_urls", shows: "mine-2", hides: "mine-0")
    expect_list("not_my_urls", shows: "theirs-2", hides: "theirs-0")
    expect(page).to have_current_path(/direction=desc/)
  end
end
# rubocop:enable Metrics/BlockLength
