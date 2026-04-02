primitive PackFixed
  """
  Child gets its preferred size. No extra space claimed.
  """
primitive PackExpand
  """
  Child claims a share of extra space but stays at preferred size,
  centered within its allocation.
  """
primitive PackFill
  """
  Child claims a share of extra space and stretches to fill it.
  """

type PackMode is (PackFixed | PackExpand | PackFill)

class val PackOption
  """
  Per-child packing configuration within a box container.
  """
  let mode: PackMode
  let padding: USize

  new val create(
    mode': PackMode = PackFixed,
    padding': USize = 0)
  =>
    """
    Create a pack option. Defaults to fixed size with no padding.
    """
    mode = mode'
    padding = padding'
