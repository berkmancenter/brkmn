class UrlsController < ApplicationController
  before_filter :is_authenticated

  def index
    @urls = Url.order('created_at desc').paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def create
    @url = Url.new(
      :shortened  => params[:url][:shortened],
      :to => params[:url][:to]
    )
    @url.user_id = current_user.id
    
    respond_to do |f|
      f.html {
        if @url.save
          render :text => "<h2 class='generated_url'>Huzzah!: <a href='http://brk.mn/#{@url.shortened}'>http://brk.mn/#{@url.shortened}</a></h2>", :layout => ! request.xhr?
        else
          logger.warn(@url.errors.inspect)
          render :text => "#{@url.errors.full_messages.join('<br/>')}", :status => :unprocessable_entity
        end
      }
    end
    
  end

end
