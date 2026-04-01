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
  """
  var _parser: InputParser ref
  let _compositor: Compositor tag
  let _focus_list: Array[Widget tag]
  let _resize_list: Array[Widget tag]
  var _focus_index: USize = 0
  var _pending_mouse: (MouseEvent | None) = None

  new create(input: TerminalInput tag, compositor: Compositor tag) =>
    _parser = InputParser
    _compositor = compositor
    _focus_list = Array[Widget tag]
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

  be register_focusable(widget: Widget tag) =>
    """
    Add a widget to the focus list. The first registered widget receives
    focus automatically.
    """
    _focus_list.push(widget)
    if _focus_list.size() == 1 then
      widget.receive_focus()
    end

  be register_widget(widget: Widget tag) =>
    """
    Register a widget for resize notifications without adding to focus list.
    """
    _resize_list.push(widget)

  be unregister_focusable(widget: Widget tag) =>
    """
    Remove a widget from the focus list and adjust the focus index.
    """
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
