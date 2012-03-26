require 'test_helper'

class UrlTest < ActiveSupport::TestCase
  test 'URL requirements' do
    @url = Url.new(:from => 'foobar', :to => 'http://google.com')
    assert @url.valid?, 'Should have been valid'

    @url = Url.new(:from => 'foobar', :to => 'hp://google.com')
    assert ! @url.valid?, 'Should not have been valid'

    @url = Url.new(:from => nil, :to => 'http://google.com')
    assert @url.valid?, 'Auto generated'
  end

  test 'URL ownership' do

    urls = Url.mine(users(:normal))
    assert urls.length == 2, "The normal user didn't have 2 links"

    urls = Url.mine(users(:admin))
    assert urls.length == 3, "The superadmin couldn't see their three links"

    urls = Url.mine(users(:secondnormal))
    assert urls.length == 0, "The second normal user had links."

  end

  test 'Auto URL generation' do

    u = Url.new(:to => 'http://www.google.com')
    assert u.save, "Couldn't save auto generated URL"
    puts "from is: " + u.from
    assert u.from == '7', "Didn't look like what we wanted."

    u2 = Url.new(:to => 'http://www.google.com')
    assert u2.save, "Couldn't save auto generated URL"
    puts "second from is: " + u2.from
    assert u2.from == 'c', "Didn't look like what we wanted."

  end

end
