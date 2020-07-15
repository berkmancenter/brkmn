# frozen_string_literal: true

require 'test_helper'

class UrlsTest < IntegrationTest
  def setup
    @redirect_url = 'https://scratch.mit.edu/'
    @url = Url.create(to: @redirect_url)
    @user = User.find_or_create_by(username: USERNAME)
    login_as @user
  end

  def teardown
    logout
    Url.destroy_all
  end

  context 'url#show' do
    it 'lets you see a url' do
      visit url_path(@url)

      assert page.has_content?("Full URL: #{@url.to}")
      assert page.has_content?("Shortened URL: #{@url.shortened}")
      assert page.has_content?("Clicks: #{@url.clicks}")
    end
  end

  context 'url#edit' do
    it 'resolves' do
      @user.update(superadmin: true)

      visit edit_url_path(@url)
    end

    it 'lets users see a url they own' do
      @user.update(superadmin: false)
      url = Url.create(
        to: 'http://cyber.law.harvard.edu/getinvolved/internships_summer',
        user: @user
      )

      visit edit_url_path(url)

      assert page.status_code == 200
    end

    it 'lets superadmins see a url they do not own' do
      @user.update(superadmin: true)
      normal = User.where(superadmin: false).first
      url = Url.create(
        to: 'https://cyber.law.harvard.edu/publications/2015/digitallyconnected_globalperspectives',
        user: normal
      )

      visit edit_url_path(url)

      assert page.status_code == 200
    end

    it 'does not let regular users see a url they do not own' do
      @user.update(superadmin: false)
      normal = User.find_by(username: 'normal')
      url = Url.create(
        to: 'http://wilkins.law.harvard.edu/courses/CopyrightX2015/3.3_hi.mp4',
        user: normal
      )

      assert_raises CanCan::AccessDenied do
        visit edit_url_path(url)
      end
    end

    it 'lets you edit the url' do
      url = Url.create(
        to: 'http://cyber.law.harvard.edu/getinvolved/internships_summer',
        user: @user
      )
      new_url = 'https://cyber.harvard.edu/getinvolved/fellowships/opencall20172018'

      visit edit_url_path(url)
      fill_in 'url_to', with: new_url
      click_on 'Update'
      url.reload

      assert url.to == new_url
    end
  end

  context 'index page' do
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
      visit urls_path(search: 'scratch')

      assert page.has_content?('https://scratch.mit.edu/')
      assert page.has_no_content?('https://totallydifferent.domain.com')
      assert page.current_path == search_urls_path
    end

    it "shows you your links separately from everyone else's" do
      my_link = 'https://en.wikipedia.org/wiki/List_of_software_bugs'
      Url.create(
        to: my_link,
        user: @user
      )

      visit urls_path

      within '#my_urls' do
        find_link my_link
        assert find_all('td.to').count == 1
      end

      within '#not_my_urls' do
        find_link @redirect_url
        assert find_all('td.to').count == Url.count - 1
      end
    end
  end

  it 'adds users to urls automatically on url creation' do
    visit urls_path
    fill_in 'URL to shorten', with: 'https://a.new.url'
    click_on 'Shorten'

    assert Url.last.user == @user
  end
end
