require 'base32/crockford'
require 'uri'
class Url < ActiveRecord::Base
  validates_presence_of :to

  validates_length_of :to, maximum: 10.kilobytes, allow_blank: false
  validates_format_of :to, with: /^https?:\/\/.+/i,
    message: 'should begin with http:// or https:// and contain a valid URL'

  belongs_to :user

  attr_accessible :to, :shortened, :auto, :clicks
  before_create :generate_url

  URL_FORMAT = /^[a-z\d\/_]+$/i

  scope :auto, where(auto: true)
  scope :mine, proc { |u| where(['user_id = ?', u.id]) }

  validate :to do
    if to.match(PROTECTED_REDIRECT_REGEX)
      self.errors.add(:to, "cannot be 'localhost' or 'brk.mn'.")
    end
    unless valid_url?(to.delete 'https://', 'http://')
      self.errors.add(:to, 'is not a valid URL and contains invalid characters.')
    end
  end

  validate :shortened, on: :create do
    # We will auto-create if it's blank.
    return if shortened.blank?
    if Url.count(conditions: { shortened: shortened } ) > 0
      self.errors.add(:shortened, "(#{shortened}) is already in use in the system. Please choose another.")
    end
    if shortened.match(PROTECTED_URL_REGEX)
      self.errors.add(:shortened, 'is a protected URL and cannot be used. Please choose another.')
    end
    unless valid_url?(shortened)
      self.errors.add(:shortened, 'is not a valid URL and contains invalid characters.')
    end
    return
  end

  validate :shortened, on: :update do
    # We will auto-create if it's blank.
    return if shortened.blank?
    if Url.count(conditions: {
      shortened: shortened,
      to: to,
      user_id: user_id
    }) > 0
      self.errors.add(:shortened, "(#{shortened}) is already in use for #{to}. Please choose another.")
    end
    if shortened.match(PROTECTED_URL_REGEX)
      self.errors.add(:shortened, 'is a protected URL and cannot be used. Please choose another.')
    end
    unless valid_url?(shortened)
      self.errors.add(:shortened, 'is not a valid URL and contains invalid characters.')
    end
    return
  end

  def self.all_owners
    %w[Others Mine]
  end

  def self.search(search)
    if search
      where('lower(shortened) like lower(?) OR lower("to") like lower(?)', "%#{search}%", "%#{search}%")
    else
      scoped
    end
  end

  def valid_url?(url)
    !!URI.parse(url)
  rescue URI::InvalidURIError
    false
  end

  def generate_url
    if shortened.blank?
      # Auto create here. If the auto-create URL has already been used, give it
      # a suffix.
      next_id = Url.find_by_sql('select last_value from urls_id_seq')
                   .first['last_value']
                   .to_i
      # This burps on the second autocreated URL. Not worth fixing.
      next_id += 1 unless next_id == 1
      encoded_shortened = Base32::Crockford.encode(next_id).downcase
      suffix = ''
      # These will never be used by Base32 encoding, so it's pretty unlikely
      # they'll occur giving us a high probability of matching with only one
      # character.
      suffix_array = %w[i l o u]
      until Url.count(conditions: { shortened: "#{encoded_shortened}#{suffix}" }).zero?
        suffix = "#{suffix}#{suffix_array[rand(suffix_array.length)]}"
      end
      self.shortened = "#{encoded_shortened}#{suffix}"
      self.auto = true
    else
      self.auto = false
    end

    # Return true to ensure this doesn't look like a failed validation.
    true
  end
end
