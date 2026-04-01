trait tag WidgetParent
  """
  Anything that can receive a Grid from a child widget.
  Both the Compositor and box containers implement this.
  """
  be receive_grid(widget: Any tag, grid: Grid)

trait tag Widget
  """
  Base trait for all widget actors. Users implement their own actors
  with this trait. Required helpers provide access to widget state;
  default behavior implementations handle common patterns.

  The required fun ref methods are uncallable from outside the actor
  because external references are always `tag` capability.
  """

  // -- Required: user must implement these --

  fun ref render(): Grid
    """
    Produce a grid representing the current widget state.
    """

  fun ref parent(): WidgetParent tag
    """
    Return the parent that receives this widget's grids.
    """

  fun ref width(): USize
    """
    Return the current allocated width.
    """

  fun ref height(): USize
    """
    Return the current allocated height.
    """

  fun ref set_size(w: USize, h: USize)
    """
    Store the new allocated dimensions.
    """

  // -- Provided: default implementations using the required helpers --

  fun ref render_and_send() =>
    """
    Render the widget and send the grid to the parent.
    """
    parent().receive_grid(this, render())

  be resize(w: USize, h: USize) =>
    """
    Update allocated size and re-render.
    """
    set_size(w, h)
    render_and_send()

  be trigger_render() =>
    """
    Force a re-render and send to parent.
    """
    render_and_send()

  be receive_key(key: KeyEvent) =>
    """
    Handle a key event. Default: ignore.
    """
    None

  be receive_focus() =>
    """
    Called when this widget receives focus. Default: re-render.
    """
    render_and_send()

  be receive_blur() =>
    """
    Called when this widget loses focus. Default: re-render.
    """
    render_and_send()
