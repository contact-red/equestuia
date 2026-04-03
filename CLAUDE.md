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

**Widget** (`widget_base.pony`) — trait for all widget actors. Requires:
- `fun ref state(): WidgetState` — return the state field
- `fun ref render(): Grid` — produce the visual output

Default behaviors provided for `resize`, `trigger_render`, `receive_key`, `receive_focus`, `receive_blur`, `set_debug_bg`.

**CompositeWidget** — extends Widget for containers. Adds child grid storage, dirty-flag coalescing (multiple child updates batched into one rerender via `_deferred_render`), and a default `render()` that composites children on top of `render_background()`. Children must be explicitly registered via `register_child`, `pack_start`/`pack_end`, or `set_child` — there is no lazy discovery.

**WidgetState** (`widget_state.pony`) — bundles common fields: `parent`, `width`, `height`, `child_grids`, `dirty`, `debug_bg`. Every widget stores one `let _state: WidgetState` field and exposes it via `fun ref state()`.

### Construction Patterns

**Imperative:**
```pony
let vbox = VBox(compositor)
let label = Label(vbox, "Hello", Green)
vbox.pack_start(label, 80, 1)
compositor.register_root(vbox)
vbox.resize(term_w, term_h)  // must be last — from same sender as pack calls
```

**Declarative (UIBuilder):**
```pony
let builder = UIBuilder(compositor, input_actor)
builder.register("counter", {(p) => Counter(p, env, input)} val)
match builder.build("vbox\n  pack-start *x1\n    label \"Hello\" fg=green")
| let root: Widget tag =>
  compositor.register_root(root)
  root.resize(term_w, term_h)
end
```

The builder parses an indentation-based DSL, instantiates widgets via a factory registry, wires parent-child relationships, applies properties, and registers focusable widgets. Custom widget types are added via `builder.register()`. Widgets retrievable by `#id` via `builder.get_widget()`.

### Async Message Ordering

All widget wiring is async (behaviors). Race conditions arise because messages from different actors to the same target are unordered. Key patterns:

- **Resize must come from the same sender as wiring**: `register_root()` registers without resizing. The caller sends `root.resize()` directly, ensuring it's ordered with `pack_start`/`set_child` messages from the same actor.
- **Self-healing containers**: `pack_start`/`pack_end`/`set_child` repack or resize the child immediately if the container already has dimensions. This handles late-arriving children after a resize cascade.
- **Dirty-flag coalescing**: CompositeWidget batches multiple child grid arrivals into one rerender via `_deferred_render`.

### Packing Model

HBox/VBox use GTK2-style packing with `PackMode`:
- `PackFixed` (default) — child gets preferred size
- `PackExpand` — claims extra space, centered at preferred size
- `PackFill` — claims extra space and stretches to fill

Container-level `Alignment` (AlignStart/AlignCenter/AlignEnd) positions the entire group of packed children. Cross-axis always fills the container width/height.

### Pony-Specific Patterns

- All cross-actor data is `val` (Cell, Grid, PackOption, etc.)
- `fun ref` methods on traits are uncallable from outside the actor (external refs are `tag`) — used to expose internal state without making fields public
- `recover val/iso` blocks can't access `ref` fields — capture into locals before the block
- `Grid._from()` is package-private (underscore prefix) — use `GridFactory` or `Grid.filled` from outside the package
- Widget identity uses `Any tag` with `is` comparison for actor identity matching
- `DrawingPrimitives` functions are `fun tag` so they work inside `recover` blocks
- Size token parser must validate digit/star patterns — words like "vbox" contain "x" and must not match as sizes

## Conventions

- Pony docstrings: opening and closing `"""` on their own lines
- Commit messages: `feat:`, `refactor:`, `perf:`, `docs:`, `fix:` prefixes
- No Co-Authored-By headers in commits
- `docs/` directory is in `.gitignore` — never commit docs
- Library source files have no prefix; test files start with `_test`
- Type names with `_` prefix are package-private in Pony (e.g. `_WinchNotify`, `_HitTestRequester`)
- Test files: `_test_*.pony`, test classes: `_TestFoo` / `_PropFoo`
- Builder integration tests use mock I/O actors (`_MockOutput`, `_MockInput`) to avoid stdin keeping the runtime alive
