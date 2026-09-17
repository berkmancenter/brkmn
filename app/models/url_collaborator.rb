# frozen_string_literal: true

# == Schema Information
#
# Table name: url_collaborators
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  granted_by_id :bigint
#  url_id        :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_url_collaborators_on_granted_by_id       (granted_by_id)
#  index_url_collaborators_on_url_id              (url_id)
#  index_url_collaborators_on_url_id_and_user_id  (url_id,user_id) UNIQUE
#  index_url_collaborators_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (granted_by_id => users.id)
#  fk_rails_...  (url_id => urls.id)
#  fk_rails_...  (user_id => users.id)
#
class UrlCollaborator < ApplicationRecord
  belongs_to :url
  belongs_to :user
  belongs_to :granted_by,
    class_name: "User",
    optional: true,
    inverse_of: :granted_url_collaborations

  validates :user_id, uniqueness: {scope: :url_id}
  validate :user_is_not_owner

  private

  def user_is_not_owner
    errors.add(:user, "already owns this link") if url&.user_id == user_id
  end
end
