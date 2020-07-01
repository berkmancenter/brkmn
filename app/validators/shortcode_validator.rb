class ShortcodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # We will auto-create if it's blank.
    # This needs to be a Validator subclass and not an inline function because
    # the return is only permissible here.
    return if value.blank?

    if Url.where(shortened_conditions(record)).present?
      record.errors.add attribute, "(#{value}) is already in use. Please choose another."
    end

    if value.match(PROTECTED_URL_REGEX)
      record.errors.add attribute, 'is a protected URL and cannot be used. Please choose another.'
    end

    unless URI.encode(value) == value
      record.errors.add attribute, 'contains invalid URL characters.'
    end
  end

  def shortened_conditions(record)
    if record.persisted?
      { shortened: record.shortened, to: record.to, user_id: record.user_id }
    else
      { shortened: record.shortened }
    end
  end
end
