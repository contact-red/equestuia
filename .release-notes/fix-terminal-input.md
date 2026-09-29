## Fix terminal input requiring Enter

`StdinInput` now enables raw terminal input when subscribed, so key presses are delivered without waiting for Enter and typed characters are no longer echoed by the terminal. Disposing `StdinInput` restores the previous terminal settings.

This is needed since a recent ponyc upgrade changed the default mode on stdin.
