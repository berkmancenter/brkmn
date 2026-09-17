# frozen_string_literal: true

class UrlCollaboratorsController < ApplicationController
  include UrlSharing

  def create
    authorize! :share, @url
    user = find_user
    error_message = sharing_error(user)

    return render_modal_error(error_message) if error_message.present?

    render_modal_update(grant_access(user), refresh: :people_with_access)
  end

  def destroy
    authorize! :share, @url
    collaborator = @url.url_collaborators.find(params[:id])
    user = collaborator.user

    collaborator.destroy!
    @url.url_access_requests.pending.where(user: user).find_each do |request|
      request.resolve!(:denied, by: current_user)
    end
    notify_access_removed(user)
    render_modal_update(
      "Edit access was removed from #{user.email || user.username}.",
      refresh: :people_with_access
    )
  end

  private

  def sharing_error(user)
    if user.blank?
      "No user was found with that email address."
    elsif @url.owned_by?(user)
      "The owner already has full access to this link."
    end
  end

  def notify_access_removed(user)
    return if user.email.blank?

    UrlCollaboratorMailer.with(url: @url, user: user).removal_notification.deliver_later
  end

  def find_user
    email = params[:email].to_s.strip.downcase
    return if email.blank?

    User.where("LOWER(email) = ?", email).first
  end

  def grant_access(user)
    collaboration = @url.grant_edit_access_to(user, granted_by: current_user)
    notify_access_granted(user) if collaboration.previously_new_record?
    resolve_request(user)
    "#{user.email || user.username} can now edit this link."
  end

  def notify_access_granted(user)
    return if user.email.blank?

    UrlCollaboratorMailer.with(url: @url, user: user).grant_notification.deliver_later
  end

  def resolve_request(user)
    request = @url.url_access_requests.find_by(user: user)
    request&.resolve!(:approved, by: current_user)
  end
end
