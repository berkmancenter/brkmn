# frozen_string_literal: true

module Brkmn
  # The API tokens of the demo data (see Brkmn::DemoData). Their secrets come
  # from the demo random seed, so the report can show them and the same
  # secrets work after every load. Only the digests are stored, as always.
  class DemoApiTokens
    BASE58 = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    URL_SAFE = [*"A".."Z", *"a".."z", *"0".."9", "-", "_"].join.freeze
    CLAIM_TOKEN_LENGTH = 43 # like SecureRandom.urlsafe_base64(32)

    # A token of the data file with its secret, or with the claim link token
    # when nobody collected it yet.
    Plan = Struct.new(:data, :secret, :claim_token, keyword_init: true) do
      def name = data[:name]
      def email = DemoData.email_for(data[:user])
      def claim_path = "/api/token_claim?token=#{claim_token}"

      def token
        secret ? ApiToken.find_for_secret(secret) : ApiToken.find_for_claim(claim_token)
      end
    end

    attr_reader :plans

    def initialize(tokens_data, random_seed:)
      random = Random.new(random_seed)
      @plans = Array(tokens_data).map do |data|
        if data[:claim] == "pending"
          Plan.new(data: data, claim_token: pick(random, URL_SAFE, CLAIM_TOKEN_LENGTH))
        else
          Plan.new(data: data, secret: ApiToken::SECRET_PREFIX + pick(random, BASE58, ApiToken::SECRET_LENGTH))
        end
      end
    end

    # Makes the tokens again. Tokens demo users made while playing are removed.
    def load(users)
      ApiToken.where(user_id: users.values.map(&:id)).destroy_all
      plans.each { |plan| create(plan, users) }
    end

    def named(name)
      plans.find { |plan| plan.name == name }
    end

    private

    def pick(random, characters, length)
      Array.new(length) { characters[random.rand(characters.length)] }.join
    end

    def create(plan, users)
      data = plan.data
      created_at = DemoData.ago(data[:created])
      token = ApiToken.new(
        user: users.fetch(data[:user].to_sym),
        created_by: users.fetch((data[:created_by] || data[:user]).to_sym),
        name: data[:name],
        note: data[:note],
        access_level: data[:access],
        lifetime_days: data[:lifetime_days],
        created_at: created_at,
        updated_at: created_at
      )
      plan.secret ? issue(token, plan) : token.assign_attributes(claim_link(plan, created_at))
      revoke(token, data, users) if data[:revoked]
      token.save!
    end

    # Like ApiToken#issue_secret, at the time the token was made or collected.
    def issue(token, plan)
      data = plan.data
      issued_at = DemoData.ago(data[:claimed] || data[:created])
      token.assign_attributes(
        token_digest: ApiToken.digest(plan.secret),
        token_prefix: plan.secret.first(ApiToken::VISIBLE_PREFIX_LENGTH),
        expires_at: data[:lifetime_days] && (issued_at + data[:lifetime_days].days),
        last_used_at: data[:last_used] && DemoData.ago(data[:last_used]),
        claimed_at: data[:claimed] && issued_at
      )
    end

    def claim_link(plan, created_at)
      {
        claim_digest: ApiToken.digest(plan.claim_token),
        claim_expires_at: created_at + ApiToken::CLAIM_LINK_LIFETIME
      }
    end

    def revoke(token, data, users)
      token.assign_attributes(
        revoked_at: DemoData.ago(data[:revoked]),
        revoked_by: users.fetch(data[:revoked_by].to_sym)
      )
    end
  end
end
