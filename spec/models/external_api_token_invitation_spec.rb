# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe ExternalApiTokenInvitation, type: :model do
  let!(:admin) { create(:user, :superadmin) }
  let(:attributes) do
    {
      email: " Partner@Example.org ",
      name: "Newsletter",
      note: "Weekly digest links",
      access_level: "read_write",
      lifetime_days: "30"
    }
  end

  it "creates an API-only user and a pending token with a claim link" do
    invitation = described_class.new(attributes)

    expect do
      expect(invitation.save(created_by: admin)).to be(true)
    end.to change(User, :count).by(1).and change(ApiToken, :count).by(1)

    user = User.find_by(email: "partner@example.org")
    expect(user).to have_attributes(api_only: true, username: "partner@example.org")
    expect(user).to be_confirmed
    expect(user.active_for_authentication?).to be(false)

    token = invitation.api_token
    expect(token).to have_attributes(
      user: user,
      name: "Newsletter",
      note: "Weekly digest links",
      access_level: "read_write",
      lifetime_days: 30,
      created_by: admin
    )
    expect(token).to be_pending
    expect(ApiToken.find_for_claim(invitation.claim_token)).to eq(token)
  end

  it "refuses an email that belongs to an existing account" do
    create(:user, email: "partner@example.org")
    invitation = described_class.new(attributes)

    expect do
      expect(invitation.save(created_by: admin)).to be(false)
    end.not_to change(User, :count)

    expect(invitation.errors[:email].first).to include("already belongs to an account")
  end

  it "points to “Send new link” when the email already has external access" do
    create(:user, email: "partner@example.org", api_only: true)
    invitation = described_class.new(attributes)

    expect(invitation.save(created_by: admin)).to be(false)
    expect(invitation.errors[:email].first).to include("Send new link")
  end

  it "refuses an email used as another account's username" do
    create(:user, username: "partner@example.org", email: "someone-else@example.org")
    invitation = described_class.new(attributes)

    expect(invitation.save(created_by: admin)).to be(false)
    expect(invitation.errors[:email]).to be_present
  end

  it "requires an expiry from the listed choices" do
    invitation = described_class.new(attributes.merge(lifetime_days: ""))

    expect(invitation.save(created_by: admin)).to be(false)
    expect(invitation.errors[:lifetime_days]).to be_present
  end

  it "rolls back the user when the token is invalid" do
    invitation = described_class.new(attributes.merge(access_level: "superuser"))

    expect do
      expect(invitation.save(created_by: admin)).to be(false)
    end.not_to change(User, :count)

    expect(invitation.errors[:access_level]).to be_present
    expect(invitation.api_token).to be_nil
  end

  it "normalizes the email address" do
    expect(described_class.new(email: "  Partner@Example.org ").email).to eq("partner@example.org")
  end

  it "validates the email format" do
    invitation = described_class.new(attributes.merge(email: "not an email"))

    expect(invitation).not_to be_valid
    expect(invitation.errors[:email]).to be_present
  end
end
# rubocop:enable Metrics/BlockLength
