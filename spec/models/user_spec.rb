# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "#set_username" do
    it "uses the email address when a database-auth user has no username" do
      user = build(:user, username: nil, email: "person@example.com")

      expect(user.save).to be(true)
      expect(user.username).to eq("person@example.com")
    end
  end

  describe "#cas_extra_attributes=" do
    it "maps the CAS mail attribute to email" do
      user = described_class.new
      user.cas_extra_attributes = {mail: "cas-user@example.com"}

      expect(user.email).to eq("cas-user@example.com")
    end
  end
end
