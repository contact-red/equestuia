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

    match GridFactory(w, h, cells)
    | let g: Grid => g
    | GridDimensionMismatch => Grid.filled(w, h, Cell.empty())
    end

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


    // VBox fills the full terminal
    let vbox = VBox(compositor)
    input_actor.register_widget(vbox)

    // Top label
    let top_label = Label(vbox, "Top of VBox", Green)
    vbox.pack_start(top_label, term_w, 1)

    let hline0 = HLine(vbox)
    let hline1 = HLine(vbox)
    vbox.pack_start(hline0, term_w, 1)

    let hbox = HBox(vbox)
    vbox.pack_start(hbox, term_w, 4, PackOption(PackFill))

    // Counter Frame 0
    let frame0 = Frame(hbox, "Frame 0", Red)
    hbox.pack_start(frame0, term_w / 2, 4, PackOption(PackFill))

    // Counter inside the frame 0
    let counter0 = Counter(frame0, env, input)
    frame0.set_child(counter0)
    input_actor.register_focusable(counter0)

    // Counter Frame 1
    let frame1 = Frame(hbox, "Frame 1", Red)
    hbox.pack_start(frame1, term_w / 2, 4, PackOption(PackFill))

    // Counter inside the frame 1
    let counter1 = Counter(frame1, env, input)
    frame1.set_child(counter1)
    input_actor.register_focusable(counter1)

    // Bottom label
    vbox.pack_start(hline1, term_w, 1)
    let bottom_label = Label(vbox, "Bottom of VBox", Red)
    vbox.pack_end(bottom_label, term_w, 1)

    // Register root and kick off layout — must be after all children are added
    compositor.set_root(vbox)

