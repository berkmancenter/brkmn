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

  describe "API-only accounts" do
    let(:api_user) { create(:user, api_only: true, confirmed_at: Time.current) }

    it "can't sign in to the website" do
      expect(api_user.active_for_authentication?).to be(false)
      expect(api_user.inactive_message).to eq(:api_only)
      expect(create(:user, confirmed_at: Time.current).active_for_authentication?).to be(true)
    end

    it "doesn't get password reset emails" do
      expect do
        api_user.send_reset_password_instructions
      end.not_to change(ActionMailer::Base.deliveries, :count)
    end

    it "becomes a regular account on CAS sign-in" do
      api_user.cas_extra_attributes = {mail: api_user.email}

      expect(api_user.api_only).to be(false)
    end

    it "becomes a regular account on SAML sign-in" do
      api_user.apply_saml_response(UserSamlResponse.new({email: api_user.email}), api_user.email)

      expect(api_user.api_only).to be(false)
    end

    it "keeps the SSO decision when matched to the stored account by email" do
      signing_in = described_class.new(username: "sso-name")
      signing_in.cas_extra_attributes = {mail: api_user.email}

      signing_in.send(:match_existing_user)
      signing_in.save!

      expect(signing_in.id).to eq(api_user.id)
      expect(signing_in.api_only).to be(false)
      expect(api_user.reload.api_only).to be(false)
    end

    it "becomes a regular account when the auth proxy vouches for it" do
      user = described_class.from_auth_headers(email: api_user.email, name: "proxy-name")

      expect(user).to eq(api_user)
      expect(user.api_only).to be(false)
    end
  end
end
# rubocop:enable Metrics/BlockLength
