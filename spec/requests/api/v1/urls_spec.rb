# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe "API v1 URLs", type: :request do
  let(:user) { create(:user) }
  let(:secret) { ApiToken.generate_secret }
  let(:access_level) { :read_write }
  let!(:token) { create(:api_token, user: user, secret: secret, access_level: access_level) }
  let(:headers) { api_headers(secret) }

  def share(url, with:)
    UrlCollaborator.create!(url: url, user: with, granted_by: url.user)
  end

  describe "GET /api/v1/urls" do
    let!(:own) { create(:url, user: user, to: "https://example.org/own-page") }
    let!(:shared) { create(:url, to: "https://example.org/shared-page").tap { |url| share(url, with: user) } }
    let!(:other) { create(:url, to: "https://example.org/other-page") }

    it "lists the caller's own and shared URLs by default, newest first" do
      get api_v1_urls_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["urls"].pluck("id")).to eq([shared.id, own.id])
      expect(json["meta"]).to eq("page" => 1, "per_page" => 25, "total_pages" => 1, "total_count" => 2)
    end

    it "lists every URL with scope=all" do
      get api_v1_urls_path(scope: "all"), headers: headers

      expect(json["urls"].pluck("id")).to contain_exactly(own.id, shared.id, other.id)
    end

    it "rejects an unknown scope" do
      get api_v1_urls_path(scope: "everything"), headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]["message"]).to include("mine, all")
    end

    it "filters by search text and by exact shortcode" do
      get api_v1_urls_path(search: "shared-page"), headers: headers
      expect(json["urls"].pluck("id")).to eq([shared.id])

      get api_v1_urls_path(scope: "all", shortened: other.shortened), headers: headers
      expect(json["urls"].pluck("id")).to eq([other.id])
    end

    it "paginates and caps the page size" do
      get api_v1_urls_path(per_page: 1, page: 2), headers: headers
      expect(json["urls"].pluck("id")).to eq([own.id])
      expect(json["meta"]).to include("page" => 2, "per_page" => 1, "total_pages" => 2)

      get api_v1_urls_path(per_page: 1000), headers: headers
      expect(json["meta"]["per_page"]).to eq(100)
    end

    it "rejects an invalid page number" do
      get api_v1_urls_path(page: "zero"), headers: headers

      expect(response).to have_http_status(:bad_request)
    end

    it "describes each URL with links and the caller's permissions" do
      get api_v1_urls_path(scope: "all"), headers: headers
      by_id = json["urls"].index_by { |url| url["id"] }

      expect(by_id[own.id]).to include(
        "shortened" => own.shortened,
        "short_url" => shortened_url(own.shortened),
        "to" => "https://example.org/own-page",
        "qr_code_url" => qr_api_v1_url_url(own),
        "owner" => {"id" => user.id, "email" => user.email},
        "owned_by_you" => true,
        "permissions" => {"update" => true, "destroy" => true}
      )
      expect(by_id[shared.id]["permissions"]).to eq("update" => true, "destroy" => false)
      expect(by_id[other.id]["permissions"]).to eq("update" => false, "destroy" => false)
    end

    context "with a read-only token" do
      let(:access_level) { :read_only }

      it "can list URLs but reports no write permissions" do
        get api_v1_urls_path, headers: headers

        expect(response).to have_http_status(:ok)
        expect(json["urls"].pluck("permissions").uniq).to eq([{"update" => false, "destroy" => false}])
      end
    end
  end

  describe "GET /api/v1/urls/:id" do
    it "returns any URL, as in the web UI" do
      url = create(:url)

      get api_v1_url_path(url), headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["url"]["id"]).to eq(url.id)
    end

    it "returns JSON 404 for a missing URL" do
      get api_v1_url_path(id: 0), headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json["error"]["code"]).to eq("not_found")
    end
  end

  describe "POST /api/v1/urls" do
    it "creates a URL with a custom shortcode" do
      expect do
        post api_v1_urls_path,
          params: {url: {to: "https://example.org/new", shortened: "api-made"}},
          headers: headers,
          as: :json
      end.to change(Url, :count).by(1)

      url = Url.last
      expect(response).to have_http_status(:created)
      expect(response.headers["Location"]).to eq(api_v1_url_url(url))
      expect(url).to have_attributes(user: user, shortened: "api-made", auto: false)
      expect(json["url"]).to include("shortened" => "api-made", "owned_by_you" => true)
    end

    it "accepts unwrapped attributes and generates a shortcode" do
      post api_v1_urls_path, params: {to: "https://example.org/auto"}, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(json["url"]).to include("auto_generated" => true, "to" => "https://example.org/auto")
      expect(json["url"]["shortened"]).to match(/\A[A-Z]{6}\z/)
    end

    it "returns validation errors" do
      create(:url, shortened: "taken")

      post api_v1_urls_path,
        params: {url: {to: "https://ex ample.org", shortened: "taken"}},
        headers: headers,
        as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]["code"]).to eq("validation_failed")
      expect(json["error"]["details"]["to"]).to include("must be a valid url")
      expect(json["error"]["details"]["shortened"].first).to include("already in use")
    end

    it "requires the url parameters" do
      post api_v1_urls_path, params: {}, headers: headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]["message"]).to eq("Missing parameter: url.")
    end

    it "rejects url parameters that aren't an object" do
      post api_v1_urls_path, params: {url: "not-an-object"}, headers: headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json["error"]["message"]).to eq("Missing parameter: url.")
    end

    context "with a read-only token" do
      let(:access_level) { :read_only }

      it "refuses to create URLs" do
        expect do
          post api_v1_urls_path, params: {url: {to: "https://example.org"}}, headers: headers, as: :json
        end.not_to change(Url, :count)

        expect(response).to have_http_status(:forbidden)
        expect(json["error"]["code"]).to eq("insufficient_scope")
        expect(response.headers["WWW-Authenticate"]).to include('error="insufficient_scope"')
      end
    end
  end

  describe "PATCH /api/v1/urls/:id" do
    let(:url) { create(:url, user: user, to: "https://example.org/original") }

    it "updates the destination and records the editor" do
      patch api_v1_url_path(url), params: {url: {to: "https://example.org/updated"}}, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["url"]["to"]).to eq("https://example.org/updated")
      expect(url.reload).to have_attributes(to: "https://example.org/updated", last_edited_by: user)
    end

    it "lets a collaborator update a shared URL" do
      shared = create(:url)
      share(shared, with: user)

      patch api_v1_url_path(shared), params: {url: {to: "https://example.org/team"}}, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(shared.reload.to).to eq("https://example.org/team")
    end

    it "refuses to update someone else's URL" do
      other = create(:url, to: "https://example.org/theirs")

      patch api_v1_url_path(other), params: {url: {to: "https://example.org/mine"}}, headers: headers, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json["error"]["code"]).to eq("forbidden")
      expect(other.reload.to).to eq("https://example.org/theirs")
    end

    it "lets a superadmin update any URL" do
      user.update!(superadmin: true)
      other = create(:url)

      patch api_v1_url_path(other), params: {url: {to: "https://example.org/admin"}}, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "doesn't allow changing the shortcode" do
      patch api_v1_url_path(url), params: {url: {shortened: "renamed"}}, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]["details"]).to eq("shortened" => ["can't be changed"])
      expect(url.reload.shortened).not_to eq("renamed")
    end

    it "returns validation errors" do
      patch api_v1_url_path(url), params: {url: {to: "https://ex ample.org"}}, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(url.reload.to).to eq("https://example.org/original")
    end
  end

  describe "DELETE /api/v1/urls/:id" do
    it "lets the owner delete a URL" do
      url = create(:url, user: user)

      delete api_v1_url_path(url), headers: headers

      expect(response).to have_http_status(:no_content)
      expect(Url.exists?(url.id)).to be(false)
    end

    it "doesn't let a collaborator delete a shared URL" do
      shared = create(:url)
      share(shared, with: user)

      delete api_v1_url_path(shared), headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(Url.exists?(shared.id)).to be(true)
    end

    context "with a read-only token" do
      let(:access_level) { :read_only }

      it "refuses to delete" do
        url = create(:url, user: user)

        delete api_v1_url_path(url), headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(Url.exists?(url.id)).to be(true)
      end
    end
  end

  describe "GET /api/v1/urls/:id/qr" do
    let(:access_level) { :read_only }

    it "returns the QR code PNG with token authentication" do
      url = create(:url)

      get qr_api_v1_url_path(url), headers: {"Authorization" => "Bearer #{secret}"}

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.body.byteslice(0, 8).bytes).to eq([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    end

    it "requires a token" do
      get qr_api_v1_url_path(create(:url))

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
# rubocop:enable Metrics/BlockLength
