require "../src/cute"

# Demonstrates the middleware feature.

class Chat
  @io : IO = STDOUT

  Cute.middleware def send_message(body : String) : Int32
    @io.puts "Sending #{body}"
    body.size
  end
end

chat = Chat.new

# Add a Capt'n Caps middleware :)
chat.send_message.add { |body, yielder| yielder.call(body.upcase) }

# Prepend our user name
chat.send_message.add { |body, yielder| yielder.call("Alice: #{body}")}

# Send a message
chat.send_message.call("Hello") #=> 13
# Prints "Sending Alice: HELLO"
