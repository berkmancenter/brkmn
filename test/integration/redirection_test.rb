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
    visit "/#{@url.shortened}"

    assert page.current_url == @redirect_url,
           "Did not redirect; current_url is #{page.current_url}"
  end

  it 'updates the view count' do
    orig_count = @url.clicks

    visit "/#{@url.shortened}"
    @url.reload

    assert @url.clicks == orig_count + 1
  end

  it '404s for unknown urls' do
    shortened = 'nope'
    assert Url.where(shortened: shortened).empty?

    visit "/#{shortened}"

    assert page.status_code == 404
  end
end
