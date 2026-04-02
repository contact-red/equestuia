use "collections"

actor HBox is CompositeWidget
  """
  Horizontal box container. Packs children left-to-right using
  GTK2-style expand/fill/padding semantics.
  """
  let _parent: WidgetParent tag
  var _width: USize
  var _height: USize
  let _children: Array[(Any tag, USize, USize, PackOption)]
  let _child_grids: Array[(Any tag, Grid)]
  var _dirty: Bool = false

  new create(p: WidgetParent tag) =>
    _parent = p
    _width = 0
    _height = 0
    _children = Array[(Any tag, USize, USize, PackOption)]
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
    Grid.filled(_width, _height, Cell.empty())

  // -- Override render: position children using packer allocations --

  fun ref render(): Grid =>
    """
    Compose all child grids into a single grid using packer allocations.
    """
    let allocs = Packer.pack(Horizontal, _width, _height, _pack_params())

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

  be add_child(widget: Widget tag, w: USize, h: USize, option: PackOption = PackOption) =>
    """
    Add a child widget with its preferred size and pack option.
    """
    _children.push((widget, w, h, option))
    _child_grids.push((widget, Grid.filled(w, h, Cell.empty())))

  fun ref _pack_params(): Array[(USize, USize, PackOption)] val =>
    let n = _children.size()
    let arr: Array[(USize, USize, PackOption)] iso =
      recover iso Array[(USize, USize, PackOption)](n) end
    for child in _children.values() do
      (_, let pw, let ph, let opt) = child
      arr.push((pw, ph, opt))
    end
    consume arr

  fun ref _repack() =>
    let allocs = Packer.pack(Horizontal, _width, _height, _pack_params())
    for i in Range(0, _children.size().min(allocs.size())) do
      try
        (let w, _, _, _) = _children(i)?
        let alloc = allocs(i)?
        match w
        | let r: Widget tag => r.resize(alloc.width, alloc.height)
        end
      end
    end
