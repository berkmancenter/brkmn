# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  email               :string(100)
#  encrypted_password  :string           default(""), not null
#  remember_created_at :datetime
#  superadmin          :boolean          default(FALSE)
#  username            :string(100)      not null
#  created_at          :datetime
#  updated_at          :datetime
#
# Indexes
#
#  index_users_on_email       (email)
#  index_users_on_superadmin  (superadmin)
#  index_users_on_username    (username)
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, authentication_keys: [:username]
  validates :username, uniqueness: true
end
