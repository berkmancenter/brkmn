# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe ApiTokenMailer, type: :mailer do
  describe "claim instructions" do
    let(:admin) { create(:user, :superadmin) }
    let(:user) { create(:user, email: "partner@example.org", api_only: true) }
    let(:api_token) do
      ApiToken.new(
        user: user,
        name: "Newsletter",
        note: "Weekly digest",
        access_level: :read_write,
        lifetime_days: 30,
        created_by: admin
      )
    end
    let!(:claim_token) { api_token.issue_claim }
    let(:mail) { described_class.with(api_token: api_token, claim_token: claim_token).claim_instructions }

    it "emails a single-use link with the token details" do
      claim_url = api_token_claim_url(token: claim_token)

      expect(URI(claim_url).path).to eq("/api/token_claim")
      expect(mail.to).to eq(["partner@example.org"])
      expect(mail.from).to eq([Rails.application.config.default_sender])
      expect(mail.subject).to eq("Your #{REDIRECT_DOMAIN} API access token")
      [mail.html_part.body.decoded, mail.text_part.body.decoded].each do |body|
        expect(body).to include(admin.email, "Newsletter", "30 days", "Weekly digest", "Authorization: Bearer")
        expect(body).to include("http://www.example.com/api/v1")
      end
      expect(mail.html_part.body.decoded).to include("Read &amp; write", CGI.escapeHTML(claim_url))
      expect(mail.text_part.body.decoded).to include("Read & write", claim_url)
    end
  end
end
# rubocop:enable Metrics/BlockLength
