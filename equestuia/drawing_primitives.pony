use "collections"

primitive DrawingPrimitives
  """
  Utility functions for drawing common shapes into cell arrays.
  All functions are `tag` so they can be called inside `recover` blocks.
  """
  fun draw_box(
    cells: Array[Cell] ref,
    grid_width: USize,
    grid_height: USize,
    box_width: USize,
    box_height: USize,
    color: Color = White)
  =>
    """
    Draw a single-line box border into a cell array. The box is placed at
    the top-left of the grid. grid_width is the row stride for indexing.
    """
    let bw = box_width.min(grid_width)
    let bh = box_height.min(grid_height)
    if (bw < 2) or (bh < 2) then return end

    for row in Range(0, bh) do
      for col in Range(0, bw) do
        let is_top = (row == 0)
        let is_bottom = (row == (bh - 1))
        let is_left = (col == 0)
        let is_right = (col == (bw - 1))
        let on_border = is_top or is_bottom or is_left or is_right

        if on_border then
          let ch: U32 =
            if is_top and is_left then 0x250C       // ┌
            elseif is_top and is_right then 0x2510   // ┐
            elseif is_bottom and is_left then 0x2514 // └
            elseif is_bottom and is_right then 0x2518 // ┘
            elseif is_top or is_bottom then 0x2500   // ─
            else 0x2502                              // │
            end
          try
            cells((row * grid_width) + col)? = Cell(ch, 1, color, Default, 0)
          end
        end
      end
    end
