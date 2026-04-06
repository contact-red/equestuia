use "collections"

actor Label is Widget
  """
  A text display widget that does not accept focus. Renders a single
  line of text with configurable alignment within the widget's width.
  """
  let _state: WidgetState
  var _text: String val
  var _fg: Color
  var _bg: Color
  var _align: Alignment

  new create(
    p: WidgetParent tag,
    text: String val = "",
    fg: Color = White,
    bg: Color = Default,
    align: Alignment = AlignStart)
  =>
    _state = WidgetState(p)
    _text = text
    _fg = fg
    _bg = bg
    _align = align

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

  be set_fg(fg: Color) =>
    """
    Update foreground color only and re-render.
    """
    _fg = fg
    render_and_send()

  be set_bg(bg: Color) =>
    """
    Update background color only and re-render.
    """
    _bg = bg
    render_and_send()

  be set_align(align: Alignment) =>
    """
    Set text alignment and re-render.
    """
    _align = align
    render_and_send()

  // -- Widget required helpers --

  fun ref state(): WidgetState => _state

  fun ref render(): Grid =>
    let w = _state.width
    let h = _state.height
    let text = _text
    let fg = _fg
    let bg = _bg
    let text_len = text.size().min(w)
    let offset = match _align
    | AlignStart => USize(0)
    | AlignCenter => (w - text_len) / 2
    | AlignEnd => w - text_len
    end

    let empty = _state.empty_cell()
    let cells = recover val
      let size = w * h
      let arr = Array[Cell](size)

      for row in Range(0, h) do
        for col in Range(0, w) do
          let text_col = col - offset
          if (row == 0) and (col >= offset) and (text_col < text_len) then
            try
              arr.push(Cell(text(text_col)?.u32(), 1, fg, bg, 0))
            else
              arr.push(empty)
            end
          else
            arr.push(empty)
          end
        end
      end
      arr
    end

    GridFactory(w, h, cells)
