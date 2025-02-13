# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                   :integer          not null, primary key
#  confirmation_sent_at :datetime
#  confirmation_token   :string
#  confirmed_at         :datetime
#  email                :string(100)
#  encrypted_password   :string           default(""), not null
#  remember_created_at  :datetime
#  superadmin           :boolean          default(FALSE)
#  unconfirmed_email    :string
#  username             :string(100)      not null
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_users_on_email       (email)
#  index_users_on_superadmin  (superadmin)
#  index_users_on_username    (username)
#

class User < ApplicationRecord
  if Rails.application.config.devise_auth_type == 'cas'
    devise :cas_authenticatable, :rememberable
    before_validation :match_existing_user
  end

  if Rails.application.config.devise_auth_type == 'db'
    devise_modules = [:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :confirmable]
    devise(*devise_modules)

    before_create :set_username
  end

  validates :username, uniqueness: true

  def cas_extra_attributes=(extra_attributes)
    extra_attributes.each do |name, value|
      case name.to_sym
      when :mail
        self.email = value
      end
    end
  end

  def set_username
    self.username = self.email if self.username.blank?
  end

  private

  def match_existing_user
    existing_user = User.where(email: self.email).first

    unless existing_user.nil?
      self.attributes = existing_user.attributes.except('username')
      @new_record = false
    end

    self.encrypted_password = SecureRandom.base64(15) unless self.encrypted_password.present?
  end
end
