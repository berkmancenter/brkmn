# frozen_string_literal: true

class LdapQuery
  # See the Brief Introduction to LDAP in the Net::LDAP docs:
  # https://www.rubydoc.info/gems/ruby-net-ldap/Net/LDAP

  def initialize(username, password)
    @username = username
    @password = password
    @login_succeeded = false
    @dn = nil
    @ldap ||= YAML.load_file(Rails.root.join(Rails.root, 'config', 'ldap.yml'))
  end
  attr_reader :username, :password, :ldap
  attr_accessor :login_succeeded, :dn

  def authenticatable?
    # Run checks.
    return true if Rails.application.config.use_fakeauth
    return false if password.empty?

    # The overall series of steps:
    # - connect to LDAP server with application credentials
    # - query for dn ("distinguished name")
    # - if the dn is found, connect to LDAP server with user credentials
    # - return success or failure of that connection
    bind_user if dn_found?

    login_succeeded
  end

  def initialize_ldap_conn(host, port, user, pass)
    Net::LDAP.new(
      port: port,
      host: host,
      encryption: :simple_tls,
      auth: {
        method: :simple,
        username: user,
        password: pass
      }
    )
  end

  private

  def search_connection
    initialize_ldap_conn(
      ldap['bind_hostname'],
      ldap['bind_port'],
      ldap['bind_username'],
      ldap['bind_password']
    )
  end

  def bind_user
    ldap_connection = initialize_ldap_conn(
      ldap['bind_hostname'],
      ldap['bind_port'],
      dn,
      password
    )

    login_succeeded = true if ldap_connection.bind
  end

  def dn_found?
    result = search_connection.search(
      base: ldap['base_tree'],
      filter: name_filter,
      attributes: ['dn']
    )

    dn = extract_entry(result).dn

    dn.present?
  end

  def name_filter
    Net::LDAP::Filter.eq('sAMAccountName', username)
  end

  def extract_entry(result)
    case result
    when Array
      result.first
    else
      result
    end
  end
end
