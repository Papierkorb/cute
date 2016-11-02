require "./spec_helper"
require "../src/spec"

private class Thing
  Cute.signal none
  Cute.signal one(msg : String)
  Cute.signal many(a : Bool, b : Int32)
end

describe Cute::SignalSpy do
  context "signal without arguments" do
    it "adds nil" do
      thing = Thing.new
      spy = Cute.spy thing, none

      spy.size.should eq 0

      thing.none.emit
      spy.size.should eq 1

      thing.none.emit
      spy.size.should eq 2

      spy.should eq [ nil, nil ]
    end
  end

  context "signal with one argument" do
    it "adds the value" do
      thing = Thing.new
      spy = Cute.spy thing, one(msg : String)

      spy.size.should eq 0

      thing.one.emit "First"
      spy.size.should eq 1

      thing.one.emit "Second"
      spy.size.should eq 2

      spy.should eq [ "First", "Second" ]
    end
  end

  context "signal with multiple arguments" do
    it "adds the value" do
      thing = Thing.new
      spy = Cute.spy thing, many(a : Bool, b : Int32)

      spy.size.should eq 0

      thing.many.emit true, 1
      spy.size.should eq 1

      thing.many.emit false, 2
      spy.size.should eq 2

      spy.should eq [ { true, 1 }, { false, 2 } ]
    end
  end
end
