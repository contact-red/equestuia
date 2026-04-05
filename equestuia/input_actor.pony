use "collections"
use "signals"

class _WinchNotify is SignalNotify
  """
  Signal handler that notifies the InputActor on SIGWINCH.
  """
  let _input: InputActor tag

  new create(input: InputActor tag) =>
    _input = input

  fun apply(times: U32): Bool =>
    _input._winch()
    true

actor InputActor is (InputListener & _HitTestRequester)
  """
  Reads terminal input, parses events, routes to focused widget.
  Listens for SIGWINCH to detect terminal resize.

  Focus is scope-aware: widgets are registered with an optional scope token.
  Disabling a scope removes its widgets from the active focus list.
  Widgets with no scope (None) are always active.
  """
  var _parser: InputParser ref
  let _compositor: Compositor tag
  let _focus_scopes: Array[(Widget tag, (Any tag | None))]
  let _focus_list: Array[Widget tag]
  let _disabled_scopes: Array[Any tag]
  let _resize_list: Array[Widget tag]
  var _focus_index: USize = 0
  var _pending_mouse: (MouseEvent | None) = None

  new create(input: TerminalInput tag, compositor: Compositor tag) =>
    _parser = InputParser
    _compositor = compositor
    _focus_scopes = Array[(Widget tag, (Any tag | None))]
    _focus_list = Array[Widget tag]
    _disabled_scopes = Array[Any tag]
    _resize_list = Array[Widget tag]
    input.subscribe(this)
    ifdef not windows then
      SignalHandler(recover _WinchNotify(this) end, Sig.winch())
    end

  be _winch() =>
    """
    Called when SIGWINCH is received. Queries the new terminal size and
    routes it as a resize event.
    """
    (let w, let h) = TermSize()
    _route_resize(ResizeEvent(w, h))

  be register_focusable(widget: Widget tag, scope: (Any tag | None) = None) =>
    """
    Add a widget to the focus list with an optional scope. The first
    registered widget in an enabled scope receives focus automatically.
    """
    _focus_scopes.push((widget, scope))
    if _is_scope_enabled(scope) then
      _focus_list.push(widget)
      if _focus_list.size() == 1 then
        widget.receive_focus()
      end
    end

  be register_widget(widget: Widget tag) =>
    """
    Register a widget for resize notifications without adding to focus list.
    """
    _resize_list.push(widget)

  be unregister_focusable(widget: Widget tag) =>
    """
    Remove a widget from both the scope registry and the focus list,
    and adjust the focus index.
    """
    // Remove from _focus_scopes
    for i in Range[USize](0, _focus_scopes.size()) do
      try
        (let w, _) = _focus_scopes(i)?
        if w is widget then
          _focus_scopes.delete(i)?
          break
        end
      end
    end
    // Remove from _focus_list
    try
      let idx = _find_in_focus_list(widget)?
      _focus_list.delete(idx)?
      if _focus_list.size() == 0 then
        _focus_index = 0
      elseif idx < _focus_index then
        _focus_index = _focus_index - 1
      elseif _focus_index >= _focus_list.size() then
        _focus_index = _focus_list.size() - 1
      end
    end

  be disable_scope(scope: Any tag) =>
    """
    Disable a scope, removing its widgets from the active focus list.
    If the currently focused widget is in the disabled scope, focus
    moves to the first remaining widget.
    """
    // Don't double-add
    for s in _disabled_scopes.values() do
      if s is scope then return end
    end
    _disabled_scopes.push(scope)
    _rebuild_focus_list()

  be enable_scope(scope: Any tag) =>
    """
    Re-enable a previously disabled scope, restoring its widgets to
    the active focus list. No-op if the scope is not currently disabled.
    """
    var found: Bool = false
    for i in Range[USize](0, _disabled_scopes.size()) do
      try
        if _disabled_scopes(i)? is scope then
          _disabled_scopes.delete(i)?
          found = true
          break
        end
      end
    end
    if found then
      _rebuild_focus_list()
    end

  be _query_focus_state(cb: {(USize, USize)} val) =>
    """
    Query the current focus state (focus index and focus list size).
    Package-private — used by tests to verify focus after async operations.
    Messages to this behavior are ordered with other behaviors on this actor,
    so querying after disable_scope/enable_scope guarantees the state reflects
    those operations.
    """
    cb(_focus_index, _focus_list.size())

  be receive(data: Array[U8] val) =>
    """
    Called by TerminalInput when raw bytes arrive. Parses and routes events.
    """
    let events = _parser.parse(data)
    for event in events.values() do
      match event
      | let ke: KeyEvent => _route_key(ke)
      | let me: MouseEvent => _route_mouse(me)
      | let re: ResizeEvent => _route_resize(re)
      end
    end

  be hit_test_result(widget: (Any tag | None)) =>
    """
    Callback from compositor hit_test. Mouse routing is not yet implemented.
    """
    _pending_mouse = None

  fun ref _route_key(ke: KeyEvent) =>
    if (ke.key is Tab) and ((ke.modifiers and Modifiers.shift()) != 0) then
      _focus_prev()
    elseif ke.key is Tab then
      _focus_next()
    else
      try _focus_list(_focus_index)?.receive_key(ke) end
    end

  fun ref _route_mouse(me: MouseEvent) =>
    _pending_mouse = me
    _compositor.hit_test(me.col, me.row, this)

  fun ref _route_resize(re: ResizeEvent) =>
    for widget in _resize_list.values() do
      widget.resize(re.width, re.height)
    end
    _compositor.screen_resize(re.width, re.height)

  fun ref _focus_next() =>
    if _focus_list.size() == 0 then return end
    try _focus_list(_focus_index)?.receive_blur() end
    _focus_index = (_focus_index + 1) % _focus_list.size()
    try _focus_list(_focus_index)?.receive_focus() end

  fun ref _focus_prev() =>
    if _focus_list.size() == 0 then return end
    try _focus_list(_focus_index)?.receive_blur() end
    if _focus_index == 0 then
      _focus_index = _focus_list.size() - 1
    else
      _focus_index = _focus_index - 1
    end
    try _focus_list(_focus_index)?.receive_focus() end

  fun _find_in_focus_list(widget: Widget tag): USize ? =>
    for i in Range[USize](0, _focus_list.size()) do
      try
        if _focus_list(i)? is widget then return i end
      end
    end
    error

  fun ref _rebuild_focus_list() =>
    """
    Rebuild _focus_list from _focus_scopes, excluding disabled scopes.
    Preserves focus on the current widget if it's still in the list,
    otherwise focuses the first available widget.
    """
    // Remember the currently focused widget before rebuilding
    let prev_focused: (Widget tag | None) =
      try _focus_list(_focus_index)? else None end

    // Blur the current widget — it may or may not retain focus
    match prev_focused
    | let w: Widget tag => w.receive_blur()
    end

    _focus_list.clear()
    for entry in _focus_scopes.values() do
      (let w, let s) = entry
      if _is_scope_enabled(s) then
        _focus_list.push(w)
      end
    end

    // Try to keep focus on the same widget
    _focus_index = 0
    match prev_focused
    | let pw: Widget tag =>
      try
        _focus_index = _find_in_focus_list(pw)?
      end
    end

    // Focus the widget at the new index
    try _focus_list(_focus_index)?.receive_focus() end

  fun _is_scope_enabled(scope: (Any tag | None)): Bool =>
    """
    Check if a scope is enabled. None (no scope) is always enabled.
    """
    // Can't match (Any tag | None) because None is a subtype of Any tag.
    // Use identity comparison instead.
    if scope is None then return true end
    for disabled in _disabled_scopes.values() do
      if disabled is scope then return false end
    end
    true
