require "./cute/signal"
require "./cute/version"

# Easy to use event-oriented publisher/subscribe modelled after the
# Qt Framework.
module Cute
  # Creates a *signal*. A signal manages listeners (So called *slots*), which
  # will be called when an event has been *emitted*. Emitting is the act of
  # triggering a signal to announce an event to the listeners.
  #
  # Creates the method `name`, which returns a `Signal`.
  # This method does not take any arguments. Instead, the call arguments are
  # type declarations for the signal arguments, and will be passed through
  # `Signal#emit` to listeners as block arguments in the same order.
  #
  # By default, the signal listeners are called in the fiber `#emit` is
  # called from. You can override this by setting the optional argument
  # *async* to `true`. In this case, the signal listeners will be called
  # in turn in a Fiber on their own.
  #
  # Example usage:
  # ```
  # class Button
  #   Cute.signal clicked(x : Int32, y : Int32)
  # end
  #
  # btn = Button.new
  # btn.clicked.on { |x, y| p x, y }
  # btn.clicked.emit 5, 4 #=> Will print 5, 4
  # ```
  #
  # **Note:** You have to fully qualify all argument types to `Cute.signal`.
  #
  # If your signal does not require any arguments, you can omit the `()`:
  # ```
  # class MyIO
  #   Cute.signal data_received() # With empty parantheses
  #   Cute.signal closed # Or without. Both are fine.
  # end
  # ```
  #
  # Signal listeners are called in the order they were connected. You can
  # disconnect them later by using `Signal#disconnect`. Pass it the identifier
  # you got from `#on`:
  # ```
  # btn = Button.new
  # handle = btn.clicked.on { |x, y| p x, y }
  # btn.clicked.disconnect(handle) # Removes the connection again.
  # ```
  #
  # It's also possible to use a `Channel` instead, if you want to wait for
  # an event in a blocking fashion. Use the `#new_channel` method for this:
  # ```
  # btn = Button.new
  # ch, handle = btn.clicked.new_channel # Create channel
  # x, y = ch.retrieve # Wait for event
  # btn.clicked.disconnect(handle) # Remove channel
  # ```
  #
  # The channel will transport the signal argument, or will use a `Tuple` if the
  # signal uses multiple arguments. If the signal has no arguments, the channel
  # will be `Channel(Nil)` instead.
  #
  # **Note:** A channel is just like a handle. Make sure to disconnect it
  # if you don't need it any longer.
  #
  # You can also wait just once for an event using the `#wait` method. This
  # method returns the signal arguments. Example:
  # ```
  # btn = Button.new
  # x, y = btn.clicked.wait # Wait just once
  # ```
  #
  # This is especially useful if you're only interested in the event once or
  # rarely. If you expect events regularly, you're better served using one of
  # the other solutions above.
  #
  # Look in `samples/` for runnable examples.
  #
  # ## Naming convention
  #
  # Signal names should be written in past-tense: The slots are usually called
  # when something already happened. So, a signal name like `clicked` is good,
  # a signal name like `click` not so much. This also helps avoiding name
  # clashes.
  macro signal(call, async = false)
    # :nodoc:
    class Signal_{{ call.name.id }} < ::Cute::Signal
      {% if call.args.empty? %}
        alias Handler = Proc(Nil)
        alias HandlerChannel = Channel(Nil)
      {% else %}
        alias Handler = Proc({{ call.args.map(&.type).argify }}, Nil)
        {% if call.args.size == 1 %}
          alias HandlerChannel = Channel({{ call.args[0].type }})
        {% else %}
          alias HandlerChannel = Channel(Tuple({{ call.args.map(&.type).argify }}))
        {% end %}
      {% end %}

      def initialize
        @listeners = Array(Handler).new
      end

      def on(&block : Handler)
        @listeners << block
        block.hash
      end

      def emit({{ call.args.argify }}) : Nil
        {% if async %}spawn do{% end %}
        @listeners.each do |handler|
          handler.call({{ call.args.map(&.var.id).argify }})
        end
        {% if async %}end{% end %}
      end

      def new_channel : Tuple(HandlerChannel, Int32)
        ch = HandlerChannel.new

        handle = {% if call.args.empty? %}
          on{ ch.send(nil) }
        {% elsif call.args.size == 1 %}
          on{|arg| ch.send(arg)}
        {% else %}
          on{|{{ call.args.map(&.var.id).argify }}| ch.send({ {{ call.args.map(&.var.id).argify }} })}
        {% end %}

        { ch, handle }
      end
    end

    @cute_signal_{{ call.name.id }} : Signal_{{ call.name.id }}?
    def {{ call.name.id }} : Signal_{{ call.name.id }}
      signal = @cute_signal_{{ call.name.id }}

      if signal.nil?
        signal = @cute_signal_{{ call.name.id }} = Signal_{{ call.name.id }}.new
      end

      signal
    end
  end

  # Connects a method as handler for a signal. The method must be given as
  # prototype. The argument types are not important though, feel free to omit
  # them.
  # Returns the signal handler.
  #
  # Example usage:
  # ```
  # class Window
  #   def initialize
  #     @btn = Button.new
  #     @btn_handler = Cute.connect @btn.clicked, on_button_clicked(x, y)
  #   end
  #
  #   def on_button_clicked(x, y)
  #     # ...
  #   end
  # end
  # ```
  #
  # See `samples/qt_connect.cr` for a runnable example.
  #
  # **Note:** The handler may be called in a different Fiber.
  macro connect(signal, handler)
    {% if handler.args.empty? %}
      {{ signal }}.on{ {{ handler.name }} }
    {% else %}
      {{ signal }}.on do |{{ handler.args.map{|c| c.is_a?(Call) ? c : c.var }.argify }}|
        {{ handler.name }}({{ handler.args.map{|c| c.is_a?(Call) ? c : c.var }.argify }})
      end
    {% end %}
  end
end
