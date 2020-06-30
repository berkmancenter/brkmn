class ApplicationController < ActionController::Base
  protect_from_forgery
  attr_reader :current_user

  def authenticated?
    # In production with the apache config in README.rdoc there should never be
    # an app-level authentication request.
    msg = 'The Berkman URL Shortener: Log in with your HLS AD account'
    authenticate_or_request_with_http_basic msg do |username, password|
      @current_user = User.authenticate(username, password)
      !@current_user.nil?
    end
  end
end
