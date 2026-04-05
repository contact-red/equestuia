use "pony_test"
use "collections"

actor _StackTestParent is WidgetParent
  """
  Test parent that captures grids. The `check_when_nonempty` variant
  waits until a grid with actual content arrives (width > 0 and height > 0),
  retrying by re-sending itself if the grid is empty or not yet received.
  """
  var _latest: (Grid | None) = None
  var _count: USize = 0

  new create() => None

  be receive_grid(widget: Any tag, grid: Grid) =>
    _latest = grid
    _count = _count + 1

  be check(cb: {(Grid, USize)} val) =>
    """
    Return whatever we have right now.
    """
    match _latest
    | let g: Grid => cb(g, _count)
    | None => cb(Grid.filled(0, 0, Cell.empty()), _count)
    end

  be check_when_content(cb: {(Grid, USize)} val, retries: USize = 50) =>
    """
    Wait until we have a grid with actual dimensions. Re-sends to self
    to yield the scheduler, allowing pending actor messages to process.
    """
    match _latest
    | let g: Grid if (g.width > 0) and (g.height > 0) =>
      cb(g, _count)
    else
      if retries > 0 then
        check_when_content(cb, retries - 1)
      else
        // Give up — return whatever we have
        match _latest
        | let g: Grid => cb(g, _count)
        | None => cb(Grid.filled(0, 0, Cell.empty()), _count)
        end
      end
    end

class \nodoc\ iso _TestStackFirstChildActive is UnitTest
  """
  Add two children, resize. The first child should be active by default
  and its content should appear in the rendered grid.
  """
  fun name(): String => "Stack.first_child_active"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let parent = _StackTestParent
    let stack = Stack(parent)

    let label_a = Label(stack, "AAAA", Green)
    let label_b = Label(stack, "BBBB", Red)

    stack.add_child("a", label_a)
    stack.add_child("b", label_b)
    stack.resize(4, 1)

    parent.check_when_content({(grid: Grid, count: USize)(h) =>
      match grid(0, 0)
      | let c: Cell =>
        h.assert_eq[U32]('A', c.char, "first child 'a' should be active")
      | GridCellOutOfBounds =>
        h.fail("grid should not be empty")
      end
      h.complete(true)
    } val)

class \nodoc\ iso _TestStackShowSwitches is UnitTest
  """
  Add two children, resize, then show("b"). The second child's content
  should appear in the rendered grid.
  """
  fun name(): String => "Stack.show_switches"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let parent = _StackTestParent
    let stack = Stack(parent)

    let label_a = Label(stack, "AAAA", Green)
    let label_b = Label(stack, "BBBB", Red)

    stack.add_child("a", label_a)
    stack.add_child("b", label_b)
    stack.resize(4, 1)

    // Switch to child "b"
    stack.show("b")

    parent.check_when_content({(grid: Grid, count: USize)(h) =>
      match grid(0, 0)
      | let c: Cell =>
        h.assert_eq[U32]('B', c.char, "child 'b' should be active after show")
      | GridCellOutOfBounds =>
        h.fail("grid should not be empty")
      end
      h.complete(true)
    } val)

class \nodoc\ iso _TestStackShowInvalidNoOp is UnitTest
  """
  Show a nonexistent name. The first child should still be active.
  """
  fun name(): String => "Stack.show_invalid_noop"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let parent = _StackTestParent
    let stack = Stack(parent)

    let label_a = Label(stack, "AAAA", Green)
    let label_b = Label(stack, "BBBB", Red)

    stack.add_child("a", label_a)
    stack.add_child("b", label_b)
    stack.resize(4, 1)

    // Try to show a nonexistent child
    stack.show("nonexistent")

    parent.check_when_content({(grid: Grid, count: USize)(h) =>
      match grid(0, 0)
      | let c: Cell =>
        h.assert_eq[U32]('A', c.char, "first child should still be active")
      | GridCellOutOfBounds =>
        h.fail("grid should not be empty")
      end
      h.complete(true)
    } val)

class \nodoc\ iso _TestStackResizeAllChildren is UnitTest
  """
  Add two children, resize, switch to second. Verify it has the correct
  dimensions (it was resized even when not active).
  """
  fun name(): String => "Stack.resize_all_children"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let parent = _StackTestParent
    let stack = Stack(parent)

    let label_a = Label(stack, "AAAA", Green)
    let label_b = Label(stack, "BBBB", Red)

    stack.add_child("a", label_a)
    stack.add_child("b", label_b)
    stack.resize(8, 2)

    // Switch to child "b"
    stack.show("b")

    parent.check_when_content({(grid: Grid, count: USize)(h) =>
      h.assert_eq[USize](8, grid.width, "grid width should be 8")
      h.assert_eq[USize](2, grid.height, "grid height should be 2")
      match grid(0, 0)
      | let c: Cell =>
        h.assert_eq[U32]('B', c.char, "child 'b' should render with correct size")
      | GridCellOutOfBounds =>
        h.fail("grid should not be empty")
      end
      h.complete(true)
    } val)
