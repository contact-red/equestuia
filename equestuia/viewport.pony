class val ViewPort
  """
  A widget's declaration of screen position, size, and layer.
  """
  let anchor: Anchor
  let width: USize
  let height: USize
  let offset_x: ISize
  let offset_y: ISize
  let z_order: I32

  new val create(
    anchor': Anchor,
    width': USize,
    height': USize,
    offset_x': ISize = 0,
    offset_y': ISize = 0,
    z_order': I32 = 0)
  =>
    """
    Create a viewport with anchor, dimensions, optional offset, and z-order.
    """
    anchor = anchor'
    width = width'
    height = height'
    offset_x = offset_x'
    offset_y = offset_y'
    z_order = z_order'
