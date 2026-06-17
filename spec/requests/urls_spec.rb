# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "Urls", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe "POST /urls" do
    it "creates a URL for the signed-in user" do
      expect do
        post urls_path, params: {url: {to: "https://example.org/new-page", shortened: "new-page"}}
      end.to change(Url, :count).by(1)

      url = Url.last
      expect(url.user).to eq(user)
      expect(url.to).to eq("https://example.org/new-page")
      expect(url.shortened).to eq("new-page")
      expect(response).to redirect_to(urls_path)
    end

    it "redirects with an error without creating an invalid URL" do
      expect do
        post urls_path, params: {url: {to: "https://ex ample.org", shortened: "bad-url"}}
      end.not_to change(Url, :count)

      expect(flash[:error]).to include("must be a valid url")
      expect(response).to redirect_to(urls_path)
    end
  end

  describe "PATCH /urls/:id" do
    let(:url) { create(:url, user: user, to: "https://example.org/original") }

    it "updates the destination URL" do
      patch url_path(url), params: {url: {to: "https://example.org/updated"}}

      expect(response).to redirect_to(urls_path)
      expect(url.reload.to).to eq("https://example.org/updated")
    end

    it "renders the edit form and preserves the URL when the update is invalid" do
      patch url_path(url), params: {url: {to: "https://ex ample.org"}}

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("URL Details")
      expect(url.reload.to).to eq("https://example.org/original")
    end
  end

  describe "GET /urls/:id/qr" do
    it "returns an inline PNG QR code for the short URL" do
      url = create(:url, user: user, shortened: "qr-code")

      get qr_url_path(url)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.body.bytes.first(8)).to eq([137, 80, 78, 71, 13, 10, 26, 10])
    end
  end
end
# rubocop:enable Metrics/BlockLength
