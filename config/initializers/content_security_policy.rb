# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri :self
    policy.connect_src :self
    policy.font_src :self, :data
    policy.frame_ancestors :self
    policy.img_src :self, :data
    policy.object_src :none
    # Scripts only from our host, inline ones (importmap, capybara-lockstep)
    # need the nonce.
    policy.script_src :self
    # Inline styles stay allowed: Turbo's progress bar and a few style
    # attributes use them.
    policy.style_src :self, :unsafe_inline
  end

  # Nonce per session, so Turbo doesn't see changed <script> tags on every visit.
  # Never the session id itself: with the database session store the id is the
  # cookie value, and the nonce is readable in the page.
  config.content_security_policy_nonce_generator = lambda do |request|
    session_id = request.session.id.to_s
    if session_id.present?
      key = Rails.application.key_generator.generate_key("content security policy nonce")
      OpenSSL::HMAC.hexdigest("SHA256", key, session_id)
    else
      SecureRandom.base64(16)
    end
  end
  config.content_security_policy_nonce_directives = %w[script-src]

  # rack-mini-profiler and web-console add their own scripts in development,
  # only report violations there.
  config.content_security_policy_report_only = Rails.env.development?
end
