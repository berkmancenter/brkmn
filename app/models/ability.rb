# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    can :manage, :all if user.superadmin?

    can :read, Url
    can :update, Url do |url|
      url.url_collaborators.any? { |collaboration| collaboration.user_id == user.id }
    end
    can :update, Url, user_id: user.id
    can :destroy, Url, user_id: user.id
    can :qr, Url, user_id: user.id
    can :share, Url, user_id: user.id
  end
end
