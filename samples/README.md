# Directory of sample snippets

## Signals

* `simple.cr` - A basic example to get started
* `real_world.cr` - A small example application, using signals and sinks
* `qt_connect.cr` - Coming from C++/Qt? Missing `QObject::connect`? This is for you.
* `async.cr` - Using asynchronous signals to spawn a new fiber for emissions
* `channel.cr` - Using a `Channel(T)` as signal emission target
* `wait.cr` - How to wait for the next emission of a signal
* `testing.cr` - How to write specs (**test**) for signal communication

## Sinks

* `sink_synchronisation.cr` - How to use sinks as synchronisation primitive
* `real_world.cr` - Uses sinks to redraw the screen once per second - Or not at all.

## Middleware

* `middleware.cr` - Using middlewares to create a configurable process flow
* `monkey_middleware.cr` - How to test a middleware pipeline for robustness
