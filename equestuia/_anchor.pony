primitive North
  """
  Top edge, centered horizontally.
  """
primitive NorthEast
  """
  Top-right corner.
  """
primitive East
  """
  Right edge, centered vertically.
  """
primitive SouthEast
  """
  Bottom-right corner.
  """
primitive South
  """
  Bottom edge, centered horizontally.
  """
primitive SouthWest
  """
  Bottom-left corner.
  """
primitive West
  """
  Left edge, centered vertically.
  """
primitive NorthWest
  """
  Top-left corner.
  """
primitive Center
  """
  Centered both horizontally and vertically.
  """

type Anchor is
  ( North | NorthEast | East | SouthEast | South
  | SouthWest | West | NorthWest | Center )
