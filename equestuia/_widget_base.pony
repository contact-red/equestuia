use "collections"

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

trait tag CompositeWidget is (Widget & WidgetParent)
  """
  A widget that contains child widgets. Extends Widget with child grid
  storage, compositing, and resize propagation.

  The user implements `render_background()` for their own content and
  `child_grids()` to expose the storage field. The trait handles
  `receive_grid`, `resize` with child propagation, and composites
  children on top of the background in `render`.

  Typical usage:

  ```
  actor MyWidget is CompositeWidget
    let _parent: WidgetParent tag
    var _width: USize
    var _height: USize
    let _child_grids: Array[(Any tag, Grid)]

    new create(p: WidgetParent tag, w: USize, h: USize) =>
      _parent = p
      _width = w
      _height = h
      _child_grids = Array[(Any tag, Grid)]

    // Widget helpers
    fun ref parent(): WidgetParent tag => _parent
    fun ref width(): USize => _width
    fun ref height(): USize => _height
    fun ref set_size(w: USize, h: USize) => _width = w; _height = h
    fun ref child_grids(): Array[(Any tag, Grid)] => _child_grids

    fun ref render_background(): Grid =>
      Grid.filled(width(), height(), Cell.empty())
  ```
  """

  // -- Required: user must implement --

  fun ref render_background(): Grid
    """
    Produce the background grid before children are composited on top.
    Return an empty grid if there is no background.
    """

  fun ref child_grids(): Array[(Any tag, Grid)]
    """
    Return the child grid storage array (backed by a field on the actor).
    """

  // -- Provided: compositing render --

  fun ref render(): Grid =>
    """
    Render background, then overlay all child grids on top.
    Non-empty cells from children overwrite the background.
    """
    let bg = render_background()
    let w = width()
    let h = height()
    let grids = child_grids()

    if grids.size() == 0 then
      return bg
    end

    let cells: Array[Cell] iso = recover iso
      let size = w * h
      let arr = Array[Cell](size)
      // Copy background
      for row in Range(0, h) do
        for col in Range(0, w) do
          match bg(col, row)
          | let c: Cell => arr.push(c)
          | GridCellOutOfBounds => arr.push(Cell.empty())
          end
        end
      end
      arr
    end

    // Blit child grids on top
    for child in grids.values() do
      (_, let grid) = child
      for row in Range(0, grid.height.min(h)) do
        for col in Range(0, grid.width.min(w)) do
          match grid(col, row)
          | let c: Cell =>
            if (c.char != ' ') or (c.attrs != 0) then
              try cells((row * w) + col)? = c end
            end
          end
        end
      end
    end

    let cells_val: Array[Cell] val = consume cells
    match GridFactory(w, h, cells_val)
    | let g: Grid => g
    | GridDimensionMismatch => Grid.filled(w, h, Cell.empty())
    end

  // -- Provided: child management --

  be receive_grid(widget: Any tag, grid: Grid) =>
    """
    Receive a child's grid, store it, and re-render.
    """
    let grids = child_grids()
    var found = false
    for i in Range(0, grids.size()) do
      try
        (let w, _) = grids(i)?
        if w is widget then
          grids(i)? = (w, grid)
          found = true
          break
        end
      end
    end
    if not found then
      grids.push((widget, grid))
    end
    render_and_send()

  be resize(w: USize, h: USize) =>
    """
    Update size, propagate resize to all children, and re-render.
    """
    set_size(w, h)
    for child in child_grids().values() do
      (let cw, _) = child
      match cw
      | let r: Widget tag => r.resize(w, h)
      end
    end
    render_and_send()
