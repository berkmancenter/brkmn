# frozen_string_literal: true

# == Schema Information
#
# Table name: urls
#
#  id         :integer          not null, primary key
#  auto       :boolean          default(TRUE)
#  clicks     :integer          default(0)
#  shortened  :string(255)
#  to         :string(10240)    not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  index_urls_on_auto       (auto)
#  index_urls_on_clicks     (clicks)
#  index_urls_on_shortened  (shortened)
#  index_urls_on_to         (to)
#  index_urls_on_user_id    (user_id)
#
require 'test_helper'

describe Url do
  describe '.to' do
    it 'must be present' do
      @url = Url.new(shortened: 'foobar', to: nil)
      assert_not @url.valid?, 'Empty :to was allowed'
    end

    it 'validates URLs' do
      @url = Url.new(to: 'https://ex ample.com')
      assert_not @url.valid?, 'invalid URLs should not be allowed'
    end

    it 'does not allow localhost' do
      @url = Url.new(to: 'http://localhost.com')
      assert_not @url.valid?, 'localhost should not have been allowed'

      @url = Url.new(to: 'https://localhost.com')
      assert_not @url.valid?, 'localhost should not have been allowed'
    end

    it 'does not allow brk.mn, no infinite redirects for you' do
      @url = Url.new(to: 'http://brk.mn')
      assert_not @url.valid?, 'brk.mn should not have been allowed'

      @url = Url.new(to: 'https://brk.mn')
      assert_not @url.valid?, 'brk.mn should not have been allowed'
    end

    it 'ensures that the protocol appears in the URL exactly once' do
      # Well-formed case: keep the protocol you're given.
      url = Url.create(shortened: 'foobar', to: 'http://google.com')
      assert url.to == 'http://google.com'

      url = Url.create(shortened: 'foobar', to: 'https://google.com')
      assert url.to == 'https://google.com'

      # No protocol given: add one.
      url = Url.create(shortened: 'foobar', to: 'google.com')
      assert url.to == 'https://google.com'

      # Protocol given twice, e.g. due to both form and user supplying it;
      # use only one. (The last one, as that is likely the one copy-pasted
      # in by the user.)
      url = Url.create(shortened: 'foobar', to: 'http://http://google.com')
      assert url.to == 'http://google.com'

      url = Url.create(shortened: 'foobar', to: 'http://https://google.com')
      assert url.to == 'https://google.com'

      url = Url.create(shortened: 'foobar', to: 'https://http://google.com')
      assert url.to == 'http://google.com'

      url = Url.create(shortened: 'foobar', to: 'https://https://google.com')
      assert url.to == 'https://google.com'
    end
  end

  describe '.shortened on creation' do
    it 'autocreates if left blank' do
      @url = Url.create(shortened: nil, to: 'http://google.com')
      assert @url.shortened.present?
    end

    it 'generates shortcodes' do
      ActiveRecord::Base.connection.execute("select setval('urls_id_seq', 5, TRUE)")

      u = Url.new(to: 'http://www.google.com', user: users(:normal))
      assert u.save, "Couldn't save auto generated URL"
      assert u.shortened == '6', "Expected shortcode to be 6; was #{u.shortened}."

      u2 = Url.new(to: 'http://www.google.com', user: users(:normal))
      assert u2.save, "Couldn't save auto generated URL"
      assert u2.shortened == '7', "Expected shortcode to be 6; was #{u.shortened}."
    end

    it 'disallows shortcodes already in the system' do
      shortcode = '42'
      Url.create(shortened: shortcode, to: 'http://google.com', user: users(:normal))

      @url = Url.new(shortened: shortcode, to: 'https://google.com', user: users(:normal))
      assert_not @url.valid?, 'Should not allow reuse of existing shortcodes'
    end

    it 'disallows protected URL regex elements' do
      # Check expectation
      assert PROTECTED_URL_REGEX == /^(url|user|metric|redirector|preview|logout)/i

      assert_not Url.new(shortened: 'url', to: 'https://google.com', user: users(:normal)).valid?,
                 'shortcode cannot begin with `url`'

      assert_not Url.new(shortened: 'user', to: 'https://google.com', user: users(:normal)).valid?,
                 'shortcode cannot begin with `user`'

      assert_not Url.new(shortened: 'metric', to: 'https://google.com', user: users(:normal)).valid?,
                 'shortcode cannot begin with `metric`'

      assert_not Url.new(shortened: 'redirector7', to: 'https://google.com').valid?,
                 'shortcode cannot begin with `redirector`'

      assert_not Url.new(shortened: 'preview_yay', to: 'https://google.com').valid?,
                 'shortcode cannot begin with `preview`'

      assert_not Url.new(shortened: 'logoutlogout', to: 'https://google.com').valid?,
                 'shortcode cannot begin with `logout`'
    end

    it "disallows characters that can't be used in a URL" do
      assert_not Url.new(shortened: '🤷‍', to: 'https://google.com').valid?,
                 'shortcode cannot contain invalid URL characters'

      assert_not Url.new(shortened: 'no spaces', to: 'https://google.com').valid?,
                 'shortcode cannot contain invalid URL characters'
    end
  end

  describe '.shortened on update' do
    it 'handles blank codes' do
      url = Url.create(shortened: '42', to: 'http://google.com')
      url.shortened = ''
      url.save
      url.reload
      assert url.shortened.present?, 'should not delete shortcode on update'
    end

    it 'does not allow duplicates' do
      url1 = Url.new(
        shortened: 'url1',
        to: 'http://www.google.com'
      )
      # protected attributes can't be set via #create.
      url1.user_id = users(:normal).id
      url1.save

      url2 = Url.new(
        shortened: 'url2',
        to: 'http://www.google.com'
      )
      url2.user_id = users(:normal).id
      url1.save

      url1.shortened = 'url2'

      assert_not url1.valid?
    end

    it 'disallows protected URL regex elements' do
      # Check expectation
      assert PROTECTED_URL_REGEX == /^(url|user|metric|redirector|preview|logout)/i

      url = Url.create(to: 'https://google.com')

      url.shortened = 'url'
      assert_not url.valid?, 'shortcode cannot begin with `url`'

      url.shortened = 'user'
      assert_not url.valid?, 'shortcode cannot begin with `user`'

      url.shortened = 'metric'
      assert_not url.valid?, 'shortcode cannot begin with `metric`'

      url.shortened = 'redirector7'
      assert_not url.valid?, 'shortcode cannot begin with `redirector`'

      url.shortened = 'preview_yay'
      assert_not url.valid?, 'shortcode cannot begin with `preview`'

      url.shortened = 'logoutlogout'
      assert_not url.valid?, 'shortcode cannot begin with `logout`'
    end

    it "disallows characters that can't be used in a URL" do
      url = Url.create(to: 'https://google.com')

      url.shortened = '🤷‍'
      assert_not url.valid?, 'shortcode cannot contain invalid URL characters'

      url.shortened = 'no spaces'
      assert_not url.valid?, 'shortcode cannot contain invalid URL characters'
    end
  end

  describe 'scopes' do
    it 'returns only my urls with .mine' do
      Url.destroy_all
      u1 = Url.create(to: 'https://indigodragonfly.ca/', user: users(:normal))
      u2 = Url.create(to: 'https://fiberopticyarns.com/')
      u3 = Url.create(to: 'https://shop.thebluebrick.ca/', user: users(:secondnormal))

      assert Url.mine(users(:normal)).to_a == [u1]
    end

    it "returns only others' urls with .not_mine" do
      Url.destroy_all
      u1 = Url.create(to: 'https://indigodragonfly.ca/', user: users(:normal))
      u2 = Url.create(to: 'https://fiberopticyarns.com/')
      u3 = Url.create(to: 'https://shop.thebluebrick.ca/', user: users(:secondnormal))

      assert Url.not_mine(users(:normal)).to_a == [u2, u3]
    end
  end

  describe 'search' do
    it 'searches .shortened' do
      Url.create(shortened: 'forty-two', to: 'http://google.com')

      assert Url.search('forty-two').present?, 'it should find whole terms'
      assert Url.search('forty').present?, 'it should find substrings'
      assert Url.search('FORTY').present?, 'it should be case insensitive'
    end

    it 'searches .to' do
      Url.create(shortened: 'forty-two', to: 'http://google.com')

      assert Url.search('http://google.com').present?, 'it should find whole terms'
      assert Url.search('google').present?, 'it should find substrings'
      assert Url.search('GOOG').present?, 'it should be case insensitive'
    end

    it 'handles a nil argument' do
      Url.create(shortened: 'forty-two', to: 'http://google.com')

      assert Url.search(nil) == Url.all, 'nil search did not return properly'
    end
  end
end
