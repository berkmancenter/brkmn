require 'base32/crockford'
class Url < ActiveRecord::Base
  validates_presence_of :to

  validates_length_of :to, :maximum => 10.kilobytes, :allow_blank => false 
  validates_format_of :to, :with => /https?:\/\/.+/i, :message => 'should begin with http:// or https:// and look like a valid URL'

  belongs_to :user

  attr_accessible :to, :from, :auto
  before_create :generate_url

  PROTECTED_URL_REGEX = /^(url|user|metric)/i
  URL_FORMAT = /^[a-z\d\/]+$/i

  validate :from do
    # We will auto-create if it's blank.
    return if self.from.blank?
    if Url.count(:conditions =>{:from => self.from}) > 0
      self.errors.add(:from, "is already in use. Please choose another.")
    end
    if self.from.match(PROTECTED_URL_REGEX)
      self.errors.add(:from, "is a protected URL and you can't have it. It's mine.")
    end
    if ! self.from.match(URL_FORMAT)
      self.errors.add(:from, "needs to contains letters, numbers, or the forward slash")
    end
  end

  scope :auto, where({:auto => true})
  scope :mine, Proc.new{|u| 
      where(['user_id = ?',u.id])
  }

  def generate_url
    if self.from.blank?
      # Auto create here. If the auto-create URL has already been used, give it a suffix.
      next_id = Url.find_by_sql('select last_value from urls_id_seq').first['last_value'].to_i
      #This burps on the second autocreated URL. Not worth fixing.
      next_id = next_id + 1 unless next_id == 1
      encoded_from = Base32::Crockford.encode(next_id).downcase
      suffix = ''
      # These will never be used by Base32 encoding, so it's pretty unlikely they'll occur giving us a high probability
      # of matching with only one character. 
      suffix_array = ['i','l','o','u'] 
      until Url.count(:conditions => {:from => "#{encoded_from}#{suffix}"}) == 0
        suffix = "#{suffix}#{suffix_array[rand(suffix_array.length)]}" 
      end
      self.from = "#{encoded_from}#{suffix}"
      self.auto = true
    else
      # 
      self.auto = false
    end
  end

end
