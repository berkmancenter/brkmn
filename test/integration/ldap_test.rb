# frozen_string_literal: true

require 'test_helper'

class LdapTest < IntegrationTest
  before do
    @cached_fakeauth = Rails.application.config.use_fakeauth
    Rails.application.config.use_fakeauth = false
  end

  after do
    Rails.application.config.use_fakeauth = @cached_fakeauth
  end

  context 'fakeauth' do
    it 'returns a user when fakeauth is true' do
      Rails.application.config.use_fakeauth = true

      assert User.authenticate('whoever', 'whatever').is_a? User
    end

    it 'calls out to LDAP when fakeauth is false' do
      mock_ldap = make_mock

      # `expect` requires a return value to be among the arguments but does not
      # check it; we don't care what it is, particularly as we defined it in
      # make_mock so we already know what it will be.
      mock_ldap.expect :search, :anything
      mock_ldap.expect :bind, :anything

      BerkmanLdapAuth.stub :initialize_ldap_con, mock_ldap do
        User.authenticate('whoever', 'whatever')
      end
    end
  end

  context 'User.authenticate from LDAP auth mixin' do
    it 'finds an existing user (where present) on successful auth' do
      mock_ldap = make_mock
      existing_user = User.create(username: 'kermit')

      ldap_user = BerkmanLdapAuth.stub :initialize_ldap_con, mock_ldap do
        User.authenticate('kermit', 'piggy')
      end

      assert existing_user.id == ldap_user.id
    end

    it 'creates a user (where not present) on successful auth' do
      mock_ldap = make_mock
      assert User.where(username: 'statler').empty?

      ldap_user = BerkmanLdapAuth.stub :initialize_ldap_con, mock_ldap do
        User.authenticate('statler', 'waldorf')
      end

      assert ldap_user.is_a? User
      assert ldap_user.username == 'statler'
    end

    it 'does not return a user when auth is unsuccessful' do
      mock_ldap = make_mock(false)
      User.create(username: 'gonzo')

      ldap_user = BerkmanLdapAuth.stub :initialize_ldap_con, mock_ldap do
        User.authenticate('gonzo', 'camilla')
      end

      assert ldap_user.nil?
    end

    it 'does not create a user when auth is unsuccessful' do
      mock_ldap = make_mock(false)
      assert User.where(username: 'animal').empty?

      ldap_user = BerkmanLdapAuth.stub :initialize_ldap_con, mock_ldap do
        User.authenticate('animal', 'drums')
      end

      assert ldap_user.nil?
    end
  end

  it 'lets you log out' do
    skip('need to mock out ldap system')
    authorize

    visit '/'
    assert page.has_content? 'Logged in as'

    click_on 'Logout'

    visit '/'
    assert page.has_no_content? 'Logged in as'
  end

  # Create a mock LDAP entry that we can inject via initialize_ldap_con.
  # We can't use webmock + VCR to record/replay http interactions because LDAP
  # uses TCP, and thus flies beneath what webmock can see.
  def make_mock(successful = true)
    mock = MiniTest::Mock.new

    def mock.search(*)
      # Based on actual data from performing #search against production LDAP.
      [Net::LDAP::Entry.new('CN=Kermit Frog,OU=Muppets,DC=law,DC=harvard,DC=edu')]
    end

    # Yes, this is very weird. `successful` isn't defined inside of
    # def mock.bind, so we can't just return it.
    if successful
      def mock.bind; true; end
    else
      def mock.bind; false; end
    end

    mock
  end
end
