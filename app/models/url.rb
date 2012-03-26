require 'base32/crockford'
class Url < ActiveRecord::Base
  validates_presence_of :to

  validates_length_of :to, :maximum => 10.kilobytes, :allow_blank => false 
  validates_format_of :to, :with => /^https?:\/\/.+/i, :message => 'should begin with http:// or https:// and look like a valid URL'

  belongs_to :user

  attr_accessible :to, :shortened, :auto
  before_create :generate_url

  URL_FORMAT = /^[a-z\d\/]+$/i

  scope :auto, where({:auto => true})
  scope :mine, Proc.new{|u| 
      where(['user_id = ?',u.id])
  }

  validate :to do
    if self.to.match(PROTECTED_REDIRECT_REGEX)
      self.errors.add(:to, "just can't go there. Not gonna happen.")
    end
  end

  validate :shortened do
    # We will auto-create if it's blank.
    return if self.shortened.blank?
    if Url.count(:conditions =>{:shortened => self.shortened}) > 0
      self.errors.add(:shortened, "is already in use. Please choose another.")
    end
    if self.shortened.match(PROTECTED_URL_REGEX)
      self.errors.add(:shortened, "is a protected URL and you can't have it. It's mine.")
    end
    if ! self.shortened.match(URL_FORMAT)
      self.errors.add(:shortened, "needs to contains letters, numbers, or the forward slash")
    end
    return 
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
