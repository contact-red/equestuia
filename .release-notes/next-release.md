## Initial Release

Still some work to do, but you should be able to build applications with it.  I do not forsee the API changing hugely.

## Fix UIBuilder tabs= wrapping rendering

Stack widgets with `tabs=` were broken: the tab bar or the stack content was invisible depending on whether the stack was the root widget or nested. This happened because the wrapper container was created after the Stack, leaving the Stack's parent pointing to the wrong widget. Both root and nested stacks with tabs now render correctly.

## Fix Enter key not recognized

Enter key presses were silently ignored. Terminals with the ICRNL flag (the default on most systems) translate CR to LF before delivery, and the input parser only recognized CR. Enter now works in all standard terminal configurations.

## Add Stack example

New `examples/stack` demonstrates tabbed navigation with a Stack widget using `tabs=north`, multiple pages with different content, and keyboard-driven tab switching.

## Fix UIBuilder bg= silently overwriting fg=

Setting both `fg=` and `bg=` on a Label or TextBox in the DSL (e.g., `label "Hi" fg=green bg=red`) silently discarded the foreground color — `bg=` hardcoded white as the foreground. Both properties now apply independently.

## Add set_fg/set_bg behaviors to Label and TextBox

Label and TextBox now have `set_fg` and `set_bg` behaviors for changing foreground or background color independently. The existing `set_color` behavior (which sets both at once) is unchanged.

```pony
label.set_fg(Green)
label.set_bg(Red)
// or set both at once, as before:
label.set_color(Green, Red)
```
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

