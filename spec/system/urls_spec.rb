# frozen_string_literal: true

require "rails_helper"

# rubocop:disable-next Metrics/BlockLength
RSpec.describe "Managing short links", type: :system do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  it "generates a shortcode when shortening a link from the bookmarklet page" do
    destination = "https://example.org/bookmarklet"
    visit bookmarklet_urls_path(url: {to: destination})
    expect(page).to have_field("URL to shorten", with: destination)
    click_button "Shorten"

    within "#my_urls" do
      expect(page).to have_link(destination)
      expect(page).to have_link(href: %r{/\w{6}$}, text: /\A[A-Z]{6}\z/)
    end
  end

  it "creates a custom short link, edits its destination, and deletes it from the list" do
    visit urls_path
    fill_in "URL to shorten", with: "https://example.org/original"
    fill_in "url_shortened", with: "browser-demo"
    click_button "Shorten"

    within "#my_urls" do
      expect(page).to have_link("browser-demo")
      expect(page).to have_link("https://example.org/original")
      click_link "Edit"
    end

    within "dialog.link_edit" do
      fill_in "Full URL", with: "https://example.org/updated"
      click_button "Save"
    end

    within "#my_urls" do
      expect(page).to have_link("browser-demo")
      expect(page).to have_link("https://example.org/updated")
      accept_confirm("Are you sure you want to delete this?") { click_link "Delete" }
    end

    expect(page).to have_no_link("browser-demo")
  end

  it "shows a validation error for an invalid destination" do
    visit urls_path
    fill_in "URL to shorten", with: "https://ex ample.org"
    click_button "Shorten"

    expect(page).to have_text("must be a valid url")
    expect(page).to have_text("There are no URLs to display.")
  end

  it "searches for links from the header and clears the filter" do
    matching_url = create(:url, user: user, to: "https://example.org/research")
    other_url = create(:url, to: "https://example.org/another-link")

    visit urls_path
    find(".header-items-item-search > a", text: "Search").click
    fill_in "search", with: "research"
    click_button "search_button"

    expect(page).to have_current_path(search_urls_path, ignore_query: true)
    expect(page).to have_link(matching_url.shortened)
    expect(page).to have_no_link(other_url.shortened)

    click_link "Clear"
    expect(page).to have_link(other_url.shortened)
  end

  it "sorts the owned links by click count in both directions" do
    few_clicks = create(:url, user: user, shortened: "alpha", clicks: 2)
    many_clicks = create(:url, user: user, shortened: "beta", clicks: 8)

    visit urls_path
    within "#my_urls" do
      click_link "Clicks"
      expect(page).to have_css("a.current.asc", text: "Clicks")
      expect(all(".shortened-title").map(&:text)).to eq([few_clicks.shortened, many_clicks.shortened])

      click_link "Clicks"
      expect(page).to have_css("a.current.desc", text: "Clicks")
      expect(all(".shortened-title").map(&:text)).to eq([many_clicks.shortened, few_clicks.shortened])
    end
  end

  it "shows the next page of owned links" do
    first_url = create(:url, user: user, shortened: "alpha")
    second_url = create(:url, user: user, shortened: "beta")

    visit urls_path(per_page: 1)
    within "#my_urls" do
      expect(page).to have_link(first_url.shortened)
      expect(page).to have_no_link(second_url.shortened)
      within ".top_pagination" do
        click_link "2"
      end
      expect(page).to have_link(second_url.shortened)
      expect(page).to have_no_link(first_url.shortened)
    end
  end

  it "copies the short link and opens its QR code in a new tab" do
    url = create(:url, user: user)

    visit urls_path
    within "#my_urls" do
      accept_alert("URL copied to clipboard!") do
        find("[title='Click to copy to clipboard']").click
      end
    end

    qr_window = window_opened_by { click_link "Show QR code for this url" }
    within_window qr_window do
      expect(page).to have_current_path(qr_url_path(url))
      expect(page).to have_css("img")
    end
  end

  it "cuts a long short link and shows the whole one with the toggle button" do
    long_code = "a-very-long-custom-short-link-for-the-spring-campaign-2026"
    create(:url, user: user, shortened: "short")
    create(:url, user: user, shortened: long_code)

    visit urls_path

    within "#my_urls" do
      expect(page).to have_link("short")
      expect(page).to have_button("Show the whole short link short", visible: :hidden)

      link = find_link(long_code)
      cut_height = link.evaluate_script("this.getBoundingClientRect().height")
      expect(link.evaluate_script("this.scrollWidth > this.clientWidth")).to be(true)

      toggle = find_button("Show the whole short link #{long_code}")
      expect(toggle["aria-expanded"]).to eq("false")
      toggle.click

      expect(page).to have_css(".shortened-title--expanded .shortened-title-toggle[aria-expanded='true']")
      expect(link.evaluate_script("this.getBoundingClientRect().height")).to be > cut_height

      toggle.click
      expect(page).to have_no_css(".shortened-title--expanded")
      expect(toggle["aria-expanded"]).to eq("false")
    end
  end

  it "keeps the selected theme after reloading" do
    visit urls_path
    click_link "Classic"
    expect(page).to have_css("body.viewing-mode-classic") {
      page.evaluate_script("document.cookie").include?("viewing_mode=classic")
    }

    refresh
    expect(page).to have_css("body.viewing-mode-classic")
    click_link "Light"
    expect(page).to have_css("body.viewing-mode-modern")
  end

  context "when signed in as a superadmin" do
    let(:user) { create(:user, :superadmin) }

    it "can edit another user's link from the shared list" do
      url = create(:url)

      visit urls_path
      within "#not_my_urls" do
        click_link "Edit", href: edit_url_path(url)
      end
      within "dialog.link_edit" do
        fill_in "Full URL", with: "https://example.org/admin-edit"
        click_button "Save"
      end

      within "#not_my_urls" do
        expect(page).to have_link("https://example.org/admin-edit")
      end
    end
  end
end
