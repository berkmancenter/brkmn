class ApplicationController < ActionController::Base
  protect_from_forgery

  def is_authenticated
    # In production with the apache config in README.rdoc there should never be an app-level
    # authentication request.
    authenticate_or_request_with_http_basic 'The Berkman URL Shortener' do |user_name, password|
	  @current_user = User.authenticate(user_name,password)
	  !@current_user.nil?
    end
  end

  def current_user
    @current_user
  end

end
