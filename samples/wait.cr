require "../src/cute"

# Demonstrates the use of `Cute::Signal#wait`

class Button
  Cute.signal clicked(x : Int32, y : Int32)
end

btn = Button.new
spawn{ btn.clicked.trigger 5, 4 }

puts "Waiting for a click"
x, y = btn.clicked.wait
puts "Done: #{x} #{y}"
