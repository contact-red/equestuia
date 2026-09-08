## Update InputActor for ponyc 0.71.0

`InputActor.create` now requires a `SignalAuth` parameter for SIGWINCH handling, matching the ponyc 0.71.0 signals API.

Before:

```pony
let input_actor = InputActor(input, compositor)
```

After:

```pony
use "signals"

let input_actor = InputActor(SignalAuth(env.root), input, compositor)
```
