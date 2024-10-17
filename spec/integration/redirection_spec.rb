# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "URL Redirection", type: :request do
  let(:redirect_url) { 'https://theuselessweb.com/' }
  let(:url) { Url.create(to: redirect_url) }

  after do
    url.destroy
  end

  it 'redirects when given a known url' do
    get "/#{url.shortened}"

    expect(response).to have_http_status(302)
    expect(response.headers['Location']).to eq(redirect_url)
  end

  it 'updates the view count' do
    orig_count = url.clicks

    get "/#{url.shortened}"
    url.reload

    expect(url.clicks).to eq(orig_count + 1)
  end

  it '404s for unknown urls' do
    shortened = 'nope'
    expect(Url.where(shortened: shortened)).to be_empty

    get "/#{shortened}"

    expect(response).to have_http_status(404)
  end
end
