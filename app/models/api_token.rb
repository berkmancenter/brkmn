# frozen_string_literal: true

require "openssl"
require "securerandom"

# == Schema Information
#
# Table name: api_tokens
#
#  id               :bigint           not null, primary key
#  access_level     :integer          default("read_only"), not null
#  claim_digest     :string
#  claim_expires_at :datetime
#  claimed_at       :datetime
#  expires_at       :datetime
#  last_used_at     :datetime
#  lifetime_days    :integer
#  name             :string(100)      not null
#  note             :text
#  revoked_at       :datetime
#  token_digest     :string
#  token_prefix     :string(20)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  created_by_id    :bigint
#  revoked_by_id    :bigint
#  user_id          :bigint           not null
#
# Indexes
#
#  index_api_tokens_on_claim_digest   (claim_digest) UNIQUE
#  index_api_tokens_on_created_by_id  (created_by_id)
#  index_api_tokens_on_expires_at     (expires_at)
#  index_api_tokens_on_revoked_at     (revoked_at)
#  index_api_tokens_on_revoked_by_id  (revoked_by_id)
#  index_api_tokens_on_token_digest   (token_digest) UNIQUE
#  index_api_tokens_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (revoked_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class ApiToken < ApplicationRecord
  # A recognizable prefix lets people (and secret scanners) spot leaked tokens.
  SECRET_PREFIX = "brkmn_"
  SECRET_LENGTH = 40
  VISIBLE_PREFIX_LENGTH = SECRET_PREFIX.length + 6
  CLAIM_LINK_LIFETIME = 72.hours
  LAST_USED_PRECISION = 5.minutes
  LIFETIME_CHOICES = [7, 30, 90, 180, 365].freeze
  MAX_LIFETIME_DAYS = 3650

  belongs_to :user
  belongs_to :created_by, class_name: "User", optional: true, inverse_of: :created_api_tokens
  belongs_to :revoked_by, class_name: "User", optional: true, inverse_of: :revoked_api_tokens

  enum :access_level, {read_only: 0, read_write: 1}, validate: true

  validates :name, presence: true, length: {maximum: 100}
  validates :note, length: {maximum: 1_000}
  validates :lifetime_days,
    numericality: {only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_LIFETIME_DAYS},
    allow_nil: true

  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :unrevoked, -> { where(revoked_at: nil) }
  scope :pending, -> { unrevoked.where(token_digest: nil) }
  scope :issued, -> { unrevoked.where.not(token_digest: nil) }
  scope :expired, -> { issued.where(api_tokens: {expires_at: ..Time.current}) }
  scope :active, -> { issued.where("api_tokens.expires_at IS NULL OR api_tokens.expires_at > ?", Time.current) }

  def self.digest(value)
    OpenSSL::Digest::SHA256.hexdigest(value.to_s)
  end

  def self.generate_secret
    "#{SECRET_PREFIX}#{SecureRandom.base58(SECRET_LENGTH)}"
  end

  # Returns the token a presented secret belongs to, whatever its state.
  def self.find_for_secret(secret)
    return if secret.blank?

    find_by(token_digest: digest(secret))
  end

  def self.find_for_claim(claim_token)
    return if claim_token.blank?

    find_by(claim_digest: digest(claim_token))
  end

  def status
    if revoked?
      :revoked
    elsif pending?
      :pending
    elsif expired?
      :expired
    else
      :active
    end
  end

  def usable?
    status == :active
  end

  def revoked?
    revoked_at.present?
  end

  def pending?
    !revoked? && token_digest.nil?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def external?
    user.present? && user.api_only?
  end

  def claimable?
    !revoked? && claim_digest.present? && claim_expires_at.present? && claim_expires_at.future?
  end

  def claim_expired?
    !revoked? && claim_digest.present? && !claimable?
  end

  # Generates a new secret, invalidating any previous one, and restarts the
  # token's lifetime. Returns the plaintext secret, or nil if it can't be saved.
  def issue_secret
    if revoked?
      errors.add(:base, "A revoked token can't be regenerated.")
      return
    end

    secret = self.class.generate_secret
    assign_attributes(
      token_digest: self.class.digest(secret),
      token_prefix: secret.first(VISIBLE_PREFIX_LENGTH),
      expires_at: lifetime_days&.days&.from_now,
      last_used_at: nil,
      claim_digest: nil,
      claim_expires_at: nil
    )
    secret if save
  end

  # Replaces the secret with a single-use claim link. Any current secret stops
  # working. Returns the plaintext claim token, or nil if it can't be saved.
  def issue_claim
    if revoked?
      errors.add(:base, "A revoked token can't be reissued.")
      return
    end

    claim_token = SecureRandom.urlsafe_base64(32)
    assign_attributes(
      token_digest: nil,
      token_prefix: nil,
      expires_at: nil,
      last_used_at: nil,
      claimed_at: nil,
      claim_digest: self.class.digest(claim_token),
      claim_expires_at: CLAIM_LINK_LIFETIME.from_now
    )
    claim_token if save
  end

  # Exchanges a valid claim link for the secret. The row lock makes sure two
  # simultaneous requests can't both collect it.
  def claim(claim_token)
    with_lock do
      next unless claimable?
      next unless ActiveSupport::SecurityUtils.secure_compare(
        claim_digest,
        self.class.digest(claim_token)
      )

      self.claimed_at = Time.current
      issue_secret
    end
  end

  def revoke!(by:)
    return if revoked?

    update!(revoked_at: Time.current, revoked_by: by, claim_digest: nil, claim_expires_at: nil)
  end

  # Records use without a database write on every request.
  def record_use!
    now = Time.current
    updated = self.class
      .where(id: id)
      .where("last_used_at IS NULL OR last_used_at < ?", now - LAST_USED_PRECISION)
      .update_all(last_used_at: now)
    self.last_used_at = now if updated.positive?
  end
end
