module Cute
  # Combination of `IntervalSink` and `BufferSink`:  Consumes data until either
  # the maximum `#size` is reached, or the set `#interval` elapsed.
  #
  # See `Sink` for documentation on the usage.
  class TimedBufferSink(T) < IntervalSink(T)

    # Size of the buffer
    property size : Int32

    def initialize(@size : Int32, interval : Time::Span)
      super(interval)
    end

    protected def process_notification
      emit_now if hit_count >= @size
    end
  end
end
