primitive AlignStart
  """
  Align packed children to the start of the container (default).
  """
primitive AlignCenter
  """
  Center packed children within the container's remaining space.
  """
primitive AlignEnd
  """
  Align packed children to the end of the container.
  """

type Alignment is (AlignStart | AlignCenter | AlignEnd)
