primitive Default
  """
  Terminal default color.
  """
  fun fg_code(): U8 =>
    """
    ANSI SGR code for default foreground.
    """
    39
  fun bg_code(): U8 =>
    """
    ANSI SGR code for default background.
    """
    49

primitive Black
  """
  ANSI black.
  """
  fun fg_code(): U8 => 30
  fun bg_code(): U8 => 40

primitive Red
  """
  ANSI red.
  """
  fun fg_code(): U8 => 31
  fun bg_code(): U8 => 41

primitive Green
  """
  ANSI green.
  """
  fun fg_code(): U8 => 32
  fun bg_code(): U8 => 42

primitive Yellow
  """
  ANSI yellow.
  """
  fun fg_code(): U8 => 33
  fun bg_code(): U8 => 43

primitive Blue
  """
  ANSI blue.
  """
  fun fg_code(): U8 => 34
  fun bg_code(): U8 => 44

primitive Magenta
  """
  ANSI magenta.
  """
  fun fg_code(): U8 => 35
  fun bg_code(): U8 => 45

primitive Cyan
  """
  ANSI cyan.
  """
  fun fg_code(): U8 => 36
  fun bg_code(): U8 => 46

primitive White
  """
  ANSI white.
  """
  fun fg_code(): U8 => 37
  fun bg_code(): U8 => 47

primitive BrightBlack
  """
  ANSI bright black (gray).
  """
  fun fg_code(): U8 => 90
  fun bg_code(): U8 => 100

primitive BrightRed
  """
  ANSI bright red.
  """
  fun fg_code(): U8 => 91
  fun bg_code(): U8 => 101

primitive BrightGreen
  """
  ANSI bright green.
  """
  fun fg_code(): U8 => 92
  fun bg_code(): U8 => 102

primitive BrightYellow
  """
  ANSI bright yellow.
  """
  fun fg_code(): U8 => 93
  fun bg_code(): U8 => 103

primitive BrightBlue
  """
  ANSI bright blue.
  """
  fun fg_code(): U8 => 94
  fun bg_code(): U8 => 104

primitive BrightMagenta
  """
  ANSI bright magenta.
  """
  fun fg_code(): U8 => 95
  fun bg_code(): U8 => 105

primitive BrightCyan
  """
  ANSI bright cyan.
  """
  fun fg_code(): U8 => 96
  fun bg_code(): U8 => 106

primitive BrightWhite
  """
  ANSI bright white.
  """
  fun fg_code(): U8 => 97
  fun bg_code(): U8 => 107

primitive Rainbow
  """
  Sentinel: not a real ANSI color. Signals containers to cycle through
  a palette of colors per packed slot, making expand vs fill visible.
  Falls back to Default codes if it ever reaches the encoder directly.
  """
  fun fg_code(): U8 => 39
  fun bg_code(): U8 => 49

type Color is
  ( Default | Black | Red | Green | Yellow | Blue | Magenta | Cyan | White
  | BrightBlack | BrightRed | BrightGreen | BrightYellow | BrightBlue
  | BrightMagenta | BrightCyan | BrightWhite | Rainbow )

primitive _RainbowPalette
  """
  Cycling color palette for Rainbow debug-bg. Returns a color for a
  given slot index, wrapping around the palette.
  """
  fun apply(index: USize): Color =>
    match index % 6
    | 0 => Red
    | 1 => Green
    | 2 => Blue
    | 3 => Yellow
    | 4 => Magenta
    | 5 => Cyan
    else
      Red // unreachable
    end

interface val Colorable
  fun fg_code(): U8
  fun bg_code(): U8
