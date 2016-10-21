require "../src/cute"

# Demonstrates how `cute` can turn a signal into a channel

class Button
  Cute.signal clicked(x : Int32, y : Int32)
end

btn = Button.new
channel, _handle = btn.clicked.new_channel

spawn do
  x, y = channel.receive
  puts "Received: #{x}, #{y}"
end

btn.clicked.emit 5, 4
Fiber.yield
