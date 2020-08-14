# frozen_string_literal: true

class UrlsController < ApplicationController
  before_action :authenticate_user!
  helper_method :sort_column, :sort_direction

  def bookmarklet
    @page_title = "Shorten a URL - #{REDIRECT_DOMAIN}"
  end

  def show
    @url = Url.find url_params[:id]
  end

  def index
    @page_title = "Shorten a URL - #{REDIRECT_DOMAIN}"

    search = url_params[:search]&.strip&.tr(' ', '-')
    redirect_to search_urls_path(search: search) if search.present?

    hilite

    @not_my_urls = organized(Url.not_mine(current_user), :others_page)
    @my_urls = organized(Url.mine(current_user), :my_page)
  end

  def search
    @page_title = "Shorten a URL - #{REDIRECT_DOMAIN}"

    hilite

    @not_my_urls = organized(Url.not_mine(current_user).search(url_params[:search]), :others_page)
    @my_urls = organized(Url.mine(current_user).search(url_params[:search]), :my_page)

    render 'index'
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create
    @url = Url.new(
      shortened: url_params[:url][:shortened],
      to: url_params[:url][:to],
      user: current_user
    )

    respond_to do |f|
      f.html do
        if @url.save
          flash[:notice] = "Shortened URL (#{root_url}#{@url.shortened}) was successfully created."
        else
          logger.warn(@url.errors.inspect)
          flash[:error] = "ERROR: #{@url.errors.full_messages}"
        end
      end
    end

    redirect_to urls_path
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def edit
    @url = Url.find(params[:id])
    authorize! :update, @url
  end

  def update
    @url = Url.find(params[:id])
    authorize! :update, @url

    if @url.update(update_url_params)
      redirect_to @url
    else
      render 'edit'
    end
  end

  def destroy
    @url = Url.find(params[:id])
    authorize! :destroy, @url
    @url.destroy
    respond_to do |format|
      format.html { redirect_to root_path }
    end
  end

  private

  def url_params
    params.permit(
      :id, :search, :my_page, :others_page, :per_page, :sort, :direction,
      url: %i[shortened to]
    )
  end

  def update_url_params
    params.permit(url: :to)[:url]
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

  def organized(relation, page_indicator)
    relation.order(sort_column + ' ' + sort_direction)
            .paginate(
              page: url_params[page_indicator],
              per_page: url_params[:per_page]
            )
  end

  # rubocop:disable Metrics/MethodLength
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
  # rubocop:enable Metrics/MethodLength
end
