# frozen_string_literal: true

# Demo data to play with, see "Demo data" in README.md.
# rubocop:disable Metrics/BlockLength
namespace :demo do
  # A refusal (e.g. in production) is a short message, not a backtrace.
  with_demo_data = lambda do |&action|
    action.call(Brkmn::DemoData.from_env)
  rescue Brkmn::DemoData::NotAllowed => e
    abort e.message
  end

  desc "Load the demo data. Running it again puts the demo data back to its starting state"
  task load: :environment do
    with_demo_data.call { |demo| puts demo.load!.report }
  end

  desc "Remove the demo data and load it again"
  task reset: :environment do
    with_demo_data.call { |demo| puts demo.reset!.report }
  end

  desc "Remove the demo data (demo users and their links), everything else stays"
  task remove: :environment do
    with_demo_data.call do |demo|
      demo.remove!
      puts "Demo data removed."
    end
  end

  desc "Show the demo accounts and things to try"
  task info: :environment do
    with_demo_data.call { |demo| puts demo.report }
  end

  desc "Load the demo data when SEED_DEMO_DATA=true (used by the development Docker setup)"
  task auto: :environment do
    Rake::Task["demo:load"].invoke if ENV["SEED_DEMO_DATA"] == "true"
  end
end
# rubocop:enable Metrics/BlockLength
