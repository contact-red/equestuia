use "collections"

actor VLine is Widget
  """
  A vertical line widget, one column wide. Fills its height with a
  repeating character (defaults to │). Does not accept focus.
  """
  let _parent: WidgetParent tag
  var _width: USize
  var _height: USize
  var _char: U32
  var _color: Color

  new create(
    p: WidgetParent tag,
    h: USize,
    ch: U32 = 0x2502,
    color: Color = White)
  =>
    _parent = p
    _width = 1
    _height = h
    _char = ch
    _color = color

  be set_char(ch: U32) =>
    """
    Change the line character and re-render.
    """
    _char = ch
    render_and_send()

  be set_color(color: Color) =>
    """
    Change the line color and re-render.
    """
    _color = color
    render_and_send()

  // -- Widget required helpers --

  fun ref parent(): WidgetParent tag => _parent
  fun ref width(): USize => _width
  fun ref height(): USize => _height
  fun ref set_size(w: USize, h: USize) => _width = 1; _height = h

  fun ref render(): Grid =>
    let h = _height
    let ch = _char
    let color = _color
    Grid.filled(1, h, Cell(ch, 1, color, Default, 0))
