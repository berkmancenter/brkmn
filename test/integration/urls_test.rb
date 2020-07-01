require 'test_helper'

class UrlsTest < IntegrationTest
  before do
    @redirect_url = 'https://scratch.mit.edu/'
    @url = Url.create(to: @redirect_url)
    authorize
  end

  it 'lets you see a url' do
    visit url_path(@url.id)

    assert page.has_content?("Full URL: #{@url.to}")
    assert page.has_content?("Shortened URL: #{@url.shortened}")
    assert page.has_content?("Clicks: #{@url.clicks}")
  end

  it 'lets you create a URL on the index page' do
    orig_count = Url.count

    visit urls_path
    fill_in 'URL to shorten', with: 'https://a.new.url'
    click_on 'Shorten'

    assert Url.count == orig_count + 1
    assert Url.where(to: 'https://a.new.url').present?
  end

  it 'lets you create a URL with a specific shortcode on the index page' do
    orig_count = Url.count

    visit urls_path
    fill_in 'URL to shorten', with: 'https://a.new.url'
    fill_in 'OPTIONAL: shorten to. . . ', with: 'new'
    click_on 'Shorten'

    assert Url.count == orig_count + 1
    assert Url.where(to: 'https://a.new.url', shortened: 'new').present?
  end

  it 'shows you the list of URLs on the index page' do
    visit urls_path

    Url.all.each do |url|
      assert page.has_content? url.to
    end
  end

  it 'lets you search for URLs on the index page' do
    Url.create(to: 'https://totallydifferent.domain.com')

    visit urls_path
    fill_in 'search', with: 'scratch'
    click_on 'Search'

    assert page.has_content?('https://scratch.mit.edu/')
    assert page.has_no_content?('https://totallydifferent.domain.com')
  end

  it 'redirects from index to search when search in params' do
    Url.create(to: 'https://totallydifferent.domain.com')
    visit urls_path, params: { search: 'scratch' }

    assert page.has_content?('https://scratch.mit.edu/')
    assert page.has_no_content?('https://totallydifferent.domain.com')
  end
end
