require "eventmachine"
require "em-websocket"
require "colorize"
require "jsonify"
require "em-jack"
require "./lib/cache.rb"

class String
  def from_json
    JSON.parse(self)
  rescue JSON::ParseError
    return nil
  end
end

#
# @message String Message to be printed to console
#
def debug(message)
  puts "%s %s" % ["==>".black, message.to_s.green]
end

port = ARGV[0] || 3333

EM.run do
  jack    = EMJack::Connection.new(tube: "linjekoll.socket-server")
  channel = EM::Channel.new
  cache   = Cache.new
    
  EventMachine::WebSocket.start(host: "0.0.0.0", port: port) do |ws|
    # @event String Event that should be triggered on the client side.
    # @data Object Data that should be pushed to the given client
    # @data could be anything that has implemented #to_json
    def ws.trigger(event, data)
      self.send({
        data: data,
        event: event
      }.to_json.force_encoding("BINARY"))
    end
    
    ws.onopen do
      debug "WebSocket connection open."
      sid = nil
      list = []
      ws.onmessage do |ingoing|
        ingoing = ingoing.from_json
        
        # This must be an array, otherwise we abort.
        unless ingoing.is_a?(Hash)
          ws.trigger("error", {
            message: "Invalid data, should be an array.",
            ingoing: ingoing
          })
          debug("Invalid message from client: #{ingoing}"); next
        end
        
        # If this isn't the correct event, abort!
        unless ingoing["event"] == "subscribe.trip.update"
          ws.trigger("error", {
            message: "Invalid event.",
            ingoing: ingoing
          })
          
          debug("Invalid event: #{ingoing.inspect}"); next
        end
        
        # Client could send invalid data, if so; abort!
        if not notification = ingoing["data"] or not notification.is_a?(Array)
          ws.trigger("error", {
            message: "Received data was invalid.",
            ingoing: ingoing
          })
          
          debug("Invalid: #{ingoing.inspect}"); next
        end
        
        # Let's print the given data
        debug("Data push from client: #{notification.inspect}")
        
        # @listen Should now only contain new lines
        listen = notification.uniq - list
                
        # Nothing to listen for?
        next if listen.empty?
        
        list.push(*listen)
        
        # Do we have any cached data to respond with?
        listen.each do |what|
          cache = cache.read(what)
          if cache
            ws.trigger("update.trip", cache)
          end
        end
                
        sid = channel.subscribe do |data|
          listen.each do |message|
            # Do we have any data to push to user?            
            if ["provider_id", "line_id"].all?{|w| message[w].to_s == data[w].to_s}              
              ws.trigger("update.trip", data)
              debug("Pushing :" + data.inspect)
            end
          end          
        end
      end
            
      ws.onclose do
        channel.unsubscribe(sid)
      end
    end
  end
  
  jack.each_job do |job|
    debug "Ingoing job with id #{job.jobid} and size #{job.body.size}."
    
    begin
      parsed = JSON.parse(job.body)
    rescue JSON::ParserError
      debug $!.message
    ensure
      jack.delete(job)
    end
    
    next if parsed.nil?
    
    # Everything should be saved to cache
    cache.save!(parsed)
    
    # Push data to client
    channel.push(parsed)
  end
  
  debug "Server started on port #{port}."
end