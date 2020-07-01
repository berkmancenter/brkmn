require 'test_helper'

class RedirectionTest < IntegrationTest
  before do
    @redirect_url = 'https://theuselessweb.com/'
    @url = Url.create(to: @redirect_url)
    authorize
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

# class RedirectorController < ApplicationController
#   def index
#     @url = Url.find_by_shortened(params[:id])
#     @url.update_attribute(:clicks, @url.clicks + 1)
#     redirect_to @url.to
#   rescue StandardError
#     render status: :not_found, action: :invalid
#   end
#
#   def invalid
#     render status: :not_found
#   end
# end
