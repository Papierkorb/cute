# Helpers for writing tests

module Cute
  # Spies upon a signal, storing all emitted values in itself.
  # It inherits from `Array(T)`, so you can use all methods from Array you know.
  #
  # Instead of instantiating this class yourself, see `Cute.spy`.
  class SignalSpy(T) < Array(T)
  end

  # Builds a signal spy listening on *sender* for *signal*. *signal* is the
  # signal definition, like in `Cute.signal`. Types must not be omitted.
  # Whenever a signal occurs, its value(s) are appended to the signal spy.
  #
  # Full usage example:
  # ```
  # require "cute/spec" # Or put it into your "spec_helper" file
  #
  # class Button
  #   Cute.signal clicked(x : Int32, y : Int32)
  #   def click; clicked.emit(4, 5); end
  # end
  #
  # describe Button do
  #   describe "#click" do
  #     it "emits #clicked" do
  #       btn = Button.new
  #       clicked_spy = Cute.spy btn, clicked(x : Int32, y : Int32) # Create the spy
  #       btn.click # Somehow emit the spied upon signal
  #       clicked_spy.size.should eq 1 # Verify
  #       clicked_spy[0].should eq({ 4, 5 })
  #     end
  #   end
  # end
  # ```
  #
  # **Note**: Signals without arguments add `nil` into the spy.
  macro spy(sender, signal)
    {% if signal.args.empty? %}
      ::Cute::SignalSpy(Nil).new.tap do |%spy|
        {{ sender }}.{{ signal.name }}.on{ %spy << nil }
      end
    {% elsif signal.args.size == 1 %}
      ::Cute::SignalSpy({{ signal.args[0].type }}).new.tap do |%spy|
        {{ sender }}.{{ signal.name }}.on{|%val| %spy << %val }
      end
    {% else %}
      ::Cute::SignalSpy(Tuple({{ signal.args.map(&.type).splat }})).new.tap do |%spy|
        {{ sender }}.{{ signal.name }}.on do |{{ signal.args.map(&.var).splat }}|
          %spy << { {{ signal.args.map(&.var).splat }} }
        end
      end
    {% end %}
  end
end
