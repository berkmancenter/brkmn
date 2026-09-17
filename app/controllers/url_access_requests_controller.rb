# frozen_string_literal: true

class UrlAccessRequestsController < ApplicationController
  include UrlSharing

  def create
    message = if @url.editable_by?(current_user)
                "You already have edit access to this link."
              else
                request_access
              end

    render_modal_update(message, refresh: :access_request_footer)
  end

  def update
    authorize! :share, @url
    request = @url.url_access_requests.find(params[:id])

    return render_modal_error("This request has already been resolved.") unless request.pending?

    message, people_changed = if params[:decision] == "approve"
                                [approve(request), true]
                              elsif params[:decision] == "deny"
                                [deny(request), false]
                              else
                                return render_modal_error("Choose whether to approve or deny the request.")
                              end

    regions = [:access_requests]
    regions << :people_with_access if people_changed
    render_modal_update(message, refresh: regions)
  end

  private

  def request_access(retrying: false)
    request = @url.url_access_requests.find_or_initialize_by(user: current_user)
    should_notify_owner = request.new_record? || !request.pending?
    request.assign_attributes(status: :pending, resolved_by: nil, resolved_at: nil)
    request.save!
    notify_owner(request) if should_notify_owner
    "Your edit access request was sent to the link owner."
  rescue ActiveRecord::RecordNotUnique
    raise if retrying

    request_access(retrying: true)
  end

  def notify_owner(request)
    UrlAccessRequestMailer.with(access_request: request).owner_notification.deliver_later
  end

  def approve(request)
    UrlAccessRequest.transaction do
      request.resolve!(:approved, by: current_user)
      @url.grant_edit_access_to(request.user, granted_by: current_user)
    end
    notify_requester(request, :approval_notification)
    "#{request.user.email || request.user.username} can now edit this link."
  end

  def deny(request)
    request.resolve!(:denied, by: current_user)
    notify_requester(request, :denial_notification)
    "The edit access request was denied."
  end

  def notify_requester(request, notification)
    return if request.user.email.blank?

    UrlAccessRequestMailer.with(access_request: request).public_send(notification).deliver_later
  end
end
