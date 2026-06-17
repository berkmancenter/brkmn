# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    can :manage, :all if user.superadmin?

    can :update, Url, user_id: user.id
    can :destroy, Url, user_id: user.id
    can :qr, Url, user_id: user.id
  end
end
