# frozen_string_literal: true

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

module DatabaseCleanerSupport
  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end
end
