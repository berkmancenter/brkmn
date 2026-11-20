# frozen_string_literal: true

class ShortcodeValidator < ActiveModel::EachValidator
  # Codes a short link could never be reached with: mounted apps are served
  # before the redirector, browsers remove "." and ".." from paths.
  RESERVED_SHORTCODES = %w[sidekiq . ..].freeze

  def validate_each(record, attribute, value)
    # We will auto-create if it's blank.
    # This needs to be a Validator subclass and not an inline function because
    # the return is only permissible here.
    return if value.blank? && !record.persisted?
    # Editing only the destination must keep working for older codes.
    return if record.persisted? && !record.will_save_change_to_attribute?(attribute)

    @record = record
    @attribute = attribute
    @value = value

    already_in_use?
    conflicts_with_valid_route?
    invalid_characters?
  end

  def already_in_use?
    return unless conflicting_urls.present?

    @record.errors.add @attribute, "(#{@value}) is already in use. Please choose another."
  end

  def conflicts_with_valid_route?
    return unless reserved? || public_file? || app_route?

    @record.errors.add @attribute, "(#{@value}) conflicts with a valid site URL. Please choose another."
  end

  def reserved?
    RESERVED_SHORTCODES.include?(@value.to_s.downcase)
  end

  # Files in public/ are served before the redirector, also without the .html
  # extension (/404 serves 404.html).
  def public_file?
    return false if @value.to_s.include?('/')

    [@value, "#{@value}.html", "#{@value}/index.html"].any? { |path| Rails.public_path.join(path.to_s).file? }
  end

  def app_route?
    recognized_route = Rails.application.routes.recognize_path(@value) rescue nil
    recognized_route.present? && recognized_route[:controller] != 'redirector'
  end

  def invalid_characters?
    return if URI.encode_www_form_component(@value) == @value

    @record.errors.add @attribute, 'contains invalid URL characters.'
  end

  def conflicting_urls
    if @record.persisted?
      Url.where(
        shortened: @record.shortened, to: @record.to, user_id: @record.user_id
      ).where.not(id: @record.id)
    else
      Url.where(shortened: @record.shortened)
    end
  end
end
