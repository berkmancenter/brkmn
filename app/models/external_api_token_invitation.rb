# frozen_string_literal: true

# Creates an API-only user for an email address that has no account yet, plus
# a token they collect through a single-use claim link.
class ExternalApiTokenInvitation
  include ActiveModel::Model
  include ActiveModel::Attributes

  DEFAULT_LIFETIME_DAYS = 90

  attribute :email, :string
  attribute :name, :string
  attribute :note, :string
  attribute :access_level, :string, default: "read_only"
  attribute :lifetime_days, :integer, default: DEFAULT_LIFETIME_DAYS

  attr_reader :api_token, :claim_token

  validates :email, presence: true, length: {maximum: 100}
  validates :email, format: {with: Devise.email_regexp}, allow_blank: true
  validates :name, presence: true
  validates :lifetime_days,
    inclusion: {
      in: ApiToken::LIFETIME_CHOICES,
      message: "must be one of the listed options"
    }
  validate :email_not_taken

  def email=(value)
    super(value.to_s.strip.downcase.presence)
  end

  def save(created_by:)
    return false if invalid?

    ApiToken.transaction do
      user = build_user
      user.save!
      @api_token = user.api_tokens.new(
        name: name,
        note: note.presence,
        access_level: access_level,
        lifetime_days: lifetime_days,
        created_by: created_by
      )
      @claim_token = @api_token.issue_claim || raise(ActiveRecord::RecordInvalid, @api_token)
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    copy_errors_from(e.record)
    @api_token = @claim_token = nil
    false
  end

  private

  def build_user
    User.new(email: email, username: email, api_only: true).tap do |user|
      user.set_random_password
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end
  end

  def email_not_taken
    return if email.blank?

    existing = User.where("LOWER(email) = :email OR LOWER(username) = :email", email: email).first
    return if existing.nil?

    errors.add(:email, existing_account_message(existing))
  end

  def existing_account_message(user)
    if user.api_only?
      "already has external API access. Use “Send new link” on their token instead."
    else
      "already belongs to an account. Its owner can create their own token under Settings → API tokens."
    end
  end

  def copy_errors_from(record)
    record.errors.each do |error|
      if error.attribute != :base && respond_to?(error.attribute)
        errors.add(error.attribute, error.message)
      else
        errors.add(:base, error.full_message)
      end
    end
  end
end
