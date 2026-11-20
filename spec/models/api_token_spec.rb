# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe ApiToken, type: :model do
  let(:user) { create(:user) }

  describe ".generate_secret" do
    it "creates a long random secret with a recognizable prefix" do
      secret = described_class.generate_secret

      expect(secret).to start_with("brkmn_")
      expect(secret.length).to eq("brkmn_".length + ApiToken::SECRET_LENGTH)
      expect(described_class.generate_secret).not_to eq(secret)
    end
  end

  describe "#issue_secret" do
    it "stores only a digest and a short display prefix" do
      token = described_class.new(user: user, name: "CI", lifetime_days: 30)
      secret = token.issue_secret

      expect(token).to be_persisted
      expect(token.token_digest).to eq(described_class.digest(secret))
      expect(token.token_digest).not_to include(secret)
      expect(token.token_prefix).to eq(secret.first(ApiToken::VISIBLE_PREFIX_LENGTH))
      expect(token.expires_at).to be_within(5.seconds).of(30.days.from_now)
      expect(described_class.find_for_secret(secret)).to eq(token)
    end

    it "leaves the token without an expiry when it has no lifetime" do
      token = described_class.new(user: user, name: "Forever", lifetime_days: nil)
      token.issue_secret

      expect(token.expires_at).to be_nil
    end

    it "invalidates the previous secret when regenerating" do
      old_secret = ApiToken.generate_secret
      token = create(:api_token, user: user, secret: old_secret, last_used_at: 1.hour.ago)

      new_secret = token.issue_secret

      expect(described_class.find_for_secret(old_secret)).to be_nil
      expect(described_class.find_for_secret(new_secret)).to eq(token)
      expect(token.last_used_at).to be_nil
    end

    it "refuses to regenerate a revoked token" do
      token = create(:api_token, :revoked, user: user)

      expect(token.issue_secret).to be_nil
      expect(token.errors[:base]).to include("A revoked token can't be regenerated.")
    end

    it "returns nil when the token is invalid" do
      token = described_class.new(user: user, name: "")

      expect(token.issue_secret).to be_nil
      expect(token).not_to be_persisted
    end

    it "reports an unknown access level as a validation error" do
      token = described_class.new(user: user, name: "Bad", access_level: "admin")

      expect(token).not_to be_valid
      expect(token.errors[:access_level]).to be_present
    end
  end

  describe "#status" do
    it "derives each state" do
      expect(create(:api_token).status).to eq(:active)
      expect(create(:api_token, lifetime_days: nil, expires_at: nil).status).to eq(:active)
      expect(create(:api_token, :expired).status).to eq(:expired)
      expect(create(:api_token, :revoked).status).to eq(:revoked)
      expect(create(:api_token, :expired, :revoked).status).to eq(:revoked)
      expect(create(:api_token, token_digest: nil, token_prefix: nil, expires_at: nil).status).to eq(:pending)
    end

    it "matches the status scopes" do
      active = create(:api_token)
      expired = create(:api_token, :expired)
      revoked = create(:api_token, :revoked)
      pending = create(:api_token, token_digest: nil, token_prefix: nil, expires_at: nil)

      expect(described_class.active).to contain_exactly(active)
      expect(described_class.expired).to contain_exactly(expired)
      expect(described_class.revoked).to contain_exactly(revoked)
      expect(described_class.pending).to contain_exactly(pending)
    end
  end

  describe "claim links" do
    let(:token) { described_class.new(user: user, name: "Partner", lifetime_days: 30) }

    it "issues a claim link that can be collected exactly once" do
      claim_token = token.issue_claim

      expect(token).to be_pending
      expect(token.claim_digest).to eq(described_class.digest(claim_token))
      expect(token.claim_expires_at).to be_within(5.seconds).of(ApiToken::CLAIM_LINK_LIFETIME.from_now)

      found = described_class.find_for_claim(claim_token)
      secret = found.claim(claim_token)

      expect(found.reload.status).to eq(:active)
      expect(found.claimed_at).to be_present
      expect(found.expires_at).to be_within(5.seconds).of(30.days.from_now)
      expect(described_class.find_for_secret(secret)).to eq(found)
      expect(described_class.find_for_claim(claim_token)).to be_nil
      expect(found.claim(claim_token)).to be_nil
    end

    it "can't be collected after the link expires" do
      claim_token = token.issue_claim
      token.update!(claim_expires_at: 1.minute.ago)

      expect(described_class.find_for_claim(claim_token)).to be_claim_expired
      expect(token.claim(claim_token)).to be_nil
      expect(token.reload.token_digest).to be_nil
    end

    it "stops the current secret working when a new link is issued" do
      secret = ApiToken.generate_secret
      issued = create(:api_token, user: user, secret: secret)

      issued.issue_claim

      expect(described_class.find_for_secret(secret)).to be_nil
      expect(issued).to be_pending
    end

    it "can't be collected after the token is revoked" do
      claim_token = token.issue_claim
      token.revoke!(by: create(:user, :superadmin))

      expect(described_class.find_for_claim(claim_token)).to be_nil
      expect(token.claim(claim_token)).to be_nil
    end

    it "doesn't exchange an obsolete claim after a new link is issued" do
      old_claim_token = token.issue_claim
      stale_token = described_class.find_for_claim(old_claim_token)
      new_claim_token = token.issue_claim

      expect(stale_token.claim(old_claim_token)).to be_nil
      expect(described_class.find_for_claim(new_claim_token)).to eq(token)
      expect(token.reload).to be_claimable
    end
  end

  describe "#revoke!" do
    it "records who revoked the token and when" do
      admin = create(:user, :superadmin)
      token = create(:api_token, user: user)

      token.revoke!(by: admin)

      expect(token.reload).to be_revoked
      expect(token.revoked_by).to eq(admin)
      expect(token.revoked_at).to be_within(5.seconds).of(Time.current)
    end

    it "keeps the original details when revoked twice" do
      first_admin = create(:user, :superadmin)
      token = create(:api_token, user: user)
      token.revoke!(by: first_admin)

      token.revoke!(by: create(:user, :superadmin))

      expect(token.reload.revoked_by).to eq(first_admin)
    end
  end

  describe "#record_use!" do
    it "writes last_used_at at most once per precision window" do
      token = create(:api_token, user: user)

      token.record_use!
      first_use = token.reload.last_used_at
      expect(first_use).to be_present

      token.record_use!
      expect(token.reload.last_used_at).to eq(first_use)

      travel(ApiToken::LAST_USED_PRECISION + 1.second) do
        token.record_use!
        expect(token.reload.last_used_at).to be > first_use
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
