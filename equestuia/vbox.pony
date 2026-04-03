use "collections"

actor VBox is CompositeWidget
  """
  Vertical box container. Packs children top-to-bottom using
  GTK2-style expand/fill/padding semantics.
  """
  let _state: WidgetState
  let _children: Array[(Any tag, USize, USize, PackOption, Bool)]
  var _align: Alignment = AlignStart

  new create(p: WidgetParent tag, align: Alignment = AlignStart) =>
    _state = WidgetState(p)
    _children = Array[(Any tag, USize, USize, PackOption, Bool)]
    _align = align

  // -- Widget + CompositeWidget required helpers --

  fun ref state(): WidgetState => _state

  // -- Override render: position children using packer allocations --

  fun ref render(): Grid =>
    """
    Compose all child grids into a single grid using packer allocations.
    When debug_bg is Rainbow, each allocation region gets a distinct
    background color from a cycling palette, making expand vs fill visible.
    """
    let w = _state.width
    let h = _state.height
    let allocs = Packer.pack(Vertical, w, h, _pack_params(), _align)

    let empty = _state.empty_cell()
    let is_rainbow = match _state.debug_bg | let _: Rainbow => true else false end
    let combined: Array[Cell] iso =
      recover iso
        let size = w * h
        let cells = Array[Cell](size)
        for j in Range(0, size) do
          cells.push(empty)
        end
        cells
      end

    for i in Range(0, allocs.size()) do
      try
        let alloc = allocs(i)?

        // Fill slot region with per-slot color when rainbow
        if is_rainbow then
          let slot_cell = Cell(' ', 1, Default, _RainbowPalette(i), 0)
          for row in Range(0, alloc.slot_height) do
            for col in Range(0, alloc.slot_width.min(w)) do
              let dest_col = alloc.slot_x + col
              let dest_row = alloc.slot_y + row
              if (dest_col < w) and (dest_row < h) then
                combined((dest_row * w) + dest_col)? = slot_cell
              end
            end
          end
        end

        // Composite child grid on top
        if i < _state.child_grids.size() then
          (_, let grid) = _state.child_grids(i)?
          for row in Range(0, grid.height.min(alloc.height)) do
            for col in Range(0, grid.width.min(alloc.width)) do
              let dest_col = alloc.x + col
              let dest_row = alloc.y + row
              if (dest_col < w) and (dest_row < h) then
                match grid(col, row)
                | let c: Cell =>
                  combined((dest_row * w) + dest_col)? = c
                end
              end
            end
          end
        end
      end
    end

    let cells_val: Array[Cell] val = consume combined
    Grid._from(w, h, cells_val)

  // -- Override resize: repack children --

  be resize(w: USize, h: USize) =>
    """
    Update container size, repack children, and re-render.
    """
    _state.width = w
    _state.height = h
    _repack()

  // -- Container-specific --

  be set_align(align: Alignment) =>
    """
    Set the container alignment and re-render.
    """
    _align = align
    _repack()

  be pack_start(widget: Widget tag, w: USize, h: USize, option: PackOption = PackOption) =>
    """
    Pack a child from the start (top). Repacks if already sized.
    """
    _children.push((widget, w, h, option, false))
    _state.child_grids.push((widget, Grid.filled(w, h, Cell.empty())))
    if (_state.width > 0) or (_state.height > 0) then _repack() end

  be pack_end(widget: Widget tag, w: USize, h: USize, option: PackOption = PackOption) =>
    """
    Pack a child from the end (bottom). Repacks if already sized.
    """
    _children.push((widget, w, h, option, true))
    _state.child_grids.push((widget, Grid.filled(w, h, Cell.empty())))
    if (_state.width > 0) or (_state.height > 0) then _repack() end

  fun ref _pack_params(): Array[(USize, USize, PackOption, Bool)] val =>
    let n = _children.size()
    let arr: Array[(USize, USize, PackOption, Bool)] iso =
      recover iso Array[(USize, USize, PackOption, Bool)](n) end
    for child in _children.values() do
      (_, let pw, let ph, let opt, let fe) = child
      arr.push((pw, ph, opt, fe))
    end
    consume arr

  fun ref _repack() =>
    let allocs = Packer.pack(Vertical, _state.width, _state.height, _pack_params(), _align)
    for i in Range(0, _children.size().min(allocs.size())) do
      try
        (let w, _, _, _, _) = _children(i)?
        let alloc = allocs(i)?
        match w
        | let r: Widget tag => r.resize(alloc.width, alloc.height)
        end
      end
    end
