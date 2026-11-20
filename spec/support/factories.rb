# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  ## User Factory
  factory :user do
    username { Faker::Internet.unique.username(specifier: 5..8) }
    email { Faker::Internet.unique.email }
    password { 'correct-horse-battery' }
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

  ## API token factory. Pass `secret:` to know the plaintext in a spec.
  factory :api_token do
    association :user
    sequence(:name) { |n| "Token #{n}" }
    access_level { :read_write }
    lifetime_days { 90 }

    transient do
      secret { ApiToken.generate_secret }
    end

    token_digest { ApiToken.digest(secret) }
    token_prefix { secret.first(ApiToken::VISIBLE_PREFIX_LENGTH) }
    expires_at { lifetime_days&.days&.from_now }

    trait :read_only do
      access_level { :read_only }
    end

    trait :revoked do
      revoked_at { 1.hour.ago }
    end

    trait :expired do
      expires_at { 1.minute.ago }
    end
  end
end
