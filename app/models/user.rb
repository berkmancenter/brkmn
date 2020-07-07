# frozen_string_literal: true

require 'berkman_ldap_auth_mixin'

class User < ApplicationRecord
  extend BerkmanLdapAuthMixin
end
