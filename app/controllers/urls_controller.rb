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
          render :text => "<h2 class='generated_url'>Huzzah!: <a href='http://brk.mn/#{@url.from}'>http://brk.mn/#{@url.from}</a></h2>", :layout => ! request.xhr?
        else
          logger.warn(@url.errors.inspect)
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
