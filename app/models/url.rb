require 'base32/crockford'
require 'uri'

class Url < ActiveRecord::Base
  include ActiveModel::Validations

  belongs_to :user

  before_create :generate_url

  validates_length_of :to, maximum: 10.kilobytes, allow_blank: false
  validates_format_of :to, with: /\Ahttps?:\/\/.+/i,
    message: 'should begin with http:// or https:// and contain a valid URL'

  validates :shortened, shortcode: true, on: [:create, :update]

  URL_FORMAT = /^[a-z\d\/_]+$/i

  scope :auto, -> { where(auto: true) }
  scope :mine, proc { |u| where(['user_id = ?', u.id]) }

  validate :to do
    unless to.present?
      self.errors.add(:to, 'Target URL must be present.')
    end
    if to&.match(PROTECTED_REDIRECT_REGEX)
      self.errors.add(:to, "cannot be 'localhost' or 'brk.mn'.")
    end
    unless valid_url?(to&.delete 'https://', 'http://')
      self.errors.add(:to, 'is not a valid URL and contains invalid characters.')
    end
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

  private

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
      until Url.where(shortened: "#{encoded_shortened}#{suffix}").empty?
        suffix = "#{suffix}#{suffix_array.sample}"
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
