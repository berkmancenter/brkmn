# frozen_string_literal: true

module Api
  module V1
    # Base for the JSON API. Inherits from ActionController::API, so there is no
    # browser version check, CSRF protection, or cookie session: every request
    # authenticates with an `Authorization: Bearer <token>` header.
    class BaseController < ActionController::API
      AUTH_REALM = "brkmn"
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      # Overridable in tests; defaults to Rails.cache.
      class_attribute :rate_limit_store, default: nil

      before_action :authenticate_api_token!, except: :route_not_found
      before_action :enforce_rate_limit!, except: :route_not_found

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from CanCan::AccessDenied, with: :render_access_denied
      rescue_from ActionController::ParameterMissing,
        ActionDispatch::Http::Parameters::ParseError,
        WillPaginate::InvalidPage,
        with: :render_bad_request

      attr_reader :current_api_token

      def route_not_found
        render_error(:not_found, "not_found", "No API endpoint matches #{request.method} #{request.path}.")
      end

      private

      def current_user
        current_api_token&.user
      end

      def authenticate_api_token!
        secret = ActionController::HttpAuthentication::Token.token_and_options(request)&.first
        if secret.blank?
          return render_unauthorized(nil, "Missing access token. Send it as `Authorization: Bearer <token>`.")
        end

        token = ApiToken.includes(:user).find_for_secret(secret)
        case token&.status
        when :active
          @current_api_token = token
          token.record_use!
        when :expired
          render_unauthorized("invalid_token", "This access token expired at #{token.expires_at.iso8601}.")
        else
          render_unauthorized("invalid_token", "Invalid or revoked access token.")
        end
      end

      # Fixed-window counter per token, shared by every API endpoint.
      def enforce_rate_limit!
        limit = Rails.configuration.x.api.rate_limit
        period = [Rails.configuration.x.api.rate_limit_period, 1].max
        window = Time.current.to_i / period
        count = (rate_limit_store || Rails.cache).increment(
          "api-rate-limit:#{current_api_token.id}:#{window}", 1, expires_in: period + 60
        )
        return if count.nil? # The cache store doesn't support counters (e.g. :null_store).

        reset_at = (window + 1) * period
        response.set_header("X-RateLimit-Limit", limit.to_s)
        response.set_header("X-RateLimit-Remaining", [limit - count, 0].max.to_s)
        response.set_header("X-RateLimit-Reset", reset_at.to_s)
        return if count <= limit

        retry_after = [reset_at - Time.current.to_i, 1].max
        response.set_header("Retry-After", retry_after.to_s)
        render_error(
          :too_many_requests,
          "rate_limited",
          "Rate limit of #{limit} requests per #{period} seconds exceeded. Retry in #{retry_after} seconds."
        )
      end

      def require_write_access!
        return if current_api_token.read_write?

        response.set_header(
          "WWW-Authenticate",
          %(Bearer realm="#{AUTH_REALM}", error="insufficient_scope", error_description="This token is read-only")
        )
        render_error(
          :forbidden,
          "insufficient_scope",
          "This token is read-only. Use a read & write token to make changes."
        )
      end

      def writable?
        current_api_token.read_write?
      end

      def paginate(relation)
        per_page = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i.clamp(1, MAX_PER_PAGE)
        relation.paginate(page: params[:page].presence || 1, per_page: per_page)
      end

      def pagination_meta(collection)
        {
          page: collection.current_page,
          per_page: collection.per_page,
          total_pages: collection.total_pages,
          total_count: collection.total_entries
        }
      end

      def render_error(status, code, message, details: nil)
        error = {code: code, message: message}
        error[:details] = details if details.present?
        render json: {error: error}, status: status
      end

      def render_validation_errors(errors)
        render_error(
          :unprocessable_content,
          "validation_failed",
          errors.full_messages.to_sentence,
          details: errors.to_hash
        )
      end

      def render_unauthorized(error_code, message)
        challenge = %(Bearer realm="#{AUTH_REALM}")
        challenge += %(, error="#{error_code}", error_description="#{message.delete('"')}") if error_code
        response.set_header("WWW-Authenticate", challenge)
        render_error(:unauthorized, error_code || "missing_token", message)
      end

      def render_not_found(_exception = nil)
        render_error(:not_found, "not_found", "Not found.")
      end

      def render_access_denied(_exception = nil)
        render_error(:forbidden, "forbidden", "You don't have permission to do that.")
      end

      def render_bad_request(exception)
        message = case exception
                  when ActionController::ParameterMissing then "Missing parameter: #{exception.param}."
                  when ActionDispatch::Http::Parameters::ParseError then "The request body is not valid JSON."
                  else "Invalid page number."
                  end
        render_error(:bad_request, "bad_request", message)
      end
    end
  end
end
