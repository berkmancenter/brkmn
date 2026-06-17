# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Theme", type: :request do
  describe "GET /toggle_mode" do
    it "switches the default modern mode to classic" do
      get toggle_mode_path

      expect(response).to have_http_status(:ok)
      expect(response.cookies["viewing_mode"]).to eq("classic")
      expect(response.body).to include("Light")
    end

    it "switches classic mode back to modern" do
      cookies[:viewing_mode] = "classic"

      get toggle_mode_path

      expect(response).to have_http_status(:ok)
      expect(response.cookies["viewing_mode"]).to eq("modern")
      expect(response.body).to include("Classic")
    end
  end
end
