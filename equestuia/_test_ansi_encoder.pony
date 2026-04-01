use "pony_test"

class \nodoc\ iso _TestEncoderMoveTo is UnitTest
  fun name(): String => "AnsiEncoder.move_to"

  fun apply(h: TestHelper) =>
    // move_to(4, 2): col+1=5, row+1=3 → ESC[3;5H
    let buf = AnsiEncoder.move_to(4, 2)
    h.assert_eq[String]("\x1B[3;5H", String.from_array(buf))

class \nodoc\ iso _TestEncoderSetFg is UnitTest
  fun name(): String => "AnsiEncoder.set_fg"

  fun apply(h: TestHelper) =>
    let buf = AnsiEncoder.set_fg(Red)
    h.assert_eq[String]("\x1B[31m", String.from_array(buf))

class \nodoc\ iso _TestEncoderSetBg is UnitTest
  fun name(): String => "AnsiEncoder.set_bg"

  fun apply(h: TestHelper) =>
    let buf = AnsiEncoder.set_bg(Blue)
    h.assert_eq[String]("\x1B[44m", String.from_array(buf))

class \nodoc\ iso _TestEncoderSetAttrs is UnitTest
  fun name(): String => "AnsiEncoder.set_attrs"

  fun apply(h: TestHelper) =>
    let attrs = CellAttrs.bold() or CellAttrs.underline()
    let buf = AnsiEncoder.set_attrs(attrs)
    let s = String.from_array(buf)
    h.assert_true(s.contains("\x1B[1m"), "expected bold SGR")
    h.assert_true(s.contains("\x1B[4m"), "expected underline SGR")

class \nodoc\ iso _TestEncoderResetAttrs is UnitTest
  fun name(): String => "AnsiEncoder.reset"

  fun apply(h: TestHelper) =>
    let buf = AnsiEncoder.reset()
    h.assert_eq[String]("\x1B[0m", String.from_array(buf))

class \nodoc\ iso _TestEncoderWriteChar is UnitTest
  fun name(): String => "AnsiEncoder.write_char_ascii"

  fun apply(h: TestHelper) =>
    let buf = AnsiEncoder.write_char('A')
    h.assert_eq[String]("A", String.from_array(buf))

class \nodoc\ iso _TestEncoderWriteUtf8 is UnitTest
  fun name(): String => "AnsiEncoder.write_char_utf8"

  fun apply(h: TestHelper) =>
    // U+00E9 (é) encodes as 2 UTF-8 bytes: 0xC3 0xA9
    let buf = AnsiEncoder.write_char(0xE9)
    h.assert_eq[USize](2, buf.size())

class \nodoc\ iso _TestEncoderHideCursor is UnitTest
  fun name(): String => "AnsiEncoder.hide_cursor"

  fun apply(h: TestHelper) =>
    let buf = AnsiEncoder.hide_cursor()
    h.assert_eq[String]("\x1B[?25l", String.from_array(buf))

class \nodoc\ iso _TestEncoderShowCursor is UnitTest
  fun name(): String => "AnsiEncoder.show_cursor"

  fun apply(h: TestHelper) =>
    let buf = AnsiEncoder.show_cursor()
    h.assert_eq[String]("\x1B[?25h", String.from_array(buf))

class \nodoc\ iso _TestEncoderClearScreen is UnitTest
  fun name(): String => "AnsiEncoder.clear_screen"

  fun apply(h: TestHelper) =>
    let buf = AnsiEncoder.clear_screen()
    h.assert_eq[String]("\x1B[2J", String.from_array(buf))
