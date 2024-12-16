# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include BasicAuth
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protect_from_forgery

  private

  def login_or_authenticate_user
    return if Rails.env.test?

    cas_data_file = "#{ENV['CAS_DATA_DIRECTORY']}/#{cookies[:MOD_AUTH_CAS]}"
    user_data = {}

    begin
      cas_data_file_content = File.read(cas_data_file)
      cas_data_file_parsed = Nokogiri::XML('<?xml version="1.0" encoding="utf-8"?>' + cas_data_file_content)
      cas_data_file_parsed.root.add_namespace_definition('def', 'http://uconn.edu/cas/mod_auth_cas')

      cas_data_file_parsed.search('//def:attribute').each do |attribute|
        if attribute.attributes['name'].value == 'mail'
          attribute_value_node = attribute.children.find { |child| child.name == 'value' }
          user_data['email'] = attribute_value_node.text
        end

        if attribute.attributes['name'].value == 'displayName'
          attribute_value_node = attribute.children.find { |child| child.name == 'value' }
          user_data['name'] = attribute_value_node.text
        end
      end

      raise("Email or name missing for #{cas_data_file}") if (user_data['email'].present? == false) || (user_data['name'].present? == false)

      user = User.find_by(email: user_data['email'])
      unless user
        user = User.new(
          username: user_data['email'].sub('@', '.'),
          email: user_data['email']
        )
        user.save!(validate: false)
      end
    rescue => e
      logger.error(e)
      raise ActiveRecord::RecordNotFound, 'Something went wrong'
    end

    sign_in(user)

    authenticate_user!
    Rack::MiniProfiler.authorize_request if !Rails.env.production? && current_user&.superadmin
  end
end
