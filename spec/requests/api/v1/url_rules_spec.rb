# frozen_string_literal: true

require "rails_helper"

# The website's rules for links (destinations, short codes, search, who can
# do what) apply to the API in the same way.
# rubocop:disable Metrics/BlockLength
RSpec.describe "API v1 URL rules", type: :request do
  let(:user) { create(:user) }
  let(:secret) { ApiToken.generate_secret }
  let(:access_level) { :read_write }
  let!(:token) { create(:api_token, user: user, secret: secret, access_level: access_level) }
  let(:headers) { api_headers(secret) }

  def create_url(attributes)
    post api_v1_urls_path, params: {url: attributes}, headers: headers, as: :json
  end

  describe "destinations" do
    it "keeps a URL inside the query as it is" do
      create_url(to: "https://example.org/login?next=https://other.example.org/page")

      expect(response).to have_http_status(:created)
      expect(json["url"]["to"]).to eq("https://example.org/login?next=https://other.example.org/page")
    end

    it "adds https:// and fixes doubled or upper case protocols" do
      {
        "example.org/page" => "https://example.org/page",
        "https://http://example.org/page" => "http://example.org/page",
        "HTTPS://Example.org/Page" => "https://Example.org/Page"
      }.each do |given, saved|
        create_url(to: given)

        expect(response).to have_http_status(:created)
        expect(json["url"]["to"]).to eq(saved)
      end
    end

    it "rejects a destination without a host, other schemes and the site itself" do
      ["https://", "ftp://example.org/file", "http://localhost:3000/urls", "https://#{REDIRECT_DOMAIN}/loop"]
        .each do |destination|
          expect { create_url(to: destination) }.not_to change(Url, :count)
          expect(response).to have_http_status(:unprocessable_content)
          expect(json["error"]["details"]).to have_key("to")
        end
    end

    it "uses the same rules when the destination changes" do
      url = create(:url, user: user, to: "https://example.org/old")

      patch api_v1_url_path(url), params: {url: {to: "https://"}}, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(url.reload.to).to eq("https://example.org/old")
    end
  end

  describe "short codes" do
    it "refuses codes the site uses for its own pages and files" do
      %w[urls api settings up manifest robots.txt 404 sidekiq].each do |code|
        expect { create_url(to: "https://example.org", shortened: code) }.not_to change(Url, :count)
        expect(json["error"]["details"]["shortened"].join).to include("conflicts with a valid site URL")
      end
    end

    it "refuses characters that can't be in a URL" do
      create_url(to: "https://example.org", shortened: "no spaces")

      expect(json["error"]["details"]["shortened"]).to include("contains invalid URL characters.")
    end

    it "makes a short link that redirects and counts the clicks" do
      create_url(to: "https://example.org/target", shortened: "from-api")
      id = json["url"]["id"]

      2.times { get "/from-api" }
      expect(response).to redirect_to("https://example.org/target")

      get api_v1_url_path(id), headers: headers
      expect(json["url"]["clicks"]).to eq(2)
    end

    it "accepts the current code in an update" do
      url = create(:url, user: user, shortened: "keep-me")

      patch api_v1_url_path(url),
        params: {url: {shortened: "keep-me", to: "https://example.org/new"}},
        headers: headers,
        as: :json

      expect(response).to have_http_status(:ok)
      expect(url.reload).to have_attributes(shortened: "keep-me", to: "https://example.org/new")
    end
  end

  describe "search and pages" do
    it "treats % and _ in the search as plain characters" do
      underscore = create(:url, user: user, shortened: "a_b")
      create(:url, user: user, shortened: "axb")

      get api_v1_urls_path(search: "a_b"), headers: headers
      expect(json["urls"].pluck("id")).to eq([underscore.id])

      get api_v1_urls_path(search: "%"), headers: headers
      expect(json["urls"]).to be_empty
    end

    it "shows at least one URL per page and an empty page after the last one" do
      create_list(:url, 2, user: user)

      get api_v1_urls_path(per_page: 0), headers: headers
      expect(json["meta"]).to include("per_page" => 1, "total_pages" => 2)

      get api_v1_urls_path(page: 99), headers: headers
      expect(json["urls"]).to be_empty
      expect(json["meta"]).to include("page" => 99, "total_count" => 2)
    end
  end

  context "with a read-only token" do
    let(:access_level) { :read_only }
    let(:url) { create(:url, user: user, to: "https://example.org/old") }

    it "can't change a destination, even of an own URL" do
      patch api_v1_url_path(url), params: {url: {to: "https://example.org/new"}}, headers: headers, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json["error"]["code"]).to eq("insufficient_scope")
      expect(url.reload.to).to eq("https://example.org/old")
    end

    it "can still get QR codes" do
      get qr_api_v1_url_path(url), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
    end
  end

  describe "deleting" do
    it "lets a superadmin delete anybody's URL" do
      user.update!(superadmin: true)
      url = create(:url, user: create(:user))

      expect do
        delete api_v1_url_path(url), headers: headers
      end.to change(Url, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "removes the URL's editors and access requests too" do
      url = create(:url, user: user)
      UrlCollaborator.create!(url: url, user: create(:user), granted_by: user)
      UrlAccessRequest.create!(url: url, user: create(:user))

      delete api_v1_url_path(url), headers: headers

      expect(response).to have_http_status(:no_content)
      expect(UrlCollaborator.where(url_id: url.id)).to be_empty
      expect(UrlAccessRequest.where(url_id: url.id)).to be_empty
    end

    it "returns JSON 404 for a URL that is already gone" do
      url = create(:url, user: user)
      url.destroy!

      delete api_v1_url_path(url), headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json["error"]["code"]).to eq("not_found")
    end
  end
end
# rubocop:enable Metrics/BlockLength
