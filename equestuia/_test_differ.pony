use "collections"
use "pony_test"
use "pony_check"

class \nodoc\ iso _TestDifferIdenticalFrames is UnitTest
  fun name(): String => "Differ.identical_frames"

  fun apply(h: TestHelper) =>
    let g = Grid.filled(3, 2, Cell.empty())
    let changes = Differ.diff(g, g)
    h.assert_eq[USize](0, changes.size())

class \nodoc\ iso _TestDifferAllChanged is UnitTest
  fun name(): String => "Differ.all_changed"

  fun apply(h: TestHelper) =>
    let prev = Grid.filled(3, 2, Cell.empty())
    let curr = Grid.filled(3, 2, Cell('X', 1, Default, Default, 0))
    let changes = Differ.diff(prev, curr)
    h.assert_eq[USize](6, changes.size())

class \nodoc\ iso _TestDifferSingleChange is UnitTest
  fun name(): String => "Differ.single_change"

  fun apply(h: TestHelper) =>
    // 3x2 grid, flat index 4 → col=1, row=1
    let curr = GridFactory(3, 2, recover val
      let arr = Array[Cell](6)
      for i in Range(0, 6) do
        if i == 4 then
          arr.push(Cell('Z', 1, Default, Default, 0))
        else
          arr.push(Cell.empty())
        end
      end
      arr
    end)
    let prev = Grid.filled(3, 2, Cell.empty())
    let changes = Differ.diff(prev, curr)
    h.assert_eq[USize](1, changes.size())
    try
      (let col, let row, let cell) = changes(0)?
      h.assert_eq[USize](1, col)
      h.assert_eq[USize](1, row)
      h.assert_eq[U32]('Z', cell.char)
    else
      h.fail("index error")
    end

class \nodoc\ iso _TestDifferEmptyPrevious is UnitTest
  fun name(): String => "Differ.empty_previous"

  fun apply(h: TestHelper) =>
    let prev = Grid.filled(2, 2, Cell.empty())
    let curr = Grid.filled(2, 2, Cell('A', 1, Default, Default, 0))
    let changes = Differ.diff(prev, curr)
    h.assert_eq[USize](4, changes.size())

class \nodoc\ iso _PropDifferIdenticalZeroChanges is Property1[_DifferSample]
  """Property: diff of identical frames always yields 0 changes."""
  fun name(): String => "Differ.identical_zero_changes"

  fun gen(): Generator[_DifferSample] =>
    Generators.map2[USize, USize, _DifferSample](
      Generators.usize(1, 20),
      Generators.usize(1, 20),
      {(w, h) => (w, h)})

  fun property(sample: _DifferSample, h: PropertyHelper) =>
    (let w, let ht) = sample
    let g = Grid.filled(w, ht, Cell.empty())
    let changes = Differ.diff(g, g)
    h.assert_eq[USize](0, changes.size())

class \nodoc\ iso _PropDifferFullChangeCount is Property1[_DifferSample]
  """Property: diff(empty, filled) always yields w*h changes."""
  fun name(): String => "Differ.full_change_count"

  fun gen(): Generator[_DifferSample] =>
    Generators.map2[USize, USize, _DifferSample](
      Generators.usize(1, 20),
      Generators.usize(1, 20),
      {(w, h) => (w, h)})

  fun property(sample: _DifferSample, h: PropertyHelper) =>
    (let w, let ht) = sample
    let prev = Grid.filled(w, ht, Cell.empty())
    let curr = Grid.filled(w, ht, Cell('X', 1, Default, Default, 0))
    let changes = Differ.diff(prev, curr)
    h.assert_eq[USize](w * ht, changes.size())

type _DifferSample is (USize, USize)
