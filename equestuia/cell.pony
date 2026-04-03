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
    match a
    | let _: Default => match b | let _: Default => true else false end
    | let _: Black => match b | let _: Black => true else false end
    | let _: Red => match b | let _: Red => true else false end
    | let _: Green => match b | let _: Green => true else false end
    | let _: Yellow => match b | let _: Yellow => true else false end
    | let _: Blue => match b | let _: Blue => true else false end
    | let _: Magenta => match b | let _: Magenta => true else false end
    | let _: Cyan => match b | let _: Cyan => true else false end
    | let _: White => match b | let _: White => true else false end
    | let _: BrightBlack => match b | let _: BrightBlack => true else false end
    | let _: BrightRed => match b | let _: BrightRed => true else false end
    | let _: BrightGreen => match b | let _: BrightGreen => true else false end
    | let _: BrightYellow => match b | let _: BrightYellow => true else false end
    | let _: BrightBlue => match b | let _: BrightBlue => true else false end
    | let _: BrightMagenta => match b | let _: BrightMagenta => true else false end
    | let _: BrightCyan => match b | let _: BrightCyan => true else false end
    | let _: BrightWhite => match b | let _: BrightWhite => true else false end
    | let _: Rainbow => match b | let _: Rainbow => true else false end
    end
