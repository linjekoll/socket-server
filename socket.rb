require "eventmachine"
require "em-websocket"
require "colorize"
require "jsonify"
require "em-jack"

#
# @message String Message to be printed to console
#
def debug(message)
  puts "%s %s" % ["==>".black, message.to_s.green]
end

port = ARGV[0] || 3333

EM.run do
  jack = EMJack::Connection.new
  channel = EM::Channel.new
  
  EventMachine::WebSocket.start(host: "0.0.0.0", port: port) do |ws|
    ws.onopen do
      debug "WebSocket connection open."
      sid = nil
      
      ws.onmessage do |msg|
        # User subscribes to the 'new data' channel
        # When new data is beign fetch and processed, 
        # this is the channel that'll be notified
        # @data Hash Data push from a provider
        # msg = {provider_id: n, line_id: n}
        msg = JSON.parse(msg)
        debug(msg)
        sid = channel.subscribe do |data|
          msg.each do |message|
            # Do we have any data to push to user?            
            if ["provider_id", "line_id"].all?{|w| message[w].to_s == data[w].to_s}
              ws.send(data.to_json.force_encoding("BINARY"))
              debug("Pushing :" + data.to_json)
            else
              debug "'%s' did not match '%s', or '%s' did not match '%s'." % [
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
  
  jack.use("linjekoll.socket-server").callback do
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
  end
  
  debug "Server started on port #{port}."
end