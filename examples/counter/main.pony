use "../../equestuia"
use "collections"

actor Counter is Widget
  """
  A simple counter widget. Press Up/Down to change the count,
  'q' to quit. Shows focus state with a border color change.
  """
  let _parent: WidgetParent tag
  var _width: USize
  var _height: USize
  var _count: I64 = 0
  var _focused: Bool = false
  let _env: Env
  let _input: TerminalInput tag

  new create(
    p: WidgetParent tag,
    w: USize,
    h: USize,
    env: Env,
    input: TerminalInput tag)
  =>
    _parent = p
    _width = w
    _height = h
    _env = env
    _input = input

  // -- Widget required helpers --

  fun ref parent(): WidgetParent tag => _parent
  fun ref width(): USize => _width
  fun ref height(): USize => _height
  fun ref set_size(w: USize, h: USize) => _width = w; _height = h

  fun ref render(): Grid =>
    let label = "Count: " + _count.string()
    let border_color: Color = if _focused then Green else White end
    let text_color: Color = BrightWhite

    let cells = recover val
      let size = _width * _height
      let arr = Array[Cell](size)
      for i in Range(0, size) do
        arr.push(Cell.empty())
      end

      DrawingPrimitives.draw_box(arr, _width, _height, _width, _height, border_color)

      // Label on row 2
      for col in Range(0, label.size().min(_width - 2)) do
        try
          arr((2 * _width) + col + 1)? =
            Cell(label(col)?.u32(), 1, text_color, Default, 0)
        end
      end

      // Help text on row 4
      let help = "Up/Down  q=quit"
      for col in Range(0, help.size().min(_width - 2)) do
        try
          arr((4 * _width) + col + 1)? =
            Cell(help(col)?.u32(), 1, Cyan, Default, 0)
        end
      end

      arr
    end

    match GridFactory(_width, _height, cells)
    | let g: Grid => g
    | GridDimensionMismatch => Grid.filled(_width, _height, Cell.empty())
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

    let counter = Counter(compositor, 20, 7, env, input)

    let viewport = ViewPort(Center, 20, 7)
    compositor.register(counter, viewport)
    input_actor.register_focusable(counter)
    counter.trigger_render()

