require "../src/cute"

# Demonstrates the use of `Cute::BufferSink` to wait for multiple emissions to
# occur.

# Runs a complex calculation in parallel
class SomethingComplex
  Cute.signal finished(index : Int32)

  def initialize(@index : Int32)
  end

  def run
    spawn do
      sleep rand(0.0..2.0)
      finished.emit @index
    end
  end
end

# The destination sink.  Batch the result into pairs of five.
sink = Cute::BufferSink(Int32).new(size: 5)
10.times do |index| # Create ten jobs
  thing = SomethingComplex.new(index)
  thing.finished.on(sink) # Connect the signal to our sink
  thing.run               # Run the complex calculation!
end

# Ten jobs, at batches of five, so wait two times.
pp sink.wait
pp sink.wait

# Other sink types you can try are `IntervalSink` and `TimedBufferSink`
