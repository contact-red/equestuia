trait Renderable
  """
  Implement to provide a visual representation.
  """
  fun render(width: USize, height: USize): Grid
    """
    Produce a grid of the given dimensions representing the current state.
    """

trait Updatable[M: Any val]
  """
  Implement to handle typed messages.
  """
  fun ref update(msg: M): Bool
    """
    Handle a message. Return true if the widget should re-render.
    """

trait InputHandler
  """
  Implement to handle key input.
  """
  fun ref handle_key(key: KeyEvent): Bool
    """
    Handle a key event. Return true if consumed (triggers re-render).
    """

trait Focusable
  """
  Implement to react to focus changes.
  """
  fun ref on_focus(): None
    """
    Called when this widget receives focus.
    """
  fun ref on_blur(): None
    """
    Called when this widget loses focus.
    """

trait tag WidgetParent
  """
  Internal trait: anything that can receive a Grid from a child widget.
  Both the Compositor and box containers implement this.
  Widget identity is plain `tag` so both WidgetBase and box containers work.
  """
  be receive_grid(widget: Any tag, grid: Grid)

trait tag Resizable
  """Internal trait for receiving resize notifications."""
  be resize(width: USize, height: USize)

actor WidgetBase is Resizable
  """
  Base actor for all widgets. Handles framework plumbing:
  registration, size management, resize handling, and grid delivery.
  """
  let _parent: WidgetParent tag
  let _renderer: Renderable ref
  var _width: USize
  var _height: USize

  new create(
    parent: WidgetParent tag,
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
    """
    Update the widget's allocated size and re-render.
    """
    _width = width
    _height = height
    _render_and_send()

  be receive_key(key: KeyEvent) =>
    """
    Deliver a key event. If the renderer implements InputHandler and
    consumes the key, triggers a re-render.
    """
    match _renderer
    | let ih: InputHandler =>
      if ih.handle_key(key) then
        _render_and_send()
      end
    end

  be receive_focus() =>
    """
    Notify the widget it has received focus.
    """
    match _renderer
    | let f: Focusable => f.on_focus()
    end
    _render_and_send()

  be receive_blur() =>
    """
    Notify the widget it has lost focus.
    """
    match _renderer
    | let f: Focusable => f.on_blur()
    end
    _render_and_send()

  be trigger_render() =>
    """
    Force a re-render and send to parent.
    """
    _render_and_send()

  fun ref _render_and_send() =>
    let grid = _renderer.render(_width, _height)
    _parent.receive_grid(this, grid)
