# frozen_string_literal: true

require 'test_helper'

# It's really hard to test the authenticate! method on the strategy, so we
# test that LdapQuery.authenticatable? works as expected, and leave a hole
# around checking that Devise::Strategies::LdapAuthenticatable relies on it.
class LdapAuthTest < IntegrationTest
  def setup
    @cached_fakeauth = Rails.application.config.use_fakeauth
    Rails.application.config.use_fakeauth = false
  end

  def teardown
    Rails.application.config.use_fakeauth = @cached_fakeauth
    logout
  end

  context 'fakeauth' do
    it 'returns true when fakeauth is true' do
      Rails.application.config.use_fakeauth = true

      assert LdapQuery.new('username', 'password').authenticatable?
    end

    it 'calls out to LDAP when fakeauth is false' do
      mock_ldap = make_mock
      username = 'normal'
      password = 'whatever'

      # `expect` requires a return value to be among the arguments but does not
      # check it; we don't care what it is, particularly as we defined it in
      # make_mock so we already know what it will be.
      mock_ldap.expect :search, :anything
      mock_ldap.expect :bind, :anything

      stubbed_query = LdapQuery.new(username, password)
      stubbed_query.stub :initialize_ldap_conn, mock_ldap do
        stubbed_query.authenticatable?
      end
    end
  end

  context 'ldap querying' do
    it 'finds an existing user (where present) on successful auth' do
      username = 'kermit'
      password = 'piggy'
      existing_user = User.create(username: username)
      mock_ldap_query = MiniTest::Mock.new

      mock_ldap_query.expect(:authenticatable?, true)

      LdapQuery.stub(:new, mock_ldap_query) do
        visit new_user_session_path

        fill_in 'user_username', with: username
        fill_in 'user_password', with: password
        click_on 'Log in'

        # This is a super janky way to test that the login succeeded but we
        # can't actually grab the page context. 🤷‍♀️
        assert page.has_content? "Logged in as #{username}"
      end
    end

    it 'creates a user (where not present) on successful auth' do
      mock_ldap_query = MiniTest::Mock.new
      username = 'statler'
      password = 'waldorf'

      assert User.where(username: username).empty?
      mock_ldap_query.expect(:authenticatable?, true)

      LdapQuery.stub(:new, mock_ldap_query) do
        visit new_user_session_path

        fill_in 'user_username', with: username
        fill_in 'user_password', with: password
        click_on 'Log in'

        assert page.has_content? "Logged in as #{username}"
        assert User.find_by(username: username).present?
      end
    end

    it 'does not return a user when auth is unsuccessful' do
      mock_ldap_query = MiniTest::Mock.new
      username = 'gonzo'
      password = 'camilla'

      mock_ldap_query.expect(:authenticatable?, false)

      LdapQuery.stub(:new, mock_ldap_query) do
        visit new_user_session_path

        fill_in 'user_username', with: username
        fill_in 'user_password', with: password
        click_on 'Log in'

        assert page.has_no_content? "Logged in as #{username}"
        assert page.current_path == new_user_session_path
      end
    end

    it 'does not create a user when auth is unsuccessful' do
      username = 'animal'
      password = 'drums'
      assert User.where(username: username).empty?
      mock_ldap_query = MiniTest::Mock.new

      mock_ldap_query.expect(:authenticatable?, false)

      LdapQuery.stub(:new, mock_ldap_query) do
        visit new_user_session_path

        fill_in 'user_username', with: username
        fill_in 'user_password', with: password
        click_on 'Log in'

        assert page.has_no_content? "Logged in as #{username}"
        assert User.where(username: username).empty?
      end
    end
  end

  it 'lets you log out' do
    login_as User.find_by(username: 'normal')

    visit '/'
    assert page.has_content? 'Logged in as'

    click_on 'Logout'

    visit '/'
    assert page.has_no_content? 'Logged in as'
  end

  # Create a mock LDAP entry that we can inject via initialize_ldap_conn.
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
