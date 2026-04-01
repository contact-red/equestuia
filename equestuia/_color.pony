primitive Default
  fun fg_code(): U8 => 39
  fun bg_code(): U8 => 49

primitive Black
  fun fg_code(): U8 => 30
  fun bg_code(): U8 => 40

primitive Red
  fun fg_code(): U8 => 31
  fun bg_code(): U8 => 41

primitive Green
  fun fg_code(): U8 => 32
  fun bg_code(): U8 => 42

primitive Yellow
  fun fg_code(): U8 => 33
  fun bg_code(): U8 => 43

primitive Blue
  fun fg_code(): U8 => 34
  fun bg_code(): U8 => 44

primitive Magenta
  fun fg_code(): U8 => 35
  fun bg_code(): U8 => 45

primitive Cyan
  fun fg_code(): U8 => 36
  fun bg_code(): U8 => 46

primitive White
  fun fg_code(): U8 => 37
  fun bg_code(): U8 => 47

primitive BrightBlack
  fun fg_code(): U8 => 90
  fun bg_code(): U8 => 100

primitive BrightRed
  fun fg_code(): U8 => 91
  fun bg_code(): U8 => 101

primitive BrightGreen
  fun fg_code(): U8 => 92
  fun bg_code(): U8 => 102

primitive BrightYellow
  fun fg_code(): U8 => 93
  fun bg_code(): U8 => 103

primitive BrightBlue
  fun fg_code(): U8 => 94
  fun bg_code(): U8 => 104

primitive BrightMagenta
  fun fg_code(): U8 => 95
  fun bg_code(): U8 => 105

primitive BrightCyan
  fun fg_code(): U8 => 96
  fun bg_code(): U8 => 106

primitive BrightWhite
  fun fg_code(): U8 => 97
  fun bg_code(): U8 => 107

type Color is
  ( Default | Black | Red | Green | Yellow | Blue | Magenta | Cyan | White
  | BrightBlack | BrightRed | BrightGreen | BrightYellow | BrightBlue
  | BrightMagenta | BrightCyan | BrightWhite )

interface val _Colorable
  fun fg_code(): U8
  fun bg_code(): U8
