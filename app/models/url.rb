require 'base32/crockford'
require 'uri'
class Url < ActiveRecord::Base
  validates_presence_of :to

  validates_length_of :to, :maximum => 10.kilobytes, :allow_blank => false 
  validates_format_of :to, :with => /^https?:\/\/.+/i, :message => 'should begin with http:// or https:// and contain a valid URL'

  belongs_to :user

  attr_accessible :to, :shortened, :auto, :clicks
  before_create :generate_url

  URL_FORMAT = /^[a-z\d\/_]+$/i

  scope :auto, where({:auto => true})
  scope :mine, Proc.new{|u| 
      where(['user_id = ?',u.id])
  }

  validate :to do
    if self.to.match(PROTECTED_REDIRECT_REGEX)
      self.errors.add(:to, "cannot be 'localhost' or 'brk.mn'.")
    end
    if ! valid_url?(self.to.delete "https://", "http://")
      self.errors.add(:to, "is not a valid URL and contains invalid characters.")
    end
  end

  validate :shortened, :on => :create do
    # We will auto-create if it's blank.
    return if self.shortened.blank?
    if Url.count(:conditions =>{:shortened => self.shortened}) > 0
      self.errors.add(:shortened, "(" + self.shortened + ") is already in use in the system. Please choose another.")
    end
    if self.shortened.match(PROTECTED_URL_REGEX)
      self.errors.add(:shortened, "is a protected URL and cannot be used. Please choose another.")
    end
    if ! valid_url?(self.shortened)
      self.errors.add(:shortened, "is not a valid URL and contains invalid characters.")
    end
    return 
  end
  
  validate :shortened, :on => :update do
    # We will auto-create if it's blank.
    return if self.shortened.blank?
    if Url.count(:conditions =>{:shortened => self.shortened, :to => self.to, :user_id => self.user_id}) > 0
      self.errors.add(:shortened, "(" + self.shortened + ") is already in use for " + self.to + ". Please choose another.")
    end
    if self.shortened.match(PROTECTED_URL_REGEX)
      self.errors.add(:shortened, "is a protected URL and cannot be used. Please choose another.")
    end
    if ! valid_url?(self.shortened)
      self.errors.add(:shortened, "is not a valid URL and contains invalid characters.")
    end
    return 
  end

  def self.all_owners
	%w(Others Mine)
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
    if self.shortened.blank?
      # Auto create here. If the auto-create URL has already been used, give it a suffix.
      next_id = Url.find_by_sql('select last_value from urls_id_seq').first['last_value'].to_i
      #This burps on the second autocreated URL. Not worth fixing.
      next_id = next_id + 1 unless next_id == 1
      encoded_shortened = Base32::Crockford.encode(next_id).downcase
      suffix = ''
      # These will never be used by Base32 encoding, so it's pretty unlikely they'll occur giving us a high probability
      # of matching with only one character. 
      suffix_array = ['i','l','o','u'] 
      until Url.count(:conditions => {:shortened => "#{encoded_shortened}#{suffix}"}) == 0
        suffix = "#{suffix}#{suffix_array[rand(suffix_array.length)]}" 
      end
      self.shortened = "#{encoded_shortened}#{suffix}"
      self.auto = true
    else
      self.auto = false
    end
    #Return true to ensure this doesn't look like a failed validation.
    return true
  end  

end
