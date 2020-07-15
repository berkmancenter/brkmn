require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def authenticate!
        @username = params[:user][:username]
        password = params[:user][:password]

        LdapQuery.new(@username, password).authenticatable? ? win : fail(:invalid_login)
      end

      def win
        user = User.find_or_create_by(username: @username)
        success!(user)
      end
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
