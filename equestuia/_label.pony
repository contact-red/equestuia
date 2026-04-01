use "collections"

actor Label is Widget
  """
  A text display widget that does not accept focus. Renders a single
  line of text, truncated to the widget's width.
  """
  let _parent: WidgetParent tag
  var _width: USize
  var _height: USize
  var _text: String val
  var _fg: Color
  var _bg: Color

  new create(
    p: WidgetParent tag,
    w: USize,
    h: USize,
    text: String val = "",
    fg: Color = White,
    bg: Color = Default)
  =>
    _parent = p
    _width = w
    _height = h
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

  fun ref parent(): WidgetParent tag => _parent
  fun ref width(): USize => _width
  fun ref height(): USize => _height
  fun ref set_size(w: USize, h: USize) => _width = w; _height = h

  fun ref render(): Grid =>
    let cells = recover val
      let size = _width * _height
      let arr = Array[Cell](size)
      let text_len = _text.size().min(_width)

      for row in Range(0, _height) do
        for col in Range(0, _width) do
          if (row == 0) and (col < text_len) then
            try
              arr.push(Cell(_text(col)?.u32(), 1, _fg, _bg, 0))
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
