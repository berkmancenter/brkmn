# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  ## User Factory
  factory :user do
    username { Faker::Internet.unique.username(specifier: 5..8) }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    superadmin { false }

    # Ensure Devise's requirement for password confirmation
    password_confirmation { password }

    trait :superadmin do
      superadmin { true }
    end
  end

  ## URL Factory
  factory :url do
    to { 'https://example.com' }

    shortened do
      # Generates a random 6-character string for the shortcode
      loop do
        shortcode = Faker::Alphanumeric.alphanumeric(number: 6).upcase
        break shortcode unless Url.exists?(shortened: shortcode)
      end
    end

    auto { true }
    clicks { 0 }
    association :user

    trait :with_clicks do
      clicks { rand(1..100) }
    end

    trait :custom_shortened do
      sequence(:shortened) { |n| "SHORT#{n}" }
    end

    trait :without_user do
      user { nil }
    end
  end
end
