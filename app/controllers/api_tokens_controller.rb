# frozen_string_literal: true

# Lets signed-in users create, regenerate, and revoke their own API tokens.
class ApiTokensController < ApplicationController
  DEFAULT_LIFETIME_DAYS = 90

  before_action :authenticate_user!
  before_action :set_api_token, only: %i[regenerate revoke]

  def index
    @new_api_token = build_token
    load_tokens
  end

  def create
    api_token = build_token(api_token_params)

    if (secret = api_token.issue_secret)
      show_secret(secret, api_token, "Token “#{api_token.name}” created.")
    else
      @new_api_token = api_token
      load_tokens
      render :index, status: :unprocessable_content
    end
  end

  def regenerate
    if (secret = @api_token.issue_secret)
      show_secret(secret, @api_token, "Token “#{@api_token.name}” regenerated. The previous value no longer works.")
    else
      redirect_to api_tokens_path, alert: @api_token.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def revoke
    @api_token.revoke!(by: current_user)
    redirect_to api_tokens_path, notice: "Token “#{@api_token.name}” was revoked.", status: :see_other
  end

  private

  # Scoped to the current user, so other people's tokens are simply not found.
  def set_api_token
    @api_token = current_user.api_tokens.find(params[:id])
  end

  def build_token(attributes = {})
    ApiToken.new(
      {access_level: :read_only, lifetime_days: DEFAULT_LIFETIME_DAYS}
        .merge(attributes.to_h.symbolize_keys)
        .merge(user: current_user, created_by: current_user)
    )
  end

  def load_tokens
    @tokens = current_user.api_tokens
      .includes(:created_by, :revoked_by)
      .order(Arel.sql("api_tokens.revoked_at IS NOT NULL"), created_at: :desc, id: :desc)
  end

  # The plaintext secret only ever appears in this one response: it never goes
  # into the session, the flash, or any cache.
  def show_secret(secret, api_token, heading)
    @secret = {value: secret, api_token: api_token, heading: heading}
    @new_api_token = build_token
    load_tokens
    response.headers["Cache-Control"] = "no-store"

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("api_tokens_page", partial: "api_tokens/page") }
      format.html { render :index }
    end
  end

  def api_token_params
    params.require(:api_token).permit(:name, :access_level, :lifetime_days)
  end
end
