require "redis"

class Cache
  def initialize
    # We're using the default port, nothing fancy in other words
    @redis = Redis.new(host: "127.0.0.1", port: 6380)
  end
  
  # Saves data to cache
  # @data Hash Contains the following keys.
  # "provider_id" Integer A provider id.
  # "line_id" Integer A line id.
  # All keys should be strings, not symbols
  def save!(data)
    @redis.set("line.provider.#{data["provider"]}.#{data["line"]}", data.to_json)
  end
  
  # Reads data from cache
  # @data Hash Contains the following keys.
  # "provider_id" Integer A provider id.
  # "line_id" Integer A line id.
  # @return Hash An hash on the following form
  # {
  #   alert_message: ""
  #   arrival_time: "1319031890"
  #   event: "did_leave_station"
  #   journey_id: "30"
  #   line_id: "4"
  #   next_station: "898345"
  #   previous_station: "8998235"
  #   provider_id: "1"
  #   station_id: "00012130"
  # } 
  # It might return an nil if cache is empty
  # All keys should be strings, not symbols
  def read(data)
    data = @redis.get("line.provider.#{data["provider_id"]}.#{data["line_id"]}")
    if data
      return data.from_json
    end
  end
end