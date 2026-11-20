# frozen_string_literal: true

module Brkmn
  # Demo data to play with: people with different roles, links with clicks and
  # history, shared links and access requests in every state. The data itself
  # is in db/seeds/demo_data.yml, see "Demo data" in README.md.
  #
  # Every run gives the same data (fixed random seed, times relative to now).
  # Demo users have a @demo.brkmn.test email, that's how demo data is told
  # apart from real data: loading again puts the demo data back to its starting
  # state, removing it leaves everything else alone.
  class DemoData
    DOMAIN = "demo.brkmn.test"
    DATA_FILE = Rails.root.join("db/seeds/demo_data.yml")
    DEFAULT_PASSWORD = "brkmn-demo-password"
    DEFAULT_GENERATED_LINKS = 120
    DEFAULT_RANDOM_SEED = 2012
    TIME_AGO = /\A(\d+) (minute|hour|day)s?\z/

    class NotAllowed < StandardError; end

    def self.from_env
      new(
        generated_links: Integer(ENV.fetch("DEMO_GENERATED_LINKS", DEFAULT_GENERATED_LINKS)),
        password: ENV["DEMO_PASSWORD"].presence || DEFAULT_PASSWORD,
        random_seed: Integer(ENV.fetch("DEMO_RANDOM_SEED", DEFAULT_RANDOM_SEED))
      )
    end

    # Demo accounts have a known password, so only in development and test
    # unless asked for (e.g. a demo server).
    def self.allowed?
      Rails.env.local? || ENV["ALLOW_DEMO_DATA"] == "true"
    end

    def self.email_for(key)
      "#{key}@#{DOMAIN}"
    end

    attr_reader :password, :skipped_codes

    def initialize(
      generated_links: DEFAULT_GENERATED_LINKS,
      password: DEFAULT_PASSWORD,
      random_seed: DEFAULT_RANDOM_SEED
    )
      @generated_links = generated_links
      @password = password
      @random_seed = random_seed
      @data = YAML.load_file(DATA_FILE, symbolize_names: true)
      @skipped_codes = []
    end

    def load!
      ensure_allowed!
      @random = Random.new(@random_seed)
      @used_codes = Set.new

      ActiveRecord::Base.transaction do
        load_users
        load_links
        load_generated_links
        remove_extra_links
        reset_sharing
        load_shares
        load_access_requests
      end
      self
    end

    def remove!
      ensure_allowed!
      ActiveRecord::Base.transaction do
        demo_urls.destroy_all
        demo_users.destroy_all
      end
      self
    end

    def reset!
      remove!
      load!
    end

    def report
      DemoReport.new(self).to_s
    end

    def users_data
      @data[:users]
    end

    def demo_users
      User.where("email LIKE ?", "%@#{DOMAIN}")
    end

    # Links of demo users, and the ownerless old links from the data file.
    def demo_urls
      Url.where(user_id: demo_users.select(:id)).or(Url.where(user_id: nil, shortened: legacy_codes))
    end

    private

    def ensure_allowed!
      return if self.class.allowed?

      raise NotAllowed,
        "The demo data has accounts with a known password, so it only loads in development and test. " \
        "Set ALLOW_DEMO_DATA=true to load it anyway (for example on a demo server)."
    end

    def load_users
      @users = DemoUsers.new(users_data, password: password).load
      @demo_user_ids = @users.values.map(&:id)
    end

    def load_links
      @links = {}
      @data[:links].each do |link|
        code = link[:code] || generated_code
        @used_codes << code
        url = Url.find_or_initialize_by(shortened: code)
        next skip(code) unless demo_url?(url)

        save_link(url, link)
        @links[code] = url
      end
    end

    def save_link(url, link)
      url.assign_attributes(
        to: link[:to],
        user: @users[link[:owner]&.to_sym],
        clicks: link[:clicks],
        created_at: ago(link[:created]),
        last_edited_by: @users[link[:edited_by]&.to_sym],
        last_edited_at: link[:edited] && ago(link[:edited])
      )
      url.save!
      # Saving a code marks the link as not generated, set it like the app would.
      url.update_columns(auto: link[:code].nil?, updated_at: ago(link[:edited] || link[:created]))
    end

    # One insert without validations: the generated values are valid, and it's
    # much faster for hundreds of links.
    def load_generated_links
      rows = Array.new(@generated_links) { |index| generated_link(index + 1) }
      taken = Url.where(shortened: rows.pluck(:shortened))
        .where("user_id IS NULL OR user_id NOT IN (?)", @demo_user_ids)
        .pluck(:shortened)
      taken.each { |code| skip(code) }
      rows.reject! { |row| taken.include?(row[:shortened]) }
      Url.upsert_all(rows, unique_by: :shortened, record_timestamps: false) if rows.any?
    end

    def generated_link(number)
      words = @data[:generated]
      animal = pick(words[:animals])
      auto = @random.rand < 0.25
      code = auto ? generated_code : "#{pick(words[:adjectives])}-#{animal}-#{number}"
      @used_codes << code
      created_at = Time.current - @random.rand(1..1095).days - @random.rand(86_400).seconds

      {
        shortened: code,
        to: "https://#{pick(words[:hosts])}/#{pick(words[:topics])}/#{animal}-#{number}",
        user_id: @users.fetch(pick(words[:owners]).to_sym).id,
        auto: auto,
        # Most links get a few clicks, some get thousands.
        clicks: ((@random.rand**4) * 9_000).round,
        created_at: created_at,
        updated_at: created_at
      }
    end

    # Links a demo user made while playing, and generated links from a run
    # with a bigger DEMO_GENERATED_LINKS.
    def remove_extra_links
      Url.where(user_id: @demo_user_ids).where.not(shortened: @used_codes.to_a).destroy_all
    end

    # Only sharing between demo users on demo links, a real user's request
    # for a demo link stays.
    def reset_sharing
      UrlCollaborator.where(url_id: demo_urls.select(:id), user_id: @demo_user_ids).delete_all
      UrlAccessRequest.where(url_id: demo_urls.select(:id), user_id: @demo_user_ids).delete_all
    end

    def load_shares
      @data[:shares].each do |share|
        url = @links[share[:code]] or next
        created_at = ago(share[:created])
        url.url_collaborators.create!(
          user: @users.fetch(share[:user].to_sym),
          granted_by: @users.fetch(share[:by].to_sym),
          created_at: created_at,
          updated_at: created_at
        )
      end
    end

    def load_access_requests
      @data[:access_requests].each do |request|
        url = @links[request[:code]] or next
        url.url_collaborators.reset
        url.url_access_requests.create!(
          user: @users.fetch(request[:user].to_sym),
          status: request[:status],
          resolved_by: request[:by] && @users.fetch(request[:by].to_sym),
          resolved_at: request[:resolved] && ago(request[:resolved]),
          created_at: ago(request[:created]),
          updated_at: ago(request[:resolved] || request[:created])
        )
      end
    end

    def demo_url?(url)
      url.new_record? || @demo_user_ids.include?(url.user_id) ||
        (url.user_id.nil? && legacy_codes.include?(url.shortened))
    end

    def legacy_codes
      @data[:links].select { |link| link[:owner].nil? && link[:code] }.pluck(:code)
    end

    # Six capital letters, like Url#random_shortcode, but from the seeded random.
    def generated_code
      loop do
        code = Array.new(6) { ("A".."Z").to_a.sample(random: @random) }.join
        return code unless @used_codes.include?(code)
      end
    end

    def pick(values)
      values.sample(random: @random)
    end

    def skip(code)
      @skipped_codes << code
    end

    def ago(text)
      amount, unit = TIME_AGO.match(text.to_s)&.captures
      raise ArgumentError, "Unknown time #{text.inspect} in #{DATA_FILE}, use e.g. \"3 days\"" unless amount

      amount.to_i.public_send(unit).ago
    end
  end
end
