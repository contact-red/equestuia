class val PackOption
  """
  Per-child packing configuration within a box container (GTK2-style).
  """
  let from_end: Bool
  let expand: Bool
  let fill: Bool
  let padding: USize

  new val create(
    from_end': Bool = false,
    expand': Bool = false,
    fill': Bool = false,
    padding': USize = 0)
  =>
    """
    Create a pack option. All fields default to false/zero.
    """
    from_end = from_end'
    expand = expand'
    fill = fill'
    padding = padding'
