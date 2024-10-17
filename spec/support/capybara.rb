require 'capybara/rspec'

# https://docs.travis-ci.com/user/common-build-problems/#capybara-im-getting-errors-about-elements-not-being-found
Capybara.default_max_wait_time = 15

default_chrome_options = %w(
  --disable-extensions
  --disable-gpu
  --disable-infobars
  --disable-notifications
  --disable-password-generation
  --disable-password-manager-reauthentication
  --disable-popup-blocking
  --disable-save-password-bubble
  --disable-dev-shm-usage
  --headless=new
  --ignore-certificate-errors
  --incognito
  --mute-audio
  --remote-debugging-port=9222
  --no-sandbox
)

chrome_options = Selenium::WebDriver::Chrome::Options.new
default_chrome_options.each { |o| chrome_options.add_argument(o) }
client = Selenium::WebDriver::Remote::Http::Default.new(open_timeout: nil, read_timeout: 120)

Capybara.register_driver :headless do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    clear_local_storage: true,
    clear_session_storage: true,
    options: chrome_options,
    http_client: client
  )
end

Capybara.javascript_driver = :headless
Capybara.server = :puma

Capybara.configure do |config|
  config.server_port = 9887
end
