require "./spec_helper"

describe Cute::TimedBufferSink do
  describe "emission behaviour" do
    it "emits after 3 elements or 10msec" do
      subject = Cute::TimedBufferSink(Int32).new(interval: 10.milliseconds, size: 3)

      emits = [] of Array(Int32)
      empty = [] of Array(Int32)
      subject.on{|x| emits << x}

      # Both buffer and time constraints
      (1..5).each{|i| subject.notify i}

      sleep 20.milliseconds
      emits.should eq [ [ 1, 2, 3 ], [ 4, 5 ] ]

      # Time constraint
      (6..7).each{|i| subject.notify i}

      sleep 20.milliseconds
      emits.should eq [ [ 1, 2, 3 ], [ 4, 5 ], [ 6, 7 ] ]

      # Size constraint
      subject.notify 8
      subject.notify 9
      subject.notify 0

      start = Time.utc
      Fiber.yield # We're not hitting the time constraint, right?
      (start - Time.utc).should be < 10.milliseconds

      emits.should eq [ [ 1, 2, 3 ], [ 4, 5 ], [ 6, 7 ], [ 8, 9, 0 ] ]

      # Does nothing if no notifications are received
      sleep 20.milliseconds
      emits.should eq [ [ 1, 2, 3 ], [ 4, 5 ], [ 6, 7 ], [ 8, 9, 0 ] ]
    end
  end
end
