# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Urls', type: :feature do
  let(:redirect_url) { 'https://scratch.mit.edu/' }
  let!(:url) { Url.create(to: redirect_url) }
  let!(:user) { User.find_or_create_by(username: USERNAME) }

  before do
    sign_in(user)
  end

  after do
    sign_out
    Url.destroy_all
  end

  describe 'url#show' do
    it 'lets you see a url' do
      visit url_path(url)

      expect(page).to have_content("Full URL: #{url.to}")
      expect(page).to have_content("Shortened URL: #{url.shortened}")
      expect(page).to have_content("Clicks: #{url.clicks}")
    end
  end

  describe 'url#edit' do
    context 'when user is superadmin' do
      before { user.update(superadmin: true) }

      it 'allows to visit edit page' do
        visit edit_url_path(url)
        expect(page).to have_current_path(edit_url_path(url))
      end

      it 'lets superadmins see a url they do not own' do
        normal_user = User.where(superadmin: false).first
        url = Url.create(
          to: 'https://cyber.law.harvard.edu/publications/2015/digitallyconnected_globalperspectives',
          user: normal_user
        )

        visit edit_url_path(url)
        expect(page.status_code).to eq(200)
      end

      it 'lets superadmins delete a url they do not own' do
        normal_user = User.where(superadmin: false).first
        url = Url.create(
          to: 'http://cyber.law.harvard.edu/getinvolved/internships_summer',
          user: normal_user
        )
        orig_id = url.id

        page.driver.delete url_path(url)
        expect(Url.where(id: orig_id)).to be_empty
      end
    end

    context 'when user is not superadmin' do
      before { user.update(superadmin: false) }

      it 'lets users see a url they own' do
        url = Url.create(
          to: 'http://cyber.law.harvard.edu/getinvolved/internships_summer',
          user: user
        )

        visit edit_url_path(url)
        expect(page.status_code).to eq(200)
      end

      it 'does not let regular users see a url they do not own' do
        normal_user = User.find_by(username: 'normal')
        url = Url.create(
          to: 'http://wilkins.law.harvard.edu/courses/CopyrightX2015/3.3_hi.mp4',
          user: normal_user
        )

        expect {
          visit edit_url_path(url)
        }.to raise_error(CanCan::AccessDenied)
      end

      it 'lets you edit the url' do
        url = Url.create(
          to: 'http://cyber.law.harvard.edu/getinvolved/internships_summer',
          user: user
        )
        new_url = 'https://cyber.harvard.edu/getinvolved/fellowships/opencall20172018'

        visit edit_url_path(url)
        fill_in 'url_to', with: new_url
        click_on 'Update'
        url.reload

        expect(url.to).to eq(new_url)
      end
    end
  end

  describe 'url#delete' do
    context 'when user is not superadmin' do
      before { user.update(superadmin: false) }

      it 'lets users delete a url they own' do
        url = Url.create(
          to: 'http://cyber.law.harvard.edu/getinvolved/internships_summer',
          user: user
        )
        orig_id = url.id

        page.driver.delete url_path(url)
        expect(Url.where(id: orig_id)).to be_empty
      end

      it 'does not let regular users delete a url they do not own' do
        normal_user = User.find_by(username: 'normal')
        url = Url.create(
          to: 'http://wilkins.law.harvard.edu/courses/CopyrightX2015/3.3_hi.mp4',
          user: normal_user
        )

        expect {
          page.driver.delete url_path(url)
        }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe 'index page' do
    it 'lets you create a URL on the index page' do
      orig_count = Url.count

      visit urls_path
      fill_in 'URL to shorten', with: 'https://a.new.url'
      click_on 'Shorten'

      expect(Url.count).to eq(orig_count + 1)
      expect(Url.where(to: 'https://a.new.url')).to be_present
    end

    it 'lets you create a URL with a specific shortcode on the index page' do
      orig_count = Url.count

      visit urls_path
      fill_in 'URL to shorten', with: 'https://a.new.url'
      fill_in 'OPTIONAL: shorten to. . . ', with: 'new'
      click_on 'Shorten'

      expect(Url.count).to eq(orig_count + 1)
      expect(Url.where(to: 'https://a.new.url', shortened: 'new')).to be_present
    end

    it 'shows you the list of URLs on the index page' do
      visit urls_path

      Url.all.each do |url|
        expect(page).to have_content(url.to)
      end
    end

    it 'lets you search for URLs on the index page' do
      Url.create(to: 'https://totallydifferent.domain.com')

      visit urls_path
      fill_in 'my_urls_search', with: 'scratch'
      click_on 'my_urls_search_button'

      expect(page).to have_content('https://scratch.mit.edu/')
      expect(page).not_to have_content('https://totallydifferent.domain.com')
    end

    it 'redirects from index to search when search in params' do
      Url.create(to: 'https://totallydifferent.domain.com')
      visit urls_path(search: 'scratch')

      expect(page).to have_content('https://scratch.mit.edu/')
      expect(page).not_to have_content('https://totallydifferent.domain.com')
      expect(page).to have_current_path(search_urls_path(search: 'scratch'))
    end

    it "shows you your links separately from everyone else's" do
      my_link = 'https://en.wikipedia.org/wiki/List_of_software_bugs'
      Url.create(
        to: my_link,
        user: user
      )

      visit urls_path

      within '#my_urls' do
        find_link my_link
        expect(find_all('td.to').count).to eq(1)
      end

      within '#not_my_urls' do
        find_link redirect_url
        expect(find_all('td.to').count).to eq(Url.count - 1)
      end
    end
  end

  it 'adds users to urls automatically on url creation' do
    visit urls_path
    fill_in 'URL to shorten', with: 'https://a.new.url'
    click_on 'Shorten'

    expect(Url.last.user).to eq(user)
  end
end
