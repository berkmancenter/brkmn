class UrlsController < ApplicationController
  before_action :authenticated?
  skip_before_action :authenticated?, only: :logout
  helper_method :sort_column, :sort_direction

  def bookmarklet
    @page_title = "Shorten a URL - #{REDIRECT_DOMAIN}"
  end

  def show
    @url = Url.find url_params[:id]
  end

  def index
    @page_title = "Shorten a URL - #{REDIRECT_DOMAIN}"

    @search = url_params[:search]

    if @search != nil
      redirect_to '/urls/search/' + @search.strip.gsub(' ', '-')
    end

    hilite

    @urls = Url.order(sort_column + ' ' + sort_direction)
               .paginate(page: url_params[:page], per_page: url_params[:per_page])
  end

  def search
    @page_title = "Shorten a URL - #{REDIRECT_DOMAIN}"

    hilite

    @urls = Url.search(url_params[:search])
               .order(sort_column + ' ' + sort_direction)
               .paginate(page: url_params[:page], per_page: url_params[:per_page])
  end

  def create
    @url = Url.new(
      shortened: url_params[:url][:shortened],
      to: url_params[:url][:to]
    )

    respond_to do |f|
      f.html do
        if @url.save
          flash[:notice] = "Shortened URL (http://brk.mn/#{@url.shortened}) was successfully created."
        else
          logger.warn(@url.errors.inspect)
          flash[:error] = "ERROR: #{@url.errors.full_messages}"
        end
      end
    end

    redirect_to urls_path
  end

  private

  def url_params
    params.permit(
      :id, :search, :page, :per_page, :sort, :direction,
      url: %i[shortened to]
    )
  end

  def sort_column
    sort = url_params[:sort] || session[:sort]

    session[:sort] = sort if url_params[:sort] != session[:sort]

    %w[shortened "to" clicks].include?(sort) ? sort : 'shortened'
  end

  def sort_direction
    direction = url_params[:direction] || session[:direction]

    session[:direction] = direction if url_params[:direction] != session[:direction]

    %w[asc desc].include?(direction) ? direction : 'asc'
  end

  def hilite
    case url_params[:sort] || session[:sort]
    when '"to"'
      @to_header = 'to hilite'
      @clicks_header = 'clicks'
      @shortened_header = 'shortened'
    when 'clicks'
      @clicks_header = 'clicks hilite'
      @to_header = 'to'
      @shortened_header = 'shortened'
    else
      @shortened_header = 'shortened hilite'
      @clicks_header = 'clicks'
      @to_header = 'to'
    end
  end
end
