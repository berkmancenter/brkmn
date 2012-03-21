class UrlsController < ApplicationController
  before_filter :rights_check

  def index
    @urls = Url.accessible(u).paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def create
  end

  def new
  end

  def update
  end

  def edit
  end

  def destroy
  end

  private
  def rights_check
    #TODO
  end

end
