require "./spec_helper"

describe Cute::BufferSink do
  describe "emission behaviour" do
    it "emits at the exact amount of given notifications" do
      subject = Cute::BufferSink(Int32).new(size: 3)

      emits = [] of Array(Int32)
      empty = [] of Array(Int32)
      subject.on { |x| emits << x }

      subject.notify 1
      subject.notify 2
      subject.notify 3

      Fiber.yield
      emits.should eq [[1, 2, 3]]

      (4..8).each { |i| subject.notify i }

      Fiber.yield
      emits.should eq [[1, 2, 3], [4, 5, 6]]

      subject.notify 9

      Fiber.yield
      emits.should eq [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
    end
  end
end
