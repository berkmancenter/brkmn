# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe Brkmn::SamlAttributeMapResolver do
  around do |example|
    original_email_attribute = ENV["DEVISE_SAML_EMAIL_ATTRIBUTE"]
    original_username_attribute = ENV["DEVISE_SAML_USERNAME_ATTRIBUTE"]
    original_member_of_attribute = ENV["DEVISE_SAML_MEMBER_OF_ATTRIBUTE"]
    ENV["DEVISE_SAML_EMAIL_ATTRIBUTE"] = "customEmail"
    ENV["DEVISE_SAML_USERNAME_ATTRIBUTE"] = "customUsername"
    ENV["DEVISE_SAML_MEMBER_OF_ATTRIBUTE"] = "customMemberOf"

    example.run
  ensure
    ENV["DEVISE_SAML_EMAIL_ATTRIBUTE"] = original_email_attribute
    ENV["DEVISE_SAML_USERNAME_ATTRIBUTE"] = original_username_attribute
    ENV["DEVISE_SAML_MEMBER_OF_ATTRIBUTE"] = original_member_of_attribute
  end

  it "maps common and configured SAML attributes to user attributes" do
    attribute_map = described_class.new(nil).attribute_map

    {
      "mail" => "email",
      "customEmail" => "email",
      "uid" => "username",
      "customUsername" => "username",
      "givenName" => "first_name",
      "sn" => "last_name",
      "displayName" => "display_name",
      "memberOf" => "member_of",
      "customMemberOf" => "member_of"
    }.each do |saml_key, resource_key|
      expect(attribute_map[saml_key]).to eq(resource_key)
    end
  end
end
# rubocop:enable Metrics/BlockLength
