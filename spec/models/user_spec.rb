# frozen_string_literal: true

require "rails_helper"

UserSamlResponse = Struct.new(:mapped_values) do
  def attribute_value_by_resource_key(key)
    mapped_values[key]
  end
end

# rubocop:disable Metrics/BlockLength
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

  describe "#saml_extra_attributes=" do
    it "maps SAML email attributes to email and username" do
      user = described_class.new
      user.saml_extra_attributes = {mail: "saml-user@example.com"}

      expect(user.email).to eq("saml-user@example.com")
      expect(user.username).to eq("saml-user@example.com")
    end

    it "uses SAML username attributes when provided" do
      user = described_class.new
      user.saml_extra_attributes = {
        mail: "saml-user@example.com",
        uid: "saml-user"
      }

      expect(user.email).to eq("saml-user@example.com")
      expect(user.username).to eq("saml-user")
    end
  end

  describe "#apply_saml_response" do
    it "maps a SAML response to user attributes" do
      user = described_class.new
      saml_response = UserSamlResponse.new(
        {
          email: ["response-user@example.com"],
          username: ["response-user"]
        }
      )

      user.apply_saml_response(saml_response, "fallback@example.com")

      expect(user.email).to eq("response-user@example.com")
      expect(user.username).to eq("response-user")
    end

    it "uses the auth value when the SAML response does not include email" do
      user = described_class.new
      saml_response = UserSamlResponse.new({})

      user.apply_saml_response(saml_response, "fallback@example.com")

      expect(user.email).to eq("fallback@example.com")
      expect(user.username).to eq("fallback@example.com")
    end
  end
end
# rubocop:enable Metrics/BlockLength
