class Url < ActiveRecord::Base
  validates_presence_of :from, :to
  validates_length_of :from, :maximum => 255, :allow_blank => false 
  validates_length_of :to, :maximum => 10.kilobytes, :allow_blank => false 

  validates_format_of :to, :with => /https?:\/\/.+/i

  belongs_to :user

  attr_accessible :to, :from, :public
  scope :viewable, Proc.new{|u| 
    unless u.superadmin?
      where(['public is true OR user_id = ?',u.id])
    end
  }

end
