# frozen_string_literal: true

module Brkmn
  class SamlMemberOfValidator
    DEFAULT_ATTRIBUTE_NAMES = %w[memberOf member_of urn:mace:dir:attribute-def:memberOf].freeze

    def initialize(saml_response)
      @saml_response = saml_response
    end

    def valid?
      return true if required_member_of.blank?

      member_of_values.intersect?(required_member_of)
    end

    private

    attr_reader :saml_response

    def member_of_values
      values = normalized_values(saml_response.attribute_value_by_resource_key(:member_of))

      if saml_response.respond_to?(:attributes)
        attribute_names.each do |attribute_name|
          values.concat(normalized_values(saml_response.attributes.value_by_saml_attribute_key(attribute_name)))
        end
      end

      values.uniq
    end

    def attribute_names
      configured_attribute_names =
        ENV.fetch("DEVISE_SAML_MEMBER_OF_ATTRIBUTE", "")
          .split(",")
          .map(&:strip)
          .compact_blank

      configured_attribute_names.presence || DEFAULT_ATTRIBUTE_NAMES
    end

    def required_member_of
      @required_member_of ||=
        ENV.fetch("DEVISE_SAML_REQUIRED_MEMBER_OF", "")
          .gsub("\\n", "\n")
          .split(/[\n;]/)
          .map(&:strip)
          .compact_blank
    end

    def normalized_values(value)
      Array(value).flatten.map { |item| item.to_s.strip }.compact_blank
    end
  end
end
