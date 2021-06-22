module Cute
  # Base class for `Cute.signal`
  abstract class Signal
    # Returns the name of the signal, if applicable.
    def name : String?
      nil
    end

    # Removes the handler with the handle *handler_hash*.
    def disconnect(handler_hash)
      @listeners.reject! { |handler| handler.hash == handler_hash }
    end

    # Removes all handlers
    def disconnect
      @listeners.clear
    end

    # Waits for the next event and returns the signal arguments.
    # See `samples/wait.cr` for a usage example.
    def wait
      channel, handle = new_channel
      result = channel.receive
      disconnect handle
      result
    end

    # Private-ish macro writing methods as required by `Signal` for a sub-class
    # of it.  `call` is expected to be a `CallNode`, and `async` if the signal
    # emission shall be delivered asynchronously, or right away.
    #
    # **Note**: You usually don't use this macro yourself.  See `Cute.signal`
    # instead.
    macro implementation(call, async)
      {% if call.args.empty? %}
        {% handler_type = "Proc(Nil)" %}
        {% channel_type = "Channel(Nil)" %}
      {% else %}
        {% handler_type = "Proc(#{call.args.map(&.type).splat}, Nil)" %}
        {% if call.args.size == 1 %}
          {% channel_type = "Channel(#{call.args[0].type})" %}
        {% else %}
          {% channel_type = "Channel(Tuple(#{call.args.map(&.type).splat}))" %}
        {% end %}
      {% end %}

      @listeners : Array({{ handler_type.id }})

      def initialize
        @listeners = Array({{ handler_type.id }}).new
      end

      def name : String
        {{ call.name.stringify }}
      end

      def on(&block : {{ handler_type.id }}) : ::Cute::ConnectionHandle
        @listeners << block
        block.hash.to_u64
      end

      def on(sink : Cute::Sink(U)) forall U
        if sink.is_a?(Cute::Sink(Nil))
          on{ sink.notify(nil.as(U)).as(U) }
        else
          {% if call.args.empty? %}
            on{ sink.notify(nil.as(U)).as(U) }
          {% elsif call.args.size == 1 %}
            on{|arg| sink.notify(arg.as(U)).as(U)}
          {% else %}
            on{|{{ call.args.map(&.var.id).splat }}| sink.notify({ {{ call.args.map(&.var.id).splat }} }.as(U)).as(U)}
          {% end %}
        end
      end

      def emit({{ call.args.splat }}) : Nil
        {% if async %}spawn do{% end %}
        @listeners.each do |handler|
          handler.call({{ call.args.map(&.var.id).splat }})
        end
        {% if async %}end{% end %}
      end

      def new_channel : Tuple({{ channel_type.id }}, ::Cute::ConnectionHandle)
        ch = {{ channel_type.id }}.new

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
  end
end
