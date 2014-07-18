class RedirectorController < ApplicationController

  def index
    @url = Url.find_by_shortened(params[:id])
    @url.update_attribute(:clicks, @url.clicks + 1)
    redirect_to @url.to
  rescue Exception => e
    render :status => :not_found, :action => :invalid
  end

  def invalid
    render :status => :not_found
  end

  def to_urls
    redirect_to urls_path
  end

end
