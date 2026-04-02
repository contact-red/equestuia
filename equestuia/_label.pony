use "collections"

actor Label is Widget
  """
  A text display widget that does not accept focus. Renders a single
  line of text, truncated to the widget's width.
  """
  let _state: WidgetState
  var _text: String val
  var _fg: Color
  var _bg: Color

  new create(
    p: WidgetParent tag,
    text: String val = "",
    fg: Color = White,
    bg: Color = Default)
  =>
    _state = WidgetState(p)
    _text = text
    _fg = fg
    _bg = bg

  be set_text(text: String val) =>
    """
    Update the label text and re-render.
    """
    _text = text
    render_and_send()

  be set_color(fg: Color, bg: Color = Default) =>
    """
    Update the label colors and re-render.
    """
    _fg = fg
    _bg = bg
    render_and_send()

  // -- Widget required helpers --

  fun ref state(): WidgetState => _state

  fun ref render(): Grid =>
    let w = _state.width
    let h = _state.height
    let text = _text
    let fg = _fg
    let bg = _bg

    let cells = recover val
      let size = w * h
      let arr = Array[Cell](size)
      let text_len = text.size().min(w)

      for row in Range(0, h) do
        for col in Range(0, w) do
          if (row == 0) and (col < text_len) then
            try
              arr.push(Cell(text(col)?.u32(), 1, fg, bg, 0))
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

    match GridFactory(w, h, cells)
    | let g: Grid => g
    | GridDimensionMismatch => Grid.filled(w, h, Cell.empty())
    end
