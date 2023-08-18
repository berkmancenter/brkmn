# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.superadmin == true
      can :manage, :all
    end

    if user.present?
      can :update, Url, user_id: user.id
      can :destroy, Url, user_id: user.id
      can :qr, Url, user_id: user.id
    end
  end
end
