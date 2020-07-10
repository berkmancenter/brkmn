require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def authenticate!
        return win if Rails.application.config.use_fakeauth
        return fail(:invalid_login) if password.empty?

        if params[:user]
          conf = YAML.load_file(Rails.root.join(Rails.root, 'config', 'ldap.yml'))

          ldap = Net::LDAP.new
          ldap.host = conf['bind_hostname']
          ldap.port = conf['bind_port']
          ldap.auth username, password

          if ldap.bind
            win
          else
            return fail(:invalid_login)
          end
        end
      end

      def win
        user = User.find_or_create_by(username: username)
        success!(user)
      end

      def username
        params[:user][:username]
      end

      def password
        params[:user][:password]
      end
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
