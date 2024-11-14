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
end
