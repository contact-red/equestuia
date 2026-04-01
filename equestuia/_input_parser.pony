primitive IncompleteSequence
primitive UnrecognizedSequence

type InputParseError is (IncompleteSequence | UnrecognizedSequence)

// Parser state machine states

primitive _Ground
primitive _EscSeen
primitive _CsiEntry
primitive _CsiParam
primitive _Ss3
primitive _Utf8Two
primitive _Utf8Three
primitive _Utf8Four

type _ParseState is
  ( _Ground | _EscSeen | _CsiEntry | _CsiParam | _Ss3
  | _Utf8Two | _Utf8Three | _Utf8Four )

class ref InputParser
  var _state: _ParseState = _Ground
  // Accumulated CSI/SS3 parameter digits
  var _param: U32 = 0
  // UTF-8 accumulation: codepoint-in-progress and bytes remaining
  var _utf8_codepoint: U32 = 0
  var _utf8_remaining: U8 = 0
  // Events accumulated during the current parse() call.
  // iso so we can destructive-read it and consume to val at end of parse().
  var _out: Array[InputEvent] iso = recover iso Array[InputEvent] end

  fun ref parse(data: Array[U8] val): Array[InputEvent] val =>
    _out = recover iso Array[InputEvent] end
    for byte in data.values() do
      _process(byte)
    end
    // If we end in EscSeen with no follow-up, emit Escape
    match _state
    | _EscSeen =>
      _out.push(KeyEvent(Escape))
      _state = _Ground
    end
    // Destructive read: swap _out with a fresh iso, then consume result to val.
    let result: Array[InputEvent] iso = _out = recover iso Array[InputEvent] end
    consume result

  fun ref _process(byte: U8) =>
    match _state
    | _Ground       => _ground(byte)
    | _EscSeen      => _esc_seen(byte)
    | _CsiEntry     => _csi_entry(byte)
    | _CsiParam     => _csi_param(byte)
    | _Ss3          => _ss3(byte)
    | _Utf8Two      => _utf8_cont(byte)
    | _Utf8Three    => _utf8_cont(byte)
    | _Utf8Four     => _utf8_cont(byte)
    end

  fun ref _ground(byte: U8) =>
    if byte == 13 then
      _out.push(KeyEvent(Enter))
    elseif byte == 9 then
      _out.push(KeyEvent(Tab))
    elseif (byte == 127) or (byte == 8) then
      _out.push(KeyEvent(Backspace))
    elseif byte == 27 then
      _state = _EscSeen
    elseif (byte >= 1) and (byte <= 26) then
      // Ctrl+letter: byte 1='a', 2='b', ..., 26='z'
      // 'a' as U32 = 97; byte 1 maps to 'a', so char = 96 + byte
      let ch: U32 = 96 + byte.u32()
      _out.push(KeyEvent(CharKey, ch, Modifiers.ctrl()))
    elseif (byte >= 0x20) and (byte <= 0x7E) then
      _out.push(KeyEvent(CharKey, byte.u32()))
    elseif (byte >= 0xC0) and (byte <= 0xDF) then
      // 2-byte UTF-8: 110xxxxx
      _utf8_codepoint = (byte.u32() and 0x1F)
      _utf8_remaining = 1
      _state = _Utf8Two
    elseif (byte >= 0xE0) and (byte <= 0xEF) then
      // 3-byte UTF-8: 1110xxxx
      _utf8_codepoint = (byte.u32() and 0x0F)
      _utf8_remaining = 2
      _state = _Utf8Three
    elseif (byte >= 0xF0) and (byte <= 0xF7) then
      // 4-byte UTF-8: 11110xxx
      _utf8_codepoint = (byte.u32() and 0x07)
      _utf8_remaining = 3
      _state = _Utf8Four
    end
    // else: silently discard unrecognized bytes

  fun ref _esc_seen(byte: U8) =>
    if byte == 91 then // '['
      _param = 0
      _state = _CsiEntry
    elseif byte == 79 then // 'O'
      _state = _Ss3
    else
      // Unrecognized ESC sequence — discard, return to ground
      _state = _Ground
    end

  fun ref _csi_entry(byte: U8) =>
    if (byte >= 48) and (byte <= 57) then // '0'..'9'
      _param = (byte.u32() - 48)
      _state = _CsiParam
    else
      _csi_final(byte, 0)
    end

  fun ref _csi_param(byte: U8) =>
    if (byte >= 48) and (byte <= 57) then // '0'..'9'
      _param = (_param * 10) + (byte.u32() - 48)
    elseif byte == 59 then // ';'
      // Extended params — only first param used, ignore rest
      None
    else
      _csi_final(byte, _param)
    end

  fun ref _csi_final(byte: U8, param: U32) =>
    _state = _Ground
    if byte == 126 then // '~'
      // Tilde sequences
      let key: (Key | None) = match param
      | 1  => Home
      | 2  => Insert
      | 3  => Delete
      | 4  => End
      | 5  => PageUp
      | 6  => PageDown
      | 15 => F5
      | 17 => F6
      | 18 => F7
      | 19 => F8
      | 20 => F9
      | 21 => F10
      | 23 => F11
      | 24 => F12
      else None
      end
      match key
      | let k: Key => _out.push(KeyEvent(k))
      end
    else
      // Letter final byte
      let key: (Key | None) = match byte
      | 65 => Up    // 'A'
      | 66 => Down  // 'B'
      | 67 => Right // 'C'
      | 68 => Left  // 'D'
      | 72 => Home  // 'H'
      | 70 => End   // 'F'
      else None
      end
      match key
      | let k: Key => _out.push(KeyEvent(k))
      end
    end

  fun ref _ss3(byte: U8) =>
    _state = _Ground
    let key: (Key | None) = match byte
    | 80 => F1   // 'P'
    | 81 => F2   // 'Q'
    | 82 => F3   // 'R'
    | 83 => F4   // 'S'
    | 72 => Home // 'H'
    | 70 => End  // 'F'
    else None
    end
    match key
    | let k: Key => _out.push(KeyEvent(k))
    end

  fun ref _utf8_cont(byte: U8) =>
    // Validate continuation byte: must be 10xxxxxx
    if (byte and 0xC0) != 0x80 then
      // Malformed — discard and reset
      _state = _Ground
      return
    end
    _utf8_codepoint = (_utf8_codepoint << 6) or (byte.u32() and 0x3F)
    _utf8_remaining = _utf8_remaining - 1
    if _utf8_remaining == 0 then
      _out.push(KeyEvent(CharKey, _utf8_codepoint))
      _utf8_codepoint = 0
      _state = _Ground
    end
