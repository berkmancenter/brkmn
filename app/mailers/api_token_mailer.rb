# frozen_string_literal: true

class ApiTokenMailer < ApplicationMailer
  helper ApiTokensHelper

  # Sent to an external user when a superadmin creates or reissues their token.
  # Contains a single-use link, never the token itself.
  def claim_instructions
    @api_token = params[:api_token]
    @user = @api_token.user
    @inviter = @api_token.created_by&.email || "An administrator"
    @claim_url = api_token_claim_url(token: params[:claim_token])
    @api_base_url = api_v1_urls_url.delete_suffix("/urls")

    mail(to: @user.email, subject: "Your #{REDIRECT_DOMAIN} API access token")
  end
end
