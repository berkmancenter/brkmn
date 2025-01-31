# frozen_string_literal: true

class UrlsController < ApplicationController
  helper_method :sort_column, :sort_direction

  before_action :login_or_authenticate_user

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
      redirect_to urls_path
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

  def qr
    url = Url.find(params[:id])
    qrcode = RQRCode::QRCode.new(shortened_url(url.shortened))

    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 1,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 400,
    )

    send_data png, type: 'image/png', disposition: 'inline', filename: "brkmn-qr-#{url.shortened}.png"
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

    %w[shortened "to" clicks created_at].include?(sort) ? sort : 'shortened'
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
      @created_header = 'created_at'
    when 'clicks'
      @clicks_header = 'clicks hilite'
      @to_header = 'to'
      @shortened_header = 'shortened'
      @created_header = 'created_at'
    when 'created_at'
      @clicks_header = 'clicks'
      @to_header = 'to'
      @shortened_header = 'shortened'
      @created_header = 'created_at hilite'
    else
      @shortened_header = 'shortened hilite'
      @clicks_header = 'clicks'
      @to_header = 'to'
      @created_header = 'created_at'
    end
  end
  # rubocop:enable Metrics/MethodLength
end
