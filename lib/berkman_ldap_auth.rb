# frozen_string_literal: true

module BerkmanLdapAuth
  gem 'net-ldap'
  require 'net/ldap'
  require 'yaml'

  # See the Brief Introduction to LDAP in the Net::LDAP docs:
  # https://www.rubydoc.info/gems/ruby-net-ldap/Net/LDAP
  def self.authenticate(username, password)
    return User.first if Rails.application.config.use_fakeauth
    return false if password.empty?

    ldap = load_ldap_conf

    ldap_con = initialize_ldap_con(
      ldap['bind_hostname'],
      ldap['bind_port'],
      ldap['bind_username'],
      ldap['bind_password']
    )
    name_filter = Net::LDAP::Filter.eq('sAMAccountName', username)
    dn = ''
    entry = ldap_con.search(
      base: ldap['base_tree'],
      filter: name_filter,
      attributes: ['dn']
    )
    dn = entry.dn

    login_succeeded = false

    unless dn.empty?
      ldap_con = initialize_ldap_con(
        ldap['bind_hostname'],
        ldap['bind_port'],
        dn,
        password
      )
      login_succeeded = true if ldap_con.bind
    end
    login_succeeded
  end

  def self.load_ldap_conf
    YAML.load_file(Rails.root.join(Rails.root, 'config', 'ldap.yml'))
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
