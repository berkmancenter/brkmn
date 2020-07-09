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
    protected_regex?
    invalid_characters?
  end

  def already_in_use?
    return unless conflicting_urls.present?

    @record.errors.add @attribute, "(#{@value}) is already in use. Please choose another."
  end

  def protected_regex?
    return unless @value.match(PROTECTED_URL_REGEX)

    @record.errors.add @attribute, 'is a protected URL and cannot be used. Please choose another.'
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
