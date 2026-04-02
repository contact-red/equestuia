class ref WidgetState
  """
  Bundles the common fields every widget needs. Stored as a single field
  on the actor and exposed via `fun ref state(): WidgetState`. The Widget
  and CompositeWidget traits use this to provide default implementations
  without requiring seven boilerplate accessors.
  """
  let parent: WidgetParent tag
  var width: USize = 0
  var height: USize = 0
  let child_grids: Array[(Any tag, Grid)]
  var dirty: Bool = false
  var debug_bg: Color = Default

  new create(parent': WidgetParent tag) =>
    parent = parent'
    child_grids = Array[(Any tag, Grid)]

  fun empty_cell(): Cell =>
    """
    Return the empty cell for this widget. Uses debug_bg as background
    when set, making the widget's allocated space visible.
    """
    Cell(' ', 1, Default, debug_bg, 0)
