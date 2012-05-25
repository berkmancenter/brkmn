class RedirectorController < ApplicationController

  def index
    @url = Url.find_by_shortened(params[:id])
    redirect_to @url.to
  rescue Exception => e
    render :status => :not_found, :action => :invalid
  end

  def invalid
    render :status => :not_found
  end

end
