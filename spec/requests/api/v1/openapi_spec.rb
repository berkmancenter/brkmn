# frozen_string_literal: true

require "rails_helper"

# docs/api/openapi.yaml must describe the API that really runs: the same
# endpoints, and responses with the documented fields and types.
# rubocop:disable Metrics/BlockLength
RSpec.describe "API documentation (docs/api/openapi.yaml)", type: :request do
  let(:openapi) { YAML.safe_load_file(Rails.root.join("docs/api/openapi.yaml"), aliases: true) }
  # [verb, path, operation] for every documented endpoint.
  let(:operations) do
    openapi["paths"].flat_map do |path, item|
      item.slice("get", "post", "put", "patch", "delete").map { |verb, operation| [verb, path, operation] }
    end
  end

  def resolve(node)
    node = openapi.dig(*node["$ref"].delete_prefix("#/").split("/")) while node.is_a?(Hash) && node.key?("$ref")
    node
  end

  def response_schema(path, verb, status)
    response = resolve(openapi.dig("paths", path, verb, "responses", status.to_s))
    response.dig("content", "application/json", "schema")
  end

  # A small check for the parts of JSON schema the document uses.
  def schema_errors(value, schema, where = "response")
    schema = resolve(schema)
    return [] if value.nil? && schema["nullable"]

    errors = Array(schema["allOf"]).flat_map { |part| schema_errors(value, part, where) }
    errors += type_errors(value, schema, where)
    errors << "#{where} is #{value.inspect}, not one of #{schema["enum"]}" if schema["enum"]&.exclude?(value)
    errors
  end

  def type_errors(value, schema, where)
    case schema["type"]
    when "object" then object_errors(value, schema, where)
    when "array"
      return ["#{where} should be an array"] unless value.is_a?(Array)

      value.each_with_index.flat_map { |item, index| schema_errors(item, schema["items"], "#{where}[#{index}]") }
    when "integer" then value.is_a?(Integer) ? [] : ["#{where} should be an integer, is #{value.inspect}"]
    when "string" then value.is_a?(String) ? [] : ["#{where} should be a string, is #{value.inspect}"]
    when "boolean" then [true, false].include?(value) ? [] : ["#{where} should be true or false, is #{value.inspect}"]
    else []
    end
  end

  def object_errors(value, schema, where)
    return ["#{where} should be an object"] unless value.is_a?(Hash)

    properties = schema.fetch("properties", {})
    errors = (Array(schema["required"]) - value.keys).map { |key| "#{where}.#{key} is missing" }
    value.each do |key, item|
      if properties.key?(key)
        errors += schema_errors(item, properties[key], "#{where}.#{key}")
      elsif schema["additionalProperties"].is_a?(Hash)
        errors += schema_errors(item, schema["additionalProperties"], "#{where}.#{key}")
      elsif properties.any?
        errors << "#{where}.#{key} is not documented"
      end
    end
    errors
  end

  def expect_documented_response(path, verb)
    schema = response_schema(path, verb, response.status)
    expect(schema).to be_present, "#{verb.upcase} #{path} doesn't document a #{response.status} response"
    expect(schema_errors(json, schema)).to eq([])
  end

  describe "the document" do
    it "lists every API endpoint, and only those" do
      documented = operations.map { |verb, path, _operation| "#{verb.upcase} /api/v1#{path}" }
      routed = Rails.application.routes.routes.filter_map do |route|
        next unless route.defaults[:controller].to_s.start_with?("api/v1/")
        next if route.defaults[:action] == "route_not_found" || route.verb == "PUT" # update is documented as PATCH

        "#{route.verb} #{route.path.spec.to_s.delete_suffix("(.:format)").gsub(/:(\w+)/, '{\1}')}"
      end

      expect(documented).to match_array(routed)
    end

    it "only refers to things it defines" do
      refs = []
      find_refs = lambda do |node|
        case node
        when Hash then node.each { |key, child| key == "$ref" ? refs << child : find_refs.call(child) }
        when Array then node.each { |child| find_refs.call(child) }
        end
      end
      find_refs.call(openapi)

      expect(refs).not_to be_empty
      expect(refs.uniq.reject { |ref| openapi.dig(*ref.delete_prefix("#/").split("/")) }).to eq([])
    end

    it "documents the token and rate limit errors on every endpoint" do
      operations.each do |verb, path, operation|
        expect(operation["responses"].keys).to include("401", "429"), "#{verb.upcase} #{path}"
      end
    end

    it "has a unique operationId for every endpoint" do
      ids = operations.map { |_verb, _path, operation| operation["operationId"] }

      expect(ids).to all(be_present)
      expect(ids).to eq(ids.uniq)
    end
  end

  describe "the responses" do
    let(:user) { create(:user, confirmed_at: Time.current) }
    let(:editor) { create(:user) }
    let(:secret) { ApiToken.generate_secret }
    let!(:token) { create(:api_token, user: user, secret: secret, access_level: :read_write) }
    let(:headers) { api_headers(secret) }
    let!(:url) do
      create(:url, user: user, shortened: "documented").tap do |url|
        url.update!(last_edited_by: editor, last_edited_at: 1.hour.ago)
      end
    end

    it "match the schema for the account" do
      get api_v1_me_path, headers: headers
      expect_documented_response("/me", "get")
    end

    it "match the schema for lists, single URLs, creating and updating" do
      create(:url, user: create(:user))

      get api_v1_urls_path(scope: "all"), headers: headers
      expect_documented_response("/urls", "get")

      get api_v1_url_path(url), headers: headers
      expect_documented_response("/urls/{id}", "get")

      post api_v1_urls_path, params: {url: {to: "https://example.org/new"}}, headers: headers, as: :json
      expect_documented_response("/urls", "post")

      patch api_v1_url_path(url), params: {url: {to: "https://example.org/edited"}}, headers: headers, as: :json
      expect_documented_response("/urls/{id}", "patch")
    end

    it "match the schema for errors" do
      get api_v1_me_path
      expect_documented_response("/me", "get")

      post api_v1_urls_path, params: {url: {to: "https://"}}, headers: headers, as: :json
      expect_documented_response("/urls", "post")

      post api_v1_urls_path, params: {}, headers: headers, as: :json
      expect_documented_response("/urls", "post")

      get api_v1_url_path(id: 0), headers: headers
      expect_documented_response("/urls/{id}", "get")

      delete api_v1_url_path(create(:url, user: create(:user))), headers: headers
      expect_documented_response("/urls/{id}", "delete")
    end
  end
end
# rubocop:enable Metrics/BlockLength
