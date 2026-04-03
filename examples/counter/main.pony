use "../../equestuia"
use "collections"

actor Counter is Widget
  """
  A simple counter widget. Press Up/Down to change the count,
  'q' to quit. Shows focus state with a border color change.
  """
  let _state: WidgetState
  var _count: I64 = 0
  var _focused: Bool = false
  let _env: Env
  let _input: TerminalInput tag

  new create(
    p: WidgetParent tag,
    env: Env,
    input: TerminalInput tag)
  =>
    _state = WidgetState(p)
    _env = env
    _input = input

  // -- Widget required helpers --

  fun ref state(): WidgetState => _state

  fun ref render(): Grid =>
    let w = _state.width
    let h = _state.height
    let label = "Count: " + _count.string()
    let border_color: Color = if _focused then Green else White end
    let text_color: Color = BrightWhite

    let cells = recover val
      let size = w * h
      let arr = Array[Cell](size)
      for i in Range(0, size) do
        arr.push(Cell.empty())
      end

      DrawingPrimitives.draw_box(arr, w, h, w, h, border_color)

      // Label on row 2
      for col in Range(0, label.size().min(w - 2)) do
        try
          arr((2 * w) + col + 1)? =
            Cell(label(col)?.u32(), 1, text_color, Default, 0)
        end
      end

      // Help text on row 4
      let help = "Up/Down  q=quit"
      for col in Range(0, help.size().min(w - 2)) do
        try
          arr((4 * w) + col + 1)? =
            Cell(help(col)?.u32(), 1, Cyan, Default, 0)
        end
      end

      arr
    end

    GridFactory(w, h, cells)

  // -- Override behaviors --

  be receive_key(key: KeyEvent) =>
    match key.key
    | Up =>
      _count = _count + 1
      render_and_send()
    | Down =>
      _count = _count - 1
      render_and_send()
    | CharKey =>
      if key.char == 'q' then
        _env.out.write(AnsiEncoder.clear_screen())
        _env.out.write(AnsiEncoder.move_to(0, 0))
        _env.out.write(AnsiEncoder.reset())
        _env.out.write(AnsiEncoder.show_cursor())
        _input.dispose()
      end
    end

  be receive_focus() =>
    _focused = true
    render_and_send()

  be receive_blur() =>
    _focused = false
    render_and_send()


actor Main
  new create(env: Env) =>
    let output = StdoutOutput(env.out)
    let input = StdinInput(env)

    (let term_w, let term_h) = TermSize()
    let compositor = Compositor(output, term_w, term_h)
    let input_actor = InputActor(input, compositor)

    let builder = UIBuilder(compositor, input_actor)
    builder.register("counter", {(p: WidgetParent tag): Widget tag =>
      Counter(p, env, input)
    } val)

    match builder.build(
"""
vbox
  pack-start *x1
    label "Top of VBox" fg=green
  pack-start *x1
    hline
  pack-start *x4 fill
    hbox
      pack-start 0x4 fill
        frame "Frame 0" border-color=red
          counter #counter0 focusable
      pack-start 0x4 fill
        frame "Frame 1" border-color=red
          counter #counter1 focusable
  pack-start *x1
    hline
  pack-end *x1
    label "Bottom of VBox" fg=red
"""
    )
    | let root: Widget tag =>
      compositor.register_root(root)
      root.resize(term_w, term_h)
    | let e: BuilderError =>
      env.out.print("Builder error: " + e.string())
    end

