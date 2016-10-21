require "../src/cute"

# Demonstrates the use of `Cute.connect`, which is the pendant to `QObject::connect()`.

class Button
  Cute.signal clicked(x : Int32, y : Int32)
end

class Window
  getter button : Button

  def initialize
    @button = Button.new

    Cute.connect @button.clicked, on_button_clicked(x, y)
  end

  def on_button_clicked(x, y)
    puts "Clicked at #{x}, #{y}"
  end
end

window = Window.new
window.button.clicked.trigger 3, 4
