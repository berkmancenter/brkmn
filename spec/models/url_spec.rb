# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Url, type: :model do
  describe 'validations' do
    it 'requires :to to be present' do
      url = Url.new(shortened: 'foobar', to: nil)
      expect(url).not_to be_valid
    end

    it 'validates URLs' do
      url = Url.new(to: 'https://ex ample.com')
      expect(url).not_to be_valid
    end

    it 'does not allow localhost' do
      url = Url.new(to: 'http://localhost.com')
      expect(url).not_to be_valid

      url = Url.new(to: 'https://localhost.com')
      expect(url).not_to be_valid
    end

    it 'does not allow brk.mn, no infinite redirects for you' do
      url = Url.new(to: 'http://brk.mn')
      expect(url).not_to be_valid

      url = Url.new(to: 'https://brk.mn')
      expect(url).not_to be_valid
    end

    it 'ensures that the protocol appears in the URL exactly once' do
      # Well-formed case: keep the protocol you're given.
      url = Url.create(shortened: 'foobar', to: 'http://google.com')
      expect(url.to).to eq('http://google.com')

      url = Url.create(shortened: 'foobar', to: 'https://google.com')
      expect(url.to).to eq('https://google.com')

      # No protocol given: add one.
      url = Url.create(shortened: 'foobar', to: 'google.com')
      expect(url.to).to eq('https://google.com')

      # Protocol given twice.
      url = Url.create(shortened: 'foobar', to: 'http://http://google.com')
      expect(url.to).to eq('http://google.com')

      url = Url.create(shortened: 'foobar', to: 'http://https://google.com')
      expect(url.to).to eq('https://google.com')

      url = Url.create(shortened: 'foobar', to: 'https://http://google.com')
      expect(url.to).to eq('http://google.com')

      url = Url.create(shortened: 'foobar', to: 'https://https://google.com')
      expect(url.to).to eq('https://google.com')
    end
  end

  describe '.shortened on creation' do
    it 'autocreates if shortened is left blank' do
      url = Url.create(shortened: nil, to: 'http://google.com')
      expect(url.shortened).to be_present
    end

    it 'generates shortcodes' do
      user = create(:user)
      url = Url.new(to: 'http://www.google.com', user: user)
      expect(url.save).to be true
      expect(url.shortened).to be_present
    end

    it 'disallows reuse of existing shortcodes' do
      shortcode = '42'
      create(:url, shortened: shortcode, to: 'http://google.com')

      url = Url.new(shortened: shortcode, to: 'https://google.com')
      expect(url).not_to be_valid
    end

    it 'disallows protected URL regex elements' do
      expect(PROTECTED_URL_REGEX).to eq(/^(url|user|metric|redirector|preview|logout)/i)

      ['url', 'user', 'metric', 'redirector7', 'preview_yay', 'logoutlogout'].each do |shortcode|
        url = Url.new(shortened: shortcode, to: 'https://google.com')
        expect(url).not_to be_valid
      end
    end

    it "disallows characters that can't be used in a URL" do
      ['🤷‍', 'no spaces'].each do |shortcode|
        url = Url.new(shortened: shortcode, to: 'https://google.com')
        expect(url).not_to be_valid
      end
    end
  end

  describe '.shortened on update' do
    it 'handles blank codes' do
      url = create(:url, shortened: '42', to: 'http://google.com')
      url.shortened = ''
      url.save
      url.reload
      expect(url.shortened).to be_present
    end

    it 'does not allow duplicates' do
      user = create(:user)
      url1 = create(:url, shortened: 'hoho1', to: 'http://www.google.com', user: user)
      url2 = create(:url, shortened: 'hoho2', to: 'http://www.google.com', user: user)

      url1.shortened = 'hoho2'
      expect(url1).not_to be_valid
    end

    it 'disallows protected URL regex elements' do
      expect(PROTECTED_URL_REGEX).to eq(/^(url|user|metric|redirector|preview|logout)/i)

      url = create(:url, to: 'https://google.com')

      ['url', 'user', 'metric', 'redirector7', 'preview_yay', 'logoutlogout'].each do |shortcode|
        url.shortened = shortcode
        expect(url).not_to be_valid
      end
    end

    it "disallows characters that can't be used in a URL" do
      url = create(:url, to: 'https://google.com')

      ['🤷‍', 'no spaces'].each do |shortcode|
        url.shortened = shortcode
        expect(url).not_to be_valid
      end
    end
  end

  describe 'scopes' do
    it 'returns only my urls with .mine' do
      Url.destroy_all
      user_normal = create(:user)
      create(:url, to: 'https://indigodragonfly.ca/', user: user_normal)
      create(:url, to: 'https://fiberopticyarns.com/')
      create(:url, to: 'https://shop.thebluebrick.ca/', user: create(:user))

      expect(Url.mine(user_normal)).to match_array([Url.first])
    end

    it "returns only others' urls with .not_mine" do
      Url.destroy_all
      user_normal = create(:user)
      create(:url, to: 'https://indigodragonfly.ca/', user: user_normal)
      unowned_urls = [
        create(:url, to: 'https://fiberopticyarns.com/'),
        create(:url, to: 'https://shop.thebluebrick.ca/', user: create(:user))
      ]

      expect(Url.not_mine(user_normal)).to match_array(unowned_urls)
    end
  end

  describe 'search' do
    before do
      create(:url, shortened: 'forty-two', to: 'http://google.com')
    end

    it 'searches .shortened' do
      expect(Url.search('forty-two')).to be_present
      expect(Url.search('forty')).to be_present
      expect(Url.search('FORTY')).to be_present
    end

    it 'searches .to' do
      expect(Url.search('http://google.com')).to be_present
      expect(Url.search('google')).to be_present
      expect(Url.search('GOOG')).to be_present
    end

    it 'handles a nil argument' do
      expect(Url.search(nil)).to eq(Url.all)
    end
  end
end
