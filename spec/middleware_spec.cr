require "./spec_helper"

private class Chat
  getter sent = [ ] of String

  Cute.middleware def send_message(body : String) : Int32
    @sent << body
    body.size
  end

  Cute.middleware def ping : Int32
    123
  end
end

describe "Cute.middleware" do
  describe "without arguments" do
    it "works fine" do
      chat = Chat.new
      chat.ping.add{|y| y.call * 2}
      chat.ping.call.should eq 123 * 2
    end
  end

  describe "with arguments" do
    context "if no middleware was added" do
      it "calls the method" do
        chat = Chat.new
        chat.send_message.call("Hello").should eq 5
        chat.sent.should eq [ "Hello" ]
      end
    end

    context "if one middleware was added" do
      it "calls the middleware, then the method" do
        chat = Chat.new
        chat.send_message.add{|m, y| y.call m.upcase}
        chat.send_message.call("Hello").should eq 5
        chat.sent.should eq [ "HELLO" ]
      end
    end

    context "if multiple middlewares are added" do
      it "calls the middlewares in order, then the method" do
        chat = Chat.new
        chat.send_message.add{|m, y| y.call m.upcase}
        chat.send_message.add{|m, y| y.call "saying #{m}"}
        chat.send_message.call("Hello").should eq "saying HELLO".size
        chat.sent.should eq [ "saying HELLO" ]
      end
    end

    context "if a middleware doesn't call onwards" do
      it "the next stage is not called" do
        chat = Chat.new
        chat.send_message.add{|m, y| -1}
        chat.send_message.add{|m, y| y.call m.upcase}
        chat.send_message.call("Hello").should eq -1
        chat.sent.empty?.should eq true
      end
    end
  end
end
