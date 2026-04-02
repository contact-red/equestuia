# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make test          # Compile and run all tests
make counter       # Build examples/counter
make keyboard      # Build examples/keyboard
make clean         # Remove build directory
```

Tests use `pony_test` and `pony_check` (property-based). The test harness is `equestuia/_test.pony` — register new tests there. All test files are `_test_*.pony` in the `equestuia/` directory.

Build uses `corral run -- ponyc`. Run `corral fetch` (or `make fetch`) if dependencies are missing.

## Architecture

equesTUIa is an actor-based TUI library for Pony. Widgets are actors that produce 2D grids of styled cells. Grids flow up through a widget tree to a Compositor that diffs against the previous frame and emits minimal ANSI escape sequences.

### Message Flow

```
Terminal → StdinInput → InputActor → Widget (receive_key)
                                        ↓ (render_and_send)
Terminal ← StdoutOutput ← Compositor ← Widget (receive_grid on parent)
```

InputActor owns focus (Tab/Shift-Tab cycling) and routes SIGWINCH resize events. The Compositor owns the screen buffer and does differential rendering.

### Widget System

**Widget** (`_widget_base.pony`) — trait for all widget actors. Requires:
- `fun ref state(): WidgetState` — return the state field
- `fun ref render(): Grid` — produce the visual output

Default behaviors provided for `resize`, `trigger_render`, `receive_key`, `receive_focus`, `receive_blur`, `set_debug_bg`.

**CompositeWidget** — extends Widget for containers. Adds child grid storage, dirty-flag coalescing (multiple child updates batched into one rerender via `_deferred_render`), and a default `render()` that composites children on top of `render_background()`. Children must be explicitly registered via `register_child`, `pack_start`/`pack_end`, or `set_child` — there is no lazy discovery.

**WidgetState** (`_widget_state.pony`) — bundles common fields: `parent`, `width`, `height`, `child_grids`, `dirty`, `debug_bg`. Every widget stores one `let _state: WidgetState` field and exposes it via `fun ref state()`.

### Construction Pattern

Widgets start at size 0x0. Containers don't repack on `pack_start`/`pack_end` — layout only happens when the container's own `resize` arrives. The root widget's `resize` must be the last message sent, after all children are added. `compositor.set_root(widget)` handles this for the common case.

```pony
// Build tree first (all async messages queue up)
let vbox = VBox(compositor)
let label = Label(vbox, "Hello", Green)
vbox.pack_start(label, 80, 1)
// Kick off layout cascade last
compositor.set_root(vbox)
```

### Packing Model

HBox/VBox use GTK2-style packing with `PackMode`:
- `PackFixed` (default) — child gets preferred size
- `PackExpand` — claims extra space, centered at preferred size
- `PackFill` — claims extra space and stretches to fill

Container-level `Alignment` (AlignStart/AlignCenter/AlignEnd) positions the entire group of packed children. Cross-axis always fills the container width/height.

### Pony-Specific Patterns

- All cross-actor data is `val` (Cell, Grid, ViewPort, PackOption, etc.)
- `fun ref` methods on traits are uncallable from outside the actor (external refs are `tag`) — used to expose internal state without making fields public
- `recover val/iso` blocks can't access `ref` fields — capture into locals before the block
- `Grid._from()` is package-private (underscore prefix) — use `GridFactory` or `Grid.filled` from outside the package
- Widget identity uses `Any tag` with `is` comparison for actor identity matching
- `DrawingPrimitives` functions are `fun tag` so they work inside `recover` blocks

## Conventions

- Pony docstrings: opening and closing `"""` on their own lines
- Commit messages: `feat:`, `refactor:`, `perf:`, `docs:`, `fix:` prefixes
- No Co-Authored-By headers in commits
- `docs/` directory is in `.gitignore` — never commit docs
- Library source files have no prefix; test files start with `_test`
- Type names with `_` prefix are package-private in Pony (e.g. `_WinchNotify`, `_HitTestRequester`)
- Test files: `_test_*.pony`, test classes: `_TestFoo` / `_PropFoo`
