use "collections"

actor VBox is (WidgetParent & Resizable)
  """
  Vertical box container. Packs children top-to-bottom using
  GTK2-style expand/fill/padding semantics.
  """
  let _parent: WidgetParent tag
  var _width: USize
  var _height: USize
  let _children: Array[(Any tag, SizeHint, PackOption)]
  let _grids: Array[(Any tag, Grid)]

  new create(parent: WidgetParent tag, width: USize, height: USize) =>
    _parent = parent
    _width = width
    _height = height
    _children = Array[(Any tag, SizeHint, PackOption)]
    _grids = Array[(Any tag, Grid)]

  be add_child(widget: Any tag, hint: SizeHint, option: PackOption) =>
    """
    Add a child widget with its size hint and pack option.
    """
    _children.push((widget, hint, option))
    _grids.push((widget, Grid.filled(hint.preferred_width, hint.preferred_height, Cell.empty())))
    _repack()

  be receive_grid(widget: Any tag, grid: Grid) =>
    """
    Receive an updated grid from a child and recompose.
    """
    for i in Range(0, _grids.size()) do
      try
        (let w, _) = _grids(i)?
        if w is widget then
          _grids(i)? = (w, grid)
          _compose_and_send()
          return
        end
      end
    end

  be resize(width: USize, height: USize) =>
    """
    Update container size and repack all children.
    """
    _width = width
    _height = height
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
    let hints_and_opts = _hints_and_opts()
    let allocs = Packer.pack(Vertical, _width, _height, hints_and_opts)
    for i in Range(0, _children.size().min(allocs.size())) do
      try
        (let w, _, _) = _children(i)?
        let alloc = allocs(i)?
        match w
        | let r: Resizable tag => r.resize(alloc.width, alloc.height)
        end
      end
    end

  fun ref _compose_and_send() =>
    let allocs = Packer.pack(Vertical, _width, _height, _hints_and_opts())

    let combined: Array[Cell] iso =
      recover iso
        let size = _width * _height
        let cells = Array[Cell](size)
        for j in Range(0, size) do
          cells.push(Cell.empty())
        end
        cells
      end

    for i in Range(0, _grids.size().min(allocs.size())) do
      try
        (_, let grid) = _grids(i)?
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
    let combined_grid = Grid._from(_width, _height, cells_val)
    _parent.receive_grid(this, combined_grid)
