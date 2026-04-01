trait Renderable
  """Implement to provide a visual representation."""
  fun render(width: USize, height: USize): Grid

trait Updatable[M: Any val]
  """Implement to handle typed messages."""
  fun ref update(msg: M): Bool

trait InputHandler
  """Implement to handle key input."""
  fun ref handle_key(key: KeyEvent): Bool

trait Focusable
  """Implement to react to focus changes."""
  fun ref on_focus(): None
  fun ref on_blur(): None

trait tag _WidgetParent
  """
  Internal trait: anything that can receive a Grid from a child widget.
  Both the Compositor and box containers implement this.
  Widget identity is plain `tag` so both WidgetBase and box containers work.
  """
  be receive_grid(widget: Any tag, grid: Grid)

trait tag _Resizable
  """Internal trait for receiving resize notifications."""
  be resize(width: USize, height: USize)

actor WidgetBase is _Resizable
  """
  Base actor for all widgets. Handles framework plumbing.
  """
  let _parent: _WidgetParent tag
  let _renderer: Renderable ref
  var _width: USize
  var _height: USize

  new create(
    parent: _WidgetParent tag,
    renderer: Renderable iso,
    width: USize,
    height: USize)
  =>
    """
    Create the widget. The widget does not render immediately on construction.
    The expected flow is: create widget, register with Compositor via
    `compositor.register(widget, viewport)`, then call `widget.trigger_render()`
    to produce the first frame.
    """
    _parent = parent
    _renderer = consume renderer
    _width = width
    _height = height

  be resize(width: USize, height: USize) =>
    _width = width
    _height = height
    _render_and_send()

  be receive_key(key: KeyEvent) =>
    match _renderer
    | let ih: InputHandler =>
      if ih.handle_key(key) then
        _render_and_send()
      end
    end

  be receive_focus() =>
    match _renderer
    | let f: Focusable => f.on_focus()
    end
    _render_and_send()

  be receive_blur() =>
    match _renderer
    | let f: Focusable => f.on_blur()
    end
    _render_and_send()

  be trigger_render() =>
    """Force a re-render and send to parent."""
    _render_and_send()

  fun ref _render_and_send() =>
    let grid = _renderer.render(_width, _height)
    _parent.receive_grid(this, grid)
