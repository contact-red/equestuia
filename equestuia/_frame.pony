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
  let _state: WidgetState
  var _title: String val
  var _border_color: Color
  var _title_color: Color
  var _child: (Widget tag | None)

  new create(
    p: WidgetParent tag,
    title: String val = "",
    border_color: Color = White,
    title_color: Color = BrightWhite)
  =>
    _state = WidgetState(p)
    _title = title
    _border_color = border_color
    _title_color = title_color
    _child = None

  // -- Widget + CompositeWidget required helpers --

  fun ref state(): WidgetState => _state

  fun ref render_background(): Grid =>
    """
    Draw the border with optional title.
    """
    let w = _state.width
    let h = _state.height
    let title = _title
    let border_color = _border_color
    let title_color = _title_color

    let empty = _state.empty_cell()
    let cells = recover val
      let size = w * h
      let arr = Array[Cell](size)
      for i in Range(0, size) do
        arr.push(empty)
      end

      if (w >= 2) and (h >= 2) then
        DrawingPrimitives.draw_box(arr, w, h, w, h, border_color)

        // Draw title in top border: ┌─ Title ─────┐
        if title.size() > 0 then
          // 6 = 3 chars before title (┌─ ) + 3 chars after ( ─┐)
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

    GridFactory(w, h, cells)

  // -- Override render: blit child into interior with 1-cell inset --

  fun ref render(): Grid =>
    """
    Draw border background, then blit the child grid into the interior.
    """
    let bg = render_background()
    let w = _state.width
    let h = _state.height

    if (w < 3) or (h < 3) or (_state.child_grids.size() == 0) then
      return bg
    end

    // Get the child's grid (first entry)
    let child_grid = try
      (_, let g) = _state.child_grids(0)?
      g
    else
      return bg
    end

    let empty = _state.empty_cell()
    let cells: Array[Cell] iso = recover iso
      let size = w * h
      let arr = Array[Cell](size)
      // Copy background
      for row in Range(0, h) do
        for col in Range(0, w) do
          match bg(col, row)
          | let c: Cell => arr.push(c)
          | GridCellOutOfBounds => arr.push(empty)
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
    GridFactory(w, h, cells_val)

  // -- Override resize: resize child to interior dimensions --

  be resize(w: USize, h: USize) =>
    """
    Update frame size and resize the child to the new interior dimensions.
    """
    _state.width = w
    _state.height = h
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
    Set the single child widget. The child will be resized when the
    frame's own resize arrives from its parent.
    """
    _child = widget
    _state.child_grids.push((widget, Grid.filled(0, 0, Cell.empty())))

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
