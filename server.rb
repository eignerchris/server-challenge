require 'socket'
require 'benchmark'
require 'optparse'
require './request_handler'

HTTP_PORT = 3000

# Basic HTTP server.  Handles incoming requests and returns files.
# Server can handle multiple requests at the same time.

# Usage:
# $ ruby server.rb -p 3000
#
# Testing: you can test via watch and curl by running all of these
# simultaneously in separate shells:
#   watch -n0.5 'http://localhost:3000/index.html'
#   watch -n1 'http://localhost:3000/programming.gif'
#   watch -n0.5 'http://localhost:3000/file_not_found'
#

default_options = {:port => HTTP_PORT}
OptionParser.new do |opt|
  opt.on('-p', '--port N', OptionParser::DecimalInteger, 'Port on which to start up server.') do |port|
    puts "Running on port #{port}"
    default_options[:port] = port.to_i
  end
end.parse!

def handle_incoming_requests(server)
  Thread.start(server.accept) do |socket|
    begin
      handler = RequestHandler.new(socket)
      elapsed = Benchmark.realtime do
        handler.process_request
        socket.close
      end
      puts "#{handler.response_code}\t#{handler.verb}\t#{handler.resource}\t#{elapsed}ms"
    rescue => e
      puts e.inspect
      puts e.class, e.message
      puts e.backtrace
    end
  end
end

server = TCPServer.new(default_options[:port])
loop do
  handle_incoming_requests(server)
end
