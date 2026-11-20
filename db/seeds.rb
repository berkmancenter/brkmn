# frozen_string_literal: true

# rubocop:disable Rails/Output -- seeds report to the terminal

# Seeds are the demo data, see "Demo data" in README.md and
# db/seeds/demo_data.yml.
#
# Only for development: db:prepare runs this file whenever it creates a
# database, and test and production databases must stay empty. The demo
# accounts have a known password.
if Rails.env.development? || ENV["ALLOW_DEMO_DATA"] == "true"
  puts Brkmn::DemoData.from_env.load!.report
else
  puts "No seeds for the #{Rails.env} environment, the demo data is only for development."
end
# rubocop:enable Rails/Output
