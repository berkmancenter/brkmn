# frozen_string_literal: true

# == Schema Information
#
# Table name: urls
#
#  id         :integer          not null, primary key
#  auto       :boolean          default(TRUE)
#  clicks     :integer          default(0)
#  shortened  :string(255)
#  to         :string(10240)    not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  index_urls_on_auto       (auto)
#  index_urls_on_clicks     (clicks)
#  index_urls_on_shortened  (shortened)
#  index_urls_on_to         (to)
#  index_urls_on_user_id    (user_id)
#
class Url < ApplicationRecord
  include ActiveModel::Validations

  belongs_to :user, optional: true

  before_create :generate_url

  validates :to, length: { maximum: 10.kilobytes }, allow_blank: false
  validates :to, presence: true
  validate :to do
    errors.add(:to, "cannot be 'localhost' or '#{REDIRECT_DOMAIN}'.") if
      to&.match(PROTECTED_REDIRECT_REGEX)
    errors.add(:to, 'must be a valid url') unless valid_url?(to)
  end
  validates :shortened, shortcode: true, on: %i[create update]

  scope :auto, -> { where(auto: true) }
  scope :mine, ->(u) { where(user_id: u.id) }
  scope :not_mine, ->(u) {
    where.not(user_id: u.id).or(Url.default_scoped.where(user_id: nil))
  }

  def self.search(search)
    if search
      where(
        'lower(shortened) like lower(?) OR lower("to") like lower(?)',
        "%#{search}%", "%#{search}%"
      )
    else
      all
    end
  end

  # Don't let shortcodes be overwritten with blank data.
  def shortened=(value)
    return if value.blank?

    super
  end

  # Ensure protocol appears exactly once.
  def to=(value)
    if value.present?
      protocols = value.scan(%r{https?://})
      protocol = protocols.last || 'https://'

      base_url = value.gsub(%r{https?://}, '')
      value = "#{protocol}#{base_url}"
    end

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
      self.shortened = create_shortcode
    end
  end

  def create_shortcode
    shortened = random_shortcode

    until Url.where(shortened: shortened).empty?
      shortened = random_shortcode
    end

    shortened
  end

  def suffix
    # These will never be used by Base32 encoding, so it's pretty unlikely
    # they'll occur giving us a high probability of matching with only one
    # character.
    %w[i l o u].sample
  end

  def random_shortcode
    (0...6).map { (65 + rand(26)).chr }.join
  end
end
