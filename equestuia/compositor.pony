use "collections"

trait tag _HitTestRequester
  be hit_test_result(widget: (Any tag | None))

actor Compositor is WidgetParent
  """
  Receives grids from widget-actors, composites by z-order,
  diffs against previous frame, and writes ANSI output.
  """
  let _output: TerminalOutput tag
  var _screen_width: USize
  var _screen_height: USize
  var _prev_frame: Grid
  // Registered widgets: identity, viewport, latest grid.
  // Order in array is registration order; z_order is in ViewPort.
  var _widgets: Array[(Any tag, ViewPort, Grid)]
  var _dirty: Bool = false

  new create(output: TerminalOutput tag, width: USize, height: USize) =>
    _output = output
    _screen_width = width
    _screen_height = height
    _prev_frame = Grid.filled(width, height, Cell.empty())
    _widgets = Array[(Any tag, ViewPort, Grid)]
    // Send initial clear screen + hide cursor
    let init = recover iso
      let buf = Array[U8]
      for b in AnsiEncoder.clear_screen().values() do buf.push(b) end
      for b in AnsiEncoder.hide_cursor().values() do buf.push(b) end
      buf
    end
    _output.write(consume init)

  be register_root(widget: Widget tag) =>
    """
    Register the root widget at NorthWest filling the full screen.
    Does not send a resize — the caller must send resize() to the
    widget directly to ensure correct message ordering.
    """
    let viewport = ViewPort(NorthWest, _screen_width, _screen_height)
    _widgets.push((widget, viewport,
      Grid.filled(_screen_width, _screen_height, Cell.empty())))

  be receive_grid(widget: Any tag, grid: Grid) =>
    """
    Receive an updated grid from a widget. Stores the grid and schedules
    a deferred recompose if not already pending.
    """
    try
      let idx = _find_widget(widget)?
      (let w, let vp, _) = _widgets(idx)?
      _widgets(idx)? = (w, vp, grid)
      if not _dirty then
        _dirty = true
        _deferred_compose()
      end
    end

  be _deferred_compose() =>
    """
    Runs after all queued receive_grid messages have been processed.
    Performs one compose-and-render pass.
    """
    _dirty = false
    _compose_and_render()

  be hit_test(col: USize, row: USize, requester: _HitTestRequester tag) =>
    """
    Find the topmost widget at the given screen coordinate and send the
    result back to the requester.
    """
    // Walk widgets in reverse z-order (highest first) to find topmost
    let sorted = _sorted_indices()
    var i = sorted.size()
    while i > 0 do
      i = i - 1
      try
        let idx = sorted(i)?
        (let w, let vp, let g) = _widgets(idx)?
        (let ax, let ay) = _resolve_position(vp, g.width, g.height)
        if (col >= ax) and (col < (ax + g.width))
          and (row >= ay) and (row < (ay + g.height))
        then
          requester.hit_test_result(w)
          return
        end
      end
    end
    requester.hit_test_result(None)

  be screen_resize(width: USize, height: USize) =>
    """
    Handle terminal resize: update dimensions, clear screen, and recompose.
    """
    _screen_width = width
    _screen_height = height
    _prev_frame = Grid.filled(width, height, Cell.empty())
    let clear = recover iso
      let buf = Array[U8]
      for b in AnsiEncoder.clear_screen().values() do buf.push(b) end
      buf
    end
    _output.write(consume clear)
    _compose_and_render()

  fun ref _compose_and_render() =>
    let sw = _screen_width
    let sh = _screen_height

    // 1. Pre-extract resolved positions and grids in z-order.
    let sorted = _sorted_indices()
    let layers_iso: Array[(USize, USize, Grid)] iso =
      recover iso Array[(USize, USize, Grid)] end
    for sort_i in Range(0, sorted.size()) do
      try
        let idx = sorted(sort_i)?
        (_, let vp, let g) = _widgets(idx)?
        (let ax, let ay) = _resolve_position(vp, g.width, g.height)
        layers_iso.push((ax, ay, g))
      end
    end
    let layers: Array[(USize, USize, Grid)] val = consume layers_iso

    // 2. Build frame buffer. All inputs to this block are val or sendable.
    let cells_val: Array[Cell] val = recover val
      let size = sw * sh
      let cells = Array[Cell](size)
      let empty = Cell.empty()
      for i in Range(0, size) do
        cells.push(empty)
      end

      for layer in layers.values() do
        (let ax, let ay, let g) = layer

        for grow in Range(0, g.height) do
          let screen_row = ay + grow
          if screen_row >= sh then break end

          for gcol in Range(0, g.width) do
            let screen_col = ax + gcol
            if screen_col >= sw then break end

            match g(gcol, grow)
            | let cell: Cell =>
              // Wide char clipping: if a wide char would extend past right edge,
              // replace with a space
              if (cell.width == 2) and ((screen_col + 1) >= sw) then
                try cells((screen_row * sw) + screen_col)? = Cell.empty() end
              else
                try cells((screen_row * sw) + screen_col)? = cell end
              end
            end
          end
        end
      end
      cells
    end

    let curr_frame = GridFactory(sw, sh, cells_val)

    // 3. Diff current vs previous
    let changes = Differ.diff(_prev_frame, curr_frame)

    // 4. Render changes as ANSI output
    if changes.size() > 0 then
      let output = recover iso
        let buf = Array[U8]
        for change in changes.values() do
          (let col, let row, let cell) = change
          for b in AnsiEncoder.move_to(col, row).values() do buf.push(b) end
          for b in AnsiEncoder.reset().values() do buf.push(b) end
          if cell.attrs != 0 then
            for b in AnsiEncoder.set_attrs(cell.attrs).values() do buf.push(b) end
          end
          for b in AnsiEncoder.set_fg(cell.fg).values() do buf.push(b) end
          for b in AnsiEncoder.set_bg(cell.bg).values() do buf.push(b) end
          for b in AnsiEncoder.write_char(cell.char).values() do buf.push(b) end
        end
        buf
      end
      _output.write(consume output)
    end

    // 5. Current frame becomes previous
    _prev_frame = curr_frame

  fun _find_widget(widget: Any tag): USize ? =>
    """Find widget index by identity. Raises error if not found."""
    for i in Range(0, _widgets.size()) do
      try
        (let w, _, _) = _widgets(i)?
        if w is widget then return i end
      end
    end
    error

  fun _sorted_indices(): Array[USize] =>
    """Return widget indices sorted by z_order ascending (insertion sort)."""
    let indices = Array[USize](_widgets.size())
    for idx in Range(0, _widgets.size()) do
      indices.push(idx)
    end
    // Insertion sort by z_order
    var i: USize = 1
    while i < indices.size() do
      try
        let key_idx = indices(i)?
        (_, let key_vp, _) = _widgets(key_idx)?
        let key_z = key_vp.z_order
        var j = i
        while j > 0 do
          let prev_idx = indices(j - 1)?
          (_, let prev_vp, _) = _widgets(prev_idx)?
          if prev_vp.z_order <= key_z then break end
          indices(j)? = prev_idx
          j = j - 1
        end
        indices(j)? = key_idx
      end
      i = i + 1
    end
    indices

  fun _resolve_position(vp: ViewPort, widget_width: USize, widget_height: USize): (USize, USize) =>
    """Map anchor + offset to absolute screen coordinates."""
    (let base_x: ISize, let base_y: ISize) = match vp.anchor
    | North =>
      (_center_h(widget_width), ISize(0))
    | NorthEast =>
      (_right_edge(widget_width), ISize(0))
    | East =>
      (_right_edge(widget_width), _center_v(widget_height))
    | SouthEast =>
      (_right_edge(widget_width), _bottom_edge(widget_height))
    | South =>
      (_center_h(widget_width), _bottom_edge(widget_height))
    | SouthWest =>
      (ISize(0), _bottom_edge(widget_height))
    | West =>
      (ISize(0), _center_v(widget_height))
    | NorthWest =>
      (ISize(0), ISize(0))
    | Center =>
      (_center_h(widget_width), _center_v(widget_height))
    end

    let rx = base_x + vp.offset_x
    let ry = base_y + vp.offset_y
    let x: USize = if rx < 0 then USize(0) else rx.usize() end
    let y: USize = if ry < 0 then USize(0) else ry.usize() end
    (x, y)

  fun _center_h(widget_width: USize): ISize =>
    if _screen_width >= widget_width then
      ISize.from[USize]((_screen_width - widget_width) / 2)
    else
      ISize(0)
    end

  fun _center_v(widget_height: USize): ISize =>
    if _screen_height >= widget_height then
      ISize.from[USize]((_screen_height - widget_height) / 2)
    else
      ISize(0)
    end

  fun _right_edge(widget_width: USize): ISize =>
    if _screen_width >= widget_width then
      ISize.from[USize](_screen_width - widget_width)
    else
      ISize(0)
    end

  fun _bottom_edge(widget_height: USize): ISize =>
    if _screen_height >= widget_height then
      ISize.from[USize](_screen_height - widget_height)
    else
      ISize(0)
    end
