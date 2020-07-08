# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  email      :string(100)
#  superadmin :boolean          default(FALSE)
#  username   :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_users_on_email       (email)
#  index_users_on_superadmin  (superadmin)
#  index_users_on_username    (username)
#
require 'berkman_ldap_auth_mixin'

class User < ApplicationRecord
  extend BerkmanLdapAuthMixin
end
