"""
equesTUIa: Intermediate-mode TUI library for Pony.

Widget-actors own their state, produce 2D styled-cell grids, and send them
to a compositor that diffs and renders to the terminal.

## Core Types

- `Cell` — styled terminal character (char, width, fg, bg, attrs)
- `Grid` — 2D rectangle of cells
- `Color` — ANSI color union (Default, Black, Red, ..., BrightWhite)
- `CellAttrs` — attribute bitfield constants (bold, dim, underline, blink, reverse)

## Positioning

- `Anchor` — compass direction (North, NorthEast, ..., Center)
- `ViewPort` — position, offset, z-order
- `PackOption` — GTK2-style packing (from_end, expand, fill, padding)

## Actors

- `Compositor` — composites widget grids, diffs, renders to TerminalOutput
- `InputActor` — parses terminal input, routes events, manages focus
- `HBox` / `VBox` — container widgets with GTK2-style packing
- `Frame` — single-child container with box border and optional title
- `Label` — single-line text display
- `TextBox` — multi-line text display with optional word wrap
- `HLine` / `VLine` — horizontal/vertical line widgets

## I/O

- `TerminalOutput` / `TerminalInput` — traits for I/O abstraction
- `StdoutOutput` / `StdinInput` — default implementations
- `TermSize` — query terminal dimensions via ioctl

## Widget Traits

- `Widget` — base trait for all widget actors
- `CompositeWidget` — extends Widget for containers with child compositing
- `WidgetParent` — trait for anything that receives grids from children
"""
