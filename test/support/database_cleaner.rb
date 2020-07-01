DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

module DatabaseCleanerSupport
  def before_setup
    super
    DatabaseCleaner.start
  end

  def after_teardown
    DatabaseCleaner.clean
    super
  end
end
