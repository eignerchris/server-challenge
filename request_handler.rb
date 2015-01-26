class RequestHandler
  attr_reader :verb, :resource, :response_code

  ROOT_DIRECTORY = "public"

  def initialize(tcp_socket)
    @socket = tcp_socket
    @request_line = @socket.gets
    @verb, @resource, stuff = @request_line.split " "
    # puts "Incoming #{@verb} request for #{@resource} at #{Time.now}"
  end

  def process_request
    file_path = ROOT_DIRECTORY + @resource
    unless File.exists?(file_path)
      @response_code = 404      
      render_a_404
      return 
    end
    
    @response_code = 200
    write_file_contents(file_path)
  rescue => e
    # todo - render 5xx
    @response_code = 500
    puts e.inspect, e.backtrace
    write_file_contents(file_path)
  end

  def render_a_404
    write_file_contents(ROOT_DIRECTORY + "/404.html")
  end

  def write_file_contents(file_path)
    File.open(file_path, "rb") do |file|  
      @socket.print "HTTP/1.1  #{@response_code} OK\r\n" +
        "Content-Type: #{content_type(file_path)}\r\n" +
        "Content-Length: #{file.size}\r\n" +
        "Connection: close\r\n"

      @socket.print "\r\n"

      IO.copy_stream(file, @socket)    
    end
  end

  def content_type(file)
    extension = file.split(".")[-1]
    case extension
      when 'htm', 'html', 'txt', 'css', 'js' then "text/#{extension}"

      when 'gif', 'png' then "image/#{extension}"
      when 'jpg' then 'image/jpeg'
      else 'text/plain'
    end
  end
end