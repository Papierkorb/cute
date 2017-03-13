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
  #
  # ## Testing
  #
  # Using `Cute.spy`, you can create signal spies, which will record all
  # emitted values.
  macro signal(call, async = false)
    # :nodoc:
    class Signal_{{ call.name.id }} < ::Cute::Signal
      {% if call.args.empty? %}
        alias Handler = Proc(Nil)
        alias HandlerChannel = Channel(Nil)
      {% else %}
        alias Handler = Proc({{ call.args.map(&.type).splat }}, Nil)
        {% if call.args.size == 1 %}
          alias HandlerChannel = Channel({{ call.args[0].type }})
        {% else %}
          alias HandlerChannel = Channel(Tuple({{ call.args.map(&.type).splat }}))
        {% end %}
      {% end %}

      def initialize
        @listeners = Array(Handler).new
      end

      def on(&block : Handler)
        @listeners << block
        block.hash
      end

      def emit({{ call.args.splat }}) : Nil
        {% if async %}spawn do{% end %}
        @listeners.each do |handler|
          handler.call({{ call.args.map(&.var.id).splat }})
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
          on{|{{ call.args.map(&.var.id).splat }}| ch.send({ {{ call.args.map(&.var.id).splat }} })}
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
      {{ signal }}.on do |{{ handler.args.map{|c| c.is_a?(Call) ? c : c.var }.splat }}|
        {{ handler.name }}({{ handler.args.map{|c| c.is_a?(Call) ? c : c.var }.splat }})
      end
    {% end %}
  end

  # Creates a *middleware*.  A middleware offers the user of your class to
  # extend its functionality by adding user-defined behaviour before calling
  # the actualy middleware, giving the opportunity to modify arguments or the
  # result value, or not call later stages at all.
  #
  # The argument to the macro is a full method definition, whose code body will
  # be called last.  It's named the "final stage" because of that, and always
  # exists.
  #
  # Like `Cute.signal`, the macro creates a class and makes the method return
  # it.  You can then `#add` middleware, get the `#list` of added middleware
  # and modify it directly, or `#call` it.
  #
  # Example usage:
  # ```
  # class Chat
  #   Cute.middleware def send_message(body : String) : String
  #     # `self` is the instance of `Chat` here.
  #     puts "Sending #{body}"
  #     "Sent #{body.size} bytes"
  #   end
  # end
  #
  # chat = Chat.new
  # chat.send_message.add { |body, yielder| yielder.call body.upcase }
  #
  # chat.send_message.call("Hello") #=> "Sent 5 bytes"
  # # Prints "Sending HELLO"
  # ```
  #
  # ## Calling behaviour
  #
  # When called (Through `#call`), the algorithm will run each middleware stage
  # in the order it was added (Or: As it appears in the `#list`).  That is, the
  # stage that was added first will be called first, the second one after that,
  # and finally the final stage.
  #
  # It's possible to manually add or reorder the middleware stages by modifying
  # the `#list` directly.
  #
  # The final stage is called in the context of the host class instance.  That
  # means it behaves like a normal method, as if it was declared without the
  # macro.
  #
  # ## Caveats
  #
  # For this to work you have to explicitly mark the argument and result types.
  # Also note that if your middleware decides to not call the next stage, you
  # still have to return something matching the return type.  You can make it
  # easier by allowing `nil` results.
  #
  # This won't work:
  # ```
  # # Swear filter
  # chat.send_message.add { |body, yielder| yielder.call(body) if body !~ /dang/ }
  # ```
  #
  # Possible solutions are these:
  # ```
  # # Solution 1: Return something matching the return type
  # chat.send_message.add do |body, yielder|
  #   if body !~ /dang/
  #     yielder.call(body)
  #   else
  #     "Swearing is not allowed"
  #   end
  # end
  #
  # # Solution 2: Allow nil result
  # class Chat
  #   Cute.middleware def send_message(body : String) : String?
  #     # ...
  #   end
  # end
  #
  # # Now the previous example would work fine:
  # chat.send_message.add { |body, yielder| yielder.call(body) if body !~ /dang/ }
  # ```
  macro middleware(deff)
    # Implementation of the {{ deff.name.id }} middleware.
    class Middleware_{{ deff.name.id }}(T) < ::Cute::Signal
      {% if deff.args.empty? %}
        alias Yielder = Proc({{ deff.return_type }})
        alias Handler = Proc(Yielder, {{ deff.return_type }})
      {% else %}
        alias Yielder = Proc({{ deff.args.map(&.restriction).splat }}, {{ deff.return_type }})
        alias Handler = Proc({{ deff.args.map(&.restriction).splat }}, Yielder, {{ deff.return_type }})
      {% end %}

      def initialize(@instance : T)
        @listeners = Array(Handler).new
      end

      # Returns the list of middleware.
      def list
        @listeners
      end

      # Appends a middleware handler
      def add(&block : Handler)
        @listeners << block
        block.hash
      end

      # Appends *handler*
      def add(handler : Handler)
        @listeners << handler
        handler.hash
      end

      # Calls the middleware chain.
      def call({{ deff.args.splat }})
        call_stage(0, {{ deff.args.map(&.name).splat }})
      end

      private def call_stage(cute_stage_idx, {{ deff.args.splat }})
        if cute_stage_idx >= @listeners.size
          @instance.call_{{ deff.name.id }}({{ deff.args.map(&.name).splat }})
        else
          yielder = ->({{ deff.args.splat }}){ call_stage(cute_stage_idx + 1, {{ deff.args.map(&.name).splat }}) }
          @listeners[cute_stage_idx].call({% unless deff.args.empty? %}{{ deff.args.map(&.name).splat }}, {% end %}yielder)
        end
      end
    end

    # Calls the final stage of {{ deff.name.id }} directly, without calling any
    # previous stages.
    def call_{{ deff.name.id }}({{ deff.args.splat }})
      {{ deff.body }}
    end

    @cute_middleware_{{ deff.name.id }} : Middleware_{{ deff.name.id }}(self)?

    # Returns the {{ deff.name.id }} middleware object.
    def {{ deff.name.id }} : Middleware_{{ deff.name.id }}
      middleware = @cute_middleware_{{ deff.name.id }}

      if middleware.nil?
        middleware = @cute_middleware_{{ deff.name.id }} = Middleware_{{ deff.name.id }}.new(self)
      end

      middleware
    end
  end
end
