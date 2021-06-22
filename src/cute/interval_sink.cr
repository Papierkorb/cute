module Cute
  # This sink has an internal timer.  All collected data is only emitted once
  # the timer triggers.  If no data has been collected, the sink does not emit.
  #
  # See `Sink` for documentation on the usage.
  class IntervalSink(T) < Sink(T)
    # Check interval
    property interval : Time::Span

    def initialize(@interval : Time::Span)
      super()
      @active = true
      create_timer_fiber
    end

    # Will eventually halt the internal timer fiber, releasing resources this
    # sink occupies.
    def stop!
      @active = false
      super
    end

    private def create_timer_fiber
      spawn(name: "Cute::IntervalSink timer fiber") do
        while @active
          emit_now if hit_count > 0
          sleep @interval
        end
      end
    end

    protected def process_notification
      # Do nothing.
    end
  end
end
