# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe UrlCollaboratorMailer, type: :mailer do
  describe "grant notification" do
    let(:owner) { create(:user) }
    let(:collaborator) { create(:user) }
    let(:url) { create(:url, user: owner) }
    let(:mail) { described_class.with(url: url, user: collaborator).grant_notification }

    it "emails the collaborator with an edit link but no short URL" do
      expect(mail.to).to eq([collaborator.email])
      expect(mail.from).to eq([Rails.application.config.default_sender])
      expect(mail.subject).to eq("Edit access granted for #{url.shortened}")
      expect(mail.html_part.body.decoded).to include(url.shortened, url.to, edit_url_url(url))
      expect(mail.text_part.body.decoded).to include(url.shortened, url.to, edit_url_url(url))
      expect(mail.body.decoded).not_to include(shortened_url(url.shortened))
    end
  end

  describe "removal notification" do
    let(:owner) { create(:user) }
    let(:collaborator) { create(:user) }
    let(:url) { create(:url, user: owner) }
    let(:mail) { described_class.with(url: url, user: collaborator).removal_notification }

    it "emails the former collaborator without linking to the short URL" do
      expect(mail.to).to eq([collaborator.email])
      expect(mail.from).to eq([Rails.application.config.default_sender])
      expect(mail.subject).to eq("Edit access removed for #{url.shortened}")
      expect(mail.html_part.body.decoded).to include(url.shortened, url.to)
      expect(mail.text_part.body.decoded).to include(url.shortened, url.to)
      expect(mail.body.decoded).not_to include(shortened_url(url.shortened))
    end
  end
end
# rubocop:enable Metrics/BlockLength
