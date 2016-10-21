require "./spec_helper"

private class Widget
  Cute.signal moved(x : Int32, y : Int32)
  Cute.signal one(message : String)
  Cute.signal closed
  Cute.signal asynced, async: true
end

describe "Cute.signal" do
  describe "#on" do
    it "registers a handler" do
      subject = Widget.new
      response = 0

      handler = subject.moved.on do |x, y|
        response = x / y
      end

      subject.moved.emit 6, 3
      response.should eq 2
      handler.should_not be_nil
    end
  end

  describe "#emit" do
    it "calls multiple handlers in order" do
      subject = Widget.new

      calls = Array(Int32).new
      subject.closed.on{ calls << 1 }
      subject.closed.on{ calls << 2 }
      subject.closed.on{ calls << 3 }

      calls.size.should eq 0
      subject.closed.emit
      calls.should eq [ 1, 2, 3 ]
    end

    context "with async: true" do
      it "calls the handlers in a different fiber" do
        subject = Widget.new

        fibers = Array(Fiber).new
        subject.asynced.on{ fibers << Fiber.current }
        subject.asynced.on{ fibers << Fiber.current; Fiber.yield }

        subject.asynced.emit
        Fiber.yield # Call slot fiber

        fibers.size.should eq 2
        fibers[0].should_not be Fiber.current
        fibers[0].should be fibers[1]
      end
    end
  end

  describe "#disconnect" do
    it "removes a handler" do
      subject = Widget.new

      calls = Array(Int32).new
      subject.closed.on{ calls << 1 }
      handler = subject.closed.on{ calls << 2 }
      subject.closed.on{ calls << 3 }

      calls.size.should eq 0
      subject.closed.disconnect(handler)
      subject.closed.emit
      calls.should eq [ 1, 3 ]
    end
  end

  describe "#new_channel" do
    context "with one signal argument" do
      subject = Widget.new

      ch, handler = subject.one.new_channel
      fut = future{ ch.receive }
      subject.one.emit "Okay"

      handler.should_not be_nil
      fut.completed?.should be_true
      fut.get.should eq "Okay"
    end

    context "with many signal arguments" do
      subject = Widget.new

      ch, handler = subject.moved.new_channel
      fut = future{ ch.receive }
      subject.moved.emit 4, 5

      fut.completed?.should be_true
      handler.should_not be_nil
      fut.get.should eq({ 4, 5 })
    end

    context "with no signal arguments" do
      subject = Widget.new

      ch, handler = subject.closed.new_channel
      fut = future{ ch.receive }
      subject.closed.emit

      handler.should_not be_nil
      fut.completed?.should be_true
    end
  end

  describe "#wait" do
    context "with one signal argument" do
      subject = Widget.new

      spawn{ subject.one.emit "Okay" }
      result = subject.one.wait
      result.should eq "Okay"
    end

    context "with many signal arguments" do
      subject = Widget.new

      spawn{ subject.moved.emit 4, 5 }
      result = subject.moved.wait
      result.should eq({ 4, 5 })
    end

    context "with no signal arguments" do
      subject = Widget.new

      spawn{ subject.closed.emit }
      subject.closed.wait
    end
  end
end
