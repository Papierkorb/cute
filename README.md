# Cute [![Build Status](https://travis-ci.org/Papierkorb/cute.svg?branch=master)](https://travis-ci.org/Papierkorb/cute)

An event-centric publisher/subscribe model for objects inspired by [the Qt framework](https://www.qt.io/)
and middleware runner.

## Why?

**Decoupled inter-module communication**  Using signals, you can let your front-
and back-end communicate without letting one know of the other.

**Asynchronous work-flow** Take action when events occur.  Or add this later
when a business-case appears.  Never poll again.

**Resource saving** Reduce load on CPU by only rendering only when something
happened.  Reduce network traffic by batching messages to be sent into fewer
densly packed network packets.

**Ease development** Don't waste too much time on not leaking fibers all over
the place.

**Standarized communication** Use signals at every layer, and have one
standarized way of in-process communication.  Don't write callback handling
code for the umpteenth time.  You need to act on data, and not react to it?
See middlewares!

**Test communication** Using `Cute.spy`, you can spy on signal communication.
Have an excuse for not testing it up til now?  Well, not anymore :)

**Test processing robustness** Using middlewares for processing data?  You can
easily add a middleware which fails: Always for tests, or just now and then.
To improve in-process robustness - Or to drive your coworker crazy.
Please prefer the former.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  cute:
    github: Papierkorb/cute
```

## Usage

See [samples/](https://github.com/Papierkorb/cute/tree/master/samples) for more examples.

### Signals

Let your user know about an event, without disrupting flow, and without writing
some callback code for the umpteenth time.  This is a notification mechanism,
so the callback (the "slot") has no way of returning something to you.  If you
need that, see the next section.

See the in-source docs of `Cute.signal` for further details.

```crystal
require "cute"

class Button
  Cute.signal clicked(x : Int32, y : Int32)
end

btn = Button.new
btn.clicked.on { |x, y| p x, y }
btn.clicked.emit 5, 4 #=> Will print 5, 4
```

### Middleware

It's easy to allow the user of your library to augment, or otherwise extend,
the behaviour of your logic.  A middleware works akin to a UNIX pipe, where
the input arguments (or the result) can be modified along the call.

See the `Cute.middleware` in-source docs for further details.

```crystal
class Chat
  @io : IO = STDOUT

  Cute.middleware def send_message(body : String) : Int32
    @io.puts "Sending #{body}"
    body.size
  end
end

chat = Chat.new

# Add a Capt'n Caps middleware :)
chat.send_message.add { |body, yielder| yielder.call(body.upcase) }

# Send a message
chat.send_message.call("Hello") #=> 5
# Prints "Sending HELLO"
```

## Contributing

1. Fork it ( https://github.com/Papierkorb/cute/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Papierkorb](https://github.com/Papierkorb) Stefan Merettig - creator, maintainer
