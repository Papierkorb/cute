module Cute
  # Base class for `Cute.signal`
  abstract class Signal
    # Removes the handler with the handle *handler_hash*.
    def disconnect(handler_hash)
      @listeners.reject!{|handler| handler.hash == handler_hash}
    end

    # Waits for the next event and returns the signal arguments.
    # See `samples/wait.cr` for a usage example.
    def wait
      channel, handle = new_channel
      result = channel.receive
      disconnect handle
      result
    end
  end
end
