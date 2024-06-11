# frozen_string_literal: true

require 'test_helper'

class RedirectionTest < IntegrationTest
  def setup
    @redirect_url = 'https://theuselessweb.com/'
    @url = Url.create(to: @redirect_url)
  end

  def teardown
    @url.destroy
  end

  it 'redirects when given a known url' do
    Capybara.current_driver = :no_redirects

    visit "/#{@url.shortened}"

    assert page.response_headers['location'] == @redirect_url

    Capybara.use_default_driver
  end

  it 'updates the view count' do
    Capybara.current_driver = :no_redirects

    orig_count = @url.clicks

    visit "/#{@url.shortened}"
    @url.reload

    assert @url.clicks == orig_count + 1

    Capybara.use_default_driver
  end

  it '404s for unknown urls' do
    shortened = 'nope'
    assert Url.where(shortened: shortened).empty?

    visit "/#{shortened}"

    assert page.status_code == 404
  end
end
