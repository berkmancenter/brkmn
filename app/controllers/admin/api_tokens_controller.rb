# frozen_string_literal: true

module Admin
  # Superadmin view of every API token, plus tokens for external users.
  class ApiTokensController < ApplicationController
    STATUSES = %w[active pending expired revoked].freeze
    KINDS = %w[internal external].freeze
    PER_PAGE = 50

    before_action :authenticate_user!
    before_action :require_superadmin!
    before_action :set_api_token, only: %i[revoke reissue]

    def index
      @filters = params.permit(:q, :status, :kind).to_h.symbolize_keys
      @api_tokens = filtered_tokens
        .includes(:user, :created_by, :revoked_by)
        .order(created_at: :desc, id: :desc)
        .paginate(page: params[:page], per_page: PER_PAGE)
    end

    def new
      @invitation = ExternalApiTokenInvitation.new
    end

    def create
      @invitation = ExternalApiTokenInvitation.new(invitation_params)

      if @invitation.save(created_by: current_user)
        send_claim_link(@invitation.api_token, @invitation.claim_token, verb: "created")
        redirect_to admin_api_tokens_path, status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def revoke
      @api_token.revoke!(by: current_user)
      redirect_back_or_to admin_api_tokens_path,
        notice: "Token “#{@api_token.name}” for #{@api_token.user.email} was revoked.",
        status: :see_other
    end

    # Sends an external user a fresh claim link. Their current token, if any,
    # stops working right away.
    def reissue
      unless @api_token.external?
        return redirect_back_or_to admin_api_tokens_path,
          alert: "Only external users' tokens can be reissued. Other users regenerate their own.",
          status: :see_other
      end

      if (claim_token = @api_token.issue_claim)
        send_claim_link(@api_token, claim_token, verb: "reissued")
      else
        flash[:alert] = @api_token.errors.full_messages.to_sentence
      end
      redirect_back_or_to admin_api_tokens_path, status: :see_other
    end

    private

    def require_superadmin!
      return if current_user.superadmin?

      redirect_to urls_path, alert: "Only superadmins can manage all API tokens.", status: :see_other
    end

    def set_api_token
      @api_token = ApiToken.includes(:user).find(params[:id])
    end

    def filtered_tokens
      tokens = ApiToken.joins(:user)
      tokens = tokens.public_send(@filters[:status]) if STATUSES.include?(@filters[:status])
      tokens = tokens.where(users: {api_only: @filters[:kind] == "external"}) if KINDS.include?(@filters[:kind])
      search(tokens, @filters[:q])
    end

    def search(tokens, query)
      return tokens if query.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query.strip.downcase)}%"
      tokens.where(
        "LOWER(users.email) LIKE :pattern OR LOWER(api_tokens.name) LIKE :pattern " \
        "OR LOWER(api_tokens.note) LIKE :pattern OR LOWER(api_tokens.token_prefix) LIKE :pattern",
        pattern: pattern
      )
    end

    # Sent through the job queue (Sidekiq in production), which retries failed
    # deliveries. Only a failure to enqueue is reported back to the admin.
    def send_claim_link(api_token, claim_token, verb:)
      ApiTokenMailer.with(api_token: api_token, claim_token: claim_token).claim_instructions.deliver_later
      flash[:notice] = "Token “#{api_token.name}” #{verb}. " \
                       "A single-use link is being emailed to #{api_token.user.email}."
    rescue => e
      Rails.logger.error("Could not queue the claim email for API token #{api_token.id}: #{e.class}: #{e.message}")
      flash[:alert] = "Token “#{api_token.name}” #{verb}, but the email to #{api_token.user.email} " \
                      "could not be queued. Use “Send new link” to try again."
    end

    def invitation_params
      params.require(:external_api_token_invitation).permit(:email, :name, :note, :access_level, :lifetime_days)
    end
  end
end
