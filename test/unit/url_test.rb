require 'test_helper'

class UrlTest < ActiveSupport::TestCase
  test 'URL requirements' do
    @url = Url.new(shortened: 'foobar', to: 'http://google.com')
    assert @url.valid?, 'Should have been valid'

    @url = Url.new(shortened: 'foobar', to: 'hp://google.com')
    assert !@url.valid?, 'Should not have been valid'

    @url = Url.new(shortened: nil, to: 'http://google.com')
    assert @url.valid?, 'Auto generated'
  end

  test 'URL ownership' do
    urls = Url.mine(users(:normal))
    assert urls.length == 2, "The normal user didn't have 2 links"

    urls = Url.mine(users(:admin))
    assert urls.length == 3, "The superadmin couldn't see their three links"

    urls = Url.mine(users(:secondnormal))
    assert urls.length.zero?, 'The second normal user had links.'
  end

  test 'Auto URL generation' do
    Url.find_by_sql("select setval('urls_id_seq', 5,TRUE)")

    u = Url.new(to: 'http://www.google.com')
    assert u.save, "Couldn't save auto generated URL"
    assert u.shortened == '6', "Didn't look like what we wanted."

    u2 = Url.new(to: 'http://www.google.com')
    assert u2.save, "Couldn't save auto generated URL"
    assert u2.shortened == '7', "Didn't look like what we wanted."
  end
end
