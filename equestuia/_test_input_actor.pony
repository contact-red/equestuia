use "pony_test"
use "collections"

actor _FocusRecorder is Widget
  """
  A minimal widget that records focus/blur events for testing.
  """
  let _state: WidgetState
  var _focused: Bool = false

  new create(p: WidgetParent tag) =>
    _state = WidgetState(p)

  fun ref state(): WidgetState => _state

  fun ref render(): Grid =>
    Grid.filled(_state.width, _state.height, Cell.empty())

  be receive_focus() =>
    _focused = true

  be receive_blur() =>
    _focused = false

// A trivial scope token — just needs identity comparison
actor _ScopeToken

// A sink that accepts child grids (needed as WidgetParent for _FocusRecorder)
actor _NullParent is WidgetParent
  be receive_grid(widget: Any tag, grid: Grid) => None

class \nodoc\ iso _TestInputActorScopeDisable is UnitTest
  """
  Register widgets under a scope, disable the scope, verify focus moves
  to an unscoped widget.
  """
  fun name(): String => "InputActor.scope_disable"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let output = _MockOutput
    let input = _MockInput
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)

    let parent = _NullParent
    let scope = _ScopeToken

    // w1 is scoped, w2 is unscoped
    let w1 = _FocusRecorder(parent)
    let w2 = _FocusRecorder(parent)

    input_actor.register_focusable(w1, scope)
    input_actor.register_focusable(w2)

    // Disable the scope — w1 should be removed, only w2 remains
    input_actor.disable_scope(scope)

    // Query through InputActor to guarantee ordering.
    // After disable: focus list = [w2], focus_index = 0
    input_actor._query_focus_state({(idx: USize, size: USize)(h) =>
      h.assert_eq[USize](1, size, "focus list should have 1 widget after disable")
      h.assert_eq[USize](0, idx, "focus index should be 0")
      h.complete(true)
    } val)

class \nodoc\ iso _TestInputActorScopeEnable is UnitTest
  """
  Disable then re-enable a scope, verify widgets are reachable again.
  """
  fun name(): String => "InputActor.scope_enable"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let output = _MockOutput
    let input = _MockInput
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)

    let parent = _NullParent
    let scope = _ScopeToken

    let w1 = _FocusRecorder(parent)
    let w2 = _FocusRecorder(parent)

    input_actor.register_focusable(w1, scope)
    input_actor.register_focusable(w2)

    // Disable then re-enable
    input_actor.disable_scope(scope)
    input_actor.enable_scope(scope)

    // After re-enabling, both widgets should be in the focus list
    input_actor._query_focus_state({(idx: USize, size: USize)(h) =>
      h.assert_eq[USize](2, size,
        "focus list should have 2 widgets after re-enable")
      h.complete(true)
    } val)

class \nodoc\ iso _TestInputActorNoScopeAlwaysEnabled is UnitTest
  """
  Widgets with no scope are unaffected by disable_scope.
  """
  fun name(): String => "InputActor.no_scope_always_enabled"

  fun apply(h: TestHelper) =>
    h.long_test(2_000_000_000)

    let output = _MockOutput
    let input = _MockInput
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)

    let parent = _NullParent
    let scope = _ScopeToken

    // Both widgets unscoped
    let w1 = _FocusRecorder(parent)
    let w2 = _FocusRecorder(parent)

    input_actor.register_focusable(w1)
    input_actor.register_focusable(w2)

    // Disable some scope — should not affect unscoped widgets
    input_actor.disable_scope(scope)

    // Both should still be in focus list, focus_index should be 0 (w1)
    input_actor._query_focus_state({(idx: USize, size: USize)(h) =>
      h.assert_eq[USize](2, size,
        "focus list should still have 2 unscoped widgets")
      h.assert_eq[USize](0, idx,
        "focus should still be on first widget")
      h.complete(true)
    } val)
