use "pony_test"
use "collections"

actor _TabCallback
  """
  Records callback invocations for test assertions.
  """
  var _last_key: (String val | None) = None
  var _count: USize = 0

  new create() => None

  be record(key: String val) =>
    _last_key = key
    _count = _count + 1

  be check(cb: {(String val, USize)} val) =>
    match _last_key
    | let k: String val => cb(k, _count)
    | None => cb("", _count)
    end

class \nodoc\ iso _TestTabBarHorizontalRender is UnitTest
  """
  Add 2 tabs, resize. Verify 'A' from "Alpha" appears in the grid.
  """
  fun name(): String => "TabBar.horizontal_render"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let parent = _StackTestParent
    let cb = _TabCallback
    let bar = TabBar(parent, {(key: String val) => cb.record(key)} val)

    bar.add_tab("a", "Alpha")
    bar.add_tab("b", "Beta")
    bar.resize(20, 3)

    parent.check_when_content({(grid: Grid, count: USize)(h) =>
      // Row 0 should contain " Alpha " starting at col 0
      // First cell is space, second is 'A'
      match grid(1, 0)
      | let c: Cell =>
        h.assert_eq[U32]('A', c.char, "should find 'A' from Alpha")
      | GridCellOutOfBounds =>
        h.fail("grid cell out of bounds")
      end
      h.complete(true)
    } val)

class \nodoc\ iso _TestTabBarVerticalRender is UnitTest
  """
  Add 2 tabs in vertical mode. Verify 'A' in row 0 and 'B' in row 1.
  """
  fun name(): String => "TabBar.vertical_render"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let parent = _StackTestParent
    let cb = _TabCallback
    let bar = TabBar(parent, {(key: String val) => cb.record(key)} val,
      TabVertical)

    bar.add_tab("a", "Alpha")
    bar.add_tab("b", "Beta")
    bar.resize(20, 5)

    parent.check_when_content({(grid: Grid, count: USize)(h) =>
      // Row 0: " Alpha ...", col 1 = 'A'
      match grid(1, 0)
      | let c: Cell =>
        h.assert_eq[U32]('A', c.char, "row 0 should have 'A'")
      | GridCellOutOfBounds =>
        h.fail("row 0 out of bounds")
      end
      // Row 1: " Beta ...", col 1 = 'B'
      match grid(1, 1)
      | let c: Cell =>
        h.assert_eq[U32]('B', c.char, "row 1 should have 'B'")
      | GridCellOutOfBounds =>
        h.fail("row 1 out of bounds")
      end
      h.complete(true)
    } val)

class \nodoc\ iso _TestTabBarKeyboardActivate is UnitTest
  """
  Add 3 tabs, receive_focus, Right arrow, Enter. Callback fires with "b".
  """
  fun name(): String => "TabBar.keyboard_activate"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let parent = _StackTestParent
    let cb = _TabCallback
    let bar = TabBar(parent, {(key: String val) => cb.record(key)} val)

    bar.add_tab("a", "Alpha")
    bar.add_tab("b", "Beta")
    bar.add_tab("c", "Charlie")
    bar.resize(40, 1)

    bar.receive_focus()
    bar.receive_key(KeyEvent(Right))
    bar.receive_key(KeyEvent(Enter))

    // Allow messages to process, then check callback
    parent.check_when_content({(grid: Grid, count: USize)(h, cb) =>
      cb.check({(key: String val, count: USize)(h) =>
        h.assert_eq[String val]("b", key, "callback should fire with key 'b'")
        h.assert_eq[USize](1, count, "callback should fire exactly once")
        h.complete(true)
      } val)
    } val)

class \nodoc\ iso _TestTabBarWrapAround is UnitTest
  """
  Add 2 tabs, receive_focus, Left from first wraps to last,
  Enter fires callback with "b".
  """
  fun name(): String => "TabBar.wrap_around"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let parent = _StackTestParent
    let cb = _TabCallback
    let bar = TabBar(parent, {(key: String val) => cb.record(key)} val)

    bar.add_tab("a", "Alpha")
    bar.add_tab("b", "Beta")
    bar.resize(20, 1)

    bar.receive_focus()
    bar.receive_key(KeyEvent(Left))
    bar.receive_key(KeyEvent(Enter))

    parent.check_when_content({(grid: Grid, count: USize)(h, cb) =>
      cb.check({(key: String val, count: USize)(h) =>
        h.assert_eq[String val]("b", key, "wrap-around should select 'b'")
        h.assert_eq[USize](1, count, "callback should fire exactly once")
        h.complete(true)
      } val)
    } val)

class \nodoc\ iso _TestTabBarSetActiveNoCallback is UnitTest
  """
  Add 2 tabs, set_active("b"). Callback count stays 0.
  """
  fun name(): String => "TabBar.set_active_no_callback"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let parent = _StackTestParent
    let cb = _TabCallback
    let bar = TabBar(parent, {(key: String val) => cb.record(key)} val)

    bar.add_tab("a", "Alpha")
    bar.add_tab("b", "Beta")
    bar.resize(20, 1)

    bar.set_active("b")

    parent.check_when_content({(grid: Grid, count: USize)(h, cb) =>
      cb.check({(key: String val, count: USize)(h) =>
        h.assert_eq[USize](0, count, "set_active should not fire callback")
        h.complete(true)
      } val)
    } val)
