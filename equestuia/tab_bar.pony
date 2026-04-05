use "collections"

primitive TabHorizontal
primitive TabVertical
type TabOrientation is (TabHorizontal | TabVertical)

actor TabBar is Widget
  """
  A focusable, keyboard-navigable tab bar. Displays a row (horizontal)
  or column (vertical) of labelled tabs. Arrow keys move the highlight;
  Enter/Space activates the highlighted tab and fires the callback.
  """
  let _state: WidgetState
  let _tabs: Array[(String val, String val)]
  var _highlight: USize = 0
  var _active: USize = 0
  let _orientation: TabOrientation
  let _callback: {(String val): None} val
  var _focused: Bool = false

  new create(
    p: WidgetParent tag,
    callback: {(String val): None} val,
    orientation: TabOrientation = TabHorizontal)
  =>
    _state = WidgetState(p)
    _tabs = Array[(String val, String val)]
    _orientation = orientation
    _callback = callback

  fun ref state(): WidgetState => _state

  be add_tab(key: String val, label: String val) =>
    """
    Append a tab and re-render.
    """
    _tabs.push((key, label))
    render_and_send()

  be set_active(key: String val) =>
    """
    Set the active tab by key without firing the callback.
    Also moves highlight to match. No-op if key not found.
    """
    for i in Range(0, _tabs.size()) do
      try
        (let k, _) = _tabs(i)?
        if k == key then
          _active = i
          _highlight = i
          render_and_send()
          return
        end
      end
    end

  be receive_focus() =>
    _focused = true
    render_and_send()

  be receive_blur() =>
    _focused = false
    render_and_send()

  be receive_key(key: KeyEvent) =>
    let count = _tabs.size()
    if count == 0 then return end

    match key.key
    | Right | Down =>
      _highlight = (_highlight + 1) % count
      render_and_send()
    | Left | Up =>
      _highlight = if _highlight == 0 then count - 1 else _highlight - 1 end
      render_and_send()
    | Enter =>
      _activate()
    | CharKey if key.char == ' ' =>
      _activate()
    end

  fun ref _activate() =>
    """
    Activate the currently highlighted tab.
    """
    _active = _highlight
    try
      (let k, _) = _tabs(_highlight)?
      _callback(k)
    end
    render_and_send()

  fun ref render(): Grid =>
    let w = _state.width
    let h = _state.height
    if (w == 0) or (h == 0) or (_tabs.size() == 0) then
      return Grid.filled(w, h, _state.empty_cell())
    end

    let empty = _state.empty_cell()

    match _orientation
    | TabHorizontal => _render_horizontal(w, h, empty)
    | TabVertical => _render_vertical(w, h, empty)
    end

  fun ref _render_horizontal(w: USize, h: USize, empty: Cell): Grid =>
    let cells = recover iso Array[Cell](w * h) end

    // Build row 0 with tabs
    var col: USize = 0
    for i in Range(0, _tabs.size()) do
      try
        (_, let label) = _tabs(i)?

        // Inter-tab space (not before first tab)
        if (i > 0) and (col < w) then
          cells.push(empty)
          col = col + 1
        end

        // Space before label
        if col < w then
          cells.push(_tab_cell(' ', i))
          col = col + 1
        end

        // Label characters
        for ci in Range(0, label.size()) do
          if col < w then
            try
              cells.push(_tab_cell(label(ci)?.u32(), i))
            else
              cells.push(_tab_cell(' ', i))
            end
            col = col + 1
          end
        end

        // Space after label
        if col < w then
          cells.push(_tab_cell(' ', i))
          col = col + 1
        end
      end
    end

    // Fill remaining columns in row 0
    while col < w do
      cells.push(empty)
      col = col + 1
    end

    // Fill remaining rows
    for row in Range(1, h) do
      for c in Range(0, w) do
        cells.push(empty)
      end
    end

    GridFactory(w, h, consume cells)

  fun ref _render_vertical(w: USize, h: USize, empty: Cell): Grid =>
    let cells = recover iso Array[Cell](w * h) end

    for row in Range(0, h) do
      if row < _tabs.size() then
        try
          (_, let label) = _tabs(row)?
          var col: USize = 0

          // Space before label
          if col < w then
            cells.push(_tab_cell(' ', row))
            col = col + 1
          end

          // Label characters
          for ci in Range(0, label.size()) do
            if col < w then
              try
                cells.push(_tab_cell(label(ci)?.u32(), row))
              else
                cells.push(_tab_cell(' ', row))
              end
              col = col + 1
            end
          end

          // Space after label
          if col < w then
            cells.push(_tab_cell(' ', row))
            col = col + 1
          end

          // Fill remaining columns
          while col < w do
            cells.push(empty)
            col = col + 1
          end
        else
          for c in Range(0, w) do
            cells.push(empty)
          end
        end
      else
        for c in Range(0, w) do
          cells.push(empty)
        end
      end
    end

    GridFactory(w, h, consume cells)

  fun _tab_cell(char: U32, tab_index: USize): Cell =>
    """
    Return a styled cell for the given tab index.
    Three visual states:
    - Normal: White on Default
    - Active: BrightWhite on Blue
    - Highlighted when focused: add underline (attrs = 4)
    """
    let is_active = (tab_index == _active)
    let is_highlight = _focused and (tab_index == _highlight)

    let fg = if is_active then BrightWhite else White end
    let bg: Color = if is_active then Blue else Default end
    let attrs: U8 = if is_highlight then 4 else 0 end

    Cell(char, 1, fg, bg, attrs)
