require 'test_helper'

class UrlTest < ActiveSupport::TestCase
  test 'URL requirements' do
    @url = Url.new(:from => 'foobar', :to => 'http://google.com')
    assert @url.valid?

    @url = Url.new(:from => 'foobar', :to => 'hp://google.com')
    assert ! @url.valid?

    @url = Url.new(:from => nil, :to => 'http://google.com')
    assert ! @url.valid?
  end

  test 'URL Accessibility' do
    normal_user = User.create(:email => 'foo@example.com')
    normal_user.username = 'foobar'
    assert normal_user.save

    admin_user = User.create(:email => 'fooadmin@example.com')
    admin_user.username = 'fooadmin'
    admin_user.superadmin = true
    assert admin_user.save

    url = Url.new(:from => 'public', :to => 'http://google.com', :public => true)
    url.user = normal_user
    assert url.save

    url = Url.new(:from => 'private', :to => 'http://google.com', :public => false)
    url.user = normal_user
    assert url.save

    url = Url.new(:from => 'adminprivate', :to => 'http://google.com', :public => false)
    url.user = admin_user
    assert url.save

    urls = Url.viewable(normal_user)
    assert urls.length == 2

#    urls = Url.viewable(admin_user)
#    assert urls.length == 3

  end
end
