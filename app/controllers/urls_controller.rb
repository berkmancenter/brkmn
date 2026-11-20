# frozen_string_literal: true

class UrlsController < ApplicationController
  PER_PAGE_LIMIT = 100

  helper_method :sort_column, :sort_direction

  before_action :authenticate_user!

  def bookmarklet
    @page_title = "Shorten a URL - #{REDIRECT_DOMAIN}"
  end

  def show
    @url = Url.find url_params[:id]
  end

  def index
    @page_title = "Shorten a URL - #{REDIRECT_DOMAIN}"

    search = url_params[:search]&.strip&.tr(' ', '-')
    return redirect_to search_urls_path(search: search) if search.present?

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

  def create
    @url = Url.new(create_url_params.merge(user: current_user))

    respond_to do |f|
      f.html do
        if save_url
          flash[:notice] = "Shortened URL (#{root_url}#{@url.shortened}) was successfully created."
        else
          logger.warn(@url.errors.inspect)
          flash[:error] = "ERROR: #{@url.errors.full_messages.to_sentence}"
        end
      end
    end

    redirect_to urls_path
  end

  def edit
    @url = Url.includes(:url_collaborators).find(params[:id])
    authorize! :update, @url
  end

  def details
    @url = Url.with_sharing_details.find(params[:id])
    authorize! :read, @url

    render partial: "urls/details_dialog", locals: {url: @url}
  end

  def update
    @url = Url.includes(:url_collaborators).find(params[:id])
    authorize! :update, @url

    if @url.update_with_editor(update_url_params, editor: current_user)
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
    png = ShortUrlQrCode.png(shortened_url(url.shortened))

    send_data png, type: 'image/png', disposition: 'inline', filename: ShortUrlQrCode.filename(url)
  end

  private

  def url_params
    params.permit(:id, :search, :my_page, :others_page, :per_page, :sort, :direction)
  end

  # A missing or malformed url param is a 400 Bad Request, not a crash.
  def create_url_params
    params.expect(url: %i[shortened to])
  end

  def update_url_params
    params.expect(url: [:to])
  end

  # The unique index catches two people taking the same code at the same time.
  def save_url
    @url.save
  rescue ActiveRecord::RecordNotUnique
    @url.errors.add(:shortened, "(#{@url.shortened}) is already in use. Please choose another.")
    false
  end

  # Nil means the will_paginate default. Capped so one request can't render
  # every link at once.
  def per_page
    value = url_params[:per_page].to_i
    [value, PER_PAGE_LIMIT].min if value.positive?
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
    relation.with_sharing_details
      .order(sort_column + ' ' + sort_direction)
      .paginate(
        page: url_params[page_indicator],
        per_page: per_page
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
