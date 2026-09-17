# frozen_string_literal: true

module ApplicationHelper
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title,
            params.permit.merge(sort: column, direction: direction, page: nil),
            class: css_class
  end

  def viewing_mode
    cookies[:viewing_mode] || 'modern'
  end

  def user_display_name(user, fallback: "Unknown user")
    user&.username.presence || user&.email.presence || fallback
  end

  def user_email_address(user, fallback: "Email unavailable")
    user&.email.presence || fallback
  end

  def user_email_initial(user)
    user_email_address(user, fallback: "?").first.upcase
  end

  def ordered_url_collaborators(url)
    url.url_collaborators.sort_by { |collaboration| collaboration.user.email.to_s.downcase }
  end

  def current_url_access_request(url)
    url.url_access_requests.find { |request| request.user_id == current_user.id }
  end

  def modal_error_for(url)
    modal_error = flash[:modal_error]
    return unless modal_error.is_a?(Hash) && modal_error["url_id"].to_i == url.id

    modal_error["message"]
  end

  def visible_flash_messages
    flash.reject { |name, _message| name.to_sym == :modal_error }
  end
end
