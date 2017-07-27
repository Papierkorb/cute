require "./spec_helper"

private class Widget
  Cute.signal moved(x : Int32, y : Int32)
  Cute.signal one(message : String)
  Cute.signal closed
  Cute.signal asynced, async: true
end

private class TestSink(T) < Cute::Sink(T)
  getter collected
  property last_input : T?

  protected def process_notification
    @last_input = @collected.last
  end
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

    it "accepts a sink" do
      subject = Widget.new
      sink = TestSink(String).new

      handler = subject.one.on(sink)

      handler.should_not be_nil
      sink.last_input.should be_nil

      subject.one.emit "Hello"
      sink.last_input.should eq "Hello"
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

  describe "emission into a sink" do
    context "with T = nil and non-nil signal argument" do
      it "collects a nil" do
        widget = Widget.new
        sink = TestSink(Nil).new

        widget.one.on(sink)
        widget.one.emit "Foo"

        sink.collected.should eq [ nil ]
      end
    end

    context "with T = nil and multi-argument signal" do
      it "collects a nil" do
        widget = Widget.new
        sink = TestSink(Nil).new

        widget.moved.on(sink)
        widget.moved.emit 4, 5

        sink.collected.should eq [ nil ]
      end
    end

    context "with T = nil and signal with no arguments" do
      it "collects a nil" do
        widget = Widget.new
        sink = TestSink(Nil).new

        widget.closed.on(sink)
        widget.closed.emit

        sink.collected.should eq [ nil ]
      end
    end

    context "with a single argument signal" do
      it "collects the argument" do
        widget = Widget.new
        sink = TestSink(String).new

        widget.one.on(sink)
        widget.one.emit "Foo"
        widget.one.emit "Bar"

        sink.collected.should eq [ "Foo", "Bar" ]
      end
    end

    context "with a multi-argument signal" do
      it "collects all arguments as tuple" do
        widget = Widget.new
        sink = TestSink(Tuple(Int32, Int32)).new

        widget.moved.on(sink)
        widget.moved.emit 4, 5
        widget.moved.emit 6, 7

        sink.collected.should eq [ { 4, 5 }, { 6, 7 } ]
      end
    end
  end

  describe "#disconnect(handler_hash)" do
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

  describe "#disconnect()" do
    it "removes all handlers" do
      subject = Widget.new

      calls = Array(Int32).new
      subject.closed.on{ calls << 1 }
      subject.closed.on{ calls << 2 }

      calls.empty?.should be_true
      subject.closed.disconnect
      subject.closed.emit
      calls.empty?.should be_true
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
