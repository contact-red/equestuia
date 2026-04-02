use "collections"

actor HLine is Widget
  """
  A horizontal line widget, one row tall. Fills its width with a
  repeating character (defaults to ─). Does not accept focus.
  """
  let _state: WidgetState
  var _char: U32
  var _color: Color

  new create(
    p: WidgetParent tag,
    ch: U32 = 0x2500,
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
    _state.width = w
    _state.height = 1
    render_and_send()

  fun ref render(): Grid =>
    Grid.filled(_state.width, 1, Cell(_char, 1, _color, Default, 0))
