require "../src/cute"

# Demonstrates the basic usage of the cute shard.

class Button
  Cute.signal clicked(x : Int32, y : Int32)
end

btn = Button.new

# Handlers are called in the order they were connected.
btn.clicked.on { |x, y| puts "First: #{x}, #{y}" }
btn.clicked.on { |x, y| puts "Second: #{x}, #{y}" }
btn.clicked.on { |x, y| puts "Third: #{x}, #{y}" }
btn.clicked.trigger 5, 4
