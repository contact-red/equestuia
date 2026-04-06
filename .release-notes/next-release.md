## Initial Release

Still some work to do, but you should be able to build applications with it.  I do not forsee the API changing hugely.

## Fix UIBuilder tabs= wrapping rendering

Stack widgets with `tabs=` were broken: the tab bar or the stack content was invisible depending on whether the stack was the root widget or nested. This happened because the wrapper container was created after the Stack, leaving the Stack's parent pointing to the wrong widget. Both root and nested stacks with tabs now render correctly.

## Fix Enter key not recognized

Enter key presses were silently ignored. Terminals with the ICRNL flag (the default on most systems) translate CR to LF before delivery, and the input parser only recognized CR. Enter now works in all standard terminal configurations.

## Add Stack example

New `examples/stack` demonstrates tabbed navigation with a Stack widget using `tabs=north`, multiple pages with different content, and keyboard-driven tab switching.

