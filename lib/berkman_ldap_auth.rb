# frozen_string_literal: true

module BerkmanLdapAuth
  # See the Brief Introduction to LDAP in the Net::LDAP docs:
  # https://www.rubydoc.info/gems/ruby-net-ldap/Net/LDAP
  def self.authenticate(username, password)
    # Run checks.
    return User.first if Rails.application.config.use_fakeauth
    return false if password.empty?

    # Initialize variables.
    @username = username
    @password = password
    @login_succeeded = false

    # The overall series of steps:
    # - connect to LDAP server with application credentials
    # - query for dn ("distinguished name")
    # - if the dn is found, connect to LDAP server with user credentials
    # - return success or failure of that connection
    bind_user if dn_found?

    @login_succeeded
  end

  def self.ldap
    @ldap ||= YAML.load_file(Rails.root.join(Rails.root, 'config', 'ldap.yml'))
  end

  def self.search_connection
    initialize_ldap_con(
      ldap['bind_hostname'],
      ldap['bind_port'],
      ldap['bind_username'],
      ldap['bind_password']
    )
  end

  def self.bind_user
    ldap_connection = initialize_ldap_con(
      ldap['bind_hostname'],
      ldap['bind_port'],
      @dn,
      @password
    )

    @login_succeeded = true if ldap_connection.bind
  end

  def self.dn_found?
    name_filter = Net::LDAP::Filter.eq('sAMAccountName', @username)

    result = search_connection.search(
      base: ldap['base_tree'],
      filter: name_filter,
      attributes: ['dn']
    )

    @dn = extract_entry(result).dn

    @dn.present?
  end

  def self.extract_entry(result)
    case result
    when Array
      result.first
    else
      result
    end
  end

  def self.initialize_ldap_con(host, port, user, pass)
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
end
