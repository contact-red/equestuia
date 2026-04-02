use "pony_test"

class \nodoc\ iso _TestStripLineComments is UnitTest
  fun name(): String => "UIParser.strip_line_comments"

  fun apply(h: TestHelper) =>
    h.assert_eq[String]("vbox", UIParser.strip_comments("vbox // comment"))
    h.assert_eq[String]("", UIParser.strip_comments("// full comment"))
    h.assert_eq[String]("vbox", UIParser.strip_comments("vbox"))

class \nodoc\ iso _TestStripBlockComments is UnitTest
  fun name(): String => "UIParser.strip_block_comments"

  fun apply(h: TestHelper) =>
    h.assert_eq[String]("vbox  hbox",
      UIParser.strip_comments("vbox /* inline */ hbox"))
    h.assert_eq[String]("vbox",
      UIParser.strip_comments("vbox /* comment"))

class \nodoc\ iso _TestTokenizeLine is UnitTest
  fun name(): String => "UIParser.tokenize_line"

  fun apply(h: TestHelper) =>
    let input = "  label #title \"Hello\" fg=red focusable"
    match UIParser.tokenize_line(input, 1)
    | let pl: ParsedLine =>
      h.assert_eq[USize](1, pl.indent)
      h.assert_eq[USize](5, pl.tokens.size())
      try
        let t0 = pl.tokens(0)?
        h.assert_true(t0.kind is TokWord, "token 0 should be TokWord")
        h.assert_eq[String]("label", t0.value)

        let t1 = pl.tokens(1)?
        h.assert_true(t1.kind is TokId, "token 1 should be TokId")
        h.assert_eq[String]("title", t1.value)

        let t2 = pl.tokens(2)?
        h.assert_true(t2.kind is TokQuotedString,
          "token 2 should be TokQuotedString")
        h.assert_eq[String]("Hello", t2.value)

        let t3 = pl.tokens(3)?
        h.assert_true(t3.kind is TokKeyValue,
          "token 3 should be TokKeyValue")
        h.assert_eq[String]("fg", t3.key)
        h.assert_eq[String]("red", t3.value)

        let t4 = pl.tokens(4)?
        h.assert_true(t4.kind is TokWord, "token 4 should be TokWord")
        h.assert_eq[String]("focusable", t4.value)
      else
        h.fail("index error")
      end
    | let err: BuilderError =>
      h.fail("unexpected error: " + err.string())
    end

class \nodoc\ iso _TestTokenizePackLine is UnitTest
  fun name(): String => "UIParser.tokenize_pack_line"

  fun apply(h: TestHelper) =>
    let input = "    pack-start *x4 fill"
    match UIParser.tokenize_line(input, 1)
    | let pl: ParsedLine =>
      h.assert_eq[USize](2, pl.indent)
      h.assert_eq[USize](3, pl.tokens.size())
      try
        let t0 = pl.tokens(0)?
        h.assert_true(t0.kind is TokPackStart,
          "token 0 should be TokPackStart")
        h.assert_eq[String]("pack-start", t0.value)

        let t1 = pl.tokens(1)?
        h.assert_true(t1.kind is TokSize, "token 1 should be TokSize")
        h.assert_eq[String]("*x4", t1.value)

        let t2 = pl.tokens(2)?
        h.assert_true(t2.kind is TokMode, "token 2 should be TokMode")
        h.assert_eq[String]("fill", t2.value)
      else
        h.fail("index error")
      end
    | let err: BuilderError =>
      h.fail("unexpected error: " + err.string())
    end

class \nodoc\ iso _TestTokenizeSizeStar is UnitTest
  fun name(): String => "UIParser.tokenize_size_star"

  fun apply(h: TestHelper) =>
    let input = "  pack-end *"
    match UIParser.tokenize_line(input, 1)
    | let pl: ParsedLine =>
      h.assert_eq[USize](2, pl.tokens.size())
      try
        let t0 = pl.tokens(0)?
        h.assert_true(t0.kind is TokPackEnd, "token 0 should be TokPackEnd")

        let t1 = pl.tokens(1)?
        h.assert_true(t1.kind is TokSize, "token 1 should be TokSize")
        h.assert_eq[String]("*", t1.value)
      else
        h.fail("index error")
      end
    | let err: BuilderError =>
      h.fail("unexpected error: " + err.string())
    end

class \nodoc\ iso _TestTokenizeBadIndent is UnitTest
  fun name(): String => "UIParser.tokenize_bad_indent"

  fun apply(h: TestHelper) =>
    let input = "   vbox"
    match UIParser.tokenize_line(input, 5)
    | let pl: ParsedLine =>
      h.fail("expected BuilderError for odd indent")
    | let err: BuilderError =>
      h.assert_eq[USize](5, err.line)
    end

