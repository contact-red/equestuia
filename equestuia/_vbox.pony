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
    """
    let w = _state.width
    let h = _state.height
    let allocs = Packer.pack(Vertical, w, h, _pack_params(), _align)

    let empty = _state.empty_cell()
    let combined: Array[Cell] iso =
      recover iso
        let size = w * h
        let cells = Array[Cell](size)
        for j in Range(0, size) do
          cells.push(empty)
        end
        cells
      end

    for i in Range(0, _state.child_grids.size().min(allocs.size())) do
      try
        (_, let grid) = _state.child_grids(i)?
        let alloc = allocs(i)?
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
    Pack a child from the start (top for VBox).
    """
    _children.push((widget, w, h, option, false))
    _state.child_grids.push((widget, Grid.filled(w, h, Cell.empty())))

  be pack_end(widget: Widget tag, w: USize, h: USize, option: PackOption = PackOption) =>
    """
    Pack a child from the end (bottom for VBox).
    """
    _children.push((widget, w, h, option, true))
    _state.child_grids.push((widget, Grid.filled(w, h, Cell.empty())))

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
