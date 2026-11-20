# frozen_string_literal: true

# == Schema Information
#
# Table name: urls
#
#  id                :integer          not null, primary key
#  auto              :boolean          default(TRUE)
#  clicks            :integer          default(0)
#  last_edited_at    :datetime
#  shortened         :string(255)
#  to                :string(10240)    not null
#  created_at        :datetime
#  updated_at        :datetime
#  last_edited_by_id :bigint
#  user_id           :integer
#
# Indexes
#
#  index_urls_on_auto               (auto)
#  index_urls_on_clicks             (clicks)
#  index_urls_on_last_edited_by_id  (last_edited_by_id)
#  index_urls_on_shortened          (shortened) UNIQUE
#  index_urls_on_to                 (to)
#  index_urls_on_user_id            (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (last_edited_by_id => users.id)
#
class Url < ApplicationRecord
  include ActiveModel::Validations

  SHARING_ASSOCIATIONS = [
    :user,
    {url_collaborators: :user, url_access_requests: :user}
  ].freeze

  # One or more http(s):// at the start, e.g. "https://http://example.com".
  LEADING_PROTOCOLS = %r{\A(?:https?://)+}i
  OTHER_SCHEME = %r{\A[a-z][a-z0-9+.-]*://}i

  belongs_to :user, optional: true
  belongs_to :last_edited_by, class_name: "User", optional: true, inverse_of: :edited_urls

  has_many :url_collaborators, dependent: :destroy
  has_many :collaborators, through: :url_collaborators, source: :user
  has_many :url_access_requests, dependent: :destroy

  before_create :generate_url

  validates :to, length: { maximum: 10.kilobytes }, allow_blank: false
  validates :to, presence: true
  validate :to do
    errors.add(:to, "cannot be 'localhost' or '#{REDIRECT_DOMAIN}'.") if
      to&.match(PROTECTED_REDIRECT_REGEX)
    errors.add(:to, 'must be a valid url') unless to.blank? || valid_url?(to)
  end
  validates :shortened, shortcode: true, on: %i[create update]

  scope :auto, -> { where(auto: true) }
  scope :with_sharing, -> { includes(*SHARING_ASSOCIATIONS) }
  scope :with_sharing_details, -> { with_sharing.includes(:last_edited_by) }

  def self.mine(user)
    shared_url_ids = UrlCollaborator.where(user_id: user.id).select(:url_id)
    where(user_id: user.id).or(where(id: shared_url_ids))
  end

  def self.not_mine(user)
    where.not(id: mine(user).select(:id))
  end

  def owned_by?(candidate)
    candidate.present? && user_id == candidate.id
  end

  def editable_by?(candidate)
    return false if candidate.blank?

    candidate.superadmin? || owned_by?(candidate) ||
      url_collaborators.any? { |collaboration| collaboration.user_id == candidate.id }
  end

  def grant_edit_access_to(collaborator, granted_by:)
    url_collaborators.create_with(granted_by: granted_by).find_or_create_by!(user: collaborator)
  rescue ActiveRecord::RecordNotUnique
    url_collaborators.find_by!(user: collaborator)
  end

  def update_with_editor(attributes, editor:)
    assign_attributes(attributes)
    destination_changed = will_save_change_to_to?
    return false unless valid?

    if destination_changed
      self.last_edited_by = editor
      self.last_edited_at = Time.current
    end

    save
  end

  def self.search(search)
    if search
      pattern = "%#{sanitize_sql_like(search.to_s)}%"
      where('lower(shortened) like lower(?) OR lower("to") like lower(?)', pattern, pattern)
    else
      all
    end
  end

  # Don't let shortcodes be overwritten with blank data.
  def shortened=(value)
    return if value.blank?

    super
  end

  # Ensure protocol appears exactly once at the start. Only the start is
  # touched, URLs in the query (?next=https://...) stay as they are.
  def to=(value)
    value = normalize_destination(value) if value.is_a?(String) && value.present?

    super
  end

  private

  def normalize_destination(value)
    value = value.strip
    leading = value[LEADING_PROTOCOLS]
    rest = value.delete_prefix(leading.to_s)

    if leading
      "#{leading.scan(%r{https?://}i).last.downcase}#{rest}"
    elsif rest.match?(OTHER_SCHEME)
      rest # ftp:// and friends, left for the validation to reject
    else
      "https://#{rest}"
    end
  end

  def valid_url?(url)
    uri = URI.parse(url.to_s)
    uri.is_a?(URI::HTTP) && uri.host.present?
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
