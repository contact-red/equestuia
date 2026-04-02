use "collections"

actor HBox is CompositeWidget
  """
  Horizontal box container. Packs children left-to-right using
  GTK2-style expand/fill/padding semantics.
  """
  let _parent: WidgetParent tag
  var _width: USize
  var _height: USize
  let _children: Array[(Any tag, SizeHint, PackOption)]
  let _child_grids: Array[(Any tag, Grid)]

  new create(p: WidgetParent tag, w: USize, h: USize) =>
    _parent = p
    _width = w
    _height = h
    _children = Array[(Any tag, SizeHint, PackOption)]
    _child_grids = Array[(Any tag, Grid)]

  // -- Widget + CompositeWidget required helpers --

  fun ref parent(): WidgetParent tag => _parent
  fun ref width(): USize => _width
  fun ref height(): USize => _height
  fun ref set_size(w: USize, h: USize) => _width = w; _height = h
  fun ref child_grids(): Array[(Any tag, Grid)] => _child_grids

  fun ref render_background(): Grid =>
    Grid.filled(_width, _height, Cell.empty())

  // -- Override render: position children using packer allocations --

  fun ref render(): Grid =>
    """
    Compose all child grids into a single grid using packer allocations.
    """
    let allocs = Packer.pack(Horizontal, _width, _height, _hints_and_opts())

    let combined: Array[Cell] iso =
      recover iso
        let size = _width * _height
        let cells = Array[Cell](size)
        for j in Range(0, size) do
          cells.push(Cell.empty())
        end
        cells
      end

    for i in Range(0, _child_grids.size().min(allocs.size())) do
      try
        (_, let grid) = _child_grids(i)?
        let alloc = allocs(i)?
        for row in Range(0, grid.height.min(alloc.height)) do
          for col in Range(0, grid.width.min(alloc.width)) do
            let dest_col = alloc.x + col
            let dest_row = alloc.y + row
            if (dest_col < _width) and (dest_row < _height) then
              match grid(col, row)
              | let c: Cell =>
                combined((dest_row * _width) + dest_col)? = c
              end
            end
          end
        end
      end
    end

    let cells_val: Array[Cell] val = consume combined
    Grid._from(_width, _height, cells_val)

  // -- Override resize: repack children --

  be resize(w: USize, h: USize) =>
    """
    Update container size, repack children, and re-render.
    """
    set_size(w, h)
    _repack()

  // -- Container-specific --

  be add_child(widget: Widget tag, hint: SizeHint, option: PackOption) =>
    """
    Add a child widget with its size hint and pack option.
    """
    _children.push((widget, hint, option))
    _child_grids.push((widget, Grid.filled(hint.preferred_width, hint.preferred_height, Cell.empty())))
    _repack()

  fun ref _hints_and_opts(): Array[(SizeHint, PackOption)] val =>
    let n = _children.size()
    let arr: Array[(SizeHint, PackOption)] iso =
      recover iso Array[(SizeHint, PackOption)](n) end
    for child in _children.values() do
      (_, let hint, let opt) = child
      arr.push((hint, opt))
    end
    consume arr

  fun ref _repack() =>
    let allocs = Packer.pack(Horizontal, _width, _height, _hints_and_opts())
    for i in Range(0, _children.size().min(allocs.size())) do
      try
        (let w, _, _) = _children(i)?
        let alloc = allocs(i)?
        match w
        | let r: Widget tag => r.resize(alloc.width, alloc.height)
        end
      end
    end
