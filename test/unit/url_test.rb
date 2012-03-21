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

    urls = Url.viewable(users(:normal))
    assert urls.length == 3, "The normal user didn't have 3 links"

#    urls = Url.viewable(admin_user)
#    assert urls.length == 3

  end
end
