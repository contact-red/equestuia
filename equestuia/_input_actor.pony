use "collections"

actor InputActor is (_InputListener & _HitTestRequester)
  """
  Reads terminal input, parses events, routes to focused widget.
  """
  var _parser: InputParser ref
  let _compositor: Compositor tag
  let _focus_list: Array[WidgetBase tag]
  let _resize_list: Array[_Resizable tag]
  var _focus_index: USize = 0
  var _pending_mouse: (MouseEvent | None) = None

  new create(input: TerminalInput tag, compositor: Compositor tag) =>
    _parser = InputParser
    _compositor = compositor
    _focus_list = Array[WidgetBase tag]
    _resize_list = Array[_Resizable tag]
    input.subscribe(this)

  be register_focusable(widget: WidgetBase tag) =>
    _focus_list.push(widget)
    _resize_list.push(widget)
    // First registered widget gets focus
    if _focus_list.size() == 1 then
      widget.receive_focus()
    end

  be register_resizable(widget: _Resizable tag) =>
    _resize_list.push(widget)

  be unregister_focusable(widget: WidgetBase tag) =>
    try
      let idx = _find_widget(widget)?
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
    let events = _parser.parse(data)
    for event in events.values() do
      match event
      | let ke: KeyEvent => _route_key(ke)
      | let me: MouseEvent => _route_mouse(me)
      | let re: ResizeEvent => _route_resize(re)
      end
    end

  be hit_test_result(widget: (Any tag | None)) =>
    // Callback from compositor for mouse routing.
    // Mouse support is placeholder for now: just clear pending.
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

  fun _find_widget(widget: WidgetBase tag): USize ? =>
    for i in Range[USize](0, _focus_list.size()) do
      try
        if _focus_list(i)? is widget then return i end
      end
    end
    error
