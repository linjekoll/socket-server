require "rspec"
require "capybara"
require "capybara/dsl"
require "capybara/rspec"
require_relative "./../server"

Capybara.app               = Sinatra::Application
Capybara.javascript_driver = :selenium
Capybara.default_wait_time = 10

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Capybara::DSL
end