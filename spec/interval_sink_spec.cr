require "./spec_helper"

describe Cute::IntervalSink do
  describe "emission behaviour" do
    it "emits every 10msec at max" do
      subject = Cute::IntervalSink(Int32).new(interval: 10.milliseconds)

      emits = [] of Array(Int32)
      empty = [] of Array(Int32)
      subject.on{|x| emits << x}

      subject.notify 1
      subject.notify 2
      subject.notify 3

      sleep 20.milliseconds
      emits.should eq [ [ 1, 2, 3 ] ]

      (4..8).each{|i| subject.notify i}

      sleep 20.milliseconds
      emits.should eq [ [ 1, 2, 3 ], [ 4, 5, 6, 7, 8 ] ]

      subject.notify 9

      sleep 20.milliseconds
      emits.should eq [ [ 1, 2, 3 ], [ 4, 5, 6, 7, 8 ], [ 9 ] ]

      # Emits nothing if no notifications are received
      sleep 20.milliseconds
      emits.should eq [ [ 1, 2, 3 ], [ 4, 5, 6, 7, 8 ], [ 9 ] ]
    end
  end
end
