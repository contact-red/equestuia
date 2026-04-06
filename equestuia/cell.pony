primitive CellAttrs
  """
  Bitfield constants for cell text attributes.
  """
  fun bold(): U8 =>
    """
    Bold attribute bit.
    """
    0x01
  fun dim(): U8 =>
    """
    Dim attribute bit.
    """
    0x02
  fun underline(): U8 =>
    """
    Underline attribute bit.
    """
    0x04
  fun blink(): U8 =>
    """
    Blink attribute bit.
    """
    0x08
  fun reverse(): U8 =>
    """
    Reverse video attribute bit.
    """
    0x10

class val Cell is Equatable[Cell]
  """
  A single styled terminal character.
  """
  let char: U32
  let width: U8
  let fg: Color
  let bg: Color
  let attrs: U8

  new val create(
    char': U32,
    width': U8,
    fg': Color,
    bg': Color,
    attrs': U8)
  =>
    """
    Create a cell with explicit character, width, colors, and attributes.
    """
    char = char'
    width = width'
    fg = fg'
    bg = bg'
    attrs = attrs'

  new val empty() =>
    """
    A blank cell: space character, normal width, default colors, no attrs.
    """
    char = ' '
    width = 1
    fg = Default
    bg = Default
    attrs = 0

  new val continuation() =>
    """
    A continuation cell placed after a wide character.
    Width 0 signals the renderer to skip this column.
    """
    char = 0
    width = 0
    fg = Default
    bg = Default
    attrs = 0

  fun eq(that: box->Cell): Bool =>
    """
    Two cells are equal when all fields match.
    """
    (char == that.char)
      and (width == that.width)
      and (_color_eq(fg, that.fg))
      and (_color_eq(bg, that.bg))
      and (attrs == that.attrs)

  fun ne(that: box->Cell): Bool =>
    """
    Negation of eq.
    """
    not eq(that)

  fun tag _color_eq(a: Color, b: Color): Bool =>
    a is b
