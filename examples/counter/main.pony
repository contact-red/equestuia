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

      for row in Range(0, _height) do
        for col in Range(0, _width) do
          let is_top = (row == 0)
          let is_bottom = (row == (_height - 1))
          let is_left = (col == 0)
          let is_right = (col == (_width - 1))

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
