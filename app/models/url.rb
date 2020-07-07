# frozen_string_literal: true

class Url < ApplicationRecord
  include ActiveModel::Validations

  belongs_to :user, optional: true

  before_create :generate_url

  validates :to, length: { maximum: 10.kilobytes }, allow_blank: false
  validates :to, format: { with: %r{\Ahttps?://.+}i.freeze, message: 'should begin with http:// or https:// and contain a valid URL' }
  validates :shortened, shortcode: true, on: %i[create update]

  URL_FORMAT = %r{^[a-z\d/_]+$}i.freeze

  scope :auto, -> { where(auto: true) }
  scope :mine, proc { |u| where(['user_id = ?', u.id]) }

  validate :to do
    # rubocop:disable Style/IfUnlessModifier
    if to.blank?
      errors.add(:to, 'Target URL must be present.')
    end
    if to&.match(PROTECTED_REDIRECT_REGEX)
      errors.add(:to, "cannot be 'localhost' or 'brk.mn'.")
    end
    unless valid_url?(to&.delete 'https://', 'http://')
      errors.add(:to, 'is not a valid URL and contains invalid characters.')
    end
    # rubocop:enable Style/IfUnlessModifier
  end

  def self.all_owners
    %w[Others Mine]
  end

  def self.search(search)
    if search
      where('lower(shortened) like lower(?) OR lower("to") like lower(?)', "%#{search}%", "%#{search}%")
    else
      all
    end
  end

  # Don't let shortcodes be overwritten with blank data.
  def shortened=(value)
    return if value.blank?

    super
  end

  private

  def valid_url?(url)
    !!URI.parse(url)
  rescue URI::InvalidURIError
    false
  end

  def generate_url
    if shortened.present?
      self.auto = false
    else
      self.auto = true
      create_shortcode
    end
  end

  def create_shortcode
    self.shortened = base_shortcode

    self.shortened += suffix until Url.where(shortened: shortened).empty?
  end

  def suffix
    # These will never be used by Base32 encoding, so it's pretty unlikely
    # they'll occur giving us a high probability of matching with only one
    # character.
    %w[i l o u].sample
  end

  def base_shortcode
    # This is not guaranteed to work, due e.g. to race conditions; only the
    # database can provide ACID guarantees. We need to actually create a Url
    # to be certain of what its ID will be. For a low-usage system this is
    # probably good enough, though.
    next_id = Url.last.id + 1
    Base32::Crockford.encode(next_id).downcase
  end
end
