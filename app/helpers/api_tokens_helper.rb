# frozen_string_literal: true

module ApiTokensHelper
  STATUS_LABELS = {
    active: "Active",
    pending: "Awaiting collection",
    expired: "Expired",
    revoked: "Revoked"
  }.freeze

  STATUS_FILTER_OPTIONS = [
    ["Any status", ""],
    ["Active", "active"],
    ["Awaiting collection", "pending"],
    ["Expired", "expired"],
    ["Revoked", "revoked"]
  ].freeze
  KIND_FILTER_OPTIONS = [["Any user", ""], ["Internal", "internal"], ["External (API-only)", "external"]].freeze

  # A one-button form that asks for confirmation before submitting.
  def api_token_button(label, path, method:, confirm:, danger: false)
    css = danger ? "api-tokens__button api-tokens__button--danger" : "api-tokens__button"
    button_to label, path, method: method, class: css, form: {data: {turbo_confirm: confirm}}
  end

  def api_token_access_label(api_token)
    api_token.read_write? ? "Read & write" : "Read-only"
  end

  def api_token_access_options
    [["Read-only", "read_only"], ["Read & write", "read_write"]]
  end

  def api_token_lifetime_options(allow_never: true)
    options = ApiToken::LIFETIME_CHOICES.map { |days| [api_token_lifetime_label(days), days] }
    allow_never ? options + [["No expiration", ""]] : options
  end

  def api_token_lifetime_label(days)
    days.nil? ? "No expiration" : pluralize(days, "day")
  end

  def api_token_status(api_token)
    status = api_token.status
    label = STATUS_LABELS.fetch(status)
    label = "Link expired" if status == :pending && api_token.claim_expired?
    tag.span(label, class: "api-token-status api-token-status--#{status}")
  end

  def api_token_status_details(api_token)
    if api_token.revoked?
      revoker = user_display_name(api_token.revoked_by, fallback: "a deleted user")
      "by #{revoker} on #{api_token_time(api_token.revoked_at)}"
    elsif api_token.pending? && api_token.claim_expires_at
      verb = api_token.claim_expired? ? "expired" : "expires"
      "link #{verb} #{api_token_time(api_token.claim_expires_at)}"
    end
  end

  def api_token_display_prefix(api_token)
    api_token.token_prefix.present? ? "#{api_token.token_prefix}…" : "—"
  end

  def api_token_time(time, blank: "—")
    time.present? ? time.strftime("%Y-%m-%d %H:%M") : blank
  end

  def api_token_expiry(api_token)
    return api_token_time(api_token.expires_at) if api_token.expires_at.present?
    return "#{api_token_lifetime_label(api_token.lifetime_days)} after collection" if api_token.pending?

    "Never"
  end
end
