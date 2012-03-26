class ApplicationController < ActionController::Base
  protect_from_forgery

  def is_authenticated
    # TODO - look for the correct environment variable
    authenticate_or_request_with_http_basic 'The Berkman URL Shortener' do |user_name, password|
      @current_user = User.find_or_create_by_username(user_name)
      @current_user.save
    end
  end

  def current_user
    @current_user
  end

end
