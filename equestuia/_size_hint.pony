class val SizeHint
  """A widget's preferred dimensions, used by box containers for packing."""
  let preferred_width: USize
  let preferred_height: USize

  new val create(preferred_width': USize, preferred_height': USize) =>
    preferred_width = preferred_width'
    preferred_height = preferred_height'
