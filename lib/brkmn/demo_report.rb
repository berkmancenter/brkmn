# frozen_string_literal: true

module Brkmn
  # What is in the demo data and how to try it, printed by the demo:* tasks.
  class DemoReport
    def initialize(demo_data)
      @demo = demo_data
    end

    def to_s
      return "No demo data loaded. Run: bin/rails demo:load" unless @demo.demo_users.exists?

      [summary, skipped, login, accounts, things_to_try].compact.join("\n\n")
    end

    private

    def summary
      urls = @demo.demo_urls
      requests = UrlAccessRequest.where(url_id: urls.select(:id))
      "Demo data: #{@demo.demo_users.count} people, #{urls.count} links " \
        "(#{number(urls.sum(:clicks))} clicks), " \
        "#{UrlCollaborator.where(url_id: urls.select(:id)).count} shared with an editor, " \
        "#{requests.count} access requests (#{requests.pending.count} waiting for an answer)"
    end

    def skipped
      return if @demo.skipped_codes.empty?

      "Not loaded, these codes are used by other links: #{@demo.skipped_codes.join(", ")}"
    end

    def login
      case Rails.application.config.devise_auth_type
      when "db"
        "Log in at /users/sign_in, every demo account has the password: #{@demo.password}"
      when "headers"
        "Header auth: send X-Auth-Email with a demo email (and any X-Auth-Name) from a trusted proxy."
      else
        "#{Rails.application.config.devise_auth_type.upcase} log in: demo users are matched by their email."
      end
    end

    def accounts
      users = @demo.users_data
      email_width = users.map { |user| DemoData.email_for(user[:key]).length }.max
      name_width = users.map { |user| user[:name].length }.max

      users.map do |user|
        "  #{DemoData.email_for(user[:key]).ljust(email_width)}  #{user[:name].ljust(name_width)}  #{user[:about]}"
      end.join("\n")
    end

    def things_to_try
      tips = [
        "Open /newsletter, the most clicked link: it redirects and counts the click",
        "Maya: answer the access requests from Sam (lab-handbook) and Jonas (survey) in the share dialog",
        "Jonas: edit spring-symposium, Maya gave him edit access",
        "Lea: ask for edit access to board-minutes, it was denied 2 hours ago so she has to wait a day",
        "Search for \"otter\", sort by clicks, page through All URLs"
      ]
      if db_auth?
        tips << "Tom: locked, the log in only says \"Invalid email or password\" (paranoid mode hides why), " \
                "\"Didn't receive unlock instructions?\" sends the unlock email"
        tips << "Nora: not confirmed yet, \"Didn't receive confirmation instructions?\" sends it again"
      end
      "Things to try:\n#{tips.map { |tip| "  - #{tip}" }.join("\n")}"
    end

    def db_auth?
      Rails.application.config.devise_auth_type == "db"
    end

    def number(value)
      ActiveSupport::NumberHelper.number_to_delimited(value)
    end
  end
end
