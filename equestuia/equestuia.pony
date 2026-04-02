"""
equesTUIa: Intermediate-mode TUI library for Pony.

Widget-actors own their state, produce 2D styled-cell grids, and send them
to a compositor that diffs and renders to the terminal.

## Core Types

- `Cell` — styled terminal character (char, width, fg, bg, attrs)
- `Grid` — 2D rectangle of cells
- `Color` — ANSI color union (Default, Black, Red, ..., BrightWhite)
- `CellAttrs` — attribute bitfield constants (bold, dim, underline, blink, reverse)

## Layout

- `Anchor` — compass direction (North, NorthEast, ..., Center)
- `ViewPort` — anchor, size, offset, z-order for compositor registration
- `PackOption` — packing options (expand, fill, padding)
- `Alignment` — container alignment (AlignStart, AlignCenter, AlignEnd)

## Widgets

- `Label` — single-line text display with alignment
- `TextBox` — multi-line text display with optional word wrap
- `HLine` / `VLine` — horizontal/vertical line widgets
- `HBox` / `VBox` — box containers with GTK2-style packing and alignment
- `Frame` — single-child container with box border and optional title

## Infrastructure

- `Compositor` — composites widget grids, diffs, renders to TerminalOutput.
  Use `set_root` for the common case of a full-screen root widget.
- `InputActor` — parses terminal input, routes events, manages focus
- `TerminalOutput` / `TerminalInput` — traits for I/O abstraction
- `StdoutOutput` / `StdinInput` — default implementations
- `TermSize` — query terminal dimensions via ioctl

## Widget Traits

- `Widget` — base trait for all widget actors. Requires `state()` and `render()`.
- `CompositeWidget` — extends Widget for containers with child compositing
- `WidgetParent` — trait for anything that receives grids from children
- `WidgetState` — bundles common widget fields (parent, width, height, etc.)

## Utilities

- `DrawingPrimitives` — helper functions for drawing shapes into cell arrays
- `AnsiEncoder` — ANSI escape sequence encoder
- `GridFactory` — validated Grid construction
"""
