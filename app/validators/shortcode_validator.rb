# frozen_string_literal: true

class ShortcodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # We will auto-create if it's blank.
    # This needs to be a Validator subclass and not an inline function because
    # the return is only permissible here.
    return if value.blank? && !record.persisted?

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
    recognized_route = Rails.application.routes.recognize_path(@value) rescue nil
    return if recognized_route.nil? || recognized_route[:controller] == 'redirector'

    @record.errors.add @attribute, "(#{@value}) conflicts with a valid site URL. Please choose another."
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
