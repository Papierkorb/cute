require "../src/cute"

# Demonstrates the use of signals, and sinks.  This is showcasing a real-world
# like application, which has data sources that need to be displayed on screen.
# To reduce flicker, a sink is used, so the screen is only updated up to once
# per second, or not at all if no data has been changed.

# Draws an integer on the screen.
class DataDisplay
  INNER_WIDTH = 10

  getter data : Int32 = 0

  # Signal emitted when the display has been changed.  A display driver should
  # schedule a redraw of this display in the near future.
  Cute.signal changed

  # Lets have a setter method which emits `changed` if the new *value* is
  # actually different to the old value.
  def data=(value)
    if @data != value
      @data = value
      changed.emit
    end
  end

  # The render method.
  def to_s(io)
    io << "[ #{@data.to_s.ljust(INNER_WIDTH)} ]"
  end
end

# Source of data.  We simulate this by emitting a new random value after a
# random amount of time.
class DataSource
  VALUE_RANGE = 1..1000
  SLEEP_RANGE = 0.01..1.0

  # Much like in `DataDisplay`.
  Cute.signal changed(data : Int32)

  def initialize
    spawn do
      loop do
        changed.emit rand(VALUE_RANGE) # Result of a complex calculation
        sleep rand(SLEEP_RANGE) # Next value will take a bit
      end
    end
  end
end

# The class pulling all of this together.
class DataApplication
  DISPLAYS = 5

  @displays = [ ] of DataDisplay

  def initialize
    # We're using an interval sink, meaning, we want to get notified if anything
    # happened within one second.
    @sink = Cute::IntervalSink(Nil).new(interval: 1.seconds)

    # If something happened, then redraw the application
    @sink.on{|hits| redraw hits.size}

    # Create something that can change
    DISPLAYS.times{ @displays << create_display }
    redraw # Don't forget to draw something initially!
  end

  private def create_display
    source = DataSource.new # We have a source
    display = DataDisplay.new # And something to show incoming data

    # If the source gets new data, supply it to the display
    source.changed.on{|value| display.data = value}

    # If the display changes somehow, schedule a redraw
    display.changed.on(@sink)

    display
  end

  def redraw(hits = 0)
    line = @displays.map(&.to_s).join(" ")

    STDOUT.raw do # Render the displays
      STDOUT.print "\r "
      STDOUT.print line
      STDOUT.print " Updates: #{hits.to_s.ljust 10}"
      STDOUT.flush
    end
  end
end

# Create the application
app = DataApplication.new

# At this point, the application runs asynchronously.
# So, put the main fiber to sleep, else our program would exit right away.
sleep
