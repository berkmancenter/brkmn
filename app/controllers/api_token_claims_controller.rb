# frozen_string_literal: true

# The page behind the single-use link emailed to external users. Opening the
# link (GET) only shows a button; the token is created on POST, so email
# security scanners that prefetch links can't use it up.
class ApiTokenClaimsController < ApplicationController
  before_action :set_private_headers
  before_action :load_claim

  def show
    render :show, status: @state == :ready ? :ok : :not_found
  end

  def create
    secret = @api_token&.claim(@claim_token)
    unless secret
      @state = :invalid if @state == :ready # Collected by a simultaneous request.
      return render(:show, status: :unprocessable_content)
    end

    @secret = {value: secret, api_token: @api_token, heading: "Here is your API token"}
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("api_token_claim", partial: "api_token_claims/revealed")
      end
      format.html { render :revealed }
    end
  end

  private

  def load_claim
    @claim_token = params[:token].to_s
    @api_token = ApiToken.includes(:user, :created_by).find_for_claim(@claim_token)
    @state = if @api_token&.claimable?
               :ready
             elsif @api_token&.claim_expired?
               :expired
             else
               :invalid
             end
  end

  # The URL carries a secret and the response may too: keep both out of caches
  # and Referer headers.
  def set_private_headers
    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end
end
