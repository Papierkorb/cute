require "./spec_helper"

private class Widget
  Cute.signal moved(x : Int32, y : Int32)
  Cute.signal one(message : String)
  Cute.signal closed
  Cute.signal asynced, async: true
end

private class Listener
  getter move_data : Tuple(Int32, Int32)?
  getter one_data : String?
  getter close_data : Bool = false

  def initialize(widget)
    Cute.connect widget.moved, on_move(x : Int32, y)
    Cute.connect widget.one, on_one(msg)
    Cute.connect widget.closed, on_close
  end

  def on_move(x, y)
    @move_data = { x, y }
  end

  def on_one(msg)
    @one_data = msg
  end

  def on_close
    @close_data = true
  end
end

describe "Cute.connect" do
  it "works with zero signal arguments" do
    widget = Widget.new
    subject = Listener.new(widget)

    widget.closed.emit
    subject.close_data.should be_true
  end

  it "works with one signal argument" do
    widget = Widget.new
    subject = Listener.new(widget)

    widget.one.emit("Okay")
    subject.one_data.should eq("Okay")
  end

  it "works with many signal arguments" do
    widget = Widget.new
    subject = Listener.new(widget)

    widget.moved.emit(5, 6)
    subject.move_data.should eq({ 5, 6 })
  end
end
