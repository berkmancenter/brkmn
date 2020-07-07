# frozen_string_literal: true

module BerkmanLdapAuthMixin
  def authenticate(username, password)
    return unless BerkmanLdapAuth.authenticate(username, password)

    # We've auth'd. Autocreate the user if they don't exist.
    u = self.find_by_username(username)
    if u.blank?
      user = User.create(username: username)
      return user
    else
      return u
    end
  end
end
