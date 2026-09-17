# frozen_string_literal: true

require "securerandom"

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
  has_many :urls, dependent: :nullify
  has_many :url_collaborators, dependent: :destroy
  has_many :granted_url_collaborations,
    class_name: "UrlCollaborator",
    foreign_key: :granted_by_id,
    dependent: :nullify,
    inverse_of: :granted_by
  has_many :shared_urls, through: :url_collaborators, source: :url
  has_many :url_access_requests, dependent: :destroy
  has_many :resolved_url_access_requests,
    class_name: "UrlAccessRequest",
    foreign_key: :resolved_by_id,
    dependent: :nullify,
    inverse_of: :resolved_by
  has_many :edited_urls,
    class_name: "Url",
    foreign_key: :last_edited_by_id,
    dependent: :nullify,
    inverse_of: :last_edited_by

  if Rails.application.config.devise_auth_type == "cas"
    devise :cas_authenticatable, :rememberable
    before_validation :match_existing_user
    before_validation :set_username
  end

  if Rails.application.config.devise_auth_type == "saml"
    devise :saml_authenticatable, :rememberable
    before_validation :match_existing_user
    before_validation :set_username
  end

  if Rails.application.config.devise_auth_type == "headers"
    devise :rememberable
  end

  if Rails.application.config.devise_auth_type == "db"
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

  def apply_saml_response(saml_response, auth_value)
    assign_external_attributes(
      email: saml_value(saml_response, :email) || auth_value,
      username: saml_value(saml_response, :username) || saml_value(saml_response, :display_name)
    )
  end

  def saml_extra_attributes=(extra_attributes)
    assign_external_attributes(
      email: external_attribute_value(extra_attributes, :email, :mail),
      username: external_attribute_value(extra_attributes, :username, :uid, :display_name, :displayName, :name)
    )
  end

  def set_username
    self.username = email if username.blank?
  end

  def self.from_auth_headers(email:, name:)
    normalized_email = email.strip.downcase
    user = where("LOWER(email) = ?", normalized_email).first_or_initialize
    user.email = normalized_email
    user.username = name.strip
    user.set_random_password
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    user.save!
    user
  end

  def set_random_password
    return if encrypted_password.present?

    random_password = SecureRandom.base64(15)
    self.password = random_password if respond_to?(:password=)
    self.encrypted_password = random_password if encrypted_password.blank?
  end

  private

  def assign_external_attributes(email: nil, username: nil)
    self.email = email if email.present?
    self.username = username if username.present? && self.username.blank?
    set_username
  end

  def saml_value(saml_response, key)
    normalize_external_value(saml_response.attribute_value_by_resource_key(key))
  end

  def external_attribute_value(attributes, *keys)
    keys.each do |key|
      value = normalize_external_value(attributes[key] || attributes[key.to_s])
      return value if value.present?
    end

    nil
  end

  def normalize_external_value(value)
    value = value.first if value.respond_to?(:first) && !value.is_a?(String)
    value.to_s.presence
  end

  def match_existing_user
    existing_user = User.where(email: email).first

    unless existing_user.nil?
      self.attributes = existing_user.attributes.except("username")
      @new_record = false
    end

    set_random_password
  end
end
