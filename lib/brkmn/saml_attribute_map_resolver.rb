# frozen_string_literal: true

module Brkmn
  class SamlAttributeMapResolver
    DEFAULT_ATTRIBUTE_MAP = {
      "email" => "email",
      "mail" => "email",
      "EmailAddress" => "email",
      "emailAddress" => "email",
      "urn:mace:dir:attribute-def:mail" => "email",
      "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" => "email",
      "username" => "username",
      "uid" => "username",
      "eduPersonPrincipalName" => "username",
      "urn:mace:dir:attribute-def:uid" => "username",
      "first_name" => "first_name",
      "givenName" => "first_name",
      "given_name" => "first_name",
      "FirstName" => "first_name",
      "urn:mace:dir:attribute-def:givenName" => "first_name",
      "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" => "first_name",
      "last_name" => "last_name",
      "sn" => "last_name",
      "surname" => "last_name",
      "LastName" => "last_name",
      "urn:mace:dir:attribute-def:sn" => "last_name",
      "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" => "last_name",
      "displayName" => "display_name",
      "display_name" => "display_name",
      "name" => "display_name",
      "cn" => "display_name",
      "urn:mace:dir:attribute-def:displayName" => "display_name",
      "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name" => "display_name",
      "memberOf" => "member_of",
      "member_of" => "member_of",
      "urn:mace:dir:attribute-def:memberOf" => "member_of"
    }.freeze

    ENV_ATTRIBUTE_MAP = {
      "DEVISE_SAML_EMAIL_ATTRIBUTE" => "email",
      "DEVISE_SAML_USERNAME_ATTRIBUTE" => "username",
      "DEVISE_SAML_FIRST_NAME_ATTRIBUTE" => "first_name",
      "DEVISE_SAML_LAST_NAME_ATTRIBUTE" => "last_name",
      "DEVISE_SAML_DISPLAY_NAME_ATTRIBUTE" => "display_name",
      "DEVISE_SAML_MEMBER_OF_ATTRIBUTE" => "member_of"
    }.freeze

    def initialize(_saml_response)
    end

    def attribute_map
      DEFAULT_ATTRIBUTE_MAP.merge(env_attribute_map)
    end

    private

    def env_attribute_map
      ENV_ATTRIBUTE_MAP.each_with_object({}) do |(env_name, resource_key), map|
        ENV.fetch(env_name, "").split(",").map(&:strip).compact_blank.each do |saml_key|
          map[saml_key] = resource_key
        end
      end
    end
  end
end
