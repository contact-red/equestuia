use "collections"

actor TextBox is Widget
  """
  A multi-line text display widget with optional word wrap.

  When word wrap is enabled, text breaks at word boundaries (spaces) to
  fit within the widget's width. When disabled, lines are hard-truncated
  at the width. Lines beyond the widget's height are not displayed.
  """
  let _state: WidgetState
  var _text: String val
  var _fg: Color
  var _bg: Color
  var _wrap: Bool

  new create(
    p: WidgetParent tag,
    text: String val = "",
    fg: Color = White,
    bg: Color = Default,
    wrap: Bool = true)
  =>
    _state = WidgetState(p)
    _text = text
    _fg = fg
    _bg = bg
    _wrap = wrap

  be set_text(text: String val) =>
    """
    Update the text content and re-render.
    """
    _text = text
    render_and_send()

  be set_color(fg: Color, bg: Color = Default) =>
    """
    Update the text colors and re-render.
    """
    _fg = fg
    _bg = bg
    render_and_send()

  be set_wrap(wrap: Bool) =>
    """
    Enable or disable word wrapping and re-render.
    """
    _wrap = wrap
    render_and_send()

  // -- Widget required helpers --

  fun ref state(): WidgetState => _state

  fun ref render(): Grid =>
    let w = _state.width
    let h = _state.height
    let fg = _fg
    let bg = _bg
    let lines_ref = _layout_lines()
    let lines: Array[String val] iso = recover iso
      Array[String val](lines_ref.size())
    end
    for line in lines_ref.values() do
      lines.push(line)
    end
    let lines_val: Array[String val] val = consume lines

    let cells = recover val
      let size = w * h
      let arr = Array[Cell](size)

      for row in Range(0, h) do
        if row < lines_val.size() then
          try
            let line = lines_val(row)?
            for col in Range(0, w) do
              if col < line.size() then
                try
                  arr.push(Cell(line(col)?.u32(), 1, fg, bg, 0))
                else
                  arr.push(Cell(' ', 1, fg, bg, 0))
                end
              else
                arr.push(Cell(' ', 1, fg, bg, 0))
              end
            end
          else
            for col in Range(0, w) do
              arr.push(Cell(' ', 1, fg, bg, 0))
            end
          end
        else
          for col in Range(0, w) do
            arr.push(Cell(' ', 1, fg, bg, 0))
          end
        end
      end
      arr
    end

    GridFactory(w, h, cells)

  fun ref _layout_lines(): Array[String val] ref =>
    """
    Split text into display lines. Respects explicit newlines.
    When wrapping is enabled, breaks long lines at word boundaries.
    """
    let result = Array[String val]
    let raw_lines = _split_newlines()

    for raw_line in raw_lines.values() do
      if _wrap and (raw_line.size() > _state.width) then
        _wrap_line(raw_line, result)
      else
        result.push(raw_line)
      end
    end
    result

  fun ref _split_newlines(): Array[String val] ref =>
    """
    Split text on newline characters.
    """
    let lines = Array[String val]
    var start: USize = 0
    var i: USize = 0

    while i < _text.size() do
      try
        if _text(i)? == '\n' then
          lines.push(_text.substring(start.isize(), i.isize()))
          start = i + 1
        end
      end
      i = i + 1
    end
    // Final segment
    if start <= _text.size() then
      lines.push(_text.substring(start.isize()))
    end
    lines

  fun ref _wrap_line(line: String val, out: Array[String val] ref) =>
    """
    Word-wrap a single line into multiple lines that fit within _state.width.
    Breaks at the last space before the width limit. If a word is longer
    than _state.width, hard-breaks it.
    """
    var remaining = line
    while remaining.size() > _state.width do
      // Find last space within width
      var break_at = _state.width
      var found_space = false
      var j = _state.width
      while j > 0 do
        j = j - 1
        try
          if remaining(j)? == ' ' then
            break_at = j
            found_space = true
            break
          end
        end
      end

      if found_space then
        out.push(remaining.substring(0, break_at.isize()))
        // Skip the space
        remaining = remaining.substring((break_at + 1).isize())
      else
        // No space found — hard break at width
        out.push(remaining.substring(0, _state.width.isize()))
        remaining = remaining.substring(_state.width.isize())
      end
    end
    // Remainder
    if remaining.size() > 0 then
      out.push(remaining)
    end
