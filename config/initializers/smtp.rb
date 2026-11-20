# frozen_string_literal: true

unless defined?(SMTP_SETTINGS)
  smtp_username = ENV['SMTP_USERNAME'].presence

  SMTP_SETTINGS = {
    address: ENV['SMTP_ADDRESS'], # example: 'smtp.sendgrid.net'
    enable_starttls_auto: true,
    domain: ENV['SMTP_DOMAIN'], # example: 'this-app.com'
    port: ENV['SMTP_PORT'],
    user_name: smtp_username,
    password: ENV['SMTP_PASSWORD'].presence,
    authentication: ((ENV['SMTP_AUTHENTICATION'].presence || 'plain').to_sym if smtp_username),
    # Check the server certificate, so nobody in the middle can read the mails
    # (they contain password reset links). Set to 'none' only for a trusted
    # internal relay with a self-signed certificate.
    openssl_verify_mode: ENV['SMTP_OPENSSL_VERIFY_MODE'].presence || 'peer'
  }.compact
end

Rails.application.config.action_mailer.smtp_settings = SMTP_SETTINGS
