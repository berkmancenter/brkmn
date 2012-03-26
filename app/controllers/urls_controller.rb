class UrlsController < ApplicationController
  before_filter :is_authenticated

  def index
    @urls = Url.paginate(:page => params[:page], :per_page => params[:per_page])
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
  end

end
