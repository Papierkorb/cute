# Cute [![Build Status](https://travis-ci.org/Papierkorb/cute.svg?branch=master)](https://travis-ci.org/Papierkorb/cute)

An event-centric publisher/subscribe model for objects inspired by [the Qt framework](https://www.qt.io/)
and middleware runner.

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
