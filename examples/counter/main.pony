use "../../equestuia"
use "collections"

class ref CounterRenderer is (Renderable & InputHandler & Focusable)
  """
  A simple counter widget. Press Up/Down to change the count,
  'q' to quit. Shows focus state with a border color change.
  """
  var _count: I64 = 0
  var _focused: Bool = false
  let _env: Env
  let _input: TerminalInput tag

  new ref create(env: Env, input: TerminalInput tag) =>
    _env = env
    _input = input

  fun render(width: USize, height: USize): Grid =>
    let label = "Count: " + _count.string()
    let border_color: Color = if _focused then Green else White end
    let text_color: Color = BrightWhite

    let cells = recover val
      let size = width * height
      let arr = Array[Cell](size)

      for row in Range(0, height) do
        for col in Range(0, width) do
          let is_top = (row == 0)
          let is_bottom = (row == (height - 1))
          let is_left = (col == 0)
          let is_right = (col == (width - 1))

          if is_top and is_left then
            arr.push(Cell(0x250C, 1, border_color, Default, 0)) // ┌
          elseif is_top and is_right then
            arr.push(Cell(0x2510, 1, border_color, Default, 0)) // ┐
          elseif is_bottom and is_left then
            arr.push(Cell(0x2514, 1, border_color, Default, 0)) // └
          elseif is_bottom and is_right then
            arr.push(Cell(0x2518, 1, border_color, Default, 0)) // ┘
          elseif is_top or is_bottom then
            arr.push(Cell(0x2500, 1, border_color, Default, 0)) // ─
          elseif is_left or is_right then
            arr.push(Cell(0x2502, 1, border_color, Default, 0)) // │
          elseif (row == 2) and ((col - 1) < label.size()) then
            try
              arr.push(Cell(label(col - 1)?.u32(), 1, text_color, Default, 0))
            else
              arr.push(Cell.empty())
            end
          elseif (row == 4) and (col >= 1) and (col <= 16) then
            let help = "Up/Down  q=quit"
            let idx = col - 1
            if idx < help.size() then
              try
                arr.push(Cell(help(idx)?.u32(), 1, Cyan, Default, 0))
              else
                arr.push(Cell.empty())
              end
            else
              arr.push(Cell.empty())
            end
          else
            arr.push(Cell.empty())
          end
        end
      end
      arr
    end

    match GridFactory(width, height, cells)
    | let g: Grid => g
    | GridDimensionMismatch => Grid.filled(width, height, Cell.empty())
    end

  fun ref handle_key(key: KeyEvent): Bool =>
    match key.key
    | Up =>
      _count = _count + 1
      true
    | Down =>
      _count = _count - 1
      true
    | CharKey =>
      if key.char == 'q' then
        // Restore terminal and shut down cleanly
        _env.out.write(AnsiEncoder.clear_screen())
        _env.out.write(AnsiEncoder.move_to(0, 0))
        _env.out.write(AnsiEncoder.reset())
        _env.out.write(AnsiEncoder.show_cursor())
        _input.dispose()
        false
      else
        false
      end
    else
      false
    end

  fun ref on_focus(): None =>
    _focused = true

  fun ref on_blur(): None =>
    _focused = false


actor Main
  new create(env: Env) =>
    // Set up terminal I/O
    let output = StdoutOutput(env.out)
    let input = StdinInput(env)

    // Query actual terminal size
    (let term_w, let term_h) = TermSize()
    let compositor = Compositor(output, term_w, term_h)

    // Create input actor
    let input_actor = InputActor(input, compositor)

    // Create the counter widget
    let renderer: CounterRenderer iso = recover iso CounterRenderer(env, input) end
    let widget = WidgetBase(compositor, consume renderer, 20, 7)

    // Register with compositor (centered on screen)
    let viewport = ViewPort(Center, 20, 7)
    compositor.register(widget, viewport)

    // Register for focus and input
    input_actor.register_focusable(widget)

    // Trigger first render
    widget.trigger_render()
