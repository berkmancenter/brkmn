# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Metrics/BlockLength
RSpec.describe Ability, type: :model do
  subject(:ability) { described_class.new(user) }

  let(:owner) { create(:user) }
  let(:owned_url) { create(:url, user: owner) }
  let(:other_url) { create(:url, user: create(:user)) }

  context "with a superadmin user" do
    let(:user) { create(:user, :superadmin) }

    it "can manage every URL" do
      expect(ability.can?(:update, other_url)).to be(true)
      expect(ability.can?(:destroy, other_url)).to be(true)
      expect(ability.can?(:qr, other_url)).to be(true)
    end
  end

  context "with a regular user" do
    let(:user) { owner }

    it "can update, destroy, and generate QR codes for owned URLs" do
      expect(ability.can?(:update, owned_url)).to be(true)
      expect(ability.can?(:destroy, owned_url)).to be(true)
      expect(ability.can?(:qr, owned_url)).to be(true)
    end

    it "cannot update, destroy, or generate QR codes for URLs owned by others" do
      expect(ability.can?(:update, other_url)).to be(false)
      expect(ability.can?(:destroy, other_url)).to be(false)
      expect(ability.can?(:qr, other_url)).to be(false)
    end

    it "can update a shared URL without receiving owner-only permissions" do
      UrlCollaborator.create!(url: other_url, user: user, granted_by: other_url.user)

      expect(ability.can?(:update, other_url)).to be(true)
      expect(ability.can?(:destroy, other_url)).to be(false)
      expect(ability.can?(:share, other_url)).to be(false)
    end
  end

  context "without a signed-in user" do
    let(:user) { nil }

    it "does not grant URL management abilities" do
      expect(ability.can?(:update, owned_url)).to be(false)
      expect(ability.can?(:destroy, owned_url)).to be(false)
      expect(ability.can?(:qr, owned_url)).to be(false)
    end
  end
end
# rubocop:enable Metrics/BlockLength
