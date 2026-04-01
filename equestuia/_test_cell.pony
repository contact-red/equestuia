use "pony_test"
use "pony_check"

class \nodoc\ iso _TestCellCreate is UnitTest
  fun name(): String => "Cell.create"

  fun apply(h: TestHelper) =>
    let cell = Cell('A', 1, Red, Blue, CellAttrs.bold())
    h.assert_eq[U32]('A', cell.char)
    h.assert_eq[U8](1, cell.width)
    h.assert_eq[U8](CellAttrs.bold(), cell.attrs)

class \nodoc\ iso _TestCellDefaults is UnitTest
  fun name(): String => "Cell.defaults"

  fun apply(h: TestHelper) =>
    let cell = Cell.empty()
    h.assert_eq[U32](' ', cell.char)
    h.assert_eq[U8](1, cell.width)
    h.assert_eq[U8](0, cell.attrs)

class \nodoc\ iso _TestCellEq is UnitTest
  fun name(): String => "Cell.eq"

  fun apply(h: TestHelper) =>
    let a = Cell('A', 1, Red, Blue, CellAttrs.bold())
    let b = Cell('A', 1, Red, Blue, CellAttrs.bold())
    let c = Cell('B', 1, Red, Blue, CellAttrs.bold())
    h.assert_true(a == b)
    h.assert_false(a == c)

class \nodoc\ iso _TestCellAttrs is UnitTest
  fun name(): String => "CellAttrs.bitfield"

  fun apply(h: TestHelper) =>
    h.assert_eq[U8](0x01, CellAttrs.bold())
    h.assert_eq[U8](0x02, CellAttrs.dim())
    h.assert_eq[U8](0x04, CellAttrs.underline())
    h.assert_eq[U8](0x08, CellAttrs.blink())
    h.assert_eq[U8](0x10, CellAttrs.reverse())
    // Combined
    let combined = CellAttrs.bold() or CellAttrs.underline()
    h.assert_eq[U8](0x05, combined)

class \nodoc\ iso _TestCellWideContinuation is UnitTest
  fun name(): String => "Cell.wide_and_continuation"

  fun apply(h: TestHelper) =>
    let wide = Cell(0x4E16, 2, Default, Default, 0) // '世' = wide
    let cont = Cell.continuation()
    h.assert_eq[U8](2, wide.width)
    h.assert_eq[U8](0, cont.width)
    h.assert_eq[U32](0, cont.char)

class \nodoc\ iso _PropCellRoundtripEq is Property1[CellTuple]
  """Property: any Cell equals itself."""
  fun name(): String => "Cell.roundtrip_eq"

  fun gen(): Generator[CellTuple] =>
    Generators.map4[U32, U8, U8, U8, CellTuple](
      Generators.u32(0x20, 0x7E),
      Generators.u8(1, 2),
      Generators.u8(0, 15),
      Generators.u8(0, 0x1F),
      {(ch, w, fg_idx, attrs) =>
        (ch, w, fg_idx, attrs)
      })

  fun property(sample: CellTuple, h: PropertyHelper) =>
    (let ch, let w, let fg_idx, let attrs) = sample
    let cell = Cell(ch, w, Default, Default, attrs)
    h.assert_true(cell == cell)

// Tuple used by the property test generator
type CellTuple is (U32, U8, U8, U8)
