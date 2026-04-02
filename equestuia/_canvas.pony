use "collections"

actor Canvas is CompositeWidget
  """
  An absolute-positioning container. Children are placed at explicit
  (x, y) coordinates with fixed sizes. The user implements
  render_background() for custom drawing; children are composited
  on top in registration order (later on top).

  Children keep their positions when the canvas resizes — they are
  clipped at the canvas bounds.
  """
  let _state: WidgetState
  let _placements: Array[(Any tag, USize, USize, USize, USize)]

  new create(p: WidgetParent tag) =>
    _state = WidgetState(p)
    _placements = Array[(Any tag, USize, USize, USize, USize)]

  // -- Widget + CompositeWidget required helpers --

  fun ref state(): WidgetState => _state

  // -- Override render: composite children at their placed positions --

  fun ref render(): Grid =>
    """
    Render background, then blit each child at its (x, y) position.
    Children are composited in registration order (later on top).
    Clipped at canvas bounds.
    """
    let bg = render_background()
    let w = _state.width
    let h = _state.height

    if _state.child_grids.size() == 0 then
      return bg
    end

    let empty = _state.empty_cell()
    let cells: Array[Cell] iso = recover iso
      let size = w * h
      let arr = Array[Cell](size)
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

    // Blit each child at its placement position
    for pi in Range(0, _placements.size()) do
      try
        (let id, let px, let py, _, _) = _placements(pi)?
        // Find the matching grid
        for gi in Range(0, _state.child_grids.size()) do
          try
            (let gid, let grid) = _state.child_grids(gi)?
            if gid is id then
              for row in Range(0, grid.height) do
                let dest_row = py + row
                if dest_row >= h then break end
                for col in Range(0, grid.width) do
                  let dest_col = px + col
                  if dest_col >= w then break end
                  match grid(col, row)
                  | let c: Cell =>
                    try cells((dest_row * w) + dest_col)? = c end
                  end
                end
              end
              break
            end
          end
        end
      end
    end

    let cells_val: Array[Cell] val = consume cells
    GridFactory(w, h, cells_val)

  // -- Container-specific --

  be add(widget: Widget tag, x: USize, y: USize, w: USize, h: USize) =>
    """
    Place a child widget at (x, y) with the given size. The child is
    resized to (w, h) when the canvas receives its own resize.
    Later-added children draw on top of earlier ones.
    """
    _placements.push((widget, x, y, w, h))
    _state.child_grids.push((widget, Grid.filled(w, h, Cell.empty())))
    widget.resize(w, h)

  be move(widget: Widget tag, x: USize, y: USize) =>
    """
    Reposition a child widget. Size is unchanged.
    """
    for i in Range(0, _placements.size()) do
      try
        (let id, _, _, let pw, let ph) = _placements(i)?
        if id is widget then
          _placements(i)? = (id, x, y, pw, ph)
          render_and_send()
          return
        end
      end
    end

  // -- Override resize: resize children to their fixed sizes --

  be resize(w: USize, h: USize) =>
    """
    Update canvas size and re-render. Children keep their fixed sizes
    and positions — they are clipped at the new bounds.
    """
    _state.width = w
    _state.height = h
    // Resize children to their assigned sizes (not the canvas size)
    for placement in _placements.values() do
      (let id, _, _, let pw, let ph) = placement
      match id
      | let r: Widget tag => r.resize(pw, ph)
      end
    end
    render_and_send()
