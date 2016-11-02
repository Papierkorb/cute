# Cute [![Build Status](https://travis-ci.org/Papierkorb/cute.svg?branch=master)](https://travis-ci.org/Papierkorb/cute)

An event-centric publisher/subscribe model for objects inspired by [the Qt framework](https://www.qt.io/).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  cute:
    github: Papierkorb/cute
```

## Usage

See the in-source docs of `Cute.signal` for further details,
see the `samples/` directory for more examples.

```crystal
require "cute"

class Button
  Cute.signal clicked(x : Int32, y : Int32)
end

btn = Button.new
btn.clicked.on { |x, y| p x, y }
btn.clicked.emit 5, 4 #=> Will print 5, 4
```

## Contributing

1. Fork it ( https://github.com/Papierkorb/cute/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Papierkorb](https://github.com/Papierkorb) Stefan Merettig - creator, maintainer
