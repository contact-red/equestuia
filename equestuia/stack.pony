use "collections"

actor Stack is CompositeWidget
  """
  A container that holds multiple named children but only renders the
  active one. Used for tabbed interfaces where switching between views
  should preserve child state.
  """
  let _state: WidgetState
  let _children_by_name: Map[String val, Widget tag]
  let _children_order: Array[(String val, Widget tag)]
  var _active_name: (String val | None) = None
  var _input_actor: (InputActor tag | None) = None

  new create(p: WidgetParent tag) =>
    _state = WidgetState(p)
    _children_by_name = Map[String val, Widget tag]
    _children_order = Array[(String val, Widget tag)]

  fun ref state(): WidgetState => _state

  be set_input_actor(input: InputActor tag) =>
    """
    Store a reference to the InputActor for focus scope gating.
    """
    _input_actor = input

  be add_child(name: String val, widget: Widget tag) =>
    """
    Register a child by name. The first child added becomes active.
    If the Stack already has dimensions, the child is resized immediately.
    Non-active children have their scope disabled if input_actor is set.
    """
    _children_by_name(name) = widget
    _children_order.push((name, widget))
    register_child(widget)

    if _active_name is None then
      _active_name = name
    else
      // Non-active child: disable its scope for focus gating
      match _input_actor
      | let ia: InputActor tag => ia.disable_scope(widget)
      end
    end

    // If already sized, resize the child to fill
    if (_state.width > 0) or (_state.height > 0) then
      widget.resize(_state.width, _state.height)
    end

  be show(name: String val) =>
    """
    Switch the active child. No-op if the name doesn't exist or is
    already active.
    """
    // Check if name exists
    if not _children_by_name.contains(name) then return end

    // Check if already active
    match _active_name
    | let current: String val if current == name => return
    end

    // Disable old scope, enable new scope
    match _input_actor
    | let ia: InputActor tag =>
      // Disable old active child's scope
      match _active_name
      | let old_name: String val =>
        try
          let old_widget = _children_by_name(old_name)?
          ia.disable_scope(old_widget)
        end
      end
      // Enable new child's scope
      try
        let new_widget = _children_by_name(name)?
        ia.enable_scope(new_widget)
      end
    end

    _active_name = name
    // Re-render with the new active child
    render_and_send()

  be receive_grid(widget: Any tag, grid: Grid) =>
    """
    Store all children's grids, but only trigger a deferred render if
    the grid came from the active child.
    """
    let s = _state
    for i in Range(0, s.child_grids.size()) do
      try
        (let w, _) = s.child_grids(i)?
        if w is widget then
          s.child_grids(i)? = (w, grid)
          if _is_active_widget(widget) then
            if not s.dirty then
              s.dirty = true
              _deferred_render()
            end
          end
          return
        end
      end
    end

  be resize(w: USize, h: USize) =>
    """
    Resize ALL children to full container size, not just the active one.
    """
    _state.width = w
    _state.height = h
    for child in _state.child_grids.values() do
      (let cw, _) = child
      match cw
      | let r: Widget tag => r.resize(w, h)
      end
    end
    render_and_send()

  fun ref render(): Grid =>
    """
    Return the active child's grid directly. If no active child,
    return the background.
    """
    match _active_name
    | let name: String val =>
      try
        let widget = _children_by_name(name)?
        for entry in _state.child_grids.values() do
          (let w, let grid) = entry
          if w is widget then
            return grid
          end
        end
      end
    end
    render_background()

  fun ref _is_active_widget(widget: Any tag): Bool =>
    """
    Check if the given widget is the currently active child.
    """
    match _active_name
    | let name: String val =>
      try
        let active = _children_by_name(name)?
        active is widget
      else
        false
      end
    else
      false
    end
