require "../src/cute"

# Demonstrates how the middleware feature could be used for testing,
# by adding faults into the pipeline.

class Chat
  @io : IO = STDOUT

  Cute.middleware def send_message(body : String) : Int32
    @io.puts "Sending #{body}"
    body.size
  end
end

chat = Chat.new

# Add the failure injecting middleware
chat.send_message.add do |body, yielder|
  if rand > 0.5 # Make every other call fail
    yielder.call(body)
  else
    raise "Failed to send message"
  end
end

# Send a message
10.times do
  begin
    chat.send_message.call("Hello")
  rescue err
    puts "Error: #{err}"
  end
end
