module Cute
  # Sink buffering incoming data up to a specified size, emitting all at once
  # when specified count has been reached.
  #
  # See `Sink` for documentation on the usage.
  class BufferSink(T) < Sink(T)
    # Size of the buffer
    property size : Int32

    def initialize(@size : Int32)
      super()
    end

    protected def process_notification
      emit_now if hit_count >= @size
    end
  end
end
