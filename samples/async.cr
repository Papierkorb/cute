require "../src/cute"

# Demonstrates a non-blocking signal

class Button
  # Setting `async` to true (Defaults to false) will spawn the handler
  # invocation in a new fiber.
  Cute.signal clicked(x : Int32, y : Int32), async: true
end

btn = Button.new

btn.clicked.on do |x, y|
  puts "Hello from #{Fiber.current}, passed arguments: #{x}, #{y}"
end

puts "Triggering from #{Fiber.current}"
btn.clicked.trigger 5, 4
Fiber.yield
puts "And back"
