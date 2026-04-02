primitive ColorLookup
  """
  Map color name strings to Color primitives.
  """
  fun apply(name: String): (Color | None) =>
    match name
    | "default" => Default
    | "black" => Black
    | "red" => Red
    | "green" => Green
    | "yellow" => Yellow
    | "blue" => Blue
    | "magenta" => Magenta
    | "cyan" => Cyan
    | "white" => White
    | "bright-black" => BrightBlack
    | "bright-red" => BrightRed
    | "bright-green" => BrightGreen
    | "bright-yellow" => BrightYellow
    | "bright-blue" => BrightBlue
    | "bright-magenta" => BrightMagenta
    | "bright-cyan" => BrightCyan
    | "bright-white" => BrightWhite
    else
      None
    end

primitive AlignLookup
  """
  Map alignment name strings to Alignment values.
  """
  fun apply(name: String): (Alignment | None) =>
    match name
    | "start" => AlignStart
    | "center" => AlignCenter
    | "end" => AlignEnd
    else
      None
    end

primitive ModeLookup
  """
  Map mode name strings to PackMode values.
  """
  fun apply(name: String): (PackMode | None) =>
    match name
    | "fill" => PackFill
    | "expand" => PackExpand
    | "fixed" => PackFixed
    else
      None
    end
