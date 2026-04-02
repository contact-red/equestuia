use "collections"

actor Frame is CompositeWidget
  """
  A single-child container that draws a box border around its content.
  Optionally displays a title in the top border:

  ```
  ┌─ Title ──────────────────┐
  │                          │
  └──────────────────────────┘
  ```

  Frame always expands to the maximum size allowed by its parent.
  The child receives the interior dimensions (width - 2, height - 2).
  """
  let _parent: WidgetParent tag
  var _width: USize
  var _height: USize
  var _title: String val
  var _border_color: Color
  var _title_color: Color
  var _child: (Widget tag | None)
  let _child_grids: Array[(Any tag, Grid)]
  var _dirty: Bool = false

  new create(
    p: WidgetParent tag,
    w: USize,
    h: USize,
    title: String val = "",
    border_color: Color = White,
    title_color: Color = BrightWhite)
  =>
    _parent = p
    _width = w
    _height = h
    _title = title
    _border_color = border_color
    _title_color = title_color
    _child = None
    _child_grids = Array[(Any tag, Grid)]

  // -- Widget + CompositeWidget required helpers --

  fun ref parent(): WidgetParent tag => _parent
  fun ref width(): USize => _width
  fun ref height(): USize => _height
  fun ref set_size(w: USize, h: USize) => _width = w; _height = h
  fun ref child_grids(): Array[(Any tag, Grid)] => _child_grids
  fun ref is_dirty(): Bool => _dirty
  fun ref set_dirty(dirty: Bool) => _dirty = dirty

  fun ref render_background(): Grid =>
    """
    Draw the border with optional title.
    """
    let w = _width
    let h = _height
    let title = _title
    let border_color = _border_color
    let title_color = _title_color

    let cells = recover val
      let size = w * h
      let arr = Array[Cell](size)
      for i in Range(0, size) do
        arr.push(Cell.empty())
      end

      if (w >= 2) and (h >= 2) then
        DrawingPrimitives.draw_box(arr, w, h, w, h, border_color)

        // Draw title in top border: ┌─ Title ─────┐
        if title.size() > 0 then
          let max_title = if w > 6 then w - 6 else 0 end
          let title_len = title.size().min(max_title)
          if (title_len > 0) and (w > 5) then
            try arr(2)? = Cell(' ', 1, border_color, Default, 0) end
            for ti in Range(0, title_len) do
              try
                arr(3 + ti)? = Cell(title(ti)?.u32(), 1, title_color, Default, 0)
              end
            end
            try arr(3 + title_len)? = Cell(' ', 1, border_color, Default, 0) end
          end
        end
      end

      arr
    end

    match GridFactory(w, h, cells)
    | let g: Grid => g
    | GridDimensionMismatch => Grid.filled(w, h, Cell.empty())
    end

  // -- Override render: blit child into interior with 1-cell inset --

  fun ref render(): Grid =>
    """
    Draw border background, then blit the child grid into the interior.
    """
    let bg = render_background()
    let w = _width
    let h = _height

    if (w < 3) or (h < 3) or (_child_grids.size() == 0) then
      return bg
    end

    // Get the child's grid (first entry)
    let child_grid = try
      (_, let g) = _child_grids(0)?
      g
    else
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

    // Blit child into interior (inset by 1)
    let inner_w = w - 2
    let inner_h = h - 2
    for crow in Range(0, child_grid.height.min(inner_h)) do
      for ccol in Range(0, child_grid.width.min(inner_w)) do
        match child_grid(ccol, crow)
        | let c: Cell =>
          try cells(((crow + 1) * w) + ccol + 1)? = c end
        end
      end
    end

    let cells_val: Array[Cell] val = consume cells
    match GridFactory(w, h, cells_val)
    | let g: Grid => g
    | GridDimensionMismatch => Grid.filled(w, h, Cell.empty())
    end

  // -- Override resize: resize child to interior dimensions --

  be resize(w: USize, h: USize) =>
    """
    Update frame size and resize the child to the new interior dimensions.
    """
    set_size(w, h)
    match _child
    | let c: Widget tag =>
      if (w >= 2) and (h >= 2) then
        c.resize(w - 2, h - 2)
      end
    end
    render_and_send()

  // -- Container-specific --

  be set_child(widget: Widget tag) =>
    """
    Set the single child widget. Resizes it to the interior dimensions.
    """
    _child = widget
    if (_width >= 2) and (_height >= 2) then
      widget.resize(_width - 2, _height - 2)
    end

  be set_title(title: String val) =>
    """
    Update the frame title and re-render.
    """
    _title = title
    render_and_send()

  be set_border_color(color: Color) =>
    """
    Update the border color and re-render.
    """
    _border_color = color
    render_and_send()
