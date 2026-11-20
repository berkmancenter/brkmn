# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Raise on a missing or wrong token. The default :null_session only clears the
  # session, and header authentication does not use the session at all.
  protect_from_forgery with: :exception, prepend: true

  def authenticate_user!(options = {})
    return super unless Rails.application.config.devise_auth_type == "headers"
    return head :unauthorized unless trusted_auth_proxy?

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

  private

  # The auth headers are only trusted when the request comes straight from the
  # auth proxy. REMOTE_ADDR is the direct peer, it can't be faked with headers.
  def trusted_auth_proxy?
    remote_addr = IPAddr.new(request.remote_addr.to_s).native
    trusted = Rails.application.config.auth_headers_trusted_proxies.any? { |proxy| proxy.include?(remote_addr) }
    logger.warn("Ignoring auth headers from untrusted address #{request.remote_addr}") unless trusted
    trusted
  rescue IPAddr::InvalidAddressError
    false
  end
end
