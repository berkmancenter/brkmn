class User < ActiveRecord::Base
  validates_presence_of :username
  validates_length_of :username, :email, :maximum => 100
  # TODO - validate email format.
  attr_accessible :email

  def superadmin?
    superadmin
  end

end
