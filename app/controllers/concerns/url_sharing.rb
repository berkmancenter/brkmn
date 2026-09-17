# frozen_string_literal: true

module UrlSharing
  extend ActiveSupport::Concern

  REFRESHABLE_REGIONS = {
    access_request_footer: :url_access_requests,
    access_requests: :url_access_requests,
    people_with_access: :url_collaborators
  }.freeze

  included do
    before_action :authenticate_user!
    before_action :load_url
  end

  private

  def load_url
    @url = Url.with_sharing.find(params[:url_id])
  end

  def render_modal_error(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: feedback_stream(message, type: :error), status: :unprocessable_content
      end
      format.html do
        flash[:modal_error] = {"url_id" => @url.id, "message" => message}
        redirect_back_or_to urls_path
      end
    end
  end

  def render_modal_update(message, refresh:)
    regions = Array(refresh)
    reset_associations_for(regions)

    respond_to do |format|
      format.turbo_stream do
        streams = [feedback_stream(message, type: :notice)]
        streams.concat(regions.map { |region| region_stream(region) })
        render turbo_stream: streams
      end
      format.html do
        flash[:notice] = message
        redirect_back_or_to urls_path
      end
    end
  end

  def reset_associations_for(regions)
    regions
      .map { |region| REFRESHABLE_REGIONS.fetch(region) }
      .uniq
      .each { |association| @url.association(association).reset }
  end

  def feedback_stream(message, type:)
    turbo_stream.replace(
      helpers.dom_id(@url, :sharing_feedback),
      partial: "urls/sharing_feedback",
      locals: {url: @url, message: message, type: type}
    )
  end

  def region_stream(region)
    REFRESHABLE_REGIONS.fetch(region)
    turbo_stream.replace(
      helpers.dom_id(@url, region),
      partial: "urls/#{region}",
      locals: {url: @url}
    )
  end
end
