use "collections"

actor Frame is (Widget & WidgetParent)
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
  var _child_grid: Grid

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
    _child_grid = Grid.filled(0, 0, Cell.empty())

  // -- Widget required helpers --

  fun ref parent(): WidgetParent tag => _parent
  fun ref width(): USize => _width
  fun ref height(): USize => _height
  fun ref set_size(w: USize, h: USize) => _width = w; _height = h

  fun ref render(): Grid =>
    let w = _width
    let h = _height
    let title = _title
    let border_color = _border_color
    let title_color = _title_color
    let child_grid = _child_grid

    let cells = recover val
      let size = w * h
      let arr = Array[Cell](size)
      for i in Range(0, size) do
        arr.push(Cell.empty())
      end

      if (w >= 2) and (h >= 2) then
        // Draw border
        for row in Range(0, h) do
          for col in Range(0, w) do
            let is_top = (row == 0)
            let is_bottom = (row == (h - 1))
            let is_left = (col == 0)
            let is_right = (col == (w - 1))

            if is_top or is_bottom or is_left or is_right then
              let ch: U32 =
                if is_top and is_left then 0x250C       // ┌
                elseif is_top and is_right then 0x2510   // ┐
                elseif is_bottom and is_left then 0x2514 // └
                elseif is_bottom and is_right then 0x2518 // ┘
                elseif is_top or is_bottom then 0x2500   // ─
                else 0x2502                              // │
                end
              try arr(((row * w) + col))? = Cell(ch, 1, border_color, Default, 0) end
            end
          end
        end

        // Draw title in top border: ┌─ Title ─────┐
        if title.size() > 0 then
          // "─ " before title starts at col 1
          let max_title = if w > 6 then w - 6 else 0 end
          let title_len = title.size().min(max_title)
          if (title_len > 0) and (w > 5) then
            // col 1 is already ─, col 2 = space
            try arr(2)? = Cell(' ', 1, border_color, Default, 0) end
            // title chars starting at col 3
            for ti in Range(0, title_len) do
              try
                arr(3 + ti)? = Cell(title(ti)?.u32(), 1, title_color, Default, 0)
              end
            end
            // space after title
            try arr(3 + title_len)? = Cell(' ', 1, border_color, Default, 0) end
            // remaining cols are already ─ from border drawing
          end
        end

        // Blit child grid into interior
        let inner_w = w - 2
        let inner_h = h - 2
        for crow in Range(0, child_grid.height.min(inner_h)) do
          for ccol in Range(0, child_grid.width.min(inner_w)) do
            match child_grid(ccol, crow)
            | let c: Cell =>
              try arr(((crow + 1) * w) + ccol + 1)? = c end
            end
          end
        end
      end

      arr
    end

    match GridFactory(w, h, cells)
    | let g: Grid => g
    | GridDimensionMismatch => Grid.filled(w, h, Cell.empty())
    end

  // -- Override resize to resize child --

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

  // -- WidgetParent --

  be receive_grid(widget: Any tag, grid: Grid) =>
    """
    Receive the child's grid and re-render.
    """
    _child_grid = grid
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
