primitive AnsiEncoder
  fun move_to(col: USize, row: USize): Array[U8] val =>
    """Emit ESC[(row+1);(col+1)H — terminal coordinates are 1-indexed."""
    recover val
      let buf = Array[U8]
      buf.push(0x1B); buf.push('[')
      _push_usize(buf, row + 1)
      buf.push(';')
      _push_usize(buf, col + 1)
      buf.push('H')
      buf
    end

  fun set_fg(color: Color): Array[U8] val =>
    """Emit ESC[{fg_code}m."""
    let code =
      match color
      | let c: _Colorable => c.fg_code()
      end
    _sgr(code.usize())

  fun set_bg(color: Color): Array[U8] val =>
    """Emit ESC[{bg_code}m."""
    let code =
      match color
      | let c: _Colorable => c.bg_code()
      end
    _sgr(code.usize())

  fun set_attrs(attrs: U8): Array[U8] val =>
    """
    Emit an SGR sequence for each set bit.
    bold=1, dim=2, underline=4, blink=5, reverse=7
    """
    recover val
      let buf = Array[U8]
      if (attrs and CellAttrs.bold()) != 0 then
        for b in _sgr(1).values() do buf.push(b) end
      end
      if (attrs and CellAttrs.dim()) != 0 then
        for b in _sgr(2).values() do buf.push(b) end
      end
      if (attrs and CellAttrs.underline()) != 0 then
        for b in _sgr(4).values() do buf.push(b) end
      end
      if (attrs and CellAttrs.blink()) != 0 then
        for b in _sgr(5).values() do buf.push(b) end
      end
      if (attrs and CellAttrs.reverse()) != 0 then
        for b in _sgr(7).values() do buf.push(b) end
      end
      buf
    end

  fun reset(): Array[U8] val =>
    """Emit ESC[0m."""
    _sgr(0)

  fun write_char(codepoint: U32): Array[U8] val =>
    """Encode a Unicode codepoint as UTF-8 bytes."""
    recover val
      let buf = Array[U8]
      if codepoint <= 0x7F then
        buf.push(codepoint.u8())
      elseif codepoint <= 0x7FF then
        buf.push((0xC0 or (codepoint >> 6)).u8())
        buf.push((0x80 or (codepoint and 0x3F)).u8())
      elseif codepoint <= 0xFFFF then
        buf.push((0xE0 or (codepoint >> 12)).u8())
        buf.push((0x80 or ((codepoint >> 6) and 0x3F)).u8())
        buf.push((0x80 or (codepoint and 0x3F)).u8())
      else
        buf.push((0xF0 or (codepoint >> 18)).u8())
        buf.push((0x80 or ((codepoint >> 12) and 0x3F)).u8())
        buf.push((0x80 or ((codepoint >> 6) and 0x3F)).u8())
        buf.push((0x80 or (codepoint and 0x3F)).u8())
      end
      buf
    end

  fun hide_cursor(): Array[U8] val =>
    """Emit ESC[?25l."""
    recover val
      [as U8: 0x1B; '['; '?'; '2'; '5'; 'l']
    end

  fun show_cursor(): Array[U8] val =>
    """Emit ESC[?25h."""
    recover val
      [as U8: 0x1B; '['; '?'; '2'; '5'; 'h']
    end

  fun clear_screen(): Array[U8] val =>
    """Emit ESC[2J."""
    recover val
      [as U8: 0x1B; '['; '2'; 'J']
    end

  fun tag _sgr(code: USize): Array[U8] val =>
    """Build ESC[{code}m."""
    recover val
      let buf = Array[U8]
      buf.push(0x1B); buf.push('[')
      _push_usize(buf, code)
      buf.push('m')
      buf
    end

  fun tag _push_usize(buf: Array[U8], n: USize) =>
    """Append the decimal ASCII representation of n to buf."""
    if n >= 10 then
      _push_usize(buf, n / 10)
    end
    buf.push(((n % 10) + 48).u8())
