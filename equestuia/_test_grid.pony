use "collections"
use "pony_test"
use "pony_check"

class \nodoc\ iso _TestGridCreate is UnitTest
  fun name(): String => "Grid.create"

  fun apply(h: TestHelper) =>
    let cells = recover val
      let arr = Array[Cell](6)
      for i in Range(0, 6) do
        arr.push(Cell('A' + i.u32(), 1, Default, Default, 0))
      end
      arr
    end
    match GridFactory(3, 2, cells)
    | let g: Grid =>
      h.assert_eq[USize](3, g.width)
      h.assert_eq[USize](2, g.height)
    | let _: GridDimensionMismatch =>
      h.fail("unexpected GridDimensionMismatch")
    end

class \nodoc\ iso _TestGridDimensionMismatch is UnitTest
  fun name(): String => "Grid.dimension_mismatch"

  fun apply(h: TestHelper) =>
    let cells = recover val Array[Cell](2) .> push(Cell.empty()) .> push(Cell.empty()) end
    match GridFactory(3, 2, cells)
    | let _: Grid =>
      h.fail("expected GridDimensionMismatch")
    | let _: GridDimensionMismatch =>
      None // correct
    end

class \nodoc\ iso _TestGridApply is UnitTest
  fun name(): String => "Grid.apply"

  fun apply(h: TestHelper) =>
    let cells = recover val
      let arr = Array[Cell](4)
      arr .> push(Cell('A', 1, Default, Default, 0))
          .> push(Cell('B', 1, Default, Default, 0))
          .> push(Cell('C', 1, Default, Default, 0))
          .> push(Cell('D', 1, Default, Default, 0))
      arr
    end
    match GridFactory(2, 2, cells)
    | let g: Grid =>
      match g(0, 0)
      | let c: Cell => h.assert_eq[U32]('A', c.char)
      | let _: GridCellOutOfBounds => h.fail("unexpected out of bounds")
      end
      match g(1, 0)
      | let c: Cell => h.assert_eq[U32]('B', c.char)
      | let _: GridCellOutOfBounds => h.fail("unexpected out of bounds")
      end
      match g(0, 1)
      | let c: Cell => h.assert_eq[U32]('C', c.char)
      | let _: GridCellOutOfBounds => h.fail("unexpected out of bounds")
      end
      match g(1, 1)
      | let c: Cell => h.assert_eq[U32]('D', c.char)
      | let _: GridCellOutOfBounds => h.fail("unexpected out of bounds")
      end
    | let _: GridDimensionMismatch =>
      h.fail("unexpected GridDimensionMismatch")
    end

class \nodoc\ iso _TestGridOutOfBounds is UnitTest
  fun name(): String => "Grid.out_of_bounds"

  fun apply(h: TestHelper) =>
    let cells = recover val
      Array[Cell](2) .> push(Cell.empty()) .> push(Cell.empty())
    end
    match GridFactory(2, 1, cells)
    | let g: Grid =>
      match g(5, 0)
      | let _: Cell => h.fail("expected out of bounds")
      | let _: GridCellOutOfBounds => None // correct
      end
    | let _: GridDimensionMismatch =>
      h.fail("unexpected GridDimensionMismatch")
    end

class \nodoc\ iso _TestGridFilled is UnitTest
  fun name(): String => "Grid.filled"

  fun apply(h: TestHelper) =>
    let g = Grid.filled(3, 2, Cell('X', 1, Red, Default, 0))
    h.assert_eq[USize](3, g.width)
    h.assert_eq[USize](2, g.height)
    match g(2, 1)
    | let c: Cell => h.assert_eq[U32]('X', c.char)
    | let _: GridCellOutOfBounds => h.fail("unexpected out of bounds")
    end

class \nodoc\ iso _PropGridAccessValid is Property1[_GridAccessSample]
  """Property: any (col, row) within bounds returns the correct cell."""
  fun name(): String => "Grid.access_valid"

  fun gen(): Generator[_GridAccessSample] =>
    Generators.map2[USize, USize, _GridAccessSample](
      Generators.usize(1, 20),
      Generators.usize(1, 20),
      {(w, h) => (w, h) })

  fun property(sample: _GridAccessSample, h: PropertyHelper) =>
    (let w, let ht) = sample
    let g = Grid.filled(w, ht, Cell.empty())
    // Every valid coordinate should succeed
    for row in Range(0, ht) do
      for col in Range(0, w) do
        match g(col, row)
        | let _: Cell => None
        | let _: GridCellOutOfBounds =>
          h.fail("unexpected out of bounds at (" + col.string() + ", " + row.string() + ")")
          return
        end
      end
    end
    // One past the end should fail
    match g(w, 0)
    | let _: Cell =>
      h.fail("expected out of bounds at (" + w.string() + ", 0)")
    | let _: GridCellOutOfBounds => None
    end

type _GridAccessSample is (USize, USize)
