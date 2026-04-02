primitive UIParser
  """
  Stateless parser for the UI DSL. Handles comment stripping,
  line tokenization, and size literal parsing.
  """

  fun strip_comments(line: String): String =>
    """
    Remove // line comments and /* ... */ inline block comments.
    If a block comment is opened but not closed, strip from /* to end of line.
    """
    recover val
      var result: String ref = line.clone()

      // Strip block comments (/* ... */ or unclosed /*)
      try
        while true do
          let open_idx = result.find("/*")?
          try
            let close_idx = result.find("*/", open_idx.isize() + 2)?
            // Remove from /* through */
            let before = result.substring(0, open_idx.isize())
            let after = result.substring(close_idx.isize() + 2)
            result = before.clone()
            result.append(consume after)
          else
            // Unclosed block comment: strip from /* to end
            result = result.substring(0, open_idx.isize()).clone()
          end
        end
      end

      // Strip line comments (//)
      try
        let idx = result.find("//")?
        result = result.substring(0, idx.isize()).clone()
      end

      result.strip()
      result
    end

  fun tokenize_line(line: String, line_num: USize)
    : (ParsedLine | BuilderError)
  =>
    """
    Count leading spaces for indent level (must be multiple of 2),
    then tokenize the remaining content.
    """
    // Count leading spaces
    var spaces: USize = 0
    try
      while spaces < line.size() do
        if line(spaces)? == ' ' then
          spaces = spaces + 1
        else
          break
        end
      end
    end

    if (spaces % 2) != 0 then
      return BuilderError(line_num,
        "indentation must be a multiple of 2 spaces (found " + spaces.string()
          + ")")
    end

    let indent = spaces / 2

    let content: String val =
      recover val
        let c: String ref = line.substring(spaces.isize())
        c.strip()
        c
      end

    if content.size() == 0 then
      return ParsedLine(indent, recover val Array[Token](0) end)
    end

    // Tokenize content
    let tokens: Array[Token] iso = recover iso Array[Token] end

    var i: USize = 0
    while i < content.size() do
      try
        // Skip whitespace
        if content(i)? == ' ' then
          i = i + 1
          continue
        end

        // Quoted string
        if content(i)? == '"' then
          let start = i + 1
          var end_idx = start
          try
            while end_idx < content.size() do
              if content(end_idx)? == '"' then break end
              end_idx = end_idx + 1
            end
          end
          let inner = content.substring(start.isize(), end_idx.isize())
          tokens.push(Token(TokQuotedString, consume inner))
          i = end_idx + 1
          continue
        end

        // ID (#name)
        if content(i)? == '#' then
          let start = i + 1
          var end_idx = start
          try
            while end_idx < content.size() do
              if content(end_idx)? == ' ' then break end
              end_idx = end_idx + 1
            end
          end
          let name = content.substring(start.isize(), end_idx.isize())
          tokens.push(Token(TokId, consume name))
          i = end_idx
          continue
        end

        // Word: read until space
        let start = i
        var end_idx = start
        try
          while end_idx < content.size() do
            if content(end_idx)? == ' ' then break end
            end_idx = end_idx + 1
          end
        end
        let word: String val = content.substring(start.isize(), end_idx.isize())
        tokens.push(_classify_word(word))
        i = end_idx
      else
        break
      end
    end

    let final_tokens: Array[Token] val = consume tokens
    ParsedLine(indent, final_tokens)

  fun _classify_word(word: String val): Token =>
    """
    Classify a plain word into the appropriate token kind.
    """
    match word
    | "pack-start" => Token(TokPackStart, word)
    | "pack-end" => Token(TokPackEnd, word)
    else
      if _is_mode(word) then
        Token(TokMode, word)
      elseif _is_size(word) then
        Token(TokSize, word)
      elseif word.contains("=") then
        try
          let eq_idx = word.find("=")?
          let key = word.substring(0, eq_idx.isize())
          let value = word.substring(eq_idx.isize() + 1)
          Token(TokKeyValue, consume value, consume key)
        else
          Token(TokWord, word)
        end
      else
        Token(TokWord, word)
      end
    end

  fun _is_size(word: String val): Bool =>
    (word == "*") or word.contains("x")

  fun _is_mode(word: String val): Bool =>
    match word
    | "fill" => true
    | "expand" => true
    | "fixed" => true
    else
      false
    end
