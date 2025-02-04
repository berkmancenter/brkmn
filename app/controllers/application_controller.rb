# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protect_from_forgery

  # Override a Devise callback after logout.
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
