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

#
# @data String Pushes @data to client
# Example data being pushed.
# {
#   event: "event",
#   next_station: 8998235,
#   previous_station: 898345,
#   arrival_time: 1318843870,
#   alert_message: "oops!",
#   line_id: 2342
#   provider_id: 123123,
#   journey_id: 123123
# }
# Take a look at the readme in the API server js project
# https://github.com/linjekoll/api-server-js/blob/master/README.md
#

beanstalk = Beanstalk::Pool.new(['localhost:11300'])
beanstalk.use("linjekoll.socket-server")

def push(data)
  beanstalk.put(data)
end