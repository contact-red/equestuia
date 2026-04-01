"""
equesTUIa: Intermediate-mode TUI library for Pony.

Widget-actors own their state, produce 2D styled-cell grids, and send them
to a compositor that diffs and renders to the terminal.

## Quick Start

```pony
actor MyWidget
  let _base: WidgetBase

  new create(compositor: Compositor tag, input_actor: InputActor tag) =>
    let renderer = object iso is Renderable
      fun render(width: USize, height: USize): Grid =>
        Grid.filled(width, height, Cell('*', 1, Green, Default, 0))
    end
    _base = WidgetBase(compositor, consume renderer, 20, 10)
```

## Core Types

- `Cell` — styled terminal character (char, width, fg, bg, attrs)
- `Grid` — 2D rectangle of cells
- `Color` — ANSI color union (Default, Black, Red, ..., BrightWhite)
- `CellAttrs` — attribute bitfield constants (bold, dim, underline, blink, reverse)

## Positioning

- `Anchor` — compass direction (North, NorthEast, ..., Center)
- `ViewPort` — position, size, offset, z-order
- `SizeHint` — preferred dimensions for box packing
- `PackOption` — GTK2-style packing (from_end, expand, fill, padding)

## Actors

- `Compositor` — composites widget grids, diffs, renders to TerminalOutput
- `InputActor` — parses terminal input, routes events, manages focus
- `WidgetBase` — base widget actor with framework plumbing
- `HBox` / `VBox` — container widgets with GTK2-style packing

## I/O

- `TerminalOutput` / `TerminalInput` — traits for I/O abstraction
- `StdoutOutput` / `StdinInput` — default implementations

## Widget Traits

- `Renderable` — produce a Grid from allocated dimensions
- `Updatable[M]` — handle typed messages
- `InputHandler` — handle key events
- `Focusable` — react to focus/blur
"""
