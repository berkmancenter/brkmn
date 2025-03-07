# frozen_string_literal: true

class RedirectorController < ApplicationController
  def index
    @url = Url.find_by(shortened: params[:id])
    @url.update_attribute(:clicks, @url.clicks + 1)
    redirect_to @url.to, allow_other_host: true
  rescue StandardError
    render status: :not_found, action: :invalid
  end

  def invalid
    render status: :not_found
  end
end
