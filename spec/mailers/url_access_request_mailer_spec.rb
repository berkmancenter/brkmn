# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe UrlAccessRequestMailer, type: :mailer do
  describe "owner notification" do
    let(:owner) { create(:user) }
    let(:requester) { create(:user) }
    let(:url) { create(:url, user: owner) }
    let(:access_request) { UrlAccessRequest.create!(url: url, user: requester) }
    let(:mail) { described_class.with(access_request: access_request).owner_notification }

    it "emails the owner with the requester and link details" do
      expect(mail.to).to eq([owner.email])
      expect(mail.from).to eq([Rails.application.config.default_sender])
      expect(mail.subject).to eq("Edit access requested for #{url.shortened}")
      expect(mail.html_part.body.decoded).to include(requester.email, url.shortened, url.to)
      expect(mail.text_part.body.decoded).to include(requester.email, url.shortened, url.to)
      expect(mail.body.decoded).not_to include(shortened_url(url.shortened))
    end
  end

  describe "approval notification" do
    let(:owner) { create(:user) }
    let(:requester) { create(:user) }
    let(:url) { create(:url, user: owner) }
    let(:access_request) { UrlAccessRequest.create!(url: url, user: requester) }
    let(:mail) { described_class.with(access_request: access_request).approval_notification }

    it "emails the requester with a link to edit" do
      expect(mail.to).to eq([requester.email])
      expect(mail.subject).to eq("Edit access approved for #{url.shortened}")
      expect(mail.html_part.body.decoded).to include(url.shortened, url.to, edit_url_url(url))
      expect(mail.text_part.body.decoded).to include(url.shortened, url.to, edit_url_url(url))
      expect(mail.body.decoded).not_to include(shortened_url(url.shortened))
    end
  end

  describe "denial notification" do
    let(:owner) { create(:user) }
    let(:requester) { create(:user) }
    let(:url) { create(:url, user: owner) }
    let(:access_request) { UrlAccessRequest.create!(url: url, user: requester) }
    let(:mail) { described_class.with(access_request: access_request).denial_notification }

    it "emails the requester with the denied link details" do
      expect(mail.to).to eq([requester.email])
      expect(mail.subject).to eq("Edit access request denied for #{url.shortened}")
      expect(mail.html_part.body.decoded).to include(url.shortened, url.to)
      expect(mail.text_part.body.decoded).to include(url.shortened, url.to)
      expect(mail.body.decoded).not_to include(shortened_url(url.shortened))
    end
  end
end
# rubocop:enable Metrics/BlockLength
