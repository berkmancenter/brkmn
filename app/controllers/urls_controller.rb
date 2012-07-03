class UrlsController < ApplicationController
  before_filter :is_authenticated

  def bookmarklet
  end

  def index
    @urls = Url.order('created_at desc').paginate(:page => params[:page], :per_page => params[:per_page])
  end

  def url_list
    query = Url.select([:id, :auto, :shortened, '"to"', :user_id]).where((params[:filter].blank?) ? ['1 = 1'] : ['"to" like ?',"%#{params[:filter]}%"]).order('created_at desc').paginate(:page => params[:page], :per_page => params[:per_page])
    @urls = query
    respond_to do |f|
      f.html { render :partial => 'shared/url_list' }
    end
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
