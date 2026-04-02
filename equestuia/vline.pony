use "collections"

actor VLine is Widget
  """
  A vertical line widget, one column wide. Fills its height with a
  repeating character (defaults to │). Does not accept focus.
  """
  let _state: WidgetState
  var _char: U32
  var _color: Color

  new create(
    p: WidgetParent tag,
    ch: U32 = 0x2502,
    color: Color = White)
  =>
    _state = WidgetState(p)
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

  fun ref state(): WidgetState => _state

  be resize(w: USize, h: USize) =>
    _state.width = 1
    _state.height = h
    render_and_send()

  fun ref render(): Grid =>
    Grid.filled(1, _state.height, Cell(_char, 1, _color, Default, 0))
