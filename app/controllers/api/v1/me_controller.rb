# frozen_string_literal: true

module Api
  module V1
    # GET /api/v1/me — a cheap way for clients to check that a token works.
    class MeController < BaseController
      def show
        render json: {
          user: {
            id: current_user.id,
            email: current_user.email,
            username: current_user.username,
            superadmin: current_user.superadmin?
          },
          token: {
            id: current_api_token.id,
            name: current_api_token.name,
            prefix: current_api_token.token_prefix,
            access_level: current_api_token.access_level,
            expires_at: current_api_token.expires_at,
            last_used_at: current_api_token.last_used_at,
            created_at: current_api_token.created_at
          }
        }
      end
    end
  end
end
