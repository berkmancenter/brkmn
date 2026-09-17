# frozen_string_literal: true

# == Schema Information
#
# Table name: url_access_requests
#
#  id             :bigint           not null, primary key
#  resolved_at    :datetime
#  status         :integer          default("pending"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  resolved_by_id :bigint
#  url_id         :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_url_access_requests_on_resolved_by_id      (resolved_by_id)
#  index_url_access_requests_on_url_id              (url_id)
#  index_url_access_requests_on_url_id_and_user_id  (url_id,user_id) UNIQUE
#  index_url_access_requests_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (resolved_by_id => users.id)
#  fk_rails_...  (url_id => urls.id)
#  fk_rails_...  (user_id => users.id)
#
class UrlAccessRequest < ApplicationRecord
  belongs_to :url
  belongs_to :user
  belongs_to :resolved_by,
    class_name: "User",
    optional: true,
    inverse_of: :resolved_url_access_requests

  enum :status, {pending: 0, approved: 1, denied: 2}

  validates :user_id, uniqueness: {scope: :url_id}
  validate :pending_requester_needs_access, if: :pending?

  def resolve!(decision, by:)
    update!(status: decision, resolved_by: by, resolved_at: Time.current)
  end

  private

  def pending_requester_needs_access
    return if url.blank? || user.blank?

    errors.add(:user, "already has edit access") if url.editable_by?(user)
  end
end
