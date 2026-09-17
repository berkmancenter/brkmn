# frozen_string_literal: true

class UrlCollaboratorMailer < ApplicationMailer
  before_action :set_url_and_user

  def grant_notification
    @edit_url = edit_url_url(@url)

    mail(
      to: @user.email,
      subject: "Edit access granted for #{@url.shortened}"
    )
  end

  def removal_notification
    mail(
      to: @user.email,
      subject: "Edit access removed for #{@url.shortened}"
    )
  end

  private

  def set_url_and_user
    @url = params[:url]
    @user = params[:user]
  end
end
