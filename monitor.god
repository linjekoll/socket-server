root = File.expand_path("..", __FILE__)

God.watch do |w|
  w.name     = "socket"
  w.group    = "linjekoll"
  w.interval = 30.seconds
  w.start    = "bundle exec ruby #{root}/socket.rb"
  
  w.env = {
    "BUNDLE_GEMFILE" => "#{root}/Gemfile"
  }
  
  # Monitoring:
  w.start_if do |start|
    start.condition(:process_running) { |c| c.running = false }
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 200.megabytes
      c.times = [3, 5]
    end

    restart.condition(:cpu_usage) do |c|
      c.above = 95.percent
      c.times = 5
    end
  end

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end