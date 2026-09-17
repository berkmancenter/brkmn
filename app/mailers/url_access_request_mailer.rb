# frozen_string_literal: true

class UrlAccessRequestMailer < ApplicationMailer
  before_action :set_access_request

  def owner_notification
    @review_url = urls_url
    recipients = owner_notification_recipients
    return if recipients.blank?

    mail(
      to: recipients,
      subject: "Edit access requested for #{@url.shortened}"
    )
  end

  def approval_notification
    @edit_url = edit_url_url(@url)

    mail(
      to: @requester.email,
      subject: "Edit access approved for #{@url.shortened}"
    )
  end

  def denial_notification
    mail(
      to: @requester.email,
      subject: "Edit access request denied for #{@url.shortened}"
    )
  end

  private

  def set_access_request
    @access_request = params[:access_request]
    @url = @access_request.url
    @requester = @access_request.user
  end

  def owner_notification_recipients
    return [@url.user.email] if @url.user&.email.present?

    User.where(superadmin: true).where.not(email: [nil, ""]).pluck(:email)
  end
end
