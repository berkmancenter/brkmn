class UrlsController < ApplicationController
  before_filter :is_authenticated

  def index
    @urls = Url.paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def create
    @url = Url.new(
      :from  => params[:url][:from],
      :to => params[:url][:to]
    )
    @url.user_id = current_user.id
    
    respond_to do |f|
      f.html {
        if @url.save
          render :text => 'Success! We created that URL for you.', :layout => ! request.xhr?
        else
          render :text => "Sorry, we couldn't create that URL.<br/>#{@url.errors.full_messages.join('<br/>')}", :status => :unprocessable_entity
        end
      }
    end
    
  end

  def new
    @url = Url.new(
      :from  => params[:url][:from],
      :to => params[:url][:to]
    )
    @url.user_id = current_user.id
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
