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

    urls = Url.viewable(users(:admin))
    assert urls.length == 4, "The superadmin couldn't see all the links"

    urls = Url.viewable(users(:secondnormal))
    assert urls.length == 2, "The second normal user didn't see the proper number of links"

  end
end
