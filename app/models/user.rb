require 'berkman_ldap_auth_mixin'

class User < ActiveRecord::Base
  extend BerkmanLdapAuthMixin
end
