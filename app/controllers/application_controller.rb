# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_action do
    Rack::MiniProfiler.authorize_request if current_user&.superadmin
  end
end
