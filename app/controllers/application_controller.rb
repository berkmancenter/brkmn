# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protect_from_forgery

  def authenticate_user!(options = {})
    return super unless Rails.application.config.devise_auth_type == "headers"

    email = request.headers["X-Auth-Email"].to_s.strip
    name = request.headers["X-Auth-Name"].to_s.strip
    return head :unauthorized if email.blank? || name.blank?

    user = User.from_auth_headers(email: email, name: name)
    request.env.fetch("warden").set_user(user, scope: :user, store: false)
  end

  # Override a Devise callback after logout.
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
