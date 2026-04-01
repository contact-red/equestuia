use "pony_test"

class \nodoc\ iso _TestParserPrintableChar is UnitTest
  fun name(): String => "InputParser.printable_char"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 'a'])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: CharKey => None
        else h.fail("expected CharKey")
        end
        h.assert_eq[U32]('a', ke.char)
        h.assert_eq[U8](0, ke.modifiers)
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserEnter is UnitTest
  fun name(): String => "InputParser.enter"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 13])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Enter => None
        else h.fail("expected Enter")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserEscape is UnitTest
  fun name(): String => "InputParser.escape"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 27])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Escape => None
        else h.fail("expected Escape")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserTab is UnitTest
  fun name(): String => "InputParser.tab"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 9])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Tab => None
        else h.fail("expected Tab")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserBackspace is UnitTest
  fun name(): String => "InputParser.backspace"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 127])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Backspace => None
        else h.fail("expected Backspace")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserCtrlA is UnitTest
  fun name(): String => "InputParser.ctrl_a"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 1])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: CharKey => None
        else h.fail("expected CharKey")
        end
        h.assert_eq[U32]('a', ke.char)
        h.assert_eq[U8](Modifiers.ctrl(), ke.modifiers)
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserArrowUp is UnitTest
  fun name(): String => "InputParser.arrow_up"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 27; 91; 65])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Up => None
        else h.fail("expected Up")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserArrowDown is UnitTest
  fun name(): String => "InputParser.arrow_down"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 27; 91; 66])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Down => None
        else h.fail("expected Down")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserArrowRight is UnitTest
  fun name(): String => "InputParser.arrow_right"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 27; 91; 67])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Right => None
        else h.fail("expected Right")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserArrowLeft is UnitTest
  fun name(): String => "InputParser.arrow_left"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 27; 91; 68])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Left => None
        else h.fail("expected Left")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserHome is UnitTest
  fun name(): String => "InputParser.home"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 27; 91; 72])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Home => None
        else h.fail("expected Home")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserEnd is UnitTest
  fun name(): String => "InputParser.end"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 27; 91; 70])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: End => None
        else h.fail("expected End")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserDeleteKey is UnitTest
  fun name(): String => "InputParser.delete_key"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 27; 91; 51; 126])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: Delete => None
        else h.fail("expected Delete")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserF1 is UnitTest
  fun name(): String => "InputParser.f1"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 27; 79; 80])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: F1 => None
        else h.fail("expected F1")
        end
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserUtf8TwoByte is UnitTest
  fun name(): String => "InputParser.utf8_two_byte"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 0xC3; 0xA9])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: CharKey => None
        else h.fail("expected CharKey")
        end
        h.assert_eq[U32](0xE9, ke.char)
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserUtf8ThreeByte is UnitTest
  fun name(): String => "InputParser.utf8_three_byte"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 0xE4; 0xB8; 0x96])
    h.assert_eq[USize](1, events.size())
    try
      match events(0)?
      | let ke: KeyEvent =>
        match ke.key
        | let _: CharKey => None
        else h.fail("expected CharKey")
        end
        h.assert_eq[U32](0x4E16, ke.char)
      else h.fail("expected KeyEvent")
      end
    else
      h.fail("no events")
    end

class \nodoc\ iso _TestParserMultipleChars is UnitTest
  fun name(): String => "InputParser.multiple_chars"

  fun apply(h: TestHelper) =>
    let parser = InputParser
    let events = parser.parse([as U8: 'a'; 'b'; 'c'])
    h.assert_eq[USize](3, events.size())
    for i in events.values() do
      match i
      | let ke: KeyEvent =>
        match ke.key
        | let _: CharKey => None
        else h.fail("expected CharKey")
        end
      else h.fail("expected KeyEvent")
      end
    end
