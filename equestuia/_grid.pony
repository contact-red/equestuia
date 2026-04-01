use "collections"

primitive GridCellOutOfBounds
primitive GridDimensionMismatch

type GridError is (GridCellOutOfBounds | GridDimensionMismatch)

class val Grid
  """
  A 2D rectangle of styled cells. Immutable for safe passing between actors.
  Row-major layout: index = (row * width) + col.
  """
  let width: USize
  let height: USize
  let _cells: Array[Cell] val

  new val _from(width': USize, height': USize, cells': Array[Cell] val) =>
    width = width'
    height = height'
    _cells = cells'

  new val filled(width': USize, height': USize, fill: Cell) =>
    """Create a grid where every cell is `fill`."""
    width = width'
    height = height'
    _cells = recover val
      let size = width' * height'
      let arr = Array[Cell](size)
      for i in Range(0, size) do
        arr.push(fill)
      end
      arr
    end

  fun apply(col: USize, row: USize): (Cell | GridCellOutOfBounds) =>
    """Look up a cell by (col, row). Returns error if out of bounds."""
    if (col >= width) or (row >= height) then
      GridCellOutOfBounds
    else
      try
        _cells((row * width) + col)?
      else
        _Unreachable()
        Cell.empty() // compiler needs a return after the panic call
      end
    end

primitive GridFactory
  """Validated constructor for Grid. Returns GridDimensionMismatch if cells.size() != width * height."""
  fun apply(width: USize, height: USize, cells: Array[Cell] val)
    : (Grid | GridDimensionMismatch)
  =>
    if cells.size() != (width * height) then
      GridDimensionMismatch
    else
      Grid._from(width, height, cells)
    end
