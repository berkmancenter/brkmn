# frozen_string_literal: true

class RedirectorController < ApplicationController
  def index
    url = Url.find_by(shortened: params[:id])
    return invalid if url.nil?

    # Sending visitors to other sites is the point of a URL shortener. The
    # destination is validated as an http(s) URL when the link is saved.
    redirect_to url.to, allow_other_host: true
    # One UPDATE ... SET clicks = clicks + 1, so parallel clicks are all counted.
    Url.update_counters(url.id, clicks: 1)
  rescue ActionController::Redirecting::UnsafeRedirectError
    invalid
  end

  def invalid
    render :invalid, status: :not_found
  end
end
