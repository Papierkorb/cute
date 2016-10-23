require "../src/cute"

# Demonstrates the signal spy mechanism for testing purposes.

require "spec"
require "../src/spec"

class Button
  Cute.signal clicked(x : Int32, y : Int32)

  def click
    clicked.emit(4, 5)
  end
end

describe Button do
  describe "#click" do
    it "emits #clicked" do
      btn = Button.new

      # Build the spy. Just copy the signal definition over.
      clicked_spy = Cute.spy btn, clicked(x : Int32, y : Int32)
      btn.click # Somehow trigger a signal emission

      # The signal spy inherits from an array, so verification is easy
      clicked_spy.size.should eq 1
      clicked_spy.first.should eq({ 4, 5 })
    end
  end
end
