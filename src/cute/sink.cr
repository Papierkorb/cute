module Cute
  # Base class for sinks.  A sink acts like a `Signal`, and is used to emit upon
  # fulfilling sink-specific conditions.
  #
  # ## Usage
  #
  # A sink really acts like a `Signal`, because it is one.  This means, you
  # connect to it using `#on`.  You can even chain sinks!
  # You connect a `Sink` to a `Signal` by passing it as argument to `#on`:
  #
  # ```
  # btn = Button.new
  # sink = Cute::BufferSink(Nil).new(size: 2)
  # btn.clicked.on(sink)
  # sink.on { puts "Clicked twice!" }
  # ```
  #
  # The generic argument to the class is what the signal emits as type.  The
  # example above uses the Button class, used as example for `Cute.signal`. Its
  # `clicked` signal however had the two arguments `x : Int32, y : Int32`!  If
  # you want to collect these, you have to pass the type(s) as generic argument:
  #
  # ```
  # btn = Button.new
  # sink = Cute::BufferSink(Tuple(Int32, Int32)).new(size: 2)
  # btn.clicked.on(sink)
  # sink.on { |collected| puts "Clicked twice, positions: #{collected}" }
  # ```
  #
  # **Note**: When you're using a sink to collect from a signal passing multiple
  # arguments you have to use a `Tuple` as type to collect them all at once.
  #
  # **Note**: To collect a signal with no arguments, use `Nil`, like in
  # `Cute::BufferSink(Nil).new(...)`
  #
  # In the above example, the `collected` argument to the `#on` block to the
  # sink will contain all collected signal emission arguments since the last
  # emission.
  #
  # ### Writing synchronously using asynchronous signals
  #
  # Another great use-case using a sink with the `Signal#wait` method.
  # Let's assume your program downloads data in parallel from the Internet,
  # showing progress to the user using signals, and want to process the
  # results at once after finishing all of them:
  #
  # ```
  # def download_all(urls) : Cute::Sink
  #   sink = Cute::BufferSink(HttpResponse).new(size: urls.size) # Create a sink
  #   urls.each do |url|
  #     down = AsynchronousDownloader.new(url)
  #     down.progress.on { |percent| show_progress(down, percent) } # Update the UI
  #     down.finished.on(sink)                                      # Once finished, notify the sink
  #   end
  #   sink # And return the sink
  # end
  # ```
  #
  # With that method in place, it's really easy to write synchronous code to
  # process the results:
  #
  # ```
  # sink = download_all(the_urls) # Start the asynchronous download
  # results = sink.wait           # Use Signal#wait to wait
  # # results will be a `Array(HttpResponse)`
  # pp results # Do something with the results.
  # ```
  #
  # Following a pattern like this makes it easy to inform your user about
  # progress, while being able to easily write synchronous code: The best of
  # both worlds.
  #
  # ### Manually using a sink
  #
  # It may be useful to manually provide data into a sink.  This is useful to
  # convert results from a non-signal based into a signal based one.
  #
  # For this, you can use `Sink#notify`:
  # ```
  # sink = Cute::BufferSink(Int32).new(size: 10) # Set it up
  # sink.on { |data| puts "Calculation results: #{data}" }
  #
  # 10.times { sink.notify rand(1..100) } # Calculate and provide data
  # ```
  #
  # ### Creating a custom sink
  #
  # You can easily create a custom sink.  All you have to do is sub-classing
  # `Sink(T)`.
  #
  # Provide an implementation `#process_notification`.  And
  # that's it.  See the built-in sinks for implementation examples.
  abstract class Sink(T) < Signal
    Cute::Signal.implementation(dummy(data : Array(T)), true)

    def initialize
      super()
      @listeners = Array(Proc(Array(T), Nil)).new
      @collected = [] of T
    end

    def notify(data : T)
      @collected << data
      process_notification
    end

    protected def emit_now
      list = @collected
      @collected = [] of T
      emit list
    end

    # Count of hits since the last emission.
    def hit_count : Int32
      @collected.size
    end

    # Stops the sink, disposing of internal state.
    def stop!
      disconnect
    end

    # Called from `#notify` for the implementation to do any work required after
    # the sink has been notified of new data.  Some sinks may not require this
    # method and can provide an empty implementation.
    protected abstract def process_notification
  end
end
