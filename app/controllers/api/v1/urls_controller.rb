# frozen_string_literal: true

module Api
  module V1
    # CRUD for short URLs. Permissions come from Ability, the same rules the
    # web UI uses: anyone can read, owners and collaborators can update, only
    # owners can delete, superadmins can do everything.
    class UrlsController < BaseController
      SCOPES = %w[mine all].freeze
      PRELOADS = [:user, :last_edited_by, :url_collaborators].freeze

      before_action :require_write_access!, only: %i[create update destroy]
      before_action :load_url, only: %i[show update destroy qr]

      # GET /api/v1/urls?scope=mine|all&search=&shortened=&page=&per_page=
      def index
        scope = params.fetch(:scope, "mine")
        unless SCOPES.include?(scope)
          return render_error(:bad_request, "bad_request", "scope must be one of: #{SCOPES.join(", ")}.")
        end

        urls = scope == "all" ? Url.all : Url.mine(current_user)
        urls = urls.search(params[:search].presence)
        urls = urls.where(shortened: params[:shortened]) if params[:shortened].present?
        urls = paginate(urls.includes(*PRELOADS).order(id: :desc))

        render json: {urls: urls.map { |url| serialize(url) }, meta: pagination_meta(urls)}
      end

      def show
        authorize! :read, @url
        render json: {url: serialize(@url)}
      end

      def create
        @url = Url.new(url_params.merge(user: current_user))

        if @url.save
          render json: {url: serialize(@url)}, status: :created, location: api_v1_url_url(@url)
        else
          render_validation_errors(@url.errors)
        end
      end

      # Only the destination can change, as in the web UI.
      def update
        authorize! :update, @url
        attributes = url_params

        if attributes[:shortened].present? && attributes[:shortened] != @url.shortened
          @url.errors.add(:shortened, "can't be changed")
          return render_validation_errors(@url.errors)
        end

        if @url.update_with_editor(attributes.slice(:to), editor: current_user)
          render json: {url: serialize(@url)}
        else
          render_validation_errors(@url.errors)
        end
      end

      def destroy
        authorize! :destroy, @url
        @url.destroy!
        head :no_content
      end

      def qr
        authorize! :read, @url
        send_data ShortUrlQrCode.png(shortened_url(@url.shortened)),
          type: "image/png",
          disposition: "inline",
          filename: ShortUrlQrCode.filename(@url)
      end

      private

      def load_url
        @url = Url.includes(*PRELOADS).find(params[:id])
      end

      def url_params
        nested = params.require(:url)
        raise ActionController::ParameterMissing, :url unless nested.is_a?(ActionController::Parameters)

        nested.permit(:to, :shortened)
      end

      def serialize(url)
        owned_by_you = url.owned_by?(current_user)
        can_view_user_details = can?(:update, url)
        user_details = if can_view_user_details
          {
            owner: user_summary(url.user),
            last_edited_by: user_summary(url.last_edited_by)
          }
        else
          {}
        end

        {
          id: url.id,
          shortened: url.shortened,
          short_url: shortened_url(url.shortened),
          to: url.to,
          auto_generated: url.auto,
          clicks: url.clicks,
          qr_code_url: qr_api_v1_url_url(url),
          **user_details,
          owned_by_you: owned_by_you,
          permissions: {
            update: writable? && can_view_user_details,
            destroy: writable? && can?(:destroy, url)
          },
          last_edited_at: url.last_edited_at,
          created_at: url.created_at,
          updated_at: url.updated_at
        }
      end

      def user_summary(user)
        user && {id: user.id, email: user.email}
      end
    end
  end
end
