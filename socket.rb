require "eventmachine"
require "em-websocket"
require "colorize"
require "jsonify"
require "em-jack"

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
  jack = EMJack::Connection.new(tube: "linjekoll.socket-server")
  channel = EM::Channel.new
  
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
        unless ingoing.is_a?(Array)
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
        unless notification = ingoing["data"]
          ws.trigger("error", {
            message: "Received that was empty.",
            ingoing: ingoing
          })
          
          debug("Empty data: #{ingoing.inspect}"); next
        end
        
        # Let's print the given data
        debug("Data push from client: #{notification.inspect}")
        
        listen = notification.uniq - list
                
        # Nothing to listen for?
        next if listen.empty?
        
        list.push(*listen)
                
        sid = channel.subscribe do |data|
          listen.each do |message|
            # Do we have any data to push to user?            
            if ["provider_id", "line_id"].all?{|w| message[w].to_s == data[w].to_s}              
              ws.trigger("update.trip", data)              
              debug("Pushing :" + data.inspect)
            else
              debug "'%s' did not match '%s', or '%s' did not match '%s', I'm not sure." % [
                message["provider_id"],
                data["provider_id"],
                message["line_id"],
                data["line_id"]
              ]
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
      channel.push(JSON.parse(job.body))
    rescue JSON::ParserError
      debug $!.message
    ensure
      jack.delete(job)
    end
  end
  
  debug "Server started on port #{port}."
end