# frozen_string_literal: true

module Brkmn
  # The people of the demo data (see Brkmn::DemoData), in every account state
  # the auth type has: confirmed or not, locked or not.
  class DemoUsers
    def initialize(users_data, password:)
      @users_data = users_data
      @password = password
    end

    # Creates or restores every demo user, returns them by key (:maya, ...).
    def load
      @users_data.to_h do |attributes|
        user = User.find_or_initialize_by(email: DemoData.email_for(attributes[:key]))
        user.username = attributes[:name]
        user.superadmin = attributes.fetch(:superadmin, false)
        user.api_only = attributes.fetch(:api_only, false)
        assign_password(user)
        assign_confirmation(user, confirmed: attributes[:state] != "unconfirmed")
        user.save!
        assign_lock(user, locked: attributes[:state] == "locked")
        [attributes[:key].to_sym, user]
      end
    end

    private

    # Other auth types (CAS, SAML, headers) have no passwords, their users are
    # matched by email when they log in.
    def assign_password(user)
      if user.respond_to?(:password=)
        user.password = @password
        user.password_confirmation = @password
      else
        user.set_random_password
      end
    end

    def assign_confirmation(user, confirmed:)
      return unless devise_module?(:confirmable)

      if confirmed
        user.skip_confirmation! unless user.confirmed?
      else
        user.confirmed_at = nil
        user.skip_confirmation_notification!
      end
    end

    def assign_lock(user, locked:)
      return unless devise_module?(:lockable)

      if locked
        user.update_columns(locked_at: Time.current, failed_attempts: Devise.maximum_attempts)
      else
        user.update_columns(locked_at: nil, failed_attempts: 0, unlock_token: nil)
      end
    end

    def devise_module?(name)
      User.devise_modules.include?(name)
    end
  end
end
